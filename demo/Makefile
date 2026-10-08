# -demo variants of the 4.3 - 5.2 images.
# All tooling runs via docker: no local installs required beyond curl.

IMAGE_PREFIX ?= plone-demo
DOCKER ?= docker

# The official images are linux/amd64 only. On an arm64 host (Apple Silicon)
# they run under emulation.
PLATFORM ?= linux/amd64

# Every series with a -demo variant, oldest first. Keep in sync with the
# matrix in ../.github/workflows/demo-build.yml.
SERIES := 4.3 5.0 5.1 5.2

# series -> full version, and the official image it is built on, pinned by
# digest so that a demo image is always seeded from exactly the image that was
# reviewed. Resolve a digest with:
#   docker buildx imagetools inspect --format '{{.Manifest.Digest}}' plone:<tag>
FULL_VERSION_4.3 := 4.3.19
FULL_VERSION_5.0 := 5.0.8
FULL_VERSION_5.1 := 5.1.6
FULL_VERSION_5.2 := 5.2.14
BASE_4.3 := docker.io/library/plone:4.3.19@sha256:a717118d21b880e96f83a96fce868ce15bd96b102225b1691f61fa1157d26840
BASE_5.0 := docker.io/library/plone:5.0.8@sha256:010d8e92106ef5aa3ad43664780f29c8844b79a4b89bb203b051f9a690c38274
BASE_5.1 := docker.io/library/plone:5.1.6@sha256:067ec2433da954c1fb1f9abad7233b7a7409688a913ff048871a0644d24827a7
BASE_5.2 := docker.io/library/plone:5.2.14@sha256:e73ae6e9864e43d4d49169f9fda09012d48c7720e8e204a8b0304b764600923b

# [V 2026-10-08] The signal that stops each base image cleanly. 4.3 - 5.1 trap
# TERM and run `bin/instance stop`. 5.2 execs `bin/instance console`, which
# ignored TERM until docker's 120s timeout killed it, and stops in about a
# second on INT.
STOP_SIGNAL_4.3 := TERM
STOP_SIGNAL_5.0 := TERM
STOP_SIGNAL_5.1 := TERM
STOP_SIGNAL_5.2 := INT

# [V 2026-10-08] Where each base image logs, for the smoke test's product-load
# check: 4.3 - 5.1 write /data/log/instance.log; 5.2 logs to stdout/stderr
# and writes no log file at all.
LOG_SOURCE_4.3 := file
LOG_SOURCE_5.0 := file
LOG_SOURCE_5.1 := file
LOG_SOURCE_5.2 := docker

define require_version
	@test -n "$(FULL_VERSION_$(1))" || { \
		echo "No FULL_VERSION_$(1) in the Makefile — is '$(1)' a real series?"; \
		exit 1; \
	}
endef

.PHONY: help
help: ## Show this help
	@grep -hE '^[a-zA-Z0-9_.%-]+:.*## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS=":.*## "}; {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}'

.PHONY: seed-%
seed-%: ## Seed a site from the official image, e.g. make seed-5.2
	$(call require_version,$*)
	PLATFORM=$(PLATFORM) STOP_SIGNAL=$(STOP_SIGNAL_$*) \
		./seed.sh $(BASE_$*) build/$*

# Defined BEFORE demo-%: macOS ships GNU Make 3.81, which takes the first
# matching pattern rather than the shortest stem (see ../legacy/Makefile).
.PHONY: demo-image-%
demo-image-%: ## Build only the -demo image from an existing seed, e.g. make demo-image-5.2
	$(call require_version,$*)
	@test -f build/$*/filestorage/Data.fs || { echo "No seed in build/$*/ — run make seed-$*"; exit 1; }
	$(DOCKER) build \
		--platform $(PLATFORM) \
		--build-arg BASE_IMAGE=$(BASE_$*) \
		--build-arg SEED=build/$* \
		-t $(IMAGE_PREFIX):$(FULL_VERSION_$*)-demo \
		-t $(IMAGE_PREFIX):$*-demo \
		.

.PHONY: demo-%
demo-%: ## Seed and build the -demo image for a series, e.g. make demo-5.2
	$(call require_version,$*)
	$(MAKE) seed-$*
	$(MAKE) demo-image-$*

.PHONY: test-demo-%
test-demo-%: ## Smoke-test a built -demo image, e.g. make test-demo-5.2
	$(call require_version,$*)
	SMOKE_EXPECT_SITE=1 \
	SMOKE_LOG_SOURCE=$(LOG_SOURCE_$*) \
	IMAGE=$(IMAGE_PREFIX):$(FULL_VERSION_$*)-demo \
		../legacy/shared/smoke-test.sh

.PHONY: demos
demos: ## Build every -demo image (slow: each one boots Zope and creates a site)
	@for v in $(SERIES); do $(MAKE) demo-$$v || exit 1; done

.PHONY: test-demos
test-demos: ## Smoke-test every built -demo image
	@for v in $(SERIES); do $(MAKE) test-demo-$$v || exit 1; done

.PHONY: lint
lint: ## Lint the Dockerfile (hadolint) and shell scripts (shellcheck)
	@echo "hadolint Dockerfile"
	@$(DOCKER) run --rm -v "$(CURDIR):/mnt:ro" -w /mnt \
		hadolint/hadolint hadolint Dockerfile
	@echo "shellcheck *.sh"
	@$(DOCKER) run --rm -v "$(CURDIR):/mnt:ro" -w /mnt koalaman/shellcheck:stable \
		-s sh seed.sh demo-entrypoint.sh
	@echo "lint OK"

.PHONY: clean
clean: ## Remove seeds and locally built -demo images
	rm -rf build
	-@$(DOCKER) rmi -f $(foreach v,$(SERIES),$(IMAGE_PREFIX):$(v)-demo $(IMAGE_PREFIX):$(FULL_VERSION_$(v))-demo) 2>/dev/null
