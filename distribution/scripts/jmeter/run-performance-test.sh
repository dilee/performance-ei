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
# Run Performance Tests for WSO2 Enterprise Integrator
# ----------------------------------------------------------------------------
script_dir=$(dirname "$0")
declare -a message_sizes=("500" "1024" "5120" "10240" "102400" "512000")
payload_size_postfix="B"

# Execute common script
. $script_dir/perf-test-common.sh -b $message_sizes

function initialize() {
    export ei_ssh_host=ei
    export ei_host=$(get_ssh_hostname $ei_ssh_host)
}
export -f initialize

product=wso2ei
heap_size=2

declare -A test_scenario0=(
    [name]="DirectProxy"
    [path]="/services/DirectProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario1=(
    [name]="CBRProxy"
    [path]="/services/CBRProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario2=(
    [name]="CBRSOAPHeaderProxy"
    [path]="/services/CBRSOAPHeaderProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario3=(
    [name]="CBRTransportHeaderProxy"
    [path]="/services/CBRTransportHeaderProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario4=(
    [name]="SecureProxy"
    [path]="/services/SecureProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="https"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario5=(
    [name]="XSLTEnhancedProxy"
    [path]="/services/XSLTEnhancedProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=false
    [skip]=false
)
declare -A test_scenario10=(
    [name]="XSLTProxy"
    [path]="/services/XSLTProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=true
)

function verifyRequestPayloads() {
    for i in "${message_sizes[@]}"
    do
        i+=$payload_size_postfix
        echo $i
        if ! ls requests/$i* 1> /dev/null 2>&1; then
            echo "Test payload for size: $i is missing"
            exit 1
        fi
    done
}

function before_execute_test_scenario() {
    local service_path=${scenario[path]}
    local protocol=${scenario[protocol]}
    local response_pattern="soapenv:Body"

    jmeter_params+=("host=$ei_host" "path=$service_path" "response_pattern=${response_pattern}")
    jmeter_params+=("response_size=${msize}B" "protocol=$protocol")

    if [[ "${scenario[name]}" == "SecureProxy" ]]; then
        jmeter_params+=("port=8243")
        jmeter_params+=("payload=$HOME/jmeter/requests/${msize}B_buyStocks_secure.xml")
    else
        jmeter_params+=("port=8280")
        jmeter_params+=("payload=$HOME/jmeter/requests/${msize}B_buyStocks.xml")
    fi

    echo "Starting Enterprise Integrator..."
    ssh $ei_ssh_host "./ei/ei-start.sh -p $product -s $heap_size"
}

function after_execute_test_scenario() {
    write_server_metrics ei $ei_ssh_host carbon
}

test_scenarios
