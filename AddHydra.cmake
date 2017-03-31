include(DownloadProject)
message(STATUS "Downloading Hydra if needed")
download_project(PROJ                hydra
                 GIT_REPOSITORY      https://github.com/AAAlvesJr/Hydra.git
		         GIT_TAG             master
                 UPDATE_DISCONNECTED 1
                 QUIET
)

if(NOT CMAKE_BUILD_TYPE STREQUAL Release)
    message(STATUS "You will get best perfomance from a release build!")
endif()

if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    set(HYDRA_CXX_FLAGS "-march=native")
elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Intel")
    set(HYDRA_CXX_FLAGS "-xHost;-march=native")
endif()

add_library(Hydra_Core INTERFACE)
target_include_directories(Hydra_Core INTERFACE ${hydra_SOURCE_DIR})
target_compile_features(Hydra_Core INTERFACE cxx_std_11)
set_target_properties(Hydra_Core
    PROPERTIES INTERFACE_POSITION_INDEPENDENT_CODE ON)
target_compile_options(Hydra_Core INTERFACE $<$<CONFIG:Release>:${HYDRA_CXX_FLAGS}>)
target_compile_definitions(Hydra_Core INTERFACE "THRUST_VARIADIC_TUPLE")


add_library(Hydra_CPP INTERFACE)
target_compile_definitions(Hydra_CPP INTERFACE "THRUST_HOST_SYSTEM=THRUST_HOST_SYSTEM_CPP"
                                     INTERFACE "THRUST_DEVICE_SYSTEM=THRUST_DEVICE_SYSTEM_CPP")
target_link_libraries(Hydra_CPP INTERFACE Hydra_Core)
add_library(Hydra::CPP ALIAS Hydra_CPP)


find_package(TBB)
if(TBB_FOUND)
    add_library(Hydra_TBB INTERFACE)
    target_compile_definitions(Hydra_TBB INTERFACE "THRUST_HOST_SYSTEM=THRUST_HOST_SYSTEM_TBB"
                                         INTERFACE "THRUST_DEVICE_SYSTEM=THRUST_DEVICE_SYSTEM_TBB")
    target_link_libraries(Hydra_TBB INTERFACE Hydra_Core tbb)
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
    target_link_libraries(Hydra_OMP INTERFACE Hydra_Core omp)
    add_library(Hydra::OMP ALIAS Hydra_OMP)
endif()

set(HYDRA_ARCH Auto CACHE STRING "The GPU Archetecture, can be Auto, All, Common, a number, or a name")

find_package(CUDA 8.0)
if(CUDA_FOUND)
    set(HYDRA_CUDA_FLAGS
         --expt-relaxed-constexpr; -ftemplate-backtrace-limit=0;
         --expt-extended-lambda; --relocatable-device-code=false;
         --generate-line-info)

     cuda_select_nvcc_arch_flags(ARCH_FLAGS ${HYDRA_ARCH})
     message(STATUS "Hydra is compiling for GPU arch: ${ARCH_FLAGS}")

    add_library(Hydra_CUDA INTERFACE)
    if(OPENMP_FOUND)
        target_compile_definitions(Hydra_CUDA INTERFACE "THRUST_HOST_SYSTEM=THRUST_HOST_SYSTEM_OMP")
        target_link_libraries(Hydra_OMP INTERFACE omp)
    elseif(TBB_FOUND)
        target_compile_definitions(Hydra_CUDA INTERFACE "THRUST_HOST_SYSTEM=THRUST_HOST_SYSTEM_TBB")
        target_link_libraries(Hydra_OMP INTERFACE tbb)
    else()
        target_compile_definitions(Hydra_CUDA INTERFACE "THRUST_HOST_SYSTEM=THRUST_HOST_SYSTEM_CPP")
    endif()
    target_compile_definitions(Hydra_CUDA INTERFACE "THRUST_DEVICE_SYSTEM=THRUST_DEVICE_SYSTEM_CUDA")
    target_compile_features(Hydra_CUDA INTERFACE cxx_std_11)
    target_compile_options(Hydra_CUDA INTERFACE "${HYDRA_CUDA_FLAGS}" "${ARCH_FLAGS}")
    target_compile_options(Hydra_CUDA INTERFACE
                             "-Xptxas=-fmad=true,-dlcm=cg,--opt-level=4")
    #target_link_libraries(Hydra_OMP INTERFACE Hydra_Core)
    target_include_directories(Hydra_CUDA INTERFACE ${hydra_SOURCE_DIR})
    target_compile_definitions(Hydra_CUDA INTERFACE "THRUST_VARIADIC_TUPLE")
    add_library(Hydra::CUDA ALIAS Hydra_CUDA)
endif()

macro(hydra_add_executable NAME) 
    add_library(${NAME} INTERFACE)
        
    add_executable(${NAME}_CPP ${ARGN})
    target_link_libraries(${NAME}_CPP PUBLIC Hydra::CPP ${NAME})

    if(OPENMP_FOUND)
        add_executable(${NAME}_OMP ${ARGN})
        target_link_libraries(${NAME}_OMP PUBLIC Hydra::OMP ${NAME})
    endif()

    if(TBB_FOUND)
        add_executable(${NAME}_TBB ${ARGN})
        target_link_libraries(${NAME}_TBB PUBLIC Hydra::TBB ${NAME})
    endif()

    if(CUDA_FOUND)
        enable_language(CUDA)
        foreach(F ${ARGN})
            configure_file(${F} ${F}.cu)
            list(APPEND CUDA_FILES ${F}.cu)
        endforeach()
        add_executable(${NAME}_CUDA ${CUDA_FILES})
        target_link_libraries(${NAME}_CUDA PUBLIC Hydra::CUDA ${NAME})
    endif()
endmacro()
