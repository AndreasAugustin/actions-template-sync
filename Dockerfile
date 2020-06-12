#######################################
# image for dev build environment
######################################
FROM golang:1.14-alpine as DEV

# install packages
RUN apk add --update --no-cache bash make git zsh curl tmux musl build-base

# Make zsh your default shell for tmux
RUN echo "set-option -g default-shell /bin/zsh" >> /root/.tmux.conf

# install oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

RUN git clone https://github.com/cli/cli.git gh-cli \
    && cd gh-cli \
    && make \
    && mv ./bin/gh /usr/local/bin/

WORKDIR /app

#######################################
# image for creating the documentation
######################################
FROM node:14.4.0-alpine as DOCS

# install packages
RUN apk add --update --no-cache bash make git zsh curl tmux

# Make zsh your default shell for tmux
RUN echo "set-option -g default-shell /bin/zsh" >> /root/.tmux.conf

# install oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# install quality gate
RUN npm install -g markdownlint-cli

WORKDIR /app
