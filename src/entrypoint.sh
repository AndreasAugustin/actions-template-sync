#! /usr/bin/env bash
set -e

[ -z "${INPUT_GITHUB_TOKEN}" ] && {
    echo "Missing input 'github_token: \${{ secrets.GITHUB_TOKEN }}'.";
    exit 1;
};


sh -c "/template-sync.sh $*"
