import logging
import os
from time import sleep, time

import pika
import psycopg2
import redis

check_timeout: int = int(os.getenv("POSTGRES_CHECK_TIMEOUT", 30))
check_interval: int = int(os.getenv("POSTGRES_CHECK_INTERVAL", 1))
interval_unit = "second" if check_interval == 1 else "seconds"

# PostgreSQL Config
pg_config = {
    "dbname": os.getenv("POSTGRES_DATABASE", "unknown"),
    "user": os.getenv("POSTGRES_USER", "unknown"),
    "password": os.getenv("POSTGRES_PASSWORD", ""),
    "host": os.getenv("DATABASE_URL", "unknown"),
}

# Redis Config
redis_host = os.getenv("REDIS_HOST", "localhost")
redis_port = int(os.getenv("REDIS_PORT", 6379))

# RabbitMQ Config
rabbit_host = os.getenv("RABBITMQ_HOST", "localhost")
rabbit_port = int(os.getenv("RABBITMQ_PORT", 5672))


start_time = time()
logger = logging.getLogger()
logger.setLevel(logging.WARNING)
logger.addHandler(logging.StreamHandler())


def pg_isready(host, user, password, dbname):
    while time() - start_time < check_timeout:
        try:
            conn = psycopg2.connect(**vars())
            logger.info("Postgres is ready! ✨ 💅")
            conn.close()
            return True
        except psycopg2.OperationalError:
            logger.info(
                f"Postgres isn't ready. Waiting for {check_interval} {interval_unit}..."
            )
            sleep(check_interval)

    logger.error(f"We could not connect to Postgres within {check_timeout} seconds.")
    return False


def redis_isready(host, port):
    while time() - start_time < check_timeout:
        try:
            r = redis.Redis(host=host, port=port)
            if r.ping():
                logger.info("Redis is ready! ✨ 💅")
                return True
        except redis.ConnectionError:
            logger.info(
                f"Redis isn't ready. Waiting for {check_interval} {interval_unit}..."
            )
            sleep(check_interval)
    logger.error(f"Could not connect to Redis within {check_timeout} seconds.")
    return False


def rabbitmq_isready(host, port):
    while time() - start_time < check_timeout:
        try:
            connection = pika.BlockingConnection(
                pika.ConnectionParameters(host=host, port=port)
            )
            logger.info("RabbitMQ is ready! ✨ 💅")
            connection.close()
            return True
        except pika.exceptions.AMQPConnectionError:
            logger.info(
                f"RabbitMQ isn't ready. Waiting for {check_interval} {interval_unit}..."
            )
            sleep(check_interval)
    logger.error(f"Could not connect to RabbitMQ within {check_timeout} seconds.")
    return False


# Check services
pg_isready(**pg_config)  # type: ignore
redis_isready(redis_host, redis_port)
rabbitmq_isready(rabbit_host, rabbit_port)
