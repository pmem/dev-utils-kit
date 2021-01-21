#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2021, Intel Corporation

# removeNamespaces.sh - Clear all existing namespaces.
set -e

echo "Clearing all existing namespaces"
MOUNTPOINT=$(lsblk | grep "pmem" | tr -s ' ' | cut -d ' ' -f 7)

for m in $MOUNTPOINT; do
  sudo umount $m
done

namespace_names=$(ndctl list -X | jq -r '.[].dev')

for n in $namespace_names; do
	sudo ndctl clear-errors $n -v
done

sudo ndctl disable-namespace all || true
sudo ndctl destroy-namespace all || true
