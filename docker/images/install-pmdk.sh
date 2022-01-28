#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2018-2021, Intel Corporation

#
# install-pmdk.sh [prefix] [just_install]
#	- PMDK's libraries installation script. Can be use in two ways:
#	1. Regular usage would be to "just install" all PMDK's libraries (preferably from packages).
#	2. The other scenario (when `just_install == 0`) is to 'make install' in '${PREFIX}' and
#		prepare packages (for further use) in '${PREFIX}-pkg' dir. With this usage, it's probably
#		the best to use prefix in a non-system path, e.g. "/opt/pmdk".
#

set -e

if [ "${SKIP_PMDK_BUILD}" ]; then
	echo "Variable 'SKIP_PMDK_BUILD' is set; skipping building PMDK"
	exit
fi

## Script's arguments:
PREFIX=${1:-/usr}
JUST_INSTALL=${2:-1} # if == 0: create extra packages in '${PREFIX}-pkg' dir

## Environment variables:
PACKAGE_TYPE=${PACKAGE_MANAGER,,} # make it lowercase
[ "${PACKAGE_TYPE}" == "deb" ] && PACKAGE_TYPE="dpkg" # XXX: PMDK uses different alias
# common: 1.11.1 release, 24.09.2021
CHECKOUT=${PMDK_VERSION:-5b21904a257eff47f2e87fcbf2de46111f03ddd8}

echo "Installation prefix: '${PREFIX}'"
echo "Bool flag - just_install: '${JUST_INSTALL}'"
echo "Package type: '${PACKAGE_TYPE}'"
echo "Checkout version: '${CHECKOUT}'"

# prepare repo
build_dir=$(mktemp -d -t pmdk-XXX)
git clone https://github.com/pmem/pmdk ${build_dir}
pushd ${build_dir}
git checkout ${CHECKOUT}

# make initial build
make -j$(nproc)
echo "### PMDK compilation complete ###"

if [ "${JUST_INSTALL}" == "1" ]; then
	# install, preferably using packages
	if [ -z "${PACKAGE_TYPE}" ]; then
		sudo make install -j$(nproc) prefix=${PREFIX}
	else
		make BUILD_PACKAGE_CHECK=n "${PACKAGE_TYPE}" -j$(nproc)
		echo "### PMDK package compilation complete ###"
		if [ "${PACKAGE_TYPE}" = "dpkg" ]; then
			sudo dpkg -i dpkg/*.deb
		elif [ "${PACKAGE_TYPE}" = "rpm" ]; then
			sudo rpm -iv rpm/*/*.rpm
		fi
	fi
else
	# install within '${PREFIX}'
	sudo make install -j$(nproc) prefix=${PREFIX}

	# and prepare packages (move them, no install) into '${PREFIX}-pkg/'
	make BUILD_PACKAGE_CHECK=n "${PACKAGE_TYPE}" -j$(nproc)
	echo "### PMDK package compilation complete ###"

	mkdir -p "${PREFIX}-pkg/"
	if [ "${PACKAGE_TYPE}" = "dpkg" ]; then
		sudo mv dpkg/*.deb "${PREFIX}-pkg/"
	elif [ "${PACKAGE_TYPE}" = "rpm" ]; then
		sudo mv rpm/x86_64/*.rpm "${PREFIX}-pkg/"
	fi
fi

popd
rm -r ${build_dir}
