# /home/norbert/sqlite3-android/Makefile
#
.DEFAULT_GOAL		:= build
SQLITE_DOWNLOAD_PAGE := $(shell curl -s https://sqlite.org/download.html)
YYYY := $(shell echo "$(SQLITE_DOWNLOAD_PAGE)" | grep -oP 'href="\K\d+/sqlite-amalgamation-\d+\.zip' | head -n1 | cut -d/ -f1)
SQLITE_AMALGATION := $(shell echo "$(SQLITE_DOWNLOAD_PAGE)" | grep -oP 'href=".*sqlite-amalgamation-\d+\.zip"' | sed -n 's/.*href=".*\/\(.*\)\.zip".*/\1/p' | head -n1)
#SQLITE_AMALGATION	:= sqlite-amalgamation-3490200
SQLITE_SOURCEURL := https://www.sqlite.org/$(YYYY)/$(SQLITE_AMALGATION).zip  # SQLite --version 3.49.2 Source Code: https://www.sqlite.org/download.html
# TARGET ABI            := armeabi armeabi-v7a arm64-v8a x86 x86_64 mips mips64 (or all)
TARGET_ABI		:= arm64-v8a armeabi-v7a x86 x86_64
# URL_DOWNLOADER	:= wget -c
URL_DOWNLOADER		:= aria2c -q -c -x 3
CHECK_NDKPATH		:= $(shell which ndk-build >/dev/null 2>&1 ; echo $$?)


check-ndk-path:
ifneq ($(CHECK_NDKPATH), 0)
	$(error Cannot find ndk-build in $(PATH). Make sure Android NDK directory is included in your $$PATH variable)
endif

download: check-ndk-path
	@echo "===> Downloading file $(SQLITE_SOURCEURL)"
	@test ! -s "$(SQLITE_AMALGATION).zip" && \
		$(URL_DOWNLOADER) "$(SQLITE_SOURCEURL)" || \
		echo "===> File $(SQLITE_AMALGATION).zip already exists... skipping download."

unpack: download
	@echo "===> Unpacking $(SQLITE_AMALGATION).zip"
	@unzip -qo "$(SQLITE_AMALGATION).zip"
	@mv "$(SQLITE_AMALGATION)" build

build:	unpack
	@echo "===> Building $(SQLITE_AMALGATION)"
	@ndk-build NDK_DEBUG=0 APP_ABI="$(TARGET_ABI)"

clean:
	@echo "===> Cleaning up $(SQLITE_AMALGATION), build, libs, and obj directory"
	@rm -rf "$(SQLITE_AMALGATION)" build obj libs

clean-all: clean
	@echo "===> Deleting $(SQLITE_AMALGATION).zip"
	@rm -f "$(SQLITE_AMALGATION).zip"

print:
	@echo "SQLITE_AMALGATION: $(SQLITE_AMALGATION)"
	@echo "SQLITE_SOURCEURL: $(SQLITE_SOURCEURL)"
