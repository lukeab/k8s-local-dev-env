#!/bin/bash
##script just to document by way of code the files to delete to clean up the environment.
set -eo pipefail
[ -n "$DEBUG" ] && set -x

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
rm "${SCRIPT_DIR}/ca.key"
rm "${SCRIPT_DIR}/ca.crt"
rm "${SCRIPT_DIR}/secret-ca.yaml"