import pandas as pd
from sqlalchemy import create_engine

# Filepath to the CSV file
file_path = "/Users/drkp4/Downloads/UNSW-NB15_1_col.csv"

# PostgreSQL connection string
connection_string = "postgresql+psycopg2://user:password@localhost:5432/network_traffic_dw?connect_timeout=10&sslmode=prefer"

# Load the CSV into a pandas DataFrame
try:
    df = pd.read_csv(file_path)

    # Inspect the data (optional)
    print("Sample Data:")
    print(df.head())

    # Create a database engine
    engine = create_engine(connection_string)

    # Load the data into the staging table
    table_name = "staging_connections"
    schema_name = "dw"
    
    df.to_sql(table_name, engine, schema=schema_name, if_exists="replace", index=False)
    print(f"Table {schema_name}.{table_name} created and data loaded successfully!")

except Exception as e:
    print("An error occurred:", e)
