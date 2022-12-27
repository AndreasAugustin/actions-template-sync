#! /usr/bin/env bash

set -e
# set -u
set -x

#######################################
# write a message to STDERR.
# Arguments:
#   message to print.
#######################################
err() {
  echo "::error::[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2;
}

#######################################
# write a debug message.
# Arguments:
#   message to print.
#######################################
debug() {
   echo "::debug::$*";
}

#######################################
# write a warn message.
# Arguments:
#   message to print.
#######################################
warn() {
  echo "::warn::$*";
}

#######################################
# write a info message.
# Arguments:
#   message to print.
#######################################
info() {
	echo "::info::$*";
}
