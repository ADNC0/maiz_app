import os
import psycopg2

def get_connection():
    return psycopg2.connect(
        host=os.getenv('DB_HOST', 'db'),
        port=os.getenv('DB_PORT', '5432'),
        user=os.getenv('DB_USER', 'user'),
        password=os.getenv('DB_PASSWORD', 'Maiz3606'),
        database=os.getenv('DB_NAME', 'maizdb')
    )
