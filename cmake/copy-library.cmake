# Copies the one library matching `pattern` in `directory` to `destination`,
# which keeps the rest of the build from having to know how a dependency spells
# its own output. Anything other than a single match is a mistake worth
# reporting where it happens rather than passing on as a path that does not
# resolve.

file(GLOB libraries "${directory}/${pattern}")

list(LENGTH libraries count)

if(NOT count EQUAL 1)
  file(GLOB contents "${directory}/*")

  list(JOIN contents "\n  " contents)

  message(FATAL_ERROR
    "Expected one library matching '${pattern}' in '${directory}', found ${count}.\n"
    "The directory holds:\n  ${contents}\n"
  )
endif()

cmake_path(GET destination PARENT_PATH parent)

file(MAKE_DIRECTORY "${parent}")

file(COPY_FILE "${libraries}" "${destination}" ONLY_IF_DIFFERENT)
