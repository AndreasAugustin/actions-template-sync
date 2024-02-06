#!/usr/bin/env bash

if [[ -n "${GPG_PASSPHRASE}" ]]  &>/dev/null;  then
    echo -e "${GPG_PASSPHRASE}" |  gpg --pinentry-mode loopback --batch --yes --passphrase-fd 0 "$@" <&0
else
  gpg --pinentry-mode loopback --yes --batch "$@" <&0
fi

exit $?
