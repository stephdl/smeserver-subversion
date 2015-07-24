# $Id: smeserver-subversion.spec,v 1.3 2012/09/07 15:56:41 snetram Exp $
# Authority: snetram
# Name: Jonathan Martens

Summary: Subversion for SME Server
%define name smeserver-subversion
Name: %{name}
%define version 1.5
%define release 3
Version: %{version}
Release: %{release}%{?dist}
License: GPL
Group: Applications/Internet
Source: %{name}-%{version}.tgz
BuildArchitectures: noarch
BuildRoot: /var/tmp/%{name}-%{version}-%{release}-buildroot
Requires: smeserver-mod_dav subversion >= 1.2 
Requires: smeserver-release >= 8 
Requires: mod_dav_svn httpd >= 2 
Requires: e-smith-formmagick >= 1.4.0-12
BuildRequires: e-smith-devtools >= 1.13.1-03

%description
Implementation of Subversion for SME Server 8 using WebDAV.

%changelog
* Fri Sep 7 2012 Jonathan Martens <smeserver-contribs@snetram.nl> 1.5-3.sme
- Fix location of pwauth on 64 bit systems [SME: 7093]

* Wed Jun 13 2012 Jonathan Martens <smeserver-contribs@snetram.nl> 1.5-2.sme
- Prevent empty description [SME: 6988]
- Apply latest locale patch

* Sat May 26 2012 Jonathan Martens <smeserver-contribs@snetram.nl> 1.5-1.sme
- Initial version

%prep
%setup

%build
perl createlinks

%install
rm -rf $RPM_BUILD_ROOT
(cd root ; find . -depth -print | cpio -dump $RPM_BUILD_ROOT)
rm -f %{name}-%{version}-filelist
/sbin/e-smith/genfilelist $RPM_BUILD_ROOT > %{name}-%{version}-filelist

%clean
rm -rf $RPM_BUILD_ROOT

%files -f %{name}-%{version}-filelist
%defattr(-,root,root)
