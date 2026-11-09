# Included by the initial cache of every platform: the compiler runtime builtins
# for the bare metal targets, which any host can target.
#
# Like the WebAssembly builtins, these are freestanding and build against
# nothing but clang's own headers. The libc is built against these in
# `picolibc-sysroot`, not here.
#
# The triples are spelled as the driver normalizes them, because that is the
# directory it looks the libraries up in.

set(baremetal_targets
  riscv32-unknown-none-elf
  thumbv8m.main-unknown-none-eabihf
)

# This file is the initial cache of the LLVM build, so `CMAKE_BINARY_DIR` is
# that build's directory and the tools land beneath it.
set(baremetal_toolchain "${CMAKE_BINARY_DIR}/bin")

if(CMAKE_HOST_WIN32)
  set(baremetal_suffix ".exe")
else()
  set(baremetal_suffix "")
endif()

foreach(target IN LISTS baremetal_targets)
  # A builtins target that is not the default one is configured from its own
  # passthrough options alone, and without a system name of its own it takes
  # the build host's, which on macOS has compiler-rt build it as Apple.
  set(BUILTINS_${target}_CMAKE_SYSTEM_NAME Generic CACHE STRING "")

  set(BUILTINS_${target}_CMAKE_ASM_COMPILER "${baremetal_toolchain}/clang${baremetal_suffix}" CACHE FILEPATH "")
  set(BUILTINS_${target}_CMAKE_C_COMPILER "${baremetal_toolchain}/clang${baremetal_suffix}" CACHE FILEPATH "")
  set(BUILTINS_${target}_CMAKE_CXX_COMPILER "${baremetal_toolchain}/clang++${baremetal_suffix}" CACHE FILEPATH "")

  set(BUILTINS_${target}_CMAKE_AR "${baremetal_toolchain}/llvm-ar${baremetal_suffix}" CACHE FILEPATH "")
  set(BUILTINS_${target}_CMAKE_NM "${baremetal_toolchain}/llvm-nm${baremetal_suffix}" CACHE FILEPATH "")
  set(BUILTINS_${target}_CMAKE_RANLIB "${baremetal_toolchain}/llvm-ranlib${baremetal_suffix}" CACHE FILEPATH "")

  set(BUILTINS_${target}_COMPILER_RT_BAREMETAL_BUILD ON CACHE BOOL "")
endforeach()

# The driver gives Armv8-M Mainline a double precision FPU by default, but the
# Cortex-M33 has only a single precision one. Code built for it also runs on
# the later cores, whose FPU adds double precision.
foreach(language IN ITEMS ASM C CXX)
  set(BUILTINS_thumbv8m.main-unknown-none-eabihf_CMAKE_${language}_FLAGS "-mfpu=fpv5-sp-d16" CACHE STRING "")
endforeach()
