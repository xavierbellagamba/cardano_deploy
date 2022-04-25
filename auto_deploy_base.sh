#!/usr/bin/env bash 

# Execute at user root level
# Run with the -i flag (interactive) and within tmux

############################################################
# SET THE NODE PARAMETERS
############################################################

# Node type 
NODE="CORE" # "CORE" or "RELAY"

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
sleep 5400

# Make accessible and dave the node socket path in the environment variables
echo -e "export CARDANO_NODE_SOCKET_PATH=\"~/$FOLDER/db/node.socket\"" >> ~/.bashrc
chmod 777 ~/$FOLDER/db/node.socket
source ~/.bashrc
