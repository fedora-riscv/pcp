#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/pcp/Sanity/pcp-python-compliance
#   Description: Check for a compliance with Fedora Packaging Guidelines
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
PYPACKAGE="$(rpm -q --qf '%{name}\n' python3-pcp python-pcp 2>/dev/null | grep '^python')"

rlJournalStart
    rlPhaseStartSetup
        rlLog "Compliance with Fedora Packaging Guidelines test"
        rlLog "Check https://docs.fedoraproject.org/en-US/packaging-guidelines/Python/"
        rlAssertRpm ${PACKAGE}
        rlAssertRpm ${PYPACKAGE}
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
    rlPhaseEnd

    rlPhaseStartTest "Check for *.pyc files"
        rlRun "rpm -ql ${PYPACKAGE} > filelist.list"
        while read f; do
            if [[ ${f##*.} == "py" ]]; then
                rlLog "Checking PYC file for $f"
                BASE=$(basename $f)
                DIR=$(dirname $f)
                if [[ "${PYPACKAGE%%-*}" == "python3" ]]; then
                    rlAssertGrep "${DIR}/__pycache__/${BASE%.*}\..*\.pyc" filelist.list -E
                else
                    rlAssertGrep "${DIR}/${BASE%.*}.*\.pyc" filelist.list -E
                fi
            fi
        done < "filelist.list"
    rlPhaseEnd

    rlPhaseStartTest "Check for egg-info files"
        rlAssertGrep "/${PACKAGE}-.*\.egg-info" filelist.list -E
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
