FROM alpine:3.11

# labels
LABEL \
  "name"="GitHub template sync" \
  "homepage"="https://github.com/marketplace/actions/github-template-sync" \
  "repository"="https://github.com/AndreasAugustin/actions-template-sync" \
  "maintainer"="Andreas Augustin <dev@andreas-augustin.org>"

# install packages
RUN apk add --no-cache git bash openssh-client && \
  echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

ADD *.sh /bin/
RUN chmod +x /bin/entrypoint.sh && \
    chmod +x /bin/template-sync.sh

ENTRYPOINT ["/bin/entrypoint.sh"]
