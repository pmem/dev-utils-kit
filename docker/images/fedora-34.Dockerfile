# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2016-2021, Intel Corporation

#
# Dockerfile - Base image for PMDK related projects.

# Pull base image
FROM registry.fedoraproject.org/fedora:34
MAINTAINER TBD

# Set required environment variables
ENV OS fedora
ENV OS_VER 34
ENV PACKAGE_MANAGER rpm
ENV NOTTY 1

# Base development packages
ARG BASE_DEPS="\
	cmake \
	gcc \
	gcc-c++ \
	git \
	make"

# PMDK's dependencies (optional; libpmemobj-devel package may be used instead)
ARG PMDK_DEPS="\
	autoconf \
	automake \
	daxctl-devel \
	man \
	ndctl-devel \
	pandoc \
	python3 \
	rpm-build \
	rpm-build-libs \
	rpmdevtools \
	which"

# pmem's Valgrind (optional; valgrind-devel may be used instead)
ARG VALGRIND_DEPS="\
	autoconf \
	automake"

# Documentation (optional)
ARG DOC_DEPS="\
	doxygen \
	pandoc"

# Tests (optional)
# NOTE: glibc is installed as a separate command; see below
ARG TESTS_DEPS="\
	gdb \
	libunwind-devel"

# Misc for our builds/CI (optional)
ARG MISC_DEPS="\
	clang \
	hub \
	perl-Text-Diff \
	pkgconf \
	sudo"

# Coverity
ENV COVERITY_DEPS "\
	wget"

# Update packages and install basic tools
RUN dnf update -y \
 && dnf install -y \
	${BASE_DEPS} \
	${PMDK_DEPS} \
	${VALGRIND_DEPS} \
	${DOC_DEPS} \
	${TESTS_DEPS} \
	${MISC_DEPS} \
	${COVERITY_DEPS} \
 && dnf debuginfo-install -y glibc \
 && dnf clean all

# Install valgrind
COPY install-valgrind.sh install-valgrind.sh
RUN ./install-valgrind.sh

# Add user
ENV USER user
ENV USERPASS pass
RUN useradd -m $USER \
 && echo "$USER:$USERPASS" | chpasswd \
 && gpasswd wheel -a $USER
USER $USER
