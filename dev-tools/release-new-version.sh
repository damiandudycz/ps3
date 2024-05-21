readonly PATH_START=$(dirname "$(realpath "$0")") || die

declare -a SETUP_SCRIPTS=(
    release-builder/release-prepare.sh
    release-builder/release-build.sh
    release-builder/release-upload.sh
    binhost/binhost-upload.sh
    release-builder/release-tag.sh
)

for SCRIPT in "${SETUP_SCRIPTS[@]}"; do
    DIR=$(dirname "${SCRIPT}")
    SCRIPT_NAME=$(basename ${SCRIPT})
    (cd "${DIR}" && "./${SCRIPT_NAME}") || { echo "Script ${SCRIPT} failed. Exiting."; exit 1; }
    cd "${PATH_START}"
done

echo "New release was successfully released!"
