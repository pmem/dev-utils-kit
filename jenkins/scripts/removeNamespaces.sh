#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2021, Intel Corporation

# removeNamespaces.sh - Clear all existing namespaces.
set -e

echo "Clearing all existing namespaces"
MOUNTPOINTS=$(lsblk | grep "pmem" | grep "/" | tr -s ' ' | cut -d ' ' -f 7)
for m in $MOUNTPOINTS; do
  sudo umount $m
done

NAMESPACE_NAMES=$(ndctl list -X | jq -r '.[].dev')
for n in $NAMESPACE_NAMES; do
	sudo ndctl clear-errors $n -v
done

sudo ndctl disable-namespace all
sudo ndctl destroy-namespace all
