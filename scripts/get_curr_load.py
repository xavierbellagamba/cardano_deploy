import json

with open('curr_tip.json', 'r') as f:
    data = json.load(f)

curr_load = data["syncProgress"]

with open('curr_load.txt', 'w') as f:
  f.write(curr_load)