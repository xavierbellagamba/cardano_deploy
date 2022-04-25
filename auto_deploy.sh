#!/usr/bin/env bash 

# Execute at user root level
# Run with the -i flag (interactive) and within tmux

############################################################
# SET THE NODE PARAMETERS
############################################################

# Node type 
NODE="RELAY" # "CORE" or "RELAY"

# Pool parameters (only for core node)
PLEDGE=50000000000
COST=340000000
MARGIN=0.025
POOL_NAME="versorium"
POOL_TCKR="VRSM"
POOL_DESCR="The versorium.io pool"
POOL_HOME="https://versorium.io"
POOL_META_URL="https://tinyurl.com/versorium"

# Cabal-related parameters
CABAL_REPO="https://downloads.haskell.org/~cabal/cabal-install-3.6.2.0/"
CABAL_INSTALL="cabal-install-"
CABAL_VERSION="3.6.2.0"
CABAL_EXT="-x86_64-linux-deb10.tar.xz"

# Cardano version
CARDANO_TAG="1.34.0"

# Deployment network
NETWORK_NAME="mainnet" # "mainnet" or "testnet-magic 1097911063"
NETWORK_LVL="mainnet" # "mainnet" or "testnet"
IP_ADDR="0.0.0.0"
PORT="6000"

# Relay IP (only necessary for the core node)
# Needs to be set up manually on AWS as Elastic IPv4
N_RELAY=2 # 1 or 2
RELAY_DNS="ec2-18-194-10-11.eu-central-1.compute.amazonaws.com"
RELAY_PORT="6000"
RELAY_DNS_2="ec2-52-57-255-147.eu-central-1.compute.amazonaws.com"
RELAY_PORT_2="6000"

# Core IP
# Needs to be set up manually on AWS as Elastic IPv4
CORE_DNS="ec2-18-156-17-168.eu-central-1.compute.amazonaws.com"
CORE_PORT="6000"

if [[ "$NODE" == "CORE" ]]
then
  FOLDER="core"
elif [[ "$NODE" == "RELAY" ]]
then
  FOLDER="relay"
fi

CURRENT_PATH="$PWD"


############################################################
# CHECK IF METADATA READY
############################################################

if [[ "$NODE" == "CORE" ]]
then
  echo "________________________"
  echo
  echo "CHECK IF METADATA READY"
  echo "________________________"
  if [ -f pool_metadata.json ]
  then
    echo "File existing. Able to proceed. Make sure it is online before finalizing the install"
  else
    echo "File non-existing. Please make sure pool_metadata.json exists where the script is being run"
    return 1
  fi
fi


############################################################
# INSTALL THE DEPENDENCIES
############################################################

echo "________________________"
echo
echo "INSTALL ALL DEPENDENCIES"
echo "________________________"

# Get dependencies
echo "Installing updates and base dependencies"
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt-get autoremove -y
sudo apt-get install automake build-essential pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev make g++ tmux git jq wget libncursesw5 libtool python autoconf -y
echo "Updates and base dependencies installed"

# Get and setup Cabal
echo "Installing Cabal"
wget $CABAL_REPO$CABAL_INSTALL$CABAL_VERSION$CABAL_EXT
tar -xf $CABAL_INSTALL$CABAL_VERSION$CABAL_EXT
rm $CABAL_INSTALL$CABAL_VERSION$CABAL_EXT
mkdir -p ~/.local
mkdir -p ~/.local/bin
mv cabal ~/.local/bin/
echo -e "\n# Added for Cardano node runtime\nexport PATH=\"~/.local/bin:$PATH\"" >> ~/.bashrc
source ~/.bashrc
cabal update
cabal --version

# Install GHC
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org > hkl.sh

# Install file requires modifications for automation purposes
sed -i 's+</dev/tty+ +g' hkl.sh
sed -i 's+read -r+read -p+g' hkl.sh

sh hkl.sh << HEREDOC
$(sleep 2)
$echo
A
N
N
$echo
HEREDOC

reset
source ~/.bashrc
ghcup install ghc 8.10.7
ghcup install cabal 3.6.2.0
ghcup set ghc 8.10.7
ghcup set cabal 3.6.2.0
echo "Cabal installed"

# Prep the builds
mkdir -p ~/cardano
mkdir -p ~/cardano/src

# Get and install libsodium
echo "Installing libsodium"
cd ~/cardano/src
git clone https://github.com/input-output-hk/libsodium
cd libsodium
git checkout 66f017f1
./autogen.sh
./configure
make
sudo make install

echo -e "export LD_LIBRARY_PATH=\"/usr/local/lib:$LD_LIBRARY_PATH\"" >> ~/.bashrc
echo -e "export PKG_CONFIG_PATH=\"/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH\"" >> ~/.bashrc
source ~/.bashrc
echo "Libsodium installed"

cd $CURRENT_PATH
rm hkl.sh


############################################################
# INSTALL THE CARDANO
############################################################

echo "________________________"
echo
echo "INSTALL CARDANO"
echo "________________________"

# Get Cardano repo
echo "Download the node install binary"
cd ~/cardano/src
git clone https://github.com/input-output-hk/cardano-node.git
cd cardano-node
git fetch --all --recurse-submodules --tags
git checkout tags/$CARDANO_TAG
echo "Node install binary downloaded"

# Install Cardano
echo "Installing the Cardano node and cli"
cabal configure --with-compiler=ghc-8.10.7

echo "package cardano-crypto-praos" >>  cabal.project.local
echo "  flags: -external-libsodium-vrf" >>  cabal.project.local

cabal build all

cp -p "$(./scripts/bin-path.sh cardano-node)" ~/.local/bin/
cp -p "$(./scripts/bin-path.sh cardano-cli)" ~/.local/bin/

cardano-cli --version
cardano-node --version
echo "Node and cli installed"

# Create the folder structure and move files
mkdir -p ~/$FOLDER
mkdir -p ~/keysnaddresses

# Get topology files
echo "Getting base typology files"
cd ~/$FOLDER
wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/$NETWORK_LVL-config.json
wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/$NETWORK_LVL-byron-genesis.json
wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/$NETWORK_LVL-shelley-genesis.json
wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/$NETWORK_LVL-alonzo-genesis.json
wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/$NETWORK_LVL-topology.json
cd $CURRENT_PATH
echo "Base typology files downloaded"


############################################################
# RUN THE NODE IN THE BACKGROUND TO COMPLETE THE SETUP
############################################################

echo "________________________"
echo
echo "DOWNLOAD THE BLOCKCHAIN"
echo "________________________"

# If existing copy pre-synched files
if [[ -d "./presync" ]]
then
  mkdir -p $CURRENT_PATH/$FOLDER
  mv ./presync $CURRENT_PATH/$FOLDER/db
fi

# Make accessible and dave the node socket path in the environment variables
echo -e "export CARDANO_NODE_SOCKET_PATH=\"$HOME/$FOLDER/db/node.socket\"" >> ~/.bashrc
chmod 777 $HOME/$FOLDER/db/node.socket
source $HOME/.bashrc

# Start the node in a background process with tmux
NODE_RUN="cardano-node run \
  --topology ~/$FOLDER/$NETWORK_LVL-topology.json \
  --database-path ~/$FOLDER/db \
  --socket-path ~/$FOLDER/db/node.socket \
  --host-addr $IP_ADDR \
  --port $PORT \
  --config ~/$FOLDER/$NETWORK_LVL-config.json"

tmux new -d -s vanilla_run
tmux send-keys -t vanilla_run "$NODE_RUN" Enter

echo "Node started successfully, waiting for the socket to be created (45 mins)"
sleep 7200

###########################################################
# THIS IS WHERE RELAY AND CORE ARE DIFFERENTIATED
###########################################################

if [[ "$NODE" == "RELAY" ]]
then

  echo "________________________"
  echo
  echo "BLOCKCHAIN DOWNLOADING"
  echo "________________________"
  echo "This could take a while (12-24 hours depending on network amd machine performances)"

  P=0
  while (( P < 100 ))
  do
    sleep 900
    cardano-cli query tip --$NETWORK_NAME >> curr_tip.json
    python3 $CURRENT_PATH/scripts/get_curr_load.py
    P=$( cat curr_load.txt )
    echo "Cardano network loaded at $P%"
    rm curr_tip.json
    rm curr_load.txt
  done

  echo "Basic installation for the relay node completed, shutting down the node vanilla run"
  tmux send-keys -t vanilla_run C-c
  tmux kill-session -t vanilla_run
  echo "Node shut down"


  ############################################################
  # SETUP RELAY TOPOLOGY
  ############################################################

  echo "________________________"
  echo
  echo "SETUP RELAY TOPOLOGY"
  echo "________________________"

  # Get list from repo
  echo "Getting the latest full topology file"
  cd $CURRENT_PATH
  wget https://explorer.cardano-mainnet.iohk.io/relays/topology.json
  echo "Topology file downloaded"

  # Random selection of other relay nodes and add core node to the list (1st item)
  echo "Set up relay node topology file"
  echo $CORE_DNS >> core_dns.txt
  echo $CORE_PORT >> core_port.txt
  python3 $CURRENT_PATH/scripts/create_relay_topology.py
  cp $CURRENT_PATH/topology_raw.json ~/$FOLDER/$NETWORK_LVL-topology.json
  rm core_port.txt
  rm core_dns.txt
  rm topology_raw.json
  rm topology.json
  echo "Topology file of the relay node set up"


  ############################################################
  # SETUP GLIVEVIEW
  ############################################################
  
  echo "________________________"
  echo
  echo "SETUP gLiveView"
  echo "________________________"

  mkdir -p $CURRENT_PATH/gLiveView
  cd $CURRENT_PATH/gLiveView
  echo "Download the dependencies and package"
  sudo apt-get install bc tcptraceroute -y
  curl -s -o gLiveView.sh https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/gLiveView.sh
  curl -s -o env https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/env
  chmod 755 gLiveView.sh
  echo "Dependencies downloaded and installed"

  echo "Change environment variables for gLiveView"
  # Network config
  sed -i "s+#CONFIG=\"\${CNODE_HOME}\/files\/config.json\"+CONFIG=\"$CURRENT_PATH\/$FOLDER\/$NETWORK_LVL-config.json\"+g" env
  # Socket
  sed -i "s+#SOCKET=\"\${CNODE_HOME}\/sockets\/node0.socket\"+SOCKET=\"$CURRENT_PATH\/$FOLDER\/db\/node.socket\"+g" env
  # Topology
  sed -i "s+#TOPOLOGY=\"\${CNODE_HOME}/files/topology.json\"+SOCKET=\"$CURRENT_PATH\/$FOLDER\/$NETWORK_LVL-topology.json\"+g" env
  # DB directory
  sed -i "s+#DB_DIR=\"\${CNODE_HOME}/db\"+SOCKET=\"$CURRENT_PATH\/$FOLDER\/db\"+g" env
  # Log directory
  mkdir -p $CURRENT_PATH/$FOLDER/logs
  sed -i "s+#LOG_DIR=\"\${CNODE_HOME}\/logs\"+LOG_DIR=\"$CURRENT_PATH\/$FOLDER\/logs\"+g" env
  # Port
  sed -i "s+#CNODE_PORT=6000+CNODE_PORT=$PORT+g" env
  # Cardano node path (relay or core folder)
  sed -i "s+#CNODE_HOME=\"\/opt\/cardano\/cnode\"+CNODE_HOME=$CURRENT_PATH\/$FOLDER+g" env
  # Cardano node binary
  sed -i "s+#CNODEBIN=\"\${HOME}\/.cabal\/bin\/cardano-node\"+CNODEBIN=\"\${HOME}\/.local\/bin\/cardano-node\"+g" env
  # Cardano CLI binary
  sed -i "s+#CCLI=\"\${HOME}\/.cabal\/bin\/cardano-cli\"+CCLI=\"\${HOME}\/.local\/bin\/cardano-cli\"+g" env
  echo "Variables updated"

  cd $CURRENT_PATH
  echo "alias glv=\"$CURRENT_PATH/gLiveView/gLiveView.sh\"" >> .bashrc
  echo "gLiveView available from the console using \"glv\""
  source ~/.bashrc


  ############################################################
  # RUN RELAY AS A SERVICE
  ############################################################

  echo "________________________"
  echo
  echo "RUN RELAY AS A SERVICE"
  echo "________________________"

  # Create and parametrize the systemd structure
  mkdir -p /etc/systemd
  mkdir -p /etc/systemd/system/

  # Create the service in systemd
  if [ -f /etc/systemd/system/cardano_relay.service ]
  then
    sudo rm /etc/systemd/system/cardano_relay.service
  fi

  # Generate cardano_relay_launch script
  echo "Generate the sh launch script"

  echo "#!/usr/bin/bash" >> $CURRENT_PATH/launch_script.sh
  echo "" >> $CURRENT_PATH/launch_script.sh
  echo "$HOME/.local/bin/$NODE_RUN" >> $CURRENT_PATH/launch_script.sh

  chmod +x $CURRENT_PATH/launch_script.sh
  echo "Launch script generated"

  # Generate the service file
  echo "Generate the systemd file"

  sudo bash -c "echo '[Unit]' >> /etc/systemd/system/cardano_relay.service"
  sudo bash -c "echo 'Description=Cardano relay node' >> /etc/systemd/system/cardano_relay.service"
  sudo bash -c "echo 'Wants=network-online.target' >> /etc/systemd/system/cardano_relay.service"
  sudo bash -c "echo 'After=network-online.target' >> /etc/systemd/system/cardano_relay.service"
  sudo bash -c "echo '' >> /etc/systemd/system/cardano_relay.service"
  sudo bash -c "echo '[Service]' >> /etc/systemd/system/cardano_relay.service"
  sudo bash -c "echo 'User=$USER' >> /etc/systemd/system/cardano_relay.service"
  sudo bash -c "echo 'Type=Simple' >> /etc/systemd/system/cardano_relay.service"
  sudo bash -c "echo 'WorkingDirectory=$CURRENT_PATH' >> /etc/systemd/system/cardano_relay.service"
  sudo bash -c "echo 'ExecStart=bash -c "$CURRENT_PATH/launch_script.sh"' >> /etc/systemd/system/cardano_relay.service"
  sudo bash -c "echo 'Restart=always' >> /etc/systemd/system/cardano_relay.service"
  sudo bash -c "echo 'RestartSec=5' >> /etc/systemd/system/cardano_relay.service"
  sudo bash -c "echo 'KillSignal=SIGINT' >> /etc/systemd/system/cardano_relay.service"
  sudo bash -c "echo 'RestartKillSignal=SIGINT' >> /etc/systemd/system/cardano_relay.service"
  sudo bash -c "echo 'TimeoutStopSec=300' >> /etc/systemd/system/cardano_relay.service"
  sudo bash -c "echo 'SyslogIdentifier=cardano-node' >> /etc/systemd/system/cardano_relay.service"
  sudo bash -c "echo '' >> /etc/systemd/system/cardano_relay.service"
  sudo bash -c "echo '[Install]' >> /etc/systemd/system/cardano_relay.service"
  sudo bash -c "echo 'WantedBy=multi-user.target' >> /etc/systemd/system/cardano_relay.service"
  sudo bash -c "echo '' >> /etc/systemd/system/cardano_relay.service"

  sudo chmod 644 /etc/systemd/system/cardano_relay.service
  echo "Systemd file generated"

  # Run the service
  echo "Launch the node as a service"
  sudo systemctl daemon-reload
  sudo systemctl enable cardano_relay
  sudo systemctl start cardano_relay

  # Check if service running
  systemctl status cardano_relay >> service_status_raw.txt
  python3 $CURRENT_PATH/scripts/get_service_status.py
  SRV_ST=$( cat service_status.txt )

  if [[ "$SRV_ST" == "active" ]]
  then
    echo "Installation and deployment of the relay node completed."
    echo "Relay node deployment completed!"
  else
    echo "Something failed. Node not running. Investigate"
  fi

  rm service_status_raw.txt
  rm service_status.txt

  echo "Launching gLiveView in tmux in 90 minutes"
  sleep 5400
  tmux new -d -s gliveview
  tmux send-keys -t gliveview "glv" Enter


  ############################################################
  # CRONJOB TO REGISTER THE RELAY
  ############################################################
  
  echo "________________________"
  echo
  echo "CRONJOB TO REGISTER"
  echo "________________________"

  # Create the topologyUpdater
  echo -e "#!/bin/bash" >> $CURRENT_PATH/topologyUpdater.sh
  echo -e "CNODE_LOG_DIR=\"$CURRENT_PATH/relay/logs\"" >> $CURRENT_PATH/topologyUpdater.sh
  echo -e "CNODE_PORT=6000" >> $CURRENT_PATH/topologyUpdater.sh
  echo -e "GENESIS_JSON=\"$CURRENT_PATH/relay/mainnet-shelley-genesis.json\"" >> $CURRENT_PATH/topologyUpdater.sh
  echo -e "export CARDANO_NODE_SOCKET_PATH=\"$CURRENT_PATH/relay/db/node.socket\"" >> $CURRENT_PATH/topologyUpdater.sh
  echo -e "export PATH=\"$CURRENT_PATH/.local/bin:${PATH}\"" >> $CURRENT_PATH/topologyUpdater.sh
  echo -e "NWMAGIC=\$(jq -r .networkMagic < \$GENESIS_JSON)" >> $CURRENT_PATH/topologyUpdater.sh
  echo -e "blockNo=\$( $CURRENT_PATH/.local/bin/cardano-cli query tip --mainnet | jq -r .block )" >> $CURRENT_PATH/topologyUpdater.sh
  echo -e "curl -s -f -4 \"https://api.clio.one/htopology/v1/?port=\${CNODE_PORT}&blockNo=\${blockNo}&valency=1&magic=\${NWMAGIC}\" | sudo tee -a $CURRENT_PATH/relay/logs/topologyUpdater_lastresult.json" >> $CURRENT_PATH/topologyUpdater.sh
  echo -e "" >> $CURRENT_PATH/topologyUpdater.sh
  chmod +x topologyUpdater.sh

  # Add its execution to crontab
  echo -e "16 * * * * $CURRENT_PATH/topologyUpdater.sh" >> $CURRENT_PATH/crontab-fragment.txt
  crontab -l | cat - $CURRENT_PATH/crontab-fragment.txt > $CURRENT_PATH/crontab.txt && crontab $CURRENT_PATH/crontab.txt
  rm $CURRENT_PATH/crontab-fragment.txt

  # Wait 5h for the relay to register
  sleep 18000

  # Write the topologyPuller
  echo -e "#!/bin/bash" >> $CURRENT_PATH/topologyPuller.sh
  echo -e "BLOCKPRODUCING_IP=$CORE_DNS" >> $CURRENT_PATH/topologyPuller.sh
  echo -e "BLOCKPRODUCING_PORT=$CORE_PORT" >> $CURRENT_PATH/topologyPuller.sh
  echo -e "curl -s -o $CURRENT_PATH/$NETWORK_LVL-topology.json \"https://api.clio.one/htopology/v1/fetch/?max=25&customPeers=\${BLOCKPRODUCING_IP}:\${BLOCKPRODUCING_PORT}:1|relays-new.cardano-mainnet.iohk.io:3001:2\"" >> $CURRENT_PATH/topologyPuller.sh

  # Execute the topologyPuller
  chmod +x $CURRENT_PATH/topologyPuller.sh
  bash $CURRENT_PATH/topologyPuller.sh

  # Restart the node
  sudo systemctl restart cardano_relay

  return 0


############################################################
# CORE NODE SETUP
############################################################
elif [ $NODE == "CORE" ]
then

  echo "________________________"
  echo
  echo "BLOCKCHAIN DOWNLOADING"
  echo "________________________"
  echo "This could take a while (4-12 hours depending on network amd machine performances)"
  echo "While the blockchain is loading, request funds from the Faucet for testnet or transfer ADA for mainnet"

  P=0
  while (( P < 100 ))
  do
    sleep 900
    cardano-cli query tip --$NETWORK_NAME >> curr_tip.json
    python3 $CURRENT_PATH/scripts/get_curr_load.py
    P=$( cat curr_load.txt )
    echo "Cardano network loaded at $P%"
    rm curr_tip.json
    rm curr_load.txt
  done

  echo "Basic installation for the core node completed."


  ############################################################
  # GENERATE KEYS, ACCOUNTS AND ADDRESSES
  ############################################################

  echo "________________________"
  echo
  echo "CREATE ADDRESSES & KEYS"
  echo "________________________"

  # Generate keys and addresses
  echo "Generate addresses"
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
  echo "Addresses generated"

  # Test address and node
  cardano-cli query utxo --address $(cat ~/keysnaddresses/payment.addr) --$NETWORK_NAME
  cardano-cli query tip --$NETWORK_NAME

  # Generate the staking certificate
  echo "Generate the staking certificate"
  cardano-cli stake-address registration-certificate \
    --stake-verification-key-file ~/keysnaddresses/stake.vkey \
    --out-file ~/keysnaddresses/stake.cert
  echo "Staking certificate generated"


  ############################################################
  # WAIT FOR THE FUNDS ARRIVAL
  ############################################################

  echo "________________________"
  echo
  echo "CHECK FOR FUNDS ARRIVAL"
  echo "________________________"

  # Check if funds arrived
  cardano-cli query utxo \
    --address $(cat ~/keysnaddresses/payment.addr) \
    --$NETWORK_NAME >> curr_utxo.txt
  python3 $CURRENT_PATH/scripts/get_curr_bal.py
  FUND=$( cat curr_bal.txt )
  echo "Current balance: $FUND Lovelace"
  rm curr_bal.json
  rm curr_utxo.json
  while (( FUND < 505000000 ))
  do
    echo "Funds have not arrived yet. Checking in two minutes."
    sleep 120
    cardano-cli query utxo \
      --address $(cat ~/keysnaddresses/payment.addr) \
      --$NETWORK_NAME >> curr_utxo.txt
    python3 $CURRENT_PATH/scripts/get_curr_bal.py
    FUND=$( cat curr_bal.txt )
    echo "Current balance: $FUND Lovelace"
    rm curr_bal.json
    rm curr_utxo.json
  done
  echo "Funds have arrived. Able to proceed."


  ############################################################
  # REGISTER THE STAKING CERTIFICATE
  ############################################################

  echo "________________________"
  echo
  echo "REGISTER STAKING CERT"
  echo "________________________"

  echo "Generate the transaction to register the staking certificate"
  # Get the protocol parameters and extract staking registration deposit
  cardano-cli query protocol-parameters \
    --$NETWORK_NAME \
    --out-file protocol.json
  python3 $CURRENT_PATH/scripts/get_staking_deposit.py
  STK_DPST=$( cat staking_deposit.txt )
  rm staking_deposit.txt

  # Get current slot for TTL
  cardano-cli query tip --$NETWORK_NAME >> curr_tip.json
  python3 $CURRENT_PATH/scripts/get_curr_slot.py
  SLOT=$( cat curr_slot.txt )
  ((SLOT = SLOT + 2000 ))
  rm curr_tip.json
  rm curr_slot.txt

  # Get utxo and index and balance
  cardano-cli query utxo \
    --address $(cat ~/keysnaddresses/payment.addr) \
    --$NETWORK_NAME >> curr_utxo.txt
  python3 $CURRENT_PATH/scripts/get_curr_utxo_ix.py
  UTXOIX=$( cat curr_utxo_ix.txt )
  python3 $CURRENT_PATH/scripts/get_curr_bal.py
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
  python3 $CURRENT_PATH/scripts/get_fee.py
  FEE=$( cat fee.txt )
  rm fee_raw.txt
  rm fee.txt

  # Calculate final balance
  (( FIN_BAL= BAL - FEE - STK_DPST ))

  # Build final transaction
  echo "Build, sign and submit the registration transaction"
  cardano-cli transaction build-raw \
    --tx-in $UTXOIX \
    --tx-out $(cat ~/keysnaddresses/payment.addr)+$FIN_BAL \
    --invalid-hereafter $SLOT \
    --fee $FEE \
    --out-file tx.raw \
    --certificate-file ~/keysnaddresses/stake.cert

  # Signing transaction
  cardano-cli transaction sign \
    --tx-body-file tx.raw \
    --signing-key-file ~/keysnaddresses/payment.skey \
    --signing-key-file ~/keysnaddresses/stake.skey \
    --$NETWORK_NAME \
    --out-file tx.signed

  # Submitting transaction
  cardano-cli transaction submit \
    --tx-file tx.signed \
    --$NETWORK_NAME
  rm tx.signed
  rm tx.raw
  rm tx.draft
  echo "Staking address and certificate registered"


  ############################################################
  # GENERATE THE POOL KEYS
  ############################################################

  echo "________________________"
  echo
  echo "GENERATE POOL KEYS"
  echo "________________________"

  echo "Generate the cold and KES keys"
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
  python3 $CURRENT_PATH/scripts/get_kes.py
  KES_P=$( cat kes_period.txt )
  rm genesis_tmp.json
  rm kes_period.txt
  echo "Cold and KES keys generated"


  ############################################################
  # GENERATE THE POOL CERTIFICATES
  ############################################################

  echo "________________________"
  echo
  echo "GENERATE POOL CERT"
  echo "________________________"

  echo "Generate the operational certificate"
  # Get current slot
  cardano-cli query tip --$NETWORK_NAME >> curr_tip.json
  python3 $CURRENT_PATH/scripts/get_curr_slot.py
  SLOT=$( cat curr_slot.txt )
  rm curr_tip.json
  rm curr_slot.txt

  # Current kes epoch
  (( KES_EP= SLOT / KES_P ))

  # Generate operational certificate
  cd ~/keysnaddresses
  cardano-cli node issue-op-cert \
    --kes-verification-key-file kes.vkey \
    --cold-signing-key-file cold.skey \
    --operational-certificate-issue-counter cold.counter \
    --kes-period $KES_EP \
    --out-file node.cert
  echo "Operational certificate generated"

  echo "Generate the pool and pledge certificates"
  cd $CURRENT_PATH
  # Get the hash of it
  cardano-cli stake-pool metadata-hash --pool-metadata-file pool_metadata.json >> hash.txt
  HASH=$( cat hash.txt )
  rm hash.txt

  # Generate stake pool certificate
  cd ~/keysnaddresses
  if (( N_RELAY == 2 ))
  then
    cardano-cli stake-pool registration-certificate \
      --cold-verification-key-file cold.vkey \
      --vrf-verification-key-file vrf.vkey \
      --pool-pledge $PLEDGE \
      --pool-cost $COST \
      --pool-margin $MARGIN \
      --pool-reward-account-verification-key-file stake.vkey \
      --pool-owner-stake-verification-key-file stake.vkey \
      --$NETWORK_NAME \
      --single-host-pool-relay $RELAY_DNS \
      --pool-relay-port $RELAY_PORT \
      --single-host-pool-relay $RELAY_DNS_2 \
      --pool-relay-port $RELAY_PORT_2 \
      --metadata-url $POOL_META_URL \
      --metadata-hash $HASH \
      --out-file pool-registration.cert
  else
    cardano-cli stake-pool registration-certificate \
      --cold-verification-key-file cold.vkey \
      --vrf-verification-key-file vrf.vkey \
      --pool-pledge $PLEDGE \
      --pool-cost $COST \
      --pool-margin $MARGIN \
      --pool-reward-account-verification-key-file stake.vkey \
      --pool-owner-stake-verification-key-file stake.vkey \
      --$NETWORK_NAME \
      --single-host-pool-relay $RELAY_DNS \
      --pool-relay-port $RELAY_PORT \
      --metadata-url $POOL_META_URL \
      --metadata-hash $HASH \
      --out-file pool-registration.cert
  fi
    
  # Generate the pledge certificate
  cardano-cli stake-address delegation-certificate \
    --stake-verification-key-file stake.vkey \
    --cold-verification-key-file cold.vkey \
    --out-file delegation.cert
  echo "Pool and pledge certificates generated"

  
  ############################################################
  # REGISTER STAKING POOL
  ############################################################

  echo "________________________"
  echo
  echo "REGISTER STAKING POOL"
  echo "________________________"

  echo "Generate the transaction to register the staking pool"
  # Get current balance, utxo and ix
  cardano-cli query utxo \
    --address $(cat ~/keysnaddresses/payment.addr) \
    --$NETWORK_NAME >> curr_utxo.txt
  python3 $CURRENT_PATH/scripts/get_curr_utxo_ix.py
  UTXOIX=$( cat curr_utxo_ix.txt )
  python3 $CURRENT_PATH/scripts/get_curr_bal.py
  BAL=$( cat curr_bal.txt )
  rm curr_bal.txt
  rm curr_utxo.txt
  rm curr_utxo_ix.txt

  # Build the raw transaction
  cardano-cli transaction build-raw \
    --tx-in $UTXOIX\
    --tx-out $(cat payment.addr)+0 \
    --invalid-hereafter 0 \
    --fee 0 \
    --certificate-file pool-registration.cert \
    --certificate-file delegation.cert \
    --out-file tx.draft

  # Get the pool deposit from protocol.json
  cardano-cli query protocol-parameters \
    --$NETWORK_NAME \
    --out-file protocol.json
  python3 $CURRENT_PATH/scripts/get_pool_deposit.py
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
  python3 $CURRENT_PATH/scripts/get_fee.py
  FEE=$( cat fee.txt )
  rm fee_raw.txt
  rm fee.txt

  # Get current slot
  cardano-cli query tip --$NETWORK_NAME >> curr_tip.json
  python3 $CURRENT_PATH/scripts/get_curr_slot.py
  SLOT=$( cat curr_slot.txt )
  rm curr_tip.json
  rm curr_slot.txt

  # Calculate final balance and TTL
  (( SLOT= SLOT + 3000 ))
  (( FIN_BAL= BAL - POOL_DPST - FEE ))

  # Build final transaction
  echo "Build, sign and submit the registration transaction"
  cardano-cli transaction build-raw \
    --tx-in $UTXOIX \
    --tx-out $(cat payment.addr)+$FIN_BAL \
    --invalid-hereafter $SLOT \
    --fee $FEE \
    --certificate-file pool-registration.cert \
    --certificate-file delegation.cert \
    --out-file tx.raw

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
  echo "Staking pool registered"


  ############################################################
  # SETUP CORE TOPOLOGY
  ############################################################

  echo "________________________"
  echo
  echo "SETUP CORE TOPOLOGY"
  echo "________________________"

  echo "Core node set up. Vanilla run of the node shutting down"
  tmux send-keys -t vanilla_run C-c
  tmux kill-session -t vanilla_run
  echo "Node shut down"

  # Get list from repo
  echo "Getting the latest full topology file"
  cd $CURRENT_PATH
  wget https://explorer.cardano-mainnet.iohk.io/relays/topology.json
  echo "Topology file downloaded"

  # Random selection of other relay nodes and add core node to the list (1st item)
  echo "Set up core node topology file"
  echo $RELAY_DNS >> relay_dns.txt
  echo $RELAY_PORT >> relay_port.txt
  if (( N_RELAY == 2 ))
  then
    echo $RELAY_DNS_2 >> relay_dns_2.txt
    echo $RELAY_PORT_2 >> relay_port_2.txt
  fi
  python3 $CURRENT_PATH/scripts/create_core_topology.py
  cp $CURRENT_PATH/topology_raw.json ~/$FOLDER/$NETWORK_LVL-topology.json
  rm relay_port.txt
  rm relay_dns.txt
  if (( N_RELAY == 2 ))
  then
    rm relay_port_2.txt
    rm relay_dns_2.txt
  fi
  rm topology_raw.json
  rm topology.json
  echo "Topology file of the core node set up"


  ############################################################
  # SETUP GLIVEVIEW
  ############################################################
  
  echo "________________________"
  echo
  echo "SETUP gLiveView"
  echo "________________________"

  mkdir -p $CURRENT_PATH/gLiveView
  cd $CURRENT_PATH/gLiveView
  echo "Download the dependencies and package"
  sudo apt-get install bc tcptraceroute -y
  curl -s -o gLiveView.sh https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/gLiveView.sh
  curl -s -o env https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/env
  chmod 755 gLiveView.sh
  echo "Dependencies downloaded and installed"

  echo "Change environment variables for gLiveView"
  # Network config
  sed -i "s+#CONFIG=\"\${CNODE_HOME}\/files\/config.json\"+CONFIG=\"$CURRENT_PATH\/$FOLDER\/$NETWORK_LVL-config.json\"+g" env
  # Socket
  sed -i "s+#SOCKET=\"\${CNODE_HOME}\/sockets\/node0.socket\"+SOCKET=\"$CURRENT_PATH\/$FOLDER\/db\/node.socket\"+g" env
  # Topology
  sed -i "s+#TOPOLOGY=\"\${CNODE_HOME}/files/topology.json\"+SOCKET=\"$CURRENT_PATH\/$FOLDER\/$NETWORK_LVL-topology.json\"+g" env
  # DB directory
  sed -i "s+#DB_DIR=\"\${CNODE_HOME}/db\"+SOCKET=\"$CURRENT_PATH\/$FOLDER\/db\"+g" env
  # Log directory
  mkdir -p $CURRENT_PATH/$FOLDER/logs
  sed -i "s+#LOG_DIR=\"\${CNODE_HOME}\/logs\"+LOG_DIR=\"$CURRENT_PATH\/$FOLDER\/logs\"+g" env
  # Port
  sed -i "s+#CNODE_PORT=6000+CNODE_PORT=$PORT+g" env
  # Cardano node path (relay or core folder)
  sed -i "s+#CNODE_HOME=\"\/opt\/cardano\/cnode\"+CNODE_HOME=$CURRENT_PATH\/$FOLDER+g" env
  # Cardano node binary
  sed -i "s+#CNODEBIN=\"\${HOME}\/.cabal\/bin\/cardano-node\"+CNODEBIN=\"\${HOME}\/.local\/bin\/cardano-node\"+g" env
  # Cardano CLI binary
  sed -i "s+#CCLI=\"\${HOME}\/.cabal\/bin\/cardano-cli\"+CCLI=\"\${HOME}\/.local\/bin\/cardano-cli\"+g" env
  echo "Variables updated"

  cd
  echo "alias glv=\"$CURRENT_PATH/gLiveView/gLiveView.sh\"" >> .bashrc
  echo "gLiveView available from the console using \"glv\""
  source ~/.bashrc


  ############################################################
  # RUN CORE NODE AS A SERVICE
  ############################################################

  echo "________________________"
  echo
  echo "RUN CORE AS A SERVICE"
  echo "________________________"

  # Create and parametrize the systemd structure
  mkdir -p /etc/systemd
  mkdir -p /etc/systemd/system/

  # Create the service in systemd
  if [ -f /etc/systemd/system/cardano_core.service ]
  then
    sudo rm /etc/systemd/system/cardano_core.service
  fi

  # Node run as a core node
  NODE_RUN="cardano-node run \
    --topology ~/$FOLDER/$NETWORK_LVL-topology.json \
    --database-path ~/$FOLDER/db \
    --socket-path ~/$FOLDER/db/node.socket \
    --host-addr $IP_ADDR \
    --port $PORT \
    --config ~/$FOLDER/$NETWORK_LVL-config.json \
    --shelley-kes-key ~/keysnaddresses/kes.skey \
    --shelley-vrf-key ~/keysnaddresses/vrf.skey \
    --shelley-operational-certificate ~/keysnaddresses/node.cert"

  # Generate cardano_core_launch script
  echo "Generate the sh launch script"

  echo "#!/usr/bin/bash" >> $CURRENT_PATH/launch_script.sh
  echo "" >> $CURRENT_PATH/launch_script.sh
  echo "$HOME/.local/bin/$NODE_RUN" >> $CURRENT_PATH/launch_script.sh

  chmod +x $CURRENT_PATH/launch_script.sh
  echo "Launch script generated"

  # Generate the service file
  echo "Generate the systemd file"

  sudo bash -c "echo '[Unit]' >> /etc/systemd/system/cardano_core.service"
  sudo bash -c "echo 'Description=Cardano core node' >> /etc/systemd/system/cardano_core.service"
  sudo bash -c "echo 'Wants=network-online.target' >> /etc/systemd/system/cardano_core.service"
  sudo bash -c "echo 'After=network-online.target' >> /etc/systemd/system/cardano_core.service"
  sudo bash -c "echo '' >> /etc/systemd/system/cardano_core.service"
  sudo bash -c "echo '[Service]' >> /etc/systemd/system/cardano_core.service"
  sudo bash -c "echo 'User=$USER' >> /etc/systemd/system/cardano_core.service"
  sudo bash -c "echo 'Type=Simple' >> /etc/systemd/system/cardano_core.service"
  sudo bash -c "echo 'WorkingDirectory=$CURRENT_PATH' >> /etc/systemd/system/cardano_core.service"
  sudo bash -c "echo 'ExecStart=bash $CURRENT_PATH/launch_script.sh' >> /etc/systemd/system/cardano_core.service"
  sudo bash -c "echo 'Restart=always' >> /etc/systemd/system/cardano_core.service"
  sudo bash -c "echo 'RestartSec=5' >> /etc/systemd/system/cardano_core.service"
  sudo bash -c "echo 'RemainAfterExit=true' >> /etc/systemd/system/cardano_core.service"
  sudo bash -c "echo 'KillSignal=SIGINT' >> /etc/systemd/system/cardano_core.service"
  sudo bash -c "echo 'RestartKillSignal=SIGINT' >> /etc/systemd/system/cardano_core.service"
  sudo bash -c "echo 'TimeoutStopSec=300' >> /etc/systemd/system/cardano_core.service"
  sudo bash -c "echo 'SyslogIdentifier=cardano-node' >> /etc/systemd/system/cardano_core.service"
  sudo bash -c "echo '' >> /etc/systemd/system/cardano_core.service"
  sudo bash -c "echo '[Install]' >> /etc/systemd/system/cardano_core.service"
  sudo bash -c "echo 'WantedBy=multi-user.target' >> /etc/systemd/system/cardano_core.service"
  sudo bash -c "echo '' >> /etc/systemd/system/cardano_core.service"

  sudo chmod 644 /etc/systemd/system/cardano_core.service
  echo "Systemd file generated"

  # Run the service
  echo "Launch the node as a service"
  sudo systemctl daemon-reload
  sudo systemctl enable cardano_core
  sudo systemctl start cardano_core

  # Check if service running
  systemctl status cardano_core >> service_status_raw.txt
  python3 $CURRENT_PATH/scripts/get_service_status.py
  SRV_ST=$( cat service_status.txt )

  if [[ "$SRV_ST" == "active" ]]
  then
    echo "Installation and deployment of the core node completed."
    echo "Core node deployment completed!"
  else
    echo "Something failed. Node not running. Investigate"
  fi

  rm service_status_raw.txt
  rm service_status.txt

  # Wait a few minutes and test existence of the pool
  echo "The system will wait for 120 minutes before checking the registration of the pool on the network"
  sleep 7200
  cardano-cli stake-pool id --cold-verification-key-file cold.vkey --output-format "hex" >> stakepoolid.txt
  cardano-cli query stake-snapshot --stake-pool-id $(cat stakepoolid.txt) --mainnet 

  echo "Launching gLiveView in tmux in 30 minutes"
  sleep 1800
  tmux new -d -s gliveview
  tmux send-keys -t gliveview "glv" Enter

  return 0
fi
