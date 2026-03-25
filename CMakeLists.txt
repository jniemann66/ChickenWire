cmake_minimum_required(VERSION 3.16)

project(ChickenWire VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Widgets QuickWidgets)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appChickenWire
    main.cpp
    TonnetzController.h
    TonnetzController.cpp
)

qt_add_qml_module(appChickenWire
    URI ChickenWire
    QML_FILES
        Main.qml
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appChickenWire PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appChickenWire
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
