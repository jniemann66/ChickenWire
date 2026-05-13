add_library(chordsymbol STATIC
    chordsymbol.h
    chordsymbol.cpp
)

target_include_directories(chordsymbol PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_compile_features(chordsymbol PUBLIC cxx_std_17)
