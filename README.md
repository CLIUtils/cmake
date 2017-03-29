# cmake
A set of cmake modules to assist in building code, with some tools for common general use packages and a few High Energy Physics packages.

The following is an example of a `CMakeLists.txt` file that will build a project using ROOT. Clone the repository to your project's cmake folder, or use `git submodule add` if you are already using git.

```cmake
cmake_minimum_required(VERSION 3.4)

project(MyProject CXX)

list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)

## This is CMake < 3.8 syntax:
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(ROOT 6 REQUIRED COMPONENTS Minuit)

add_executable(MyExecutable MySourceFile.cpp)
target_link_libraries(MyExecutable ROOT::ROOT ROOT::Minuit)
```

If you are using CMake 3.8 (not yet released), you could replace the C++11 selection code with the following line right at the end:
```cmake
target_compile_features(MyExecutable PUBLIC cxx_std_11)
```

