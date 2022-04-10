import json

with open('curr_tip.json', 'r') as f:
    data = json.load(f)

curr_load = str(int(float(data["syncProgress"])))

with open('curr_load.txt', 'w') as f:
  f.write(curr_load)