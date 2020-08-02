# My useful shell scripts

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
