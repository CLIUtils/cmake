
include(DownloadProject)
message(STATUS "Downloading CLI if needed")
download_project(PROJ                cli
                 GIT_REPOSITORY      https://github.com/CLIUtils/CLI11.git
		         GIT_TAG             master
                 UPDATE_DISCONNECTED 1
                 QUIET
)

add_subdirectory(${cli_SOURCE_DIR} ${cli_SOURCE_DIR})

