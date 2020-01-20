DALi Windows Backend
====================

Follow the steps below to build the DALi Windows backend:

Step 1:

    mkdir [YourDaliDir]
    cd [YourDaliDir]

Step2:
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

Step3:
Download the windows dependencies repo which also contains the Visual Studio projects and solution:

    git clone https://github.com/dalihub/windows-dependencies.git

Step4:
Run the .bat files to config the enviorment. Note the dali-env folder has to be at the same level than dali-core, dali-adaptor, dali-toolkit and dali-demo in the filesystem hierarchy.

    windows-dependencies\prebuild.bat
    windows-dependencies\setenv.bat

Step5:
Install vcpkg to build all the third-party dependecies: go to vcpkg-script, read the Readme.md file for more instructions,
open a git bash shell for MS Windows (installed with git) and execute the script to install vcpkg.

    build-deps.sh

More info on vcpkg can be found here https://github.com/microsoft/vcpkg and here https://docs.microsoft.com/en-us/cpp/build/vcpkg?view=vs-2019

Step6:
Open **windows-dependencies\Solution\vc2017\DALi.sln**, set dali-demo as start-up project, build and run.
