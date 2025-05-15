# /home/norbert/sqlite3-android/Makefile
#
.PHONY: fetch-sqlite-info print build clean clean-all download unpack check-ndk-path .DEFAULT_GOAL
.DEFAULT_GOAL		:= build

# File to store fetched SQLite information
SQLITE_INFO_FILE := .sqlite_info

# Attempt to include the info file.
# If it doesn't exist, 'make' will try to build it using the rule below.
-include $(SQLITE_INFO_FILE)

# Rule to create/update .sqlite_info
$(SQLITE_INFO_FILE):
	@echo "===> Fetching SQLite metadata..."
	@SQLITE_DOWNLOAD_PAGE_CONTENT=$$(curl -fsSL https://sqlite.org/download.html); \
	if [ -z "$$SQLITE_DOWNLOAD_PAGE_CONTENT" ]; then \
		echo "Error: curl failed to fetch download page." >&2; \
		rm -f $(SQLITE_INFO_FILE); \
		exit 1; \
	fi; \
	AMALGAMATION_LINE=$$(echo "$$SQLITE_DOWNLOAD_PAGE_CONTENT" | grep '^PRODUCT,[^,]*,[0-9]\{4\}/sqlite-amalgamation-[0-9]*\.zip' | head -n 1); \
	if [ -z "$$AMALGAMATION_LINE" ]; then \
		echo "Error: Failed to find amalgamation line in CSV data from download page." >&2; \
		echo "Page content sample (first 600 chars):" >&2; \
		echo "$$SQLITE_DOWNLOAD_PAGE_CONTENT" | head -c 600 | sed 's/^/| /' >&2; \
		echo "Attempted grep pattern: '^PRODUCT,[^,]*,[0-9]\{4\}/sqlite-amalgamation-[0-9]*\.zip'" >&2; \
		rm -f $(SQLITE_INFO_FILE); \
		exit 1; \
	fi; \
	YYYY_VAL=$$(echo "$$AMALGAMATION_LINE" | cut -d',' -f3 | cut -d'/' -f1); \
	AMALGAMATION_ZIP_FILENAME=$$(echo "$$AMALGAMATION_LINE" | cut -d',' -f3 | cut -d'/' -f2); \
	SQLITE_AMALGATION_VAL=$$(echo "$$AMALGAMATION_ZIP_FILENAME" | sed 's/\.zip$$//'); \
	if [ -z "$$YYYY_VAL" ] || [ -z "$$SQLITE_AMALGATION_VAL" ]; then \
		echo "Error: Failed to parse YYYY or SQLITE_AMALGATION from CSV data." >&2; \
		echo "AMALGAMATION_LINE: $$AMALGAMATION_LINE" >&2; \
		echo "Parsed YYYY_VAL: '$$YYYY_VAL'" >&2; \
		echo "Parsed AMALGAMATION_ZIP_FILENAME: '$$AMALGAMATION_ZIP_FILENAME'" >&2; \
		echo "Parsed SQLITE_AMALGATION_VAL: '$$SQLITE_AMALGATION_VAL'" >&2; \
		rm -f $(SQLITE_INFO_FILE); \
		exit 1; \
	fi; \
	echo "YYYY := $$YYYY_VAL" > $(SQLITE_INFO_FILE); \
	echo "SQLITE_AMALGATION := $$SQLITE_AMALGATION_VAL" >> $(SQLITE_INFO_FILE); \
	echo "SQLITE_SOURCEURL := https://www.sqlite.org/$$YYYY_VAL/$$SQLITE_AMALGATION_VAL.zip" >> $(SQLITE_INFO_FILE); \
	echo "===> SQLite metadata (from CSV) fetched and stored in $(SQLITE_INFO_FILE)."

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

print: $(SQLITE_INFO_FILE)
	@if [ -z "$(SQLITE_AMALGATION)" ] || [ -z "$(SQLITE_SOURCEURL)" ] || [ -z "$(YYYY)" ]; then \
		$(error Essential SQLite variables are not set. Check $(SQLITE_INFO_FILE) or run 'make $(SQLITE_INFO_FILE)' manually); \
	fi
	@echo "SQLITE_AMALGATION: $(SQLITE_AMALGATION)"
	@echo "SQLITE_SOURCEURL: $(SQLITE_SOURCEURL)"
	@echo "YYYY: $(YYYY)"
