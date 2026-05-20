#!/bin/bash
# Build script for ASN Simulator

SRC_DIR=$(pwd)
BUILD_DIR="../../build/asn"

if [[ "$1" == "--arm" ]]; then
    echo "🔧 Setting up ARM (gnueabihf) cross-compilation..."
    export CC="arm-linux-gnueabihf-gcc"
    export CXX="arm-linux-gnueabihf-g++"
    rm -rf "$BUILD_DIR"
else
    if [ -z "$CXX" ] && ! command -v g++ &> /dev/null; then
        if [ -d "$HOME/miniconda3/bin" ]; then
            export PATH="$HOME/miniconda3/bin:$PATH"
            if [ -x "$HOME/miniconda3/bin/x86_64-conda-linux-gnu-g++" ]; then
                export CC="$HOME/miniconda3/bin/x86_64-conda-linux-gnu-gcc"
                export CXX="$HOME/miniconda3/bin/x86_64-conda-linux-gnu-g++"
            fi
        fi
    fi
fi

echo "--- Build Environment ---"
echo "Effective CXX: ${CXX:-$(command -v g++ || echo 'Not found')}"
echo "Effective CC: ${CC:-$(command -v gcc || echo 'Not found')}"
echo "------------------------"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR" || exit

echo "Configuring project..."
cmake "$SRC_DIR"

echo "Building project..."
cmake --build .

echo "Build finished. Binary: $(pwd)/asn_simulator"
cp asn_simulator "$SRC_DIR/asn_simulator"
