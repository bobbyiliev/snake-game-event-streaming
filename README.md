# Gaming Event Streaming Application - Snake

> Note: Still in progress...

This demo utilizes the good old Snake game to demonstrate how to stream events from a game to a Kafka cluster and then run real-time analytics on the events using Materialize.ß

## Architecture

![Gaming Event Streaming Application - Snake](https://imgur.com/PZt1FWO.png)

## Overview

The demo consists of the following components:

- [Materialize Cloud](https://materialize.com/)
- [JavaScript implementation of the Snake game](https://github.com/patorjk/JavaScript-Snake)
- [Node.js backend API that accepts game events and streams them to Kafka](./backend/)
- [Upstash Serverless Kafka cluster](https://upstash.com?utm_source=bobby)
- Deno/Node service to display the highscore list in real-time

## Prerequisites

- [Node.js](https://nodejs.org/)
- [Upstash Account](https://upstash.com/)
- [Materialize Cloud](https://materialize.com/cloud)

## Demo

You can find a live demo of this project here:

- [Snake game - Materialize Demo](https://snake.bobby.sh)

The leaderboard is updated in real-time and can be found here:

- [Snake game - Materialize Demo - Leaderboard](https://snake.bobby.sh/leaderboard)

## Materialize Cloud

### Connecting to Materialize Cloud

```
psql "postgres://YOUR_USERNAME_HERE@YOUR_MATERIALIZE_CLOUD_INSTANCE.aws.materialize.cloud:6875/materialize"
```

### Create a Materialize cluster

```sql
CREATE CLUSTER game REPLICAS (r1 (size='xsmall') );
SET cluster='game';
```

### Create your Materialize secrets:

Once you have your Materialize cluster up and running, you can create your secrets.

First head to your Upstash account and copy the username and password for your Serverless Kafka cluster.

After that, execute the following statements:

```sql
CREATE SECRET sasl_username AS 'pass-here';
CREATE SECRET sasl_password AS 'user-here';
```

### Create a connection

```sql
CREATE CONNECTION kafka
  FOR KAFKA
    BROKER 'YOUR_UPSTASH_KAFKA_CLUSTER_URL_HERE',
    SASL MECHANISMS = 'SCRAM-SHA-256',
    SASL USERNAME = SECRET sasl_username,
    SASL PASSWORD = SECRET sasl_password,
    SSL CERTIFICATE AUTHORITY = '';
```

### Create a Kafka Source

Using the Upstash Kafka details, create a Kafka source:

```sql
CREATE MATERIALIZED SOURCE game
  FROM KAFKA CONNECTION kafka
  TOPIC 'game-score'
  FORMAT JSON;
```

### Create a Materialized View

```sql
CREATE OR REPLACE VIEW scoure_board AS
    SELECT
        *
    FROM (
        SELECT
            (data->>'username')::string AS username,
            (data->>'score')::int AS score,
            (data->>'id')::string AS ud
        FROM (
            SELECT CAST(data AS jsonb) AS data
            FROM (
                SELECT convert_from(data, 'utf8') AS data
                FROM game
            )
        )
    );
```

Query the score board:

```sql
select * from scoure_board where score is not null order by score desc limit 100;
```

### SQL Script

Alternatively, you can run the `materialize.sql` SQL script to create the above resources in one go.

> Note that you need to first edit the `materialize.sql` script to replace the Upstash Kafka cluster URL, username and password to match your environment.

Once you've updated the details in the `materialize.sql` script, run the script:

```sql
psql "postgres://YOUR_USERNAME_HERE@YOUR_MATERIALIZE_CLOUD_INSTANCE.aws.materialize.cloud:6875/materialize" -f materialize.sql
```

## Helpful resources:

* [`CREATE SOURCE: PostgreSQL`](https://materialize.com/docs/sql/create-source/postgres/)
* [`CREATE SOURCE`](https://materialize.com/docs/sql/create-source/)
* [`CREATE VIEWS`](https://materialize.com/docs/sql/create-views)
* [`SELECT`](https://materialize.com/docs/sql/select)

## Community

If you have any questions or comments, please join the [Materialize Slack Community](https://materialize.com/s/chat)!