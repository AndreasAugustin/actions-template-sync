#! /usr/bin/env bash
set -e
# set -u
set -x

[ -z "${GITHUB_TOKEN}" ] && {
    echo "::error::Missing input 'github_token: \${{ secrets.GITHUB_TOKEN }}'.";
    exit 1;
};

if [[ -z "${SOURCE_REPO_PATH}" ]]; then
  echo "::error::Missing input 'source_repo_path: \${{ input.source_repo_path }}'.;"
  exit 1
fi

SOURCE_REPO_HOSTNAME="${HOSTNAME:-github.com}"

# In case of private template repository this will be overwritten
SOURCE_REPO_PREFIX="https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@${SOURCE_REPO_HOSTNAME}/"

# Forward to /dev/null to swallow the output of the private key
if [[ -n "${SSH_PRIVATE_KEY_SRC}" ]] &>/dev/null; then
  SRC_SSH_FILE_DIR="/tmp/.ssh"
  SRC_SSH_PRIVATEKEY_FILE_NAME="id_rsa_actions_template_sync"
  export SRC_SSH_PRIVATEKEY_ABS_PATH="${SRC_SSH_FILE_DIR}/${SRC_SSH_PRIVATEKEY_FILE_NAME}"
  echo "::debug::We are using SSH within a private source repo"
  mkdir -p "${SRC_SSH_FILE_DIR}"
  # use cat <<< instead of echo to swallow output of the private key
  cat <<< "${SSH_PRIVATE_KEY_SRC}" | sed 's/\\n/\n/g' > "${SRC_SSH_PRIVATEKEY_ABS_PATH}"
  chmod 600 "${SRC_SSH_PRIVATEKEY_ABS_PATH}"
  SOURCE_REPO_PREFIX="git@${SOURCE_REPO_HOSTNAME}:"
fi

export SOURCE_REPO="${SOURCE_REPO_PREFIX}${SOURCE_REPO_PATH}"

echo "::group::git init"
echo "set git global configuration"
git config --global user.email "github-action@actions-template-sync.noreply.${SOURCE_REPO_HOSTNAME}"
git config --global user.name "${GITHUB_ACTOR}"
git config --global pull.rebase false
git config --global --add safe.directory /github/workspace
echo "::endgroup::"

# shellcheck source=src/sync_template.sh
source sync_template.sh
