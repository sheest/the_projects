import psycopg2

class DbConnection:

    def __init__(self, config): 
        self.dbname = config.dbname
        self.user = config.user
        self.password = config.password
        self.host = config.host
        self.prefix = config.dbtableprefix
        self.port = config.port
        self.conn = psycopg2.connect(dbname = self.dbname,
                                    user = self.user, 
                                    password = self.password,
                                    host = self.host,
                                    port=self.port)
