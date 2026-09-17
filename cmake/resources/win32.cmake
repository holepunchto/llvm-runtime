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

# `llvm_ExternalProject_Add()` hands a sub-build the compiler it just built only
# when it decides the outer build is not itself cross compiling, and leaves the
# sub-build to find its own otherwise. What it finds is MSVC, which has no
# notion of the target triple CMake hands it, so the ARM64 libraries come out
# built for the build host and named as though they were not. Naming the
# toolchain outright is the only way to be sure of it.
#
# This file is the initial cache of the LLVM build, so `CMAKE_BINARY_DIR` is
# that build's directory and the tools land beneath it.
set(toolchain "${CMAKE_BINARY_DIR}/bin")

foreach(target IN LISTS targets)
  # The targets are MSVC ones, so the drivers are the ones that take MSVC's
  # command line and the linker is driven by CMake rather than by them.
  foreach(prefix IN ITEMS BUILTINS RUNTIMES)
    set(${prefix}_${target}_CMAKE_ASM_COMPILER "${toolchain}/clang-cl.exe" CACHE FILEPATH "")
    set(${prefix}_${target}_CMAKE_C_COMPILER "${toolchain}/clang-cl.exe" CACHE FILEPATH "")
    set(${prefix}_${target}_CMAKE_CXX_COMPILER "${toolchain}/clang-cl.exe" CACHE FILEPATH "")

    set(${prefix}_${target}_CMAKE_AR "${toolchain}/llvm-lib.exe" CACHE FILEPATH "")
    set(${prefix}_${target}_CMAKE_LINKER "${toolchain}/lld-link.exe" CACHE FILEPATH "")
    set(${prefix}_${target}_CMAKE_MT "${toolchain}/llvm-mt.exe" CACHE FILEPATH "")
    set(${prefix}_${target}_CMAKE_RC_COMPILER "${toolchain}/llvm-rc.exe" CACHE FILEPATH "")
  endforeach()

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
