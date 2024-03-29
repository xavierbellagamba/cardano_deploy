import json
import random

with open('topology.json', 'r') as f:
    data = json.load(f)

with open('./relay/mainnet-topology.json', 'r') as f:
    ref_prod = json.load(f)

with open('core_dns.txt', 'r') as f:
    ip = f.read()

with open('core_port.txt', 'r') as f:
    port = f.read()
    
# Add producing block and iohk node
topology = {
    "Producers": [
        {
            "addr": str(ip).split("\n")[0],
            "port": int(port),
            "valency": 1
        },
        {
            "addr": ref_prod["Producers"][0]["addr"],
            "port": int(ref_prod["Producers"][0]["port"]),
            "valency": int(ref_prod["Producers"][0]["valency"])
        }
    ]
}

# Reformat the entries to fit the expected format
for node in data["Producers"]:
    del node["continent"]
    del node["state"]
    node["valency"] = 1

# Add random relays
n_select = 25
i_select = random.sample(range(len(data["Producers"])), k=n_select)
for i in i_select:
    topology["Producers"].append(data["Producers"][i])

with open('topology_raw.json', 'w') as f:
  json.dump(topology, f, indent=2, separators=(",", ": "))
