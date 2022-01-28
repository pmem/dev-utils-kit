#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2016-2022, Intel Corporation

#
# install-valgrind.sh - installs valgrind with pmemcheck
#

set -e

if [ "${SKIP_VALGRIND_BUILD}" ]; then
	echo "Variable 'SKIP_VALGRIND_BUILD' is set; skipping building valgrind (pmem's fork)"
	exit
fi

build_dir=$(mktemp -d -t valgrind-XXX)
git clone https://github.com/pmem/valgrind.git ${build_dir}
pushd ${build_dir}

# pmem-3.18: memcheck: fix test addressable err exp; 21.01.2022
git checkout 06f15d69237501852dd29883940e18da4179830a

./autogen.sh
echo "### Valgrind autogen complete ###"

./configure --prefix=/usr
echo "### Valgrind configure complete ###"

make -j$(nproc)
echo "### Valgrind compilation complete ###"

sudo make -j$(nproc) install

popd
rm -rf ${build_dir}
