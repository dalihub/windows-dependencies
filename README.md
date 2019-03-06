Steps for using Dali demo Windows backend

Step1:
mkdir [YourDaliDir]
cd [YourDaliDir]

Step2:
Download the code of dali
git clone ssh://[your account]@review.tizen.org:29418/platform/core/uifw/dali-core
cd dali-core
git checkout devel/master
git pull
git fetch https://review.tizen.org/gerrit/p/platform/core/uifw/dali-core refs/changes/68/199068/2 && git cherry-pick FETCH_HEAD
cd ..

git clone ssh://[your account]@review.tizen.org:29418/platform/core/uifw/dali-adaptor
cd dali-adaptor
git checkout devel/master
git pull
git fetch https://review.tizen.org/gerrit/p/platform/core/uifw/dali-adaptor refs/changes/09/172009/67 && git cherry-pick FETCH_HEAD
cd ..

git clone ssh://[your account]@review.tizen.org:29418/platform/core/uifw/dali-toolkit
cd dali-toolkit
git checkout devel/master
git pull
git fetch https://review.tizen.org/gerrit/p/platform/core/uifw/dali-toolkit refs/changes/01/199101/1 && git cherry-pick FETCH_HEAD
cd ..

git clone ssh://[your account]@review.tizen.org:29418/platform/core/uifw/dali-demo
cd dali-demo
git checkout devel/master
git pull
cd ..

Step3:
Download the VS projects and solution
git clone https://github.com/AdunFang/windows-dependencies.git
git checkout AddThirdPartLib

Step4:
Run the .bat files to config the enviorment
windows-dependencies\prebuild.bat and windows-dependencies\setenv.bat

Step5:
Open the windows-dependencies\Solution\dali.sln, build and run.
