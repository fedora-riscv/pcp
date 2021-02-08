#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/pcp/Library/pcpcommon
#   Description: Common functions for PCP tests
#   Author: Jan Kuřík <jkurik@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2020 Red Hat, Inc.
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

rlJournalStart
    rlPhaseStartTest
        rlRun "pcpcommonLibraryLoaded"

        rlServiceStart pmcd
        rlServiceStart pmlogger
        rlServiceStart pmproxy
        rlServiceStart pmie

        err=0
        pmda=bash
        rlRun "pcpcommon_test -g sanity" || err=1
        rlRun "pcpcommon_pmda_install ${pmda}" || err=1
        rlRun "pcpcommon_pmda_tests ${pmda}" || err=1
        rlRun "pcpcommon_pmda_remove ${pmda}" || err=1
        rlRun "pcpcommon_cleanup"

        [[ ${err} -ne 0 ]] && \
            rlRun "pcpcommon_log_system_info"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
