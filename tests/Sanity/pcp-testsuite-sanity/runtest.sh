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
#   Copyright (c) 2018-2022 Red Hat, Inc.
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
. ../../Library/pcpcommon/lib.sh || exit 1

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
        rlRun "sed -i '/^${tc} /d' ${pcpcommon_TESTSUITE_DIR}/group"
    done < "${bl}"

    return
}

rlJournalStart
  rlPhaseStartSetup
    rlShowRunningKernel
    rlAssertRpm "${PACKAGE}"
    rlRun "pcpcommonLibraryLoaded"
    rlRun "pcpcommon_testsuite_bl"
    rlRun "rlServiceStart pmcd pmlogger" 0-255
    rlRun "rlServiceEnable pmcd pmlogger" 0-255
    rlRun "sleep 30" 0 "Give services some time to fully start"
  rlPhaseEnd

  rlPhaseStartTest "run testsuite"
    rlRun "pcpcommon_test -g sanity" || rlRun "pcpcommon_log_system_info"
  rlPhaseEnd

  rlPhaseStartCleanup
    rlRun "pcpcommon_cleanup"
    rlRun "rlServiceRestore" 0-255
  rlPhaseEnd
rlJournalPrintText
rlJournalEnd
