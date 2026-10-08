#!/bin/sh
# Seed a Plone site from an official base image, for the -demo variants.
#
# Usage: seed.sh <base-image> <out-dir>
#   e.g. seed.sh plone:5.2.14 build/5.2
#
# Runs on the HOST, not inside a build: the official images ship neither curl
# nor wget, and the Debian releases they are built on have left
# deb.debian.org, so nothing can be installed into them. Instead the base
# image is started as-is, the site is created through
# legacy/shared/create-plone-site.sh — the same script the legacy demo images
# and the CI gates use — Zope is stopped cleanly, and the database is copied
# out with `docker cp`. demo/Dockerfile then bakes <out-dir> into the image.
set -eu

BASE_IMAGE="${1:?usage: seed.sh <base-image> <out-dir>}"
OUT_DIR="${2:?usage: seed.sh <base-image> <out-dir>}"

SITE_ID="${SITE_ID:-Plone}"
SITE_TITLE="${SITE_TITLE:-Plone demo}"
PLATFORM="${PLATFORM:-linux/amd64}"
PORT="${PORT:-18090}"
START_TIMEOUT="${START_TIMEOUT:-300}"
STOP_TIMEOUT="${STOP_TIMEOUT:-120}"
# The signal that makes the base image shut Zope down cleanly. 4.3 - 5.1 trap
# TERM and run `bin/instance stop`; 5.2 execs `bin/instance console`, which
# does not stop on TERM and needs INT.
STOP_SIGNAL="${STOP_SIGNAL:-TERM}"
# The base images bake admin:admin into their buildout, and do not read
# ADMIN_PASSWORD.
ADMIN_USER="admin"
ADMIN_PASSWORD="admin"

CREATE_SITE="$(cd "$(dirname "$0")/../legacy/shared" && pwd)/create-plone-site.sh"
NAME="seed-$$"

cleanup() {
    docker rm -f "${NAME}" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

echo "=== seeding ${SITE_ID} from ${BASE_IMAGE} ==="
docker run -d --platform "${PLATFORM}" --name "${NAME}" \
    -p "${PORT}:8080" "${BASE_IMAGE}" >/dev/null

echo "waiting for HTTP on :${PORT} (max ${START_TIMEOUT}s)..."
elapsed=0
until curl -sf -o /dev/null "http://localhost:${PORT}/"; do
    if [ "$(docker inspect -f '{{.State.Running}}' "${NAME}")" != "true" ]; then
        echo "FAIL: Zope exited before answering HTTP" >&2
        docker logs "${NAME}" 2>&1 | tail -n 30 >&2
        exit 1
    fi
    if [ "${elapsed}" -ge "${START_TIMEOUT}" ]; then
        echo "FAIL: no HTTP answer within ${START_TIMEOUT}s" >&2
        exit 1
    fi
    sleep 3
    elapsed=$((elapsed + 3))
done
echo "OK: instance is up"

SITE_TITLE="${SITE_TITLE}" "${CREATE_SITE}" \
    "http://localhost:${PORT}" "${SITE_ID}" "${ADMIN_USER}" "${ADMIN_PASSWORD}"

# Clean shutdown, then verify it: copying a FileStorage that was killed rather
# than closed is how a half-flushed transaction ends up baked into an image.
echo "stopping Zope with SIG${STOP_SIGNAL} (max ${STOP_TIMEOUT}s)..."
docker kill -s "${STOP_SIGNAL}" "${NAME}" >/dev/null
elapsed=0
while [ "$(docker inspect -f '{{.State.Running}}' "${NAME}")" = "true" ]; do
    if [ "${elapsed}" -ge "${STOP_TIMEOUT}" ]; then
        echo "FAIL: Zope did not stop within ${STOP_TIMEOUT}s of SIG${STOP_SIGNAL}" >&2
        exit 1
    fi
    sleep 2
    elapsed=$((elapsed + 2))
done
echo "OK: Zope stopped after ${elapsed}s"

rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}"
docker cp -q "${NAME}:/data/filestorage" "${OUT_DIR}/"
docker cp -q "${NAME}:/data/blobstorage" "${OUT_DIR}/"

# FileStorage writes Data.fs.index when it is closed, and not when the process
# dies. It is evidence only: the index is a cache Zope rebuilds on first open,
# and baking a stale one is worse than baking none, so it is dropped with the
# lock and any temporary files.
if [ ! -f "${OUT_DIR}/filestorage/Data.fs.index" ]; then
    echo "FAIL: no Data.fs.index after shutdown — the storage was not closed" >&2
    exit 1
fi
find "${OUT_DIR}/filestorage" -type f ! -name Data.fs -exec rm -f {} +

SEED_BYTES=$(wc -c < "${OUT_DIR}/filestorage/Data.fs" | tr -d ' ')
if [ "${SEED_BYTES}" -lt 100000 ]; then
    echo "FAIL: seeded Data.fs is only ${SEED_BYTES} bytes — no site in it" >&2
    exit 1
fi
BLOBS=$(find "${OUT_DIR}/blobstorage" -name '*.blob' | wc -l | tr -d ' ')
echo "OK: seeded ${OUT_DIR} (Data.fs ${SEED_BYTES} bytes, ${BLOBS} blob(s))"
