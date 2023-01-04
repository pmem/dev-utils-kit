#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2016-2023, Intel Corporation

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

# pmem-3.20: "-> 3.20.0 final"; 03.01.2023
git checkout b21a0ab76d2fbc4f26d2b7c7e20df63d63f0a31b

./autogen.sh
echo "### Valgrind autogen complete ###"

./configure --prefix=/usr
echo "### Valgrind configure complete ###"

make -j$(nproc)
echo "### Valgrind compilation complete ###"

sudo make -j$(nproc) install

popd
rm -rf ${build_dir}
