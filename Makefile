GIT_COMMIT	?= $(shell git rev-parse HEAD)
GIT_TAG	?= $(shell git tag --points-at HEAD)
DIST_TYPE	?= snapshot
BRANCH	?= $(shell git rev-parse --abbrev-ref HEAD)
TARGET_PLATFORM = ${TARGET_PLATFORM}
PROJECT = sam

build: 
	cargo build --release

build_macos_osxcross: 
	cargo build --release --target x86_64-apple-darwin 

check: build
	cargo clippy && cargo check && cargo fmt -- --check

test: build check
	cargo test --release

package_linux: test check build version 
	cd ./target/release/ && tar -czvf $(PROJECT)_linux_x86_64_$(VERSION).tar.gz $(PROJECT)

package_macos_cross: build_macos_osxcross version 
	cd ./target/x86_64-apple-darwin/release && tar -czvf $(PROJECT)_macos_x86_64_$(VERSION).tar.gz $(PROJECT)

version:
	$(info =====  $@  =====)
ifneq ($(GIT_TAG),)
	$(eval VERSION := $(GIT_TAG))
else
	$(eval VERSION := $(GIT_COMMIT)-SNAPSHOT)
endif
	$(info $(VERSION) on commit $(GIT_COMMIT))

release_upload: package
ifneq ($(GIT_TAG),)
	gh release upload $(VERSION) ./$(PROJECT)_$(TARGET_PLATFORM)_$(VERSION).tar.gz 
endif

create_release: version
ifneq ($(GIT_TAG),)
	gh release create -t "Release $(VERSION)" -n "" --target master $(GIT_TAG)
	gh release upload $(GIT_TAG) ./target/release/$(PROJECT)_linux_x86_64_$(VERSION).tar.gz 
	gh release upload $(GIT_TAG) ./target/x86_64-apple-darwin/release/$(PROJECT)_macos_x86_64_$(VERSION).tar.gz 
endif

.PHONY: version create_release 
