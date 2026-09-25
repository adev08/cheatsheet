#!/usr/bin/env bash

# ==============================================================================
# Debian / Ubuntu Development Environment Setup
#
# Installs:
#   Git
#   Node.js + npm
#   Java 21
#   Python 3 + pip + venv
#   Gradle
#   PostgreSQL
#   Visual Studio Code
#   Docker Engine + Docker Compose
#
# Supported:
#   - Debian
#   - Ubuntu
#   - AMD64 / x86_64
#   - ARM64 / aarch64
#
# Examples:
#
#   Interactive:
#       ./setup_dev_debian.sh
#
#   Non-interactive:
#       ./setup_dev_debian.sh --non-interactive
#
#   Skip Docker:
#       ./setup_dev_debian.sh --skip-docker
#
#   Skip PostgreSQL:
#       ./setup_dev_debian.sh --skip-postgresql
#
#   Use Node.js 22:
#       ./setup_dev_debian.sh --node-major 22
#
#   Custom log:
#       ./setup_dev_debian.sh --log-file /var/log/dev-setup.log
#
#   Show options:
#       ./setup_dev_debian.sh --help
# ==============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="2.0.0"

NODE_MAJOR="${NODE_MAJOR:-20}"

NON_INTERACTIVE=false
SKIP_DOCKER=false
SKIP_POSTGRESQL=false
SKIP_VSCODE=false
SKIP_GRADLE=false
SKIP_PYTHON=false
SKIP_NODE=false
SKIP_JAVA=false
SKIP_GIT=false

LOG_FILE=""

# ------------------------------------------------------------------------------
# Colors
# ------------------------------------------------------------------------------

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    NC=''
fi

# ------------------------------------------------------------------------------
# State
# ------------------------------------------------------------------------------

OS_ID=""
OS_NAME=""
OS_VERSION=""
OS_CODENAME=""
ARCH=""
DOCKER_ARCH=""
DOCKER_OS=""

CURRENT_USER=""
SUDO_KEEPALIVE_PID=""

declare -a TEMP_FILES=()
declare -a INSTALLED_COMPONENTS=()
declare -a FAILED_COMPONENTS=()
declare -a SKIPPED_COMPONENTS=()

# ------------------------------------------------------------------------------
# Logging
# ------------------------------------------------------------------------------

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

section() {
    echo
    printf '%b============================================================%b\n' "$CYAN" "$NC"
    printf '%b%s%b\n' "$CYAN" "$*" "$NC"
    printf '%b============================================================%b\n' "$CYAN" "$NC"
    echo
}

# ------------------------------------------------------------------------------
# Error handling
# ------------------------------------------------------------------------------

error_handler() {
    local exit_code=$?
    local line_number="${1:-unknown}"
    local command="${2:-unknown}"

    echo
    error "Installation failed."
    error "Script:     ${SCRIPT_NAME}"
    error "Line:       ${line_number}"
    error "Exit code:  ${exit_code}"
    error "Command:    ${command}"

    echo
    error "Check the log file for complete details:"
    error "  ${LOG_FILE:-not configured}"

    exit "$exit_code"
}

trap 'error_handler "$LINENO" "$BASH_COMMAND"' ERR

# ------------------------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------------------------

cleanup() {
    local file

    for file in "${TEMP_FILES[@]:-}"; do
        if [[ -n "$file" && -e "$file" ]]; then
            rm -f -- "$file" 2>/dev/null || true
        fi
    done

    if [[ -n "${SUDO_KEEPALIVE_PID:-}" ]]; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    fi
}

trap cleanup EXIT

# ------------------------------------------------------------------------------
# Command helpers
# ------------------------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

require_command() {
    local command_name="$1"

    if ! command_exists "$command_name"; then
        die "Required command not found: ${command_name}"
    fi
}

die() {
    error "$*"
    exit 1
}

# ------------------------------------------------------------------------------
# User interaction
# ------------------------------------------------------------------------------

ask_yes_no() {
    local prompt="$1"
    local default="${2:-Y}"
    local answer

    if [[ "$NON_INTERACTIVE" == true ]]; then
        [[ "$default" =~ ^[Yy]$ ]]
        return
    fi

    if [[ "$default" =~ ^[Yy]$ ]]; then
        prompt="${prompt} [Y/n]"
    else
        prompt="${prompt} [y/N]"
    fi

    while true; do
        read -r -p "$prompt " answer || true

        if [[ -z "$answer" ]]; then
            [[ "$default" =~ ^[Yy]$ ]]
            return
        fi

        case "$answer" in
            [Yy]|[Yy][Ee][Ss])
                return 0
                ;;

            [Nn]|[Nn][Oo])
                return 1
                ;;

            *)
                echo "Please answer yes or no."
                ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# Package helpers
# ------------------------------------------------------------------------------

package_installed() {
    local package="$1"

    dpkg-query \
        -W \
        -f='${Status}' \
        "$package" 2>/dev/null |
        grep -q "install ok installed"
}

apt_package_available() {
    local package="$1"

    apt-cache show "$package" >/dev/null 2>&1
}

install_packages() {
    sudo DEBIAN_FRONTEND=noninteractive \
        apt-get install -y "$@"
}

# ------------------------------------------------------------------------------
# Version helpers
# ------------------------------------------------------------------------------

get_major_version() {
    local version="$1"

    echo "$version" | sed -E 's/[^0-9]*([0-9]+).*/\1/'
}

# ------------------------------------------------------------------------------
# Service helpers
# ------------------------------------------------------------------------------

service_running() {
    local service="$1"

    sudo systemctl is-active --quiet "$service"
}

ensure_service_running() {
    local service="$1"

    sudo systemctl enable --now "$service"

    if ! service_running "$service"; then
        die "Service '${service}' is not running."
    fi
}

# ------------------------------------------------------------------------------
# Parse command-line arguments
# ------------------------------------------------------------------------------

show_help() {
    cat <<EOF
${SCRIPT_NAME} ${SCRIPT_VERSION}

Debian/Ubuntu development environment setup.

Usage:
  ${SCRIPT_NAME} [OPTIONS]

Options:

  --non-interactive
      Run without prompts. Uses safe default choices.

  --node-major VERSION
      Node.js major version.
      Default: ${NODE_MAJOR}

  --skip-git
      Skip Git installation.

  --skip-node
      Skip Node.js installation.

  --skip-java
      Skip Java installation.

  --skip-python
      Skip Python installation.

  --skip-gradle
      Skip Gradle installation.

  --skip-postgresql
      Skip PostgreSQL installation.

  --skip-vscode
      Skip Visual Studio Code installation.

  --skip-docker
      Skip Docker installation.

  --log-file PATH
      Write installation log to PATH.

  --help
      Show this help message.

Examples:

  ${SCRIPT_NAME}

  ${SCRIPT_NAME} --non-interactive

  ${SCRIPT_NAME} --node-major 22

  ${SCRIPT_NAME} --skip-docker --skip-vscode

  ${SCRIPT_NAME} --log-file /tmp/dev-setup.log
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in

        --non-interactive)
            NON_INTERACTIVE=true
            shift
            ;;

        --node-major)
            [[ $# -ge 2 ]] || die "--node-major requires a value."

            NODE_MAJOR="$2"

            if ! [[ "$NODE_MAJOR" =~ ^[0-9]+$ ]]; then
                die "Invalid Node.js major version: ${NODE_MAJOR}"
            fi

            shift 2
            ;;

        --skip-git)
            SKIP_GIT=true
            shift
            ;;

        --skip-node)
            SKIP_NODE=true
            shift
            ;;

        --skip-java)
            SKIP_JAVA=true
            shift
            ;;

        --skip-python)
            SKIP_PYTHON=true
            shift
            ;;

        --skip-gradle)
            SKIP_GRADLE=true
            shift
            ;;

        --skip-postgresql)
            SKIP_POSTGRESQL=true
            shift
            ;;

        --skip-vscode)
            SKIP_VSCODE=true
            shift
            ;;

        --skip-docker)
            SKIP_DOCKER=true
            shift
            ;;

        --log-file)
            [[ $# -ge 2 ]] || die "--log-file requires a path."

            LOG_FILE="$2"
            shift 2
            ;;

        --help|-h)
            show_help
            exit 0
            ;;

        *)
            die "Unknown option: $1. Use --help for usage."
            ;;
    esac
done

# ------------------------------------------------------------------------------
# Log configuration
# ------------------------------------------------------------------------------

if [[ -z "$LOG_FILE" ]]; then
    LOG_FILE="${HOME}/setup_dev_debian_$(date '+%Y%m%d_%H%M%S').log"
fi

LOG_DIR="$(dirname "$LOG_FILE")"

mkdir -p "$LOG_DIR"

touch "$LOG_FILE" ||
    die "Unable to create log file: ${LOG_FILE}"

# Send stdout/stderr to both terminal and log.
exec > >(tee -a "$LOG_FILE") 2>&1

# ------------------------------------------------------------------------------
# Banner
# ------------------------------------------------------------------------------

section "Debian / Ubuntu Development Environment Setup"

log "Script version: ${SCRIPT_VERSION}"
log "Log file: ${LOG_FILE}"

# ------------------------------------------------------------------------------
# Must run as normal user
# ------------------------------------------------------------------------------

if [[ "${EUID}" -eq 0 ]]; then
    die "Do not run this script as root. Run it as a normal user with sudo privileges."
fi

CURRENT_USER="${SUDO_USER:-${USER:-}}"

if [[ -z "$CURRENT_USER" || "$CURRENT_USER" == "root" ]]; then
    die "Unable to determine the non-root user running this script."
fi

# ------------------------------------------------------------------------------
# Bootstrap required commands
# ------------------------------------------------------------------------------

section "Pre-flight Validation"

# sudo is the only prerequisite we absolutely need initially.
if ! command_exists sudo; then
    die "sudo is not installed. Install sudo first, then rerun this script."
fi

log "Checking sudo privileges..."

sudo -v ||
    die "Unable to obtain sudo privileges."

# apt-get should exist on Debian/Ubuntu.
require_command apt-get
require_command dpkg

# ------------------------------------------------------------------------------
# Detect operating system
# ------------------------------------------------------------------------------

if [[ ! -r /etc/os-release ]]; then
    die "/etc/os-release is missing."
fi

# shellcheck disable=SC1091
source /etc/os-release

OS_ID="${ID:-}"
OS_NAME="${NAME:-unknown}"
OS_VERSION="${VERSION_ID:-unknown}"
OS_CODENAME="${VERSION_CODENAME:-}"

case "$OS_ID" in

    debian)
        DOCKER_OS="debian"
        ;;

    ubuntu)
        DOCKER_OS="ubuntu"
        ;;

    *)
        die "Unsupported operating system: ${OS_NAME}. Only Debian and Ubuntu are supported."
        ;;
esac

if [[ -z "$OS_CODENAME" ]]; then
    die "Could not determine OS codename."
fi

success "Operating system: ${OS_NAME} ${OS_VERSION} (${OS_CODENAME})"

# ------------------------------------------------------------------------------
# Architecture detection
# ------------------------------------------------------------------------------

ARCH="$(dpkg --print-architecture)"

case "$ARCH" in

    amd64)
        DOCKER_ARCH="amd64"
        ;;

    arm64)
        DOCKER_ARCH="arm64"
        ;;

    armhf)
        DOCKER_ARCH="armhf"
        warning "ARMHF is supported for some packages, but ARM64 is recommended for modern development VMs."
        ;;

    *)
        die "Unsupported architecture: ${ARCH}. Supported: AMD64 and ARM64."
        ;;
esac

success "Architecture: ${ARCH}"

# ------------------------------------------------------------------------------
# CPU architecture information
# ------------------------------------------------------------------------------

MACHINE_ARCH="$(uname -m)"

log "Kernel architecture: ${MACHINE_ARCH}"

# ------------------------------------------------------------------------------
# Check internet access
# ------------------------------------------------------------------------------

require_command curl

log "Checking HTTPS connectivity..."

NETWORK_TEST_PASSED=false

for url in \
    "https://deb.debian.org" \
    "https://archive.ubuntu.com" \
    "https://packages.microsoft.com" \
    "https://download.docker.com" \
    "https://deb.nodesource.com"; do

    if curl \
        --fail \
        --silent \
        --show-error \
        --head \
        --connect-timeout 5 \
        --max-time 15 \
        "$url" >/dev/null 2>&1; then

        NETWORK_TEST_PASSED=true
        break
    fi
done

if [[ "$NETWORK_TEST_PASSED" != true ]]; then
    die "Unable to reach required HTTPS repositories."
fi

success "Network connectivity verified."

# ------------------------------------------------------------------------------
# Keep sudo alive
# ------------------------------------------------------------------------------

(
    while true; do
        sleep 45

        if ! sudo -n true; then
            exit 0
        fi
    done
) &

SUDO_KEEPALIVE_PID=$!

# ------------------------------------------------------------------------------
# Validate APT
# ------------------------------------------------------------------------------

log "Checking APT package state..."

if ! sudo apt-get check; then
    die "APT package state is inconsistent. Repair APT before running this script."
fi

success "APT package state is healthy."

# ------------------------------------------------------------------------------
# Upgrade system
# ------------------------------------------------------------------------------

section "System Packages"

log "Updating package indexes..."

sudo apt-get update

log "Applying available package upgrades..."

sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# ------------------------------------------------------------------------------
# Base packages
# ------------------------------------------------------------------------------

log "Installing base utilities..."

install_packages \
    ca-certificates \
    curl \
    wget \
    gnupg \
    lsb-release \
    apt-transport-https \
    software-properties-common \
    unzip \
    zip \
    build-essential \
    file \
    jq

success "Base utilities installed."

# ------------------------------------------------------------------------------
# Git
# ------------------------------------------------------------------------------

if [[ "$SKIP_GIT" == true ]]; then
    SKIPPED_COMPONENTS+=("Git")
else
    section "Git"

    if command_exists git; then
        success "Git is already installed: $(git --version)"
    else
        install_packages git
        success "Git installed: $(git --version)"
    fi

    if git --version >/dev/null 2>&1; then
        INSTALLED_COMPONENTS+=("Git")
    else
        FAILED_COMPONENTS+=("Git")
    fi
fi

# ------------------------------------------------------------------------------
# Node.js
# ------------------------------------------------------------------------------

if [[ "$SKIP_NODE" == true ]]; then
    SKIPPED_COMPONENTS+=("Node.js")
else
    section "Node.js ${NODE_MAJOR}"

    NODE_KEY="/etc/apt/keyrings/nodesource.gpg"
    NODE_LIST="/etc/apt/sources.list.d/nodesource.list"

    sudo install -d -m 0755 /etc/apt/keyrings

    NODE_KEY_TMP="$(mktemp)"
    TEMP_FILES+=("$NODE_KEY_TMP")

    log "Downloading NodeSource signing key..."

    curl \
        --fail \
        --silent \
        --show-error \
        --location \
        --connect-timeout 10 \
        --max-time 60 \
        https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key |
        gpg --dearmor > "$NODE_KEY_TMP"

    [[ -s "$NODE_KEY_TMP" ]] ||
        die "NodeSource signing key is empty."

    sudo install -m 0644 "$NODE_KEY_TMP" "$NODE_KEY"

    printf '%s\n' \
        "deb [arch=${ARCH} signed-by=${NODE_KEY}] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" |
        sudo tee "$NODE_LIST" >/dev/null

    sudo apt-get update

    install_packages nodejs

    require_command node
    require_command npm

    NODE_VERSION="$(node --version | sed 's/^v//')"
    NODE_INSTALLED_MAJOR="${NODE_VERSION%%.*}"

    if [[ "$NODE_INSTALLED_MAJOR" != "$NODE_MAJOR" ]]; then
        die "Node.js ${NODE_MAJOR} was requested, but ${NODE_VERSION} was installed."
    fi

    # Actual npm execution test.
    npm --version >/dev/null

    success "Node.js ${NODE_VERSION}"
    success "npm $(npm --version)"

    INSTALLED_COMPONENTS+=("Node.js")
fi

# ------------------------------------------------------------------------------
# Java
# ------------------------------------------------------------------------------

if [[ "$SKIP_JAVA" == true ]]; then
    SKIPPED_COMPONENTS+=("Java")
else
    section "Java 21"

    if ! apt_package_available openjdk-21-jdk; then
        die "openjdk-21-jdk is not available for ${OS_NAME} ${OS_VERSION}."
    fi

    install_packages openjdk-21-jdk

    require_command java
    require_command javac

    JAVA_VERSION="$(java -version 2>&1 | head -n 1)"

    if [[ "$JAVA_VERSION" != *"21"* ]]; then
        die "Java 21 verification failed: ${JAVA_VERSION}"
    fi

    # Compile and run a tiny Java program.
    JAVA_TEST_DIR="$(mktemp -d)"
    TEMP_FILES+=("$JAVA_TEST_DIR")

    cat > "${JAVA_TEST_DIR}/Test.java" <<'EOF'
public class Test {
    public static void main(String[] args) {
        System.out.println("JAVA_TEST_OK");
    }
}
EOF

    javac "${JAVA_TEST_DIR}/Test.java"

    JAVA_TEST_OUTPUT="$(
        java \
            -cp "$JAVA_TEST_DIR" \
            Test
    )"

    [[ "$JAVA_TEST_OUTPUT" == "JAVA_TEST_OK" ]] ||
        die "Java compile/runtime verification failed."

    success "Java 21 installation and compilation test passed."

    INSTALLED_COMPONENTS+=("Java")
fi

# ------------------------------------------------------------------------------
# Python
# ------------------------------------------------------------------------------

if [[ "$SKIP_PYTHON" == true ]]; then
    SKIPPED_COMPONENTS+=("Python")
else
    section "Python"

    install_packages \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        python3-setuptools \
        python3-wheel

    require_command python3

    PYTHON_VERSION="$(python3 --version)"

    python3 -c 'import sys; assert sys.version_info.major == 3'

    python3 -m pip --version >/dev/null

    PYTHON_TEST_DIR="$(mktemp -d)"
    TEMP_FILES+=("$PYTHON_TEST_DIR")

    python3 -m venv "${PYTHON_TEST_DIR}/venv"

    "${PYTHON_TEST_DIR}/venv/bin/python" \
        -c 'print("PYTHON_TEST_OK")' |
        grep -qx "PYTHON_TEST_OK"

    success "${PYTHON_VERSION}"
    success "pip and virtual-environment test passed."

    INSTALLED_COMPONENTS+=("Python")
fi

# ------------------------------------------------------------------------------
# Gradle
# ------------------------------------------------------------------------------

if [[ "$SKIP_GRADLE" == true ]]; then
    SKIPPED_COMPONENTS+=("Gradle")
else
    section "Gradle"

    if ! apt_package_available gradle; then
        die "Gradle is unavailable in the configured repositories."
    fi

    install_packages gradle

    require_command gradle

    GRADLE_VERSION="$(
        gradle --version |
        awk '/^Gradle / {print $2; exit}'
    )"

    [[ -n "$GRADLE_VERSION" ]] ||
        die "Could not determine Gradle version."

    # Functional Gradle test.
    GRADLE_TEST_DIR="$(mktemp -d)"
    TEMP_FILES+=("$GRADLE_TEST_DIR")

    cat > "${GRADLE_TEST_DIR}/settings.gradle" <<'EOF'
rootProject.name = 'setup-verification'
EOF

    cat > "${GRADLE_TEST_DIR}/build.gradle" <<'EOF'
tasks.register("verifySetup") {
    doLast {
        println("GRADLE_TEST_OK")
    }
}
EOF

    (
        cd "$GRADLE_TEST_DIR"
        gradle --offline verifySetup
    ) |
        grep -qx "GRADLE_TEST_OK"

    success "Gradle ${GRADLE_VERSION}"
    success "Gradle functional test passed."

    INSTALLED_COMPONENTS+=("Gradle")
fi

# ------------------------------------------------------------------------------
# PostgreSQL
# ------------------------------------------------------------------------------

if [[ "$SKIP_POSTGRESQL" == true ]]; then
    SKIPPED_COMPONENTS+=("PostgreSQL")
else
    section "PostgreSQL"

    install_packages \
        postgresql \
        postgresql-contrib \
        postgresql-client

    require_command psql

    ensure_service_running postgresql

    if ! sudo -u postgres psql \
        -v ON_ERROR_STOP=1 \
        -tAc "SELECT 1;" |
        grep -qx "1"; then

        die "PostgreSQL functional test failed."
    fi

    POSTGRES_VERSION="$(psql --version)"

    success "$POSTGRES_VERSION"
    success "PostgreSQL service and SQL query test passed."

    INSTALLED_COMPONENTS+=("PostgreSQL")
fi

# ------------------------------------------------------------------------------
# Visual Studio Code
# ------------------------------------------------------------------------------

if [[ "$SKIP_VSCODE" == true ]]; then
    SKIPPED_COMPONENTS+=("Visual Studio Code")
else
    section "Visual Studio Code"

    VSCODE_KEY="/etc/apt/keyrings/packages.microsoft.gpg"
    VSCODE_LIST="/etc/apt/sources.list.d/vscode.list"

    VSCODE_KEY_TMP="$(mktemp)"
    TEMP_FILES+=("$VSCODE_KEY_TMP")

    log "Downloading Microsoft signing key..."

    curl \
        --fail \
        --silent \
        --show-error \
        --location \
        --connect-timeout 10 \
        --max-time 60 \
        https://packages.microsoft.com/keys/microsoft.asc |
        gpg --dearmor > "$VSCODE_KEY_TMP"

    [[ -s "$VSCODE_KEY_TMP" ]] ||
        die "Microsoft signing key is empty."

    sudo install -m 0644 "$VSCODE_KEY_TMP" "$VSCODE_KEY"

    printf '%s\n' \
        "deb [arch=${ARCH} signed-by=${VSCODE_KEY}] https://packages.microsoft.com/repos/code stable main" |
        sudo tee "$VSCODE_LIST" >/dev/null

    sudo apt-get update

    install_packages code

    require_command code

    VSCODE_VERSION="$(code --version | head -n 1)"

    [[ -n "$VSCODE_VERSION" ]] ||
        die "Visual Studio Code verification failed."

    success "Visual Studio Code ${VSCODE_VERSION}"

    INSTALLED_COMPONENTS+=("Visual Studio Code")
fi

# ------------------------------------------------------------------------------
# Docker
# ------------------------------------------------------------------------------

if [[ "$SKIP_DOCKER" == true ]]; then
    SKIPPED_COMPONENTS+=("Docker")
else
    section "Docker"

    # --------------------------------------------------------------------------
    # Detect existing container software.
    #
    # Podman is intentionally NOT removed.
    # --------------------------------------------------------------------------

    if package_installed podman; then
        warning "Podman is already installed."
        warning "Podman will NOT be removed."
    fi

    CONFLICTING_PACKAGES=()

    for package in \
        docker.io \
        docker-engine \
        docker-doc \
        docker-compose \
        containerd \
        runc; do

        if package_installed "$package"; then
            CONFLICTING_PACKAGES+=("$package")
        fi
    done

    # If Docker CE is already installed, preserve it.
    if package_installed docker-ce; then
        log "Docker Engine is already installed."
    elif [[ ${#CONFLICTING_PACKAGES[@]} -gt 0 ]]; then

        warning "Conflicting Docker packages were detected:"
        printf '  - %s\n' "${CONFLICTING_PACKAGES[@]}"

        if ask_yes_no \
            "Remove these conflicting packages and install Docker CE?" \
            "N"; then

            log "Removing conflicting Docker packages..."

            sudo DEBIAN_FRONTEND=noninteractive \
                apt-get remove -y "${CONFLICTING_PACKAGES[@]}"

        else
            warning "Docker CE installation skipped because conflicting packages were preserved."
            SKIPPED_COMPONENTS+=("Docker")
            CONFLICTING_PACKAGES=()
        fi
    fi

    # Only configure Docker CE if it wasn't skipped.
    if [[ ! " ${SKIPPED_COMPONENTS[*]} " =~ " Docker " ]]; then

        DOCKER_KEY="/etc/apt/keyrings/docker.gpg"
        DOCKER_LIST="/etc/apt/sources.list.d/docker.list"

        sudo install -d -m 0755 /etc/apt/keyrings

        DOCKER_KEY_TMP="$(mktemp)"
        TEMP_FILES+=("$DOCKER_KEY_TMP")

        log "Downloading Docker signing key..."

        curl \
            --
