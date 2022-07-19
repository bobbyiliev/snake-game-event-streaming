-- Update the variables accordingly:
\set UPSTASH_KAFKA_CLUSTER YOUR_KAFKA_CLUSTER_NAME
\set KAFKA_USERNAME YOUR_KAFKA_USERNAME
\set KAFKA_PASSWORD YOUR_KAFKA_PASSWORD
-- Set topics
\set SCORE_COUNT_KAFKA_TOPIC score-count
\set GAME_SCORE_KAFKA_TOPIC game-score
-- Set the cluster size and name
\set CLUSTER_NAME demo
\set CLUSTER_SIZE xsmall

-- Create a cluster
CREATE CLUSTER :CLUSTER_NAME REPLICAS (r1 (SIZE=:'CLUSTER_SIZE') );
SET cluster=:'CLUSTER_NAME';

-- Create secrets
CREATE SECRET sasl_username AS :'KAFKA_USERNAME';
CREATE SECRET sasl_password AS :'KAFKA_PASSWORD';

-- Create a connection
CREATE CONNECTION kafka
  FOR KAFKA
    BROKER :'UPSTASH_KAFKA_CLUSTER',
    SASL MECHANISMS = 'SCRAM-SHA-256',
    SASL USERNAME = SECRET sasl_username,
    SASL PASSWORD = SECRET sasl_password;

-- Create a source
CREATE MATERIALIZED SOURCE score_count_topic
  FROM KAFKA CONNECTION kafka
  TOPIC :'SCORE_COUNT_KAFKA_TOPIC'
  FORMAT BYTES;

CREATE MATERIALIZED SOURCE game_scoure_topic
  FROM KAFKA CONNECTION kafka
  TOPIC :'GAME_SCORE_KAFKA_TOPIC'
  FORMAT BYTES;

-- Create views
CREATE VIEW score_count_v AS
    SELECT
        *
    FROM (
        SELECT
            (data->>'username')::string AS username,
            (data->>'score')::string AS score,
            (data->>'id')::string AS id
        FROM (
            SELECT CAST(data AS jsonb) AS data
            FROM (
                SELECT convert_from(data, 'utf8') AS data
                FROM score_count_topic
            )
        )
    );
CREATE MATERIALIZED VIEW score_count_m AS
    SELECT
        count(*)
    FROM score_count_v;

-- Create a game score view
CREATE VIEW game_score_v AS
    SELECT
        *
    FROM (
        SELECT
            (data->>'username')::string AS username,
            (data->>'score')::string AS score,
            (data->>'id')::string AS id
        FROM (
            SELECT CAST(data AS jsonb) AS data
            FROM (
                SELECT convert_from(data, 'utf8') AS data
                FROM game_scoure_topic
            )
        )
    );

-- Create a game score materialized view to sort the scores by score value
CREATE MATERIALIZED VIEW game_score_m AS
    SELECT
        *
    FROM game_score_v ORDER BY score DESC
    LIMIT 100;
