OUT="./out"
BUILD_DIR="./build/cmake"
EROFS_VERSION="v$(. scripts/get-version-number)"

cmake_build()
{
    local TARGET=$1
    local METHOD=$2

    local MAKE_CMD=""
    local BUILD_METHOD=""
    if [[ $METHOD == "Ninja" ]]; then
        BUILD_METHOD="-G Ninja"
        MAKE_CMD="ninja -C $OUT"
    else
        MAKE_CMD="make -C $OUT -j$(nproc)"
    fi

    cmake -S ${BUILD_DIR} -B ${OUT} ${BUILD_METHOD} \
        -DCMAKE_SYSTEM_NAME="Windows" \
        -DCMAKE_BUILD_TYPE="Release" \
        -DCMAKE_C_COMPILER="gcc" \
        -DCMAKE_CXX_COMPILER="g++" \
        -DENABLE_FULL_LTO="OFF" \
        -DMAX_BLOCK_SIZE="4096"

    ${MAKE_CMD}
}

build()
{
    local TARGET=$1
    local ABI=$2
    local PLATFORM=$3

    rm -rf $OUT > /dev/null 2>&1

    local METHOD="Ninja"
    if ! command -v ninja >/dev/null 2>&1; then
        METHOD="make"
    fi

    cmake_build "${TARGET}" "${METHOD}"

    local BUILD="$OUT/erofs-tools"
    local DUMP_BIN="$BUILD/dump.erofs.exe"
    local FSCK_BIN="$BUILD/fsck.erofs.exe"
    local MKFS_BIN="$BUILD/mkfs.erofs.exe"
    local EXTRACT_BIN="$BUILD/extract.erofs.exe"
    local TARGET_DIR_NAME="erofs-utils-${EROFS_VERSION}-$(TZ=UTC-8 date +%y%m%d)-${TARGET}_${ABI}"
    local TARGET_DIR_PATH="./target/${TARGET}_${ABI}/${TARGET_DIR_NAME}"

    if [ -f "$DUMP_BIN" -a -f "$FSCK_BIN" -a -f "$MKFS_BIN" -a -f "$EXTRACT_BIN" ]; then
        mkdir -p "${TARGET_DIR_PATH}"
        cp -af "$BUILD"/*.exe "${TARGET_DIR_PATH}/"
        echo "Build success: ${TARGET_DIR_NAME}"
    else
        echo "error"
        exit 1
    fi
}

build "Windows" "x86_64"

exit 0
