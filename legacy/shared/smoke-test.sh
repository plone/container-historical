#!/bin/sh
# Smoke test for a plone-legacy image.
# Usage: IMAGE=plone-legacy:2.1.4 ./shared/smoke-test.sh
# Gates: HTTP answers on / within TIMEOUT; /manage_main authenticates.
set -eu

IMAGE="${IMAGE:?set IMAGE, e.g. IMAGE=plone-legacy:2.1.4}"
PORT="${PORT:-18080}"
TIMEOUT="${TIMEOUT:-180}"
NAME="smoke-$$"

# The password the container is started with, and therefore the one every
# authenticated request below uses. Overridable so the -demo gate can prove
# that a NON-default password really reaches a pre-seeded database — the thing
# that has broken twice and that admin/admin would happily hide.
ADMIN_PW="${SMOKE_ADMIN_PASSWORD:-admin}"

cleanup() {
    docker logs "${NAME}" 2>&1 | tail -n 50 || true
    docker rm -f "${NAME}" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

docker run -d --name "${NAME}" \
    -p "${PORT}:8080" \
    -e ADMIN_PASSWORD="${ADMIN_PW}" \
    "${IMAGE}" >/dev/null

echo "waiting for HTTP on :${PORT} (max ${TIMEOUT}s)..."
elapsed=0
until curl -sf -o /dev/null "http://localhost:${PORT}/"; do
    if ! docker inspect -f '{{.State.Running}}' "${NAME}" 2>/dev/null | grep -q true; then
        echo "FAIL: container exited before answering HTTP" >&2
        exit 1
    fi
    if [ "${elapsed}" -ge "${TIMEOUT}" ]; then
        echo "FAIL: no HTTP answer within ${TIMEOUT}s" >&2
        exit 1
    fi
    sleep 3
    elapsed=$((elapsed + 3))
done
echo "OK: / answers"

if ! curl -sf -o /dev/null -u "admin:${ADMIN_PW}" "http://localhost:${PORT}/manage_main"; then
    echo "FAIL: /manage_main did not authenticate with admin:${ADMIN_PW}" >&2
    exit 1
fi
echo "OK: /manage_main authenticates as admin:${ADMIN_PW}"

# Product load check.
#
# Zope answers HTTP and authenticates even when every Plone product failed to
# import, so the two assertions above can and do pass on a completely unusable
# Plone. [V 2026-08-20] With no PIL in the image, CMFPlone, Archetypes and
# ATContentTypes all fail at "from PIL import Image" in CMFPlone/utils.py:4.
#
# [V 2026-08-20] D2/D4 are settled: the image ships PIL 1.1.6, so a clean
# product load is now the expected state and this check is FATAL by default.
# Set SMOKE_STRICT_PRODUCTS=0 to downgrade it to a warning (e.g. while
# bringing up a new version directory that has a known-broken product).
# [V 2026-08-20] The log file name is NOT stable across eras, and getting this
# wrong makes the check silently vacuous rather than noisy:
#   tarball era (2.0-3.0), mkzopeinstance : /data/log/event.log
#   buildout era (3.1+),   zope2instance  : /data/log/instance.log
# The first 3.1 run "passed" this check against a path that did not exist. So
# glob the directory, and treat *finding no log at all* as a failure — that way
# a future rename breaks the build instead of quietly disabling the gate.
#
# [V 2026-10-08] SMOKE_LOG_SOURCE=docker reads the container's own output
# instead, for images that log to stdout/stderr and write no log file at all:
# the official Plone 5.2 image does, since 5.2.5. The empty-log check still
# applies there, so a container that printed nothing still fails.
PRODUCT_PATTERN='ERROR Zope (Could not import|Couldn.t install)'
if [ "${SMOKE_LOG_SOURCE:-file}" = "docker" ]; then
    LOG_TEXT=$(docker logs "${NAME}" 2>&1 || true)
    if [ -z "${LOG_TEXT}" ]; then
        echo "FAIL: the container has logged nothing — cannot verify product load" >&2
        exit 1
    fi
    echo "checking product load in: docker logs"
else
    LOG_FILES=$(docker exec "${NAME}" sh -c 'ls /data/log/*.log 2>/dev/null' 2>/dev/null || true)
    if [ -z "${LOG_FILES}" ]; then
        echo "FAIL: no /data/log/*.log found — cannot verify product load" >&2
        docker exec "${NAME}" ls -la /data/log/ >&2 || true
        exit 1
    fi
    echo "checking product load in: $(echo "${LOG_FILES}" | tr '\n' ' ')"
    LOG_TEXT=$(docker exec "${NAME}" sh -c 'cat /data/log/*.log' 2>/dev/null || true)
fi

PRODUCT_ERRORS=$(printf '%s\n' "${LOG_TEXT}" | grep -cE "${PRODUCT_PATTERN}" || true)
[ -n "${PRODUCT_ERRORS}" ] || PRODUCT_ERRORS=0

if [ "${PRODUCT_ERRORS}" -gt 0 ]; then
    echo "WARNING: ${PRODUCT_ERRORS} product import/install failure(s) in the log:" >&2
    printf '%s\n' "${LOG_TEXT}" | grep -E "${PRODUCT_PATTERN}" >&2 || true
    if [ "${SMOKE_STRICT_PRODUCTS:-1}" = "1" ]; then
        echo "FAIL: products failed to load (set SMOKE_STRICT_PRODUCTS=0 to allow)" >&2
        exit 1
    fi
    echo "NOTE: downgraded to a warning by SMOKE_STRICT_PRODUCTS=0" >&2
else
    echo "OK: no product import/install errors"
fi

# JSON gate.
#
# [V 2026-08-27] Python grew a stdlib `json` only in 2.6, so 1.0 through 3.3
# (Python 2.3/2.4) have no JSON at all unless simplejson is installed — and
# scripted content extraction, which is the entire point of these images, is
# painful without it. 4.0+ get it from the stdlib.
#
# Asserted as a CAPABILITY — "this image can round-trip JSON the way a script
# actually runs" — rather than per-version, so a single check covers the whole
# matrix: a real gate below 4.0, where nothing satisfies it by accident, and
# free above.
#
# Two deliberate choices, both verified rather than assumed [V 2026-08-27]:
#
#   * It runs a SECOND, throwaway container instead of exec-ing into the live
#     one. The runners open the ZODB, which the running instance already holds
#     locked, and `run` is the code path a real extraction script takes.
#   * It goes through that runner rather than "$PYTHON" directly. 3.3 gets
#     simplejson from a buildout-cache EGG, which only the runner puts on
#     sys.path; probing the bare interpreter reports 3.3 as broken when it is
#     fine, and tests a path nobody uses.
#
# `zopectl run` / `bin/instance run` do not reliably propagate a script exit
# status — the same reason docker-entrypoint*.sh captures output rather than
# trusting `||` — so success is a marker in the OUTPUT, not the status.
if [ "${SMOKE_JSON:-1}" = "1" ]; then
    JSON_PROBE="$(cd "$(dirname "$0")" && pwd)/json-probe.py"
    test -f "${JSON_PROBE}"
    JSON_OUT=$(docker run --rm -v "${JSON_PROBE}:/json-probe.py:ro" \
        "${IMAGE}" run /json-probe.py 2>&1) || true
    #
    # [V 2026-10-08] The marker must START a line. A probe that fails to
    # compile prints a traceback quoting its own source — including the line
    # that would have printed the marker — so an unanchored match passed the
    # gate on Plone 5.2, where the probe had not run at all.
    if ! printf '%s\n' "${JSON_OUT}" | grep -q '^JSON-GATE-OK '; then
        echo "FAIL: no working JSON module reachable from the script runner" >&2
        printf '%s\n' "${JSON_OUT}" | tail -n 20 >&2
        exit 1
    fi
    echo "OK: JSON round-trip via $(printf '%s\n' "${JSON_OUT}" |
        sed -n 's/^JSON-GATE-OK //p')"
else
    echo "NOTE: JSON gate skipped by SMOKE_JSON=0"
fi

# Stretch gate (opt-in): scripted Plone site creation.
#
# The whole discovery-and-POST dance lives in shared/create-plone-site.sh, so
# that this gate and the -demo images' build step create their sites through
# exactly the same code path. If they diverged, the demo images would be
# tested by proxy rather than in fact.
if [ "${SMOKE_CREATE_SITE:-0}" = "1" ]; then
    SITE_ID="${SITE_ID:-Plone}"
    "$(dirname "$0")/create-plone-site.sh" \
        "http://localhost:${PORT}" "${SITE_ID}" admin "${ADMIN_PW}"
fi

# Demo-image gate (opt-in): the site must ALREADY be there on first start,
# with no creation step. Set by `make test-demo-<series>`.
#
# This is the assertion that the seeded Data.fs actually reached /data — a
# -demo image that silently fell back to an empty database would otherwise
# look identical to its base image and pass every check above.
if [ "${SMOKE_EXPECT_SITE:-0}" = "1" ]; then
    SITE_ID="${SITE_ID:-Plone}"
    SITE_HTML=$(curl -sf "http://localhost:${PORT}/${SITE_ID}") || {
        echo "FAIL: no pre-created site at /${SITE_ID}" >&2
        exit 1
    }
    if printf '%s' "${SITE_HTML}" | grep -q 'name="generator" content="Plone'; then
        SITE_MARKER="generator meta tag"
    elif printf '%s' "${SITE_HTML}" | grep -qE 'plone_javascripts|plone\.css'; then
        SITE_MARKER="plone_javascripts/plone.css (pre-2.0: no generator tag)"
    else
        echo "FAIL: /${SITE_ID} carries no Plone marker at all" >&2
        printf '%s' "${SITE_HTML}" | head -c 400 >&2
        exit 1
    fi
    echo "OK: pre-created site at /${SITE_ID} renders via ${SITE_MARKER} ($(printf '%s' "${SITE_HTML}" | wc -c) bytes)"

    # The build-time password must NOT still open the door.
    #
    # [V 2026-08-20] This is the assertion that would have caught the seeding
    # bug immediately: Zope re-applied the base image's placeholder inituser on
    # top of the seeded database, so the image came up with a working site and
    # credentials nobody could guess. Everything except authentication passed.
    # It also guards the reverse mistake — a demo image that ignores
    # ADMIN_PASSWORD and quietly keeps admin/admin.
    if [ "${ADMIN_PW}" != "admin" ]; then
        if curl -sf -o /dev/null -u admin:admin "http://localhost:${PORT}/manage_main"; then
            echo "FAIL: the build-time password admin:admin still authenticates" >&2
            echo "      after ADMIN_PASSWORD=${ADMIN_PW} was supplied" >&2
            exit 1
        fi
        echo "OK: build-time password admin:admin no longer authenticates"
    fi
fi

echo "SMOKE PASS: ${IMAGE}"
