# Plone 4.2 legacy image

Plone 4.2.6 on Zope 2.13.21 / Python 2.7.18. Buildout era.

**Not for production.** This stack has known, unpatched vulnerabilities. The
image exists for content extraction, migration rehearsal, and historical
inspection.

## Usage

```sh
docker build -f 4.2/Dockerfile -t plone-legacy:4.2.6 .
docker run -d -p 8080:8080 -e ADMIN_PASSWORD=secret \
    -v plone42-data:/data plone-legacy:4.2.6
```

| | |
|---|---|
| Port | 8080 (`ZOPE_HTTP_PORT` to change) |
| Volume | `/data` (`filestorage/Data.fs`, `log/`) |
| User | `plone` (uid 500) |
| Env | `ADMIN_USER`, `ADMIN_PASSWORD` (first run only) |

## How it is built

From the Launchpad **UnifiedInstaller**, whose
`packages/buildout-cache.tar.bz2` is a complete offline cache of every egg and
distribution including Zope itself. Buildout runs fully offline, so the old
toolchain never has to negotiate modern TLS. See
`shared/build-plone-buildout.sh`.

## Validated facts / hypotheses

- **[V 2026-08-20]** **4.2.6, not the final 4.2.7** — same reason as 4.0: the
  last published UnifiedInstaller for the series is 4.2.6.
- **[V 2026-08-20]** **First Python 2.7 image.** The cached eggs are `-py2.7.egg`,
  so 2.7 is required, and 2.7.18 (the last release) is used rather than the
  2.7.5 the installer bundles.
- **[V 2026-08-20]** **This is what forced `build-python2.sh` onto capability
  detection.** The interpreters genuinely differ, and hardcoding the 2.4-era
  behaviour breaks both newer ones:

  | Python | BASECFLAGS override | `--without-cxx` | multiarch patch |
  |---|---|---|---|
  | 2.3.7 / 2.4.6 | needed | supported | needed |
  | 2.6.9 | not needed (configure sets `-fwrapv`) | **absent** | needed |
  | 2.7.18 | not needed | absent | **not needed — native** |

  Python 2.7 grew `add_multiarch_paths()`, which runs `gcc -print-multiarch`
  itself; patching it there is both redundant and impossible, since the anchors
  the patch matches do not exist in 2.7’s `setup.py`. Passing `--without-cxx`
  to 2.6/2.7 aborts `./configure` outright. Each mitigation now probes for the
  condition it fixes.
- **[V 2026-08-20]** lxml 2.3.6 builds against bookworm’s libxml2 2.9.14 once
  the dev packages are present — see the 4.1 README.
- **[V 2026-10-11]** **The only legacy image with `ssl`.** Python is built
  against bookworm's OpenSSL 3.0 (`libssl-dev` at build, `libssl3` and
  `ca-certificates` at runtime). 2.7.18's `_ssl.c` compiles with warnings only
  and negotiates TLS 1.3 for SMTP STARTTLS (587), SMTPS (465) and
  certificate-verified HTTPS with SNI. `PYTHON_REQUIRE_SSL=1` makes the build
  fail if `_ssl` is missing, and the runtime stage checks the module and the CA
  bundle again. Before this, `import ssl` failed with `No module named _ssl`.
  Three things change because of it:
  - zope.sendmail 3.7.5 issues STARTTLS whenever the server advertises it
    (before, it skipped STARTTLS and sent in plain text). OpenSSL 3's defaults
    (TLS 1.2 minimum, `SECLEVEL=2`) reject relays that only speak TLS 1.0/1.1.
    The certificate is not verified on STARTTLS. zope.sendmail has no SMTPS
    support at all.
  - `urllib2`/`httplib` verify HTTPS certificates (PEP 476).
  - Not a change: `_hashlib` is still not built. 2.7's `setup.py` reads
    OpenSSL 3's `OPENSSL_VERSION_NUMBER` as `0x00000000` and skips it, so
    `hashlib` keeps using the built-in md5/sha modules.
- **[V 2026-08-20]** Zope is 2.13.21. Zero product import/install errors; a site
  is created and renders ~19.9 kB. Passes twice.

## Smoke test (CI gate)

```sh
make test-4.2
SMOKE_CREATE_SITE=1 make test-4.2
```
