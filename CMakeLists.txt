cmake_minimum_required(VERSION 4.0)

find_package(cmake-bare REQUIRED PATHS node_modules/cmake-bare)
find_package(cmake-fetch REQUIRED PATHS node_modules/cmake-fetch)

project(llvm_runtime C)

include(ExternalProject)

include(cmake/llvm-args.cmake)

set(LLVM_RUNTIME_VERSION "22.1.8" CACHE STRING "The LLVM release to build")

set(LLVM_RUNTIME_BACKENDS "AArch64;ARM;RISCV;WebAssembly;X86" CACHE STRING "The LLVM backends to build")

option(LLVM_RUNTIME_SHARED "Build LLVM as a shared library" ON)

option(LLVM_RUNTIME_RESOURCES "Build the clang resource directory for the target operating system" OFF)

bare_platform(platform)
bare_target(target)
bare_target(host HOST)

string(REGEX MATCH "^[0-9]+" version "${LLVM_RUNTIME_VERSION}")

set(stage "${CMAKE_CURRENT_BINARY_DIR}/stage")

set(resources "${stage}/lib/clang/${version}")

fetch_package(
  "github:llvm/llvm-project#llvmorg-${LLVM_RUNTIME_VERSION}"
  SOURCE_DIR source
  SOURCE_SUBDIR fetch-only
  PATCHES patches/llvm-orc-backtrace-tools-export.patch
)

llvm_args("${platform}" "${target}" args)

list(APPEND args
  "-DCMAKE_INSTALL_PREFIX=${stage}"
  "-DCMAKE_BUILD_TYPE=Release"
  "-DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}"
)

if(CMAKE_TOOLCHAIN_FILE)
  list(APPEND args "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}")
endif()

set(build_targets distribution)
set(install_targets install-distribution)

if(LLVM_RUNTIME_RESOURCES)
  set(cache "${CMAKE_CURRENT_SOURCE_DIR}/cmake/resources/${platform}.cmake")

  if(NOT EXISTS "${cache}")
    message(FATAL_ERROR "No compiler runtime configuration for '${platform}'")
  endif()

  list(PREPEND args -C "${cache}")

  list(APPEND args -DLLVM_ENABLE_RUNTIMES=compiler-rt -DCOMPILER_RT_BUILD_BUILTINS=OFF)

  list(APPEND build_targets builtins runtimes)
  list(APPEND install_targets install-builtins install-runtimes)
else()
  list(APPEND args -DLLVM_ENABLE_RUNTIMES=)
endif()

if(target STREQUAL host)
  list(APPEND args "-DCMAKE_CROSSCOMPILING=FALSE")
else()
  cmake_path(GET CMAKE_TOOLCHAIN_FILE PARENT_PATH toolchains)

  set(host_toolchain "${toolchains}/${host}.cmake")

  if(NOT EXISTS "${host_toolchain}")
    message(FATAL_ERROR "No toolchain file for the build host at '${host_toolchain}'")
  endif()

  list(APPEND args
    "-DCROSS_TOOLCHAIN_FLAGS_NATIVE=-DCMAKE_TOOLCHAIN_FILE=${host_toolchain}|-DCMAKE_CROSSCOMPILING=FALSE|-DCMAKE_BUILD_TYPE=Release|-DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}"
  )
endif()

ExternalProject_Add(
  llvm
  SOURCE_DIR "${source}/llvm"
  BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/llvm"
  DOWNLOAD_COMMAND ""
  UPDATE_COMMAND ""
  LIST_SEPARATOR "|"
  CMAKE_ARGS ${args}
  BUILD_COMMAND
    ${CMAKE_COMMAND} --build <BINARY_DIR> --target ${build_targets}
  INSTALL_COMMAND
    ${CMAKE_COMMAND} --build <BINARY_DIR> --target ${install_targets}
  COMMAND
    ${CMAKE_COMMAND}
      -D "directory=${stage}/lib"
      -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/remove-symlinks.cmake"
  COMMAND
    ${CMAKE_COMMAND}
      -D "directory=${stage}"
      -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/resolve-symlinks.cmake"
  USES_TERMINAL_CONFIGURE ON
  USES_TERMINAL_BUILD ON
  USES_TERMINAL_INSTALL ON
)

add_custom_target(llvm_runtime ALL)

add_dependencies(llvm_runtime llvm)

file(MAKE_DIRECTORY "${stage}/bin" "${stage}/lib" "${resources}")

set(linkers ld.lld ld64.lld lld lld-link wasm-ld)

list(TRANSFORM linkers REPLACE "\\." "\\\\.")

list(JOIN linkers "|" linkers)

set(linkers "/(${linkers})(\\.exe)?$")

set(scripts "/git-clang-format(\\.bat)?$")

install(
  DIRECTORY "${stage}/bin/"
  DESTINATION "clang-${target}/bin"
  USE_SOURCE_PERMISSIONS
  REGEX "${linkers}" EXCLUDE
  REGEX "${scripts}" EXCLUDE
)

install(
  DIRECTORY "${stage}/lib/"
  DESTINATION "clang-${target}/lib"
  USE_SOURCE_PERMISSIONS
  FILES_MATCHING
    REGEX "\\.(dylib|so(\\.[0-9]+)*)$"
    PATTERN "clang" EXCLUDE
)

install(
  DIRECTORY "${stage}/bin/"
  DESTINATION "lld-${target}/bin"
  USE_SOURCE_PERMISSIONS
  FILES_MATCHING
    REGEX "${linkers}"
)

if(LLVM_RUNTIME_SHARED AND platform STREQUAL "win32")
  install(
    DIRECTORY "${stage}/bin/"
    DESTINATION "lld-${target}/bin"
    USE_SOURCE_PERMISSIONS
    FILES_MATCHING
      REGEX "/(lib)?LLVM(-[0-9.]+)?\\.dll$"
  )
endif()

if(LLVM_RUNTIME_RESOURCES)
  install(
    DIRECTORY "${resources}/"
    DESTINATION "resources-${platform}"
    USE_SOURCE_PERMISSIONS
  )
endif()
