#!/usr/bin/env bash

export GPG_TTY=$(tty)

if [[ -n "${GPG_PASSPHRASE}" ]]  &>/dev/null;  then
    echo -e "${GPG_PASSPHRASE}" |  gpg --batch --yes --passphrase-fd 0 "$@" <&0
else
  gpg --yes --batch "$@" <&0
fi

exit $?
