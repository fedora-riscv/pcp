#!/bin/bash
#shellcheck disable=SC1091
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/pcp/Sanity/upgrade
#   Description: upgrade
#   Author: Jan Kurik <jkurik@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2022 Red Hat, Inc.
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

#shellcheck disable=SC2034
PACKAGE=pcp

distribution_mcase__test() {
    rlLogInfo 'Verify scenario upgrade works'

    rlRun "pcpcommonLibraryLoaded"
    rlRun "rlServiceStart pmcd pmlogger" 0,1
    rlRun "rlServiceEnable pmcd pmlogger" 0-255
    rlRun "sleep 10"

    rlRun "pcpcommon_test -g sanity -g pmda.linux" || rlRun "pcpcommon_log_system_info"
    rlRun "pcpcommon_cleanup"
}

rlJournalStart
    rlPhaseStartSetup "init"

        export LANG=en_US.UTF-8
        export LANGUAGE=en_US:en
        export LC_CTYPE=POSIX
        export LC_NUMERIC=POSIX
        export LC_TIME=POSIX
        export LC_COLLATE=POSIX
        export LC_MONETARY=POSIX
        export LC_MESSAGES=POSIX
        export LC_PAPER=POSIX
        export LC_NAME=POSIX
        export LC_ADDRESS=POSIX
        export LC_TELEPHONE=POSIX
        export LC_MEASUREMENT=POSIX
        export LC_IDENTIFICATION=POSIX
        export LC_ALL=

        rlImport "ControlFlow/mcase"
    rlPhaseEnd
    distribution_mcase__run
rlJournalPrintText
rlJournalEnd

#template by morf-0.29.25
