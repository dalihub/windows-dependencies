cmake_minimum_required( VERSION 3.0 )

SET( name "dali-windows-dependencies" )
 
PROJECT( ${name} LANGUAGES CXX )

# Define options to CMake

OPTION(ENABLE_DEBUG          "Enable Debug" OFF)

# Set up compiler definitions

IF(CMAKE_BUILD_TYPE MATCHES Debug)
  MESSAGE( STATUS "CMAKE_BUILD_TYPE: " Debug )
  SET( ENABLE_DEBUG ON )
ELSE()
  MESSAGE( STATUS "CMAKE_BUILD_TYPE: " Release )
ENDIF()

IF( ENABLE_DEBUG )
  ADD_DEFINITIONS( "-DDEBUG_ENABLED" )
ENDIF()

SET( ROOT_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/..)
SET( SOURCE_DIR ${ROOT_SRC_DIR}/src )
SET( INCLUDE_DIR  ${ROOT_SRC_DIR}/include )
SET( LIBTYPE STATIC )

SET( SOURCE_FILES
  ${SOURCE_DIR}/extern-definitions.cpp
)

SET( INCLUDE_HEADERS
  ${INCLUDE_DIR}/dali-windows-dependencies.h
)

SET( INCLUDE_DALI_HEADERS
  ${INCLUDE_DIR}/dali/extern-definitions.h
  ${INCLUDE_DIR}/dali/preprocessor-definitions.h
)

INCLUDE_DIRECTORIES(
  ${INCLUDE_DIR}
  ${INCLUDE_DIR}/dali
)

ADD_LIBRARY( ${name} ${LIBTYPE} ${SOURCE_FILES} )
 
SET_TARGET_PROPERTIES( ${name} PROPERTIES VERSION 1.0 )
 
TARGET_LINK_LIBRARIES( ${name} )

# Deployment folder should come from spec file or command line:
SET( PREFIX ${CMAKE_INSTALL_PREFIX})

# Set up the include dir
SET( INCLUDE_DIR $ENV{includedir} )
IF( NOT INCLUDE_DIR )
  SET( INCLUDE_DIR ${CMAKE_INSTALL_INCLUDEDIR} )
ENDIF()
IF( NOT INCLUDE_DIR )
  SET( INCLUDE_DIR ${PREFIX}/include )
ENDIF()

INSTALL(FILES ${INCLUDE_HEADERS} DESTINATION include )
INSTALL(FILES ${INCLUDE_DALI_HEADERS} DESTINATION include/dali )

INSTALL( TARGETS ${name}
  EXPORT ${name}-targets
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
)

INSTALL( EXPORT ${name}-targets
  NAMESPACE ${name}::
  FILE ${name}-targets.cmake
  DESTINATION share/${name}
)

file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/${name}-config.cmake "
  include(CMakeFindDependencyMacro)
  include(\${CMAKE_CURRENT_LIST_DIR}/${name}-targets.cmake)
")
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${name}-config.cmake DESTINATION share/${name})
