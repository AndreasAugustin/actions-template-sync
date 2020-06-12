FROM golang:1.14-alpine
# labels
LABEL \
  "name"="GitHub template sync" \
  "homepage"="https://github.com/marketplace/actions/github-template-sync" \
  "repository"="https://github.com/AndreasAugustin/actions-template-sync" \
  "maintainer"="Andreas Augustin <dev@andreas-augustin.org>"

# install packages
RUN apk add --update --no-cache bash make git zsh curl tmux musl build-base

RUN git clone https://github.com/cli/cli.git gh-cli \
    && cd gh-cli \
    && make \
    && mv ./bin/gh /usr/local/bin/

ADD *.sh /bin/
RUN chmod +x /bin/entrypoint.sh \
  && chmod +x /bin/sync_template.sh

ENTRYPOINT ["/bin/entrypoint.sh"]
