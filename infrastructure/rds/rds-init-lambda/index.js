const { Client } = require('pg');
const axios = require('axios');

async function sendResponse(event, context, status, data) {
  const responseBody = {
    Status: status,
    Reason: JSON.stringify(data),
    PhysicalResourceId: context.logStreamName,
    StackId: event.StackId,
    RequestId: event.RequestId,
    LogicalResourceId: event.LogicalResourceId,
    Data: data,
  };
  await axios.put(event.ResponseURL, responseBody);
}

exports.handler = async (event, context) => {
  const secretArn = process.env.SECRET_ARN;
  const dbHost = process.env.DB_HOST;
  const dbName = 'koop';
  let client;

  try {
    // Retrieve RDS credentials from Secrets Manager
    const secretsManager = require('aws-sdk').SecretsManager;
    const secretsClient = new secretsManager();
    const secret = await secretsClient.getSecretValue({ SecretId: secretArn }).promise();
    const { username, password } = JSON.parse(secret.SecretString);

    // Retry connection
    let retries = 5;
    while (retries > 0) {
      try {
        client = new Client({
          host: dbHost,
          port: 5432,
          database: 'postgres',
          user: username,
          password: password,
        });
        await client.connect();
        break;
      } catch (error) {
        console.error('Connection attempt failed:', error);
        retries--;
        if (retries === 0) throw error;
        await new Promise(resolve => setTimeout(resolve, 30000)); // Wait 30 seconds
      }
    }

    // Execute initialization SQL
    await client.query(`
      DO $$ 
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'koop') THEN
          CREATE DATABASE koop WITH OWNER = ${username};
        END IF;
      END $$;
      GRANT ALL PRIVILEGES ON DATABASE koop TO ${username};
      DO $$ 
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'koopuser') THEN
          CREATE USER koopuser WITH PASSWORD 'kooppass' CREATEDB;
        END IF;
      END $$;
      GRANT ALL PRIVILEGES ON DATABASE koop TO koopuser;
    `);

    // Switch to koop database
    await client.end();
    client = new Client({
      host: dbHost,
      port: 5432,
      database: 'koop',
      user: username,
      password: password,
    });
    await client.connect();

    await client.query(`
      CREATE EXTENSION IF NOT EXISTS postgis;

      CREATE TABLE IF NOT EXISTS public.territories (
        territory_id SERIAL PRIMARY KEY,
        name TEXT,
        geom GEOMETRY(POLYGON, 4326)
      );

      INSERT INTO public.territories (name, geom)
      SELECT 'Tampa North',
             ST_SetSRID(ST_MakePolygon(ST_GeomFromText(
               'LINESTRING(
                 -82.5 28.1,
                 -82.2 28.1,
                 -82.2 28.4,
                 -82.5 28.4,
                 -82.5 28.1
               )')), 4326)
      WHERE NOT EXISTS (
        SELECT 1 FROM public.territories WHERE name = 'Tampa North'
      );

      INSERT INTO public.territories (name, geom)
      SELECT 'Tampa South',
             ST_SetSRID(ST_MakePolygon(ST_GeomFromText(
               'LINESTRING(
                 -82.6 27.8,
                 -82.3 27.8,
                 -82.3 28.1,
                 -82.6 28.1,
                 -82.6 27.8
               )')), 4326)
      WHERE NOT EXISTS (
        SELECT 1 FROM public.territories WHERE name = 'Tampa South'
      );

      CREATE INDEX IF NOT EXISTS territories_geom_idx ON public.territories USING GIST (geom);
      GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO koopuser;
      GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO koopuser;
    `);

    await client.end();
    await sendResponse(event, context, 'SUCCESS', { message: 'Database initialized successfully' });
  } catch (error) {
    console.error('Error:', error);
    if (client) await client.end();
    await sendResponse(event, context, 'FAILED', { error: error.message });
  }
};