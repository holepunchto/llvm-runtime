# Initial cache for the LLVM sub-build: the compiler runtime libraries for
# Linux.
#
# Only the build host's own triple is covered. Building the runtimes for
# another architecture needs a sysroot holding that architecture's glibc, which
# this package does not yet provide.

set(COMPILER_RT_BUILD_LIBFUZZER ON CACHE BOOL "")
set(COMPILER_RT_BUILD_PROFILE ON CACHE BOOL "")
set(COMPILER_RT_BUILD_SANITIZERS ON CACHE BOOL "")

set(COMPILER_RT_BUILD_CTX_PROFILE OFF CACHE BOOL "")
set(COMPILER_RT_BUILD_MEMPROF OFF CACHE BOOL "")
set(COMPILER_RT_BUILD_ORC OFF CACHE BOOL "")
set(COMPILER_RT_BUILD_XRAY OFF CACHE BOOL "")
