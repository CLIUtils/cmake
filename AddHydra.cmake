# - Add HYDRA
# Add the HYDRA headers. Set hydra_SOURCE_DIR to remove download, or HYDRA_URL and HYDRA_TAG to control the download location.
# Set HYDRA_MT_HOST to ON to activate using OpenMP or TBB as the host with CUDA device.
#
# Creates the following interface targets (if OMP, TBB, and/or CUDA are found):
# 
# Hydra::CPP
# Hydra::TBB
# Hydra::OMP
# Hydra::CUDA (requires CUDA language to be activated)
#
# hydra_add_executable(MyProg prog.cpp) will add a MyProg master target and
# that will be inherited by the sub-targets for each platform. Use add on this target
# to control all four. The sub targets will be MyProg_CPP, MyProg_TBB, MyProg_OMP, and MyProg_CUDA.

cmake_minimum_required(VERSION 3.8)

include(DownloadProject)

if(NOT hydra_SOURCE_DIR)
    set(HYDRA_URL "https://github.com/MultithreadCorner/Hydra.git" CACHE STRING "The URL of the git repo") 
    set(HYDRA_TAG "master" CACHE STRING "The branch/tag to get, branch should be proceded by -b")

    message(STATUS "Downloading Hydra if needed")
    download_project(PROJ                hydra
                     GIT_REPOSITORY      ${HYDRA_URL}
                     GIT_TAG             ${HYDRA_TAG}
                     UPDATE_DISCONNECTED 1
                     QUIET
    )
endif()

if(NOT CMAKE_BUILD_TYPE STREQUAL Release)
    message(STATUS "You will get best perfomance from a release build!")
endif()

set(HYDRA_CXX_FLAGS "-march=native")

add_library(Hydra_Core INTERFACE)
target_include_directories(Hydra_Core INTERFACE ${hydra_SOURCE_DIR})
target_compile_features(Hydra_Core INTERFACE cxx_std_11)
set_target_properties(Hydra_Core
    PROPERTIES INTERFACE_POSITION_INDEPENDENT_CODE ON)
target_compile_definitions(Hydra_Core INTERFACE "THRUST_VARIADIC_TUPLE")


add_library(Hydra_CPU INTERFACE)
target_link_libraries(Hydra_CPU INTERFACE Hydra_Core)
target_compile_options(Hydra_CPU INTERFACE $<$<CONFIG:Release>:${HYDRA_CXX_FLAGS}>)


add_library(Hydra_CPP INTERFACE)
target_compile_definitions(Hydra_CPP INTERFACE "THRUST_HOST_SYSTEM=THRUST_HOST_SYSTEM_CPP"
                                     INTERFACE "THRUST_DEVICE_SYSTEM=THRUST_DEVICE_SYSTEM_CPP")
target_link_libraries(Hydra_CPP INTERFACE Hydra_CPU)
add_library(Hydra::CPP ALIAS Hydra_CPP)


find_package(TBB)
if(TBB_FOUND)
    add_library(Hydra_TBB INTERFACE)
    target_compile_definitions(Hydra_TBB INTERFACE "THRUST_HOST_SYSTEM=THRUST_HOST_SYSTEM_TBB"
                                         INTERFACE "THRUST_DEVICE_SYSTEM=THRUST_DEVICE_SYSTEM_TBB")
    target_link_libraries(Hydra_TBB INTERFACE Hydra_CPU tbb)
add_library(Hydra::TBB ALIAS Hydra_TBB)
endif()


find_package(OpenMP)
if(OPENMP_FOUND)
    add_library(omp INTERFACE)
    target_compile_options(omp INTERFACE "${OpenMP_CXX_FLAGS}")
    target_link_libraries(omp INTERFACE "${OpenMP_CXX_FLAGS}")

    add_library(Hydra_OMP INTERFACE)
    target_compile_definitions(Hydra_OMP INTERFACE "THRUST_HOST_SYSTEM=THRUST_HOST_SYSTEM_OMP"
        INTERFACE "THRUST_DEVICE_SYSTEM=THRUST_DEVICE_SYSTEM_OMP")
    target_link_libraries(Hydra_OMP INTERFACE Hydra_CPU omp)
    add_library(Hydra::OMP ALIAS Hydra_OMP)
endif()

set(HYDRA_ARCH Auto CACHE STRING "The GPU Archetecture, can be Auto, All, Common, a number, or a name")
set(HYDRA_MT_HOST OFF CACHE BOOL "Multithreaded host for cuda compilation")

option(HYDRA_USE_CUDA "Turn off to disable CUDA search" ON)

if(HYDRA_USE_CUDA)
find_package(CUDA 8.0)
if(CUDA_FOUND)
    set(HYDRA_CUDA_FLAGS
         --expt-relaxed-constexpr; -ftemplate-backtrace-limit=0;
         --expt-extended-lambda; --relocatable-device-code=false;
         --generate-line-info)

    cuda_select_nvcc_arch_flags(ARCH_FLAGS ${HYDRA_ARCH})
    string(REPLACE ";" " " ARCH_FLAGS "${ARCH_FLAGS}")
    message(STATUS "Hydra is compiling for GPU arch: ${ARCH_FLAGS_readable}")
    message(STATUS "Hydra flags to be added: ${ARCH_FLAGS}")
    list(APPEND CMAKE_CUDA_FLAGS "${ARCH_FLAGS}")
    

    add_library(Hydra_CUDA INTERFACE)
    if(HYDRA_MT_HOST AND OPENMP_FOUND)
        target_compile_definitions(Hydra_CUDA INTERFACE "THRUST_HOST_SYSTEM=THRUST_HOST_SYSTEM_OMP")
        target_link_libraries(Hydra_OMP INTERFACE omp)
    elseif(HYDRA_MT_HOST AND TBB_FOUND)
        target_compile_definitions(Hydra_CUDA INTERFACE "THRUST_HOST_SYSTEM=THRUST_HOST_SYSTEM_TBB")
        target_link_libraries(Hydra_OMP INTERFACE tbb)
    else()
        target_compile_definitions(Hydra_CUDA INTERFACE "THRUST_HOST_SYSTEM=THRUST_HOST_SYSTEM_CPP")
    endif()
    target_compile_definitions(Hydra_CUDA INTERFACE "THRUST_DEVICE_SYSTEM=THRUST_DEVICE_SYSTEM_CUDA")
    target_compile_options(Hydra_CUDA INTERFACE
                             "${HYDRA_CUDA_FLAGS}"
                             "-Xptxas=-fmad=true,-dlcm=cg,--opt-level=4")
    target_link_libraries(Hydra_CUDA INTERFACE Hydra_Core)
    add_library(Hydra::CUDA ALIAS Hydra_CUDA)
endif()
endif()

macro(hydra_add_executable MYNAME) 
    add_library(${MYNAME} INTERFACE)
        
    add_executable(${MYNAME}_CPP ${ARGN})
    target_link_libraries(${MYNAME}_CPP PUBLIC Hydra::CPP ${MYNAME})

    if(OPENMP_FOUND)
        add_executable(${MYNAME}_OMP ${ARGN})
        target_link_libraries(${MYNAME}_OMP PUBLIC Hydra::OMP ${MYNAME})
    endif()

    if(TBB_FOUND)
        add_executable(${MYNAME}_TBB ${ARGN})
        target_link_libraries(${MYNAME}_TBB PUBLIC Hydra::TBB ${MYNAME})
    endif()

    if(CUDA_FOUND)
        enable_language(CUDA)
        set(CUDA_FILES "")
        foreach(F ${ARGN})
            configure_file(${F} ${F}.cu)
            list(APPEND CUDA_FILES ${F}.cu)
        endforeach()
        add_executable(${MYNAME}_CUDA ${CUDA_FILES})
        target_link_libraries(${MYNAME}_CUDA PUBLIC Hydra::CUDA ${MYNAME})
    endif()
endmacro()
