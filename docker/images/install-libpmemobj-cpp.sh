#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2019-2021, Intel Corporation

#
# install-libpmemobj-cpp.sh [prefix]
#	- installs PMDK C++ bindings (libpmemobj-cpp), within given prefix, preferably from packages.
#		Default checkout revision can be overriden with env. var LIBPMEMOBJCPP_VERSION.
#

set -e

if [ "${SKIP_LIBPMEMOBJCPP_BUILD}" ]; then
	echo "Variable 'SKIP_LIBPMEMOBJCPP_BUILD' is set; skipping building libpmemobj-cpp"
	exit
fi

## Script's arguments:
PREFIX=${1:-/usr}

## Environment variables:
PACKAGE_TYPE=${PACKAGE_MANAGER^^} # make it uppercase
# common: 1.13.0 release; 27.07.2021
CHECKOUT=${LIBPMEMOBJCPP_VERSION:-9599f724d4edc3a3d973bac14eeebdc1bc31d327}

echo "Installation prefix: '${PREFIX}'"
echo "Package type: '${PACKAGE_TYPE}'"
echo "Checkout version: '${CHECKOUT}'"

# prepare repo
build_dir=$(mktemp -d -t libpmemobj-cpp-XXX)
git clone https://github.com/pmem/libpmemobj-cpp ${build_dir}
pushd ${build_dir}
git checkout ${CHECKOUT}
mkdir build
pushd build

# turn off all redundant components, set install prefix
cmake .. -DCPACK_GENERATOR="${PACKAGE_TYPE}" -DCMAKE_INSTALL_PREFIX=${PREFIX} \
	-DBUILD_EXAMPLES=OFF -DBUILD_TESTS=OFF -DBUILD_DOC=OFF \
	-DBUILD_BENCHMARKS=OFF -DTESTS_USE_VALGRIND=OFF
echo "### LIBPMEMOBJ-CPP CMake complete ###"

# install, preferably using packages
if [ -z "${PACKAGE_TYPE}" ]; then
	make -j$(nproc) install
else
	make -j$(nproc) package
	echo "### LIBPMEMOBJ-CPP package compilation complete ###"
	if [ "${PACKAGE_TYPE}" = "DEB" ]; then
		sudo dpkg -i libpmemobj++*.deb
	elif [ "${PACKAGE_TYPE}" = "RPM" ]; then
		sudo rpm -iv libpmemobj++*.rpm
	fi
fi

popd
popd
rm -r ${build_dir}
