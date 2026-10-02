# Included by the initial cache of every platform: the compiler runtime builtins
# for WebAssembly, which any host can target.
#
# The builtins are freestanding and build against nothing but clang's own
# headers, so unlike the other targets this one needs nothing installed on the
# build host. The libc and the C++ libraries are built against these in
# `wasi-sysroot`, not here.
#
# The triples are spelled as the driver normalizes them, because that is the
# directory it looks the libraries up in, and `wasm32-wasip1` is
# `wasm32-unknown-wasip1` by the time it does.

set(wasi_targets wasm32-unknown-wasip1)

# This file is the initial cache of the LLVM build, so `CMAKE_BINARY_DIR` is
# that build's directory and the tools land beneath it.
set(wasi_toolchain "${CMAKE_BINARY_DIR}/bin")

if(CMAKE_HOST_WIN32)
  set(wasi_suffix ".exe")
else()
  set(wasi_suffix "")
endif()

foreach(target IN LISTS wasi_targets)
  # A builtins target that is not the default one is configured from its own
  # passthrough options alone, and without a system name of its own it takes
  # the build host's, which on macOS has compiler-rt build it as Apple.
  set(BUILTINS_${target}_CMAKE_SYSTEM_NAME WASI CACHE STRING "")

  set(BUILTINS_${target}_CMAKE_ASM_COMPILER "${wasi_toolchain}/clang${wasi_suffix}" CACHE FILEPATH "")
  set(BUILTINS_${target}_CMAKE_C_COMPILER "${wasi_toolchain}/clang${wasi_suffix}" CACHE FILEPATH "")
  set(BUILTINS_${target}_CMAKE_CXX_COMPILER "${wasi_toolchain}/clang++${wasi_suffix}" CACHE FILEPATH "")

  set(BUILTINS_${target}_CMAKE_AR "${wasi_toolchain}/llvm-ar${wasi_suffix}" CACHE FILEPATH "")
  set(BUILTINS_${target}_CMAKE_NM "${wasi_toolchain}/llvm-nm${wasi_suffix}" CACHE FILEPATH "")
  set(BUILTINS_${target}_CMAKE_RANLIB "${wasi_toolchain}/llvm-ranlib${wasi_suffix}" CACHE FILEPATH "")

  set(BUILTINS_${target}_COMPILER_RT_BAREMETAL_BUILD ON CACHE BOOL "")
endforeach()
