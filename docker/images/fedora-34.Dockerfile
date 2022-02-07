# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2016-2022, Intel Corporation

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

# PMDK's dependencies (optional; libpmem*-devel packages may be used instead)
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

# libpmemobj-cpp's dependencies (optional; libpmemobj++-devel package may be used instead)
ARG LIBPMEMOBJ_CPP_DEPS="\
	libatomic \
	tbb-devel"

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

# Update packages and install basic tools
RUN dnf update -y \
 && dnf install -y \
	${BASE_DEPS} \
	${PMDK_DEPS} \
	${VALGRIND_DEPS} \
	${DOC_DEPS} \
	${TESTS_DEPS} \
	${MISC_DEPS} \
 && dnf debuginfo-install -y glibc \
 && dnf clean all

# Install valgrind
COPY install-valgrind.sh install-valgrind.sh
RUN ./install-valgrind.sh

# Copy common installation scripts into image - for further use
COPY install-pmdk.sh /opt/install-pmdk.sh
COPY install-libpmemobj-cpp.sh /opt/install-libpmemobj-cpp.sh

# Add user
ENV USER user
ENV USERPASS pass
RUN useradd -m $USER \
 && echo "$USER:$USERPASS" | chpasswd \
 && gpasswd wheel -a $USER
USER $USER
