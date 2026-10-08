#!/bin/sh
# Entrypoint of the 4.3 - 5.2 -demo images.
#
# The official base images know nothing about seeding, and are left exactly as
# released: this wrapper puts the baked database in place, then hands over to
# the base image's own /docker-entrypoint.sh with the same arguments.
#
# The seed lives at /app/seed and NOT under /data: /data is a VOLUME in the
# base image, so it is copied in on first start instead. Nothing is copied when
# /data already holds a database, so mounting a real site over a demo image
# still works exactly as it does on the base image.
set -e

SEED_DIR="${SEED_DIR:-/app/seed}"

if [ ! -e /data/filestorage/Data.fs ]; then
    echo "demo: seeding /data from ${SEED_DIR}"
    mkdir -p /data/filestorage /data/blobstorage
    cp -p "${SEED_DIR}/filestorage/Data.fs" /data/filestorage/Data.fs
    cp -Rp "${SEED_DIR}/blobstorage/." /data/blobstorage/
    # 4.3, 5.1 and 5.2 start as root and drop to `plone` through gosu; 5.0
    # starts as `plone` already and owns /data, so it neither needs nor may
    # chown.
    if [ "$(id -u)" = "0" ]; then
        chown -R plone:plone /data/filestorage /data/blobstorage
    fi
fi

exec /docker-entrypoint.sh "$@"
