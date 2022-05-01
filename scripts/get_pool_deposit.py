import json

with open('protocol.json', 'r') as f:
    data = json.load(f)

pool_dpst = str(data["stakePoolDeposit"])

with open('pool_deposit.txt', 'w') as f:
  f.write(pool_dpst)