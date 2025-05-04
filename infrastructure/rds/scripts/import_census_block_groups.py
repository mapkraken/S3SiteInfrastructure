import requests
from bs4 import BeautifulSoup
import os
import zipfile
import subprocess
import tempfile
import shutil
import argparse
from dotenv import load_dotenv
import psycopg2
import warnings

# Load .env file
load_dotenv()

# Get database parameters from environment variables
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")

# Construct POSTGIS_CONN string
POSTGIS_CONN = f"PG:host={DB_HOST} port={DB_PORT} dbname={DB_NAME} user={DB_USER} password={DB_PASSWORD}"

# Configuration
BASE_URL = "https://www2.census.gov/geo/tiger/TIGER2024/BG/"
OUTPUT_TABLE = "census_block_groups_2024"
TEMP_DIR = tempfile.mkdtemp()  # Temporary directory for downloads/extraction

def get_zip_files():
    """Scrape the list of zip files from the TIGER/Line URL."""
    try:
        response = requests.get(BASE_URL, timeout=10)
        response.raise_for_status()
    except requests.exceptions.SSLError as e:
        warnings.warn(
            f"SSL verification failed for {BASE_URL}: {e}. Retrying with verify=False. "
            "This is insecure; please ensure macOS certificates or certifi are installed."
        )
        response = requests.get(BASE_URL, verify=False, timeout=10)
        response.raise_for_status()
    soup = BeautifulSoup(response.text, "html.parser")
    zip_files = []
    for link in soup.find_all("a"):
        href = link.get("href")
        if href and href.endswith(".zip") and href.startswith("tl_2024_"):
            zip_files.append(href)
    return zip_files

def download_and_extract(zip_file, temp_dir):
    """Download and extract a zip file, return the shapefile path."""
    zip_url = BASE_URL + zip_file
    zip_path = os.path.join(temp_dir, zip_file)
    
    # Download
    print(f"Downloading {zip_file}...")
    try:
        response = requests.get(zip_url, stream=True, timeout=10)
        response.raise_for_status()
    except requests.exceptions.SSLError as e:
        warnings.warn(
            f"SSL verification failed for {zip_url}: {e}. Retrying with verify=False. "
            "This is insecure; please ensure macOS certificates or certifi are installed."
        )
        response = requests.get(zip_url, stream=True, verify=False, timeout=10)
        response.raise_for_status()
    with open(zip_path, "wb") as f:
        for chunk in response.iter_content(chunk_size=8192):
            f.write(chunk)
    
    # Extract
    extract_dir = os.path.join(temp_dir, zip_file.replace(".zip", ""))
    os.makedirs(extract_dir, exist_ok=True)
    with zipfile.ZipFile(zip_path, "r") as zip_ref:
        zip_ref.extractall(extract_dir)
    
    # Find the .shp file
    for root, _, files in os.walk(extract_dir):
        for file in files:
            if file.endswith(".shp"):
                return os.path.join(root, file)
    raise FileNotFoundError(f"No .shp file found in {extract_dir}")

def import_to_postgis(shp_path, table_name, is_first=False):
    """Import shapefile to PostGIS using ogr2ogr."""
    cmd = [
        "ogr2ogr",
        "-f", "PostgreSQL",
        POSTGIS_CONN,
        shp_path,
        "-nln", table_name,
        "-nlt", "PROMOTE_TO_MULTI",
        "-t_srs", "EPSG:4326"
    ]
    
    # Overwrite table for the first file, append for others
    if is_first:
        cmd.append("-overwrite")
    else:
        cmd.extend(["-append", "-update"])
    
    print(f"Importing {shp_path} to {table_name} (append={not is_first})...")
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error importing {shp_path}:")
        print(result.stderr)
        raise subprocess.CalledProcessError(result.returncode, cmd, result.stderr)
    print(f"Successfully imported {shp_path}")

def add_gid_column():
    """Add gid column to the table and populate it with ogc_fid values."""
    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )
    try:
        with conn.cursor() as cur:
            # Check if gid column exists
            cur.execute("""
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_schema = 'public' 
                AND table_name = %s 
                AND column_name = 'gid';
            """, (OUTPUT_TABLE,))
            if cur.fetchone():
                print("gid column already exists, updating values...")
                cur.execute(f"""
                    UPDATE public.{OUTPUT_TABLE}
                    SET gid = ogc_fid
                    WHERE gid IS DISTINCT FROM ogc_fid;
                """)
            else:
                print("Adding gid column and populating with ogc_fid values...")
                cur.execute(f"""
                    ALTER TABLE public.{OUTPUT_TABLE}
                    ADD COLUMN gid INTEGER;
                """)
                cur.execute(f"""
                    UPDATE public.{OUTPUT_TABLE}
                    SET gid = ogc_fid;
                """)
            conn.commit()
        print(f"Successfully added/updated gid column in {OUTPUT_TABLE}")
    except psycopg2.Error as e:
        print(f"Error adding/updating gid column: {e}")
        conn.rollback()
        raise
    finally:
        conn.close()

def grant_permissions():
    """Grant SELECT permission to koopuser on the table."""
    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )
    try:
        with conn.cursor() as cur:
            cur.execute(f"GRANT SELECT ON public.{OUTPUT_TABLE} TO {DB_USER};")
            conn.commit()
        print(f"Granted SELECT permission on {OUTPUT_TABLE} to {DB_USER}")
    finally:
        conn.close()

def main(fips_codes=None):
    try:
        # Get list of zip files
        zip_files = get_zip_files()
        print(f"Found {len(zip_files)} zip files: {zip_files}")
        
        # Filter zip files based on FIPS codes if provided
        if fips_codes is not None:
            # Convert FIPS codes to strings with leading zeros (e.g., 11 -> '11')
            fips_codes = [str(fips).zfill(2) for fips in fips_codes]
            zip_files = [
                zf for zf in zip_files
                if zf.split("_")[2][:2] in fips_codes
            ]
            if not zip_files:
                print(f"No zip files found for FIPS codes: {fips_codes}")
                return
            print(f"Processing {len(zip_files)} zip files for FIPS codes {fips_codes}: {zip_files}")
        
        # Process each zip file
        for i, zip_file in enumerate(zip_files):
            shp_path = download_and_extract(zip_file, TEMP_DIR)
            import_to_postgis(shp_path, OUTPUT_TABLE, is_first=(i == 0))
        
        # Add gid column and populate with ogc_fid
        add_gid_column()
        
        # Grant permissions
        grant_permissions()
        
        print(f"All block groups imported into public.{OUTPUT_TABLE}")
        print(f"Access via Koop: https://sit-koop.mapkraken.com/pg/rest/services/public.{OUTPUT_TABLE}/FeatureServer/0")
    
    finally:
        # Clean up temporary directory
        shutil.rmtree(TEMP_DIR, ignore_errors=True)
        print(f"Cleaned up temporary directory: {TEMP_DIR}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Process Census TIGER/Line block group files.")
    parser.add_argument(
        "--fips",
        nargs="*",
        type=int,
        help="List of FIPS codes to process (e.g., 11 12). Omit to process all."
    )
    args = parser.parse_args()
    main(args.fips)