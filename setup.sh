#!/bin/bash

sudo apt install python3
sudo apt install python3-pip -y

pip install -i https://pypi.tuna.tsinghua.edu.cn/simple pip -U
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
echo "pip换源完毕"

pip install pwntools
echo "pwntools安装完成"

sudo apt install gdb -y
echo "gdb安装完成"

sudo apt install git -y 
git clone https://github.com.cnpmjs.org/pwndbg/pwndbg
cd pwndbg






set -ex

# If we are a root in a container and `sudo` doesn't exist
# lets overwrite it with a function that just executes things passed to sudo
# (yeah it won't work for sudo executed with flags)
if ! hash sudo 2>/dev/null && whoami | grep root; then
    sudo() {
        ${*}
    }
fi

# Helper functions
linux() {
    uname | grep -i Linux &>/dev/null
}
osx() {
    uname | grep -i Darwin &>/dev/null
}

install_apt() {
    sudo apt-get update || true
    sudo apt-get install -y python3-setuptools libglib2.0-dev libc6-dbg

    if uname -m | grep x86_64 > /dev/null; then
        sudo dpkg --add-architecture i386 || true
        sudo apt-get update || true
        sudo apt-get install -y libc6-dbg:i386 || true
    fi
}

install_dnf() {
    sudo dnf update || true
    sudo dnf -y install gdb gdb-gdbserver python-devel python3-devel glib2-devel make
    sudo dnf -y debuginfo-install glibc
}

install_xbps() {
    sudo xbps-install -Su
    sudo xbps-install -Sy gdb gcc python-devel python3-devel glibc-devel make
    sudo xbps-install -Sy glibc-dbg
}

install_swupd() {
    sudo swupd update || true
    sudo swupd bundle-add gdb python3-basic make c-basic
}

install_zypper() {
    sudo zypper mr -e repo-debug
    sudo zypper refresh || true
    sudo zypper install -y gdb gdbserver python-devel python3-devel python2-pip glib2-devel make glibc-debuginfo

    if uname -m | grep x86_64 > /dev/null; then
        sudo zypper install -y glibc-32bit-debuginfo || true
    fi
}

install_emerge() {
    emerge --oneshot --deep --newuse --changed-use --changed-deps dev-lang/python dev-python/pip sys-devel/gdb
}

PYTHON=''
INSTALLFLAGS=''

if osx || [ "$1" == "--user" ]; then
    INSTALLFLAGS="--user"
else
    PYTHON="sudo "
fi

if linux; then
    distro=$(grep "^ID=" /etc/os-release | cut -d'=' -f2 | sed -e 's/"//g')

    case $distro in
        "ubuntu")
            install_apt
            ;;
        "fedora")
            install_dnf
            ;;
        "clear-linux-os")
            install_swupd
            ;;
        "opensuse-leap")
            install_zypper
            ;;
        "arch")
            echo "Install Arch linux using a community package. See:"
            echo " - https://www.archlinux.org/packages/community/any/pwndbg/"
            echo " - https://aur.archlinux.org/packages/pwndbg-git/"
            exit 1
            ;;
        "endeavouros")
            echo "Install pwndbg using a community package. See:"
            echo " - https://www.archlinux.org/packages/community/any/pwndbg/"
            echo " - https://aur.archlinux.org/packages/pwndbg-git/"
            exit 1
            ;;
        "manjaro")
            echo "Pwndbg is not available on Manjaro's repositories."
            echo "But it can be installed using Arch's AUR community package. See:"
            echo " - https://www.archlinux.org/packages/community/any/pwndbg/"
            echo " - https://aur.archlinux.org/packages/pwndbg-git/"
            exit 1
            ;;
        "void")
            install_xbps
            ;;
        "gentoo")
            install_emerge
            if ! hash sudo 2>/dev/null && whoami | grep root; then
                sudo() {
                    ${*}
                }
            fi
            ;;
        *) # we can add more install command for each distros.
            echo "\"$distro\" is not supported distro. Will search for 'apt' or 'dnf' package managers."
            if hash apt; then
                install_apt
            elif hash dnf; then
                install_dnf
            else
                echo "\"$distro\" is not supported and your distro don't have apt or dnf that we support currently."
                exit
            fi
            ;;
    esac
fi

if ! hash gdb; then
    echo "Could not find gdb in $PATH"
    exit
fi

# Update all submodules
git submodule update --init --recursive

# Find the Python version used by GDB.
PYVER=$(gdb -batch -q --nx -ex 'pi import platform; print(".".join(platform.python_version_tuple()[:2]))')
PYTHON+=$(gdb -batch -q --nx -ex 'pi import sys; print(sys.executable)')
PYTHON+="${PYVER}"

# Find the Python site-packages that we need to use so that
# GDB can find the files once we've installed them.
if linux && [ -z "$INSTALLFLAGS" ]; then
    SITE_PACKAGES=$(gdb -batch -q --nx -ex 'pi import site; print(site.getsitepackages()[0])')
    INSTALLFLAGS="--target ${SITE_PACKAGES}"
fi


# Install Python dependencies
sudo pip install ${INSTALLFLAGS} -Ur requirements.txt

# Load Pwndbg into GDB on every launch.
if ! grep pwndbg ~/.gdbinit &>/dev/null; then
    echo "source $PWD/gdbinit.py" >> ~/.gdbinit
fi




echo "pwndbg安装完成"

sudo apt install ruby -y
sudo apt install gem -y
gem sources --add https://mirrors.tuna.tsinghua.edu.cn/rubygems/ --remove https://rubygems.org/
echo "gem安装换源完成"

sudo gem install one_gadget
echo "one_gadget安装完成"
