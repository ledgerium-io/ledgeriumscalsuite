#!/bin/bash

# I was told on github that parity cannot be faster than 5 seconds blocktime:
BLOCKTIME=5

FOLDER=networks/repos/paritytech_parity-deploy
GETBACK=../../..


# allows downgrading local parity installation:
PARITY_LOCAL_REMOVE=false
# PARITY_LOCAL_REMOVE=true

# fallback if no argument given:
# PARITY_VERSION=v2.2.3
PARITY_VERSION=v1.11.11

if [ $# -eq 0 ]
  then
    echo "No arguments supplied, assuming parity $PARITY_VERSION"
else
    PARITY_VERSION=$1
    echo "Using parity $PARITY_VERSION"
fi

# possibly remove an existing parity first, because downgrade not allowed by parity-deploy
if [ "$PARITY_LOCAL_REMOVE" = true ]; then
    echo remove existing local parity
    sudo mv $(which parity) $(which parity)_BACKUP
fi

cd $FOLDER

# is this always needed?
sudo ./clean.sh

# patch for issue 76
# ! important, must not be run as root !
# mkdir -p data
# echo patched for issue 76

# run ./parity-deploy.sh with ARGS
./parity-deploy.sh -r $PARITY_VERSION $PARITY_ARGS

# now manipulate the output of that script; 
# to call the right version, and with the right blocktime, see issue 60
sed -i 's/parity:stable/parity:'$PARITY_VERSION'/g' docker-compose.yml
echo patched docker-compose.yml file to use parity $PARITY_VERSION 

if [ "$PARITY_CONSENSUS" = "aura" ]; then
    jq ".engine.authorityRound.params.stepDuration = $BLOCKTIME" deployment/chain/spec.json > tmp; mv tmp deployment/chain/spec.json
    echo patched for issue 60: stepDuration to $BLOCKTIME
fi

# patch for issue 92
# not sure at which version this was changed, for now assuming v1 --> v2
if [[ "$PARITY_VERSION" < "v2" ]]; then
    sed -i 's/user:\ parity/user:\ root/g' docker-compose.yml
    echo patched for issue 92
fi

cp deployment/$FIRST_NODE/password $GETBACK/hammer/account-passphrase.txt
echo copied password

# start network:
# docker-compose up

cd $GETBACK

