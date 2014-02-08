#!/bin/bash

# originally created by schischu and konfetti
# fedora parts prepared by lareq
# fedora/suse/ubuntu scripts merged by kire pudsje (kpc)

if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root (sudo $0)" 1>&2
	exit 1
fi

# make sure defines have not already been defined
UBUNTU=
FEDORA=
SUSE=

# Try to detect the distribution
if `which lsb_release > /dev/null 2>&1`; then 
	case `lsb_release -s -i` in
		Debian*) UBUNTU=1; INSTALL="apt-get -y install";;
		Fedora*) FEDORA=1; INSTALL="yum install -y";;
		SUSE*)   SUSE=1;   INSTALL="zypper install -y";;
		Ubuntu*) UBUNTU=1; INSTALL="apt-get -y install";;
		LinuxM*) UBUNTU=1; INSTALL="apt-get --force-yes install";;
	esac
fi

# Not detected by lsb_release, try release files
if [ -z "$FEDORA$SUSE$UBUNTU" ]; then
	if   [ -f /etc/redhat-release ]; then FEDORA=1; INSTALL="yum install -y"; 
	elif [ -f /etc/fedora-release ]; then FEDORA=1; INSTALL="yum install -y"; 
	elif [ -f /etc/SuSE-release ];   then SUSE=1;   INSTALL="zypper install -y";
	elif [ -f /etc/debian_version ]; then UBUNTU=1; INSTALL="apt-get --force-yes install";
	fi
fi

# still not detected, display error and let the user manually install
if [ -z "$FEDORA$SUSE$UBUNTU" ]; then
	echo
	echo "Cannot determine which OS distribution you use," 
	echo "or your distribution is not (yet) supported." 
	echo "Please report this fact in the AAF or Kathi-forums"
	echo
	echo "Try installing the following packages: "
	# determine probable distribution, based on package system, 
	# Suse should be last because the others may also have rpm installed.
	{ `which apt-get > /dev/null 2>&1` && UBUNTU=1; } || \
	{ `which yum     > /dev/null 2>&1` && FEDORA=1; } || \
	SUSE=2
	INSTALL="echo "
fi

if [ "$SUSE" == 1 ]; then
	SUSE_VERSION=`cat /etc/SuSE-release | line | awk '{ print $2 }'`
	if [ "$SUSE_VERSION" == "12.2" ]; then
		zypper ar "http://download.opensuse.org/repositories/home:/toganm/openSUSE_12.2/" fakeroot
	fi
	if [ "$SUSE_VERSION" == "12.1" ]; then
		zypper ar "http://download.opensuse.org/repositories/home:/toganm/openSUSE_12.1/" fakeroot
	fi
	if [ "$SUSE_VERSION" == "11.3" ]; then
		zypper ar "http://download.opensuse.org/repositories/home:/toganm/openSUSE_11.3/" fakeroot
	fi
	if [ "$SUSE_VERSION" == "11.4" ]; then
		zypper ar "http://download.opensuse.org/repositories/home:/toganm/openSUSE_11.4/" fakeroot
	fi
	zypper ref
fi

PACKAGES="\
	make \
	subversion \
	ccache \
	flex \
	bison \
	texinfo \
	libtool \
	swig \
	dialog \
	wget \
	\
	${UBUNTU:+rpm}                                               ${FEDORA:+rpm-build} \
	${UBUNTU:+lsb-release}          ${SUSE:+lsb-release}         ${FEDORA:+redhat-lsb} \
	${UBUNTU:+git-core}             ${SUSE:+git-core}            ${FEDORA:+git} \
	${UBUNTU:+libncurses5-dev}      ${SUSE:+ncurses-devel}       ${FEDORA:+ncurses-devel} \
	${UBUNTU:+gettext}              ${SUSE:+gettext-devel}       ${FEDORA:+gettext-devel} \
	${UBUNTU:+zlib1g-dev}           ${SUSE:+zlib-devel}          ${FEDORA:+zlib-devel} \
	${UBUNTU:+g++}                  ${SUSE:+gcc gcc-c++}         ${FEDORA:+gcc-c++} \
	${UBUNTU:+automake}             ${SUSE:+automake make} \
	${UBUNTU:+xfslibs-dev}          ${SUSE:+xfsprogs-devel} \
	${UBUNTU:+pkg-config}           ${SUSE:+pkg-config} \
	${UBUNTU:+patch}                ${SUSE:+patch} \
	${UBUNTU:+autopoint}            ${SUSE:+glib2-devel} \
	${UBUNTU:+cfv}                  ${SUSE:+fakeroot} \
	${UBUNTU:+fakeroot} \
	${UBUNTU:+gawk} \
	${UBUNTU:+gperf} \
	${UBUNTU:+libglib2.0-bin} \
	${UBUNTU:+libglib2.0-dev} \
	${UBUNTU:+doc-base} \
	${UBUNTU:+texi2html} \
	${UBUNTU:+help2man} \
	${UBUNTU:+libgpgme11-dev} \
	${UBUNTU:+libcurl4-openssl-dev} \
	${UBUNTU:+liblzo2-dev} \
	${UBUNTU:+libsdl-image1.2} \
	${UBUNTU:+libsdl-image1.2-dev} \
	${UBUNTU:+cmake} \
	${UBUNTU:+ruby} \
	${UBUNTU:+python-dev} \
";

if [ `which arch > /dev/null 2>&1 && arch || uname -m` == x86_64 ]; then
	# ST changed to the -m32 option for their gcc compiler build
	# we might need to install more 32bit versions of some packages
	PACKAGES="$PACKAGES \
	${UBUNTU:+gcc-multilib}         ${SUSE:+gcc-32bit}           ${FEDORA:+libstdc++-devel.i686} \
	${UBUNTU:+libc6-dev-i386}       ${SUSE:+zlib-devel-32bit}    ${FEDORA:+glibc-devel.i686} \
	${UBUNTU:+lib32z1-dev}                                       ${FEDORA:+libgcc.i686} \
	                                                             ${FEDORA:+ncurses-devel.i686} \
	";
fi
$INSTALL $PACKAGES

# Link sh to bash instead of dash on Ubuntu (and possibly others)
/bin/sh --version 2>/dev/null | grep bash -s -q
if [ ! "$?" -eq "0" ]; then
	echo
	read -p "/bin/sh should link to /bin/bash, adjust it (Y/n)? "
	if [ -z "$REPLY" -o "$REPLY" == "Y" -o "$REPLY" == "y" ]; then
		rm -f /bin/sh
		ln -s /bin/bash /bin/sh
	fi
fi

# for user mknod
chmod +s /bin/mknod
