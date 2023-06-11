from flask import Flask, request, jsonify
import redis
from redis.exceptions import ResponseError
import os
import mysql.connector
from mysql.connector import Error
import time
import socket

app = Flask(__name__)

# Read Redis host from environment variable
redis_host = os.environ.get('REDIS_HOST', 'localhost')
# Read Redis port from environment variable
redis_port = int(os.environ.get('REDIS_PORT', 6379))
# Redis in cluseter or single mode
redis_cluster_env = os.environ.get('REDIS_CLUSTER', 'false')


# Read HTTP listening port from environment variable
http_port = int(os.environ.get('HTTP_PORT', 5080))

# Read redis queue from environment variable
redis_queue = os.environ.get('REDIS_QUEUE', 'count_queue')

print(f"Redis Host: {redis_host}")
print(f"Redis Port: {redis_port}")
print(f"Redis Queue: {redis_queue}")
print(f"Redis Cluster Client: {redis_cluster_env}")
print(f"HTTP Port: {http_port}")

# Read MySQL DB environment variables
db_host = os.environ.get('DB_HOST', 'localhost')
db_port = os.environ.get('DB_PORT', 3306)
db_user = os.environ.get('DB_USER', 'root')
db_password = os.environ.get('DB_PASSWORD', 'password')
db_name = os.environ.get('DB_NAME', 'your_database_name')

# Print the MySQL DB environment variables
print(f"DB Host: {db_host}")
print(f"DB Port: {db_port}")
print(f"DB User: {db_user}")
#print(f"DB Password: {db_password}")
print(f"DB Name: {db_name}")

# Connect to redis
def connect_to_redis(host, port, redis_cluster_env):
    if redis_cluster_env and redis_cluster_env.lower() == 'true':
        r = redis.RedisCluster(host=host, port=port, cluster_error_retry_attempts=10)
        print('Using Redis Cluster client')
    else:
        r = redis.Redis(host=host, port=port)
        print('Using Redis Non-Cluster Client')
    return r

# Push to redis with retry
def retry_rpush(redis_client, redis_queue, count_value, max_retries=50, retry_delay=5):
    for attempt in range(max_retries):
        try:
            redis_client.rpush(redis_queue, count_value)
            print(f"Successfully pushed count_value to: {redis_queue}")
            break  # If successful, exit the loop
        except redis.exceptions.RedisError as e:
            print(f"Failed to push count_value to: {redis_queue} (Attempt {attempt + 1})")
            print(f"Error: {str(e)}")
            print("Reconnecting to Redis...")
            redis_client = connect_to_redis(host=redis_host, port=redis_port, redis_cluster_env=redis_cluster_env)
            time.sleep(retry_delay)  # Wait before retrying

# Establish MySQL connection
db = None

while True:
    try:
        db = mysql.connector.connect(
            host=db_host,
            port=db_port,
            user=db_user,
            password=db_password,
            database=db_name
        )
        print("Connected to MySQL")
        break
    except Error as e:
        print(f"Error connecting to MySQL: {e}")
        print("Retrying in 5 seconds...")
        time.sleep(5)

@app.after_request
def add_cors_headers(response):
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = '*'
    return response

@app.route('/')
def stat():
    print("/ invoked")
    return '', 200

@app.route('/health')
def health():
    print("/health invoked")
    hostname = socket.gethostname()
    return jsonify({"status": "healthy", "message": "application is running without issues", "hostname": hostname})


@app.route('/count', methods=['GET', 'POST'])
def count():
    print("/count invoked")
    if request.method == 'POST':
        count_value = request.json.get('count')
        redis_client = connect_to_redis(host=redis_host, port=redis_port, redis_cluster_env=redis_cluster_env)
        # Retry rpush operation
        retry_rpush(redis_client, redis_queue, count_value)
        return jsonify({"message": "Value added to Redis queue", "value": count_value}), 201
    else:
        try:
            # Read count values from MySQL
            cursor = db.cursor()

            # Overall count
            overall_count_query = "SELECT COUNT(*) FROM `count`"
            cursor.execute(overall_count_query)
            overall_count = cursor.fetchone()[0]

            # Latest count value
            latest_count_query = "SELECT count_value FROM `count` ORDER BY id DESC LIMIT 1"
            cursor.execute(latest_count_query)
            #check if no rows retuned from mysql database, return 0 if resultset is empty
            latest_count_result = cursor.fetchone()
            if latest_count_result is not None:
                latest_count_value = latest_count_result[0]
            else:
                latest_count_value = 0

            db.commit()

            hostname = socket.gethostname()
            return jsonify({"rows_count": overall_count, "latest_value": latest_count_value, "hostname": hostname}), 200
        except Error as e:
            print(f"Error executing MySQL query: {e}")
            return jsonify({"message": "Error retrieving count from MySQL"}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=http_port)
