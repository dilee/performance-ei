#!/bin/bash
# Copyright 2018 WSO2 Inc. (http://wso2.org)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ----------------------------------------------------------------------------
# Setup WSO2 Enterprise Integrator
# ----------------------------------------------------------------------------
# Make sure the script is running as root.
if [ "$UID" -ne "0" ]; then
    echo "You must be root to run $0. Try following"
    echo "sudo $0"
    exit 9
fi

export script_dir=$(dirname "$0")
export netty_host=""
export product=""
export user=""
export product_home="wso2ei"

function usageHelp() {
    echo "-n: The hostname of Netty Service."
    echo "-d: EI Product name. This should be either 'wso2ei' or 'wso2esb'"
    echo "-u: General user of the OS."
}
export -f usageHelp

while getopts "gp:w:o:hn:d:u:" opt; do
    case "${opt}" in
    n)
        netty_host=${OPTARG}
        ;;
    d)
        product=${OPTARG}
        ;;
    u)
        user=${OPTARG}
        ;;
    h)
        usageHelp
        exit 0
        ;;
    *)
        opts+=("-${opt}")
        [[ -n "$OPTARG" ]] && opts+=("$OPTARG")
        ;;
    esac
done
shift "$((OPTIND - 1))"

validate() {
    if [[ -z  $netty_host  ]]; then
        echo "Please provide netty host."
        exit 1
    fi

    if [[ -z $product ]]; then
        echo "Product name not provided."
        exit 1
    fi

    if [[ -z $user ]]; then
        echo "Please provide the username of the general os user"
        exit 1
    fi
}
export -f validate

if [[ $product == *"wso2esb"* ]]; then
    product_home="wso2esb"
fi

validate_command() {
    # Check whether given command exists
    # $1 is the command name
    # $2 is the package containing command
    if ! command -v $1 >/dev/null 2>&1; then
        echo "Please install $2 (sudo apt -y install $2)"
        exit 1
    fi
}

#Validate commands
validate_command unzip unzip

function setup() {
    export product_path="$HOME/$product"
    export product_name="Enterprise Integrator"

    if ! ls $product_path*.zip 1> /dev/null 2>&1; then
        echo "Please download the $product_name to $HOME"
        exit 1
    fi

    if [[ ! -d $product_path ]]; then
        echo "Extracting product $product"
        sudo -u $user unzip -q $product_path*.zip -d $HOME

        # Renaming the extracted EI directory to $product_home
        current_dir=$(pwd)
        cd $HOME
        for z in $product*; do
            if [ -d "$z" ]; then
                mv $z $product_home;
            fi
        done
        cd $current_dir

        echo "$product_name is extracted"
    else
        echo "$product_name is already extracted"
    fi

    capp_file=$script_dir/../ei/capp/EIPerformanceTestArtifacts-1.0.0.car

    if [ -f $capp_file ]; then
        echo "Deploying CAPP.."
        sudo -u $user cp $capp_file $product_path/repository/deployment/server/carbonapps/
        echo "CAPP Deployed.."
    else
       echo "CAPP is not available."
       exit 1
    fi

    # Add Netty Host to /etc/hosts
    echo "$netty_host netty" >> /etc/hosts

    echo "Completed.."
}
export -f setup

$script_dir/../setup/setup-common.sh "${opts[@]}" "$@"