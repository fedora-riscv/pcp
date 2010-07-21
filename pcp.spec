Summary: System-level performance monitoring and performance management
Name: pcp
Version: 3.3.3
%define buildversion 1

Release: %{buildversion}%{?dist}
License: GPLv2
URL: http://oss.sgi.com/projects/pcp
Group: Applications/System
Source0: ftp://oss.sgi.com/projects/pcp/download/pcp-%{version}-%{buildversion}.src.tar.gz

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires: procps autoconf bison flex ncurses-devel readline-devel
BuildRequires: perl(ExtUtils::MakeMaker)
BuildRequires: initscripts
 
Requires: bash gawk sed grep fileutils findutils cpp initscripts
Requires: pcp-libs = %{version}

%define _pmdasdir %{_localstatedir}/lib/pcp/pmdas

%description
Performance Co-Pilot (PCP) provides a framework and services to support
system-level performance monitoring and performance management. 

The PCP open source release provides a unifying abstraction for all of
the interesting performance data in a system, and allows client
applications to easily retrieve and process any subset of that data. 

#
# pcp-libs
#
%package libs
License: LGPLv2
Group: Applications/System
Summary: Performance Co-Pilot run-time libraries
URL: http://oss.sgi.com/projects/pcp/

%description libs
Performance Co-Pilot (PCP) run-time libraries

#
# pcp-libs-devel
#
%package libs-devel
License: GPLv2
Group: Applications/System
Summary: Performance Co-Pilot (PCP) development headers and documentation
URL: http://oss.sgi.com/projects/pcp/

Requires: pcp-libs = %{version}

%description libs-devel
Performance Co-Pilot (PCP) headers, documentation and tools for development.

#
# perl-PCP-PMDA. This is the PCP agent perl binding.
#
%package -n perl-PCP-PMDA
License: GPLv2
Group: Applications/System
Summary: Performance Co-Pilot (PCP) Perl bindings and documentation
URL: http://oss.sgi.com/projects/pcp/
Requires: pcp >= %{version}

%description -n perl-PCP-PMDA
The PCP::PMDA Perl module contains the language bindings for
building Performance Metric Domain Agents (PMDAs) using Perl.
Each PMDA exports performance data for one specific domain, for
example the operating system kernel, Cisco routers, a database,
an application, etc.

#
# perl-PCP-MMV
#
%package -n perl-PCP-MMV
License: GPLv2
Group: Applications/System
Summary: Performance Co-Pilot (PCP) Perl bindings for PCP Memory Mapped Values
URL: http://oss.sgi.com/projects/pcp/
Requires: pcp >= %{version}

%description -n perl-PCP-MMV
The PCP::MMV module contains the Perl language bindings for
building scripts instrumented with the Performance Co-Pilot
(PCP) Memory Mapped Value (MMV) mechanism.
This mechanism allows arbitrary values to be exported from an
instrumented script into the PCP infrastructure for monitoring
and analysis with pmchart, pmie, pmlogger and other PCP tools.

%prep
%setup -q
autoconf

# The standard 'configure' macro should be used here, but configure.in
# needs some tweaks before that will work correctly (TODO).
./configure --libdir=%{_libdir} --libexecdir=%{_libexecdir}

%clean
rm -Rf $RPM_BUILD_ROOT

%build
make default_pcp

%install
rm -Rf $RPM_BUILD_ROOT
export DIST_ROOT=$RPM_BUILD_ROOT
make install_pcp

# Fix stuff we do/don't want to ship
rm -f $RPM_BUILD_ROOT/%{_libdir}/*.a
mkdir -p $RPM_BUILD_ROOT/%{_localstatedir}/run/pcp

# default chkconfig off for Fedora and RHEL
for f in $RPM_BUILD_ROOT/%{_sysconfdir}/rc.d/init.d/{pcp,pmie,pmproxy}; do
	sed -i -e '/^# chkconfig/s/:.*$/: - 95 05/' -e '/^# Default-Start:/s/:.*$/:/' $f
done

# list of PMDAs in the base pkg
ls -1 $RPM_BUILD_ROOT/%{_pmdasdir} | egrep -v 'simple|sample|trivial|txmon' |\
sed -e 's#^#'%{_pmdasdir}'\/#' >base_pmdas.list

%preun
if [ "$1" -eq 0 ]
then
    #
    # Stop daemons before erasing the package
    #
    /sbin/service pcp stop >/dev/null 2>&1
    /sbin/service pmie stop >/dev/null 2>&1
    /sbin/service pmproxy stop >/dev/null 2>&1

    /sbin/chkconfig --del pcp >/dev/null 2>&1
    /sbin/chkconfig --del pmie >/dev/null 2>&1
    /sbin/chkconfig --del pmproxy >/dev/null 2>&1
fi

%post
/sbin/chkconfig --add pcp >/dev/null 2>&1
/sbin/chkconfig --add pmie >/dev/null 2>&1
/sbin/chkconfig --add pmproxy >/dev/null 2>&1

%post libs -p /sbin/ldconfig
%postun libs -p /sbin/ldconfig

%files -f base_pmdas.list
#
# Note: there are some headers (e.g. domain.h) and in a few cases some
# C source files that rpmlint complains about. These are not devel files,
# but rather they are (slightly obscure) PMDA config files.
#
%defattr(-,root,root)
%doc CHANGELOG COPYING INSTALL README VERSION.pcp pcp.lsm

%dir %{_pmdasdir}
%dir %{_datadir}/pcp
%dir %{_localstatedir}/run/pcp
%dir %{_localstatedir}/lib/pcp
%dir %{_localstatedir}/lib/pcp/config

%{_bindir}/*
%{_libexecdir}/pcp
%{_datadir}/pcp/lib
%{_localstatedir}/log/pcp
%{_localstatedir}/lib/pcp/pmns
%{_initrddir}/pcp
%{_initrddir}/pmie
%{_initrddir}/pmproxy
%{_mandir}/man1/*
%{_mandir}/man4/*
%config %{_sysconfdir}/bash_completion.d/pcp
%config %{_sysconfdir}/pcp.env
%config(noreplace) %{_localstatedir}/lib/pcp/config/pmcd/pmcd.conf
%config(noreplace) %{_localstatedir}/lib/pcp/config/pmcd/pmcd.options
%config(noreplace) %{_localstatedir}/lib/pcp/config/pmcd/rc.local
%config(noreplace) %{_localstatedir}/lib/pcp/config/pmie/config.default
%config(noreplace) %{_localstatedir}/lib/pcp/config/pmie/control
%config(noreplace) %{_localstatedir}/lib/pcp/config/pmie/crontab
%config(noreplace) %{_localstatedir}/lib/pcp/config/pmlogger/config.default
%config(noreplace) %{_localstatedir}/lib/pcp/config/pmlogger/control
%config(noreplace) %{_localstatedir}/lib/pcp/config/pmlogger/crontab
%config(noreplace) %{_localstatedir}/lib/pcp/config/pmproxy/pmproxy.options
%{_localstatedir}/lib/pcp/config/*

%files libs
%defattr(-,root,root)

%dir %{_includedir}/pcp
%{_includedir}/pcp/builddefs
%{_includedir}/pcp/buildrules
%config %{_sysconfdir}/pcp.conf
%{_libdir}/libpcp.so.3
%{_libdir}/libpcp_gui.so.2
%{_libdir}/libpcp_mmv.so.1
%{_libdir}/libpcp_pmda.so.3
%{_libdir}/libpcp_trace.so.2

%files libs-devel
%defattr(-,root,root)

%{_libdir}/libpcp.so
%{_libdir}/libpcp.so.2
%{_libdir}/libpcp_gui.so
%{_libdir}/libpcp_gui.so.1
%{_libdir}/libpcp_mmv.so
%{_libdir}/libpcp_pmda.so
%{_libdir}/libpcp_pmda.so.2
%{_libdir}/libpcp_trace.so
%{_includedir}/pcp/*.h
%{_mandir}/man3/*.3.gz
%{_datadir}/pcp/demos
%{_datadir}/pcp/examples

# PMDAs that ship src and are not for production use
# straight out-of-the-box, for devel or QA use only.
%{_localstatedir}/lib/pcp/pmdas/simple
%{_localstatedir}/lib/pcp/pmdas/sample
%{_localstatedir}/lib/pcp/pmdas/trivial
%{_localstatedir}/lib/pcp/pmdas/txmon

%files -n perl-PCP-PMDA -f perl-pcp-pmda.list
%defattr(-,root,root)

%files -n perl-PCP-MMV -f perl-pcp-mmv.list
%defattr(-,root,root)

%changelog
* Fri Jul 16 2010 Mark Goodwin - 3.3.3-1
- Update to latest PCP sources.

* Sat Jul 10 2010 Mark Goodwin - 3.3.2-1
- Update to latest PCP sources.

* Tue Jun 29 2010 Mark Goodwin - 3.3.1-1
- Update to latest PCP sources.

* Fri Jun 25 2010 Mark Goodwin - 3.3.0-1
- Update to latest PCP sources.

* Thu Mar 18 2010 Mark Goodwin - 3.1.2-1
- Update to latest PCP sources.

* Wed Jan 27 2010 Mark Goodwin - 3.1.0-1
- BuildRequires: initscripts for %{_vendor} == redhat.

* Thu Dec 10 2009 Mark Goodwin - 3.0.3-1
- BuildRequires: initscripts for FC12.

* Wed Dec 02 2009 Mark Goodwin - 3.0.2-1
- Added sysfs.kernel metrics, rebased to minor community release.

* Mon Oct 19 2009 Martin Hicks <mort@sgi.com> - 3.0.1-2
- Remove IB dependencies.  The Infiniband PMDA is being moved to
  a stand-alone package.
- Move cluster PMDA to a stand-alone package.

* Fri Oct 9 2009 Mark Goodwin <mgoodwin@redhat.com> - 3.0.0-9
- This is the initial import for Fedora
- See 3.0.0 details in CHANGELOG
