const mysql = require('mysql2/promise');
const dotenv = require('dotenv');

dotenv.config();

// Create initial connection pool
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'ebook_db',
  port: parseInt(process.env.DB_PORT || '3306'),
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  charset: 'utf8mb4'
});

// Function to test connection & verify database status
async function testConnection() {
  try {
    const connection = await pool.getConnection();
    console.log('✅ Connected to MySQL Database (phpMyAdmin / XAMPP) successfully!');
    connection.release();
    return true;
  } catch (error) {
    console.error('❌ Database Connection Error:', error.message);
    console.log('💡 Tip: Make sure XAMPP MySQL is running and database "ebook_db" is created.');
    return false;
  }
}

module.exports = {
  pool,
  testConnection
};
