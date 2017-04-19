
include(DownloadProject)
message(STATUS "Downloading PyBind11 if needed")
download_project(PROJ                minuit2
                 GIT_REPOSITORY      https://github.com/GooFit/Minuit2.git
		         GIT_TAG             master
                 UPDATE_DISCONNECTED 1
                 QUIET
)

add_subdirectory(${minuit2_SOURCE_DIR} ${minuit2_SOURCE_DIR})
