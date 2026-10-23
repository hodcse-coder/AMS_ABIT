import pg from 'pg';

if (!process.env.DATABASE_URL) {
  console.error('Set DATABASE_URL in .env using .env.example before checking the application database.');
  process.exit(1);
}

const client = new pg.Client({ connectionString: process.env.DATABASE_URL, connectionTimeoutMillis: 5000 });
try {
  await client.connect();
  const { rows } = await client.query('SELECT current_database() AS database, version() AS version');
  console.log(`Connected to ${rows[0].database}: ${rows[0].version}`);
} catch (error) {
  console.error(`Database connection failed (${error.code ?? 'unknown error'}). Check the local PostgreSQL connection settings.`);
  process.exitCode = 1;
} finally {
  await client.end();
}
