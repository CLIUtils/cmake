
include(DownloadProject)
message(STATUS "Downloading Rang if needed")
download_project(PROJ                rang
                 GIT_REPOSITORY      https://github.com/agauniyal/rang.git
		         GIT_TAG             master
                 UPDATE_DISCONNECTED 1
                 QUIET
)

add_library(rang INTERFACE)
target_include_directories(rang INTERFACE ${rang_SOURCE_DIR}/include)

add_library(rang::rang ALIAS rang) # Exported target syntax
