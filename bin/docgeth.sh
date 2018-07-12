#!/bin/bash
#

DOCKER_IMAGE="minty/docgeth"


# -----------------------------------------------------------------------------


DOCKER_PARAMS=('-it' '--rm')
DOCKER_VOLUMES=()
DOCKER_COMMAND=()

add_volume () {
	DOCKER_VOLUMES+=("--volume $(pwd)/$1:/data/$1")
}

add_docgeth_volume () {
	DOCKER_VOLUMES+=("--volume $(pwd)/.docgeth:/data")
}

# ------ Docker
dock () {
	printf "docker run \ \n"
	printf "	%s \ \n" "${DOCKER_PARAMS[@]}"
	printf "	%s \ \n" "${DOCKER_VOLUMES[@]}"
	printf "	%s %s \ \n" "$DOCKER_IMAGE" "${DOCKER_COMMAND[@]}"
	printf "\n--------------------------------------------------------------------------------\n"
docker run \
	${DOCKER_PARAMS[@]} \
	${DOCKER_VOLUMES[@]} \
	$DOCKER_IMAGE ${DOCKER_COMMAND[@]}
}

# ------ Commands
command_geth () {
	add_docgeth_volume ".docgeth"
}

command_init () {
	add_docgeth_volume ".docgeth"
	DOCKER_PARAMS+=("--entrypoint init.sh")
}

command_pkey () {
	add_docgeth_volume ".docgeth"
	DOCKER_PARAMS+=("--entrypoint gethpkey")
	DOCKER_COMMAND+=$@
	DOCKER_COMMAND+=" --path /data/blockchain/keystore"
}

command_run () {
	add_docgeth_volume ".docgeth"
	DOCKER_PARAMS+=('--publish 30303:30303')
	DOCKER_PARAMS+=('--publish 8545:8545')
	DOCKER_COMMAND+=' --datadir /data/blockchain'
	#DOCKER_COMMAND+=' --dev'
	DOCKER_COMMAND+=' --networkid 10'
	DOCKER_COMMAND+=' --maxpeers 3'
	DOCKER_COMMAND+=' --nat any'
	DOCKER_COMMAND+=' --nodiscover'
	DOCKER_COMMAND+=' --rpc'
	DOCKER_COMMAND+=' --rpcaddr 0.0.0.0'
	DOCKER_COMMAND+=' --rpcport 8545'
	#DOCKER_COMMAND+=' --rpcapi "db,eth,net,web3,personal"'
	#DOCKER_COMMAND+=' --rpcapi "eth,net,web3,admin,personal,miner,txpool"'
	DOCKER_COMMAND+=' --rpcapi web3,eth,personal,miner,net,txpool'
	DOCKER_COMMAND+=' --rpccorsdomain="*"'
	DOCKER_COMMAND+=' --ws'
	DOCKER_COMMAND+=' --wsaddr 0.0.0.0'
	DOCKER_COMMAND+=' --metrics'
	DOCKER_COMMAND+=' --preload /usr/local/bin/miner.js'
	DOCKER_COMMAND+=' --gcmode archive'
	DOCKER_COMMAND+=' --unlock 5'
	DOCKER_COMMAND+=' --password /data/password'
	DOCKER_COMMAND+=' console'
}

command_shell () {
	add_docgeth_volume ".docgeth"
	DOCKER_PARAMS+=("--entrypoint /bin/sh")
	DOCKER_COMMAND+=$@
}


# ------ Params
print_help () {
	printf 'Usage: %s [command] [params]\n' "$0"
	printf '\n'
	printf '  COMMANDS\n'
	printf '    geth    [params] - %s\n' "Runs geth with given args"
	printf '    init             - %s\n' "Initializes a new geth node"
	printf '    run              - %s\n' "Starts the geth node with a lightweight auto-miner"
	printf '    shell   [params] - %s\n' "Opens a Docker shell"
	printf '\n'
	printf '  EXAMPLES\n'
	printf '    Run Geth command:\n'
	printf '      %% ./dockit.sh geth account new --password /data/password\n'
	printf '      %% ./dockit.sh geth account new --password <(echo password)\n'
	printf '      %% ./dockit.sh geth account update 0 1 2\n'
	printf '      %% ./dockit.sh geth account list\n\n'
	printf '    Initialize a new Geth node (creates in current directory):\n'
	printf '      %% ./dockit.sh truffle develop\n\n'
	printf '    Get private key for account:\n'
	printf '      %% ./dockit.sh pkey 0x1234 "password"\n\n'
	printf '    Run Geth node:\n'
	printf '      %% ./dockit.sh run\n\n'
	printf '    Run shell:\n'
	printf '      %% ./dockit.sh shell\n'
	printf '      %% ./dockit.sh shell -c "ls -la"\n'
	printf '      %% ./dockit.sh shell -c "geth --version"\n'
	printf '      %% ./dockit.sh shell -c "gethpkey --key 0x123123 --password s3cr3t"\n'
	printf '\n'
}

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
