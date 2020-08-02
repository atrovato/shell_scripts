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
  echo "Usage: ./move_downloaded.sh [options]"
  echo "  -h display this help"
  echo "  -d dry-run"
  echo "  -x debug mode"
  exit 0
}

error() {
  echo "Invalid option: please use -h option to see usage"
  exit 1
}

line_break() {
  echo "---------------------------------------"
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

DOWNLOAD_DIR=~/Downloads/torrent/done
DESTINATION_DIR=~/Videos

VIDEO_RADIO_LIST=()
FILES=()

list_files() {
  local NB_FILES=0

  # Listing all files
  if [ "$DEBUG" = true ]; then
    line_break
    echo "Finding files:"
  fi

  while read -r f; do
    ((NB_FILES++))

    if [ "$DEBUG" = true ]; then
      echo "  $NB_FILES. $f"
    fi

    VIDEO_RADIO_LIST+=($NB_FILES "${f##*/}" off)
    FILES+=("$f")
  done < <(find $DOWNLOAD_DIR -type f | sort -n)

  if [ "$DEBUG" = true ]; then
    echo "$NB_FILES file(s) found."
  fi

  return $NB_FILES
}

#--------------------------------------------------------------------
# List all files
list_files
NB_FILES=$?

if [ $NB_FILES = 0 ]; then
  echo "No files found."
  exit $NB_FILES
fi

#--------------------------------------------------------------------
# Select files
VIDEO_SELECTION=$(
  whiptail --title "Moving videos file" --checklist "Select file:" 22 76 16 \
    "${VIDEO_RADIO_LIST[@]}" \
    3>&1 1>&2 2>&3
)

EXIT_STATUS=$?
if [ $EXIT_STATUS != 0 ]; then
  echo "Moving files cancelled"
  exit $EXIT_STATUS
elif [ -z "$VIDEO_SELECTION" ]; then
  echo "Empty selection, nothing to move."
  exit 0
fi

if [ "$DEBUG" = true ]; then
  line_break
  echo "Selected files:"
  for SELECTED in $VIDEO_SELECTION; do
    SELECTED_ID=$(echo $SELECTED | egrep -o '([0-9]+)')
    echo "  $SELECTED_ID. ${FILES[$SELECTED_ID - 1]}"
  done
fi

#--------------------------------------------------------------------
# Select video type

VIDEO_TYPES_DIR=()
VIDEO_TYPES_LIST=()

list_dirs() {
  local NB_FILES=0

  # Listing all dirs
  if [ "$DEBUG" = true ]; then
    echo "Finding directories:"
  fi

  if [ "$1" = true ]; then
    VIDEO_TYPES_LIST+=($NB_FILES "Create new..." on)
  fi

  while read -r f; do
    ((NB_FILES++))

    if [ "$DEBUG" = true ]; then
      echo "  $NB_FILES. $f"
    fi

    if [ "$1" = true ]; then
      VIDEO_TYPES_LIST+=($NB_FILES "${f##*/}" off)
    else
      VIDEO_TYPES_LIST+=($NB_FILES "$(basename $f)")
    fi
    VIDEO_TYPES_DIR+=("$f")
  done < <(find $DESTINATION_DIR -mindepth 1 -maxdepth 1 -type d | sort -nr)

  if [ "$DEBUG" = true ]; then
    echo "$NB_FILES directories found."
  fi

  return $NB_FILES
}

if [ "$DEBUG" = true ]; then
  line_break
  echo "Prepares videos types."
fi

list_dirs

VIDEO_TYPE_SELECTION=$(
  whiptail --title "Moving videos file" --menu "Select type of videos" 15 60 4 \
    "${VIDEO_TYPES_LIST[@]}" \
    3>&1 1>&2 2>&3
)

EXIT_STATUS=$?
if [ $EXIT_STATUS != 0 ]; then
  echo "Moving videos cancelled, no type selected"
  exit $EXIT_STATUS
fi

DESTINATION_DIR="${VIDEO_TYPES_DIR[$VIDEO_TYPE_SELECTION - 1]}"

if [ "$DEBUG" = true ]; then
  echo "Selected destination directory: $DESTINATION_DIR"
fi

#--------------------------------------------------------------------
# Now look is there is subfolders (for Series) to select existing movie name

select_video_name() {
  VIDEO_NAME=$(
    whiptail --title "Moving torrent file" --inputbox "Video name:" 22 76 \
      3>&1 1>&2 2>&3
  )
}

VIDEO_TYPES_DIR=()
VIDEO_TYPES_LIST=()

if [ "$DEBUG" = true ]; then
  line_break
  echo "Looking for folder selection"
fi

list_dirs true
NB_DIRS=$?

if [ $NB_DIRS != 0 ]; then
  if [ "$DEBUG" = true ]; then
    line_break
    echo "Entrering folder selection..."
  fi

  # Select sub-dir
  VIDEO_NAME_SELECTION=$(
    whiptail --title "Moving videos file" --radiolist "Select file:" 22 76 16 \
      "${VIDEO_TYPES_LIST[@]}" \
      3>&1 1>&2 2>&3
  )

  EXIT_STATUS=$?
  if [ $EXIT_STATUS != 0 ]; then
    echo "Program exit"
    exit $EXIT_STATUS
  fi

  if [ "$DEBUG" = true ]; then
    echo "Selected folder $VIDEO_NAME_SELECTION"
  fi

  if [ $VIDEO_NAME_SELECTION = 0 ]; then
    select_video_name
  else
    VIDEO_NAME=${VIDEO_TYPES_DIR[$VIDEO_NAME_SELECTION - 1]##*/}
  fi

else
  select_video_name
fi

if [ -z VIDEO_NAME ]; then
  echo "No file name."
  exit 1
fi

if [ "$DEBUG" = true ]; then
  echo "Video name: $VIDEO_NAME"
fi

#--------------------------------------------------------------------
# Moving files

move_file() {
  SOURCE=$1
  DESTINATION=$2
  DESTINATION="$DESTINATION.${SOURCE##*.}"

  if [ "$DEBUG" = true ]; then
    echo "Moving $SOURCE to $DESTINATION"
  fi

  # Creating destination dir
  DESTINATION_DIR_NAME=$(dirname "$DESTINATION")
  if [ "$DEBUG" = true ]; then
    echo "Creating dir $DESTINATION_DIR_NAME"
  fi

  if [ "$DRY_RUN" = false ]; then
    mkdir -p $(basename "$DESTINATION_DIR_NAME")
  fi

  # Moving file
  if [ "$DEBUG" = true ]; then
    echo "Moving file from $SOURCE to $DESTINATION"
  fi

  if [ "$DRY_RUN" = false ]; then
    echo -n "Copying file from $SOURCE to $DESTINATION..."
    cp -v $(basename "$DESTINATION_DIR_NAME")
    echo " done."
    if [ "$DEBUG" = true ]; then
      echo "Deleting $SOURCE"
    fi
    rm $SOURCE
  fi
}

move_serie() {
  SOURCE=$1
  DESTINATION=$2

  FILE_NAME=${SOURCE##*/}

  if [ "$DEBUG" = true ]; then
    echo "File name: $FILE_NAME"
  fi

  # Extract season and episode
  SEASON_EPISODE=$(echo $FILE_NAME | egrep -io '(S[0-9]+E[0-9]+)')

  if [ "$DEBUG" = true ]; then
    echo "Extracted season and epidose information: $SEASON_EPISODE"
  fi

  SEASON=$(echo $SEASON_EPISODE | egrep -io 'S([0-9]+)E' | egrep -io '([0-9]+)')
  EPISODE=$(echo $SEASON_EPISODE | egrep -io '([0-9]+)$')

  # Try another way to extract season / episode
  if [ -z "$SEASON" ]; then
    SEASON_EPISODE=$(echo $FILE_NAME | egrep -io '^([0-9]{3})')
    SEASON=$(echo $SEASON_EPISODE | egrep -io '^([0-9])')
    EPISODE=$(echo $SEASON_EPISODE | egrep -io '([0-9]{2})$')
  fi

  if [[ -z "$SEASON" ]] && [[ -z "$EPISODE" ]]; then
    echo "Error extracting season and episode on $SOURCE"
    exit 1
  fi

  SEASON=S$(printf "%02d" $SEASON)
  EPISODE=E$(echo $EPISODE | awk '{printf "%02d", $0;}')

  DESTINATION="$DESTINATION/$VIDEO_NAME/$VIDEO_NAME - ${SEASON^^}/$VIDEO_NAME - ${SEASON^^}${EPISODE^^}"
  if [ "$DEBUG" = true ]; then
    echo "Season $SEASON Episode $EPISODE (as $DESTINATION.${SOURCE##*.})"
  fi

  # Moving file
  move_file "$SOURCE" "$DESTINATION"
}

if [ ${#VIDEO_SELECTION[@]} = 1 ] && [ $NB_DIRS = 0 ]; then
  IS_MOVIE=true
  if [ "$DEBUG" = true ]; then
    echo "Moving as movie"
  fi
else
  IS_MOVIE=false
  if [ "$DEBUG" = true ]; then
    echo "Moving as serie"
  fi
fi

for SELECTED in $VIDEO_SELECTION; do
  SELECTED_ID=$(echo $SELECTED | egrep -o '([0-9]+)')
  FILE=${FILES[SELECTED_ID - 1]}

  if [ "$DEBUG" = true ]; then
    line_break
    echo "Ready to move file $SELECTED_ID. $FILE"
  fi

  if [ "$IS_MOVIE" = true ]; then
    move_file "$FILE" "$DESTINATION_DIR/$VIDEO_NAME"
  else
    move_serie "$FILE" "$DESTINATION_DIR"
  fi
done

if [ "$DEBUG" = true ]; then
  line_break
  echo "Removing empty directories in $DOWNLOAD_DIR..."
fi

if [ "$DRY_RUN" = false ]; then
  find $DOWNLOAD_DIR -type d -empty -delete
fi

exit 0
