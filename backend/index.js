const { Kafka, Partitioners } = require('kafkajs')
const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

const app = express();
const port = 3000;
app.use(cors());
app.use(express.json());

// Process env variables
dotenv.config();
const kafkaBrokers = process.env.KAFKA_BROKERS || 'localhost:9092';
const kafkaUser = process.env.KAFKA_USERNAME || 'test';
const kafkaPassword = process.env.KAFKA_PASSWORD || 'test';
const kafkaTopic = process.env.KAFKA_TOPIC || 'test';

const kafka = new Kafka({
  brokers: [kafkaBrokers],
  sasl: {
    mechanism: 'SCRAM-SHA-256',
    username: kafkaUser,
    password: kafkaPassword,
  },
  ssl: true,
})

// Post Endpoint to accept the data: username, score and id
app.post('/api', async (req, res) => {
  const { username, score, id, count } = req.body;
  let topic = "game-score";
  if (count) {
    topic = "score-count"
  }
  const message = { username, score, id };
  console.log(JSON.stringify(message));

  const producer = kafka.producer({ createPartitioner: Partitioners.DefaultPartitioner })
  await producer.connect();
  await producer.send({
    topic: topic,
    messages: [{
      key: 'game-score',
      value: JSON.stringify(message)
    }]
  }).then(() => {
    console.log('Message sent');
  }).finally(() => {
    producer.disconnect();
  });
  res.send('Score saved');
});

app.listen(port, () => console.log(`App listening on port ${port}!`))
