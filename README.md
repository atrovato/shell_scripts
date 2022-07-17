# My useful shell scripts

## Songs

### flac_splitter.sh

Splits an unique FLAC file to multiple FLAC files according to playlist `*.cue` file.

#### Usage

```
./flac_splitter.sh -d /path/to/flac/file -o /path/to/output
```

## Transmission

### configure_transmission_remote.sh

Configure transmission remote information to get used by `transmission_finished.sh`.
It will:

- ask for remote server information
- save it into netrc file
- update transmission configuration setting parameters:
  - torrent-done-script

### transmission_finished.sh

Remove all finished downloads from transmission torrent list.
