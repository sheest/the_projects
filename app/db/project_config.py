import os
from dotenv import load_dotenv

# Загружаем переменные из .env
load_dotenv()

class ProjectConfig:
    def __init__(self):
        self.dbname = os.getenv('DB_NAME')
        # print(self.dbname)
        self.user = os.getenv('DB_USER')
        self.password = os.getenv('DB_PASSWORD')
        self.host = os.getenv('DB_HOST')
        print(self.host)
        self.port = os.getenv('DB_PORT')
        self.dbtableprefix = os.getenv('DB_TABLE_PREFIX')