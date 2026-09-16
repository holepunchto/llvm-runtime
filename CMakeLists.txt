cmake_minimum_required(VERSION 4.0)

find_package(cmake-bare REQUIRED PATHS node_modules/cmake-bare)
find_package(cmake-fetch REQUIRED PATHS node_modules/cmake-fetch)

project(llvm_runtime C)

include(ExternalProject)

include(cmake/llvm-args.cmake)

set(LLVM_RUNTIME_VERSION "22.1.8" CACHE STRING "The LLVM release to build")

set(LLVM_RUNTIME_LIBXML2_VERSION "2.15.4" CACHE STRING "The libxml2 release to build for the manifest tool")

set(LLVM_RUNTIME_BACKENDS "AArch64;ARM;Mips;RISCV;WebAssembly;X86" CACHE STRING "The LLVM backends to build")

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

set(libxml2 "${CMAKE_CURRENT_BINARY_DIR}/libxml2")

set(libxml2_library "${CMAKE_CURRENT_BINARY_DIR}/libxml2-library/xml2${CMAKE_STATIC_LIBRARY_SUFFIX}")

set(dependencies)

if(platform STREQUAL "win32")
  fetch_package(
    "github:GNOME/libxml2#v${LLVM_RUNTIME_LIBXML2_VERSION}"
    SOURCE_DIR libxml2_source
    SOURCE_SUBDIR fetch-only
  )

  set(libxml2_args
    "-DCMAKE_INSTALL_PREFIX=${libxml2}"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}"
    -DBUILD_SHARED_LIBS=OFF

    -DLIBXML2_WITH_ICONV=OFF
    -DLIBXML2_WITH_MODULES=OFF
    -DLIBXML2_WITH_PROGRAMS=OFF
    -DLIBXML2_WITH_PYTHON=OFF
    -DLIBXML2_WITH_TESTS=OFF
  )

  if(CMAKE_TOOLCHAIN_FILE)
    list(APPEND libxml2_args "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}")
  endif()

  ExternalProject_Add(
    libxml2
    SOURCE_DIR "${libxml2_source}"
    BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/libxml2-build"
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    CMAKE_ARGS ${libxml2_args}
    INSTALL_COMMAND
      ${CMAKE_COMMAND} -E rm -rf "${libxml2}"
    COMMAND
      ${CMAKE_COMMAND} --build <BINARY_DIR> --target install
    COMMAND
      ${CMAKE_COMMAND}
        -D "directory=${libxml2}/lib"
        -D "pattern=*xml2*${CMAKE_STATIC_LIBRARY_SUFFIX}"
        -D "destination=${libxml2_library}"
        -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/copy-library.cmake"
    USES_TERMINAL_CONFIGURE ON
    USES_TERMINAL_BUILD ON
    USES_TERMINAL_INSTALL ON
  )

  list(APPEND dependencies libxml2)
endif()

llvm_args("${platform}" "${target}" "${libxml2}" "${libxml2_library}" args)

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

  # The tools that have to run on the build host are configured separately and
  # inherit nothing, so anything the host needs is repeated here.
  set(native_args
    "-DCMAKE_TOOLCHAIN_FILE=${host_toolchain}"
    -DCMAKE_CROSSCOMPILING=FALSE
    -DCMAKE_BUILD_TYPE=Release
    "-DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}"
  )

  if(platform STREQUAL "win32")
    list(APPEND native_args -DLLVM_DISABLE_ASSEMBLY_FILES=ON)
  endif()

  list(JOIN native_args "|" native_args)

  list(APPEND args "-DCROSS_TOOLCHAIN_FLAGS_NATIVE=${native_args}")
endif()

ExternalProject_Add(
  llvm
  DEPENDS ${dependencies}
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

# The linker and the resource directory each ship in a package of their own, so
# neither sits where a driver looks by default. A driver reads the configuration
# file named after it ahead of its command line, which names both without every
# invocation having to. `<CFGDIR>` expands to the directory the file was read
# from, and npm resolves all three packages from the same parent, which is three
# levels above it whether they are hoisted or nested.
set(config "${CMAKE_CURRENT_BINARY_DIR}/config/driver.cfg")

file(WRITE "${config}"
  "-B<CFGDIR>/../../../llvm-runtime-lld-${target}/bin\n"
  "-resource-dir=<CFGDIR>/../../../llvm-runtime-resources-${platform}\n"
)

foreach(driver clang clang++ clang-cl clang-cpp)
  install(
    FILES "${config}"
    DESTINATION "clang-${target}/etc/clang"
    RENAME "${driver}.cfg"
  )
endforeach()

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
