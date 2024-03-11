#!/usr/bin/env bash

if [[ -n "${GPG_PASSPHRASE}" ]]  &>/dev/null;  then
    gpg --pinentry-mode loopback --batch --yes --passphrase "${GPG_PASSPHRASE}" "$@" <&0
else
  gpg --pinentry-mode loopback --yes --batch "$@" <&0
fi

exit $?
