include(DownloadProject)
message(STATUS "Downloading Hydra as needed")
download_project(PROJ                hydra
                 GIT_REPOSITORY      https://github.com/AAAlvesJr/Hydra.git
		         GIT_TAG             master
                 UPDATE_DISCONNECTED 1
                 QUIET
)


if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    set(HYDRA_CXX_FLAGS ${HYDRA_CXX_FLAGS} "-march=native -O3")
elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Intel")
    set(HYDRA_CXX_FLAGS "-xHost -O3 -march=native")
elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    set(HYDRA_CXX_FLAGS "-O3")
else()
    set(HYDRA_CXX_FLAGS "-O3")
endif()

add_library(Hydra_Core INTERFACE)
target_include_directories(Hydra_Core INTERFACE ${hydra_SOURCE_DIR})
target_compile_options(Hydra_Core INTERFACE ${HYDRA_CXX_FLAGS})
target_compile_definitions(Hydra_Core INTERFACE "THRUST_VARIADIC_TUPLE")


add_library(Hydra_CPP INTERFACE)
target_compile_definitions(Hydra_CPP INTERFACE "THRUST_HOST_SYSTEM=THRUST_HOST_SYSTEM_CPP"
                                     INTERFACE "THRUST_DEVICE_SYSTEM=THRUST_DEVICE_SYSTEM_CPP")
target_link_libraries(Hydra_CPP INTERFACE Hydra_Core)



find_package(TBB)
if(TBB_FOUND)
    add_library(Hydra_TBB INTERFACE)
    target_compile_definitions(Hydra_TBB INTERFACE "THRUST_HOST_SYSTEM=THRUST_HOST_SYSTEM_TBB"
                                         INTERFACE "THRUST_DEVICE_SYSTEM=THRUST_DEVICE_SYSTEM_TBB")
    target_link_libraries(Hydra_TBB INTERFACE Hydra_Core tbb)
endif()


find_package(OpenMP)
if(OPENMP_FOUND)
    add_libarary(omp INTERFACE)
    target_compile_options(omp INTERFACE "${OpenMP_CXX_FLAGS}")
    target_link_libraries(omp INTERFACE "${OpenMP_CXX_FLAGS}")

    add_libarary(Hydra_OMP INTERFACE)
    target_compile_definitions(Hydra_OMP INTERFACE "THRUST_HOST_SYSTEM=THRUST_HOST_SYSTEM_OMP"
        INTERFACE "THRUST_DEVICE_SYSTEM=THRUST_DEVICE_SYSTEM_OMP")
    target_link_libraries(Hydra_OMP INTERFACE Hydra_Core omp)
endif()
