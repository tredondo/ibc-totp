#!/usr/bin/env bash
# Download external dependencies for IBC
# This script downloads third-party libraries required for building IBC with TOTP support

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Library version (com.warrenstrange:googleauth)
GOOGLEAUTH_VERSION="1.5.0"
GOOGLEAUTH_URL="https://repo1.maven.org/maven2/com/warrenstrange/googleauth/${GOOGLEAUTH_VERSION}/googleauth-${GOOGLEAUTH_VERSION}.jar"

# Download googleauth library for TOTP support
download_googleauth() {
    local dest_dir="$PROJECT_ROOT/IBC/lib"
    local dest_file="$dest_dir/googleauth-${GOOGLEAUTH_VERSION}.jar"
    
    if [ -f "$dest_file" ] && file "$dest_file" | grep -q "Zip archive"; then
        echo "✓ googleauth-${GOOGLEAUTH_VERSION}.jar already exists"
        return 0
    fi
    
    echo "Downloading googleauth library..."
    mkdir -p "$dest_dir"
    
    if command -v curl &> /dev/null; then
        curl -sL "$GOOGLEAUTH_URL" -o "$dest_file"
    elif command -v wget &> /dev/null; then
        wget -q "$GOOGLEAUTH_URL" -O "$dest_file"
    else
        echo "Error: curl or wget required"
        exit 1
    fi
    
    # Verify it's a valid JAR
    if ! file "$dest_file" | grep -q "Zip archive"; then
        echo "Error: Downloaded file is not a valid JAR"
        rm -f "$dest_file"
        exit 1
    fi
    
    echo "✓ Downloaded googleauth-${GOOGLEAUTH_VERSION}.jar"
}

# Download to docker/IBC/lib (for final deployment)
download_googleauth_docker() {
    local dest_dir="$PROJECT_ROOT/docker/IBC/lib"
    local dest_file="$dest_dir/googleauth-${GOOGLEAUTH_VERSION}.jar"
    
    if [ -f "$dest_file" ] && file "$dest_file" | grep -q "Zip archive"; then
        echo "✓ docker/IBC/lib/googleauth-${GOOGLEAUTH_VERSION}.jar already exists"
        return 0
    fi
    
    echo "Downloading googleauth library for Docker..."
    mkdir -p "$dest_dir"
    
    if command -v curl &> /dev/null; then
        curl -sL "$GOOGLEAUTH_URL" -o "$dest_file"
    elif command -v wget &> /dev/null; then
        wget -q "$GOOGLEAUTH_URL" -O "$dest_file"
    else
        echo "Error: curl or wget required"
        exit 1
    fi
    
    # Verify it's a valid JAR
    if ! file "$dest_file" | grep -q "Zip archive"; then
        echo "Error: Downloaded file is not a valid JAR"
        rm -f "$dest_file"
        exit 1
    fi
    
    echo "✓ Downloaded googleauth-${GOOGLEAUTH_VERSION}.jar for Docker"
}

# Main
case "${1:-all}" in
    all)
        echo "=== Downloading IBC External Dependencies ==="
        echo
        download_googleauth
        download_googleauth_docker
        echo
        echo "=== All dependencies downloaded ==="
        ;;
    ibc)
        echo "=== Downloading IBC Dependencies ==="
        download_googleauth
        ;;
    docker)
        echo "=== Downloading Docker Dependencies ==="
        download_googleauth_docker
        ;;
    clean)
        rm -f "$PROJECT_ROOT/IBC/lib/googleauth-${GOOGLEAUTH_VERSION}.jar"
        rm -f "$PROJECT_ROOT/docker/IBC/lib/googleauth-${GOOGLEAUTH_VERSION}.jar"
        echo "Cleaned up dependencies"
        ;;
    help|--help|-h)
        echo "Usage: $0 [all|ibc|docker|clean]"
        echo
        echo "  all    - Download all dependencies (default)"
        echo "  ibc    - Download to IBC/lib only"
        echo "  docker - Download to docker/IBC/lib only"
        echo "  clean  - Remove downloaded dependencies"
        exit 0
        ;;
    *)
        echo "Unknown option: $1"
        echo "Usage: $0 [all|ibc|docker|clean]"
        exit 1
        ;;
esac
