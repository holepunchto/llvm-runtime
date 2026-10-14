# Selects the shared C runtime for a project that is included after the project
# is declared. The toolchain file selects the static runtime with `set()`, which
# shadows a cache entry passed on the command line, so the choice has to be
# made after the toolchain file has run, which `CMAKE_PROJECT_INCLUDE` allows.

set(CMAKE_MSVC_RUNTIME_LIBRARY MultiThreadedDLL)
