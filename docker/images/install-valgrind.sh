#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2016-2021, Intel Corporation

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

# pmem-3.17: Merge pull request #85 from lukaszstolarczuk/pmem-3.17; 16.08.2021
git checkout ff6f0f125f8e1b1a2a8615f2b14efeaf135ad01b

./autogen.sh
echo "### Valgrind autogen complete ###"

./configure --prefix=/usr
echo "### Valgrind configure complete ###"

make -j$(nproc)
echo "### Valgrind compilation complete ###"

sudo make -j$(nproc) install

popd
rm -rf ${build_dir}
