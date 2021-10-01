#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2019-2021, Intel Corporation

# createNamespace.sh - Remove old namespaces and create new for pmem oriented tests.

set -e

# Region used for dax namespaces. The number represents the region's socket ID, as seen by using the command 'ipmctl show -region'.
# Currently, this variable is used to restrict the creation process to only one namespace type per region.
DEV_DAX_R=0x0000
# Region used for fsdax namespaces. The number represents the region's socket ID, as seen by using the command 'ipmctl show -region'.
# Currently, this variable is used to restrict the creation process to only one namespace type per region.
FS_DAX_R=0x0001
CREATE_DAX=false
CREATE_PMEM=false
MOUNTPOINT="/mnt/pmem0"
# The default size of namespaces.
SIZE=100G
# This user will be set as an owner of created namespace(s). It's required e.g. for pool creation in tests.
USERNAME=test-user

function usage()
{
	echo
	echo "Script for creating namespaces, a mountpoint, and configuring file permissions."
	echo "Usage: $(basename $1) [-h|--help]  [-d|--dax] [-p|--pmem] [--size]"
	echo "-h, --help       Print help and exit"
	echo "-d, --dax        Create dax device"
	echo "-p, --pmem       Create fsdax device and create mountpoint"
	echo "--size           Set size for namespaces [default: $SIZE]"
}

function remove_namespaces() {
	scriptdir=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
	$scriptdir/removeNamespaces.sh
}

function create_devdax() {
	echo "Creating devdax namespace"
	local align=$1
	local size=$2
	local cmd="sudo ndctl create-namespace --mode devdax -a ${align} -s ${size} -r ${DEV_DAX_R} -f"
	result=$(${cmd})
	if [ $? -ne 0 ]; then
		exit 1
	fi
	jq -r '.daxregion.devices[].chardev' <<< $result
}

function create_fsdax() {
	local size=$1
	local cmd="sudo ndctl create-namespace --mode fsdax -s ${size} -r ${FS_DAX_R} -f"
	result=$(${cmd})
	if [ $? -ne 0 ]; then
		exit 1
	fi
	jq -r '.blockdev' <<< $result
}

while getopts ":dhp-:" optchar; do
	case "${optchar}" in
		-)
		case "$OPTARG" in
			help) usage $0 && exit 0 ;;
			dax) CREATE_DAX=true ;;
			pmem) CREATE_PMEM=true ;;
			size=*) SIZE="${OPTARG#*=}" ;;
			*) echo "Invalid argument '$OPTARG'"; usage $0 && exit 1 ;;
		esac
		;;
		p) CREATE_PMEM=true ;;
		d) CREATE_DAX=true ;;
		h) usage $0 && exit 0 ;;
		*) echo "Invalid argument '$OPTARG'"; usage $0 && exit 1 ;;
	esac
done

# There is no default test configuration in this script. Configurations have to be specified.
if ! $CREATE_DAX && ! $CREATE_PMEM; then
	echo
	echo "ERROR: No configuration type selected. Please select one or more configuration types."
	exit 1
fi

# Remove existing namespaces.
remove_namespaces

# Creating namespaces.
trap 'echo "ERROR: Failed to create namespaces"; remove_namespaces; exit 1' ERR SIGTERM SIGABRT

if $CREATE_DAX; then
	create_devdax 4k $SIZE
	# Setting DAX ownership for the specific user.
	sudo chown -R $USERNAME /dev/dax*
fi

# Creating mountpoint.
trap 'echo "ERROR: Failed to create mountpoint"; remove_namespaces; exit 1' ERR SIGTERM SIGABRT

if $CREATE_PMEM; then

	echo "Creating fsdax namespace"
	pmem_name=$(create_fsdax $SIZE)

	if [ ! -d "$MOUNTPOINT" ]; then
		sudo mkdir $MOUNTPOINT
	fi

	if ! grep -qs "$MOUNTPOINT " /proc/mounts; then
		sudo mkfs.ext4 -F /dev/$pmem_name
		sudo mount -o dax /dev/$pmem_name $MOUNTPOINT
		# Setting mountpoint ownership for the specific user.
		sudo chown -R $USERNAME $MOUNTPOINT
	fi

	echo "Mount point: ${MOUNTPOINT}"
fi

# By using PMDK's pmempool-feature one can enable or disable the CHECK_BAD_BLOCKS compat feature.
# This feature enables checking and fixing bad blocks. Currently these operations require read
# access to the following resource files (containing physical addresses) of NVDIMM devices which only the super user
# can read by default:

# /sys/bus/nd/devices/ndbus*/region*/resource
# /sys/bus/nd/devices/ndbus*/region*/dax*/resource
# /sys/bus/nd/devices/ndbus*/region*/pfn*/resource
# /sys/bus/nd/devices/ndbus*/region*/namespace*/resource
#
# Note: Pmem libpmemset and libpmem2 libraries contain pmem_deep_flush functions,
# which requires write access to '/sys/bus/nd/devices/region*/deep_flush'.

echo "Changing file permissions"
sudo chmod a+rw /sys/bus/nd/devices/region*/deep_flush
sudo chmod +r /sys/bus/nd/devices/ndbus*/region*/resource
sudo chmod +r /sys/bus/nd/devices/ndbus*/region*/dax*/resource
sudo chmod +r /sys/bus/nd/devices/ndbus*/region*/pfn*/resource
sudo chmod +r /sys/bus/nd/devices/ndbus*/region*/namespace*/resource

echo "Print created namespaces:"
ndctl list -X | jq -r '.[] | select(.mode=="devdax") |
[.daxregion.devices[].chardev, "align: "+(.align/1024|tostring+"k"), "size: "+(.size/1024/1024/1024|tostring+"G") ]'
ndctl list | jq -r '.[] | select(.mode=="fsdax") | [.blockdev, "size: "+(.size/1024/1024/1024|tostring+"G") ]'
