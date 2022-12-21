#!/bin/bash
set -ex

mkdir build
cd build

if [[ ${cuda_compiler_version} != "None" ]]; then
  export KATAGO_BACKEND="CUDA"
  export USE_CUDA=1
  export NCCL_ROOT_DIR=$PREFIX
  export NCCL_INCLUDE_DIR=$PREFIX/include
  export USE_SYSTEM_NCCL=1
  export USE_STATIC_NCCL=0
  export USE_STATIC_CUDNN=0
  export CUDA_TOOLKIT_ROOT_DIR=$CUDA_HOME
  export CUDNN_INCLUDE_DIR=$PREFIX/include
else
  export KATAGO_BACKEND="EIGEN"
  export USE_CUDA=0
fi

# Enable AVX2 on Linux and disable on OSX
if [[ "$target_platform" == "osx-64" ]]; then
  export USE_AVX2=0

  # The build script expects Clang to need to link with `-latomic`, because it's
  # (correctly) not detecting our compiler as AppleClang and it apparently
  # expects a GNU runtime rather than compiler-rt. Because of our use of the
  # distributed training feature, which requires a build against an unpatched
  # source tree, we can't fix up the build script. So instead let's fake a
  # libatomic.
  cpu="$(echo $HOST |sed -e s/-.*//)"
  ln -s $BUILD_PREFIX/lib/clang/*/lib/libclang_rt.builtins_${cpu}_osx.a $PREFIX/lib/libatomic.a
  test -f $PREFIX/lib/libatomic.a
else
  export USE_AVX2=1
fi

cmake -G Ninja \
  ${CMAKE_ARGS} \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=TRUE \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DBUILD_DISTRIBUTED=1 \
  -DUSE_BACKEND=${KATAGO_BACKEND} \
  -DUSE_AVX2=${USE_AVX2} \
  ../cpp

cmake --build .

# Install binary
mkdir -p "${PREFIX}/bin/"
cp ./katago "${PREFIX}/bin/katago"
chmod +x "${PREFIX}/bin/katago"

# Install config files
KATAGO_VAR_DIR="${PREFIX}/var/katago/"
mkdir -p $KATAGO_VAR_DIR
cp -R ../cpp/configs/ $KATAGO_VAR_DIR

# Install NN files
KATAGO_WEIGTHS_DIR="${KATAGO_VAR_DIR}/weights/"
KATAGO_WEIGTHS_NAME="kata1-b40c256-s11840935168-d2898845681.bin.gz"
curl https://media.katagotraining.org/uploaded/networks/models/kata1/${KATAGO_WEIGTHS_NAME} --output ${KATAGO_WEIGTHS_NAME}
mkdir -p $KATAGO_WEIGTHS_DIR
cp $KATAGO_WEIGTHS_NAME "${KATAGO_WEIGTHS_DIR}/${KATAGO_WEIGTHS_NAME}"
