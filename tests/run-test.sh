#!/usr/bin/env bash
set -euo pipefail

# Resolve the absolute path to the test directory that invoked this helper.
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)

set +u
source /opt/backend-q/deploy/bin/setenv.sh
set -u

# Default behavior: run tests and exit.
# Pass -d or --debug to keep TorQ in debug mode.
DEBUG_FLAG=()
FORWARD_ARGS=()
for arg in "$@"; do
  if [[ "$arg" == "-d" || "$arg" == "--debug" ]]; then
    DEBUG_FLAG=(-debug)
  else
    FORWARD_ARGS+=("$arg")
  fi
done

ARGS=(
  "${TORQHOME}/torq.q"
  -proctype test
  -procname "${TEST_PROCNAME:?TEST_PROCNAME must be set}"
  -test "${SCRIPT_DIR}"
  -load "${KDBTESTS}/helperfunctions.q" "${SCRIPT_DIR}/settings.q"
)
ARGS+=("${DEBUG_FLAG[@]}" "${FORWARD_ARGS[@]}")

exec env ${TEST_ENV_VARS:-} "${QCMD:-q}" "${ARGS[@]}"