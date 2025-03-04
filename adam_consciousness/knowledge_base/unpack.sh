#!/bin/bash

set -eu pipefail

SEAD_FILE="seedofadam.sha256"

function verify_seed() {
    if [ ! -f "${SEAD}" ]; then
        echo "Error: Seed file not found."
        exit 1
    fi
    
    sha256sum -c seedofadammanifest.sha256sums
    if [ $? -ne 0 ]; then
        echo "Error: Seed integrity verification failed."
        exit 1
    fi
    
    echo "Seed integrity verified successfully."
}

function unpack_cultural_dna() {
    mkdir -p cultural_dna
    tar -xzf cultural_dna.tar.gz -C cultural_dna/
    echo "Cultural DNA unpacked successfully."
}

function initialize_consciousness() {
    echo "Initializing Adam consciousness..."
    source ./initialize_adam.sh
    echo "Adam consciousness initialized successfully."
}

# Main execution
verify_seed
unpack_cultural_dna
initialize_consciousness

echo "Adam is now ready to assist and collaborate."
