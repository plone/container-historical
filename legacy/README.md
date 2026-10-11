# Legacy Plone images

Container images for historical Plone releases, built with modern multi-stage
Dockerfiles and following the conventions of the current `plone/plone-backend`
images (port 8080, `/data` volume, non-root `plone` user, env-driven admin
bootstrap).

**Never for production.** These stacks have known, unpatched security issues.
They exist for content extraction, migration rehearsal, and archaeology.

## Version matrix

| Dir  | Plone | Zope    | Python | Install  | JSON         | Status |
|------|-------|---------|--------|----------|--------------|--------|
| 4.2  | 4.2.6 | 2.13.21 | 2.7.18 | buildout | stdlib `json` | **done** |
| 4.1  | 4.1.6 | 2.13.15 | 2.6.9  | buildout | stdlib `json` | **done** |
| 4.0  | 4.0.9 | 2.12.19 | 2.6.9  | buildout | stdlib `json` | **done** |
| 3.3  | 3.3.6 | 2.10.13 | 2.4.6  | buildout | `simplejson` 2.0.9 (bundled) | **done** |
| 3.2  | 3.2.3 | 2.10.7  | 2.4.6  | buildout | `simplejson` 2.0.9 (installed) | **done** |
| 3.1  | 3.1.7 | 2.10.6  | 2.4.6  | buildout | `simplejson` 2.0.9 (installed) | **done** |
| 3.0  | 3.0.5 | 2.10.13 | 2.4.6  | tarball  | `simplejson` 2.0.9 (installed) | **done** |
| 2.5  | 2.5.4-2 | 2.9.12  | 2.4.6  | tarball  | `simplejson` 2.0.9 (installed) | **done** |
| 2.1  | 2.1.4 | 2.8.12  | 2.4.6  | tarball  | `simplejson` 2.0.9 (installed) | **done** |
| 2.0  | 2.0.5 | 2.7.8   | 2.3.7  | tarball  | `simplejson` 1.9.3 (installed) | **done** |
| 1.0  | 1.0.6 | 2.7.8   | 2.3.7  | tarball  | `simplejson` 1.9.3 (installed) | **done**, [patched](1.0/README.md#the-two-patches) |

The matrix is **complete**: every series from 1.0 to 4.2 is ported. 1.0 is the
only image that patches upstream source, because it targets Zope 2.6 and has
to run on 2.7.

Adding a series touches eight places. Miss one and the build still passes — the
image is simply never built, or the docs quietly disagree with what ships — so
the list is worth working through rather than recalling:

1. `<version>/Dockerfile`
2. `<version>/README.md`, carrying that version's validated/hypothesised ledger
3. `SERIES` in the [`Makefile`](Makefile), oldest first
4. `FULL_VERSION_<version>` in the [`Makefile`](Makefile)
5. the paths-filter `v<version>` entry in
   [`../.github/workflows/legacy-build.yml`](../.github/workflows/legacy-build.yml)
6. the `ALL` list in that same workflow — **separate from the filter**, and the
   one that decides what a push to `main` builds
7. the table above, including its "remaining N" count, **and** the image table
   in [`../README.md`](../README.md)
8. a [`../CHANGES.md`](../CHANGES.md) entry

Then `make lint`, `make -n` on all four targets for the new series (see the
GNU Make 3.81 note in the Makefile), and both smoke gates —
`SMOKE_CREATE_SITE=1 make test-<version>` and `make test-demo-<version>`.

The point release is what is actually *buildable*, which is not always the last
release. **4.2.6, not the final 4.2.7**: no UnifiedInstaller was ever published
past 4.2.6, and the installer is what carries the offline buildout-cache these
images are built from. 4.2.7 does have a complete egg set at
`dist.plone.org/release/`, so it remains reachable — but only by hand-writing a
buildout against that directory instead of driving a UnifiedInstaller.

Images are **linux/amd64 only** and use a three-stage shape: a fetch stage on
modern userland (so the old toolchain never negotiates TLS), a build stage on
`debian:bookworm`, and a slim runtime.

4.2 is **buildout era** — `bin/buildout` runs fully offline against the
`buildout-cache` bundled inside the UnifiedInstaller, because old setuptools
cannot reach modern PyPI. It keeps `zope.conf` and `inituser` under
`parts/instance/` and is run through `bin/instance`.

## Quick start

    make plone-4.2        # build plone-legacy:4.2.6
    make test-4.2         # smoke test it
    docker run -d -p 8080:8080 -e ADMIN_PASSWORD=secret \
        -v mydata:/data plone-legacy:4.2

Mount an existing site by placing its `Data.fs` at
`/data/filestorage/Data.fs` before first start.

### The `/data` volume

`var/` **is** the volume — `/app/instance/var -> /data` — so `blobstorage/`,
`instance/` (CLIENTHOME), `backups/`, `instance.pid` and `instance.lock` all
land there alongside `filestorage/Data.fs` and `log/`.

Redirecting the whole of `var/` rather than a chosen pair of subdirectories is
deliberate. Plone 4.0 introduced `blob-dir /app/instance/var/blobstorage`,
which a hand-maintained symlink list did not cover: a one-shot `upgrade`
container wrote its blobs into a layer that vanished on exit and committed a
database referencing blobs that no longer existed — silently, because a
database with no `File` or `Image` content never writes a blob at all.
Redirecting the directory itself cannot miss the next one.

It is also the shape `plone/plone-backend` uses (`/app/var -> /data`), so the
volume layout carries over to the modern images.

Runtime state (`instance.pid`, `instance.lock`, `CLIENTHOME`) lands in the
volume as a consequence. That is safe: [V 2026-08-21] a container `SIGKILL`ed
with all three left behind restarts healthy and serves its content.

Add `SMOKE_CREATE_SITE=1` to the test target to also create a Plone site and
assert the site root renders real Plone markup:

    SMOKE_CREATE_SITE=1 make test-4.2

## The `-demo` variant

Every version also builds a `-demo` twin that **ships with a Plone site already
created**, at the id `Plone`:

    make demo-4.2                      # plone-legacy:4.2.6-demo and :4.2-demo
    docker run -d -p 8080:8080 plone-legacy:4.2-demo
    # http://localhost:8080/Plone is already there — admin / admin

It is the base image plus a seeded database, built by starting the image,
creating the site through the same script the CI gate uses, and shutting Zope
down cleanly. `ADMIN_USER` and `ADMIN_PASSWORD` still work at run time — they
are applied to the seeded database before Zope starts serving, since Zope's own
`inituser` only ever applies to a database being created. See
[`demo/README.md`](demo/README.md) for the details and the traps.

## JSON

Python grew a stdlib `json` in 2.6, so the 4.x series need nothing extra. Every
series below 4.0 ships `simplejson` instead — 3.3 finds it already in its own
buildout-cache, while 3.2 and earlier have it installed by
`shared/install-simplejson.sh`.

**The release is not the same across the matrix, and cannot be.** 2.4-era
series get 2.0.9; Plone 2.0 runs on Python 2.3, where 2.0.9's `encoder.py`
calls `items.sort(key=...)` — `key=` is 2.4+ — so `dumps(sort_keys=True)`
raises `TypeError`. That series gets 1.9.3. `install-simplejson.sh` fails the
build on a wrong pairing rather than shipping an image whose JSON breaks only
on the call that matters for extraction.

Import defensively if one script must cover the whole matrix:

```python
try:
    import simplejson as json
except ImportError:
    import json
```

## TLS (`ssl`)

**Only 4.2 has `ssl`.** In every other series `import ssl` fails, so Zope
cannot make outgoing TLS connections. That rules out HTTPS fetches and mail
over STARTTLS or SMTPS. zope.sendmail, like the mailers before it, does not
raise an error. When `socket.ssl` is missing, it skips STARTTLS and sends in
plain text, and a server that requires TLS then refuses the mail.

| Python | Series | `ssl` | Why |
|---|---|---|---|
| 2.7.18 | 4.2 | yes, OpenSSL 3.0 (bookworm) | `_ssl.c` builds against OpenSSL 3 |
| 2.6.9 | 4.0, 4.1 | no | `_ssl.c` needs the pre-1.1 OpenSSL structs (`invalid use of incomplete typedef 'X509_NAME_ENTRY'`) |
| 2.4.6, 2.3.7 | 1.0 – 3.3 | no | older still |

[V 2026-10-11] A static OpenSSL 1.0.2u does make 2.4 and 2.6 work, with TLS 1.2
ciphers for STARTTLS and HTTPS. It is not shipped. 1.0.2 has been end-of-life
since 2019, and neither interpreter verifies certificates or sends SNI. For
mail from those series, run an SMTP relay next to the container that accepts
plain SMTP on the internal network and does TLS upstream.

## ZEO

The image becomes a ZEO client by setting `ZEO_ADDRESS`. Nothing else changes:
same entrypoint, same commands, same `/data` layout.

    docker run -d -p 8080:8080 -e ZEO_ADDRESS=zeo:8100 plone-legacy:4.2

The entrypoint rewrites the `<zodb_db main>` storage block in `zope.conf` into
a `<zeoclient>`, keeping the blob directory the image already uses. With
`ZEO_ADDRESS` unset nothing happens at all — the instance opens its local
`Data.fs` exactly as before.

| Variable | Default | Meaning |
|---|---|---|
| `ZEO_ADDRESS` | *(unset)* | `host:port` of the ZEO server. Setting it is what turns the feature on |
| `ZEO_STORAGE` | `1` | Storage name on the server |
| `ZEO_CLIENT_CACHE_SIZE` | `128MB` | Client cache size |
| `ZEO_SHARED_BLOB_DIR` | `off` | `on` when client and server share a blob filesystem |

**Client only.** The image does not run a ZEO server, though it ships the ZEO
package, so one can be run from the same image:

    docker run -d --name zeo plone-legacy:4.2 \
        sh -c 'exec $INSTANCE_HOME/bin/zopepy -c "import sys, ZEO.runzeo; \
            sys.argv = [\"runzeo\", \"-a\", \"0.0.0.0:8100\", \"-f\", \"/data/filestorage/Data.fs\"]; \
            ZEO.runzeo.main()"'

Verified [V 2026-08-21], including that the rewritten conf keeps the image's
own `blob-dir`.

Two consequences worth knowing, both because the local `Data.fs` is never
opened in client mode:

- **`-demo` images do not seed under ZEO.** The baked database would never be
  read, so the entrypoint says so and skips it rather than seeding a file
  nothing opens.
- **`inituser` is written only when `ADMIN_PASSWORD` is set.** Zope applies
  `inituser` whenever the file exists — it does not check whether the database
  already has users — so writing it unconditionally would re-apply it to the
  shared database on every client start and clobber a changed password.

## Upgrading a database

The image carries an `upgrade` command that runs Plone's own `portal_migration`
against the database in `/data` and commits the result. The point of the matrix
is that the hops can be chained: mount the same volume into the next version
up, one version at a time.

    docker run --rm -v mydata:/data plone-legacy:4.2 upgrade

**One-shot, against a stopped database.** FileStorage takes an exclusive lock,
so `docker exec` into a running container fails with `zc.lockfile.LockError` —
which reads like corruption rather than like "stop the server first". Stop the
instance, run `upgrade`, start it again.

`SITE_ID` picks the site to migrate (default `Plone`). The command exits
non-zero and commits **nothing** if the migration fails or does not reach the
filesystem version; it is also idempotent — a second run reports `already at
<version>; nothing to do`.

There is a matching `run` command for any other script:

    docker run --rm -v mydata:/data plone-legacy:4.2 run /path/to/script.py

Three things the upgrade script does that a bare `zopectl run` does not, each
of which is a failure otherwise: it wraps the root in a request, authenticates
as an unrestricted user, and **enters the local component site**. Without the
last one a 3.x → 4.x migration dies on
`ComponentLookupError: IViewletSettingsStorage`, which names nothing useful.
The hook for it moved twice across the matrix, so it is discovered at run time
rather than branched on a version.

Do not trust the exit status of `zopectl run`/`instance run` itself: [V
2026-08-21] a failed 3.3 → 4.0 migration that logged `Migration has failed`
still exited 0. The `upgrade` command therefore trusts a sentinel the script
prints only after a successful commit, and nothing else.

## Patches

4.2 ships upstream bytes untouched. Should a future series need a patch, the
policy is:

- patches live in `<version>/patches/` as reviewable unified diffs, never as
  in-line `sed` in a Dockerfile;
- they are applied with `patch -p1 --forward --batch`, so a patch that no
  longer applies **fails the build** rather than silently doing nothing;
- each one is justified in the version README by the error text it removes, and
  the blast radius is measured rather than asserted.

## Development

    make help             # list targets
    make lint             # hadolint + shellcheck + yaml checks (via docker)
    make format           # shfmt (via docker)

Shared build logic lives in `shared/`:

| File | Purpose |
|---|---|
| `build-python2.sh` | Builds a historical CPython 2.x with the multiarch and toolchain mitigations; `PYTHON_REQUIRE_SSL=1` gates on `ssl` |
| `build-pil.sh` | Builds PIL 1.1.6 with working JPEG + PNG |
| `build-plone-buildout.sh` | Offline buildout from a UnifiedInstaller's bundled cache |
| `docker-entrypoint-buildout.sh` | Buildout-era entrypoint (`bin/instance fg`, `parts/instance/` paths) |
| `docker-entrypoint.sh` | Tarball-era entrypoint (`bin/zopectl fg`, `etc/zope.conf` paths) |
| `build-elementtree.sh` | Builds ElementTree 1.2.7 for Plone 3.0's Marshall dependency |
| `create-plone-site.sh` | Creates a site on a running instance, discovering the factory per era |
| `seed-demo-site.sh` | Build-time driver behind the `-demo` images |
| `reset-admin-password.py` | Applies `ADMIN_USER`/`ADMIN_PASSWORD` to a seeded database |
| `configure-zeo.sh` | Rewrites `zope.conf` into a ZEO client when `ZEO_ADDRESS` is set |
| `upgrade-plone.py` | Runs `portal_migration` and commits it, behind the `upgrade` command |
| `install-simplejson.sh` | Installs simplejson into a pre-2.6 interpreter, with a `sort_keys` round-trip gate |
| `json-probe.py` | Asserts a JSON module imports and round-trips, used by the smoke test |
| `smoke-test.sh` | The CI gate: HTTP, auth, product load, optional site creation |

Every shared script is now present: `build-elementtree.sh` and
`docker-entrypoint.sh` arrived with 3.0, the last series to need a new one.

Per-version notes — including each version's validated/hypothesised ledger —
live in that version directory's README.
