#!/bin/bash
set -ex

cd cpp/

# Enable/disable CUDA
if [[ ! -z "${cuda_compiler_version+x}" && "${cuda_compiler_version}" != "None" ]]; then
  if [[ -z "${CUDA_HOME+x}" ]]; then
    echo "cuda_compiler_version=${cuda_compiler_version} CUDA_HOME=$CUDA_HOME"
    CUDA_GDB_EXECUTABLE=$(which cuda-gdb || exit 0)
    if [[ -n "$CUDA_GDB_EXECUTABLE" ]]; then
      CUDA_HOME=$(dirname $(dirname $CUDA_GDB_EXECUTABLE))
    else
      echo "Cannot determine CUDA_HOME: cuda-gdb not in PATH"
      return 1
    fi
  fi
  export EXTRA_CMAKE_ARGS=" ${EXTRA_CMAKE_ARGS} -DCUDA_TOOLKIT_ROOT_DIR=${CUDA_HOME} -DCMAKE_LIBRARY_PATH=${CUDA_HOME}/lib64/stubs"
  export KATAGO_BACKEND="CUDA"
  export USE_STATIC_CUDNN=0
  export CUDNN_INCLUDE_DIR=$PREFIX/include
else
  export KATAGO_BACKEND="EIGEN"
fi

# Enable AVX2 on Linux and disable on OSX
if [[ "$target_platform" == "osx-64" ]]; then
  export USE_AVX2=0
else
  export USE_AVX2=1
fi

cmake ${CMAKE_ARGS} . \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=TRUE \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DUSE_BACKEND=${KATAGO_BACKEND} \
  -DNO_GIT_REVISION=1 \
  -DUSE_AVX2=${USE_AVX2} \
  ${EXTRA_CMAKE_ARGS}

make -j $CPU_COUNT

# Install binary
mkdir -p "${PREFIX}/bin/"
cp ./katago "${PREFIX}/bin/katago"
chmod +x "${PREFIX}/bin/katago"

# Install config files
KATAGO_VAR_DIR="${PREFIX}/var/katago/"
mkdir -p $KATAGO_VAR_DIR
cp -R ./configs/ $KATAGO_VAR_DIR

# Install NN files
KATAGO_WEIGTHS_DIR="${KATAGO_VAR_DIR}/weights/"
KATAGO_WEIGTHS_NAME="kata1-b40c256-s11840935168-d2898845681.bin.gz"
curl https://media.katagotraining.org/uploaded/networks/models/kata1/${KATAGO_WEIGTHS_NAME} --output ${KATAGO_WEIGTHS_NAME}
mkdir -p $KATAGO_WEIGTHS_DIR
cp $KATAGO_WEIGTHS_NAME "${KATAGO_WEIGTHS_DIR}/${KATAGO_WEIGTHS_NAME}"
