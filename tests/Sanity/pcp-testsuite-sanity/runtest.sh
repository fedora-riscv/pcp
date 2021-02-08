#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/pcp/Sanity/pcp-testsuite-sanity
#   Description: pcp testing by upstream testsuite
#   Author: Jan Kuřík <jkurik@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2018 Red Hat, Inc.
#
#   This program is free software: you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as
#   published by the Free Software Foundation, either version 2 of
#   the License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE.  See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program. If not, see http://www.gnu.org/licenses/.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include Beaker environment
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGE="pcp"
TSUSER="pcpqa"
TCWD="$(pwd)"

export SYSTEMD_PAGER=''

function apply_bl() {
    local bl="${1}"
    local tc

    if [[ ! -r "${bl}" ]] ; then
        rlLogDebug "No BL $(basename ${bl}) found"
        return
    fi
    rlLog "Applying BL $(basename ${bl})"
    while read tc; do
        rlRun "sed -i '/^${tc} /d' /var/lib/pcp/testsuite/group"
    done < "${bl}"

    return
}

rlJournalStart
  rlPhaseStartSetup
    rlShowRunningKernel
    rlAssertRpm "${PACKAGE}"
    rlFileBackup --clean --missing-ok /etc/pcp /etc/pcp.conf /etc/pcp.env \
        /etc/sysconfig/pmcd /etc/sysconfig/pmie_timers /etc/sysconfig/pmlogger \
        /etc/sysconfig/pmlogger_timers /etc/sysconfig/pmproxy /var/lib/pcp/config 
    rlRun "TmpDir=\$(mktemp -d)"
    rlRun "yum install -y --enablerepo=\* 'library(pcp/pcpcommon)'" 0-255
    rlRun "rlImport pcp/pcpcommon"
  rlPhaseEnd

  rlPhaseStartSetup "PCP restart"
    rlRun "rlServiceStart pmcd pmlogger" 0-255
    rlRun "rlServiceEnable pmcd pmlogger" 0-255
    rlRun "sleep 30" 0 "Give services some time to fully start"
  rlPhaseEnd

  rlPhaseStartSetup "BL listing"
    # Get all the variables we need
    read ID VERSION_ID < <(
        . /etc/os-release && \
            echo ${ID} ${VERSION_ID} || \
            echo rhel 6.10
    )
    IFS='.,-_ ' read MAJOR MINOR MICRO <<< "${VERSION_ID}"
    ARCH=$(arch)

    _BLSEQ="${ID} ${ID}-${MAJOR}"
    [[ -n "${MINOR}" ]] && _BLSEQ="${BLSEQ} ${ID}-${MAJOR}.${MINOR}"
    [[ -n "${MICRO}" ]] && _BLSEQ="${BLSEQ} ${ID}-${MAJOR}.${MINOR}.${MICRO}"

    IFS='.,-_ ' read MAJOR MINOR MICRO < <(rpm -q --qf '%{version}' ${PACKAGE})
    _BLSEQ="${BLSEQ} ${PACKAGE}"
    [[ -n "${MAJOR}" ]] && _BLSEQ="${BLSEQ} ${PACKAGE}-${MAJOR}"
    [[ -n "${MINOR}" ]] && _BLSEQ="${BLSEQ} ${PACKAGE}-${MAJOR}.${MINOR}"
    [[ -n "${MICRO}" ]] && _BLSEQ="${BLSEQ} ${PACKAGE}-${MAJOR}.${MINOR}.${MICRO}"

    BLSEQ=
    for bl in ${_BLSEQ}; do
        BLSEQ="${BLSEQ} ${bl} ${bl}.${ARCH}"
    done

    for bl in ${BLSEQ}; do
        rlLog "Looking for BL list ${bl}"
        if [[ -r "${TCWD}/bl/${bl}" ]]; then
            apply_bl "${TCWD}/bl/${bl}"
        fi
    done
  rlPhaseEnd

  rlPhaseStartTest "run testsuite"
    rlRun "pcpcommon_test -g sanity" || rlRun "pcpcommon_log_system_info"
  rlPhaseEnd

  rlPhaseStartCleanup
    rlRun "pcpcommon_cleanup"
    rlRun "rlServiceRestore" 0-255
    rlRun "rm -r $TmpDir"
    rlFileRestore
  rlPhaseEnd
rlJournalPrintText
rlJournalEnd
