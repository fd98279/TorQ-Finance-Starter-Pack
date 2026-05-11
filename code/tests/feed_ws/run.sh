#!/usr/bin/env bash
set -euo pipefail

# Get the absolute path to this script's directory
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
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

# Start a TorQ test process and load the local CSV test suite plus setup helpers.
ARGS=(
  "${TORQHOME}/torq.q"
  -proctype test
  -procname test_feed_ws
  -test "${SCRIPT_DIR}"
  -load "${KDBTESTS}/helperfunctions.q" "${SCRIPT_DIR}/settings.q"
)
ARGS+=("${DEBUG_FLAG[@]}" "${FORWARD_ARGS[@]}")

FEEDWS_NOSTART=1 FEEDWS_NOCONNECT=1 "${QCMD:-q}" "${ARGS[@]}"
