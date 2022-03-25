#!/usr/bin/env bash 

# Execute at user root level
# Run with the -i flag (interactive)

# Define run config
CURRENT_PATH="$PWD"

NODE="CORE" # NODE="RELAY"

PLEDGE=100000000
COST=340000000
MARGIN=0.02

CABAL_REPO="https://downloads.haskell.org/~cabal/cabal-install-3.6.2.0/"
CABAL_INSTALL="cabal-install-"
CABAL_VERSION="3.6.2.0"
CABAL_EXT="-x86_64-linux-deb10.tar.xz"

CARDANO_TAG="1.34.0"

NETWORK_NAME="testnet-magic 1097911063"
NETWORK_LVL="testnet" # or "mainnet"
IP_ADDR="0.0.0.0"
PORT="3001"

RELAY_IP="0.0.0.0"
RELAY_PORT="3002"

if [ NODE = "CORE" ]
then
  FOLDER="core"
elif [ NODE = "RELAY" ]
then
  FOLDER="relay"
fi

POOL_NAME="test"
POOL_TCKR="TTTT"
POOL_DESCR="test pool on testnet"
POOL_HOME="SomeAddress"
POOL_META_URL="someotheraddress.com"

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
# mkdir -p ~/$FOLDER
# mkdir -p ~/keysnaddresses

# # Get topology files
# cd ~/$FOLDER
# wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/$NETWORK_LVL-config.json
# wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/$NETWORK_LVL-byron-genesis.json
# wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/$NETWORK_LVL-shelley-genesis.json
# wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/$NETWORK_LVL-alonzo-genesis.json
# wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/$NETWORK_LVL-topology.json
# cd CURRENT_PATH

# Change to tmux (final run -end of the file to launch the app- with systemd)
# Remove the non-verbosity
# Start the node in a background process
#cardano-node run \
#  --topology ~/$FOLDER/$NETWORK_LVL-topology.json \
#  --database-path ~/$FOLDER/db \
#  --socket-path ~/$FOLDER/db/node.socket \
#  --host-addr $IP_ADDR \
#  --port $PORT \
#  --config ~/$FOLDER/$NETWORK_LVL-config.json &> /dev/null &
#disown

echo "Node started successfully, waiting for the socket to be created"
#sleep 10

# Make accessible and dave the node socket path in the environment variables
#echo -e "export CARDANO_NODE_SOCKET_PATH=\"~/$FOLDER/db/node.socket\"" >> ~/.bashrc
source ~/.bashrc
#chmod 777 ~/$FOLDER/db/node.socket

###########################################################
###########################################################
# THIS IS WHERE RELAY AND CORE ARE DIFFERENTIATED
###########################################################
###########################################################
#Relay needs to be parametrized via the typology file and then launched.
#More ops for core node

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
  python $CURRENT_PATH/scripts/get_curr_load.py
  P=$( cat curr_load.txt )
  printf "Cardano network loaded at %f%%\n" $P
  rm curr_tip.json
  rm curr_load.json
done

# Check if funds arrived
cardano-cli query utxo \
  --address $(cat ~/keysnaddresses/payment.addr) \
  --testnet-magic 1097911063 >> curr_utxo.txt
python $CURRENT_PATH/scripts/get_curr_bal.py
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
  python $CURRENT_PATH/scripts/get_curr_bal.py
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
python $CURRENT_PATH/scripts/get_staking_deposit.py
STK_DPST=$( cat staking_deposit.txt )
rm staking_deposit.txt

# Get current slot for TTL
cardano-cli query tip --$NETWORK_NAME >> curr_tip.json
python $CURRENT_PATH/scripts/get_curr_slot.py
SLOT=$( cat curr_slot.txt )
SLOT =$( expr $SLOT + 2000 )
rm curr_tip.json
rm curr_slot.txt

# Get utxo and index and balance
cardano-cli query utxo \
  --address $(cat ~/keysnaddresses/payment.addr) \
  --$NETWORK_NAME >> curr_utxo.txt
python $CURRENT_PATH/scripts/get_curr_utxo_ix.py
UTXOIX=$( cat curr_utxo_ix.txt )
python $CURRENT_PATH/scripts/get_curr_bal.py
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
python $CURRENT_PATH/scripts/get_fee.py
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


if [ $NODE = "RELAY" ]
then
  echo "Basic installation for the relay node completed"
  echo "Please shit down the cardano-node process running in the background using the kill <PID> command"
  echo "Next, its typology needs to be set up"
elif [ $NODE = "CORE" ]
then
  echo "Starting the core registration"

  # Generate cold keys
  cd ~/keysnaddresses
  cardano-cli node key-gen \
    --cold-verification-key-file cold.vkey \
    --cold-signing-key-file cold.skey \
    --operational-certificate-issue-counter-file cold.counter

  # Generate pool verfification key
  cardano-cli node key-gen-VRF \
    --verification-key-file vrf.vkey \
    --signing-key-file vrf.skey

  # Generate KES
  cardano-cli node key-gen-KES \
    --verification-key-file kes.vkey \
    --signing-key-file kes.skey

  # Get the KES period
  cd ~
  cp ~/$NODE/$NETWORK_LVL-shelley-genesis.json ~/genesis_tmp.json
  python $CURRENT_PATH/scripts/get_kes.py
  KES_P=$( cat kes_period.txt )
  rm genesis_tmp.json
  rm kes_period.txt

  # Get current slot
  cardano-cli query tip --$NETWORK_NAME >> curr_tip.json
  python $CURRENT_PATH/scripts/get_curr_slot.py
  SLOT=$( cat curr_slot.txt )
  rm curr_tip.json
  rm curr_slot.txt

  # Current kes epoch
  KES_EP=$( expr $SLOT / $KES_P )

  # Generate operational certificate
  cd ~/keysnaddresses
  cardano-cli node issue-op-cert \
    --kes-verification-key-file kes.vkey \
    --cold-signing-key-file cold.skey \
    --operational-certificate-issue-counter cold.counter \
    --kes-period KES_EP \ 
    --out-file node.cert

  # Generate pool metadata json
  cd $CURRENT_PATH
  if [ -f pool_metadata.json ]
  then
    rm pool_metadata.json
  fi
  echo -e "{" >> pool_metadata.json
  echo -e "\t\"name\": \"$POOL_NAME\"," >> pool_metadata.json
  echo -e "\t\"description\": \"$POOL_DESCR\"," >> pool_metadata.json
  echo -e "\t\"ticker\": \"$POOL_TCKR\"," >> pool_metadata.json
  echo -e "\t\"homepage\": \"$POOL_HOME\"" >> pool_metadata.json
  echo -e "}" >> pool_metadata.json

  # Get the hash of it
  cardano-cli stake-pool metadata-hash --pool-metadata-file pool_metadata.json >> hash.txt
  HASH=$( cat hash.txt )
  rm hash.txt

  # Generate stake pool certificate
  cd ~/keysnaddresses
  cardano-cli stake-pool registration-certificate \
    --cold-verification-key-file cold.vkey \
    --vrf-verification-key-file vrf.vkey \
    --pool-pledge $PLEDGE \
    --pool-cost $COST \
    --pool-margin $MARGIN \
    --pool-reward-account-verification-key-file stake.vkey \
    --pool-owner-stake-verification-key-file stake.vkey \
    --$NETWORK_NAME \
    --pool-relay-ipv4 $RELAY_IP \
    --pool-relay-port $RELAY_PORT \
    --metadata-url $POOL_META_URL \
    --metadata-hash $HASH \
    --out-file pool-registration.cert
    
  # Generate the pledge certificate
  cardano-cli stake-address delegation-certificate \
    --stake-verification-key-file stake.vkey \
    --cold-verification-key-file cold.vkey \
    --out-file delegation.cert

  # Get current balance, utxo and ix
  cardano-cli query utxo \
    --address $(cat ~/keysnaddresses/payment.addr) \
    --$NETWORK_NAME >> curr_utxo.txt
  python $CURRENT_PATH/scripts/get_curr_utxo_ix.py
  UTXOIX=$( cat curr_utxo_ix.txt )
  python $CURRENT_PATH/scripts/get_curr_bal.py
  BAL=$( cat curr_bal.txt )
  rm curr_bal.txt
  rm curr_utxo.txt
  rm curr_utxo_ix.txt

  # Build the raw transaction
  cardano-cli transaction build-raw \
    --tx-in \
    --tx-out $(cat payment.addr)+0 \
    --invalid-hereafter 0 \
    --fee 0 \
    --out-file tx.draft \
    --certificate-file pool-registration.cert \
    --certificate-file delegation.cert

  # Get the pool deposit from protocol.json
  cardano-cli query protocol-parameters \
    --$NETWORK_NAME \
    --out-file protocol.json
  python $CURRENT_PATH/scripts/get_pool_deposit.py
  POOL_DPST=$( cat pool_deposit.txt )
  rm pool_deposit.txt

  # Calculate the fees
  cardano-cli transaction calculate-min-fee \
    --tx-body-file tx.draft \
    --tx-in-count 1 \
    --tx-out-count 1 \
    --witness-count 3 \
    --byron-witness-count 0 \
    --$NETWORK_NAME \
    --protocol-params-file protocol.json >> fee_raw.txt
  python $CURRENT_PATH/scripts/get_fee.py
  FEE=$( cat fee.txt )
  rm fee_raw.txt
  rm fee.txt

  # Calculate final balance and TTL
  SLOT=$( $SLOT + 3000 )
  FIN_BAL=$( expr BAL - POOL_DPST -  )

  # Build final transaction
  cardano-cli transaction build-raw \
    --tx-in $UTXOIX \
    --tx-out $(cat payment.addr)+FIN_BAL \
    --invalid-hereafter $SLOT \
    --fee $FEE \
    --out-file tx.raw \
    --certificate-file pool-registration.cert \
    --certificate-file delegation.cert

  # Sign transaction
  cardano-cli transaction sign \
    --tx-body-file tx.raw \
    --signing-key-file payment.skey \
    --signing-key-file stake.skey \
    --signing-key-file cold.skey \
    --$NETWORK_NAME \
    --out-file tx.signed

  # Submit transaction
  cardano-cli transaction submit \
    --tx-file tx.signed \
    --$NETWORK_NAME

  # Wait a few minutes and test existence of the pool
  echo "The system will wait for 5 minutes before checking the registration of the pool on the network"
  sleep 300
  cardano-cli stake-pool id --cold-verification-key-file cold.vkey --output-format "hex"

fi





