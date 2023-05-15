FROM alpine:3.18.0

ARG GH_CLI_VER=2.21.1

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
RUN apk add --update --no-cache bash git curl musl openssh git-lfs yq

RUN wget https://github.com/cli/cli/releases/download/v${GH_CLI_VER}/gh_${GH_CLI_VER}_linux_386.tar.gz -O ghcli.tar.gz
RUN tar --strip-components=1 -xf ghcli.tar.gz

ADD *.sh /bin/
RUN chmod +x /bin/entrypoint.sh \
  && chmod +x /bin/sync_template.sh \
  && chmod +x /bin/sync_common.sh

RUN mkdir -p /root/.ssh \
  && ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts

ENTRYPOINT ["/bin/entrypoint.sh"]
