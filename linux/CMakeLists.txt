# CMakeLists.txt for Linux

cmake_minimum_required(VERSION 3.10)
project(universal_file_previewer_plugin LANGUAGES CXX)

add_library(${PROJECT_NAME} SHARED
  universal_file_previewer_plugin.cc
)

apply_standard_settings(${PROJECT_NAME})

target_link_libraries(${PROJECT_NAME} PRIVATE
  flutter_linux
)
