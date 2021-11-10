#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/pcp/Sanity/verify-systemd-units
#   Description: Verification of systemd unit files
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

PACKAGE="pcp"
PKGS="pcp pcp-zeroconf"
UNITS=""
UNITFILESDIR="/usr/lib/systemd/system/"

rlJournalStart
    rlPhaseStartSetup
        PCPVER=$(rpm -q --qf '%{version}' pcp)
        if rlTestVersion ${PCPVER} '<' '5.2.0'; then
            PKGS="${PKGS} pcp-manager"
        fi
        for P in ${PKGS}; do
            rlAssertRpm "${P}"
        done
        # Generate list of unit files
        UNITS=$(rpm -ql ${PKGS} | grep "${UNITFILESDIR}")
        rlLog "Available unit files: ${UNITS}"
    rlPhaseEnd

    rlPhaseStartTest
        FAILEDU=""
        for U in ${UNITS}; do
            if [[ -f ${U} ]] && [[ "$(dirname ${U})" == "${UNITFILESDIR%/}" ]]; then
                if ! rlRun -s "systemd-analyze --no-pager verify ${U}"; then 
                    rlFail "Error in ${U}: $(cat ${rlRun_LOG})"
                    FAILEDU="${FAILEDU} $(basename ${U})"
                fi
                if grep -q 'is deprecated' ${rlRun_LOG}; then
                    rlFail "Error in ${U}: $(cat ${rlRun_LOG})"
                    FAILEDU="${FAILEDU} $(basename ${U})"
                fi
            else
                rlLog "${U} is not a regular unit file ... skipping"
            fi
        done
        [[ -n "${FAILEDU}" ]] && rlLog "List of failed units: ${FAILEDU}"
    rlPhaseEnd

    rlPhaseStartCleanup
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
