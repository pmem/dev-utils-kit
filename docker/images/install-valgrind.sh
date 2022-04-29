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

# pmem-3.19: Merge pull request #88 from lukaszstolarczuk/pmem-3.19; 29.04.2022
git checkout 541e1c3d22b34769ad29fa75ab29cce2a65bfa91

./autogen.sh
echo "### Valgrind autogen complete ###"

./configure --prefix=/usr
echo "### Valgrind configure complete ###"

make -j$(nproc)
echo "### Valgrind compilation complete ###"

sudo make -j$(nproc) install

popd
rm -rf ${build_dir}
