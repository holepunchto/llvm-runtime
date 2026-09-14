include_guard()

# Assembles the arguments for the LLVM sub-build. List valued arguments are
# separated by `|`, which `ExternalProject_Add()` turns back into `;` by way of
# its `LIST_SEPARATOR` option.
function(llvm_args platform target libxml2 libxml2_library result)
  set(components
    clang
    clang-format
    clang-resource-headers
    clang-scan-deps
    lld
    llvm-ar
    llvm-config
    llvm-cov
    llvm-cxxfilt
    llvm-cxxmap
    llvm-dwarfdump
    llvm-lib
    llvm-nm
    llvm-objcopy
    llvm-objdump
    llvm-profdata
    llvm-ranlib
    llvm-rc
    llvm-readobj
    llvm-size
    llvm-strings
    llvm-strip
    llvm-symbolizer
    sancov
    sanstats
  )

  # Tools tied to one object format. Several are aliases of tools already in the
  # list above, and an alias installs as a copy rather than a symlink, so
  # shipping them everywhere would not be free.
  if(platform STREQUAL "darwin")
    list(APPEND components
      dsymutil
      llvm-install-name-tool
      llvm-libtool-darwin
      llvm-lipo
      llvm-otool
    )
  elseif(platform STREQUAL "linux")
    list(APPEND components
      llvm-addr2line
      llvm-readelf
    )
  elseif(platform STREQUAL "win32")
    list(APPEND components
      llvm-dlltool
      llvm-ml
      llvm-ml64
      llvm-mt
      llvm-windres
    )
  endif()

  set(args
    -DLLVM_ENABLE_PROJECTS=clang|lld
    -DLLVM_ENABLE_ASSERTIONS=OFF
    -DLLVM_ENABLE_BACKTRACES=OFF
    -DLLVM_ENABLE_CURL=OFF
    -DLLVM_ENABLE_HTTPLIB=OFF
    -DLLVM_ENABLE_LIBEDIT=OFF
    -DLLVM_ENABLE_LIBPFM=OFF
    -DLLVM_ENABLE_PLUGINS=OFF
    -DLLVM_ENABLE_TERMINFO=OFF
    -DLLVM_ENABLE_ZLIB=OFF
    -DLLVM_ENABLE_ZSTD=OFF
    -DLLVM_INCLUDE_BENCHMARKS=OFF
    -DLLVM_INCLUDE_DOCS=OFF
    -DLLVM_INCLUDE_EXAMPLES=OFF
    -DLLVM_INCLUDE_TESTS=OFF
    -DCLANG_INCLUDE_TESTS=OFF

    # Let the binaries read `<prefix>/etc/clang/<triple>.cfg`, which is how a
    # resource directory that lives in a separate package is wired up without
    # every invocation having to pass `-resource-dir`.
    -DCLANG_CONFIG_FILE_SYSTEM_DIR=../etc/clang
  )

  # CMake drives the manifest tool itself when linking for an MSVC target, so
  # `llvm-mt` is not optional there. It only exists when LLVM finds libxml2,
  # which is built alongside us rather than detected so that the tool set does
  # not depend on what the build machine happens to have. `FORCE_ON` turns a
  # missing one into a configure failure rather than a silently absent tool.
  if(platform STREQUAL "win32")
    # libxml2 is a DLL rather than a static library: a static one on Windows
    # needs `bcrypt`, and that is a usage requirement `FindLibXml2` cannot
    # carry, describing a library by path alone. The path is one we copied the
    # build's output to, so neither of us has to agree with the other on how
    # libxml2 spells it.
    list(APPEND args
      -DLLVM_ENABLE_LIBXML2=FORCE_ON
      "-DLIBXML2_INCLUDE_DIR=${libxml2}/include/libxml2"
      "-DLIBXML2_LIBRARY=${libxml2_library}"
    )
  else()
    list(APPEND args -DLLVM_ENABLE_LIBXML2=OFF)
  endif()

  if(LLVM_RUNTIME_SHARED)
    list(APPEND args
      -DLLVM_BUILD_LLVM_DYLIB=ON
      -DLLVM_LINK_LLVM_DYLIB=ON
    )

    list(APPEND components LLVM)

    if(platform STREQUAL "win32")
      # `LLVM_BUILD_LLVM_DYLIB` is a `cmake_dependent_option()` that MSVC
      # silently forces off unless this is set, which switches LLVM to the
      # explicit symbol visibility that its `LLVM_ABI` annotations exist for.
      #
      # `LLVM_DYLIB_EXPORT_INLINES` is deliberately left alone: it exists to
      # make a clang-cl built DLL consumable from MSVC, which nothing we ship
      # is, and a Windows DLL may export at most 65,535 symbols.
      #
      # clang is a different matter. Its public API carries almost none of the
      # export annotations that LLVM's does, so nothing it declares reaches a
      # DLL's export table and the drivers cannot link against one. They link
      # clang statically and share LLVM alone.
      list(APPEND args
        -DLLVM_BUILD_LLVM_DYLIB_VIS=ON
        -DCLANG_LINK_CLANG_DYLIB=OFF
      )
    else()
      list(APPEND args -DCLANG_LINK_CLANG_DYLIB=ON)

      list(APPEND components clang-cpp)

      # The shared libraries ship in the compiler package, so lld has to reach
      # across to its sibling to find them. npm resolves both packages from the
      # same parent, which keeps them siblings whether it hoists them or nests
      # them. Setting this makes `llvm_setup_rpath()` stand down, so the default
      # entry has to be repeated here. Windows has no equivalent, and gets a
      # copy of the library in each package instead.
      if(platform STREQUAL "darwin")
        set(origin "@loader_path")
      else()
        set(origin "$ORIGIN")
      endif()

      list(APPEND args
        "-DCMAKE_INSTALL_RPATH=${origin}/../lib|${origin}/../../llvm-runtime-clang-${target}/lib"
      )
    endif()
  else()
    list(APPEND args
      -DLLVM_BUILD_LLVM_DYLIB=OFF
      -DLLVM_LINK_LLVM_DYLIB=OFF
      -DCLANG_LINK_CLANG_DYLIB=OFF
    )
  endif()

  list(JOIN LLVM_RUNTIME_BACKENDS "|" backends)
  list(JOIN components "|" components)

  list(APPEND args
    "-DLLVM_TARGETS_TO_BUILD=${backends}"
    "-DLLVM_DISTRIBUTION_COMPONENTS=${components}"
  )

  set(${result} ${args})

  return(PROPAGATE ${result})
endfunction()
