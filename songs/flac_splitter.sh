#!/bin/bash

#####################
###   CONSTANTS   ###
#####################

# TODO use extension constant to look for files
# playlist_extensions="cue"
extract_file_pattern="%n - %t"

#####################
###   VARIABLES   ###
#####################

DIR=
OUTPUT=
DEBUG=false
DRY_RUN=false

#####################
###     USAGE     ###
#####################

function show_usage() {
  printf "Usage: $0 -d [path] -o [output]\n\n"
  printf "Options:\n"
  printf " -d|--directory [path], Directory with single FLAC file\n"
  printf " -o|--output [path], Output directory for splitted FLAC files\n"
  printf " -x|--debug, Enable debug mode\n"
  printf " -r|--dryrun, Dry run mode\n"
  printf " -h|--help, Display this help\n"
  return 0
}

#####################
###     DEBUG     ###
#####################

function log_debug() {
  if [ $DEBUG == "true" ]; then
    printf "[DEBUG] $1\n"
  fi
  return 0
}

function log_error() {
  printf "[ERROR] $1\n"
  return 0
}

function log_dryrun() {
  echo "[DRY_RUN] $1"
  return 0
}

#####################
###   ARGUMENTS   ###
#####################

while [ ! -z "$1" ]; do
  case "$1" in
  -h | --help)
    show_usage
    exit 0
    ;;
  -d | --directory)
    shift
    DIR="$1"
    ;;
  -o | --output)
    shift
    OUTPUT=$(realpath "$1")
    ;;
  -x | --debug)
    DEBUG=true
    ;;
  -r | --dryrun)
    DRY_RUN=true
    ;;
  *)
    printf "Incorrect input provided: $1\n\n"
    show_usage
    exit 0
    ;;
  esac
  shift
done

#####################
###    CHECKS     ###
#####################

log_debug "Input directory: "$DIR""
log_debug "Output directory: "$OUTPUT""
log_debug "Dry run mode: "$DRY_RUN""

if [[ -z "$DIR" ]]; then
  printf " -d|--directory program argument is mandatory\n\n"
  show_usage
  exit 1
fi

if [[ ! -d "$DIR" ]]; then
  printf " -d|--directory '$DIR' program argument is not an existing directory\n\n"
  show_usage
  exit 1
fi

if [[ -z "$OUTPUT" ]]; then
  printf " -o|--output program argument is mandatory\n\n"
  show_usage
  exit 1
fi

if [[ ! -d "$OUTPUT" ]]; then
  printf " -o|--output '$OUTPUT' program argument is not an existing directory\n\n"
  show_usage
  exit 1
fi

#####################
###  LOAD AND RUN ###
#####################

IFS=$(echo -en "\n\b")

# Look for playlist file
find "$DIR" -name "*.cue" | while read playlist_file; do
  log_debug "Scanning "${playlist_file}""
  song_file="${playlist_file%%.cue}"

  log_debug "Looking for FLAC file ${song_file}..."

  if [[ -f "${song_file}.wv" ]]; then
    song_file="${song_file}.wv"
  else
    song_file="${song_file}.flac"
  fi

  if [[ -f "${song_file}" ]]; then
    base_path=$(dirname ${song_file})
    song_dir=$(basename "${base_path}")
    output_dir="$OUTPUT/${song_dir}"

    if [ "$DRY_RUN" == "false" ]; then
      log_debug "Creating "${output_dir}" directory..."
      mkdir "${output_dir}"
    fi

    if [ "$DRY_RUN" == "false" ]; then
      log_debug "Working on "${song_file}" and extracting to "${output_dir}""
      shnsplit -t ${extract_file_pattern} -f "${playlist_file}" "${song_file}" -d "${output_dir}" -o flac -O always
    else
      log_dryrun "shnsplit -t ${extract_file_pattern} -f "${playlist_file}" "${song_file}" -d "${output_dir}" -o flac -O always"
    fi

    if [ "$DRY_RUN" == "false" ]; then
      log_debug "Removing "${base_path}"..."
      rm -r "${base_path}"
    else
      log_dryrun "rm -r "${base_path}""
    fi
  else
    log_error "FLAC "${song_file}" not found... skip"
  fi
done

exit 0
