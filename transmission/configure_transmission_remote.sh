#!/bin/bash

DEBUG=false
DRY_RUN=false

debug() {
    DEBUG=true
}

dry_run() {
    DRY_RUN=true
}

usage() {
    echo "Usage: ./configure_transmission_remote.sh [options]"
    echo "  -h display this help"
    echo "  -d dry-run"
    echo "  -x debug mode"
    exit 0
}

error() {
    echo "Invalid option: please use -h option to see usage"
    exit 1
}

while getopts "xdh" option; do
    case "$option" in
    x) debug ;;
    d) dry_run ;;
    h) usage ;;
    *) error ;;
    esac
done

if [ "$DEBUG" = true ]; then
    echo "Debug mode is enabled"

    if [ "$DRY_RUN" = false ]; then
        echo "Dry-run is disabled"
    else
        echo "Dry-run is enabled"
    fi
fi

BASEDIR=$(dirname $(realpath "$0"))
NETRC_FILE="$BASEDIR/.netrc"
if [ "$DEBUG" = true ]; then
    echo "Working in dir $BASEDIR"
fi

# Get transmission host
read -p "Enter transimssion host [http://localhost:9091]:" HOST
HOST=${HOST:-"http://localhost:9091"}

# Get transmission login
read -p "Enter transimssion login:" LOGIN

# Get transmission password
echo -n -e "Enter transimssion password:\n"
read -s PASSWORD

if [ "$DEBUG" = true ]; then
    echo "Recieved parameters: HOST=$HOST LOGIN=$LOGIN PASSWORD=****"
fi

if [ "$DRY_RUN" = false ]; then
    CONTENT="machine $HOST login $LOGIN password $PASSWORD"
    echo $CONTENT >$NETRC_FILE
fi

FINISHED_SCRIPT="$BASEDIR/transmission_finished.sh"
echo "Setting 'transmission_finished.sh' as script to execute when download is done"
if [ "$DEBUG" = true ]; then
    echo "Script location: $FINISHED_SCRIPT"
fi

if [ "$DRY_RUN" = false ]; then
    TRANSMISSION_REMOTE="transmission-remote --netrc $NETRC_FILE --torrent-done-script $FINISHED_SCRIPT"

fi
