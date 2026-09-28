cmake_minimum_required(VERSION 3.20)

project(plasma-applet-topos VERSION 0.2.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(ECM 6.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

find_package(Qt6 6.6 CONFIG REQUIRED COMPONENTS Core Qml DBus)
find_package(Plasma 6.0 REQUIRED)

plasma_install_package(package org.kde.plasma.topos)

add_library(toposplugin SHARED
    plugin/plugin.cpp
    plugin/toposclient.cpp
    plugin/toposclient.h
    plugin/profilemodel.cpp
    plugin/profilemodel.h
    plugin/historymodel.cpp
    plugin/historymodel.h
)

target_link_libraries(toposplugin PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::DBus
)

install(TARGETS toposplugin
    DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/plasma/private/topos
)
install(FILES plugin/qmldir
    DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/plasma/private/topos
)
