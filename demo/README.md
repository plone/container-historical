# The `-demo` variants (Plone 4.3 - 5.2)

Each of the 4.3 - 5.2 series has a `-demo` image that **already has a Plone
site**, created at the id `Plone`. Start one and browse straight to
`http://localhost:8080/Plone`.

```sh
docker run -d -p 8080:8080 plone/plone:5.2-demo
open http://localhost:8080/Plone
```

| Series | Built on | Published tags |
|---|---|---|
| 5.2 | `plone:5.2.14` | `5.2-demo`, `5.2.14-demo` |
| 5.1 | `plone:5.1.6` | `5.1-demo`, `5.1.6-demo` |
| 5.0 | `plone:5.0.8` | `5.0-demo`, `5.0.8-demo` |
| 4.3 | `plone:4.3.19` | `4.3-demo`, `4.3.19-demo` |

The tags are on `plone/plone` and `ghcr.io/plone/plone.docker`, next to the
legacy `-demo` images for 1.0 - 4.2 (see [`../legacy/demo/`](../legacy/demo/)).

| | |
|---|---|
| Site id | `Plone` |
| Admin | `admin` / `admin` |
| Everything else | identical to the base image — same Zope, Python, add-ons, environment variables |

The admin password comes from the base images, which bake `admin:admin` into
their buildout and do not read `ADMIN_PASSWORD`. These are demo images for a
throwaway stack. **Do not put them anywhere reachable.**

## Building locally

```sh
cd demo
make demo-5.2        # seeds build/5.2/, then builds plone-demo:5.2.14-demo and :5.2-demo
make test-demo-5.2   # smoke test: the site must already be there on first start
```

`make demos` and `make test-demos` cover every series. Building needs `curl`
on the host, and runs the amd64-only images under emulation on Apple Silicon.

## How it works

The base images are the **official `plone` images**, pinned by digest in the
[`Makefile`](Makefile), and are not rebuilt: their Debian releases have left
`deb.debian.org`, so a rebuild would fail or produce a different image. For the
same reason nothing can be installed into them — they ship neither `curl` nor
`wget` — so the site is created from outside:

1. [`seed.sh`](seed.sh) starts the official image as it is, waits for HTTP,
   and creates the site through
   [`legacy/shared/create-plone-site.sh`](../legacy/shared/create-plone-site.sh),
   the same script the legacy images use. It stops Zope with the signal that
   closes the storage cleanly, checks that it did, and copies `Data.fs` and the
   blob storage out with `docker cp`.
2. [`Dockerfile`](Dockerfile) adds that seed at `/app/seed`, plus
   [`demo-entrypoint.sh`](demo-entrypoint.sh): on first start it copies the
   seed into `/data`, then runs the base image's own `/docker-entrypoint.sh`
   with the same arguments. When `/data` already holds a database nothing is
   copied, so mounting a real site over a demo image still works.

## Validated facts

- **[V 2026-10-08]** **5.2 needs SIGINT to stop cleanly.** Its entrypoint
  execs `bin/instance console`, which ignored SIGTERM until `docker stop`'s
  timeout killed it — leaving no `Data.fs.index`, the evidence that the
  storage was closed. On SIGINT it stops in about a second. 4.3 - 5.1 trap
  SIGTERM and run `bin/instance stop`. See `STOP_SIGNAL_*` in the Makefile.
- **[V 2026-10-08]** **5.2 writes no log file.** It logs to stdout/stderr, so
  the smoke test reads its product-load errors from `docker logs`
  (`SMOKE_LOG_SOURCE=docker`); 4.3 - 5.1 log to `/data/log/instance.log`.
- **[V 2026-10-08]** **Plone 5's theme is not a skin.** The add-site form
  forces `plonetheme.barceloneta:default`, a Diazo theme, so the skin check
  `create-plone-site.sh` uses for Plone 4 finds nothing on Plone 5. The script
  checks for `++theme++barceloneta` in the rendered page there instead.
