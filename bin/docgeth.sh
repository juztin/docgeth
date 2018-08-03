#!/bin/sh
#

DOCKER_IMAGE="minty/docgeth"

ACCOUNT_BALANCE="${DOCGETH_BALANCE:-9999}"
ACCOUNT_NUM="${DOCGETH_ACCOUNTS:-1}"
ACCOUNT_PASSWORD="${DOCGETH_PASSWORD:-password}"


# -----------------------------------------------------------------------------


DOCKER_PARAMS=('-it' '--rm')
DOCKER_VOLUMES=()
DOCKER_COMMAND=()

# Adds a bind mount volume param to the Docker command
#
# @param 1: source path, within the current working directory
# @param 2: destination path
add_volume () {
	DOCKER_VOLUMES+=("--volume $(pwd)/$1:$2")
}

# Adds a bind mount volume for `.docgeth` at `/data`, within the container
#
add_docgeth_volume () {
	DOCKER_VOLUMES+=("--volume $(pwd)/.docgeth:/data")
}

# ------ Docker

# Format and print the Docker command to `stdout`
#
print_docker_command () {
	printf "docker run \\\\\n"
	printf "	%s \\\\\n" "${DOCKER_PARAMS[@]}"
	printf "	%s \\\\\n" "${DOCKER_VOLUMES[@]}"
	printf "	%s %s\n" "$DOCKER_IMAGE" "${DOCKER_COMMAND[@]}"
}

# Executes the Docker command, or prints the command to `stdout` when `DOCGETH_VERBOSE` is true
#
dock () {
	if [ "$DOCGETH_VERBOSE" = true ]; then
		print_docker_command
		exit 0
	fi
docker run \
	${DOCKER_PARAMS[@]} \
	${DOCKER_VOLUMES[@]} \
	$DOCKER_IMAGE ${DOCKER_COMMAND[@]}
}

# ------ Commands

# Executes Geth, passing all arguments
#
# @params: arguments to pass to Geth
command_geth () {
	add_docgeth_volume ".docgeth"
	DOCKER_COMMAND+=$@
}

# Initializes a new blockchain
#
command_init () {
	add_docgeth_volume ".docgeth"
	DOCKER_PARAMS+=("--entrypoint init.sh")
	DOCKER_PARAMS+=("--env DOCGETH_BALANCE=$ACCOUNT_BALANCE")
	DOCKER_PARAMS+=("--env DOCGETH_ACCOUNTS=$ACCOUNT_NUM")
	DOCKER_PARAMS+=("--env DOCGETH_PASSWORD=$ACCOUNT_PASSWORD")

	if [ -n "$DOCGETH_DIFFICULTY" ]; then
		DOCKER_PARAMS+=("--env DOCGETH_DIFFICULTY=$DOCGETH_DIFFICULTY")
	fi

	if [ -n "$DOCGETH_GASLIMIT" ]; then
		DOCKER_PARAMS+=("--env DOCGETH_GASLIMIT=$DOCGETH_GASLIMIT")
	fi
}

# Decrypts, and prints, a private key
#
# @param 1: the public key to retrieve the private key of
# @param 2: the password used to decrypt the private key
command_pkey () {
	add_docgeth_volume ".docgeth"
	DOCKER_PARAMS+=("--entrypoint gethpkey")
	DOCKER_COMMAND+=$@
	DOCKER_COMMAND+=" --path /data/blockchain/keystore"
}

# Starts a geth instance, using the `.docgeth` directory created during `init`
#
command_run () {
	add_docgeth_volume
	#add_volume ".docgeth/.ethereum" "/root/.ethereum"
	DOCKER_PARAMS+=('--publish 30303:30303')
	DOCKER_PARAMS+=('--publish 8545:8545')
	DOCKER_COMMAND+=' --datadir /data/blockchain'
	DOCKER_COMMAND+=' --networkid 10'
	DOCKER_COMMAND+=' --nat any'
	DOCKER_COMMAND+=' --nodiscover'
	DOCKER_COMMAND+=' --rpc'
	DOCKER_COMMAND+=' --rpcaddr 0.0.0.0'
	DOCKER_COMMAND+=' --rpcapi web3,eth,personal,miner,net,txpool'
	DOCKER_COMMAND+=' --rpccorsdomain="*"'
	DOCKER_COMMAND+=' --ws'
	DOCKER_COMMAND+=' --wsaddr 0.0.0.0'
	DOCKER_COMMAND+=' --metrics'
	DOCKER_COMMAND+=' --preload /usr/local/bin/miner.js'
	DOCKER_COMMAND+=' --gcmode archive'
	DOCKER_COMMAND+=' --password /data/password'
	DOCKER_COMMAND+=' console'
}

# Starts a Docker container where the entrypoint is `/bin/sh`
#
# @params: arguments to pass to `/bin/sh`
command_shell () {
	add_docgeth_volume ".docgeth"
	DOCKER_PARAMS+=("--entrypoint /bin/sh")
	DOCKER_COMMAND+=$@
}


# ------ Params

# Prints usage/help
#
print_help () {
	printf 'Usage: %s [command] [params]\n' "$0"
	printf '\n'
	printf '  COMMANDS\n'
	printf '    geth    [params] - %s\n' "Runs geth with given args"
	printf '    init             - %s\n' "Initializes a new geth node"
	printf '    pkey    [params] - %s\n' "Gets the matching private key"
	printf '    run              - %s\n' "Starts the geth node with a lightweight auto-miner"
	printf '    shell   [params] - %s\n' "Opens a Docker shell"
	printf '\n'
	printf '  EXAMPLES\n'
	printf '    Run Geth command:\n'
	printf '      %% docgeth.sh geth account new --datadir /data/blockchain\n'
	printf '      %% docgeth.sh geth account update 0 1 2 --datadir /data/blockchain\n'
	printf '      %% docgeth.sh geth account list --datadir /data/blockchain\n\n'
	printf '    Initialize with 10 accounts, password of `password` and a balance of 999 (createed in current directory):\n'
	printf '      %% docgeth.sh init\n'
	printf '    Initialize with 5 accounts, password of `s3cr3t` and a blance of 777 (createed in current directory):\n'
	printf '      %% DOCGETH_ACCOUNTS=5 DOCGETH_PASSWORD=s3cr3t DOCGETH_BALANCE=777 docgeth.sh init\n\n'
	printf '    Get private key for account:\n'
	printf '      %% docgeth.sh pkey 0x1234 password\n\n'
	printf '    Run Geth node:\n'
	printf '      %% docgeth.sh run\n\n'
	printf '    Run shell:\n'
	printf '      %% docgeth.sh shell\n'
	printf '      %% docgeth.sh shell -c "ls -la"\n'
	printf '      %% docgeth.sh shell -c "geth --version"\n'
	printf '    Output Docker command only (does not execute it):\n'
	printf '      %% DOCGETH_VERBOSE=true docgeth.sh pkey 0x1234 password\n'
	printf '\n'
}

# Parse arguments, and run matching command
#
# @param 1: the command to run
# @params: arguments for the command
parse_command () {
	command="$1"
	case "$command" in
		"help")
			print_help
			exit 0
			;;
		"geth")
			command_geth "${@:2}"
			;;
		"init")
			command_init
			;;
		"pkey")
			command_pkey "--key $2" "--password $3"
			;;
		"run")
			command_run
			;;
		"shell")
			command_shell "${@:2}"
			;;
		"")
			print_help
			exit 0
			;;
		*)
			printf "%s: '%s' is not a valid command.\n" "$0" "$command"
			printf "See '%s help.'\n" "$0"
			exit 0
			;;
	esac
}

# -----------------------------------------------------------------------------

parse_command $@
dock
