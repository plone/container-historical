#!/bin/sh
# Copy tags of the official `plone` image into our own repositories.
#
#   ./mirror/mirror-official.sh                  # verify only: nothing is pushed
#   PUBLISH=1 ./mirror/mirror-official.sh        # verify, copy, verify the copies
#
# Reads `<tag> <digest>` pairs from mirror/official-tags.txt. Every source tag
# must still resolve to its pinned digest before anything is copied, and every
# copy must come out with that same digest, so a mirrored tag is provably the
# official image and not a rebuild of it.
#
# The copy is `docker buildx imagetools create` from the pinned digest: a
# registry-side manifest copy, with no pull and no build, that keeps every
# platform of the multi-arch image.
set -eu

SOURCE="${SOURCE:-docker.io/library/plone}"
TARGETS="${TARGETS:-docker.io/plone/plone ghcr.io/plone/plone.docker}"
TAGS_FILE="${TAGS_FILE:-$(dirname "$0")/official-tags.txt}"
PUBLISH="${PUBLISH:-0}"

digest_of() {
    docker buildx imagetools inspect --format '{{.Manifest.Digest}}' "$1"
}

PAIRS=$(grep -vE '^[[:space:]]*(#|$)' "${TAGS_FILE}")
COUNT=$(printf '%s\n' "${PAIRS}" | wc -l | tr -d ' ')
if [ -z "${PAIRS}" ]; then
    echo "FAIL: no tags listed in ${TAGS_FILE}" >&2
    exit 1
fi

echo "=== verifying ${COUNT} source tag(s) in ${SOURCE} ==="
printf '%s\n' "${PAIRS}" | while read -r tag digest; do
    actual=$(digest_of "${SOURCE}:${tag}")
    if [ "${actual}" != "${digest}" ]; then
        echo "FAIL: ${SOURCE}:${tag} is ${actual}, pinned ${digest}" >&2
        exit 1
    fi
    echo "OK: ${SOURCE}:${tag} = ${digest}"
done

if [ "${PUBLISH}" != "1" ]; then
    echo "NOTE: PUBLISH is not 1 - verified only, nothing copied"
    exit 0
fi

for target in ${TARGETS}; do
    echo "=== copying ${COUNT} tag(s) to ${target} ==="
    printf '%s\n' "${PAIRS}" | while read -r tag digest; do
        docker buildx imagetools create \
            --tag "${target}:${tag}" "${SOURCE}@${digest}"
        actual=$(digest_of "${target}:${tag}")
        if [ "${actual}" != "${digest}" ]; then
            echo "FAIL: ${target}:${tag} came out as ${actual}, expected ${digest}" >&2
            exit 1
        fi
        echo "OK: ${target}:${tag} = ${digest}"
    done
done

echo "MIRROR PASS: ${COUNT} tag(s) x $(echo "${TARGETS}" | wc -w | tr -d ' ') target(s)"
