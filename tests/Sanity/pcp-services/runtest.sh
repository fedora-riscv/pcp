#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/pcp/Sanity/pcp-services
#   Description: Test of pcp services
#   Author: Jan Kuřík <jkurik@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2021 Red Hat, Inc.
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
PCPSERVICES="pmlogger pmie pmproxy pmcd"
TOUT="90" # Timeout to wait for a service to start / stop

function service_action() {
    local service=$1
    local status=$2
    local ss=
    local t=${TOUT}

    rlRun -s "systemctl show -p ActiveState --no-pager ${service}" 0 \
        "Check if ${service} service is in expected state"

    # Wait for the service to get into a proper state
    while [[ "${ss}" != "${status}" ]]; do
        [[ $(( t-- )) -le 0 ]] && break
        sleep 1
        ss=$(sed -n 's/^ActiveState=//g p' < ${rlRun_LOG})
    done
    if [[ "${ss}" != "${status}" ]]; then
        rlFail "The ${service} service is in unexpected state '${ss}'"
        return 1
    else
        rlPass "${service} state is OK '${ss}'"
        return 0
    fi
}

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        rlRun "systemctl --no-pager stop ${PCPSERVICES}" 0-255
    rlPhaseEnd

    rlPhaseStartTest
        for s in ${PCPSERVICES}; do
            # All services should be stopped
            service_action ${s} inactive
        done

        for s in ${PCPSERVICES}; do
            # Start a service and check it runs
            rlRun "systemctl start --no-pager ${s}"
            service_action ${s} active

            # Stop a service and check it is stopped
            rlRun "systemctl stop --no-pager ${s}"
            service_action ${s} inactive
        done
    rlPhaseEnd

    rlPhaseStartCleanup
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
