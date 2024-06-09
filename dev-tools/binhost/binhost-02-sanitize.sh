#!/bin/bash

# This function removes packages larger than size limit in github.

source ../../.env-shared.sh || exit 1
register_usage "$0 --pkgcache|-p <PKG_CACHE_DIRECTORY>"

# Parse input parameters
declare -a ARG_PACKAGES_TO_REMOVE
while [[ $# -gt 0 ]]; do
    case "$1" in
        --pkgcache|-p)
            readonly PKGCACHE_DIR_TO_SANITIZE="$2"
            shift 2
            ;;
	*)
            show_usage
            ;;
    esac
done

[[ ! -z "${PKGCACHE_DIR_TO_SANITIZE}" ]] || show_usage

source ${PATH_BINHOST_SCRIPT_DELETE} --pkgcache "${PKGCACHE_DIR_TO_SANITIZE}" --if-larger ${CONF_GIT_FILE_SIZE_LIMIT}
