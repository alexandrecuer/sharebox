config_path="#{Rails.root}/config/config.yml"
#MAIN = YAML.load_file("#{config_path}")["main"]
#FOLDERS_MSG = YAML.load_file("#{config_path}")["folders_msg"]
#USERS_MSG = YAML.load_file("#{config_path}")["users_msg"]
#ASSETS_MSG = YAML.load_file("#{config_path}")["assets_msg"]
#POLLS_MSG = YAML.load_file("#{config_path}")["polls_msg"]
#SATISFACTIONS_MSG = YAML.load_file("#{config_path}")["satisfactions_msg"]
#SHARED_FOLDERS_MSG = YAML.load_file("#{config_path}")["shared_folders_msg"]
CONF=YAML.load_file(config_path)["conf"]
message="COLIBRI VERSION GOING TO RUN is #{CONF["version"]}"
#light blue : 36
#pink: 35
#blue : 34
#yellow : 33
#green : 32
#red : 31
#color_code=33
#puts("\e[#{color_code}m#{message}\e[0m")
puts("\e[33m#{message}\e[0m")