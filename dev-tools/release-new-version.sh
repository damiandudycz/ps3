declare -a SETUP_SCRIPTS=(
    releae/release-prepare.sh
    releae/release-build.sh
    releae/release-upload.sh
    binhost/binhost-upload.sh
    releae/release-tag.sh
)

for SCRIPT in "${SETUP_SCRIPTS[@]}"; do
    DIR=$(dirname "environment/${SCRIPT}")
    (cd "${DIR}" && "./${SCRIPT}") || { echo "Script ${SCRIPT} failed. Exiting."; exit 1; }
done

echo "New release was successfully released!"
