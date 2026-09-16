# Initial cache for the LLVM sub-build: the compiler runtime libraries for
# Linux.
#
# Every architecture we can target is covered, so that any of them can be
# targeted from either host. The triples are the ones `cmake-toolchains` names,
# because the driver looks for the libraries under the triple it normalizes the
# `--target=` it was given to, and a triple we never spell is a directory
# nothing ever finds.
#
# Cross compiling these needs each architecture's headers and libraries on the
# build host, which the GCC cross toolchains provide and the driver locates on
# its own. Nothing here names a sysroot; installing `gcc-<triple>` and
# `g++-<triple>` is what makes a target buildable.

set(targets
  aarch64-linux-gnu
  arm-linux-gnueabi
  i386-linux-gnu
  mips-linux-gnu
  mipsel-linux-gnu
  riscv64-linux-gnu
  x86_64-linux-gnu
)

# The builtins and the profile runtime cover every architecture compiler-rt
# supports on Linux. The sanitizers and the fuzzer do not: upstream support for
# 32-bit Arm assumes the hard float ABI, and for 32-bit MIPS it is carried
# rather than maintained. Those architectures get the two libraries that a
# plain link needs and nothing that would only break.
set(instrumented
  aarch64-linux-gnu
  i386-linux-gnu
  riscv64-linux-gnu
  x86_64-linux-gnu
)

set(LLVM_BUILTIN_TARGETS ${targets} CACHE STRING "")
set(LLVM_RUNTIME_TARGETS ${targets} CACHE STRING "")

# `llvm_ExternalProject_Add()` hands a sub-build the compiler it just built only
# when it decides the outer build is not itself cross compiling, and leaves the
# sub-build to find its own otherwise. What it finds is the build host's
# compiler, which is not clang and so ignores the target triple CMake hands it,
# and every object comes out built for the host with nothing to say so. Naming
# the toolchain outright is the only way to be sure of it.
#
# This file is the initial cache of the LLVM build, so `CMAKE_BINARY_DIR` is
# that build's directory and the tools land beneath it.
set(toolchain "${CMAKE_BINARY_DIR}/bin")

foreach(target IN LISTS targets)
  foreach(prefix IN ITEMS BUILTINS RUNTIMES)
    set(${prefix}_${target}_CMAKE_ASM_COMPILER "${toolchain}/clang" CACHE FILEPATH "")
    set(${prefix}_${target}_CMAKE_C_COMPILER "${toolchain}/clang" CACHE FILEPATH "")
    set(${prefix}_${target}_CMAKE_CXX_COMPILER "${toolchain}/clang++" CACHE FILEPATH "")

    set(${prefix}_${target}_CMAKE_AR "${toolchain}/llvm-ar" CACHE FILEPATH "")
    set(${prefix}_${target}_CMAKE_NM "${toolchain}/llvm-nm" CACHE FILEPATH "")
    set(${prefix}_${target}_CMAKE_RANLIB "${toolchain}/llvm-ranlib" CACHE FILEPATH "")
  endforeach()

  # Only the runtimes link anything; the builtins configure with
  # `CMAKE_TRY_COMPILE_TARGET_TYPE` set to a static library and never reach a
  # linker.
  set(RUNTIMES_${target}_CMAKE_LINKER_TYPE LLD CACHE STRING "")

  set(RUNTIMES_${target}_LLVM_ENABLE_RUNTIMES compiler-rt CACHE STRING "")

  set(RUNTIMES_${target}_COMPILER_RT_BUILD_PROFILE ON CACHE BOOL "")

  set(RUNTIMES_${target}_COMPILER_RT_BUILD_CTX_PROFILE OFF CACHE BOOL "")
  set(RUNTIMES_${target}_COMPILER_RT_BUILD_MEMPROF OFF CACHE BOOL "")
  set(RUNTIMES_${target}_COMPILER_RT_BUILD_ORC OFF CACHE BOOL "")
  set(RUNTIMES_${target}_COMPILER_RT_BUILD_XRAY OFF CACHE BOOL "")

  if(target IN_LIST instrumented)
    set(RUNTIMES_${target}_COMPILER_RT_BUILD_LIBFUZZER ON CACHE BOOL "")
    set(RUNTIMES_${target}_COMPILER_RT_BUILD_SANITIZERS ON CACHE BOOL "")
  else()
    set(RUNTIMES_${target}_COMPILER_RT_BUILD_LIBFUZZER OFF CACHE BOOL "")
    set(RUNTIMES_${target}_COMPILER_RT_BUILD_SANITIZERS OFF CACHE BOOL "")
  endif()
endforeach()
