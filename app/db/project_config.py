import yaml

class ProjectConfig:
    def __init__(self):
        with open('config.yaml') as f:
            config = yaml.safe_load(f)
            self.dbname = config['dbname']
            self.user = config['user']
            self.password = config['password']
            self.host = config['host']
            self.port = config['port']
            self.dbtableprefix = config['dbtableprefix']