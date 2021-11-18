# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2016-2021, Intel Corporation

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

# PMDK's dependencies (optional; libpmemobj-devel package may be used instead)
ARG PMDK_DEPS="\
	autoconf \
	automake \
	debhelper \
	devscripts \
	libdaxctl-dev \
	libndctl-dev \
	man \
	python3"

# pmem's Valgrind (optional; valgrind-devel may be used instead)
ARG VALGRIND_DEPS="\
	autoconf \
	automake"

# Documentation (optional)
ARG DOC_DEPS="\
	doxygen \
	pandoc "

# Tests (optional)
# NOTE: glibc is installed as a separate command; see below
ARG TESTS_DEPS="\
	gdb \
	libunwind-dev"

# Misc for our builds/CI (optional)
ARG MISC_DEPS="\
	clang \
	libtext-diff-perl \
	pkgconf \
	sudo \
	whois"

# Coverity
ENV COVERITY_DEPS "\
	curl \
	ruby \
	wget"

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
	${COVERITY_DEPS} \
 && rm -rf /var/lib/apt/lists/* \
 && apt-get clean all

# Install valgrind
COPY install-valgrind.sh install-valgrind.sh
RUN ./install-valgrind.sh

# Add user
ENV USER user
ENV USERPASS pass
RUN useradd -m $USER -g sudo -p `mkpasswd $USERPASS`
USER $USER
