from table.product import *
from dbconnection import *
from project_config import *

config=ProjectConfig()
db = DbConnection(config)
receipt_table = ProductTable(db)
receipt_table.create()
receipt_table.insert_csv("../products.csv")
# receipt_table.drop()
