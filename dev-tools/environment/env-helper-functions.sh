#!/bin/bash

declare -A USAGE_DESCRIPTIONS
declare -A FAILURE_HANDLERS

echo_color() { # Usage: echo_color COLOR MESSAGE
    echo -e "${1}${2}${COLOR_NC}"
}

# Handling errors.
failure() {
    local line="${BASH_LINENO[0]}"
    local cmd="${BASH_COMMAND}"
    local file="${BASH_SOURCE[1]}"
    local custom_message="$1"
    echo_color ${COLOR_RED} "[ Error at line $line in file '$file' ]"
    if [[ -n "$custom_message" ]]; then
        echo_color ${COLOR_RED} "$custom_message"
    else
        echo_color ${COLOR_RED} "Failed command: '$cmd'"
    fi

    # Execute failure handler if added
    local failure_handler_name="$(basename \"${BASH_SOURCE[1]}\")"
    local failure_handler=${FAILURE_HANDLERS[$failure_handler_name]}
    [[ -n "${failure_handler}" ]] && eval "${failure_handler}"

    exit 1
}

register_failure_handler() {
    local file="$(basename \"${BASH_SOURCE[1]}\")"
    FAILURE_HANDLERS["$file"]="$1"
}

register_usage() {
    local file="$(basename \"${BASH_SOURCE[1]}\")"
    USAGE_DESCRIPTIONS["$file"]="$1"
}

show_usage() {
    local file="$(basename \"${BASH_SOURCE[1]}\")"
    echo "Usage: ${USAGE_DESCRIPTIONS[$file]}"
    exit 1
}

upload_repository() {
    # Upload repository at given location with commit message
    cd "${1}"
    git add -A
    git commit -m "$2"
    git push
}

empty_directory() {
    # Remove directory if exists and create empty one
    rm -rf "${1}"
    mkdir -p "${1}"
}

# For KEY="VALUE" format.
update_config_assign() {
    local KEY="$1"
    local VALUE="$2"
    local FILE="$3"

    if grep -q "^${KEY}=\".*\"" "${FILE}" 2>/dev/null; then
        sed -i "/^${KEY}=\"/c${KEY}=\"${VALUE}\"" "${FILE}"
    else
        echo "${KEY}=\"${VALUE}\"" >> "${FILE}"
    fi
}

# For KEY = VALUE format.
update_config_assign_space() {
    local KEY="$1"
    local VALUE="$2"
    local FILE="$3"

    if grep -q "^${KEY}\s*=" "${FILE}" 2>/dev/null; then
        sed -i "/^${KEY}\s*=/c${KEY} = ${VALUE}" "${FILE}"
    else
        echo "${KEY} = ${VALUE}" >> "${FILE}"
    fi
}

# Adds given line to file only if it doesn't exist yet.
add_line_if_not_exists() {
  local LINE="$1"
  local FILE="$2"
  grep -qxF "${LINE}" "${FILE}" 2>/dev/null || echo "${LINE}" >> "${FILE}"
}

unmask_package() {
    local PACKAGE="$1"
    local KEYWORDS="$2"
    [[ -z "${KEYWORDS}" ]] && KEYWORDS="~${CONF_HOST_ARCH_PORTAGE}" # If keywords not specified, unmask for current host architecture.
    local UNMASK_PATH="${PATH_ETC_PORTAGE_PACKAGE_ACCEPT_KEYWORDS}/${CONF_PROJECT_NAME}"
    add_line_if_not_exists "${PACKAGE} ${KEYWORDS}" "${UNMASK_PATH}"
}

use_set_package() {
    local PACKAGE="$1"
    local USE_FLAGS="$2"
    local USE_FLAGS_PATH="${PATH_ETC_PORTAGE_PACKAGE_USE}/${CONF_PROJECT_NAME}"
    add_line_if_not_exists "${PACKAGE} ${USE_FLAGS}" "${USE_FLAGS_PATH}"
}

set_if() {
    local VAR_NAME=$1
    local CONDITION=$2
    local RET_TRUE=$3
    local RET_FALSE=$4

    if eval "[[ $CONDITION ]]"; then
        eval "$VAR_NAME=\"$RET_TRUE\""
    else
        eval "$VAR_NAME=\"$RET_FALSE\""
    fi
}

# Restores modification date of repository files, based on last commit date (if file was not modified locally).
update_git_files_timestamps() {
    local repo_path=$1
    cd "$repo_path"

    modified_files=$(git status --porcelain | grep '^[ MADRCU]' | awk '{print $2}')

    for file in $(git ls-files); do
        if echo "$modified_files" | grep -Fxq "$file"; then
            continue
        fi

	mtime=$(git log -1 --format="%at" -- "$file")
        if [ -n "$mtime" ]; then
            touch -d @$mtime "$file"
        fi
    done

    git submodule foreach --recursive "$(declare -f update_git_files_timestamps); update_git_files_timestamps \$toplevel/\$sm_path"
}
