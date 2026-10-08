# syntax=docker/dockerfile:1
#
# The -demo variant of the 4.3 - 5.2 images.
#
# One Dockerfile serves all four series: it takes an official base image and a
# database seeded from it (see seed.sh), and adds nothing else — same Zope,
# same Python, same add-ons, same entrypoint behind a small wrapper.
#
#   ./seed.sh plone:5.2.14 build/5.2
#   docker build --build-arg BASE_IMAGE=plone:5.2.14 --build-arg SEED=build/5.2 \
#       -t plone-demo:5.2.14-demo .
#
# or just `make demo-5.2`.
#
# NOT FOR PRODUCTION: the site's admin account is admin / admin, inherited
# from the base image's buildout.
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG BASE_IMAGE
ARG SEED=build/seed

LABEL org.opencontainers.image.description="Demo variant of ${BASE_IMAGE}: identical, but ships a database with a Plone site already created at /Plone. Migration, demonstration and archaeology only — NOT for production."

# The only differences from the base image: the seeded database, and the
# wrapper that copies it into /data on first start.
COPY --chown=plone:plone ${SEED}/ /app/seed/
COPY --chmod=755 demo-entrypoint.sh /demo-entrypoint.sh

ENTRYPOINT ["/demo-entrypoint.sh"]
CMD ["start"]
