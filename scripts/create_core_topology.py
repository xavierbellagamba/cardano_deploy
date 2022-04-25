import json
import os.path as path

with open('topology.json', 'r') as f:
    data = json.load(f)

with open('relay_dns.txt', 'r') as f:
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

# Check for second relay config and if existing, adding it
if path.exists('relay_dns_2.txt'):
    with open('relay_dns_2.txt', 'r') as f:
        ip_2 = f.read()

    with open('relay_port_2.txt', 'r') as f:
        port_2 = f.read()

    topology["Producers"].append({
        "addr": str(ip_2).split("\n")[0],
        "port": int(port_2),
        "valency": 1}
    )

with open('topology_raw.json', 'w') as f:
  json.dump(topology, f, indent=2, separators=(",", ": "))
