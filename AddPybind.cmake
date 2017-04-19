
include(DownloadProject)
message(STATUS "Downloading PyBind11 if needed")
download_project(PROJ                pybind
                 GIT_REPOSITORY      https://github.com/pybind/pybind11.git
		         GIT_TAG             v2.1.0
                 UPDATE_DISCONNECTED 1
                 QUIET
)

# Exports pybind11::module
# And provides pybind11_add_module

add_subdirectory(${pybind_SOURCE_DIR} ${pybind_SOURCE_DIR})
