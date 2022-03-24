#!/usr/bin/env bash 

# Execute at user root level
# Run with the -i flag (interactive)

# Define run config
CURRENT_PATH="$PWD"

CABAL_REPO="https://downloads.haskell.org/~cabal/cabal-install-3.6.2.0/"
CABAL_INSTALL="cabal-install-"
CABAL_VERSION="3.6.2.0"
CABAL_EXT="-x86_64-linux-deb10.tar.xz"

CARDANO_TAG="1.34.0"

NETWORK_NAME="testnet-magic 1097911063"
NETWORK_LVL="testnet"
IP_ADDR="0.0.0.0"
PORT="3001"

# # Get dependencies
# sudo apt-get update -y
# sudo apt-get upgrade -y
# sudo apt-get dist-upgrade -y
# sudo apt-get autoremove -y
# sudo apt-get install automake build-essential pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev make g++ tmux git jq wget libncursesw5 libtool autoconf -y

# # Get and setup Cabal
# wget $CABAL_REPO$CABAL_INSTALL$CABAL_VERSION$CABAL_EXT
# tar -xf $CABAL_INSTALL$CABAL_VERSION$CABAL_EXT
# rm $CABAL_INSTALL$CABAL_VERSION$CABAL_EXT
# mkdir -p ~/.local
# mkdir -p ~/.local/bin
# mv cabal ~/.local/bin/
# echo -e "\n# Added for Cardano node runtime\nexport PATH=\"~/.local/bin:$PATH\"" >> ~/.bashrc
# source ~/.bashrc
# cabal update
# cabal --version

# # Install GHC
# # Install file requires modifications for automation purposes
# curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org > hkl.sh

# sed -i 's+</dev/tty+ +g' hkl.sh
# sed -i 's+read -r+read -p+g' hkl.sh

# sh hkl.sh << HEREDOC
# $(sleep 2)
# $echo
# A
# N
# N
# $echo
# HEREDOC

# reset
# source ~/.bashrc
# echo "a\n"
# ghcup install ghc 8.10.7
# echo "b\n"
# ghcup install cabal 3.6.2.0
# ghcup set ghc 8.10.7
# ghcup set cabal 3.6.2.0

# # Prep the builds
# mkdir -p ~/cardano
# mkdir -p ~/cardano/src

# # Get and install libsodium
# cd ~/cardano/src
# git clone https://github.com/input-output-hk/libsodium
# cd libsodium
# git checkout 66f017f1
# ./autogen.sh
# ./configure
# make
# sudo make install

# echo -e "export LD_LIBRARY_PATH=\"/usr/local/lib:$LD_LIBRARY_PATH\"" >> ~/.bashrc
# echo -e "export PKG_CONFIG_PATH=\"/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH\"" >> ~/.bashrc
# source ~/.bashrc

# # Get Cardano repo
# cd ~/cardano/src
# git clone https://github.com/input-output-hk/cardano-node.git
# cd cardano-node
# git fetch --all --recurse-submodules --tags
# git checkout tags/$CARDANO_TAG

# # Install Cardano
# cabal configure --with-compiler=ghc-8.10.7

# echo "package cardano-crypto-praos" >>  cabal.project.local
# echo "  flags: -external-libsodium-vrf" >>  cabal.project.local

# cabal build all

# cp -p "$(./scripts/bin-path.sh cardano-node)" ~/.local/bin/
# cp -p "$(./scripts/bin-path.sh cardano-cli)" ~/.local/bin/

# cardano-cli --version
# cardano-node --version

# # Create the folder structure and move files
# mkdir -p ~/relay
# mkdir -p ~/keysnaddresses

# # Get topology files
# cd ~/relay
# wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/$NETWORK_LVL-config.json
# wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/$NETWORK_LVL-byron-genesis.json
# wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/$NETWORK_LVL-shelley-genesis.json
# wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/$NETWORK_LVL-alonzo-genesis.json
# wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/$NETWORK_LVL-topology.json
# cd CURRENT_PATH

# Start the node in a background process
#cardano-node run \
#  --topology ~/relay/$NETWORK_LVL-topology.json \
#  --database-path ~/relay/db \
#  --socket-path ~/relay/db/node.socket \
#  --host-addr $IP_ADDR \
#  --port $PORT \
#  --config ~/relay/$NETWORK_LVL-config.json &> /dev/null &
#disown

echo "Node started successfully, waiting for the socket to be created"
#sleep 10

# Make accessible and dave the node socket path in the environment variables
#echo -e "export CARDANO_NODE_SOCKET_PATH=\"~/relay/db/node.socket\"" >> ~/.bashrc
source ~/.bashrc
#chmod 777 ~/relay/db/node.socket

# Generate keys and addresses
cardano-cli address key-gen \
  --verification-key-file ~/keysnaddresses/payment.vkey \
  --signing-key-file ~/keysnaddresses/payment.skey

cardano-cli stake-address key-gen \
  --verification-key-file ~/keysnaddresses/stake.vkey \
  --signing-key-file ~/keysnaddresses/stake.skey

cardano-cli address build \
  --payment-verification-key-file ~/keysnaddresses/payment.vkey \
  --stake-verification-key-file ~/keysnaddresses/stake.vkey \
  --out-file ~/keysnaddresses/payment.addr \
  --$NETWORK_NAME

cardano-cli stake-address build \
  --stake-verification-key-file ~/keysnaddresses/stake.vkey \
  --out-file ~/keysnaddresses/stake.addr \
  --$NETWORK_NAME

# Test address and node
cardano-cli query utxo --address $(cat ~/keysnaddresses/payment.addr) --$NETWORK_NAME
cardano-cli query tip --$NETWORK_NAME

# Request funds from FAUCET or transfer ADA from own wallet
echo "While the blockchain is loading, request funds from the Faucet for testnet or transfer ADA for mainnet"
P=0.0
while [ $P < 99.9 ]
do
  sleep 900
  cardano-cli query tip --$NETWORK_NAME >> curr_tip.json
  python $PWD/scripts/get_curr_load.py
  P=$( cat curr_load.txt )
  printf "Cardano network loaded at %f%%\n" $P
  rm curr_tip.json
  rm curr_load.json
done

# Check if funds arrived
cardano-cli query utxo \
  --address $(cat ~/keysnaddresses/payment.addr) \
  --testnet-magic 1097911063 >> curr_utxo.txt
python $PWD/scripts/get_curr_bal.py
FUND=$( cat curr_bal.txt )
rm curr_bal.json
rm curr_utxo.json
while [ FUND < 0.1 ]
do
  echo "Funds have not arrived yet. Checking in two minutes."
  sleep 120
  cardano-cli query utxo \
    --address $(cat ~/keysnaddresses/payment.addr) \
    --testnet-magic 1097911063 >> curr_utxo.txt
  python $PWD/scripts/get_curr_bal.py
  FUND=$( cat curr_bal.txt )
  rm curr_bal.json
  rm curr_utxo.json
done
echo "Funds have arrived. Able to proceed."

# Registration of the staking capability
# Generate the staking certificate
cardano-cli stake-address registration-certificate \
  --stake-verification-key-file ~/keysnaddresses/stake.vkey \
  --out-file ~/keysnaddresses/stake.cert

# Get the protocol parameters and extract staking registration deposit
cardano-cli query protocol-parameters \
  --$NETWORK_NAME \
  --out-file protocol.json
python $PWD/scripts/get_staking_deposit.py
STK_DPST=$( cat staking_deposit.txt )
rm staking_deposit.txt

# Get current slot for TTL
cardano-cli query tip --$NETWORK_NAME >> curr_tip.json
python $PWD/scripts/get_curr_slot.py
SLOT=$( cat curr_slot.txt )
SLOT =$( expr $SLOT + 2000 )
rm curr_tip.json
rm curr_slot.txt

# Get utxo and index and balance
cardano-cli query utxo \
  --address $(cat ~/keysnaddresses/payment.addr) \
  --$NETWORK_NAME >> curr_utxo.txt
python $PWD/scripts/get_curr_utxo_ix.py
UTXOIX=$( cat curr_utxo_ix.txt )
python $PWD/scripts/get_curr_bal.py
BAL=$( cat curr_bal.txt )
rm curr_bal.txt
rm curr_utxo.txt
rm curr_utxo_ix.txt

# Build transaction draft for staking certificate registration
cardano-cli transaction build-raw \
  --tx-in $UTXOIX \
  --tx-out $(cat ~/keysnaddresses/payment.addr)+0 \
  --invalid-hereafter 0 \
  --fee 0 \
  --out-file tx.draft \
  --certificate-file ~/keysnaddresses/stake.cert

# Calculate fee
cardano-cli transaction calculate-min-fee \
  --tx-body-file tx.draft \
  --tx-in-count 1 \
  --tx-out-count 1 \
  --witness-count 2 \
  --byron-witness-count 0 \
  --$NETWORK_NAME \
  --protocol-params-file protocol.json >> fee_raw.txt
python $PWD/scripts/get_fee.py
FEE=$( cat fee.txt )
rm fee_raw.txt
rm fee.txt

# Calculate final balance
FIN_BAL=$( expr $BAL - $FEE - $STK_DPST )

# Build final transaction
cardano-cli transaction build-raw \
  --tx-in $UTXOIX \
  --tx-out $(cat ~/keysnaddresses/payment.addr)+$FIN_BAL \
  --invalid-hereafter $SLOT \
  --fee $FEE \
  --out-file tx.raw \
  --certificate-file ~/keysnaddresses/stake.cert

#Signing transaction
cardano-cli transaction sign \
  --tx-body-file tx.raw \
  --signing-key-file ~/keysnaddresses/payment.skey \
  --signing-key-file ~/keysnaddresses/stake.skey \
  --$NETWORK_NAME \
  --out-file tx.signed

#Submitting transaction
cardano-cli transaction submit \
  --tx-file tx.signed \
  --$NETWORK_NAME
rm tx.signed
rm tx.raw
rm tx.draft

echo "Staking address and certificate registered"

###########################################################
###########################################################
# THIS IS WHERE RELAY AND CORE ARE DIFFERENTIATED
###########################################################
###########################################################
