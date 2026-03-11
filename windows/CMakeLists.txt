# CMakeLists.txt for Windows

cmake_minimum_required(VERSION 3.14)
project(universal_file_previewer_plugin VERSION 0.0.1 LANGUAGES CXX)

add_library(${PROJECT_NAME} SHARED
  universal_file_previewer_plugin.cpp
)

set_target_properties(${PROJECT_NAME} PROPERTIES
  CXX_STANDARD 17
  CXX_STANDARD_REQUIRED ON
)

target_compile_definitions(${PROJECT_NAME} PUBLIC
  FLUTTER_PLUGIN_IMPL
)

target_link_libraries(${PROJECT_NAME} PRIVATE
  flutter_windows
)
