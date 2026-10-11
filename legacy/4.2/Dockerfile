# syntax=docker/dockerfile:1
#
# Plone 4.2.x — buildout era (Zope 2.13.21 / Python 2.7.18)
#
# Strategy:
#   Stage 1 (fetch): modern userland downloads everything (old TLS never touches network)
#   Stage 2 (build): Python 2.7 + PIL, then an OFFLINE buildout from the
#                    UnifiedInstaller's bundled buildout-cache
#   Stage 3 (runtime): slim image, non-root, /data volume, port 8080
#
# [V 2026-08-20] 4.2.6, NOT 4.2.7. As with 4.0, the final release (4.2.7)
# has no UnifiedInstaller; the last one published is 4.2.6.
#
# This is the first image on Python 2.7 — the cached eggs are py2.7, so the
# interpreter minor version is not a free choice.
#
# [V 2026-08-20] Plone 4 packages Zope as an EGG (Zope2-2.13.21), not the
# configure+make tarball used through 3.x. The buildout handles that itself,
# which is the main reason these images are built from the UnifiedInstaller
# rather than assembled by hand.
#
# [V 2026-10-11] The only legacy image with ssl. Python 2.7.18's _ssl builds
# against bookworm's OpenSSL 3.0 (warnings only) and negotiates TLS 1.3 for
# SMTP STARTTLS, SMTPS and verified HTTPS with SNI. 2.6 and older cannot
# compile against OpenSSL 3, so the rest of the matrix stays without it.
#
# NOT FOR PRODUCTION. This stack has known, unpatched security issues.
# Intended for content extraction, migration, and archaeology only.

ARG PYTHON_VERSION=2.7.18
ARG PLONE_VERSION=4.2.6
ARG PIL_VERSION=1.1.6
ARG ZOPE_VERSION=2.13.21

ARG PYTHON_URL=https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz
ARG PLONE_URL=https://launchpad.net/plone/4.2/${PLONE_VERSION}/+download/Plone-${PLONE_VERSION}-UnifiedInstaller.tgz
ARG PIL_URL=https://dist.plone.org/thirdparty/PIL-${PIL_VERSION}.tar.gz

# ---------------------------------------------------------------------------
# Stage 1: fetch — modern TLS, nothing else
# ---------------------------------------------------------------------------
FROM debian:bookworm-slim AS fetch
ARG PYTHON_URL
ARG PLONE_URL
ARG PIL_URL
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /dist
# --retry: Launchpad intermittently answers 503 under load (observed repeatedly
# on 2026-08-20), and a transient failure here wastes the whole build.
RUN curl -fSL --retry 5 --retry-delay 5 "${PYTHON_URL}" -o python.tgz \
 && curl -fSL --retry 5 --retry-delay 5 "${PLONE_URL}"  -o installer.tgz \
 && curl -fSL --retry 5 --retry-delay 5 "${PIL_URL}"    -o pil.tar.gz

# ---------------------------------------------------------------------------
# Stage 2a: pybuild — the interpreter only (gate G1)
# ---------------------------------------------------------------------------
FROM debian:bookworm AS pybuild
ARG PYTHON_VERSION

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      gcc make libc6-dev zlib1g-dev libcrypt-dev libssl-dev \
 && rm -rf /var/lib/apt/lists/*

COPY --from=fetch /dist /dist
COPY shared/build-python2.sh /usr/local/bin/build-python2.sh

RUN PYTHON_REQUIRE_SSL=1 build-python2.sh /dist/python.tgz "${PYTHON_VERSION}" /opt/python2.7

# ---------------------------------------------------------------------------
# Stage 2b: build — PIL, then the offline buildout.
# ---------------------------------------------------------------------------
FROM pybuild AS build
ARG PLONE_VERSION
ARG PIL_VERSION

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libjpeg62-turbo-dev bzip2 libxml2-dev libxslt1-dev \
 && rm -rf /var/lib/apt/lists/*

# [V 2026-08-20] libxml2-dev/libxslt1-dev are required from 4.1 on: the
# buildout builds lxml from source (2.2.8 here, 2.3.6 in 4.2) and fails with
#   src/lxml/etree_defs.h:9: fatal error: libxml/xmlversion.h: No such file
#   ERROR: xslt-config: not found
# 4.0.9 does not pull lxml at all, which is why it builds without them.
#
# NOTE: this is NOT the "old lxml vs modern libxml2" hot spot. That one bites
# at libxml2 >= 2.12; bookworm ships 2.9.14, so the distro headers are period-
# appropriate enough and no static libxml2 build is needed. Revisit if the
# base image ever moves to trixie.
COPY shared/build-pil.sh /usr/local/bin/build-pil.sh
RUN build-pil.sh /dist/pil.tar.gz "${PIL_VERSION}" /opt/python2.7/bin/python2.7

COPY shared/build-plone-buildout.sh /usr/local/bin/build-plone-buildout.sh
RUN build-plone-buildout.sh /dist/installer.tgz "${PLONE_VERSION}" \
      /opt/python2.7/bin/python2.7 /app

# ---------------------------------------------------------------------------
# Stage 3: runtime
# ---------------------------------------------------------------------------
FROM debian:bookworm-slim
ARG PLONE_VERSION
ARG ZOPE_VERSION
ARG PYTHON_VERSION

LABEL org.opencontainers.image.title="Plone ${PLONE_VERSION} (legacy)" \
      org.opencontainers.image.description="Plone ${PLONE_VERSION} on Zope ${ZOPE_VERSION} / Python ${PYTHON_VERSION}. Migration and content-extraction use only — NOT for production." \
      org.opencontainers.image.vendor="Simples Consultoria"

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      zlib1g libcrypt1 libjpeg62-turbo libxml2 libxslt1.1 \
      libssl3 ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && useradd --system -m -d /app -U -u 500 plone \
 && mkdir -p /data \
 && chown -R plone:plone /data

COPY --from=build --chown=plone:plone /opt/python2.7 /opt/python2.7
COPY --from=build --chown=plone:plone /app /app
# The build-stage gate ran against libssl-dev; this one proves the runtime
# libraries and the CA bundle (verified HTTPS) are present in the final image.
RUN /opt/python2.7/bin/python2.7 -c "import ssl; ssl.create_default_context(); print 'runtime ssl ok: ' + ssl.OPENSSL_VERSION" \
 && test -s /etc/ssl/certs/ca-certificates.crt
COPY --chown=plone:plone shared/docker-entrypoint-buildout.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
COPY --chown=plone:plone shared/upgrade-plone.py /app/upgrade-plone.py
COPY --chown=plone:plone shared/configure-zeo.sh /app/configure-zeo.sh
RUN chmod +x /app/configure-zeo.sh

ENV INSTANCE_HOME=/app/instance \
    PYTHON=/opt/python2.7/bin/python2.7 \
    ZOPE_HTTP_PORT=8080

VOLUME /data
EXPOSE 8080
WORKDIR /app/instance
USER plone

HEALTHCHECK --interval=10s --timeout=5s --start-period=180s --retries=6 \
  CMD ["/opt/python2.7/bin/python2.7", "-c", "import urllib; urllib.urlopen('http://127.0.0.1:8080/')"]

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["start"]
