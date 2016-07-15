#!/usr/bin/env bash
#set -x # Debugging

# -----------------------------------------------------------------------------
VERSION=1.0
AUTHOR="Brian Menges"
AUTHOR_EMAIL="mengesb@gmail.com"
LICENSE="Apache 2.0"
LICENSE_URL="http://www.apache.org/licenses/LICENSE-2.0"
# -----------------------------------------------------------------------------

# Usage
usage()
{
  cat <<EOF
  usage: bash $0 [OPTIONS]

  Author : ${AUTHOR} <${AUTHOR_EMAIL}>
  Version: ${VERSION}
  Licensed under ${LICENSE} (${LICENSE_URL})

  This script is designed to establish a lock only after all other locks of a
  similar type have been released. This script doesn't release the lock so you
  are left to solve that segment of the problem. This script is designed to
  sleep until a lock can be stablished

  OPTIONAL OPTIONS:
  -d  Destination directory  ex. /tmp (default)
  -f  Filename (this should be unique)
  -h  This help message
  -v  Verbose output
EOF
}

# Generate random number
rand()
{
  local MIN=$1
  local MAX=$2
  local NUM=0

  while [ "$NUM" -le $MIN ]
  do
    NUM=$RANDOM
    let "NUM %= $MAX"
  done

  echo $NUM
}

# Requirements check
d_directory=/tmp
VAR=$(echo "$BASH_VERSION")
[[ $? -ne 0 ]] && echo "Unable to determine BASH version installed, exiting." && usage && exit 1
[[ "${BASH_VERSION}" =~ ^[0-3] ]] && echo "Script requires a BASH version 4.x or higher, found ${BASH_VERSION}" && usage && exit 1
[[ -z "$(grep --version)" ]] && echo "Program 'grep' not found in PATH!" && usage && exit 1

# Options parsing
while getopts ":f:d:hv" OPTION; do
  case "$OPTION" in
    f)
      f_filename=${OPTARG}
      ;;
    d)
      if [[ -d ${OPTARG} ]]; then
        d_directory=${OPTARG}
      fi
      ;;
    h)
      usage && exit 0
      ;;
    v)
      VERBOSE=1
      ;;
    *)
      usage && exit 1
      ;;
    ?)
      usage && exit 1
      ;;
  esac
done

#
# Main
#

sleep $(rand 5 31)
C=$(ls $d_directory | grep -Ec 'configuring\.')

while [ "$C" -gt 0 ]
do
  number=$(rand 5 20)
  echo "Waiting for $C proccesses to complete; sleeping $number seconds" && sleep $number
  C=$(ls $d_directory | grep -Ec 'configuring\.')
done

touch ${d_directory}/configuring.${f_filename}

exit 0

