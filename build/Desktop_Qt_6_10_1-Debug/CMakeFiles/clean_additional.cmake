# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "Debug")
  file(REMOVE_RECURSE
  "CMakeFiles/appChickenWire_autogen.dir/AutogenUsed.txt"
  "CMakeFiles/appChickenWire_autogen.dir/ParseCache.txt"
  "appChickenWire_autogen"
  )
endif()
