#!/bin/bash
# Build script for YALS Server

# 1. Handle cross-compilation flags
if [[ "$1" == "--arm" ]]; then
    echo "🔧 Setting up ARM (gnueabihf) cross-compilation..."
    export CC="arm-linux-gnueabihf-gcc"
    export CXX="arm-linux-gnueabihf-g++"
    # We must clean the build directory when changing toolchains
    rm -rf "./build"
else
    # Default: Try to find local compilers or use environment if set
    if [ -z "$CXX" ] && ! command -v g++ &> /dev/null; then
        # Fallback to Miniconda if present
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
echo "Miniconda path: $HOME/miniconda3"
echo "------------------------"

BUILD_DIR="./build"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR" || exit

echo "Configuring project..."
cmake ..

echo "Building project..."
cmake --build .

echo "Build finished. Binary: $(pwd)/yals_server"
cp yals_server ../yals_simulator
