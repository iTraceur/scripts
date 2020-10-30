#!/usr/bin/env sh

INSTALL_VERSION=""

LATEST=0

[[ -f /etc/redhat-release ]] && unalias -a

[[ -z $(echo $SHELL|grep zsh) ]] && ENV_FILE=".bashrc" || ENV_FILE=".zshrc"

RED="31m"
GREEN="32m"
YELLOW="33m"
BLUE="36m"
FUCHSIA="35m"

colorEcho(){
    COLOR=$1
    echo -e "\033[${COLOR}${@:2}\033[0m"
}

checkSys() {
    [ $(id -u) != "0" ] && { colorEcho ${RED} "Error: You must be root to run this script"; exit 1; }

    if [[ `command -v apt-get` ]]; then
        PACKAGE_MANAGER='apt-get'
    elif [[ `command -v dnf` ]]; then
        PACKAGE_MANAGER='dnf'
    elif [[ `command -v yum` ]]; then
        PACKAGE_MANAGER='yum'
    else
        colorEcho $RED "Not support OS!"
        exit 1
    fi

    [[ -z `echo $PATH|grep /usr/local/bin` ]] && { echo 'export PATH=$PATH:/usr/local/bin' >> /etc/profile; source /etc/profile; }
}

#安装依赖
installDependencies(){
    ${PACKAGE_MANAGER} update -y

    if [[ ${PACKAGE_MANAGER} == 'yum' || ${PACKAGE_MANAGER} == 'dnf' ]]; then
        ${PACKAGE_MANAGER} groupinstall -y "Development tools"
        ${PACKAGE_MANAGER} install -y epel-release tk-devel xz-devel gdbm-devel sqlite-devel bzip2-devel readline-devel zlib-devel openssl-devel libffi-devel unzip
    else
        ${PACKAGE_MANAGER} install -y build-essential
        ${PACKAGE_MANAGER} install -y uuid-dev tk-dev liblzma-dev libgdbm-dev libsqlite3-dev libbz2-dev libreadline-dev zlib1g-dev libncursesw5-dev libssl-dev libffi-dev unzip
    fi

    ${PACKAGE_MANAGER} install git wget python-pip python-virtualenv -y

    [ ! -d ~/.pip ] && mkdir ~/.pip
    echo -e '[global]\nindex-url = https://mirrors.aliyun.com/pypi/simple/\n[install]\ntrusted-host = mirrors.aliyun.com' > ~/.pip/pip.conf
}

installPyenv(){
    if [ ! -d ~/.pyenv ]; then
        if [ -f /tmp/pyenv-master.zip ]; then
          unzip /tmp/pyenv-master.zip && mv ./pyenv-master ~/.pyenv
        else
          git clone https://github.com/pyenv/pyenv.git ~/.pyenv
        fi
        echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/$ENV_FILE
        echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/$ENV_FILE
        echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/$ENV_FILE
        exec "$SHELL"
        source ~/$ENV_FILE
    fi

    [ ! -d ~/.pyenv/cache ] && mkdir ~/.pyenv/cache
}

checkVersion(){
    if [ -d ~/.pyenv/versions/$INSTALL_VERSION ]; then
        return 0
    fi
    return 1
}

downloadPackage(){
    PYTHON_PACKAGE="Python-$INSTALL_VERSION.tar.xz"
    wget https://cdn.npm.taobao.org/dist/python/$INSTALL_VERSION/$PYTHON_PACKAGE -P /tmp/$PYTHON_PACKAGE
    if [[ $? != 0 ]]; then
        colorEcho ${RED} "Fail download $PYTHON_PACKAGE version python!"
        rm -f /tmp/$PYTHON_PACKAGE
        exit 1
    fi
    mv /tmp/$PYTHON_PACKAGE ~/.pyenv/cache
}


install(){
    installDependencies
    installPyenv

    checkVersion
    if [[ $? != 0 ]]; then
        export PYENV_PYTHON_MIRROR_URL="https://cdn.npm.taobao.org/dist/python/"
        export PYTHON_PYTHON_MIRROR_URL="https://cdn.npm.taobao.org/dist/python/"

        downloadPackage
        pyenv install $INSTALL_VERSION
    fi
}

help(){
    echo "bash python-installer.sh [-h|--help|version]"
    echo "  -h, --help           Show help"
    echo "  version              Version of python "
    return 0
}

main(){
    checkSys

    INSTALL_VERSION=`curl -s https://npm.taobao.org/mirrors/python/|grep "/mirrors/python/"|egrep -o "python\/$VERSION"|sed s/"python\/"//g|tail -n1`

    if [[ -z $INSTALL_VERSION ]]; then
        colorEcho $RED "Python version $VERSION does not exist!"
    else
        install
    fi
}

if [[ $# > 0 ]]; then
    KEY="$1"
    case $KEY in
        -h|--help)
        help
        exit
        ;;
        *)
        VERSION="$KEY"
        echo -e "Prepare install python $(colorEcho ${BLUE} $KEY)..\n"
        ;;
    esac
else
    help
    exit
fi

main
