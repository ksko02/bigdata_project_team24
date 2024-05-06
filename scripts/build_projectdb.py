'''
Python script that builds a relational database via PostgreSQL
'''

import os
from pprint import pprint
import psycopg2 as psql


# Read password from secrets file
file = os.path.join("secrets", ".psql.pass")
with open(file, "r", encoding="utf-8") as file:
    password = file.read().rstrip()

# build connection string
conn_string = f"host=hadoop-04.uni.innopolis.ru port=5432 user=team24 \
          dbname=team24_projectdb password={password}"

# Connect to the remote dbms
with psql.connect(conn_string, encoding="utf-8") as conn:
    # Create a cursor for executing psql commands
    cur = conn.cursor()

    # Read the commands from the file and execute them.
    with open(os.path.join("sql", "drop_tables.sql"), encoding="utf-8") as file:
        content = file.read()
        cur.execute(content)
    conn.commit()

    # Read the commands from the file and execute them.
    with open(os.path.join("sql", "create_tables.sql"), encoding="utf-8") as file:
        content = file.read()
        cur.execute(content)
    conn.commit()

    # Read the commands from the file and execute them.
    with open(os.path.join("sql", "import_data.sql"), encoding="utf-8") as file:
        command = file.readlines()
        with open(os.path.join("data", "metaverse_transactions_dataset.csv"),
		  "r", encoding="utf-8") as dataset:
            cur.copy_expert(command[0], dataset)
    # If the sql statements are CRUD then you need to commit the change
    conn.commit()

    pprint(conn)
    cur = conn.cursor()
    # Read the sql commands from the file
    with open(os.path.join("sql", "test_database.sql"), encoding="utf-8") as file:
        commands = file.readlines()
        for command in commands:
            cur.execute(command)
            # Read all records and print them
            pprint(cur.fetchall())
