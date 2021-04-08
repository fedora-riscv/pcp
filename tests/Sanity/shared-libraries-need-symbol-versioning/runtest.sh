#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/pcp/Sanity/shared-libraries-need-symbol-versioning
#   Description: A check for presence of version symbols
#   Author: Milos Prchlik <mprchlik@redhat.com>, Jan Kuřík <jkurik@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2014-2021 Red Hat, Inc.
#
#   This copyrighted material is made available to anyone wishing
#   to use, modify, copy, or redistribute it subject to the terms
#   and conditions of the GNU General Public License version 2.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program; if not, write to the Free
#   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
#   Boston, MA 02110-1301, USA.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include Beaker environment
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGE="pcp"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
    rlPhaseEnd

    rlPhaseStartTest
        for lib in `rpm -ql pcp-libs | grep lib64`; do
            rlAssertExists "$lib"
            rlRun "readelf -s $lib | grep '@PCP_[[:digit:]]\+\.[[:digit:]]\+'" 0 \
                "$lib should contain versioned symbols"
        done
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
