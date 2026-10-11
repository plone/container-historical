#!/bin/sh
# Build a historical CPython 2.x from source on a modern toolchain.
#
# Usage: build-python2.sh <src-tarball> <version> <prefix>
#   e.g. build-python2.sh /dist/python.tgz 2.4.6 /opt/python2.4
#
# Set PYTHON_REQUIRE_SSL=1 to make `ssl` part of the gate. Only 2.7 can use it:
# its _ssl.c builds against the OpenSSL 3.0 that bookworm ships, while 2.6 and
# older need the pre-1.1 OpenSSL structs and fail to compile.
#
# Shared by every tarball-era image (Plone 2.0 -> 3.1). The mitigations below
# were validated on Python 2.4.6 (gate G1, 2026-08-20) and are re-verified by
# this script's own guards on every build, for every version.
set -eu

SRC="${1:?usage: build-python2.sh <src-tarball> <version> <prefix>}"
VERSION="${2:?missing version}"
PREFIX="${3:?missing prefix}"

BIN="${PREFIX}/bin/python${VERSION%.*}"
BUILD="/tmp/Python-${VERSION}"

tar -xzf "${SRC}" -C /tmp
cd "${BUILD}"

# The mitigations below are applied by CAPABILITY DETECTION, not by version
# number. [V 2026-08-20] The interpreters in this matrix genuinely differ:
#
#   Python   BASECFLAGS override   --without-cxx   multiarch patch
#   2.3.7    needed                supported       needed
#   2.4.6    needed                supported       needed
#   2.6.9    NOT needed (configure sets -fwrapv itself)  ABSENT   needed
#   2.7.18   NOT needed            ABSENT          NOT needed (native)
#
# Hardcoding the 2.4-era behaviour would fail 2.6 on ./configure and 2.7 on its
# own grep guards, so each mitigation probes for the condition it fixes.

# --- Mitigation 1: posix_close symbol collision -----------------------------
# glibc declares posix_close(); the old Modules/posixmodule.c defines its own.
# Present in 2.3 through 2.7; renamed wherever found.
if [ "$(grep -c '\bposix_close\b' Modules/posixmodule.c)" -ge 1 ]; then
    sed -i 's/\bposix_close\b/py2x_posix_close/g' Modules/posixmodule.c
    echo "mitigation: renamed posix_close"
fi

# --- Mitigation 2: multiarch library search paths ---------------------------
# [V 2026-08-20] Python 2.3-2.6 predate Debian multiarch (2011). setup.py looks
# for libraries in /lib and /usr/lib, but bookworm keeps libz.so, libcrypt.so
# and friends ONLY under /usr/lib/<triplet>. Detection fails, setup.py SILENTLY
# skips the extension (renaming it <name>_failed.so), and the breakage surfaces
# much later as "ImportError: No module named zlib".
#
# NOTE: passing LDFLAGS=-L<triplet> to ./configure does NOT help — setup.py's
# LDFLAGS-to-lib_dirs handling is guarded by `if platform == 'darwin'`.
#
# Python 2.7 grew add_multiarch_paths(), which runs `gcc -print-multiarch`
# itself — exactly this fix, upstream. Patching it there would be both
# redundant and impossible (the anchors below do not exist in 2.7's setup.py),
# so skip when the interpreter already handles it.
if [ "$(grep -c 'def add_multiarch_paths' setup.py)" -ge 1 ]; then
    echo "mitigation: multiarch patch SKIPPED (interpreter has add_multiarch_paths)"
else
    MULTIARCH="$(gcc -print-multiarch)"
    test -n "${MULTIARCH}"

    # [V 2026-08-20] The assignment is formatted differently across versions:
    #   2.3.7: lib_dirs = self.compiler.library_dirs + ['/lib', '/usr/lib']
    #   2.4.6: lib_dirs = self.compiler.library_dirs + [
    #                                                  '/lib64', '/usr/lib64',
    # so anchor on the common prefix and insert immediately after the '[',
    # rather than matching the list contents.
    test "$(grep -c 'self\.compiler\.library_dirs + \[' setup.py)" = "1"
    test "$(grep -c "self\.compiler\.include_dirs + \['/usr/include'\]" setup.py)" = "1"

    sed -i "s|self\.compiler\.library_dirs + \[|&'/lib/${MULTIARCH}', '/usr/lib/${MULTIARCH}', |" setup.py
    sed -i "s|self\.compiler\.include_dirs + \['/usr/include'\]|self.compiler.include_dirs + ['/usr/include', '/usr/include/${MULTIARCH}']|" setup.py

    # A sed that matched nothing must fail the build, not yield a crippled Python.
    test "$(grep -c "/usr/lib/${MULTIARCH}" setup.py)" -ge 1
    test "$(grep -c "/usr/include/${MULTIARCH}" setup.py)" -ge 1
    echo "mitigation: patched setup.py for multiarch (${MULTIARCH})"
fi

# --- Mitigation 3: configure flags ------------------------------------------
#   --without-cxx : skip C++ main detection (fragile, unused). 2.6 replaced it
#                   with --with-cxx-main and 2.7 dropped the "without" spelling
#                   entirely, so passing it there aborts ./configure.
#   BASECFLAGS    : -fno-strict-aliasing/-fwrapv for the pre-C99-aliasing code.
#                   2.6+ already set -fwrapv themselves; overriding BASECFLAGS
#                   there would REPLACE the flags configure worked out, so it is
#                   only forced on interpreters that lack it.
# curses, bsddb, tkinter and nis are EXPECTED to fail to build against a
# modern userland. They are optional; ZServer speaks plain HTTP. _ssl builds
# only when the image installs libssl-dev and the interpreter is 2.7 (see
# PYTHON_REQUIRE_SSL above).
CONF_ARGS="--prefix=${PREFIX}"
if [ "$(grep -c -- '--without-cxx' configure)" -ge 1 ]; then
    CONF_ARGS="${CONF_ARGS} --without-cxx"
    echo "mitigation: --without-cxx supported, enabled"
fi

if [ "$(grep -c 'fwrapv' configure)" -ge 1 ]; then
    echo "mitigation: BASECFLAGS left to configure (it handles -fwrapv)"
    # shellcheck disable=SC2086
    ./configure ${CONF_ARGS}
else
    # shellcheck disable=SC2086
    ./configure ${CONF_ARGS} \
        BASECFLAGS="-fno-strict-aliasing -fwrapv" OPT="-O2"
fi

make -j1
make install

# --- Gate -------------------------------------------------------------------
# Assert the modules Zope actually needs, not merely that the binary runs.
"${BIN}" -c "import zlib, sha, md5, crypt, socket, select, cPickle, cStringIO, binascii, struct, thread, datetime; print 'python gate ok'"

# Without this, a missing _ssl only shows up as a NOTE below, and mail then
# skips STARTTLS without any error (zope.sendmail checks hasattr(socket, 'ssl')).
if [ "${PYTHON_REQUIRE_SSL:-0}" = "1" ]; then
    # No _hashlib here: 2.7's setup.py parses OPENSSL_VERSION_NUMBER as a hex
    # literal, OpenSSL 3 defines it as an expression, so it reads 0x00000000,
    # calls the library "too old" and skips the module. hashlib then uses the
    # built-in md5/sha* modules, which is all Zope needs.
    "${BIN}" -c "import ssl, socket; assert hasattr(socket, 'ssl'); print 'ssl gate ok: ' + ssl.OPENSSL_VERSION"
fi

# Report skipped extensions so a silent loss is visible in the build log.
FAILED="$(find "${PREFIX}/lib" -name '*_failed.so' -printf '%f ' 2>/dev/null || true)"
if [ -n "${FAILED}" ]; then
    echo "NOTE: optional extensions not built: ${FAILED}"
else
    echo "NOTE: no *_failed.so — every attempted extension built"
fi

cd /
rm -rf "${BUILD}"
