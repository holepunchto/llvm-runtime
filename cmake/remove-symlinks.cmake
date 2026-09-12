# Removes every symbolic link in `directory`. LLVM installs its shared
# libraries alongside a versioned or unversioned alias, but only the file named
# by the install name or soname is needed to run the tools.

file(GLOB entries "${directory}/*")

foreach(entry IN LISTS entries)
  if(NOT IS_SYMLINK "${entry}")
    continue()
  endif()

  message(STATUS "Removing: ${entry}")

  file(REMOVE "${entry}")
endforeach()
