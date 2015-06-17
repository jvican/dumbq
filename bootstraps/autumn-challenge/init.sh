#!/bin/bash
#
# Test4Theory For Autumn Challenge Bootstrap
# (C) Copyright 2015, Ioannis Charalampidis, PH/SFT, CERN
#

# Configuration parameters
BOOTSTRAP_NAME="autumn-challenge"
BOOTSTRAP_VER="1"

# Less important parameters
DUMBQ_DIR="/cvmfs/sft.cern.ch/lcg/external/experimental/dumbq"
BOOTSTRAP_DIR="${DUMBQ_DIR}/bootstraps/${BOOTSTRAP_NAME}"
DUMBQ_BIN_DIR="${DUMBQ_DIR}/client"
DUMBQ_LOGCAT_BIN="${DUMBQ_BIN_DIR}/utils/dumbq-logcat"
DUMBQ_METRICS_BIN="${DUMBQ_BIN_DIR}/utils/dumbq-metrics"

# Databridge client bin
DATABRIDGE_AGENT_BIN="/cvmfs/sft.cern.ch/lcg/external/experimental/databridge-interface/client/bin/databridge-agent"
DATABRIDGE_BASE_URL="https://t4t-data-bridge.cern.ch"

# Test4Theory WebApp
T4T_WEBAPP_TGZ="/cvmfs/sft.cern.ch/lcg/external/cernvm-copilot/share/t4t-webapp.tgz"
T4T_WEBAPP_DST="/var/www/html"
T4T_WEBAPP_LOGDIR=${T4T_WEBAPP_DST}/logs

# 0) Redirect and start logcat 
# ----------------------------------

# Create missing directories
mkdir -p ${T4T_WEBAPP_DST}/logs
mkdir -p ${T4T_WEBAPP_DST}/job

(
  # Start logcat with all the interesting log files
  ${DUMBQ_LOGCAT_BIN} \
    --prefix="[%d/%m/%y %H:%M:%S] " \
    ${T4T_WEBAPP_LOGDIR}/bootstrap-out.log[cyan] \
    ${T4T_WEBAPP_LOGDIR}/bootstrap-err.log[magenta] \
    ${T4T_WEBAPP_LOGDIR}/job.out[green] \
    ${T4T_WEBAPP_LOGDIR}/job.err[red] \
    ${T4T_WEBAPP_LOGDIR}/databridge-client.log[yellow]
)&

# Redirect stdout/err
exec 2>${T4T_WEBAPP_LOGDIR}/bootstrap-err.log >${T4T_WEBAPP_LOGDIR}/bootstrap-out.log

# 1) Install the test4theory app
# ----------------------------------

# Unzip the t4t-webapp
/bin/tar zxvf $T4T_WEBAPP_TGZ -C $T4T_WEBAPP_DST > /dev/null 2>&1

# 2) Patch binaries queried by jobs
# ----------------------------------

# Copy the config and debug info scripts to /usr/bin
cp ${BOOTSTRAP_DIR}/bin/copilot-debug-info /usr/bin
cp ${BOOTSTRAP_DIR}/bin/copilot-config /usr/bin
chmod a+rx /usr/bin/copilot-debug-info
chmod a+rx /usr/bin/copilot-config

# 3) Start databridge-client
# ----------------------------------

# Include DUMBQ binary dir in environment
export PATH="${PATH}:${DUMBQ_BIN_DIR}"

# Start the log-monitoring agent that will update the dumbq metrics file
${BOOTSTRAP_DIR}/bin/mcprod-monitor&

# Start databridge agent
${DATABRIDGE_AGENT_BIN} "35331" "4c2ce9458a4750eafd589c9b4269fc2b" "${DATABRIDGE_BASE_URL}" 2>${T4T_WEBAPP_LOGDIR}/databridge-client.log >${T4T_WEBAPP_LOGDIR}/databridge-client.log
