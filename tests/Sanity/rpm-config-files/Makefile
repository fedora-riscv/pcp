# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Makefile of /tools/pcp/Sanity/rpm-config-files
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

export TEST=/tools/pcp/Sanity/rpm-config-files
export TESTVERSION=1.0
export TEST_GIT_REF ?= main
export TEST_GIT_URL ?= https://src.fedoraproject.org/rpms/pcp.git
export TEST_GIT_PATH ?= tests/Sanity/rpm-config-files
export TEST_GIT_SCRIPT ?= ./runtest.sh
export GIT_SSL_NO_VERIFY=true


BUILT_FILES=

FILES=$(METADATA) Makefile PURPOSE runtest.sh

.PHONY: all install download clean

run: $(FILES)
	chmod +x ./runtest.sh
	./runtest.sh

clean:
	rm -f *~ $(BUILT_FILES)


include /usr/share/rhts/lib/rhts-make.include

$(METADATA): Makefile
	@echo "Owner:           Jan Kuřík <jkurik@redhat.com>" > $(METADATA)
	@echo "Name:            $(TEST)" >> $(METADATA)
	@echo "TestVersion:     $(TESTVERSION)" >> $(METADATA)
	@echo "Path:            $(TEST_DIR)" >> $(METADATA)
	@echo "Description:     Verification of rpm config files" >> $(METADATA)
	@echo "Type:            Sanity" >> $(METADATA)
	@echo "TestTime:        30m" >> $(METADATA)
	@echo "RunFor:          pcp" >> $(METADATA)
	@echo "Requires:        pcp rpm-build" >> $(METADATA)
	@echo "Priority:        Normal" >> $(METADATA)
	@echo "License:         GPLv2+" >> $(METADATA)
	@echo "Confidential:    no" >> $(METADATA)
	@echo "Destructive:     no" >> $(METADATA)
	@echo "Bug:             1963938 1964253" >> $(METADATA)
	@echo "Releases:        -RHEL4 -RHEL6 -RHELClient5 -RHELServer5 -RHEL7" >> $(METADATA)

	rhts-lint $(METADATA)
