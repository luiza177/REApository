cmake_minimum_required(VERSION 3.15)
project(reaper_hello CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)   # needed for clangd

add_library(reaper_hello MODULE src/main.cpp)

target_include_directories(reaper_hello PRIVATE
    external/reaper-sdk/sdk
    external/WDL
    external/WDL/WDL
)

# REAPER requires the filename to start with "reaper_"
set_target_properties(reaper_hello PROPERTIES PREFIX "")
if(APPLE)
    set_target_properties(reaper_hello PROPERTIES SUFFIX ".dylib")
endif()

# Copy into REAPER's UserPlugins after each build
if(WIN32)
    set(REAPER_PLUGINS "$ENV{APPDATA}/REAPER/UserPlugins")
elseif(APPLE)
    set(REAPER_PLUGINS "$ENV{HOME}/Library/Application Support/REAPER/UserPlugins")
else()
    set(REAPER_PLUGINS "$ENV{HOME}/.config/REAPER/UserPlugins")
endif()

add_custom_command(TARGET reaper_hello POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:reaper_hello> "${REAPER_PLUGINS}/"
)
