# This file adds OpenMP to your project if you are using Apple Clang.

option(APPLE_OMP_AUTOADD "Add OpenMP if using AppleClang" ON)

if("${APPLE_OMP_AUTOADD}" AND "${CMAKE_CXX_COMPILER_ID}" STREQUAL "AppleClang" AND NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS "9")

    message(STATUS "AppleClang >= 9.0 detected, adding OpenMP. Disable with -DAPPLE_OMP_AUTOADD=OFF")

    find_program(BREW NAMES brew)
    if(BREW)
        execute_process(COMMAND ${BREW} ls libomp RESULT_VARIABLE BREW_RESULT_CODE OUTPUT_QUIET ERROR_QUIET)
        if(BREW_RESULT_CODE)
            message(STATUS "GooFit supports OpenMP on Mac through Brew. Please run \"brew install cliutils/apple/libomp\"")
        else()
            execute_process(COMMAND ${BREW} --prefix libomp OUTPUT_VARIABLE BREW_LIBOMP_PREFIX OUTPUT_STRIP_TRAILING_WHITESPACE)
            set(OpenMP_CXX_FLAGS "-Xpreprocessor -fopenmp")
            set(OpenMP_CXX_LIB_NAMES "omp")
            set(OpenMP_omp_LIBRARY "${BREW_LIBOMP_PREFIX}/lib/libomp.dylib")
            include_directories("${BREW_LIBOMP_PREFIX}/include")
            message(STATUS "Using Homebrew libomp from ${BREW_LIBOMP_PREFIX}")
        endif()
    else()
        message(STATUS "GooFit supports OpenMP on Mac through Homebrew, installing Homebrew recommmended https://brew.sh")
    endif()
endif()
