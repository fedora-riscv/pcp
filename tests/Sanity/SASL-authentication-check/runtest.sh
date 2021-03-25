#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/pcp/Sanity/SASL-authentication-check
#   Description: A basic test of SASL authentication
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
METRICUSER="pcpmetricuser"
METRICUSERPW="pcpmetricuserpw"

HASHES="scram-sha-256 digest-md5"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE

        rlServiceStart "pmcd"

        rlFileBackup --clean --missing-ok \
            /etc/pcp.env \
            /etc/sasl2/pmcd.conf \
            /etc/pcp/passwd.db
        rlRun "useradd -r ${METRICUSER}"
    rlPhaseEnd

for HASH in ${HASHES}; do

    rlPhaseStartTest "Test for ${HASH}"
        rlRun "rm -f /etc/pcp/passwd.db"
        rlRun "echo -e 'mech_list: ${HASH}\nsasldb_path: /etc/pcp/passwd.db\n' \
            > /etc/sasl2/pmcd.conf"

        rlRun "echo ${METRICUSERPW} | saslpasswd2 -p -a pmcd ${METRICUSER}"
        rlRun "chown root:pcp /etc/pcp/passwd.db"
        rlRun "chmod 640 /etc/pcp/passwd.db"

        rlServiceStart "pmcd"
        rlRun "sleep 3" 0 "Give pmcd some time to start"

        rlRun -s "pminfo -f -h 'pcp://127.0.0.1?username=${METRICUSER}&password=${METRICUSERPW}' disk.dev.read"
        rlFileSubmit "${rlRun_LOG}" "pminfo.output"
        rlAssertNotGrep "user not found" "${rlRun_LOG}"
        rlAssertGrep ".*inst .*value .*" "${rlRun_LOG}" -E
        rlFileSubmit "/var/log/pcp/pmcd/pmcd.log"
    rlPhaseEnd

done

    rlPhaseStartCleanup
        rlRun "userdel -fr ${METRICUSER}"
        rlFileRestore
        rlServiceRestore
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
