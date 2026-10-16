# Advance one program's build counter and write the version translation unit.
# The trigger file is an extra output. The build removes it after linking so
# the next build runs this script again.

if(NOT DEFINED NAME OR NOT DEFINED MAJOR OR NOT DEFINED MINOR OR NOT DEFINED PATCH
   OR NOT DEFINED CONFIG OR NOT DEFINED COUNTER OR NOT DEFINED OUT OR NOT DEFINED TRIGGER)
  message(FATAL_ERROR "bump_build.cmake: NAME, MAJOR, MINOR, PATCH, CONFIG, COUNTER, OUT, and TRIGGER are required")
endif()
if(NOT CONFIG MATCHES "^(debug|release)$")
  message(FATAL_ERROR "bump_build.cmake: CONFIG must be debug or release")
endif()

set(n 0)
if(EXISTS "${COUNTER}")
  file(READ "${COUNTER}" n)
  string(STRIP "${n}" n)
endif()
if(NOT n MATCHES "^[0-9]+$")
  set(n 0)
endif()
math(EXPR n "${n} + 1")

get_filename_component(counter_dir "${COUNTER}" DIRECTORY)
file(MAKE_DIRECTORY "${counter_dir}")
get_filename_component(out_dir "${OUT}" DIRECTORY)
file(MAKE_DIRECTORY "${out_dir}")
file(WRITE "${COUNTER}" "${n}\n")

set(text "${MAJOR}.${MINOR}.${PATCH} build ${n} ${CONFIG}")
if(NAME STREQUAL "qasm")
  file(WRITE "${OUT}"
"#include \"version.hpp\"

namespace qasm {
const char *version_string()
{
    return \"qasm ${text}\";
}
}
")
elseif(NAME STREQUAL "qlink")
  file(WRITE "${OUT}"
"const char *qlink_version_string()
{
    return \"qlink ${text}\";
}
")
elseif(NAME STREQUAL "makeBin")
  file(WRITE "${OUT}"
"const char *makebin_version_string()
{
    return \"makeBin ${text}\";
}
")
elseif(NAME STREQUAL "qomf")
  file(WRITE "${OUT}"
"const char *qomf_version_string()
{
    return \"qomf ${text}\";
}
")
elseif(NAME STREQUAL "qpro")
  file(WRITE "${OUT}"
"const char *qpro_version_string()
{
    return \"qpro ${text}\";
}
")
else()
  message(FATAL_ERROR "bump_build.cmake: unknown program ${NAME}")
endif()

file(WRITE "${TRIGGER}" "")
