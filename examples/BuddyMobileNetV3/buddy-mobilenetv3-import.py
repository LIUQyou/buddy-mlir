# ===- buddy-mobilenetv3-import.py ---------------------------------------------
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
# ===---------------------------------------------------------------------------
#
# This is the MobileNet V3 model AOT importer.
#
# ===---------------------------------------------------------------------------

import os
from pathlib import Path
import argparse
import numpy as np
import torch
import torchvision.models as models
from torch._inductor.decomposition import decompositions as inductor_decomp

from buddy.compiler.frontend import DynamoCompiler
from buddy.compiler.graph import GraphDriver
from buddy.compiler.graph.transform import simply_fuse
from buddy.compiler.ops import tosa

# Parse command-line arguments.
parser = argparse.ArgumentParser(description="MobileNetV3 model AOT importer")
parser.add_argument(
    "--output-dir", 
    type=str, 
    default="./", 
    help="Directory to save output files."
)
args = parser.parse_args()

# Ensure output directory exists.
output_dir = Path(args.output_dir)
output_dir.mkdir(parents=True, exist_ok=True)

# Retrieve the MobileNet V3 model path.
model_path = os.path.dirname(os.path.abspath(__file__))

model = models.mobilenet_v3_small(
    weights=models.MobileNet_V3_Small_Weights.IMAGENET1K_V1, pretrained=True
)
model = model.eval()

# Remove the num_batches_tracked attribute.
for layer in model.modules():
    if isinstance(layer, torch.nn.BatchNorm2d):
        if hasattr(layer, "num_batches_tracked"):
            del layer.num_batches_tracked

# Initialize Dynamo Compiler with specific configurations as an importer.
dynamo_compiler = DynamoCompiler(
    primary_registry=tosa.ops_registry,
    aot_autograd_decomposition=inductor_decomp,
)
data = torch.randn([1, 3, 224, 224])
# Import the model into MLIR module and parameters.
with torch.no_grad():
    graphs = dynamo_compiler.importer(model, data)
assert len(graphs) == 1
graph = graphs[0]
params = dynamo_compiler.imported_params[graph]
pattern_list = [simply_fuse]
graphs[0].fuse_ops(pattern_list)
driver = GraphDriver(graphs[0])
driver.subgraphs[0].lower_to_top_level_ir()
# Write generated files to the specified output directory.
with open(output_dir / "subgraph0.mlir", "w") as module_file:
    print(driver.subgraphs[0]._imported_module, file=module_file)
with open(output_dir / "forward.mlir", "w") as module_file:
    print(driver.construct_main_graph(True), file=module_file)

# Export parameters.
float32_param = np.concatenate(
    [
        param.detach().numpy().reshape([-1])
        for param in params
        if param.dtype == torch.float32
    ]
)
float32_param.tofile(output_dir / "arg0.data")
