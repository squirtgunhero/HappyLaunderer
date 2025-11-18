require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { pool } = require('../config/database');

async function runMigrations() {
  try {
    console.log('🔄 Running database migrations...');

    // Read migration file
    const migrationFile = path.join(__dirname, '001_initial_schema.sql');
    const sql = fs.readFileSync(migrationFile, 'utf8');

    // Execute migration
    await pool.query(sql);

    console.log('✅ Migrations completed successfully');
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

runMigrations();

