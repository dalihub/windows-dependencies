<img src="https://dalihub.github.io/images/DaliLogo320x200.png">

# Table of Contents

  * [Build Instructions for MS Windows](#build-instructions)
      * [1. Build DALi and DALi Demo with Visual Studio](#1-build-with-visual-studio)
      * [2. Build DALi Demo with Visual Studio using DALi VCPKG ports](#2-build-with-vcpkg)
      * [3. Build DALi windows dependencies with CMake](#3-build-with-cmake)

# Build Instructions for MS Windows

## 1. Build DALi and DALi Demo with Visual Studio

### Step 1:
    Note the windows-dependencies repository has to be at the same level than DALi repositories in the filesystem hierarchy.
    If a DALi folder has not been created create one and move or clone the windows-dependencies repository to that folder.
    This repository contains the Visual Studio projects and solution.

    mkdir [YourDaliDir]
    cd [YourDaliDir]

    git clone https://github.com/dalihub/windows-dependencies.git
    
### Step2:
Clone all DALi repos and move to the correct branch:

    git clone ssh://[your account]@review.tizen.org:29418/platform/core/uifw/dali-core
    cd dali-core
    git checkout devel/master
    git pull
    cd ..

    git clone ssh://[your account]@review.tizen.org:29418/platform/core/uifw/dali-adaptor
    cd dali-adaptor
    git checkout devel/master
    git pull
    cd ..

    git clone ssh://[your account]@review.tizen.org:29418/platform/core/uifw/dali-toolkit
    cd dali-toolkit
    git checkout devel/master
    git pull
    cd ..

    git clone ssh://[your account]@review.tizen.org:29418/platform/core/uifw/dali-demo
    cd dali-demo
    git checkout devel/master
    git pull
    cd ..

### Step3:
Run the .bat files to config the enviorment. Note the dali-env folder has to be at the same level than dali-core, dali-adaptor, dali-toolkit and dali-demo in the filesystem hierarchy.

    windows-dependencies\prebuild.bat
    windows-dependencies\setenv.bat

### Step4:
Install vcpkg to build all the third-party dependecies: go to vcpkg-script, read the Readme.md file for more instructions,
open a git bash shell for MS Windows (installed with git) and execute the script to install vcpkg.

    build-deps.sh

More info on vcpkg can be found here https://github.com/microsoft/vcpkg and here https://docs.microsoft.com/en-us/cpp/build/vcpkg?view=vs-2019

### Step5:
Open **windows-dependencies\Solution\vc2017\DALi.sln**, set dali-demo as start-up project, build and run.

## 2. Build DALi Demo with Visual Studio using DALi VCPKG ports

### Step 1:
    Note the windows-dependencies repository has to be at the same level than DALi repositories in the filesystem hierarchy.
    If a DALi folder has not been created create one and move or clone the windows-dependencies repository to that folder.
    This repository contains the Visual Studio projects and solution.

    mkdir [YourDaliDir]
    cd [YourDaliDir]

    git clone https://github.com/dalihub/windows-dependencies.git

### Step2:
Run the .bat files to config the enviorment. Note the dali-env folder has to be at the same level than dali-core, dali-adaptor, dali-toolkit and dali-demo in the filesystem hierarchy.

    windows-dependencies\prebuild.bat
    windows-dependencies\setenv.bat

### Step3:
Install vcpkg to build all the third-party dependecies: go to vcpkg-script, read the Readme.md file for more instructions,
open a git bash shell for MS Windows (installed with git) and execute the script to install vcpkg.

    build-deps.sh

More info on vcpkg can be found here https://github.com/microsoft/vcpkg and here https://docs.microsoft.com/en-us/cpp/build/vcpkg?view=vs-2019


### Step4:
Open **windows-dependencies\Solution\vc2017\DALi-VCPKG.sln**, set dali-demo as start-up project, build and run.

## 3. Build DALi windows dependencies with CMake

DALi can be built with CMake. In this section there are the instructions to build the windows dependencies. See dali-core, dali-adaptor, dali-toolkit and dali-demo README.md files for more instructions.

  * Requirements
    It's required the version 3.12.2 of CMake and a Git Bash Shell.

  * Notes and troubleshoting:
    It should be possible to use the MS Visual studio Developer Command Prompt (https://docs.microsoft.com/en-us/dotnet/framework/tools/developer-command-prompt-for-vs) to build DALi from the command line.
    However, the CMake version installed with MS Visual Studio 2017 is a bit out of date and some VCPKG modules require a higher version.
    This instructions have been tested with CMake 3.12.2 on a Git Bash shell.

  * Define an environment variable to set the path to the VCPKG folder

    $ export VCPKG_FOLDER=C:/Users/username/Workspace/VCPKG_TOOL

  * Define an environment variable to set the path where DALi is going to be installed.

    $ export DALI_ENV_FOLDER=C:/Users/username/Workspace/dali-env

  * Execute the following commands to create the makefiles, build and install DALi.
  
    $ cmake -g Ninja . -DCMAKE_TOOLCHAIN_FILE=$VCPKG_FOLDER/vcpkg/scripts/buildsystems/vcpkg.cmake -DCMAKE_INSTALL_PREFIX=$DALI_ENV_FOLDER
    $ cmake --build . --target install


  * Options:
    - CMAKE_TOOLCHAIN_FILE  ---> Needed to find packages installed by VCPKG.
    - CMAKE_INSTALL_PREFIX  ---> Were DALi is installed.
