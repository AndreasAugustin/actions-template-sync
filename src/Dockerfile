FROM alpine:3.13

ARG GH_CLI_VER=1.9.2

# labels
LABEL \
  "name"="GitHub template sync" \
  "homepage"="https://github.com/marketplace/actions/github-template-sync" \
  "repository"="https://github.com/AndreasAugustin/actions-template-sync" \
  "maintainer"="Andreas Augustin <dev@andreas-augustin.org>"

# install packages
RUN apk add --update --no-cache bash git curl musl openssh

RUN wget https://github.com/cli/cli/releases/download/v${GH_CLI_VER}/gh_${GH_CLI_VER}_linux_386.tar.gz -O ghcli.tar.gz
RUN tar --strip-components=1 -xf ghcli.tar.gz

ADD *.sh /bin/
RUN chmod +x /bin/entrypoint.sh \
  && chmod +x /bin/sync_template.sh

ENTRYPOINT ["/bin/entrypoint.sh"]
