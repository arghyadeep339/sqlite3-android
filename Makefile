# /home/norbert/sqlite3-android/Makefile
#
.DEFAULT_GOAL		:= build

# Fetch the download page content only once
SQLITE_DOWNLOAD_PAGE_FOR_MAKE := $(shell curl -s https://sqlite.org/download.html)

# Extract the relevant line from the CSV data block for the main amalgamation zip
# Pattern: PRODUCT,version,YYYY/sqlite-amalgamation-XXXXXX.zip,size,hash
AMALGAMATION_INFO_LINE := $(shell echo '$(SQLITE_DOWNLOAD_PAGE_FOR_MAKE)' | grep '^PRODUCT,[^,]*,[0-9]\{4\}/sqlite-amalgamation-[0-9]*\.zip' | head -n 1)

# Extract YYYY from the third field (RELATIVE-URL)
# e.g., from "2025/sqlite-amalgamation-3490200.zip", get "2025"
YYYY := $(shell echo '$(AMALGAMATION_INFO_LINE)' | cut -d',' -f3 | cut -d'/' -f1)

# Extract the full zip filename (e.g., sqlite-amalgamation-3490200.zip) from the third field
SQLITE_AMALGATION_ZIP_FILENAME := $(shell echo '$(AMALGAMATION_INFO_LINE)' | cut -d',' -f3 | cut -d'/' -f2)

# Extract SQLITE_AMALGATION (e.g., sqlite-amalgamation-3490200) by removing .zip extension
SQLITE_AMALGATION := $(shell echo '$(SQLITE_AMALGATION_ZIP_FILENAME)' | sed 's/\.zip$$//')

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

# Corrected print target: Only echoes variable assignments for parsing by GitHub Actions
print:
	@echo "SQLITE_AMALGATION: $(SQLITE_AMALGATION)"
	@echo "SQLITE_SOURCEURL: $(SQLITE_SOURCEURL)"
	@echo "YYYY: $(YYYY)"
