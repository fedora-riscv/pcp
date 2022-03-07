#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/pcp/Sanity/rpm-config-files
#   Description: Verification of rpm config files
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

rlJournalStart
    rlPhaseStartSetup
        rlRun "T=\$(mktemp -d /var/tmp/XXXXXXXXXXXX)"
        rlRun "pushd ${T}" || rlDie 'Something is wrong .... giving up...'

        # Get list of rpms
        rlFetchSrcForInstalled --quiet "${PACKAGE}" || \
            rlDie 'Can not get source package of ${PACKAGE} .... giving up...'
        SOURCEPKG=$(rpm -q --qf '%{name}-%{version}-%{release}.src.rpm' ${PACKAGE})
        rlAssertExists "${T}/${SOURCEPKG}"
        rlRun "rpm -D '_topdir ${T}' -i ${T}/${SOURCEPKG}"
        rlRun "RPMS=\$(rpm -q --qf '%{name}\n' --specfile ${T}/SPECS/${PACKAGE}.spec | \
            grep -v -e '-debuginfo' -e '-debugsource' | tr '\n' ' ')"
    rlPhaseEnd

    rlPhaseStartTest "Install and test all ${PACKAGE} rpms"
        rlRun "yum install -y ${RPMS}"
        for p in ${RPMS}; do
            configs=$(rpm -qc ${p})
            etc=$(rpm -ql ${p} | grep '^/etc/')
            for f in ${etc}; do
                if ! grep -q "${f}" <<< "${configs}"; then
                    [[ -f "${f}" ]] && [[ ! -h "${f}" ]] && rlFail \
                        "File ${f} from ${p} package is not marked as a config file"
                fi
            done
        done
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd" # pushd ${T}
        rlRun "rm -rf ${T}"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
