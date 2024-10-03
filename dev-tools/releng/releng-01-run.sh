#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_RELENG}" || failure "Failed to load env ${PATH_EXTRA_ENV_RELENG}"

[[ ! -d "${PATH_WORK_RELENG}" ]] && failure "No work files at ${PATH_WORK_RELENG}"

cd ${PATH_WORK_RELENG}
${PATH_RELENG_CATALYST_AUTO} -X -v -j ${CONF_CATALYST_JOBS} -c ${RL_PATH_CATALYST_AUTO_CONF_DST}

function flabel {
        F="$(basename $1)"
        echo "${F%%.*}"
}

function file_date {
        L="$(flabel $1)"
        echo "${L##*-}"
}

function process_target {
        declare -A STAGES
        PREFIX="$1"
	EXT="$2"
        FILES=$(find "${PATH_CATALYST_BUILDS_DEFAULT}" -name "${PREFIX}*${EXT}*")
        for FPATH in ${FILES[@]}; do
                FNAME=$(basename ${FPATH})
                DATE=$(file_date ${FPATH})
		DIR="${PATH_RELEASES_PS3_GENTOO_DEFAULT}/${DATE}"
		if [[ ! -d "${DIR}" ]]; then
			mkdir -p "${DIR}"
		fi
		echo " + ${FNAME}"
		mv "${FPATH}" "$DIR"/
        done
}

echo "Saving generated files to repository:"
for stage in "${RL_PUBLIC_STAGES[@]}"; do
	process_target "stage${stage}-cell" "tar.xz"
done
for iso in "${RL_PUBLIC_ISOS[@]}"; do
	process_target "install-cell-$iso" "iso"
done
