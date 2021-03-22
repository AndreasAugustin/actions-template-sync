#######################################
# image for dev build environment
######################################
FROM golang:1.14-alpine as DEV

# install packages
RUN apk add --update --no-cache bash make git zsh curl tmux musl build-base openssh

# Make zsh your default shell for tmux
RUN echo "set-option -g default-shell /bin/zsh" >> /root/.tmux.conf

# install oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# github-cli not stable yet
#RUN git clone https://github.com/cli/cli.git gh-cli \
#    && cd gh-cli \
#    && make \
#    && mv ./bin/gh /usr/local/bin/

RUN apk add --update --no-cache groff util-linux
RUN git clone \
  --config transfer.fsckobjects=false \
  --config receive.fsckobjects=false \
  --config fetch.fsckobjects=false \
  https://github.com/github/hub.git \
 && cd hub \
 && make install prefix=/usr/local

WORKDIR /app

#######################################
# image for creating the documentation
######################################
FROM node:15.12.0-alpine as DOCS

# install packages
RUN apk add --update --no-cache bash make git zsh curl tmux

# Make zsh your default shell for tmux
RUN echo "set-option -g default-shell /bin/zsh" >> /root/.tmux.conf

# install oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# install quality gate
RUN npm install -g markdownlint-cli

WORKDIR /app
