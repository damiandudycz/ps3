declare -a SETUP_SCRIPTS=(
    setup-dependencies.sh
    setup-submodules.sh
    setup-catalyst.sh
    setup-qemu.sh
    setup-releng.sh
    setup-crossdev.sh
)

GIT_USER="Damian Dudycz"
GIT_EMAIL="damiandudycz@yahoo.com"

# Setup git user details
git config --global user.name "${GIT_USER}"
git config --global user.email "${GIT_EMAIL}"

# Run setup scripts
for SCRIPT in "${SETUP_SCRIPTS[@]}"; do
    DIR=$(dirname "environment/${SCRIPT}")
    (cd "${DIR}" && "./${SCRIPT}") || { echo "Script ${SCRIPT} failed. Exiting."; exit 1; }
done

mkdir -p ../local
touch ../local/env_ready
