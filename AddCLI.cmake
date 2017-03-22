
include(DownloadProject)
message(STATUS "Downloading CLI if needed")
download_project(PROJ                cli
                 GIT_REPOSITORY      https://github.com/henryiii/CLI11.git
		         GIT_TAG             1.8.2      
                 UPDATE_DISCONNECTED 1
                 QUIET
)

include_directories("${cli_SOURCE_DIR}/include")
