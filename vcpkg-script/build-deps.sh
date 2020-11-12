#!/bin/bash

http_proxy_ip="106.1.18.35:8080"
https_proxy_ip=$http_proxy_ip

pkg_list=( dali2-toolkit )

patch_files=( 	'../[VCPKG]_0001_Fix_proxy_access.patch'
      '../[VCPKG-angle]_0001_Apply_Fix_glInvalidateFramebuffer_crash.patch'
      '../[VCPKG-getopt]_0001_Apply_Fix_extern_c.patch'
      '../[VCPKG-libjpeg-turbo]_0001_Apply_Fix_fill_jpeg_buffer_cb.patch'
      '../[VCPKG-pthreads]_0001_Apply_Fix_define_timespec.patch'
  )

# install packages
function fn_install_pkgs()
{
	export VCPKG_DEFAULT_TRIPLET=${1}
	for i in "${pkg_list[@]}"; do
		./vcpkg install ${i}
	done
}

# export packages
function fn_export_pkgs()
{
	exp_pkgs=""
	export VCPKG_DEFAULT_TRIPLET=${1}
	for i in "${pkg_list[@]}"; do
#		exp_pkgs="${exp_pkgs} \"${i}\" \"${i}\:x64-windows\""
		exp_pkgs="${exp_pkgs} ${i} ${i}:x64-windows"
	done
	echo ./vcpkg export --dry-run --triplet x86-windows ${exp_pkgs} --zip
	./vcpkg export --triplet x86-windows ${exp_pkgs} --zip
}

function fn_patch_files()
{
	for i in "${patch_files[@]}"; do
		patch -p1 -l -i ${i}
	done
}

echo "This script install vcpkg and the third-party dependencies used by watch3d."
echo "The default http proxy ip is set to " $http_proxy_ip
echo "Use the following options to set a different proxy ip"
echo " -p | -httpProxy | --httpProxy       To set the http proxy ip. It sets as well the https one"
echo "[-s | -httpsProxy | --httpsProxy]    Optional. To set the https proxy ip if it's different than the http one."
echo "[-n]                                 Optional. Doesn't set any proxy."

use_proxy=true;
while true; do
  case "$1" in
    -p | -httpProxy | --httpProxy) http_proxy_ip="$2"; https_proxy_ip=$http_proxy_ip; shift 2 ;;
    -s | -httpsProxy | --httpsProxy) https_proxy_ip="$2"; shift 2 ;;
    -n) use_proxy=false; shift; break ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

#set up proxy
if "$use_proxy" = "true" ; then
  export VCPKG_PROXY="${http_proxy_ip}"
  export HTTP_PROXY="http://${http_proxy_ip}/"
  export HTTPS_PROXY="http://${https_proxy_ip}/"
fi
env

git clone https://github.com/dalihub/vcpkg.git
cd vcpkg

fn_patch_files

./bootstrap-vcpkg.bat -disableMetrics # -disableMetrics used to opt out of usage metrics reporting.
./vcpkg integrate install

# build for x86
fn_install_pkgs x86-windows
# list the installed packages
echo List the installed packages
./vcpkg list

# build for x64
fn_install_pkgs x64-windows
# list the installed packages
echo List the installed packages
./vcpkg list


echo export the installed packages
fn_export_pkgs
