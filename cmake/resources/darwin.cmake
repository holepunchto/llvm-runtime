# Initial cache for the LLVM sub-build: the compiler runtime libraries for the
# Apple platforms we target.
#
# compiler-rt covers every Darwin platform and architecture from a single
# configuration, so the targets are given as architecture lists rather than as
# separate runtime targets. `llvm/runtimes/CMakeLists.txt` rejects a Darwin
# triple in `LLVM_RUNTIME_TARGETS` for this reason.

set(COMPILER_RT_ENABLE_IOS ON CACHE BOOL "")
set(COMPILER_RT_ENABLE_TVOS OFF CACHE BOOL "")
set(COMPILER_RT_ENABLE_WATCHOS OFF CACHE BOOL "")

set(DARWIN_osx_ARCHS arm64;x86_64 CACHE STRING "")
set(DARWIN_osx_BUILTIN_ARCHS arm64;x86_64 CACHE STRING "")

set(DARWIN_ios_ARCHS arm64 CACHE STRING "")
set(DARWIN_ios_BUILTIN_ARCHS arm64 CACHE STRING "")

set(DARWIN_iossim_ARCHS arm64;x86_64 CACHE STRING "")
set(DARWIN_iossim_BUILTIN_ARCHS arm64;x86_64 CACHE STRING "")

# `llvm_ExternalProject_Add()` hands a sub-build the compiler it just built only
# when it decides the outer build is not itself cross compiling, and leaves the
# sub-build to find its own otherwise. What it finds is Xcode's clang, which
# builds the right thing but is not the compiler these libraries ship beside.
# Naming the toolchain outright is the only way to be sure of it.
#
# Covering every architecture from one configuration also means one default
# target rather than a target apiece, so these reach the sub-builds through the
# arguments of that target rather than through a per-target prefix.
#
# The linker is left alone: Apple's is the one we do not ship.
#
# This file is the initial cache of the LLVM build, so `CMAKE_BINARY_DIR` is
# that build's directory and the tools land beneath it.
set(toolchain "${CMAKE_BINARY_DIR}/bin")

set(tools
  "-DCMAKE_ASM_COMPILER=${toolchain}/clang"
  "-DCMAKE_C_COMPILER=${toolchain}/clang"
  "-DCMAKE_CXX_COMPILER=${toolchain}/clang++"

  "-DCMAKE_AR=${toolchain}/llvm-ar"
  "-DCMAKE_LIBTOOL=${toolchain}/llvm-libtool-darwin"
  "-DCMAKE_LIPO=${toolchain}/llvm-lipo"
  "-DCMAKE_NM=${toolchain}/llvm-nm"
  "-DCMAKE_OBJDUMP=${toolchain}/llvm-objdump"
  "-DCMAKE_RANLIB=${toolchain}/llvm-ranlib"
)

set(BUILTINS_CMAKE_ARGS ${tools} CACHE STRING "")
set(RUNTIMES_CMAKE_ARGS ${tools} CACHE STRING "")

set(COMPILER_RT_BUILD_LIBFUZZER ON CACHE BOOL "")
set(COMPILER_RT_BUILD_PROFILE ON CACHE BOOL "")
set(COMPILER_RT_BUILD_SANITIZERS ON CACHE BOOL "")

set(COMPILER_RT_BUILD_CTX_PROFILE OFF CACHE BOOL "")
set(COMPILER_RT_BUILD_MEMPROF OFF CACHE BOOL "")
set(COMPILER_RT_BUILD_ORC OFF CACHE BOOL "")
set(COMPILER_RT_BUILD_XRAY OFF CACHE BOOL "")
