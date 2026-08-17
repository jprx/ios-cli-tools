#!/bin/bash
set -euo pipefail

export SRCDIR="${PWD}/src"
export WORKDIR="${PWD}/build"
export OUTDIR="${PWD}/sysroot"

export DASH_VERS="v0.5.13.5"
export DASH_REPO="https://git.kernel.org/pub/scm/utils/dash/dash.git"

export COREUTILS_VERS="coreutils-9.11"
export COREUTILS_URL="https://ftp.gnu.org/gnu/coreutils/${COREUTILS_VERS}.tar.xz"

export PREFIX="/"

CLANG="$(xcrun -sdk iphoneos --find clang)"
SYSROOT="$(xcrun -sdk iphoneos --show-sdk-path)"

export CC="${CLANG}"
export CFLAGS="-target arm64-apple-ios -isysroot ${SYSROOT}"

setup_dirs() {
  mkdir -p "${SRCDIR}"
  mkdir -p "${WORKDIR}"
  mkdir -p "${OUTDIR}"
}

# get_git_src
# Argument 1: the project name
# Argument 2: the project repo URL
# Argument 3: which tag/ branch to checkout
get_git_src() {
  local PROJECT_NAME="${1}"
  local PROJECT_REPO="${2}"
  local PROJECT_VERS="${3}"
  if [[ -d "${SRCDIR}/${PROJECT_NAME}" ]]; then
    return
  fi

  cd "${SRCDIR}" || exit
  git clone --depth 1 --branch "${PROJECT_VERS}" "${PROJECT_REPO}" "${PROJECT_NAME}"
}

# get_tarball_src
# Argument 1: the project name + version (eg. "coreutils-9.11")
# Argument 2: the project URL (eg. "https://ftp.gnu.org/gnu/coreutils/coreutils-9.11.tar.xz")
get_tarball_src() {
  local PROJECT_VERSION="${1}"
  local PROJECT_URL="${2}"
  if [[ -d "${SRCDIR}/${PROJECT_VERSION}" ]]; then
    return
  fi

  cd "${SRCDIR}" || exit
  wget "${PROJECT_URL}"
  tar -xf "${SRCDIR}/${PROJECT_VERSION}.tar.xz"
}

build_dash() {
  local DASH_NAME="dash"

  if [[ -f "${OUTDIR}/bin/sh" ]]; then
    echo "${DASH_NAME} already built"
    return
  fi

  echo "Building ${DASH_NAME}"

  get_git_src "${DASH_NAME}" "${DASH_REPO}" "${DASH_VERS}"
  cd "${SRCDIR}/${DASH_NAME}" || exit
  ./autogen.sh

  # We are always cross compiling
  sed -i.bak 's/cross_compiling=maybe/cross_compiling=yes/g' "${SRCDIR}/${DASH_NAME}/configure"
  sed -i.bak 's/cross_compiling=no/cross_compiling=yes/g' "${SRCDIR}/${DASH_NAME}/configure"

  mkdir -p "${WORKDIR}/build-${DASH_NAME}"
  cd "${WORKDIR}/build-${DASH_NAME}" || exit

  CC="${CC}" CFLAGS="${CFLAGS}" "${SRCDIR}/${DASH_NAME}/configure" --host="arm64-apple-ios" --program-transform-name="s/dash/sh/" --prefix="${PREFIX}"

  make
  make DESTDIR="${OUTDIR}" install
}

build_coreutils() {
  if [[ -f "${OUTDIR}/bin/ls" ]]; then
    echo "${COREUTILS_VERS} already built"
    return
  fi

  echo "Building ${COREUTILS_VERS}"

  get_tarball_src "${COREUTILS_VERS}" "${COREUTILS_URL}"

  mkdir -p "${WORKDIR}/build-${COREUTILS_VERS}"
  cd "${WORKDIR}/build-${COREUTILS_VERS}" || exit

  CC="${CC}" CFLAGS="${CFLAGS}" "${SRCDIR}/${COREUTILS_VERS}/configure" --host="arm64-apple-ios" ac_cv_func_clock_settime="no" gl_cv_have_unlimited_file_name_length="no" --disable-nls --prefix="${PREFIX}"

  make
  make DESTDIR="${OUTDIR}" install
}

main() {
  setup_dirs
  build_dash
  build_coreutils
}

main "$@"
