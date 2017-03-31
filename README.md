# CMake 3 Tools
A set of [CMake] modules to assist in building code, with some tools for common general use packages and a few High Energy Physics packages. These tools are built around modern CMake (See [The Ultimate Guide to Modern CMake]), which allows clean, simple user CMake files. Although modern CMake is still a little odd in a few places, it is relatively clean and descriptive.

## Installing CMake 3 anywhere

[CMake] is incredibly easy to install. The following line will install the latest 3.7.2 on Linux to your `.local` directory:

```bash
wget -qO- "https://cmake.org/files/v3.7/cmake-3.7.2-Linux-x86_64.tar.gz" | tar --strip-components=1 -xz -C ~/.local
```
If you don't want to put this in the `.local` directory, simply replace with any pre-existing directory, and add `<directory>/bin` to your `PATH`.
See the other files in [CMake downloads] to find similar installers for Mac and Windows, as well as the latest development versions.


## AddGoogleTest

This is a downloader for [GoogleTest], based on the excellent [DownloadProject] tool. Downloading a copy for each project is the recommended way to use GoogleTest (so much so, in fact, that they have disabled the automatic CMake install target), so this respects that design decision. This method downloads the project at configure time, so that IDE's correctly find the libraries. Using it is simple:

```cmake
cmake_minimum_required(VERSION 3.4)
project(MyProject CXX)
list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)

enable_testing() # Must be in main file

include(AddGoogleTest) # Could be in /tests/CMakeLists.txt
add_executable(SimpleTest SimpleTest.cu)
add_gtest(SimpleTest)
```

> Note: `add_gtest` is just a macro that adds `gtest`, `gmock`, and `gtest_main`, and then runs `add_test` to create a test with the same name:
> ```cmake
> target_link_libraries(SimpleTest gtest gmock gtest_main)
> add_test(SimpleTest SimpleTest)
> ```

## FindROOT

The following is an example of a `CMakeLists.txt` file that will build a project using [ROOT]. Clone the repository to your project's cmake folder, or use `git submodule add` if you are already using git. The `root-config` tool should be in your PATH; if is not, please run `source /my/root/install/bin/thisroot.sh` to set your PATH and other useful variables. Then your CMakeLists.txt should look like:

```cmake
cmake_minimum_required(VERSION 3.4)
project(MyProject CXX)
list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)

find_package(ROOT 6 REQUIRED COMPONENTS Minuit)

add_executable(MyExecutable MySourceFile.cpp)
target_link_libraries(MyExecutable ROOT::ROOT ROOT::Minuit)
```

In most cases, you should specify the C++ version (ROOT sets the compiler and linker flags needed, so you can ignore it if using a ROOT target). In CMake < 3.8, that looks like this:

```cmake
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
```

If you are using CMake 3.8 (not yet released), you could replace the C++11 selection code with the following line right at the end:
```cmake
target_compile_features(MyExecutable PUBLIC cxx_std_11)
```

## AddHydra

See the [example repository][HydraUser] (under development) for an example of the CMake 3.8 AddHydra module.

[CMake]:           https://cmake.org
[CMake downloads]: https://cmake.org/download/
[The Ultimate Guide to Modern CMake]: https://rix0r.nl/blog/2015/08/13/cmake-guide/
[GoogleTest]:      https://github.com/google/googletest
[ROOT]:            https://root.cern.ch
[DownloadProject]: https://github.com/Crascit/DownloadProject
[HydraUser]:       https://github.com/henryiii/HydraExample.git
