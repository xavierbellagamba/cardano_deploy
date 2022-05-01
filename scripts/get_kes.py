import json

with open('genesis_tmp.json', 'r') as f:
    data = json.load(f)

kes_period = str(data["slotsPerKESPeriod"])

with open('kes_period.txt', 'w') as f:
  f.write(kes_period)