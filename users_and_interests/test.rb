require 'yaml'

data = YAML.load_file("data/users.yml")

p data[:jamy][:interests]