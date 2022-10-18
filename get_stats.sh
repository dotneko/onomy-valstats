#!/usr/bin/env bash

DAEMON=onomyd
VALIDATORS_FULL="validators-full.json"
#VALIDATORS="validators.json"
VALIDATORS="validators.csv"
BLOCK_HEIGHT=$(onomyd q block | jq .block.header.height)
HEIGHT=${BLOCK_HEIGHT//\"/}
PARAM=$1
if [[ ${PARAM::8} == "--height" ]] || [[ ${PARAM::2} == '-h' ]]; then
        re='^[0-9]+$'
        if [[ $2 =~ $re ]]; then
		HEIGHT=$2
        fi
fi
echo $HEIGHT > blockheight.txt
HEIGHT_FLAG="--height $HEIGHT"
echo Getting validator full data =\> $VALIDATORS_FULL
$DAEMON q staking validators | yq -o=json > $VALIDATORS_FULL
echo Extracting validator moniker and addresses =\> $VALIDATORS
cat $VALIDATORS_FULL | jq -r '.validators[] | [.description.moniker,.operator_address] | @csv' > $VALIDATORS

while IFS=, read -r MONIKER ADDR; do
	MONIKER=${MONIKER//\"/}
	ADDR=${ADDR//\"/}
	echo Processing $MONIKER at $HEIGHT
	./get_delegates.sh $ADDR $HEIGHT_FLAG
done <$VALIDATORS
