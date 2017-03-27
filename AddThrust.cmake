# Downloads thrust 
#


include(DownloadProject)
message(STATUS "Downloading Thrust if needed")
download_project(PROJ                thrust
		         GIT_REPOSITORY      https://github.com/thrust/thrust.git
		         GIT_TAG             1.8.2      
                 UPDATE_DISCONNECTED 1
                 QUIET
)

set(THRUST_INCLUDE_DIRS "${thrust_SOURCE_DIR}")

