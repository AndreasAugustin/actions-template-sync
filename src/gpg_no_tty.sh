#!/usr/bin/env bash

if [[ -n "${GPG_PASSPHRASE}" ]]  &>/dev/null;  then
    echo -e "${GPG_PASSPHRASE}" |  gpg --batch --yes --passphrase-fd 0 --no-tty "$@" <&0
else
  gpg --yes --batch --no-tty "$@" <&0
fi

exit $?
