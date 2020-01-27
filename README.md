<img src="https://dalihub.github.io/images/DaliLogo320x200.png">

# Table of Contents

  * [Build Instructions for MS Windows](#build-instructions)
      * [1. Build DALi and DALi Demo with Visual Studio](#1-build-with-visual-studio)
      * [2. Build DALi Demo with Visual Studio using DALi VCPKG ports](#2-buil-with-vcpkg)

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
