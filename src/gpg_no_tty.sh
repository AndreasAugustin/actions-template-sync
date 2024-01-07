#!/usr/bin/env bash

export pflag=""
# create dynamic `--passphrase` flag to insert into the final command if the passphrase variable is not empty.
if [[ -n "$GPG_PASSPHRASE" ]];  then
    pflag="--passphrase ${GPG_PASSPHRASE}"
fi

# "<&0" → use same stdin as the one originally piped to script
# "$@" → pass all script arguments to actual command

gpg --yes --batch --no-tty "$pflag" "$@" <&0

exit $?
