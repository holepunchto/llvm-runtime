# Included by the initial cache of every platform: the compiler runtime builtins
# and libunwind for Android, which any host can target.
#
# The driver links both into everything it links for Android, so neither is
# optional. They are built against the sysroot of the NDK in
# `LLVM_RUNTIME_ANDROID_NDK` at the lowest API level the NDK supports, which
# serves every API level above it.
#
# The libraries are laid out as the NDK lays out its own, rather than in a
# directory per target. The driver only finds a per-target directory for
# Android by the exact API level of the target or a lower one, and only ever
# finds libunwind there by the exact one. The layout of the NDK is instead
# found by architecture alone.

file(GLOB android_sysroot LIST_DIRECTORIES true "${LLVM_RUNTIME_ANDROID_NDK}/toolchains/llvm/prebuilt/*/sysroot")

if(NOT android_sysroot)
  message(FATAL_ERROR "No sysroot in the Android NDK at '${LLVM_RUNTIME_ANDROID_NDK}'")
endif()

list(GET android_sysroot 0 android_sysroot)

string(REGEX MATCH "^[0-9]+" android_version "${LLVM_RUNTIME_VERSION}")

set(android_api 21)

set(android_targets
  aarch64-linux-android${android_api}
  armv7a-linux-androideabi${android_api}
  i686-linux-android${android_api}
  x86_64-linux-android${android_api}
)

# The ABI is what CMake knows an Android architecture by, and the architecture
# directory is where the driver looks for libunwind, named by the architecture
# of the triple rather than by the ABI.
set(android_aarch64-linux-android${android_api}_abi arm64-v8a)
set(android_aarch64-linux-android${android_api}_arch aarch64)

set(android_armv7a-linux-androideabi${android_api}_abi armeabi-v7a)
set(android_armv7a-linux-androideabi${android_api}_arch arm)

set(android_i686-linux-android${android_api}_abi x86)
set(android_i686-linux-android${android_api}_arch i386)

set(android_x86_64-linux-android${android_api}_abi x86_64)
set(android_x86_64-linux-android${android_api}_arch x86_64)

# This file is the initial cache of the LLVM build, so `CMAKE_BINARY_DIR` is
# that build's directory and the tools land beneath it.
set(android_toolchain "${CMAKE_BINARY_DIR}/bin")

if(CMAKE_HOST_WIN32)
  set(android_suffix ".exe")
else()
  set(android_suffix "")
endif()

foreach(target IN LISTS android_targets)
  foreach(prefix IN ITEMS BUILTINS RUNTIMES)
    # CMake only defines `ANDROID`, by which compiler-rt names its libraries
    # for Android, for a system name of Android. The sysroot is named outright,
    # as CMake leaves it unset when the compilers are named.
    set(${prefix}_${target}_CMAKE_SYSTEM_NAME Android CACHE STRING "")
    set(${prefix}_${target}_CMAKE_SYSTEM_VERSION ${android_api} CACHE STRING "")
    set(${prefix}_${target}_CMAKE_ANDROID_ARCH_ABI ${android_${target}_abi} CACHE STRING "")
    set(${prefix}_${target}_CMAKE_ANDROID_NDK "${LLVM_RUNTIME_ANDROID_NDK}" CACHE PATH "")
    set(${prefix}_${target}_CMAKE_ANDROID_STL_TYPE none CACHE STRING "")
    set(${prefix}_${target}_CMAKE_SYSROOT "${android_sysroot}" CACHE PATH "")

    set(${prefix}_${target}_CMAKE_ASM_COMPILER "${android_toolchain}/clang${android_suffix}" CACHE FILEPATH "")
    set(${prefix}_${target}_CMAKE_C_COMPILER "${android_toolchain}/clang${android_suffix}" CACHE FILEPATH "")
    set(${prefix}_${target}_CMAKE_CXX_COMPILER "${android_toolchain}/clang++${android_suffix}" CACHE FILEPATH "")

    set(${prefix}_${target}_CMAKE_AR "${android_toolchain}/llvm-ar${android_suffix}" CACHE FILEPATH "")
    set(${prefix}_${target}_CMAKE_NM "${android_toolchain}/llvm-nm${android_suffix}" CACHE FILEPATH "")
    set(${prefix}_${target}_CMAKE_RANLIB "${android_toolchain}/llvm-ranlib${android_suffix}" CACHE FILEPATH "")
  endforeach()

  # Unlike libunwind, the builtins are named by architecture, so the targets
  # can share the directory they are built into.
  set(BUILTINS_${target}_LLVM_ENABLE_PER_TARGET_RUNTIME_DIR OFF CACHE BOOL "")

  set(RUNTIMES_${target}_LLVM_ENABLE_RUNTIMES libunwind CACHE STRING "")

  # The driver only ever links the static libunwind, shared libraries included,
  # so it is position independent and its symbols are hidden, as in the NDK,
  # for a shared library linking it not to export it.
  set(RUNTIMES_${target}_CMAKE_POSITION_INDEPENDENT_CODE ON CACHE BOOL "")

  set(RUNTIMES_${target}_LIBUNWIND_ENABLE_SHARED OFF CACHE BOOL "")
  set(RUNTIMES_${target}_LIBUNWIND_HIDE_SYMBOLS ON CACHE BOOL "")
  set(RUNTIMES_${target}_LIBUNWIND_INSTALL_HEADERS OFF CACHE BOOL "")
  set(RUNTIMES_${target}_LIBUNWIND_USE_COMPILER_RT ON CACHE BOOL "")

  set(RUNTIMES_${target}_LIBUNWIND_INSTALL_LIBRARY_DIR "lib/clang/${android_version}/lib/linux/${android_${target}_arch}" CACHE STRING "")
endforeach()
