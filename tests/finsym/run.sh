#!/usr/bin/env bash
set -euo pipefail

# Keep folder-specific configuration here; shared launch logic lives one level up.
TEST_PROCNAME=test_finsym
TEST_ENV_VARS='FEEDWS_NOSTART=1 FEEDWS_NOCONNECT=1 EODWS_SYMBOLS_FILE=/opt/backend-q/deploy/TorQApp/latest/tests/finsym/symbols_fixture.csv'

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/run-test.sh" "$@"
