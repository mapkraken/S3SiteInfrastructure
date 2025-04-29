#!/bin/bash -xe
          # Define a logging function
          log_message() {
            local message="$1"
            echo "$message" >> /tmp/userdata-test.log
          }
          log_message "UserData version: ${UserDataVersion}"
          log_message "UserData script is running"
          log_message "INSTALL cloud-init"
          dnf install -y cloud-init
          log_message "Disable cloud-init network config"
          systemctl enable cloud-init
          log_message "Redirect stdout and stderr to a log file"
          # Redirect stdout and stderr to a log file
          exec > /var/log/user-data.log 2>&1
          log_message "Update packages"

          # Update packages
          dnf update -y
          log_message "Install basic tools"
          # Install basic tools
          dnf install -y wget git
          log_message "Install PostgreSQL 17"
          # Install PostgreSQL 17
          dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
          dnf -qy module disable postgresql
          dnf install -y postgresql17-server postgresql17-contrib

          log_message "Check if PostgreSQL installed successfully"
          # Check if PostgreSQL installed successfully
          if [ ! -f /usr/pgsql-17/bin/psql ]; then
            log_message "PostgreSQL install failed"
            exit 1
          fi

          log_message "Initialize and start PostgreSQL"
          # Initialize and start PostgreSQL
          /usr/pgsql-17/bin/postgresql-17-setup initdb
          systemctl enable postgresql-17
          systemctl start postgresql-17

          log_message "Configure PostgreSQL to allow remote connections"
          # PostgreSQL config
          sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /var/lib/pgsql/17/data/postgresql.conf
          echo "host all all 0.0.0.0/0 md5" >> /var/lib/pgsql/17/data/pg_hba.conf
          systemctl restart postgresql-17

          log_message "Create DB + user"
          # Create DB + user
          /usr/pgsql-17/bin/psql -U postgres -c "CREATE USER bastionuser WITH PASSWORD 'securepassword';"
          /usr/pgsql-17/bin/psql -U postgres -c "CREATE DATABASE bastiondb OWNER bastionuser;"
          /usr/pgsql-17/bin/psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE bastiondb TO bastionuser;"

          log_message "Install Shmig"
          # Install shmig
          git clone https://github.com/tigitz/shmig.git /opt/shmig
          chmod +x /opt/shmig/shmig
          export PATH=$PATH:/usr/pgsql-17/bin

          log_message "Set up the database connection"
          # Set up the database connection
          mkdir -p /opt/migrations
          cat <<EOF > /opt/shmig/shmig.conf
          TYPE=postgres
          DATABASE=bastiondb
          LOGIN=bastionuser
          PASSWORD=securepassword
          HOST=localhost
          PORT=5432
          MIGRATIONS=/opt/migrations
          EOF

          log_message "Create migration file ONE"
          # Create migration files
          cat <<EOF > /opt/migrations/001_create_table.sql
          CREATE TABLE users (
            id SERIAL PRIMARY KEY,
            name VARCHAR(255) NOT NULL
          );
          EOF

          log_message "Create data migration file TWO"
          # Create data migration file
          cat <<EOF > /opt/migrations/002_insert_data.sql
          INSERT INTO users (name) VALUES ('BastionUser');
          EOF

          log_message "Run migration"
          # Run migration
          cd /opt/shmig
          ./shmig -c shmig.conf migrate || {
            echo "Shmig migration failed" >&2
            exit 1
          }

          log_message "== Setup complete. Verifying DB =="
          # Verify DB
          # Check if PostgreSQL is running
          /usr/pgsql-17/bin/psql -U bastionuser -d bastiondb -c "SELECT * FROM users;" || echo "Verification failed"