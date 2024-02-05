#!/usr/bin/env bash
set -e
# set -u
# set -x

# shellcheck source=src/sync_common.sh
source sync_common.sh

if [[ -z "${GITHUB_TOKEN}" ]]; then
    err "Missing input 'github_token: \${{ secrets.GITHUB_TOKEN }}'.";
    exit 1;
fi

if [[ -z "${SOURCE_REPO_PATH}" ]]; then
  err "Missing input 'source_repo_path: \${{ input.source_repo_path }}'.";
  exit 1
fi

DEFAULT_REPO_HOSTNAME="github.com"
SOURCE_REPO_HOSTNAME="${HOSTNAME:-${DEFAULT_REPO_HOSTNAME}}"
GIT_USER_NAME="${GIT_USER_NAME:-${GITHUB_ACTOR}}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-github-action@actions-template-sync.noreply.${SOURCE_REPO_HOSTNAME}}"

# In case of ssh template repository this will be overwritten
SOURCE_REPO_PREFIX="https://${SOURCE_REPO_HOSTNAME}/"

function ssh_setup() {
  echo "::group::ssh setup"

  info "prepare ssh"
  SRC_SSH_FILE_DIR="/tmp/.ssh"
  SRC_SSH_PRIVATEKEY_FILE_NAME="id_rsa_actions_template_sync"
  export SRC_SSH_PRIVATEKEY_ABS_PATH="${SRC_SSH_FILE_DIR}/${SRC_SSH_PRIVATEKEY_FILE_NAME}"
  debug "We are using SSH within a private source repo"
  mkdir -p "${SRC_SSH_FILE_DIR}"
  # use cat <<< instead of echo to swallow output of the private key
  cat <<< "${SSH_PRIVATE_KEY_SRC}" | sed 's/\\n/\n/g' > "${SRC_SSH_PRIVATEKEY_ABS_PATH}"
  chmod 600 "${SRC_SSH_PRIVATEKEY_ABS_PATH}"
  SOURCE_REPO_PREFIX="git@${SOURCE_REPO_HOSTNAME}:"

  echo "::endgroup::"
}

function gpg_setup() {
  echo "::group::gpg setup"
  info "start prepare gpg"
  GPG_TTY=$(tty)
  export GPG_TTY
  echo -e "$GPG_PRIVATE_KEY" | gpg --import --batch
  for fpr in $(gpg --list-key --with-colons "${GIT_USER_EMAIL}"  | awk -F: '/fpr:/ {print $10}' | sort -u); do  echo -e "5\ny\n" |  gpg --no-tty --command-fd 0 --expert --edit-key "$fpr" trust; done

  KEY_ID="$(gpg --list-secret-key --with-colons "${GIT_USER_EMAIL}" | awk -F: '/sec:/ {print $5}')"
  git config --global user.signingkey "${KEY_ID}"
  git config --global commit.gpgsign true
  git config --global gpg.program /bin/gpg_no_tty.sh

  info "done prepare gpg"
  echo "::endgroup::"for fpr in
}

# Forward to /dev/null to swallow the output of the private key
if [[ -n "${SSH_PRIVATE_KEY_SRC}" ]] &>/dev/null; then
  ssh_setup
elif [[ "${SOURCE_REPO_HOSTNAME}" != "${DEFAULT_REPO_HOSTNAME}" ]]; then
  gh auth login --git-protocol "https" --hostname "${SOURCE_REPO_HOSTNAME}" --with-token <<< "${GITHUB_TOKEN}"
fi

export SOURCE_REPO="${SOURCE_REPO_PREFIX}${SOURCE_REPO_PATH}"

function git_init() {
  echo "::group::git init"
  info "set git global configuration"

  git config --global user.email "${GIT_USER_EMAIL}"
  git config --global user.name "${GIT_USER_NAME}"
  git config --global pull.rebase false
  git config --global --add safe.directory /github/workspace
  git lfs install

  if [[ "${IS_NOT_SOURCE_GITHUB}" == 'true' ]]; then
    info "the source repository is not located within GitHub."
    ssh-keyscan -t rsa "${SOURCE_REPO_HOSTNAME}" >> /root/.ssh/known_hosts
  else
    info "the source repository is located within GitHub."
    gh auth setup-git --hostname "${SOURCE_REPO_HOSTNAME}"
    gh auth status --hostname "${SOURCE_REPO_HOSTNAME}"
  fi
  echo "::endgroup::"
}

git_init

if [[ -n "${GPG_PRIVATE_KEY}" ]] &>/dev/null; then
  gpg_setup
fi

# shellcheck source=src/sync_template.sh
source sync_template.sh
