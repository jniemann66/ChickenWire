cmake_minimum_required(VERSION 3.16)

project(ChickenWire VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Widgets QuickWidgets ShaderTools)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appChickenWire
    main.cpp
    tonnetzController.h
    tonnetzController.cpp
    visualizerSwitcher.h
    midiFile.h
    midiFile.cpp
    midiAudio.h
    midiAudio.cpp
    midiPlayer.h
    midiPlayer.cpp
    transportWidget.h
    transportWidget.cpp
)

# Platform-specific MIDI audio backend
if(WIN32)
    target_sources(appChickenWire PRIVATE MidiAudioWin.h MidiAudioWin.cpp)
    target_link_libraries(appChickenWire PRIVATE winmm)
else()
    target_sources(appChickenWire PRIVATE midiAudioProcess.h midiAudioProcess.cpp)
endif()

set_source_files_properties(theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
    QT_QML_SOURCE_TYPENAME Theme
)

qt6_add_shaders(appChickenWire "shaders"
    PRECOMPILE
    OPTIMIZED
    PREFIX "/shaders"
    FILES coloreffect.frag
)

qt_add_qml_module(appChickenWire
    URI ChickenWire
    QML_FILES
    theme.qml
    main.qml
    tonnetz.qml
    chickenWire.qml
    cubeDance.qml
    seventhChords.qml
)

set_target_properties(appChickenWire PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appChickenWire
    PRIVATE Qt6::Quick Qt6::Widgets Qt6::QuickWidgets
)

include(GNUInstallDirs)
install(TARGETS appChickenWire
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
