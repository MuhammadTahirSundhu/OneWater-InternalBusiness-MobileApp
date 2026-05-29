import psycopg2
import os

CONN_STR = "postgresql://postgres.yvqkzrcddoulgrqstkhe:onewaterpakistan!!!!@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres"
SQL_FILE = r"c:\Users\tahir\Desktop\OneWater\OneWaterBusinessMobileApp\supabase\migrations\001_initial_schema.sql"

def run_migration():
    print("Connecting to Supabase Database...")
    conn = psycopg2.connect(CONN_STR)
    conn.autocommit = True
    cur = conn.cursor()
    
    print("Reading SQL Migration...")
    with open(SQL_FILE, "r", encoding="utf-8") as f:
        sql = f.read()
        
    print("Executing SQL Migration...")
    cur.execute(sql)
    
    print("Reloading PostgREST schema cache...")
    cur.execute("NOTIFY pgrst, 'reload schema';")
    
    cur.close()
    conn.close()
    print("✅ Migration applied successfully!")

if __name__ == "__main__":
    run_migration()
