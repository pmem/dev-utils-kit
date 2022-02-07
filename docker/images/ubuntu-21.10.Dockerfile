# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2016-2022, Intel Corporation

#
# Dockerfile - Base image for PMDK related projects.

# Pull base image
FROM registry.hub.docker.com/library/ubuntu:21.10
MAINTAINER TBD

# Set required environment variables
ENV OS ubuntu
ENV OS_VER 21.10
ENV PACKAGE_MANAGER deb
ENV NOTTY 1

# Base development packages
ARG BASE_DEPS="\
	build-essential \
	ca-certificates \
	cmake \
	git"

# PMDK's dependencies (optional; libpmem*-dev packages may be used instead)
ARG PMDK_DEPS="\
	autoconf \
	automake \
	debhelper \
	devscripts \
	libdaxctl-dev \
	libndctl-dev \
	man \
	pandoc \
	python3"

# libpmemobj-cpp's dependencies (optional; libpmemobj-cpp-dev package may be used instead)
ARG LIBPMEMOBJ_CPP_DEPS="\
	libatomic1 \
	libtbb-dev"

# pmem's Valgrind (optional; valgrind may be used instead)
ARG VALGRIND_DEPS="\
	autoconf \
	automake"

# Documentation (optional)
ARG DOC_DEPS="\
	doxygen \
	pandoc"

# Tests (optional)
ARG TESTS_DEPS="\
	gdb \
	libc6-dbg \
	libunwind-dev"

# Misc for our builds/CI (optional)
ARG MISC_DEPS="\
	clang \
	libtext-diff-perl \
	pkgconf \
	sudo \
	whois"

ENV DEBIAN_FRONTEND noninteractive

# Update packages and install basic tools
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
	${BASE_DEPS} \
	${PMDK_DEPS} \
	${VALGRIND_DEPS} \
	${DOC_DEPS} \
	${TESTS_DEPS} \
	${MISC_DEPS} \
 && rm -rf /var/lib/apt/lists/* \
 && apt-get clean all

# Install valgrind
COPY install-valgrind.sh install-valgrind.sh
RUN ./install-valgrind.sh

# Copy common installation scripts into image - for further use
COPY install-pmdk.sh /opt/install-pmdk.sh
COPY install-libpmemobj-cpp.sh /opt/install-libpmemobj-cpp.sh

# Add user
ENV USER user
ENV USERPASS pass
RUN useradd -m $USER -g sudo -p `mkpasswd $USERPASS`
USER $USER
