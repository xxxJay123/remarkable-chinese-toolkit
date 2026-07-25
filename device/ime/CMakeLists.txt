cmake_minimum_required(VERSION 3.16)

project(remarkable_chinese_ime VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick)
find_package(PkgConfig REQUIRED)
pkg_check_modules(Rime REQUIRED IMPORTED_TARGET rime)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(remarkable-chinese-ime-prototype
    src/main.cpp
    src/RimeController.cpp
    src/RimeController.h
)

qt_add_qml_module(remarkable-chinese-ime-prototype
    URI Remarkable.ChineseToolkit.Ime
    VERSION 1.0
    QML_FILES
        qml/Main.qml
)

target_link_libraries(remarkable-chinese-ime-prototype
    PRIVATE
        Qt6::Quick
        PkgConfig::Rime
)

install(TARGETS remarkable-chinese-ime-prototype
    RUNTIME DESTINATION bin
)
