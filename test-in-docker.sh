#!/bin/bash

set -o errexit
set -o pipefail

## GET SCRIPTING DIRECTORY AND LOAD DEFAULTS
## --------------------------------------------------------------------------------------------------------------------
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source ${SCRIPT_DIR}/.env

## SET DEFAULTS IF NOT SET IN .EMV
## --------------------------------------------------------------------------------------------------------------------
PLATFORM=${PLATFORM:="linux/amd64"}
SWIFT_VERSION=${SWIFT_VERSION:="5.6"}

## ENABLE DEBUG MODE WITH ENVIRONMENT VARIABLE DEBUG=1
## --------------------------------------------------------------------------------------------------------------------
if [ ! -z ${DEBUG} ]; then
	set -o xtrace
fi

## ADD PACKAGES THAT THE APPLICATION NEEDS
## --------------------------------------------------------------------------------------------------------------------
ADDITIONAL_APT_PACKAGES=""

## RUN TESTS IN LINUX CONTAINER
## --------------------------------------------------------------------------------------------------------------------
docker run -ti --rm \
  --platform=${PLATFORM}  \
  -v ${SCRIPT_DIR}/Package.swift:/Project/Package.swift \
  -v ${SCRIPT_DIR}/Sources:/Project/Sources \
  -v ${SCRIPT_DIR}/Tests:/Project/Tests \
  --network host \
  swift:${SWIFT_VERSION}-focal /bin/bash -c "
    if [ ! -z "${ADDITIONAL_APT_PACKAGES}" ]; then
    apt update -q \
    && apt dist-upgrade -y -q \
    && apt install -q -y \
       ${ADDITIONAL_APT_PACKAGES} \
       2> /dev/null 1> /dev/null
    fi
    cd /Project
    if [ ! -z "${GET_SHELL}" ]; then
      bash
    else
      swift package resolve
      swift build
      swift test
    fi
"
if [ ! -z "$!" ]; then
	echo "Tests failed!"
else
  echo "Tests passed."
fi