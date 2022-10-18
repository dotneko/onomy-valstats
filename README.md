# onomy-valstats
Simple scripts to calculate validator delegation statistics for Onomy

## Installation

Install dependences:

`pip install -r requirements.txt`

## Usage

**Requires a running Onomy daemon**

Run bash script to retrieve data:

`./get_stats.sh`

* Retrieves list of validators => `validators.csv`
* Queries delegations for each validator and saves as `.csv` file
* Optional `--height <block-height>` parameter can be added for specific block height

Run python script to compute statistics:

`python3 compute_stats.py`

