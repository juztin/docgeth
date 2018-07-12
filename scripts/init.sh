#!/bin/sh


PASSWORD="${PASSWORD:-password}"
PASSWORD_FILE="${PASSWORD_FILE:-/data/password}"
ACCOUNT_NUM="${ACCOUNT_NUM:-10}"
BLOCK_DIFFICULTY="${BLOCK_DIFFICULTY:-0x400}"
BLOCK_GASLIMIT="${BLOCK_GASLIMIT:-0x8000000}"

# ------------------------------------------------------------------------------

ACCOUNT_ID=""

# Creates an account, and sets the id to `accountId`.
#
# @param 1: password for the account
createAccount() {
	#  Receives:
	#    ```
	#    Address: {1f057006cb657678b6ae849b954154c00b4a1f0c}
	#    ```
	#  Sets:
	#    accountId="1f057006cb657678b6ae849b954154c00b4a1f0c"
	#
	data=`geth --datadir /data/blockchain account new --password "$1"`
	ACCOUNT_ID=`echo $data | awk -F"[{}]" '{print $2;}'`
}

# Creates {n} number of accounts.
#
# @param 1: Number of accounts to create.
# @param 2: The password to use for the accounts. (TODO: allow passing an array for unique passwords?)
createAccounts() {
	# @param 1
	# Creates `n` number of accounts
	for i in $(seq 1 $ACCOUNT_NUM); do
		createAccount "$2"
		ACCOUNTS=$ACCOUNTS'"0x'$ACCOUNT_ID'": { "balance": "999000000000000000000" },'$'\n    '
	done
	# Remove trailing comma
	ACCOUNTS=${ACCOUNTS%,*}
}

# Creates the genesis Geth configuration file.
#
# @param 1: The name of the genesis file.
createGenesis() {
	echo '{
  "config": {
        "chainId": 10,
        "homesteadBlock": 0,
        "eip150Block": 0,
        "eip150Hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
        "eip155Block": 0,
        "eip158Block": 0,
        "ByzantiumBlock": 0,
        "ethash": {}
    },
  "coinbase"   : "0x0000000000000000000000000000000000000000",
  "difficulty" : '\"$BLOCK_DIFFICULTY\"',
  "gasLimit"   : '\"$BLOCK_GASLIMIT\"',
  "extraData"  : "",
  "mixhash"    : "0x0000000000000000000000000000000000000000000000000000000000000000",
  "nonce"      : "0x0000000000000042",
  "parentHash" : "0x0000000000000000000000000000000000000000000000000000000000000000",
  "timestamp"  : "0x00",
  "alloc": {
    '"$ACCOUNTS"'
  }
}' > /data/genesis.json
}

# Initializes the new Geth blockchain, using the previsously created genesis file.
#
# @param 1: The blockchain directory.
# @param 2: The genesis file.
initNode() {
	geth \
		--datadir /data/blockchain \
		init /data/genesis.json
}


# ------------------------------------------------------------------------------

# ----- Create Password File
echo "Creating password file: \"$PASSWORD_FILE\""
echo "$PASSWORD" > "$PASSWORD_FILE"

# ----- Create Accounts
echo "Creating $ACCOUNT_NUM Accounts..."
createAccounts $ACCOUNT_NUM "$PASSWORD_FILE";
echo "------------------------------------"
echo "    $ACCOUNTS"
echo "------------------------------------"

# ----- Create Genesis File
echo "Creating Genesis..."
createGenesis

# ----- Initialize Node
echo "Initializing Node..."
initNode
