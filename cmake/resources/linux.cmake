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

foreach(target IN LISTS targets)
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
