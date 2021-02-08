# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   lib.sh of /CoreOS/pcp/Library/pcpcommon
#   Description: Common functions for PCP tests
#   Author: Milos Prchlik <mprchlik@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2013 Red Hat, Inc. All rights reserved.
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
#   library-prefix = pcpcommon
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

. /usr/share/beakerlib/beakerlib.sh

PACKAGES="pcp"

pcpcommon_TESTDIR="$(pwd)"

# Set all the usefull PCP variables
pcpcommon_PCP_ENV="${pcpcommon_PCP_ENV:-/etc/pcp.env}"
for i in $(. ${pcpcommon_PCP_ENV}; set | grep '^PCP_' | grep -v '\s'); do
    eval pcpcommon_$i
done

pcpcommon_PCP_VAR_DIR=${pcpcommon_PCP_VAR_DIR:-/var/lib/pcp}
pcpcommon_PCP_PMDAS_DIR=${pcpcommon_PCP_PMDAS_DIR:-${pcpcommon_PCP_VAR_DIR}/pmdas}
pcpcommon_PCP_PMCDCONF_PATH=${pcpcommon_PCP_PMCDCONF_PATH:-/etc/pcp/pmcd/pmcd.conf}
pcpcommon_PCP_LOG_DIR=${pcpcommon_PCP_LOG_DIR:-/var/log/pcp}
pcpcommon_TESTSUITE_DIR=${pcpcommon_TESTSUITE_DIR:-${pcpcommon_PCP_VAR_DIR}/testsuite}
pcpcommon_TESTSUITE_USER="${pcpcommon_TESTSUITE_USER:-pcpqa}"
pcpcommon_TESTSUITE_USER_HOME=$(getent passwd ${pcpcommon_TESTSUITE_USER} \
            | awk -F : '{print $6}')
pcpcommon_TESTSUITE_USER_HOME="${pcpcommon_TESTSUITE_USER_HOME:-/home/${pcpcommon_TESTSUITE_USER}}"
pcpcommon_REAL_TESTSUITE_USER="${pcpcommon_TESTSUITE_USER}"

function map_metric() {
    case "$1" in
        dm)
            echo dmcache
            ;;
        *)
            echo $1
            ;;
    esac

    return 0
}

function _pcpcommon_pmda_bpftrace_setup() {
    rlFileBackup --namespace pcpcommon_pcpqa "${pcpcommon_PCP_PMDAS_DIR}/bpftrace"
    if rlIsRHEL '>8.2'; then
        rlRun "sed -i \
            -e 's/^enabled =.*\$/enabled = true/g' \
            -e 's/^auth_enabled =.*\$/auth_enabled = false/g' \
            ${pcpcommon_PCP_PMDAS_DIR}/bpftrace/bpftrace.conf"
    else
        rlRun "sed -i \
            -e 's/^enabled =.*\$/enabled = false/g' \
            ${pcpcommon_PCP_PMDAS_DIR}/bpftrace/bpftrace.conf"
    fi
}

pcpcommon_PCPQA_CREATED=
pcpcommon_PCPQA_SETUP=
function pcpcommon_testsuite_user() {
    # Check if we have already setup the testsuite user or not
    [[ -n "${pcpcommon_PCPQA_SETUP}" ]] && return 0
    pcpcommon_PCPQA_SETUP="done"

    rlFileBackup --clean --namespace pcpcommon_pcpqa --missing-ok \
        "${pcpcommon_TESTSUITE_USER_HOME}"
    if ! rlRun "id ${pcpcommon_TESTSUITE_USER}" 0,1; then
        rlRun "useradd -d ${pcpcommon_TESTSUITE_USER_HOME} -m \
            -s /bin/bash -U ${pcpcommon_TESTSUITE_USER}"
        rlRun "chown -R ${pcpcommon_TESTSUITE_USER}:${pcpcommon_TESTSUITE_USER} \
            ${pcpcommon_TESTSUITE_DIR}"
        rlFail "User ${pcpcommon_TESTSUITE_USER} was not created by pcp packages" \
            "- see BZ#1025688"
        pcpcommon_PCPQA_CREATED="yes"
    fi

    # Fallback
    if [[ ! -d ${pcpcommon_TESTSUITE_USER_HOME} ]]; then
        rlRun "mkdir -p ${pcpcommon_TESTSUITE_USER_HOME}"
    fi

    # Make sure all the testsuite files are owned by pcpqa
    rlRun "chown -R ${pcpcommon_TESTSUITE_USER}:${pcpcommon_TESTSUITE_USER} \
        ${pcpcommon_TESTSUITE_DIR} ${pcpcommon_TESTSUITE_USER_HOME}"

    # Configure sudo
    if [[ -d "/etc/sudoers.d/" ]]; then
        if [[ ! -f "/etc/sudoers.d/99_${pcpcommon_TESTSUITE_USER}" ]]; then
            rlRun "rlFileBackup --clean --namespace pcpcommon_pcpqa --missing-ok \
                /etc/sudoers.d/99_${pcpcommon_TESTSUITE_USER}"
            rlRun "echo 'Defaults:${pcpcommon_TESTSUITE_USER} !requiretty' \
                > /etc/sudoers.d/99_${pcpcommon_TESTSUITE_USER}"
            rlRun "echo '${pcpcommon_TESTSUITE_USER} ALL=(ALL) NOPASSWD: ALL' \
                >> /etc/sudoers.d/99_${pcpcommon_TESTSUITE_USER}"
            rlRun "chmod 0440 /etc/sudoers.d/99_${pcpcommon_TESTSUITE_USER}"
        fi
    else
        if ! grep -q "${pcpcommon_TESTSUITE_USER} ALL=(ALL) NOPASSWD: ALL" \
            /etc/sudoers ; then
            rlRun "rlFileBackup --namespace pcpcommon_pcpqa /etc/sudoers"
            rlRun "echo 'Defaults:${pcpcommon_TESTSUITE_USER} !requiretty' \
                >> /etc/sudoers"
            rlRun "echo '${pcpcommon_TESTSUITE_USER} ALL=(ALL) NOPASSWD: ALL' \
                >> /etc/sudoers"
        fi
    fi

    # Setup ssh
    rlRun "rlFileBackup --clean --namespace pcpcommon_pcpqa --missing-ok \
        ${pcpcommon_TESTSUITE_USER_HOME}/.ssh"
    if [[ ! -f "${pcpcommon_TESTSUITE_USER_HOME}/.ssh/id_rsa" ]]; then
        rlRun "su - -c 'mkdir ${pcpcommon_TESTSUITE_USER_HOME}/.ssh' \
            ${pcpcommon_TESTSUITE_USER}"
        rlRun "su - -c 'ssh-keygen -t rsa -N \"\" \
            -f ${pcpcommon_TESTSUITE_USER_HOME}/.ssh/id_rsa' ${pcpcommon_TESTSUITE_USER}"
    fi
    rlRun "su - -c 'cat ${pcpcommon_TESTSUITE_USER_HOME}/.ssh/id_rsa.pub \
        >> ${pcpcommon_TESTSUITE_USER_HOME}/.ssh/authorized_keys' \
        ${pcpcommon_TESTSUITE_USER}"
    rlRun "echo 'Host *' >> ${pcpcommon_TESTSUITE_USER_HOME}/.ssh/config"
    rlRun "echo 'StrictHostKeyChecking no' \
        >> ${pcpcommon_TESTSUITE_USER_HOME}/.ssh/config"
    rlRun "echo 'UserKnownHostsFile=/dev/null' \
        >> ${pcpcommon_TESTSUITE_USER_HOME}/.ssh/config"
    rlRun "chmod 600 ${pcpcommon_TESTSUITE_USER_HOME}/.ssh/config"
    rlRun "chmod 0700 ${pcpcommon_TESTSUITE_USER_HOME}/.ssh"
    rlRun "chmod 0640 ${pcpcommon_TESTSUITE_USER_HOME}/.ssh/authorized_keys"

    # Setup default PATHs etc.
    rlFileBackup --clean --namespace pcpcommon_pcpqa --missing-ok \
        "${pcpcommon_TESTSUITE_USER_HOME}/.bashrc"
    rlRun "su -s /bin/sh -c 'touch ${pcpcommon_TESTSUITE_USER_HOME}/.bashrc' \
        ${pcpcommon_TESTSUITE_USER}"
    rlRun "echo 'PATH=\${PATH}:\${PCP_BIN_DIR}:\${PCP_BINADM_DIR}:\${PCP_PLATFORM_PATHS}'\
        >> ${pcpcommon_TESTSUITE_USER_HOME}/.bashrc"

    return 0
}

function pcpcommon_testsuite_user_cleanup() {
    # Check if we have anything to clenup
    [[ -z "${pcpcommon_PCPQA_SETUP}" ]] && return 0
    pcpcommon_PCPQA_SETUP=

    # Kill everything related to pcpqa
    rlRun "pkill --signal SIGTERM -u ${pcpcommon_TESTSUITE_USER}" 0-255
    rlRun "pkill --signal SIGTERM -g ${pcpcommon_TESTSUITE_USER}" 0-255
    rlRun "sleep 5" 0 "Wait a bit, so proceses can terminate gracefully"
    rlRun "pkill --signal SIGKILL -u ${pcpcommon_TESTSUITE_USER}" 0-255
    rlRun "pkill --signal SIGKILL -g ${pcpcommon_TESTSUITE_USER}" 0-255

    if [[ -n "${pcpcommon_PCPQA_CREATED}" ]]; then
        rlRun "userdel -f -r -Z ${pcpcommon_TESTSUITE_USER}" 0-255
    fi
    rlFileRestore --namespace pcpcommon_pcpqa

    return 0
}

function pcpcommon_log_system_info() {
    local pcpcommon_TMP=$(mktemp -d)
    local pcpcommon_TAR=$(mktemp /tmp/XXXXXXXX.tar.gz)

    rlShowRunningKernel
    [[ -d /etc/os-release ]] && \
        cp /etc/os-release ${pcpcommon_TMP}/os-release
    env &> ${pcpcommon_TMP}/env
    sestatus &> ${pcpcommon_TMP}/sestatus
    [[ -d /var/run/pcp ]] && \
        ls -alZ /var/run/pcp &> ${pcpcommon_TMP}/ls-alZ_var.run.pcp
    pstree -u &> ${pcpcommon_TMP}/pstree
    ps xau &> ${pcpcommon_TMP}/ps.aux
    netstat -lpn &> ${pcpcommon_TMP}/netstat
    ip addr &> ${pcpcommon_TMP}/ip.addr
    hostname &> ${pcpcommon_TMP}/hostname
    cp /etc/hosts ${pcpcommon_TMP}/etc.hosts
    which iptables &> /dev/null && \
        iptables -S &> ${pcpcommon_TMP}/iptables
    which nft &> /dev/null && \
        nft list ruleset &> ${pcpcommon_TMP}/nftables
    
    # Upload everything
    tar czf ${pcpcommon_TAR} -C ${pcpcommon_TMP} $(cd ${pcpcommon_TMP} && ls -1)
    rlFileSubmit "${pcpcommon_TAR}" "system.info.tar.gz"

    # Cleanup
    rm -rf ${pcpcommon_TMP} ${pcpcommon_TAR}

    return 0
}

function pcpcommon_test () {
    local ret=0
    local params="$@"

    pcpcommon_testsuite_user

    if rlRun "pushd ${pcpcommon_TESTSUITE_DIR}"; then
        rlRun -s "su -l -s /bin/bash -c 'cd ${pcpcommon_TESTSUITE_DIR} && \
            ./check ${params}' ${pcpcommon_REAL_TESTSUITE_USER}"
        rlFileSubmit "${rlRun_LOG}" "check.log"
        local _test_results="${rlRun_LOG}"

        if ! rlRun "egrep 'Passed all [[:digit:]]+ tests' ${_test_results}" 0 \
            "Assert all testcases passed"; then
            local _tmp_dir=$(mktemp -d)
            local _tmp_tar=$(mktemp /tmp/XXXXXXXX.tar.gz)
            local failid
            local failids="$(egrep 'Failures: ' ${_test_results} | cut -d' ' -f2-)"

            if [[ -n "${failids}" ]]; then
                for failid in ${failids}; do
                    rlFail "TC $failid failed"
                    rlRun "cp ${failid}.out ${_tmp_dir}/"
                    rlRun "cp ${failid}.out.bad ${_tmp_dir}/"
                done
                tar czf ${_tmp_tar} -C ${_tmp_dir} $(cd ${_tmp_dir} && ls -1)
                rlFileSubmit "${_tmp_tar}" "failed.tests.tar.gz"
            fi
            rm -rf ${_tmp_tar} ${_tmp_dir}
            ret=1
        fi

        if rlRun -s "egrep 'Not run: [[:digit:]]+' ${_test_results}" 0,1; then
            rlLogWarning "$(cat ${rlRun_LOG})"
        fi

        rlRun "popd"
    fi

    return ${ret}
}

function pcpcommon_cleanup () {
    # Cleanup everything related to pcpqa
    pcpcommon_testsuite_user_cleanup
    rlFileRestore --namespace pcpcommon_init 

    return $?
}

function pcpcommon_pmda_install () {
    local ret=1
    local pmda="$1"
    local retries=${2:-10}
    local metrics

    # Make sure the PMDA's RPM is installed
    if ! rpm -q pcp-pmda-${pmda} &> /dev/null; then
        rlRun "yum install -y pcp-pmda-${pmda}" || return 1
    fi

    # Check if the PMDA is already installed in PCP
    rlRun -s "sed -e 's/^#.*\$//' -e '/^\\s*\$/d' -e '/^\\s*\\[.*\$/,\$ d' \
        ${pcpcommon_PCP_PMCDCONF_PATH} | cut -f 1" 0 "Get the list of installed PMDAs"
    if grep -w ${pmda} "${rlRun_LOG}"; then
        rlLogInfo "${pmda} is already installed"
        ret=0
    else
        if rlRun "pushd ${pcpcommon_PCP_PMDAS_DIR}/${pmda}"; then
            [[ "${pmda}" == "bpftrace" ]] && _pcpcommon_pmda_bpftrace_setup
            if rlRun "./Install < /dev/null"; then
                ret=0

                # Log all values the pmda is providing
                rlRun -s "pminfo -f $(map_metric ${pmda})"
		metrics="${rlRun_LOG}"
		while [[ ${retries} -gt 0 ]]; do
		    if grep -q 'Try again. Information not currently available' \
                        "${metrics}"; then
		        rlRun "sleep 10" 0 "Waiting for metrics to be available"
                        rlRun -s "pminfo -f $(map_metric ${pmda})"
		        metrics="${rlRun_LOG}"
			rlLog "Number of retries left: $(( --retries ))"
		    else
                        retries=0
		    fi
		done
                rlAssertNotGrep "Error: Resource temporarily unavailable" \
		    "${metrics}" || ret=1
                rlAssertNotGrep "Try again. Information not currently available" \
		    "${metrics}" || ret=1
                rlFileSubmit "${metrics}" "pmda.${pmda}.metrics.log"
            fi
            rlRun "popd"
        else
            rlFail "Unable to find PMDA's basedir ${pcpcommon_PCP_PMDAS_DIR}/${pmda}"
        fi
    fi

    return ${ret}
}

function pcpcommon_pmda_remove () {
    local ret=1
    local pmda="$1"

    if rlRun "pushd ${pcpcommon_PCP_PMDAS_DIR}/${pmda}" 0-255; then
        rlRun "./Remove" 0-255 && ret=0
        rlRun "popd"
    else
        rlLogInfo "Unable to find PMDA's basedir ${pcpcommon_PCP_PMDAS_DIR}/${pmda}"
    fi

    return ${ret}
}

function pcpcommon_pmda_check_log () {
    local pmda="$1"
    local errstr="fail|warn|error|crit|denied"
    local logf="${pcpcommon_PCP_LOG_DIR}/pmcd/${pmda}.log"
    local result=0

    # Skip the log check if requested
    case "${PCPCOMMON_PMDA_CHECK_LOG}" in
        0|[Ff][Aa][Ll][Ss][Ee]|[Nn][Oo])
            rlLogInfo "Skipping check of the ${pmda} log file"
            return 0
            ;;
    esac

    if [[ "${pmda}" == "nfsclient" ]]; then
        rlRun -s "grep -v 'ignored, already in cache' ${logf}"
        logf="${rlRun_LOG}"
    fi

    rlAssertNotGrep "${errstr}" ${logf} -Ei || result=1
    rlFileSubmit "${logf}"

    return ${result}
}

function pcpcommon_pmda_tests () {
    local pmda="$1"
    local addparam="$2"
    local testgroup="pmda.${pmda}"

    if rlRun "grep -q ${testgroup} ${pcpcommon_PCP_VAR_DIR}/testsuite/group" 0,1; then
        pcpcommon_test "000 -g ${testgroup} ${addparam}"
        pcpcommon_pmda_check_log ${pmda}
    else
        rlLogInfo "No upstream tests for ${pmda}"
    fi
}

function pcpcommonLibraryLoaded () {
    if ! rpm -q pcp-testsuite &>/dev/null; then
        rlFail "pcp-testsuite RPM is not installed"
        return 1
    fi

    rlFileBackup --namespace pcpcommon_init ${pcpcommon_PCP_ENV}

    # RHEL-6 workaround
    if ! ping -c 1 $(hostname) &> /dev/null; then
        rlFileBackup --namespace pcpcommon_init /etc/hosts
        echo 127.0.0.2 $(hostname) >> /etc/hosts
    fi

    # For PCP versions < '5.1.0' run the testuite as root
    local _pcpver=$(rpm -q --qf '%{version}' pcp)
    local _pcpcmp=$(rlCmpVersion "${_pcpver}" "5.2.0")
    if [[ "${_pcpcmp}" == "<" ]];then
        rlLogInfo "According to the PCP version, the testsuite will run as user: ${pcpcommon_REAL_TESTSUITE_USER}"
        pcpcommon_REAL_TESTSUITE_USER="root"
    fi

    return 0
}
