#!/usr/bin/env bash
set -e

if [ $# -eq 0 ]; then
	echo Usage:
	echo ./get_delegates.sh valoper-address [-h block_height]
	exit 1
fi
VALOPER=$1
PARAM=$2
if [[ ${VALOPER::12} != "onomyvaloper" ]]; then
	echo Invalid valoper address. Aborting
	exit 1
fi
if [[ ${PARAM::8} == "--height" ]] || [[ ${PARAM::2} == '-h' ]]; then
	re='^[0-9]+$'
	if [[ $3 =~ $re ]]; then
		HEIGHT_FLAG="--height $3"
	else
		HEIGHT_FLAG=""
	fi
else
	HEIGHT_FLAG=""
fi
PAGE=1
JSON_P1=${VALOPER:5}_$PAGE.json
CSVFILE=${VALOPER:5}_dlgs.csv

echo Getting delegates for $VALOPER $HEIGHT_FLAG

# Get 1st page
echo Getting 1st page
onomyd q staking delegations-to $VALOPER --page $PAGE $HEIGHT_FLAG --count-total -o json > $JSON_P1

# Calculate pages
TOTAL=$(( $(jq -r '.pagination.total' $JSON_P1) + 0 ))
PAGES=$(( $TOTAL / 100 + 1 ))
echo Total delegators: $TOTAL, Pages: $PAGES

# Skip if total delegators empty
if [[ $TOTAL -eq 0 ]]; then
	echo No delegators for $VALOPER. Aborting
	rm $JSON_P1
	exit
fi
echo Parsing 1st page to $CSVFILE
jq -r '.delegation_responses[] | [.delegation.delegator_address, .balance.amount] | @csv' $JSON_P1 > $CSVFILE
rm $JSON_P1

# Loop through pages, append to CSV
for PAGE in $(seq 2 $PAGES);
do
	echo Processing page $PAGE
	onomyd q staking delegations-to $VALOPER --page $PAGE --count-total -o json | jq -r '.delegation_responses[] | [.delegation.delegator_address, .balance.amount] | @csv' >> $CSVFILE
	DELEGATES_ADDED=$(wc -l < $CSVFILE)
	echo Cumulative delegates added: $DELEGATES_ADDED
done
echo Total $DELEGATES_ADDED/$TOTAL delegates added to CSV file
