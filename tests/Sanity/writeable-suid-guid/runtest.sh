#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/pcp/Sanity/writeable-suid-guid
#   Description: Test for BZ#1025583 (pcp creates a world writeable directory)
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
. ../../Library/pcpcommon/lib.sh || exit 1

PACKAGE="pcp"
DIRS="/var/lib/pcp /usr/include/pcp /etc/pcp /usr/libexec/pcp /var/log/pcp \
      /usr/share/pcp /usr/share/doc/pcp"
DIRS="${pcpcommon_PCP_VAR_DIR} ${pcpcommon_PCP_INC_DIR} ${pcpcommon_PCP_SYSCONF_DIR} \
    /usr/libexec/pcp ${pcpcommon_PCP_BINADM_DIR} ${pcpcommon_PCP_LIBADM_DIR} \
    ${pcpcommon_PCP_PMDASADM_DIR} ${pcpcommon_PCP_RC_DIR} ${pcpcommon_PCP_LOG_DIR} \
    ${pcpcommon_PCP_SHARE_DIR} ${pcpcommon_PCP_DOC_DIR} ${pcpcommon_PCP_DEMOS_DIR} \
    ${pcpcommon_PCP_HTML_DIR} ${pcpcommon_PCP_HTML_DIR} /usr/share/doc/pcp-doc \
    "

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        rlRun "T=\$(mktemp -d)"
        rlRun "pushd ${T}" || rlDie "Can not 'cd' into a temporary directory"
    rlPhaseEnd

    rlPhaseStartTest
        rlRun -s "find ${DIRS} \
            \\( -perm -4000 -fprintf suid.txt '%#m %u:%g %p\\\\n' \\) , \
            \\( -perm -2000 -fprintf guid.txt '%#m %u:%g %p\\\\n' \\) , \
            \\( -perm -1000 -fprintf sticky.txt '%#m %u:%g %p\\\\n' \\) , \
            \\( -type d -perm -0002 -fprintf writeable-d.txt '%#m %u:%g %p\\\\n' \\) , \
            \\( -type f -perm -0002 -fprintf writeable-f.txt '%#m %u:%g %p\\\\n' \\) \
            " 0 "Search for world-writable, SUID, GUID or sticky bit files and directories"
        for f in suid.txt guid.txt sticky.txt writeable-d.txt writeable-f.txt; do
            if [[ -s ${f} ]]; then
                rlLogInfo "${f} contains the following files:"
                rlLogInfo "$(cat ${f})"
                rlFail "PCP files/dirs should not contain SUID, GUID, sticky or world" \
                    "writeable files"
            fi
        done
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -rf ${T}"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
