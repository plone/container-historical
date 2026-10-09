# Changelog
- Add `-demo` variants of Plone 4.3, 5.0, 5.1 and 5.2 (`4.3-demo`, `5.0-demo`, `5.1-demo`, `5.2-demo` and their full-version tags), each the official image with a Plone site already created at `/Plone`. Refs #211
  [@ericof]
- Fix the smoke test's JSON gate passing when the probe script failed to compile, and make the probe run on Python 3. Refs #211
  [@ericof]
- Publish Plone 5.2.14 as `plone/plone:5.2.14` (and GHCR), copied by digest from the official `plone:5.2.14`. `plone/plone:latest`, `5`, `5.2` and `python38` now point at 5.2.14 instead of 5.2.4. Refs #210
  [@ericof]
- Add Plone 1.0 image to the legacy matrix, completing it. Refs #197
  [@ericof]
- Add Plone 2.0 image to the legacy matrix. Refs #196
  [@ericof]
- Add Plone 2.1 image to the legacy matrix. Refs #195
  [@ericof]
- Add Plone 2.5 image to the legacy matrix. Refs #194
  [@ericof]
- Expand the legacy series-wiring checklist in legacy/README.md from four places to eight. Refs #204
  [@ericof]
- Add Plone 3.0 image to the legacy matrix. Refs #187
  [@ericof]
- Add Plone 3.1 image to the legacy matrix. Refs #186
  [@ericof]
- Add Plone 3.2 image to the legacy matrix. Refs #185
  [@ericof]
- Add Plone 3.3 image to the legacy matrix. Refs #184
  [@ericof]
- Add Plone 4.0 image to the legacy matrix. Refs #183
  [@ericof]
- Add Plone 4.1 image to the legacy matrix. Refs #182
  [@ericof]
- Add Plone 4.2 image, the first of the legacy matrix (Plone 1.0 - 4.2). For content extraction, migration and archaeology only. Refs #180
  [@ericof]
- fix shared-blob-dir always off
  [@sauzher]
- Default logging to stdout/stderr by default from 5.2.5. Setting env FILE_LOGGING to revert to previous behavior.
  [@mamico]
- Allow buildout to extend custom files
  [@pnicolli]
- Enable LDAP/AD support on Plone 5.1
  [@pnicolli]
- Only extend develop.cfg when needed
  [@pnicolli]
- Add LDAP/AD support
  [@eikichi18]
- Add RelStorage support
  [@pnicolli]
- Typo fix: CORS_TEMPLACE
  [@avoinea]
- Add find-links and sources part to custom buildout
  [pnicolli]
- Fixed interaction between SITE env var and a zeo setup. Fixes issue #135
  [pnicolli]
- Update docs
  [staeff]
- Add possibility to initialize Plone SITE with custom PROFILES/ADDONS on first run
  [avoinea refs #121]
- Cleanup docker-entrypoint.sh: Use `bin/instance console` to start Plone and `bin/zeo fg` for ZEO Server.
  See https://github.com/docker-library/official-images/pull/6343
  [avoinea]
- Added support for Diazo theme central resource directory - fixes issue #114
  [avoinea]
- Added libffi-dev to alpine 5.2.0 Dockerfile, build depedency was needed to successfully build BTrees package.
  [pigeonflight]
- Used PLONE_VERSION_RELEASE env variable in the 5.2.0 Dockerfiles... fixes issue #117
  [pigeonflght]
- add Plone 5.1 images
  [svx]
- add prerequisite of installing & running Docker
  [tkimnguyen]
- Update docs
  [svx]
- Switch from `curl` to `wget`, because `wget` has less dependencies than `curl` for Plone 5.
  [svx]
- Switch from `curl` to `wget`, because `wget` has less dependencies than `curl` for Plone 4.
  [svx]
- Remove `apt-clean`, not needed because of https://github.com/moby/moby/blob/e925820bfd5af066497800a02c597d6846988398/contrib/mkimage/debootstrap#L107-L130
  [svx]
- Add missing dependencies for pillow and transforms.
  [jladage]
- Add -m option to `useradd` command to correctly set the home dir.
  [jladage]
- Remove deprecated maintainer setting
  [svx]
- Adjust Label settings to follow best practices
  [svx]
- Add (`apt-mark showauto`), Jenkins shut up
  [svx]
- Indicate where Plone 6 images are available from
  [tkimnguyen]
- Updated Wheel Package to 0.38.1 to remove the vulnerability associated with the package
  [suryadev99]
- Release Plone 5.2.10
  [iulianpetchesi]
- Release Plone 5.2.11
  [iulianpetchesi]
- Release Plone 5.2.12
  [iulianpetchesi]
- Release Plone 5.2.13
  [valipod]
