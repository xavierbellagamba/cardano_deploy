import json

with open('protocol.json', 'r') as f:
    data = json.load(f)

staking_dpst = data["stakeAddressDeposit"]

with open('staking_deposit.txt', 'w') as f:
  f.write(staking_dpst)