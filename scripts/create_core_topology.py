import json
import random

with open('topology.json', 'r') as f:
    data = json.load(f)

with open('relay_ip.txt', 'r') as f:
    ip = f.read()

with open('relay_port.txt', 'r') as f:
    port = f.read()

# Add producing block
topology = {
    "Producers": [
        {
            "addr": str(ip).split("\n")[0],
            "port": int(port),
            "valency": 1
        }
    ]
}

with open('topology_raw.json', 'w') as f:
  json.dump(topology, f)
