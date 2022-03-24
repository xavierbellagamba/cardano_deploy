import json

with open('curr_tip.json', 'r') as f:
    data = json.load(f)

curr_slot = data["slot"]

with open('curr_slot.txt', 'w') as f:
  f.write(curr_slot)