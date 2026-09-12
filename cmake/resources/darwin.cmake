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

set(COMPILER_RT_BUILD_LIBFUZZER ON CACHE BOOL "")
set(COMPILER_RT_BUILD_PROFILE ON CACHE BOOL "")
set(COMPILER_RT_BUILD_SANITIZERS ON CACHE BOOL "")

set(COMPILER_RT_BUILD_CTX_PROFILE OFF CACHE BOOL "")
set(COMPILER_RT_BUILD_MEMPROF OFF CACHE BOOL "")
set(COMPILER_RT_BUILD_ORC OFF CACHE BOOL "")
set(COMPILER_RT_BUILD_XRAY OFF CACHE BOOL "")
