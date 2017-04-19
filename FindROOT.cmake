# - Finds ROOT instalation
# This module sets up ROOT information
# It defines:
# ROOT_FOUND          If the ROOT is found
# ROOT_INCLUDE_DIR    PATH to the include directory
# ROOT_INCLUDE_DIRS   PATH to the include directories (not cached)
# ROOT_LIBRARIES      Most common libraries
# ROOT_<name>_LIBRARY Full path to the library <name>
# ROOT_LIBRARY_DIR    PATH to the library directory
# ROOT_DEFINITIONS    Compiler definitions and flags
# ROOT_LINK_FLAGS     Linker flags
#
# The modern CMake 3 imported targets are also created:
# ROOT::ROOT (Most common libraries)
# ROOT::<name> (The library with name)
#
# Updated by K. Smith (ksmith37@nd.edu) to properly handle
#  dependencies in ROOT_GENERATE_DICTIONARY
# Updated by H. Schreiner (hschrein@cern.ch) to support CMake 3 syntax

find_program(ROOT_CONFIG_EXECUTABLE root-config
  PATHS $ENV{ROOTSYS}/bin)

if(ROOT_CONFIG_EXECUTABLE)
    execute_process(
        COMMAND ${ROOT_CONFIG_EXECUTABLE} --prefix
        OUTPUT_VARIABLE ROOTSYS
        OUTPUT_STRIP_TRAILING_WHITESPACE)

    execute_process(
        COMMAND ${ROOT_CONFIG_EXECUTABLE} --version
        OUTPUT_VARIABLE ROOT_VERSION
        OUTPUT_STRIP_TRAILING_WHITESPACE)

    execute_process(
        COMMAND ${ROOT_CONFIG_EXECUTABLE} --incdir
        OUTPUT_VARIABLE ROOT_INCLUDE_DIR
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    set(ROOT_INCLUDE_DIRS ${ROOT_INCLUDE_DIR})

    execute_process(
        COMMAND ${ROOT_CONFIG_EXECUTABLE} --libdir
        OUTPUT_VARIABLE ROOT_LIBRARY_DIR
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    set(ROOT_LIBRARY_DIRS ${ROOT_LIBRARY_DIR})

    execute_process(
        COMMAND ${ROOT_CONFIG_EXECUTABLE} --cflags
        OUTPUT_VARIABLE ROOT_DEFINITIONS
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    string(REGEX REPLACE "(^|[ ]*)-I[^ ]*" "" ROOT_DEFINITIONS ${ROOT_DEFINITIONS})
    set(ROOT_DEF_LIST ${ROOT_DEFINITIONS})
    separate_arguments(ROOT_DEF_LIST)

    execute_process(
        COMMAND ${ROOT_CONFIG_EXECUTABLE} --ldflags
        OUTPUT_VARIABLE ROOT_LINK_FLAGS
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    set(ROOT_LINK_LIST ${ROOT_LINK_FLAGS})
    separate_arguments(ROOT_LINK_LIST)

    # Needed because ROOT on Mac does not use Mac conventions
    set(CMAKE_SHARED_LIBRARY_SUFFIX .so)

    file(GLOB ROOT_LIBFILELIST
        LIST_DIRECTORIES false
        RELATIVE "${ROOT_LIBRARY_DIR}"
        "${ROOT_LIBRARY_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}*${CMAKE_SHARED_LIBRARY_SUFFIX}")
    
    if(NOT ROOT_LIBFILELIST)
        message(FATAL_ERROR "ROOT libraries not found at ${ROOT_LIBRARY_DIR}")
    endif()

    set(ROOT_ALLLIBS "")
    foreach(_file ${ROOT_LIBFILELIST})
        string(REGEX REPLACE "^${CMAKE_SHARED_LIBRARY_PREFIX}" "" _newer ${_file})
        string(REGEX REPLACE "${CMAKE_SHARED_LIBRARY_SUFFIX}$" "" _newest ${_newer})
        list(APPEND ROOT_ALLLIBS ${_newest})
    endforeach()

    set(ROOT_CORELIBS Core RIO Net Hist Graf Graf3d Gpad Tree Rint Postscript Matrix Physics MathCore Thread MultiProc)

    add_library(ROOT::ROOT INTERFACE IMPORTED)

    set(ROOT_LIBRARIES)
    foreach(_cpt ${ROOT_ALLLIBS})
      find_library(ROOT_${_cpt}_LIBRARY ${_cpt} HINTS ${ROOT_LIBRARY_DIR})
      if(ROOT_${_cpt}_LIBRARY)
        mark_as_advanced(ROOT_${_cpt}_LIBRARY)
        add_library(ROOT::${_cpt} SHARED IMPORTED)
        set_target_properties(ROOT::${_cpt} PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${ROOT_INCLUDE_DIRS}"
            IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
            IMPORTED_LOCATION "${ROOT_${_cpt}_LIBRARY}"
            INTERFACE_COMPILE_OPTIONS "${ROOT_DEF_LIST}"
            INTERFACE_LINK_LIBRARIES "${ROOT_LINK_LIST}")
      endif()
    endforeach()

    set(targetlist)
    foreach(_cpt ${ROOT_CORELIBS} ${ROOT_FIND_COMPONENTS})
      if(ROOT_${_cpt}_LIBRARY)
        list(APPEND ROOT_LIBRARIES "${ROOT_${_cpt}_LIBRARY}")
        list(REMOVE_ITEM ROOT_FIND_COMPONENTS ${_cpt})
        list(APPEND targetlist ROOT::${_cpt})
      endif()
    endforeach()

    set_target_properties(ROOT::ROOT PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${ROOT_INCLUDE_DIRS}")
    set_target_properties(ROOT::ROOT PROPERTIES
        INTERFACE_LINK_LIBRARIES "${targetlist}")
    unset(targetlist)

    list(REMOVE_DUPLICATES ROOT_LIBRARIES)


    execute_process(
      COMMAND ${ROOT_CONFIG_EXECUTABLE} --features
      OUTPUT_VARIABLE _root_options
      OUTPUT_STRIP_TRAILING_WHITESPACE)
    foreach(_opt ${_root_options})
      set(ROOT_${_opt}_FOUND TRUE)
    endforeach()
endif()
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(ROOT DEFAULT_MSG ROOT_CONFIG_EXECUTABLE
    ROOTSYS ROOT_VERSION ROOT_INCLUDE_DIR ROOT_LIBRARIES ROOT_LIBRARY_DIR)

mark_as_advanced(ROOT_CONFIG_EXECUTABLE)

include(CMakeParseArguments)
find_program(ROOTCINT_EXECUTABLE rootcint PATHS $ENV{ROOTSYS}/bin)
find_program(GENREFLEX_EXECUTABLE genreflex PATHS $ENV{ROOTSYS}/bin)
find_package(GCCXML)

#----------------------------------------------------------------------------
# function ROOT_GENERATE_DICTIONARY( dictionary
#                                    header1 header2 ...
#                                    LINKDEF linkdef1 ...
#                                    OPTIONS opt1...)
function(ROOT_GENERATE_DICTIONARY dictionary)
  CMAKE_PARSE_ARGUMENTS(ARG "" "" "LINKDEF;OPTIONS" "" ${ARGN})
  #---Get the list of include directories------------------
  get_directory_property(incdirs INCLUDE_DIRECTORIES)
  set(includedirs)
  foreach( d ${incdirs})
     set(includedirs ${includedirs} -I${d})
  endforeach()
  #---Get the list of header files-------------------------
  set(headerfiles)
  foreach(fp ${ARG_UNPARSED_ARGUMENTS})
    if(${fp} MATCHES "[*?]") # Is this header a globbing expression?
      file(GLOB files ${fp})
      foreach(f ${files})
        if(NOT f MATCHES LinkDef) # skip LinkDefs from globbing result
          set(headerfiles ${headerfiles} ${f})
        endif()
      endforeach()
    else()
      find_file(headerFile ${fp} PATHS ${incdirs})
      set(headerfiles ${headerfiles} ${headerFile})
      unset(headerFile CACHE)
    endif()
  endforeach()
  #---Get LinkDef.h file------------------------------------
  set(linkdefs)
  foreach( f ${ARG_LINKDEF})
    find_file(linkFile ${f} PATHS ${incdirs})
    set(linkdefs ${linkdefs} ${linkFile})
    unset(linkFile CACHE)
  endforeach()
  #---call rootcint------------------------------------------
  add_custom_command(OUTPUT ${dictionary}.cxx ${dictionary}.h
                     COMMAND ${ROOTCINT_EXECUTABLE} -cint -f  ${dictionary}.cxx
                                          -c ${ARG_OPTIONS} ${includedirs} ${headerfiles} ${linkdefs}
                     DEPENDS ${headerfiles} ${linkdefs} VERBATIM)
endfunction()

#----------------------------------------------------------------------------
# function REFLEX_GENERATE_DICTIONARY(dictionary
#                                     header1 header2 ...
#                                     SELECTION selectionfile ...
#                                     OPTIONS opt1...)
function(REFLEX_GENERATE_DICTIONARY dictionary)
  CMAKE_PARSE_ARGUMENTS(ARG "" "" "SELECTION;OPTIONS" "" ${ARGN})
  #---Get the list of header files-------------------------
  set(headerfiles)
  foreach(fp ${ARG_UNPARSED_ARGUMENTS})
    file(GLOB files ${fp})
    if(files)
      foreach(f ${files})
        set(headerfiles ${headerfiles} ${f})
      endforeach()
    else()
      set(headerfiles ${headerfiles} ${fp})
    endif()
  endforeach()
  #---Get Selection file------------------------------------
  if(IS_ABSOLUTE ${ARG_SELECTION})
    set(selectionfile ${ARG_SELECTION})
  else()
    set(selectionfile ${CMAKE_CURRENT_SOURCE_DIR}/${ARG_SELECTION})
  endif()
  #---Get the list of include directories------------------
  get_directory_property(incdirs INCLUDE_DIRECTORIES)
  set(includedirs)
  foreach( d ${incdirs})
    set(includedirs ${includedirs} -I${d})
  endforeach()
  #---Get preprocessor definitions--------------------------
  get_directory_property(defs COMPILE_DEFINITIONS)
  foreach( d ${defs})
   set(definitions ${definitions} -D${d})
  endforeach()
  #---Nanes and others---------------------------------------
  set(gensrcdict ${dictionary}.cpp)
  if(MSVC)
    set(gccxmlopts "--gccxmlopt=\"--gccxml-compiler cl\"")
  else()
    #set(gccxmlopts "--gccxmlopt=\'--gccxml-cxxflags -m64 \'")
    set(gccxmlopts)
  endif()
  #set(rootmapname ${dictionary}Dict.rootmap)
  #set(rootmapopts --rootmap=${rootmapname} --rootmap-lib=${libprefix}${dictionary}Dict)
  #---Check GCCXML and get path-----------------------------
  if(GCCXML)
    get_filename_component(gccxmlpath ${GCCXML} PATH)
  else()
    message(WARNING "GCCXML not found. Install and setup your environment to find 'gccxml' executable")
  endif()
  #---Actual command----------------------------------------
  add_custom_command(OUTPUT ${gensrcdict} ${rootmapname}
                     COMMAND ${GENREFLEX_EXECUTABLE} ${headerfiles} -o ${gensrcdict} ${gccxmlopts} ${rootmapopts} --select=${selectionfile}
                             --gccxmlpath=${gccxmlpath} ${ARG_OPTIONS} ${includedirs} ${definitions}
                     DEPENDS ${headerfiles} ${selectionfile})
endfunction()

mark_as_advanced(ROOTCINT_EXECUTABLE GENREFLEX_EXECUTABLE) 
