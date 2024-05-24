#!/bin/bash

# This script enables function that can run some code in PPC64 Crossdev environment if needed.

run_ppc64() {
    ARCHITECTURE=$(uname -m)
    ACTIONS="$@"
    if [ "$ARCHITECTURE" == "ppc64" ]; then
        $ACTIONS
    else
        ARCH=powerpc CROSS_COMPILE=powerpc64-unknown-linux-gnu- $ACTIONS
    fi
}

export -f run_ppc64
