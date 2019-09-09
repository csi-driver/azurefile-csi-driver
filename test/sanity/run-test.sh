#!/bin/bash

# Copyright 2019 The Kubernetes Authors.
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

set -euo pipefail

function cleanup {
  echo "pkill -f azurefileplugin"
  pkill -f azurefileplugin
  rm -rf csi-test
}

function install_csi_sanity_bin {
  git clone https://github.com/kubernetes-csi/csi-test.git -b v1.1.0
  pushd csi-test/cmd/csi-sanity
  make install
  popd
}

install_csi_sanity_bin
endpoint='unix:///tmp/csi.sock'
nodeid='CSINode'
if [[ "$#" -gt 0 ]]; then
  nodeid="$1"
fi

sudo _output/azurefileplugin --endpoint "$endpoint" --nodeid "$nodeid" -v=5 &
trap cleanup EXIT

# Skip "should fail when requesting to create a snapshot with already existing name and different SourceVolumeId.", because azurefile cannot specify the snapshot name.
echo "Begin to run sanity test..."
sudo csi-sanity --ginkgo.v --csi.endpoint="$endpoint" -ginkgo.skip='should fail when requesting to create a snapshot with already existing name and different SourceVolumeId.'
