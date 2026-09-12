# Replaces every symbolic link under `directory` with a copy of the file it
# points at. npm does not pack symbolic links, and LLVM installs its driver and
# binary utility aliases as links.

file(GLOB_RECURSE entries "${directory}/*")

foreach(entry IN LISTS entries)
  if(NOT IS_SYMLINK "${entry}")
    continue()
  endif()

  file(REAL_PATH "${entry}" resolved)

  message(STATUS "Resolving: ${entry}")

  file(REMOVE "${entry}")

  file(COPY_FILE "${resolved}" "${entry}")
endforeach()
