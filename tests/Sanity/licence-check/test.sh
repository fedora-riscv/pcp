#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGE=pcp
TCWD="$(pwd)"

rlJournalStart
    rlPhaseStartSetup
        rlRun "tmp=\$(mktemp -d /var/tmp/XXXXXXXXXXXXX)" 0 "Create tmp directory"
        rlRun "pushd $tmp"
        rlRun "set -o pipefail"

        # Ensure we have license tools available
        EPELREPO=
        if ! which license-fedora2spdx &>/dev/null; then
            YUMPARAM=
            if rlIsRHEL || rlIsCentOS; then
                EPELREPO="/etc/yum.repos.d/$(basename ${tmp})"
                rlRun "cp ${TCWD}/epel.repo ${EPELREPO}"
                YUMPARAM="--enablerepo=epel"
            else
                rlDie "Can not find license-validate tool"
            fi
            rlRun "yum install -y ${YUMPARAM} license-validate" \
                || rlDie "Failed to install license-validate tool"
        fi

        # Get list of rpms
        rlFetchSrcForInstalled --quiet "${PACKAGE}" || \
            rlDie 'Can not get source package of ${PACKAGE} .... giving up...'
        SOURCEPKG=$(rpm -q --qf '%{name}-%{version}-%{release}.src.rpm' ${PACKAGE})
        rlAssertExists "${tmp}/${SOURCEPKG}"
        rlRun "rpm -D '_topdir ${tmp}' -i ${tmp}/${SOURCEPKG}"
        rlRun "LICENSES=\"\$(rpm -q --qf '%{license}\n' --specfile ${tmp}/SPECS/${PACKAGE}.spec\
            | sed -e 's/ and /\\n/g' -e 's/^ *//' -e 's/ *$//')\""
        rlRun "TUPLE=\"\$(rpm -q --qf '%{name} %{license}\n' \
            --specfile ${tmp}/SPECS/${PACKAGE}.spec )\""
    rlPhaseEnd

while read l; do
    rlPhaseStart FAIL "License check of ${l}"
        retcode=
        rlRun -s "license-validate '${l}'" || retcode=Fail
        #rlAssertNotGrep 'Warning: ' "${rlRun_LOG}" \
        #    || { rlLogInfo "$(cat ${rlRun_LOG})"; retcode="warn"; }
        #rlAssertEquals "Check if the package license is SPDX identifier" \
        #    "${l}" "$(cat ${rlRun_LOG})" || retcode="fail"

        # Report affected packages
        if [[ -n "${retcode}" ]]; then
            rlLogInfo "The following packages needs to fix the ${l} license:"
            #for p in $(awk "\$0~/${l}/{print \$1;}" <<< "${TUPLE}"); do
            for p in $(grep "${l}" <<< "${TUPLE}" | cut -d ' ' -f 1); do
                rlLogInfo "  - ${p}"
            done
        fi
    rlPhaseEnd
done < <(sort -u <<< "${LICENSES}")

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $tmp" 0 "Remove tmp directory"
        rlRun "yum clean metadata"
        [[ -n "${EPELREPO}" ]] && rlRun "rm -f ${EPELREPO}"
    rlPhaseEnd
rlJournalEnd
