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
  echo "Usage: ./transmission_finished.sh [options]"
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

BASEDIR=$(dirname "$0")
if [ "$DEBUG" = true ]; then
  echo "Working in dir $BASEDIR"
fi

# Create transmission-remote command from .netrc file
NETRC_FILE=(pwd "$BASEDIR/.netrc")
TRANSMISSION_REMOTE="transmission-remote --netrc $NETRC_FILE"

# List all downloads
TORRENTLIST=$($TRANSMISSION_REMOTE --list | sed -e '1d' -e '$d' | awk '{print $1}' | sed -e 's/[^0-9]*//g')

# On each downloading files
for TORRENT_ID in $TORRENTLIST; do
  # Get torrent information
  TORRENT_INFO=$($TRANSMISSION_REMOTE --torrent $TORRENTID --info)
  TORRENT_NAME=$(echo $TORRENT_INFO | sed -e 's/.*Name: \(.*\) Hash.*/\1/')
  echo -e "Processing #$TORRENT_ID - $TORRENT_NAME"

  # Check if torrent download is completed
  DL_COMPLETED=$(echo $TORRENT_INFO | grep "Done: 100%")
  # Check torrents current state is
  STATE_STOPPED=$(echo $TORRENT_INFO | grep "State: Seeding\|State: Stopped\|State: Finished\|State: Idle")

  # If the torrent is "Stopped", "Finished", or "Idle after downloading 100%"
  if [ "$DL_COMPLETED" ] && [ "$STATE_STOPPED" ]; then
    echo "Torrent #$TORRENT_ID is fully downloaded."

    if [ "$DRY_RUN" = true ]; then
      echo "Removing torrent from list."
      $(TRANSMISSION_REMOTE --torrent $TORRENTID --remove)
    elif [ "$DEBUG" = true ]; then
      echo "Removing torrent from list not applied in dry-run mode."
    fi
  elif [ "$DEBUG" = true ]; then
    echo "Torrent #$TORRENT_ID is not completed. Ignoring."
  fi
done
