# Initial cache for the LLVM sub-build: the compiler runtime libraries for
# Windows.
#
# Both architectures are covered so that either one can be targeted from either
# host, which is what the official LLVM release for Windows does not allow. The
# ARM64 build needs the ARM64 MSVC libraries on the build host.
#
# The sanitizers are only built for x64; they have no supported ARM64 Windows
# configuration upstream.

set(targets x86_64-pc-windows-msvc aarch64-pc-windows-msvc)

set(LLVM_BUILTIN_TARGETS ${targets} CACHE STRING "")
set(LLVM_RUNTIME_TARGETS ${targets} CACHE STRING "")

foreach(target IN LISTS targets)
  set(RUNTIMES_${target}_LLVM_ENABLE_RUNTIMES compiler-rt CACHE STRING "")

  set(RUNTIMES_${target}_COMPILER_RT_BUILD_PROFILE ON CACHE BOOL "")

  set(RUNTIMES_${target}_COMPILER_RT_BUILD_CTX_PROFILE OFF CACHE BOOL "")
  set(RUNTIMES_${target}_COMPILER_RT_BUILD_LIBFUZZER OFF CACHE BOOL "")
  set(RUNTIMES_${target}_COMPILER_RT_BUILD_MEMPROF OFF CACHE BOOL "")
  set(RUNTIMES_${target}_COMPILER_RT_BUILD_ORC OFF CACHE BOOL "")
  set(RUNTIMES_${target}_COMPILER_RT_BUILD_SANITIZERS OFF CACHE BOOL "")
  set(RUNTIMES_${target}_COMPILER_RT_BUILD_XRAY OFF CACHE BOOL "")
endforeach()

set(RUNTIMES_x86_64-pc-windows-msvc_COMPILER_RT_BUILD_LIBFUZZER ON CACHE BOOL "" FORCE)
set(RUNTIMES_x86_64-pc-windows-msvc_COMPILER_RT_BUILD_SANITIZERS ON CACHE BOOL "" FORCE)
