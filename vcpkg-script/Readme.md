# Instructions to build the third-party dependencies

## 0. Note
Due to different architectures, platforms, configurations, etc the script might need to be modified in order to be able to install the third-party dependencies.

## 1. Prerequisites

- Install Visual Studio
Current instructions are for VC2017 although some users are using VC2019
  - Install Windows 10.0 SDK
  - Install MFC and ATL support(x86, x64)
  - Install 2017 v141 for Desktop
  - After installing VS please check that the license has been properly updated:
  Help →Register Product.  If this shows a trial version then click "Check for an updated license".  You should see this:
    License: MSDN Subscription
    This product is licensed to: USER.NAME@samsung.com

- Install the 'English language pack' for Visual Studio. Otherwise vcpkg is unable to find some needed tools to build the libraries.

- Install git.
The git version control can be downloaded from https://git-scm.com/download/win
Follow the instructions on the link to install it.

The git bash app will be used to run the script.

- Set a proxy ip might be needed.
The default http proxy ip is set to the one in SRUK
Use the following options as a parameter for the script to set a different proxy ip:
-p | -httpProxy | --httpProxy To set the http proxy ip. It sets as well the https one
[-s | -httpsProxy | --httpsProxy] Optional. To set the https proxy ip if it's different than the http one.
[-n] Optional. Doesn't set any proxy.

## 2. Install VCPKG
- Create a folder where to install VCPKG. Better if this forder is outside of any DALi folder. i.e C:\Tools\VCPKG
- Copy the build-deps.sh file and all the patch files to the newly created folder.
- Open a Git bash shell and run the script.

The script will clone vcpkg from github apply all the patches, build all the dependencies and integrate with Visual Studio.
