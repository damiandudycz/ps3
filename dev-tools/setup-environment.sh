declare -a SETUP_SCRIPTS=(
    setup-submodules.sh
    setup-catalyst.sh
    setup-qemu.sh
    setup-releng.sh
)

for SCRIPT in "${SETUP_SCRIPTS[@]}"; do
    DIR=$(dirname "environment/${SCRIPT}")
    (cd "${DIR}" && "./${SCRIPT}") || { echo "Script ${SCRIPT} failed. Exiting."; exit 1; }
done

mkdir -p ../local
touch ../local/env_ready
