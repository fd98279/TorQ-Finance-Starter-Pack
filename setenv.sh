#!/bin/bash

# if running the kdb+tick example, change these to full paths
# some of the kdb+tick processes will change directory, and these will no longer be valid

# get absolute path to setenv.sh directory
if [ "-bash" = $0 ]; then
  dirpath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  dirpath="$(cd "$(dirname "$0")" && pwd)"
fi

export TORQHOME=${dirpath}
export TORQAPPHOME=${TORQHOME}
export TORQDATAHOME=${TORQHOME}
export KDBCONFIG=${TORQHOME}/config
export KDBCODE=${TORQHOME}/code
export KDBTESTS=${TORQHOME}/tests
export KDBLOG=${TORQDATAHOME}/logs
export KDBHTML=${TORQHOME}/html
export KDBLIB=${TORQHOME}/lib
export KDBHDB=${TORQDATAHOME}/hdb
export KDBWDB=${TORQDATAHOME}/wdbhdb
export KDBDQCDB=${TORQDATAHOME}/dqe/dqcdb/database
export KDBDQEDB=${TORQDATAHOME}/dqe/dqedb/database
export KDBTPLOG=${TORQDATAHOME}/tplogs
export KDBTESTS=${TORQHOME}/tests
export KDBPCAPS=${TORQAPPHOME}/pcaps

# set rlwrap and qcon paths for use in torq.sh qcon flag functions
export RLWRAP="rlwrap"
export QCON="qcon"
export QCMD="q" #set qcmd path

# set the application specific configuration directory
export KDBAPPCONFIG=${TORQAPPHOME}/appconfig
export KDBAPPCODE=${TORQAPPHOME}/code

# set KDBBASEPORT to the default value for a TorQ Installation
export KDBBASEPORT=6000

# set TORQPROCESSES to the default process csv
export TORQPROCESSES=${KDBAPPCONFIG}/process.csv

# set DOGSTATSD_PORT to the default value for datadog daemon
export DOGSTATSD_PORT=8125

# if using the email facility, modify the library path for the email lib depending on OS
# e.g. linux:
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$KDBLIB/l[32|64]
# e.g. macOS:
# export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$KDBLIB/m[32|64]

TORQSSLCERT=${KDBLOG}/torqsslcert.txt
touch ${TORQSSLCERT}
if [ -z "${SSL_CA_CERT_FILE}" ]; then
  if [ -n "${KX_SSL_CA_FILE}" ] && [ -f "${KX_SSL_CA_FILE}" ]; then
    echo "`date`    Using existing CA bundle at ${KX_SSL_CA_FILE}" </dev/null >>$TORQSSLCERT
    export SSL_CA_CERT_FILE=${KX_SSL_CA_FILE}
  elif [ -f /etc/ssl/certs/ca-certificates.crt ]; then
    echo "`date`    Using system CA bundle at /etc/ssl/certs/ca-certificates.crt" </dev/null >>$TORQSSLCERT
    export SSL_CA_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
  else
    mkdir -p ${TORQHOME}/certs
    curl -s https://curl.se/ca/cacert.pem > ${TORQHOME}/certs/cabundle.pem
    echo "`date`    The SSL security certificate has been downloaded to ${TORQHOME}/certs/cabundle.pem" </dev/null >>$TORQSSLCERT
    export SSL_CA_CERT_FILE=${TORQHOME}/certs/cabundle.pem
  fi
else
  echo "`date`    The SSL security certificate already exists. If https requests fail it may be because of inappropriate certification." </dev/null >>$TORQSSLCERT
fi
