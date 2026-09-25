#!/usr/bin/env bash

# ==============================================================================
# Red Hat Enterprise Linux 9 Development Environment Setup
#
# Target:
#   - Red Hat Enterprise Linux 9.x ONLY
#
# Installs:
#   - Git
#   - Node.js 20 + npm
#   - Java 21 OpenJDK
#   - Python 3 + pip + development tools
#   - Gradle
#   - PostgreSQL
#   - Visual Studio Code
#   - Docker Engine + Docker Compose
#
# Usage:
#   chmod +x setup_dev_rhel9.sh
#   ./setup_dev_rhel9.sh
#
# Requirements:
#   - RHEL 9.x
#   - Active RHEL subscription
#   - sudo privileges
#   - Internet access
#   - Run as a normal user, NOT root
#
# ==============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

# ==============================================================================
# Configuration
# ==============================================================================

readonly SCRIPT_NAME="$(basename "$0")"

readonly REQUIRED_RHEL_MAJOR="9"
readonly NODE_MAJOR="${NODE_MAJOR:-20}"

# Gradle version used when the RHEL repositories do not provide Gradle.
readonly GRADLE_VERSION="${GRADLE_VERSION:-8.10.2}"

readonly DOCKER_REPO_URL="https://download.docker.com/linux/centos/docker-ce.repo"
readonly NODE_REPO_URL="https://rpm.nodesource.com/setup_${NODE_MAJOR}.x"
readonly VSCODE_REPO_URL="https://packages.microsoft.com/yumrepos/vscode"

TEMP_FILES=()
SUDO_KEEPALIVE_PID=""
CURRENT_USER=""
POSTGRES_SERVICE=""

# ==============================================================================
# Colors
# ==============================================================================

if [[ -t 1 ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly NC='\033[0m'
else
    readonly RED=''
    readonly GREEN=''
    readonly YELLOW=''
    readonly BLUE=''
    readonly NC=''
fi

# ==============================================================================
# Logging
# ==============================================================================

log() {
    printf '%b[INFO]%b %s\n' "$BLUE" "$NC" "$*"
}

success() {
    printf '%b[ OK ]%b %s\n' "$GREEN" "$NC" "$*"
}

warning() {
    printf '%b[WARN]%b %s\n' "$YELLOW" "$NC" "$*" >&2
}

error() {
    printf '%b[ERROR]%b %s\n' "$RED" "$NC" "$*" >&2
}

die() {
    error "$*"
    exit 1
}

# ==============================================================================
# Error handling
# ==============================================================================

error_handler() {
    local exit_code=$?
    local line_number="${1:-unknown}"
    local command="${2:-unknown}"

    echo
    error "============================================================"
    error "Installation failed"
    error "============================================================"
    error "Script:     ${SCRIPT_NAME}"
    error "Line:       ${line_number}"
    error "Exit code:  ${exit_code}"
    error "Command:    ${command}"
    echo

    exit "$exit_code"
}

trap 'error_handler "$LINENO" "$BASH_COMMAND"' ERR

# ==============================================================================
# Cleanup
# ==============================================================================

cleanup() {
    local file

    for file in "${TEMP_FILES[@]:-}"; do
        if [[ -n "$file" && -e "$file" ]]; then
            rm -f -- "$file" || true
        fi
    done

    if [[ -n "${SUDO_KEEPALIVE_PID:-}" ]]; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    fi
}

trap cleanup EXIT

# ==============================================================================
# Utility functions
# ==============================================================================

require_command() {
    local command_name="$1"

    if ! command -v "$command_name" >/dev/null 2>&1; then
        die "Required command not found: ${command_name}"
    fi
}

package_installed() {
    local package="$1"

    rpm -q "$package" >/dev/null 2>&1
}

package_available() {
    local package="$1"

    sudo dnf list --available "$package" >/dev/null 2>&1 ||
        sudo dnf list --installed "$package" >/dev/null 2>&1
}

require_package_available() {
    local package="$1"

    if ! package_available "$package"; then
        die "Required package '${package}' is not available."
    fi
}

require_service_running() {
    local service="$1"

    if ! sudo systemctl is-active --quiet "$service"; then
        die "Service '${service}' is not running."
    fi
}

# ==============================================================================
# Header
# ==============================================================================

echo
echo "============================================================"
echo " RHEL 9 Development Environment Setup"
echo "============================================================"
echo

# ==============================================================================
# 1. Initial validation
# ==============================================================================

log "Performing initial system validation..."

# Do not run directly as root.
if [[ "${EUID}" -eq 0 ]]; then
    die "Do not run this script as root. Run it as a normal user with sudo privileges."
fi

# Required commands.
for command in \
    sudo \
    dnf \
    rpm \
    curl \
    wget \
    gpg \
    systemctl \
    grep \
    awk \
    sed \
    tar \
    unzip \
    mktemp; do

    require_command "$command"
done

# ------------------------------------------------------------------------------
# sudo validation
# ------------------------------------------------------------------------------

log "Checking sudo access..."

if ! sudo -v; then
    die "Unable to obtain sudo privileges."
fi

CURRENT_USER="${SUDO_USER:-${USER:-}}"

if [[ -z "$CURRENT_USER" || "$CURRENT_USER" == "root" ]]; then
    die "Unable to determine the non-root user."
fi

if ! id "$CURRENT_USER" >/dev/null 2>&1; then
    die "User '${CURRENT_USER}' does not exist."
fi

success "Running as user: ${CURRENT_USER}"

# ==============================================================================
# 2. RHEL 9 validation
# ==============================================================================

log "Validating operating system..."

if [[ ! -r /etc/os-release ]]; then
    die "/etc/os-release does not exist."
fi

# shellcheck disable=SC1091
source /etc/os-release

if [[ "${ID:-}" != "rhel" ]]; then
    die "This script supports RHEL 9 only. Detected ID='${ID:-unknown}'."
fi

RHEL_MAJOR="${VERSION_ID%%.*}"

if [[ "$RHEL_MAJOR" != "$REQUIRED_RHEL_MAJOR" ]]; then
    die "This script requires RHEL ${REQUIRED_RHEL_MAJOR}. Detected RHEL ${VERSION_ID}."
fi

success "Confirmed Red Hat Enterprise Linux ${VERSION_ID}."

# ==============================================================================
# 3. Architecture validation
# ==============================================================================

ARCH="$(uname -m)"

case "$ARCH" in
    x86_64|aarch64)
        success "Supported architecture detected: ${ARCH}"
        ;;

    *)
        die "Unsupported architecture: ${ARCH}. Supported architectures: x86_64 and aarch64."
        ;;
esac

# ==============================================================================
# 4. Subscription validation
# ==============================================================================

log "Checking RHEL subscription..."

if ! command -v subscription-manager >/dev/null 2>&1; then
    die "subscription-manager is not installed."
fi

if ! sudo subscription-manager identity >/dev/null 2>&1; then
    die "This RHEL system is not registered with Red Hat."
fi

if ! sudo subscription-manager status >/dev/null 2>&1; then
    warning "Unable to confirm subscription status."
fi

success "RHEL registration detected."

# ==============================================================================
# 5. Enable required RHEL repositories
# ==============================================================================

log "Checking enabled RHEL repositories..."

# Determine architecture used by RHEL repository names.
RHEL_ARCH="$(uname -m)"

# BaseOS and AppStream should be enabled on every normal RHEL 9 system.
if ! sudo dnf repolist enabled |
    grep -Eq '^rhel-9-for-[^ ]+-baseos-rpms|rhel-9-for-[^ ]+-appstream-rpms'; then

    warning "Expected RHEL 9 repositories were not detected."
    warning "Attempting to refresh subscription repositories..."
fi

# CodeReady Builder is useful for development dependencies.
CRB_REPO="codeready-builder-for-rhel-9-${RHEL_ARCH}-rpms"

if sudo subscription-manager repos --list-enabled |
    grep -q "$CRB_REPO"; then

    success "CodeReady Builder repository is enabled."

else
    log "Enabling CodeReady Builder repository..."

    sudo subscription-manager repos \
        --enable="$CRB_REPO" \
        >/dev/null 2>&1 || \
        warning "CodeReady Builder could not be enabled automatically."
fi

# Refresh metadata.
sudo dnf clean expire-cache
sudo dnf makecache

# ==============================================================================
# 6. Validate DNF
# ==============================================================================

log "Validating DNF package state..."

if ! sudo dnf check; then
    die "DNF package state is inconsistent."
fi

success "DNF package state is healthy."

# ==============================================================================
# 7. Network validation
# ==============================================================================

log "Checking network connectivity..."

NETWORK_URLS=(
    "https://access.redhat.com"
    "https://rpm.nodesource.com"
    "https://packages.microsoft.com"
    "https://download.docker.com"
    "https://services.gradle.org"
)

NETWORK_OK=false

for url in "${NETWORK_URLS[@]}"; do
    if curl -fsSIL \
        --connect-timeout 5 \
        --max-time 15 \
        "$url" >/dev/null 2>&1; then

        NETWORK_OK=true
        break
    fi
done

if [[ "$NETWORK_OK" != true ]]; then
    die "Unable to connect to required HTTPS repositories."
fi

success "Network connectivity verified."

# ==============================================================================
# 8. Keep sudo alive
# ==============================================================================

log "Keeping sudo credentials active..."

(
    while true; do
        sleep 45
        sudo -n true || exit 0
    done
) &

SUDO_KEEPALIVE_PID=$!

# ==============================================================================
# 9. Update RHEL
# ==============================================================================

log "Updating RHEL packages..."

sudo dnf upgrade -y

success "RHEL packages updated."

# ==============================================================================
# 10. Base development packages
# ==============================================================================

log "Installing base development packages..."

BASE_PACKAGES=(
    git
    curl
    wget
    ca-certificates
    gnupg2
    unzip
    zip
    tar
    gzip
    make
    gcc
    gcc-c++
    openssl-devel
    libffi-devel
    pkgconf-pkg-config
)

sudo dnf install -y "${BASE_PACKAGES[@]}"

success "Base development packages installed."

# ==============================================================================
# 11. Node.js 20
# ==============================================================================

echo
log "Configuring NodeSource for Node.js ${NODE_MAJOR}..."

# NodeSource installer creates the required RPM repository.
curl -fsSL \
    --connect-timeout 10 \
    --max-time 120 \
    "$NODE_REPO_URL" |
    sudo bash -

# Confirm NodeSource repository exists.
if ! compgen -G "/etc/yum.repos.d/nodesource*.repo" >/dev/null; then
    die "NodeSource repository was not created."
fi

sudo dnf clean expire-cache
sudo dnf makecache

log "Installing Node.js ${NODE_MAJOR}..."

require_package_available nodejs

sudo dnf install -y nodejs

require_command node
require_command npm

NODE_VERSION="$(node --version | sed 's/^v//')"
NODE_MAJOR_INSTALLED="${NODE_VERSION%%.*}"

if [[ "$NODE_MAJOR_INSTALLED" != "$NODE_MAJOR" ]]; then
    die "Expected Node.js ${NODE_MAJOR}.x but installed ${NODE_VERSION}."
fi

success "Node.js ${NODE_VERSION} installed."
success "npm $(npm --version) installed."

# ==============================================================================
# 12. Java 21
# ==============================================================================

echo
log "Installing OpenJDK 21..."

require_package_available java-21-openjdk
require_package_available java-21-openjdk-devel

sudo dnf install -y \
    java-21-openjdk \
    java-21-openjdk-devel

require_command java
require_command javac

JAVA_VERSION="$(java -version 2>&1 | head -n 1)"

if [[ "$JAVA_VERSION" != *"21"* ]]; then
    die "Java 21 verification failed. Detected: ${JAVA_VERSION}"
fi

success "Java 21 installed."

# ==============================================================================
# 13. Python 3
# ==============================================================================

echo
log "Installing Python development environment..."

PYTHON_PACKAGES=(
    python3
    python3-pip
    python3-devel
    python3-setuptools
    python3-wheel
)

sudo dnf install -y "${PYTHON_PACKAGES[@]}"

require_command python3

if ! python3 --version >/dev/null 2>&1; then
    die "Python installation could not be verified."
fi

if ! python3 -m pip --version >/dev/null 2>&1; then
    die "pip installation could not be verified."
fi

# Test virtual environment support.
PYTHON_TEST_DIR="$(mktemp -d)"
TEMP_FILES+=("$PYTHON_TEST_DIR")

if ! python3 -m venv "$PYTHON_TEST_DIR/venv" >/dev/null 2>&1; then
    warning "Python venv support is not available."
else
    success "Python virtual environment support verified."
fi

success "Python: $(python3 --version)"
success "pip: $(python3 -m pip --version | awk '{print $1, $2}')"

# ==============================================================================
# 14. Gradle
# ==============================================================================

echo
log "Installing Gradle..."

if package_available gradle; then

    log "Gradle is available through the configured RHEL repositories."

    sudo dnf install -y gradle

else

    warning "Gradle is not available from the configured RHEL repositories."
    warning "Installing Gradle ${GRADLE_VERSION} from the official distribution."

    GRADLE_ARCHIVE="/tmp/gradle-${GRADLE_VERSION}-bin.zip"
    GRADLE_INSTALL_DIR="/opt/gradle"

    TEMP_FILES+=("$GRADLE_ARCHIVE")

    curl -fsSL \
        --connect-timeout 10 \
        --max-time 120 \
        -o "$GRADLE_ARCHIVE" \
        "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"

    if [[ ! -s "$GRADLE_ARCHIVE" ]]; then
        die "Gradle download failed."
    fi

    sudo mkdir -p "$GRADLE_INSTALL_DIR"

    sudo unzip -q -o \
        "$GRADLE_ARCHIVE" \
        -d "$GRADLE_INSTALL_DIR"

    if [[ ! -x "$GRADLE_INSTALL_DIR/gradle-${GRADLE_VERSION}/bin/gradle" ]]; then
        die "Gradle binary was not found after extraction."
    fi

    sudo ln -sfn \
        "$GRADLE_INSTALL_DIR/gradle-${GRADLE_VERSION}" \
        "$GRADLE_INSTALL_DIR/current"

    sudo ln -sfn \
        "$GRADLE_INSTALL_DIR/current/bin/gradle" \
        /usr/local/bin/gradle
fi

require_command gradle

GRADLE_INSTALLED="$(gradle --version |
    awk '/^Gradle / {print $2; exit}')"

if [[ -z "$GRADLE_INSTALLED" ]]; then
    die "Unable to determine installed Gradle version."
fi

success "Gradle ${GRADLE_INSTALLED} installed."

# ==============================================================================
# 15. PostgreSQL
# ==============================================================================

echo
log "Installing PostgreSQL..."

# RHEL 9 AppStream provides PostgreSQL.
require_package_available postgresql
require_package_available postgresql-server
require_package_available postgresql-contrib

sudo dnf install -y \
    postgresql \
    postgresql-server \
    postgresql-contrib

require_command psql

# ------------------------------------------------------------------------------
# Initialize PostgreSQL
# ------------------------------------------------------------------------------

if [[ ! -f /var/lib/pgsql/data/PG_VERSION ]]; then

    log "Initializing PostgreSQL database..."

    if command -v postgresql-setup >/dev/null 2>&1; then
        sudo postgresql-setup --initdb
    else
        die "postgresql-setup was not found."
    fi
fi

if [[ ! -f /var/lib/pgsql/data/PG_VERSION ]]; then
    die "PostgreSQL database initialization failed."
fi

POSTGRES_SERVICE="postgresql"

if ! sudo systemctl list-unit-files |
    grep -q '^postgresql.service'; then

    die "PostgreSQL systemd service was not found."
fi

log "Starting PostgreSQL..."

sudo systemctl enable --now "$POSTGRES_SERVICE"

require_service_running "$POSTGRES_SERVICE"

# Functional database test.
if ! sudo -u postgres psql -tAc "SELECT 1;" 2>/dev/null |
    grep -q '^1$'; then

    die "PostgreSQL did not respond correctly to SELECT 1."
fi

success "PostgreSQL is installed and operational."
success "PostgreSQL client: $(psql --version)"

# ==============================================================================
# 16. Visual Studio Code
# ==============================================================================

echo
log "Configuring Microsoft repository for Visual Studio Code..."

VSCODE_REPO="/etc/yum.repos.d/vscode.repo"

sudo rpm --import \
    https://packages.microsoft.com/keys/microsoft.asc

sudo tee "$VSCODE_REPO" >/dev/null <<EOF
[code]
name=Visual Studio Code
baseurl=${VSCODE_REPO_URL}
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

if [[ ! -s "$VSCODE_REPO" ]]; then
    die "VS Code repository configuration failed."
fi

sudo dnf clean expire-cache
sudo dnf makecache

log "Installing Visual Studio Code..."

require_package_available code

sudo dnf install -y code

require_command code

if ! code --version >/dev/null 2>&1; then
    die "VS Code installation could not be verified."
fi

success "Visual Studio Code $(code --version | head -n 1) installed."

# ==============================================================================
# 17. Docker Engine
# ==============================================================================

echo
log "Removing conflicting container packages..."

sudo dnf remove -y \
    podman-docker \
    docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-engine \
    moby-engine \
    moby-cli \
    containerd \
    runc || true

echo
log "Configuring Docker repository..."

DOCKER_REPO="/etc/yum.repos.d/docker-ce.repo"

sudo curl -fsSL \
    --connect-timeout 10 \
    --max-time 60 \
    -o "$DOCKER_REPO" \
    "$DOCKER_REPO_URL"

if [[ ! -s "$DOCKER_REPO" ]]; then
    die "Docker repository file is empty."
fi

sudo dnf clean expire-cache
sudo dnf makecache

# ------------------------------------------------------------------------------
# Docker packages
# ------------------------------------------------------------------------------

DOCKER_PACKAGES=(
    docker-ce
    docker-ce-cli
    containerd.io
    docker-buildx-plugin
    docker-compose-plugin
)

for package in "${DOCKER_PACKAGES[@]}"; do
    require_package_available "$package"
done

log "Installing Docker Engine..."

sudo dnf install -y "${DOCKER_PACKAGES[@]}"

require_command docker

# ------------------------------------------------------------------------------
# Start Docker
# ------------------------------------------------------------------------------

log "Starting Docker..."

sudo systemctl enable --now docker

require_service_running docker

# Functional Docker test.
if ! sudo docker info >/dev/null 2>&1; then
    die "Docker daemon is running but docker info failed."
fi

if ! sudo docker compose version >/dev/null 2>&1; then
    die "Docker Compose plugin could not be verified."
fi

success "Docker installed: $(docker --version)"
success "Docker Compose installed: $(docker compose version)"

# ==============================================================================
# 18. Docker group
# ==============================================================================

echo
log "Configuring Docker permissions..."

if getent group docker >/dev/null 2>&1; then
    success "Docker group exists."
else
    sudo groupadd docker
    success "Docker group created."
fi

if id -nG "$CURRENT_USER" |
    tr ' ' '\n' |
    grep -qx docker; then

    success "User '${CURRENT_USER}' is already in the docker group."
else
    sudo usermod -aG docker "$CURRENT_USER"
    success "User '${CURRENT_USER}' added to the docker group."
fi

# ==============================================================================
# 19. Final DNF validation
# ==============================================================================

echo
log "Running final DNF validation..."

if ! sudo dnf check; then
    die "DNF package validation failed."
fi

success "DNF package state is healthy."

# ==============================================================================
# 20. Final command verification
# ==============================================================================

echo
echo "============================================================"
echo " Final Installation Verification"
echo "============================================================"
echo

FAILED=0

verify_command() {
    local name="$1"
    local command_name="$2"

    if command -v "$command_name" >/dev/null 2>&1; then
        success "${name}: available"
    else
        error "${name}: NOT FOUND"
        FAILED=1
    fi
}

verify_command "Git" "git"
verify_command "Node.js" "node"
verify_command "npm" "npm"
verify_command "Java" "java"
verify_command "javac" "javac"
verify_command "Python" "python3"
verify_command "pip" "pip3"
verify_command "Gradle" "gradle"
verify_command "PostgreSQL" "psql"
verify_command "Visual Studio Code" "code"
verify_command "Docker" "docker"

echo

# ==============================================================================
# 21. Final service verification
# ==============================================================================

if sudo systemctl is-active --quiet postgresql; then
    success "PostgreSQL service: running"
else
    error "PostgreSQL service: NOT RUNNING"
    FAILED=1
fi

if sudo systemctl is-active --quiet docker; then
    success "Docker service: running"
else
    error "Docker service: NOT RUNNING"
    FAILED=1
fi

echo

if [[ "$FAILED" -ne 0 ]]; then
    die "Final verification failed."
fi

# ==============================================================================
# 22. Display installed versions
# ==============================================================================

echo "============================================================"
echo " Installed Versions"
echo "============================================================"
echo

printf '%-20s %s\n' "OS:" "RHEL ${VERSION_ID}"
printf '%-20s %s\n' "Architecture:" "${ARCH}"
printf '%-20s %s\n' "Git:" "$(git --version)"
printf '%-20s %s\n' "Node.js:" "$(node --version)"
printf '%-20s %s\n' "npm:" "$(npm --version)"
printf '%-20s %s\n' "Java:" "$(java -version 2>&1 | head -n 1)"
printf '%-20s %s\n' "Python:" "$(python3 --version)"
printf '%-20s %s\n' "pip:" "$(python3 -m pip --version)"
printf '%-20s %s\n' "Gradle:" "$(gradle --version | awk '/^Gradle / {print; exit}')"
printf '%-20s %s\n' "PostgreSQL:" "$(psql --version)"
printf '%-20s %s\n' "VS Code:" "$(code --version | head -n 1)"
printf '%-20s %s\n' "Docker:" "$(docker --version)"
printf '%-20s %s\n' "Compose:" "$(docker compose version)"

# ==============================================================================
# 23. Completion
# ==============================================================================

echo
echo "============================================================"
echo -e "${GREEN} RHEL 9 Development Environment Ready${NC}"
echo "============================================================"
echo

warning "Log out and back in before using Docker without sudo."

echo
echo "After logging back in, test Docker:"
echo "  docker run hello-world"

echo
echo "Test PostgreSQL:"
echo "  sudo -u postgres psql"

echo
echo "Create a Python virtual environment:"
echo "  python3 -m venv .venv"

echo
echo "Verify Gradle:"
echo "  gradle --version"

echo
success "All installation and validation checks passed."
