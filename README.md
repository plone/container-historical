> **⚠️ WARNING**: **These images are no longer supported.** They are preserved for
> historical reference only. Plone 4.x and 5.x have both reached end of life, the
> images receive no security or dependency updates, and they are no longer part of
> the [Docker Official Images](https://docs.docker.com/docker-hub/official_images/)
> programme. Do **not** run them in production or expose them to an untrusted
> network.
>
> They remain useful for content extraction, migration rehearsal and archaeology.
> For a supported Plone, use Plone 6:
> [plone-backend](https://github.com/plone/container-backend),
> [plone-frontend](https://github.com/plone/container-frontend) and
> [plone-zeo](https://github.com/plone/container-zeo). See the
> [release schedule](https://plone.org/download/release-schedule).

# Plone

[Plone](https://plone.org) is a free and open source content management system built on top of the Zope application server.

## Features

- Images for **Plone 5.x** and **Plone 4.x**, plus a `legacy/` matrix reaching back to **Plone 1.0**
- Images for **Plone 6** are available at https://github.com/plone/container-backend
- Enable add-ons via environment variables
- Built-in RelStorage support, configurable via environment variables (requires Plone 5.2+)
- Built-in LDAP/AD support via pas.plugins.ldap (requires Plone 5.1+)

> **NOTE**: **Python 2 based Docker images** are no longer supported by the [Docker Official Images](https://docs.docker.com/docker-hub/official_images/) \
If you need Python 2, you can use `plone/plone:5-python2` instead of `plone:5-python2`.

## Images

Newest to oldest. For the 4.3 - 5.2 series only the **latest point release** is
listed; earlier point releases remain in the repository and on Docker Hub.

| Plone | Python | Variant | Built from | Published tags |
|---|---|---|---|---|
| 5.2.14 | 3.8 | Debian | [`5.2/5.2.14/debian/Dockerfile`](5.2/5.2.14/debian/Dockerfile) | `latest`, `5`, `5.2`, `5.2.14`, `python38`, `5-python38`, `5.2-python38`, `5.2.14-python38` |
| 5.2.14 | 3.8 | Alpine | [`5.2/5.2.14/alpine/Dockerfile`](5.2/5.2.14/alpine/Dockerfile) | *not published* |
| 5.2.14 | 3.7 | Debian | [`5.2/5.2.14/python37/Dockerfile`](5.2/5.2.14/python37/Dockerfile) | *not published* |
| 5.2.14 | 2.7 | Debian | [`5.2/5.2.14/python2/Dockerfile`](5.2/5.2.14/python2/Dockerfile) | *not published* |
| 5.1.6 | 2.7 | Debian | [`5.1/5.1.6/debian/Dockerfile`](5.1/5.1.6/debian/Dockerfile) | `5.1`, `5.1.6` |
| 5.1.6 | 2.7 | Alpine | [`5.1/5.1.6/alpine/Dockerfile`](5.1/5.1.6/alpine/Dockerfile) | `5.1-alpine`, `5.1.6-alpine` |
| 5.0.8 | 2.7 | Debian | [`5.0/5.0.8/debian/Dockerfile`](5.0/5.0.8/debian/Dockerfile) | `5.0`, `5.0.8` |
| 5.0.8 | 2.7 | Alpine | [`5.0/5.0.8/alpine/Dockerfile`](5.0/5.0.8/alpine/Dockerfile) | *not published* |
| 4.3.19 | 2.7 | Debian | [`4.3/4.3.19/debian/Dockerfile`](4.3/4.3.19/debian/Dockerfile) | `4`, `4.3`, `4.3.19` |
| 4.3.19 | 2.7 | Alpine | [`4.3/4.3.19/alpine/Dockerfile`](4.3/4.3.19/alpine/Dockerfile) | `4-alpine`, `4.3-alpine`, `4.3.19-alpine` |
| 4.2.6 | 2.7.18 | Debian *(legacy)* | [`legacy/4.2/Dockerfile`](legacy/4.2/Dockerfile) | `4.2`, `4.2.6`, `4.2-demo`, `4.2.6-demo` |
| 4.1.6 | 2.6.9 | Debian *(legacy)* | [`legacy/4.1/Dockerfile`](legacy/4.1/Dockerfile) | `4.1`, `4.1.6`, `4.1-demo`, `4.1.6-demo` |
| 4.0.9 | 2.6.9 | Debian *(legacy)* | [`legacy/4.0/Dockerfile`](legacy/4.0/Dockerfile) | `4.0`, `4.0.9`, `4.0-demo`, `4.0.9-demo` |
| 3.3.6 | 2.4.6 | Debian *(legacy)* | [`legacy/3.3/Dockerfile`](legacy/3.3/Dockerfile) | `3.3`, `3.3.6`, `3.3-demo`, `3.3.6-demo` |
| 3.2.3 | 2.4.6 | Debian *(legacy)* | [`legacy/3.2/Dockerfile`](legacy/3.2/Dockerfile) | `3.2`, `3.2.3`, `3.2-demo`, `3.2.3-demo` |
| 3.1.7 | 2.4.6 | Debian *(legacy)* | [`legacy/3.1/Dockerfile`](legacy/3.1/Dockerfile) | `3.1`, `3.1.7`, `3.1-demo`, `3.1.7-demo` |
| 3.0.5 | 2.4.6 | Debian *(legacy)* | [`legacy/3.0/Dockerfile`](legacy/3.0/Dockerfile) | `3.0`, `3.0.5`, `3.0-demo`, `3.0.5-demo` |
| 2.5.4-2 | 2.4.6 | Debian *(legacy)* | [`legacy/2.5/Dockerfile`](legacy/2.5/Dockerfile) | `2.5`, `2.5.4-2`, `2.5-demo`, `2.5.4-2-demo` |
| 2.1.4 | 2.4.6 | Debian *(legacy)* | [`legacy/2.1/Dockerfile`](legacy/2.1/Dockerfile) | `2.1`, `2.1.4`, `2.1-demo`, `2.1.4-demo` |
| 2.0.5 | 2.3.7 | Debian *(legacy)* | [`legacy/2.0/Dockerfile`](legacy/2.0/Dockerfile) | `2.0`, `2.0.5`, `2.0-demo`, `2.0.5-demo` |
| 1.0.6 | 2.3.7 | Debian *(legacy)* | [`legacy/1.0/Dockerfile`](legacy/1.0/Dockerfile) | `1.0`, `1.0.6`, `1.0-demo`, `1.0.6-demo` |

### Where the tags live

The two halves of the table publish to **different places**, and the tag names
alone do not say which:

| Rows | Registry | Pull with |
|---|---|---|
| 4.3 - 5.2 | the official `plone` image | `docker pull plone:5.2.14` |
| 5.2.14 (Debian) | also `plone/plone` and GHCR | `docker pull plone/plone:5.2.14`<br>`docker pull ghcr.io/plone/plone.docker:5.2.14` |
| `legacy/` | `plone/plone` and GHCR | `docker pull plone/plone:4.2`<br>`docker pull ghcr.io/plone/plone.docker:4.2` |

The 5.2.14 tags on `plone/plone` and GHCR are copies of the official image, made
by digest rather than rebuilt: `plone/plone:5.2.14` *is* `plone:5.2.14`. The
tags copied, and the digests they are pinned to, are listed in
[`mirror/official-tags.txt`](mirror/official-tags.txt); the
[`mirror official`](.github/workflows/mirror-official.yml) workflow publishes
them.

`plone/plone`'s other 4.3 - 5.2 tags come from an earlier mirror, last pushed in
**March 2021**, and lag behind the official image. For any other 4.3 - 5.2 tag,
prefer `plone:<tag>`.

Each legacy series publishes four tags — the full version and the series, each
with a `-demo` counterpart that ships a Plone site already created.

The 4.3 - 5.2 images take Python from an upstream `python:*` base image. The
`legacy/` images build the interpreter from source, because no usable base
image exists for Python 2.3 - 2.7 of that vintage.

Floating tags such as `5.2-alpine`, `5.2-python2` and `5.2-python37` exist on
the official image but point at **earlier** point releases than 5.2.14 — the 5.2.14
roll published only the Python 3.8 variant.

## Legacy images (Plone 1.0 - 4.2)

Images for Plone releases older than 4.3 live under [`legacy/`](legacy/) and are
built separately. They are intended for **content extraction, migration
rehearsal and archaeology only** — these stacks have known, unpatched security
issues and must never be exposed.

Each series also ships a `-demo` variant with a Plone site already created, and
carries an `upgrade` command so a database can be walked up one version at a
time. See [`legacy/README.md`](legacy/README.md).

## Prerequisites

Make sure you have Docker installed and running for your platform.
You can download Docker from https://www.docker.com.

## Usage

Choose either single Plone instance or ZEO cluster.

> **NOTE**: It is inadvisable to use following configurations for production.

### Standalone Plone instance

Plone standalone instances are best suited for testing Plone and development.

Download and start the latest Plone 5 container, based on [Debian](https://www.debian.org/).

```shell
docker run -p 8080:8080 plone
```

This image includes `EXPOSE 8080` (the Plone port), standard container linking will make it automatically available to the linked containers.

You can add a Plone Site at http://localhost:8080 - default Zope user and password are **`admin/admin`**.

By using the `tags` listed above a Plone container with a different version can be downloaded and started.

The following command starts a Plone 4.3 container, based on [Alpine](https://alpinelinux.org/).

```shell
docker run -p 8080:8080 plone:4.3-alpine
```

### Plone as ZEO cluster

ZEO cluster are best suited for production setups, you will **need** a loadbalancer.

Start ZEO server in the background

```shell
docker run -d --name=zeo plone zeo
```

Start 2 Plone clients (also in the background)

```shell
docker run -d --name=instance1 --link=zeo -e ZEO_ADDRESS=zeo:8080 -p 8081:8080 plone
docker run -d --name=instance2 --link=zeo -e ZEO_ADDRESS=zeo:8080 -p 8082:8080 plone
```

### Start Plone in debug mode

You can also start Plone in debug mode (`fg`) by running

```shell
docker run -p 8080:8080 plone fg
```

Debug mode may be used with ZEO

```shell
docker run --link=zeo -e ZEO_ADDRESS=zeo:8080 -p 8080:8080 plone fg
```

For more information on how to extend this image with your own custom settings,
adding more add-ons, building it or mounting volumes,
please refer to our [documentation](https://docs.plone.org/manage/docker/docs/index.html).


## Supported environment variables

The Plone image uses several environment variable that allow to specify a more specific setup.

### For basic usage

* `ADDONS` - Customize Plone via Plone add-ons using this environment variable
* `ZEO_ADDRESS` - This environment variable allows you to run Plone image as a ZEO client.
* `SITE` - Add Plone with this id to `Data.fs` on first run. If NOT provided, you'll have to manually add a Plone Site via web UI
* `VERSIONS` - Use specific versions of Plone Add-on or python libraries

Run Plone and install two addons ([eea.facetednavigation](https://github.com/eea/eea.facetednavigation) and [collective.easyform](https://github.com/collective/collective.easyform)).

```shell
docker run -p 8080:8080 -e SITE="mysite" -e ADDONS="eea.facetednavigation collective.easyform" plone
```

To use specific add-ons versions:

```shell
 -e ADDONS="eea.facetednavigation collective.easyform" -e VERSIONS="eea.facetednavigation=13.3 collective.easyform=2.1.0"
```

RestAPI:

```shell
docker run -p 8080:8080 -e SITE=plone plone

curl -H 'Accept: application/json' http://localhost:8080/plone
```

### For advanced usage

**Plone:**

* `PLONE_ADDONS`, `ADDONS` - Customize Plone via Plone add-ons using this environment variable
* `PLONE_SITE`, `SITE` - Add Plone with this id to `Data.fs` on first run. If NOT provided, you'll have to manually add a Plone Site via web UI
* `PLONE_VERSIONS`, `VERSIONS` - Use specific versions of Plone Add-on or python libraries
* `PLONE_PROFILES, PROFILES` - GenericSetup profiles to include when `SITE` environment provided.
* `PLONE_ZCML`, `ZCML` - Include custom Plone add-ons ZCML files
* `PLONE_DEVELOP`, `DEVELOP` - Develop new or existing Plone add-ons
* `BUILDOUT_EXTENDS` - Add configuration files that buildout should extend
* `FIND_LINKS` - Add custom `find-links` to the buildout configuration
* `SOURCES` - Add custom `sources` to the buildout configuration

To add custom sources, the `SOURCES` env var needs to be a string containing a *comma*-separated list of sources.
This is different from the other environment variables described above, which are *space*-separated.

For example:

```shell
 -e SOURCES="plone.restapi = git https://github.com/plone/plone.restapi,plone.staticresources = git https://github.com/plone/plone.staticresources"
```

**ZEO:**

* `ZEO_ADDRESS` - This environment variable allows you to run Plone image as a ZEO client.
* `ZEO_READ_ONLY` - Run Plone as a read-only ZEO client. Defaults to `off`.
* `ZEO_CLIENT_READ_ONLY_FALLBACK` - A flag indicating whether a read-only remote storage should be acceptable as a fallback when no writable storages are available. Defaults to `false`.
* `ZEO_SHARED_BLOB_DIR` - Set this to on if the ZEO server and the instance have access to the same directory. Defaults to `off`.
* `ZEO_STORAGE` - Set the storage number of the ZEO storage. Defaults to `1`.
* `ZEO_CLIENT_CACHE_SIZE` - Set the size of the ZEO client cache. Defaults to `128MB`.
* `ZEO_PACK_KEEP_OLD` - Can be set to false to disable the creation of *.fs.old files before the pack is run. Defaults to true.

**CORS:**

* `CORS_ALLOW_ORIGIN` - Origins that are allowed access to the resource. Either a comma separated list of origins, for example `http://example.net,http://mydomain.com` or `*`. Defaults to `http://localhost:3000,http://127.0.0.1:3000`
* `CORS_ALLOW_METHODS` - A comma separated list of HTTP method names that are allowed by this CORS policy, for example `DELETE,GET,OPTIONS,PATCH,POST,PUT`. Defaults to `DELETE,GET,OPTIONS,PATCH,POST,PUT`
* `CORS_ALLOW_CREDENTIALS` - Indicates whether the resource supports user credentials in the request. Defaults to `true`
* `CORS_EXPOSE_HEADERS` - A comma separated list of response headers clients can access, for example `Content-Length,X-My-Header`. Defaults to `Content-Length,X-My-Header`
* `CORS_ALLOW_HEADERS` - A comma separated list of request headers allowed to be sent by the client, for example `X-My-Header`. Defaults to `Accept,Authorization,Content-Type,X-Custom-Header`
* `CORS_MAX_AGE` - Indicates how long the results of a preflight request can be cached. Defaults to `3600`

**RELSTORAGE:**

* `RELSTORAGE_ADAPTER_OPTIONS` - A comma separated list of RelStorage adapter options to set for the plone instance (using [plone.recipe.zope2instance](https://relstorage.readthedocs.io/en/latest/configure-application.html#configuring-plone)). This is required in order to use RelStorage.

All other available environment variables match exactly with RelStorage settings, according to the following table and the [settings specification available on the docs](https://relstorage.readthedocs.io/en/latest/relstorage-options.html).

| Environment variable                      | RelStorage option              | Default value                   |
| ----------------------------------------- | ------------------------------ | ------------------------------- |
| RELSTORAGE_NAME                           | name                           | None                            |
| RELSTORAGE_READ_ONLY                      | read-only                      | None                            |
| RELSTORAGE_KEEP_HISTORY                   | keep-history                   | None                            |
| RELSTORAGE_COMMIT_LOCK_TIMEOUT            | commit-lock-timeout            | None                            |
| RELSTORAGE_COMMIT_LOCK_ID                 | commit-lock-id                 | None                            |
| RELSTORAGE_CREATE_SCHEMA                  | create-schema                  | None                            |
| RELSTORAGE_BLOB_DIR                       | blob-dir                       | /plone/instance/var/blobstorage |
| RELSTORAGE_SHARED_BLOB_DIR                | shared-blob-dir                | None                            |
| RELSTORAGE_BLOB_CACHE_SIZE                | blob-cache-size                | None                            |
| RELSTORAGE_BLOB_CACHE_SIZE_CHECK          | blob-cache-size-check          | None                            |
| RELSTORAGE_BLOB_CACHE_SIZE_CHECK_EXTERNAL | blob-cache-size-check-external | None                            |
| RELSTORAGE_BLOB_CHUNK_SIZE                | blob-chunk-size                | None                            |
| RELSTORAGE_REPLICA_CONF                   | replica-conf                   | None                            |
| RELSTORAGE_RO_REPLICA_CONF                | ro-replica-conf                | None                            |
| RELSTORAGE_REPLICA_TIMEOUT                | replica-timeout                | None                            |
| RELSTORAGE_REVERT_WHEN_STALE              | revert-when-stale              | None                            |
| RELSTORAGE_PACK_GC                        | pack-gc                        | None                            |
| RELSTORAGE_PACK_PREPACK_ONLY              | pack-prepack-only              | None                            |
| RELSTORAGE_PACK_SKIP_PREPACK              | pack-skip-prepack              | None                            |
| RELSTORAGE_PACK_BATCH_TIMEOUT             | pack-batch-timeout             | None                            |
| RELSTORAGE_PACK_COMMIT_BUSY_DELAY         | pack-commit-busy-delay         | None                            |
| RELSTORAGE_CACHE_PREFIX                   | cache-prefix                   | None                            |
| RELSTORAGE_CACHE_LOCAL_MB                 | cache-local-mb                 | None                            |
| RELSTORAGE_CACHE_LOCAL_OBJECT_MAX         | cache-local-object-max         | None                            |
| RELSTORAGE_CACHE_LOCAL_COMPRESSION        | cache-local-compressione       | None                            |
| RELSTORAGE_CACHE_DELTA_SIZE_LIMIT         | cache-delta-size-limit         | None                            |
| RELSTORAGE_CACHE_LOCAL_DIR                | cache-local-dir                | None                            |

## Documentation

Full documentation for end users can be found online at [docs.plone.org](https://docs.plone.org/manage/docker/docs/index.html).

## Contribute

- Issue Tracker: http://github.com/plone/container-historical/issues
- Source Code: http://github.com/plone/container-historical
- Documentation: http://docs.plone.org/

## Support

If you are having issues, please let us know at https://community.plone.org

## License

The project is licensed under the GPLv2.
