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
Run the .bat files to config the enviorment

    windows-dependencies\prebuild.bat
    windows-dependencies\setenv.bat

Step5:
Open **windows-dependencies\Solution\dali.sln**, build and run.
