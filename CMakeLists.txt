cmake_minimum_required (VERSION 3.10)
project (ska-restapi C)

set(DEPS_STAGING_DIR ${PROJECT_SOURCE_DIR}/build-deps/staging)
set(DEPS_TARGET_DIR ${PROJECT_SOURCE_DIR}/build-deps/target)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/.built/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/.built/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/.built/lib/static)

if("${CMAKE_INSTALL_PREFIX}" STREQUAL "")
    message(STATUS "Override install dir")
    set(CMAKE_INSTALL_PREFIX ${DEPS_TARGET_DIR})
endif()

include_directories(${DEPS_STAGING_DIR}/include)
include_directories(${DEPS_STAGING_DIR}/usr/include)

link_directories(${DEPS_STAGING_DIR}/usr/lib)

add_subdirectory(src)

