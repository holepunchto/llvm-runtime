# Initial cache for the LLVM sub-build: the compiler runtime libraries for
# Linux.
#
# Every architecture we can target is covered, so that any of them can be
# targeted from either host. The triples are the ones `cmake-toolchains` names,
# because the driver looks for the libraries under the triple it normalizes the
# `--target=` it was given to, and a triple we never spell is a directory
# nothing ever finds.
#
# Cross compiling the glibc targets needs each architecture's headers and
# libraries on the build host, which the GCC cross toolchains provide and the
# driver locates on its own. Installing `gcc-<triple>` and `g++-<triple>` is
# what makes one of them buildable. The musl targets instead name a sysroot of
# musl headers, which the outer build installs for them.

set(targets
  aarch64-linux-gnu
  arm-linux-gnueabi
  i386-linux-gnu
  mips-linux-gnu
  mipsel-linux-gnu
  riscv64-linux-gnu
  x86_64-linux-gnu
)

set(musl_targets
  aarch64-linux-musl
  arm-linux-musleabi
  i386-linux-musl
  mips-linux-musl
  mips-linux-muslsf
  mipsel-linux-musl
  mipsel-linux-muslsf
  x86_64-linux-musl
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

include("${CMAKE_CURRENT_LIST_DIR}/wasi.cmake")

set(LLVM_BUILTIN_TARGETS ${targets} ${musl_targets} ${wasi_targets} CACHE STRING "")
set(LLVM_RUNTIME_TARGETS ${targets} ${musl_targets} CACHE STRING "")

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

foreach(target IN LISTS targets musl_targets)
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

# The musl headers are installed once per architecture that musl knows, which
# covers both MIPS byte orders and both float ABIs, as those follow from the
# compiler rather than from the headers.
#
# With headers and no libc, nothing links, so the runtimes probe the target by
# compiling alone, as the builtins already do. Probes that link would all fail
# and quietly leave out what they test for, such as the atomic counters of the
# profile runtime.
foreach(target IN LISTS musl_targets)
  string(REGEX MATCH "^[^-]+" arch "${target}")

  if(arch MATCHES "^mips")
    set(arch mips)
  endif()

  foreach(prefix IN ITEMS BUILTINS RUNTIMES)
    set(${prefix}_${target}_CMAKE_SYSROOT "${CMAKE_BINARY_DIR}/musl/${arch}" CACHE PATH "")
  endforeach()

  set(RUNTIMES_${target}_CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY CACHE STRING "")
endforeach()

# compiler-rt's Arm sources are written for Armv7-A, its atomic routines
# reaching for `dmb` and `ldrexd`, and the architecture the sources are chosen
# by follows from the triple alone. `arm-linux-gnueabi` and
# `arm-linux-musleabi` leave clang defaulting to Armv4T, so the architecture is
# raised to meet them rather than the sources lowered.
foreach(target IN ITEMS arm-linux-gnueabi arm-linux-musleabi)
  foreach(prefix IN ITEMS BUILTINS RUNTIMES)
    foreach(language IN ITEMS ASM C CXX)
      set(${prefix}_${target}_CMAKE_${language}_FLAGS "-march=armv7-a" CACHE STRING "")
    endforeach()
  endforeach()
endforeach()

# clang reads the floating point ABI from `-msoft-float` alone and not from the
# `muslsf` environment, which would otherwise yield hard float runtimes.
foreach(target IN ITEMS mips-linux-muslsf mipsel-linux-muslsf)
  foreach(prefix IN ITEMS BUILTINS RUNTIMES)
    foreach(language IN ITEMS ASM C CXX)
      set(${prefix}_${target}_CMAKE_${language}_FLAGS "-msoft-float" CACHE STRING "")
    endforeach()
  endforeach()
endforeach()
