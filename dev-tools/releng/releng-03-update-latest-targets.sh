#!/bin/bash

source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_RELENG}" || failure "Failed to load env ${PATH_EXTRA_ENV_RELENG}"

cd "${PATH_RELEASES_PS3_GENTOO_DEFAULT}"

function flabel {
	F="$(basename $1)"
	echo "${F%%.*}"
}

function file_date {
	L="$(flabel $1)"
	echo "${L##*-}"
}

function file_target {
	L="$(flabel $1)"
	echo "${L%-*}"
}

function targets_list_latest {
	for key in "${!TARGETS[@]}"; do
		FILE="${TARGETS[$key]}"
		FSIZE=$(stat -c%s "$FILE")
		RPATH="${FILE#./}"
		echo "$RPATH $FSIZE"
	done
}

function process_target {
	PREFIX="$1"
	EXT="$2"
	LINKS_FILENAME="$3"
	declare -A TARGETS
	FILES=$(find . -name "${PREFIX}*.${EXT}")
	for FPATH in ${FILES[@]}; do
		FNAME=$(basename ${FPATH})
		DATE=$(file_date ${FPATH})
		LABEL=$(flabel ${FPATH})
		TARGET=$(file_target ${FPATH})

		if [[ ! -n "${TARGETS[$TARGET]}" ]]; then
			TARGETS[$TARGET]="$FPATH"
		else
			# Compare dates and get the better one
			OLD_DATE=$(file_date "${TARGETS[$TARGET]}")
			NEW_DATE=$(file_date "${FPATH}")
			if [[ ${NEW_DATE} > ${OLD_DATE} ]]; then
				TARGETS[$TARGET]="$FPATH"
			fi
		fi

	done
	echo "$(targets_list_latest | sort)" > "${LINKS_FILENAME}"
	for TARGET in "${TARGETS[@]}"; do
		echo " + $TARGET"
	done
}

echo "Updating latest links:"
for stage in "${RL_PUBLIC_STAGES[@]}"; do
	process_target "stage${stage}-cell" "tar.xz" "latest-stage${stage}.txt"
done
for iso in "${RL_PUBLIC_ISOS[@]}"; do
	process_target "install-cell-${iso}" "iso" "latest-iso-${iso}.txt"
done
