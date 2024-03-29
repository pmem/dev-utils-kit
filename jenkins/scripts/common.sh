#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2019-2021, Intel Corporation

# common.sh - Contains bash functions used in all jenkins pipelines.

set -o pipefail

scriptdir=$(readlink -f $(dirname ${BASH_SOURCE[0]}))

function system_info {
	echo "********** system_info **********"
	cat /etc/os-release | grep -oP "PRETTY_NAME=\K.*"
	uname -r
	echo "libndctl: $(pkg-config --modversion libndctl || echo 'libndctl not found')"
	echo "libfabric: $(pkg-config --modversion libfabric || echo 'libfabric not found')"
	echo "libpmem: $(pkg-config --modversion libpmem || echo 'libpmem not found')"
	echo "libpmemobj: $(pkg-config --modversion libpmemobj || echo 'libpmemobj not found')"
	echo "libpmemobj++: $(pkg-config --modversion libpmemobj++ || echo 'libpmemobj++ not found')"
	echo "memkind: $(pkg-config --modversion memkind || echo 'memkind not found')"
	echo "librpma: $(pkg-config --modversion librpma || echo 'librpma not found')"
	echo "libpmemkv:  $(pkg-config --modversion libpmemkv || echo 'libpmemkv not found')"
	echo "TBB : $(pkg-config --modversion TBB || echo 'TBB not found')"
	echo "valgrind: $(pkg-config --modversion valgrind || echo 'valgrind not found')"
	echo "******************** memory-info *******************"
	sudo ipmctl show -dimm || true
	sudo ipmctl show -topology || true
	echo "*************** list-existing-namespaces ***************"
	sudo ndctl list -M -N
	echo "*************** installed-packages ***************"
	# Instructions below will return some minor errors, as they are dependent on the Linux distribution.
	zypper se --installed-only 2>/dev/null || true
	apt list --installed 2>/dev/null || true
	yum list installed 2>/dev/null || true
	echo "**********/proc/cmdline**********"
	cat /proc/cmdline
	echo "**********/proc/modules**********"
	cat /proc/modules
	echo "**********/proc/cpuinfo**********"
	cat /proc/cpuinfo
	echo "**********/proc/meminfo**********"
	cat /proc/meminfo
	echo "**********/proc/swaps**********"
	cat /proc/swaps
	echo "**********/proc/version**********"
	cat /proc/version
	echo "**********check-updates**********"
	# Instructions below will return some minor errors, as they are dependent on the Linux distribution.
	sudo zypper list-updates 2>/dev/null || true
	sudo apt-get update 2>/dev/null || true
	sudo apt upgrade --dry-run 2>/dev/null || true
	sudo dnf check-update 2>/dev/null || true
	echo "**********list-enviroment**********"
	env
}

function set_warning_message {
	local info_addr=$1
	sudo bash -c "cat > /etc/motd <<EOL
 ___            ___
/   \          /   \                            HELLO!
\_   \        /  __/            THIS NODE IS CONNECTED TO PMEM ORIENTED JENKINS
 _\   \      /  /__             THERE ARE TESTS CURRENTLY RUNNING ON THIS MACHINE
 \___  \____/   __/                         PLEASE GO AWAY :)
     \_       _/
       | @ @  \_
       |                        FOR MORE INFORMATION GO: ${info_addr}
     _/     /\ 
    /o)  (o/\ \_
    \_____/ /
      \____/

EOL"
}

function disable_warning_message {
	sudo rm -f /etc/motd
}

# Check host Linux distribution and return distro name
function check_distro {
	distro=$(cat /etc/os-release | grep -e ^NAME= | cut -c6-) && echo "${distro//\"}"
}
