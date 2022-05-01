# Pool security

## Infrastructure security
- AWS console must be protected by a 24 character long password

### Relay node
- SSH key must be stored on a cold storage

### Core node
- Enable communication only with the relay nodes
- When connection is required, connect with SSH
- SSH key must be stored on a cold storage
- Only the three following files should be on the machine:
    - kes.skey
    - node.cert
    - vrf.skey

## Staking pool security (keys)
- All other keys, addresses and certificates must be stored on a cold storage
- Cold keys must always be remove from connected infra

## Cold storage
- Have three copies in three different locations
- Encrypt the storages with 16 character long password