const WebSocket = require('ws')
const { Client } = require('pg');
const dotenv = require('dotenv');

dotenv.config();
// Get the environment variables from the .env file
const {
  DB_USER,
  DB_PASSWORD,
  DB_NAME,
  DB_HOST,
  DB_PORT } = process.env;

const wss = new WebSocket.Server({ port: 8080 })

wss.on('connection', async ws => {
  // Connect to the database
  const client = new Client({
    user: DB_USER,
    password: DB_PASSWORD,
    host: DB_HOST,
    port: DB_PORT,
    database: DB_NAME,
    ssl: true
  });
  await client.connect();
  console.log("Connected to Materialize");
  // Send current score count
  const currnetScore = await client.query('SELECT * FROM score_count_m');
  ws.send(JSON.stringify(currnetScore.rows));

  // Get the total score of all players
  await client.query('SET CLUSTER=devex');
  await client.query('BEGIN');
  await client.query('DECLARE c CURSOR FOR SUBSCRIBE score_count_m WITH (SNAPSHOT = false)');

  while (true) {
    const res = await client.query('FETCH ALL c');
    console.log(res.rows);
    ws.send(JSON.stringify(res.rows));
  }
})
