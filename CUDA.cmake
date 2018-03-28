# This file should be included with include(CUDA)
#
# It adds:
#
#   cuda_protect_flags(NAME LANG)
#     Protect the flags on the target with a LANG requirement
#
#
#   cuda_convert_flags(NAME)
#     Pass the flags on the target to the compiler in case of CUDA.
#
#
#
#   cuda_arch_detect([ARCHES]
#                    FLAGS OUTVAR
#                    NAMES OUTVAR
#                    QUIET)
#
#


function(CUDA_CONVERT_FLAGS EXISTING_TARGET)
    get_property(old_flags TARGET ${EXISTING_TARGET} PROPERTY INTERFACE_COMPILE_OPTIONS)
    if(NOT "${old_flags}" STREQUAL "")
        string(REPLACE ";" "," CUDA_flags "${old_flags}")
        set_property(TARGET ${EXISTING_TARGET} PROPERTY INTERFACE_COMPILE_OPTIONS
            "$<$<BUILD_INTERFACE:$<NOT:$<COMPILE_LANGUAGE:CUDA>>>:${old_flags}>$<$<BUILD_INTERFACE:$<COMPILE_LANGUAGE:CUDA>>:-Xcompiler=${CUDA_flags}>"
            )
    endif()
endfunction()

function(CUDA_PROTECT_FLAGS EXISTING_TARGET)
    get_property(old_flags TARGET ${EXISTING_TARGET} PROPERTY INTERFACE_COMPILE_OPTIONS)
    if(NOT "${old_flags}" STREQUAL "")
        set_property(TARGET ${EXISTING_TARGET} PROPERTY INTERFACE_COMPILE_OPTIONS
            "$<$<BUILD_INTERFACE:$<NOT:$<COMPILE_LANGUAGE:CUDA>>>:${old_flags}>"
            )
    endif()
endfunction()

include("${CMAKE_CURRENT_LIST_DIR}/select_compute_arch.cmake")

function(CUDA_DETECT_ARCH)
    set(oneValueArgs NVCC_FLAGS READABLE)
    cmake_parse_arguments(
        CDA
        ""
        "${oneValueArgs}"
        ""
        ${ARGN})
    
    cuda_select_nvcc_arch_flags(CDA_val)

    if(NOT CDA_FLAGS STREQUAL "")
        string(REPLACE ";" " " CDA_flags_val "${CDA_val}")
        set(${CDA_NVCC_FLAGS} "${CDA_flags_val}" PARENT_SCOPE)
    endif()

    if(NOT CDA_READABLE STREQUAL "")
        set(${CDA_READABLE} "${CDA_val_readable}" PARENT_SCOPE)
    endif()
endfunction()
