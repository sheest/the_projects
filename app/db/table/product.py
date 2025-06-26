from  dbconnection import *
import os

class ProductTable:
    def __init__(self, db_conn: DbConnection):
        self.conn = db_conn.conn
        self.prefix = db_conn.prefix
        self.table_name = "products"
        self.columns = {
            'Name': 'TEXT',
            'Cost': 'NUMERIC',
            'Quantity': 'TEXT',
            'Date': 'TIMESTAMP'
        }

    def create(self):
        fields_sql = ",\n".join([f"{col} {datatype}" for col, datatype in self.columns.items()])
        query = f"""
        CREATE TABLE IF NOT EXISTS {self.table_name} (
            {fields_sql}
        );
        """
        with self.conn.cursor() as cur:
            cur.execute(query)
            self.conn.commit()

    def insert_csv(self, filepath):
        if not os.path.exists(filepath):
            raise FileNotFoundError(f"Файл '{filepath}' не найден.")
        
        with self.conn.cursor() as cur, open(filepath,  encoding='utf-8') as file:
            next(file)  
            cur.copy_from(file, self.table_name, sep=';')
            self.conn.commit()

    def drop(self):
        query = f"DROP TABLE IF EXISTS {self.table_name};"
        with self.conn.cursor() as cur:
            cur.execute(query)
            self.conn.commit()
