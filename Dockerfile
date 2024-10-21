########################################
# prod image
#######################################
FROM alpine:3.20.3 AS prod

ARG GH_CLI_VER=2.44.1

# TODO(anau) change user
ARG GITHUB_URL="https://github.com/AndreasAugustin/actions-template-sync"

# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.url="${GITHUB_URL}"
LABEL org.opencontainers.image.documentation="${GITHUB_URL}/README.md"
LABEL org.opencontainers.image.source="${GITHUB_URL}"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.authors="andyAugustin"
LABEL org.opencontainers.image.title="actions-template-sync image"
LABEL org.opencontainers.image.description="contains actions-template-sync"

# install packages
RUN apk add --update --no-cache bash git curl musl openssh git-lfs yq gnupg

RUN wget https://github.com/cli/cli/releases/download/v${GH_CLI_VER}/gh_${GH_CLI_VER}_linux_386.tar.gz -O ghcli.tar.gz
RUN tar --strip-components=1 -xf ghcli.tar.gz

ADD src/*.sh /bin/
RUN chmod +x /bin/entrypoint.sh \
  && chmod +x /bin/sync_template.sh \
  && chmod +x /bin/sync_common.sh \
  && chmod +x /bin/gpg_no_tty.sh

RUN mkdir -p /root/.ssh \
  && ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts

ENTRYPOINT ["/bin/bash", "/bin/entrypoint.sh"]
#######################################
# image for dev build environment
######################################
FROM prod AS dev

# install packages
RUN apk add --update --no-cache make zsh tmux vim tig

# Make zsh your default shell for tmux
RUN echo "set-option -g default-shell /bin/zsh" >> /root/.tmux.conf

# install oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

WORKDIR /app

ENTRYPOINT ["/bin/zsh"]

#######################################
# image for creating the documentation
######################################
FROM node:23.0.0-alpine AS docs

# install packages
RUN apk add --update --no-cache bash make git zsh curl tmux

# Make zsh your default shell for tmux
RUN echo "set-option -g default-shell /bin/zsh" >> /root/.tmux.conf

# install oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# install quality gate
RUN npm install -g markdownlint-cli

WORKDIR /app
