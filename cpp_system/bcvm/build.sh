#!/bin/bash
# Build script for YAV Client

SRC_DIR=$(pwd)
BUILD_DIR="../../build/bcvm"

# 1. Handle cross-compilation flags
if [[ "$1" == "--arm" ]]; then
    echo "🔧 Setting up ARM (gnueabihf) cross-compilation..."
    
    # Pre-check for arm compiler
    if ! command -v arm-linux-gnueabihf-g++ &> /dev/null; then
        echo "❌ Error: arm-linux-gnueabihf-g++ compiler is not found in PATH."
        echo ""
        echo "----------------------------------------------------------------"
        echo "For ARM Linux cross-compilation on Windows, you must either:"
        echo "1. Compile directly in the cloud AI Studio preview container (where compilers are pre-installed)."
        echo "2. Install an 'arm-linux-gnueabihf' cross-compiler toolchain for Windows."
        echo "3. Run this project within WSL (Windows Subsystem for Linux) and install the toolchain via apt (sudo apt install g++-arm-linux-gnueabihf)."
        echo "----------------------------------------------------------------"
        exit 1
    fi
    
    export CC="arm-linux-gnueabihf-gcc"
    export CXX="arm-linux-gnueabihf-g++"
    # We must clean the build directory when changing toolchains
    rm -rf "$BUILD_DIR"
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

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR" || exit

CMAKE_OPTS=""
if [[ "$1" == "--arm" ]]; then
    CMAKE_OPTS="-DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=arm"
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$(uname)" =~ "MINGW" || "$(uname)" =~ "MSYS" ]]; then
        if command -v mingw32-make &> /dev/null; then
            CMAKE_OPTS="$CMAKE_OPTS -G \"MinGW Makefiles\""
        elif command -v make &> /dev/null; then
            CMAKE_OPTS="$CMAKE_OPTS -G \"Unix Makefiles\""
        elif command -v ninja &> /dev/null; then
            CMAKE_OPTS="$CMAKE_OPTS -G \"Ninja\""
        fi
    fi
fi

echo "Configuring project with: cmake $CMAKE_OPTS \"$SRC_DIR\""
cmake $CMAKE_OPTS "$SRC_DIR"

echo "Building project..."
cmake --build .

echo "Locating build binary..."
FOUND_BINARY=""
if [ -f "yav_client" ]; then
    FOUND_BINARY="yav_client"
elif [ -f "Debug/yav_client.exe" ]; then
    FOUND_BINARY="Debug/yav_client.exe"
elif [ -f "Release/yav_client.exe" ]; then
    FOUND_BINARY="Release/yav_client.exe"
elif [ -f "Debug/yav_client" ]; then
    FOUND_BINARY="Debug/yav_client"
elif [ -f "Release/yav_client" ]; then
    FOUND_BINARY="Release/yav_client"
elif [ -f "yav_client.exe" ]; then
    FOUND_BINARY="yav_client.exe"
fi

if [ -n "$FOUND_BINARY" ]; then
    echo "Found compiled binary: $FOUND_BINARY"
    cp "$FOUND_BINARY" "$SRC_DIR/yav_client"
    if [[ "$1" == "--arm" ]]; then
        cp "$FOUND_BINARY" "$SRC_DIR/yav_client_arm"
    fi
else
    echo "❌ Error: Compiled binary yav_client not found in build directory!"
    exit 1
fi

