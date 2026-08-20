# Digit Classification FFN — Detailed Handover

## Purpose

This document hands the project to a fresh chat without losing technical context. The project is a SystemVerilog MNIST digit-classification accelerator. The immediate state is: individual RTL blocks are verified, a NumPy-only training/reference model has reached **91.96% test accuracy** in an RTL-matched integer inference flow, and the next chat must resolve one small diagnostic-cell unpacking error before progressing to RTL/Python end-to-end comparison.

---

## Non-negotiable collaboration preferences

The user is actively learning and writes the RTL themselves.

- Do **not** edit RTL, testbenches, notebooks, or any project files unless the user explicitly asks you to do so.
- Before proposing an edit or asking permission, explain: what you want to do, why it is needed, and what result it will establish.
- Do **not** create new files without explaining the file name, contents, purpose, and expected benefit beforehand. The user may prefer to create files themselves.
- Teach rather than dump a finished solution. When providing Python code, explain what every line does.
- The user sometimes prefers 2–3 manageable code cells together rather than one cell at a time, but does not want a giant code dump.
- Do not overstate results on a resume or LinkedIn. A performance number is only claimable for RTL after the exact exported weights/biases/shifts are loaded and an RTL-vs-reference comparison passes.
- Preserve user changes and unrelated Vivado-generated files. Never reset/clean the worktree.

One earlier mistake occurred: the assistant modified the pooling RTL after an ambiguous instruction. The user objected; those assistant edits were reverted. Do not repeat this. Guide/review the user’s edits instead.

---

## Project location and implementation

Project root:

`E:\VerilogProjects\Digit_Classification_FFN`

Known simulator/testbench location:

`E:\VerilogProjects\Digit_Classification_FFN\Digit_Classification_FFN.srcs\sim_1\new`

An assistant-created notebook exists:

`E:\VerilogProjects\Digit_Classification_FFN\rtl_matched_mnist_model.ipynb`

The user did **not** want a prebuilt notebook and instead worked interactively in a fresh Google Colab notebook. Do not modify the local notebook unless explicitly asked.

The user is using NumPy 2.0.2 in Colab and intentionally does not want TensorFlow/PyTorch for this project. Use NumPy, Matplotlib, and Python standard-library modules only unless the user later changes that decision.

---

## RTL architecture

End-to-end architecture:

```text
28×28 uint8 MNIST image
    ↓
2×2 average pooling, stride 2
    ↓
14×14 = 196 pooled values
    ↓
Dense-1: 196 inputs → 32 neurons
    ↓
ReLU + arithmetic right shift + signed-16-bit saturation
    ↓
Dense-2: 32 inputs → 10 neurons
    ↓
ReLU + arithmetic right shift + signed-16-bit saturation
    ↓
select_max → predicted digit 0–9
```

### Intended numeric types

- Original MNIST pixels: unsigned, `0…255` (`uint8`).
- Pooling arithmetic: pixels should remain unsigned while being summed/averaged. Pool output is 16-bit and used as a signed value by the later MAC layer; its numeric values are nonnegative.
- Weights: signed 8-bit (`int8`), because weights can be negative.
- Neuron inputs: signed 16-bit.
- Neuron accumulator: signed 32-bit.
- Biases: signed int8, added after the MAC accumulation in the current neuron design.
- ReLU outputs: signed 16-bit, although nonnegative after ReLU.

### `neuron.sv`

The neuron consumes one signed 16-bit input and one signed int8 weight per clock, multiplies and accumulates internally, then adds its signed int8 bias. It has a signed 32-bit accumulator. Its MAC operation is sequential across the input vector.

### `dense_layer.sv`

The dense layer instantiates an array of neuron modules.

- It is **parallel across neurons**: 32 neuron instances in Dense-1 and 10 in Dense-2.
- Each individual neuron serializes its MACs internally: one MAC per clock.
- `layer_done` is registered/synchronous. It asserts one clock after the combined neuron completion condition is observed. This was intentionally retained because it creates a clean synchronous handoff and avoids combinational done glitches.

For a 4-input testbench instance, the registered completion therefore occurs after the fifth relevant clock edge rather than directly on the fourth MAC edge. This is correct for the current synchronous interface.

### `relu.sv`

The user updated the ReLU behavior. The verified logic is conceptually:

```systemverilog
module relu #(parameter WIDTH = 8, SHIFT = 6)(
    input  signed [4*WIDTH-1:0] data_in,
    output signed [2*WIDTH-1:0] data_out
);
    localparam IN_WIDTH  = 4*WIDTH;
    localparam OUT_WIDTH = 2*WIDTH;
    localparam signed [IN_WIDTH-1:0] MAX_OUTPUT = (1 <<< (OUT_WIDTH-1)) - 1;

    wire signed [IN_WIDTH-1:0] relu_value;
    wire signed [IN_WIDTH-1:0] scaled_value;

    assign relu_value   = (data_in > 0) ? data_in : '0;
    assign scaled_value = relu_value >>> SHIFT;
    assign data_out = (scaled_value > MAX_OUTPUT)
                    ? MAX_OUTPUT[OUT_WIDTH-1:0]
                    : scaled_value[OUT_WIDTH-1:0];
endmodule
```

For `WIDTH=8`, `data_out` is signed 16-bit. Its largest positive value is `2^15 − 1 = 32767`.

With `SHIFT=6`:

- largest unsaturated input: `2^21 − 1 = 2,097,151`; it right-shifts/truncates to `32767`;
- first saturating input: `2^21 = 2,097,152`; it right-shifts to `32768`, then clamps to `32767`.

### `select_max.sv`

The select-max module chooses the greatest score. It uses `>=`, so equal scores select the **highest index** (the final tied digit), not the lowest index. The Python reference must implement this exact tie rule.

`layer_done` remains high until reset in this module; this was observed and should be considered if the top-level interface is refined later.

### Average pooling redesign

Original pooling was serial. The user redesigned it as **14 row-parallel processing elements**, each producing one pooled row per cycle. The entire 14×14 pooled image is produced in 14 active cycles.

The user considered alternatives:

- fully combinational parallel pooling: fastest, but substantial fanout/routing and a very large combinational cone;
- four chunks / 49 cycles: moderate parallelism;
- 14 row PEs / 14 cycles: selected compromise, much lower latency while remaining structurally manageable.

The relevant synchronization discussion:

- `pool_en` currently functions as a registered active/busy state rather than merely a simple enable.
- Making downstream start/done signals synchronous is deliberate: it gives a stable full data cycle at the module boundary and avoids coupling modules through combinational completion paths.
- If semantics are revisited later, a clearer name such as `pool_busy` could be considered, but no rename is required now.

The user temporarily tried nonblocking assignments in an internal pooling calculation; it made output behavior worse and they reverted to their original blocking assignments. They also corrected extension of `in1…in4` to 16 bits because `pool_out` is 16-bit. Pooling simulation now works.

---

## RTL verification already completed

All these results are user-run simulations and passed.

### Average pooling layer

`tb_avg_pooling_layer.sv` passed after the 14-PE row-parallel redesign. Earlier there was a one-sample/output-check offset; this was reasoned about in terms of registered timing and subsequently resolved. The latest pooling simulation works.

### Neuron

`tb_neuron.sv` passed:

```text
PASS: neuron operation and timing working correctly.
PASS: neuron resets correctly for next MAC operation.
```

Simulation finished at 66 ns.

### Dense layer

The testbench initially produced `X` outputs because reset was not connected and initialization/assertion details were incorrect. The key corrections were:

- connect `.reset(reset)` on the DUT;
- initialize arrays cleanly (assignment patterns `'{...}` are preferred over packed concatenations for simulator portability);
- fix a `26` typo and use logical `||` where appropriate;
- expect registered `layer_done` one edge later than the final neuron completion.

The user fixed it and it passed:

```text
PASS: neuron operation and timing working correctly.
PASS: layer resets correctly for next inference operation.
```

Simulation finished at 76 ns.

### ReLU

Passed all tests:

```text
PASS: negative value clamps to zero | input=-1, output=0
PASS: zero remains zero | input=0, output=0
PASS: 63 shifted by 6 becomes zero | input=63, output=0
PASS: 64 shifted by 6 becomes one | input=64, output=1
PASS: 65 truncates to one | input=65, output=1
PASS: largest non-saturated output | input=2097151, output=32767
PASS: first saturated output | input=2097152, output=32767
PASS: maximum positive accumulator saturates | input=2147483647, output=32767
PASS: all ReLU tests completed.
```

### Select max

Passed all tests:

```text
PASS: normal maximum | selected digit=1
PASS: tie selects highest index | selected digit=2
PASS: all-negative signed comparison | selected digit=3
PASS: all select_max tests completed.
```

### Old full-NN smoke test

An earlier full top-level `NN_tb` run produced predictions for labels 0–9:

```text
RTL outputs: 0, 1, 2, 3, 4, 6, 6, 7, 8, 9
```

Only the sample for digit 5 was predicted as 6. `NN_done=1` for all transactions. This was a smoke test only, not an accuracy benchmark, because it used the old embedded RTL weights.

Approximate transaction interval changed from roughly 8.66 µs with serial pooling to roughly 5.02 µs after the 14-row-PE pooling redesign: about a 42% latency reduction in that testbench measurement. Treat this as an early simulation observation, not a formal performance claim until cycle accounting is finalized.

---

## Colab / NumPy model: completed learning sequence

The user was taught the model cell-by-cell. The following is the exact conceptual progression and important helper functions. The new chat should continue to explain code rather than paste a full notebook.

### Data acquisition and parsing

MNIST IDX gzip files were downloaded from the canonical Yann LeCun storage URLs using `urllib.request.urlretrieve` and a `Path('mnist_data')` folder in Colab.

Files:

- `train-images-idx3-ubyte.gz`
- `train-labels-idx1-ubyte.gz`
- `t10k-images-idx3-ubyte.gz`
- `t10k-labels-idx1-ubyte.gz`

Parsed observations:

```text
Train image magic number: 2051
Train image count: 60000
Dimensions: 28 × 28
train_images shape: (60000, 28, 28), dtype uint8, range 0…255

Train label magic number: 2049
Train label count: 60000
```

The first displayed sample looked like a 5, and its label was 5.

Generic readers were later created conceptually:

```python
def read_mnist_images(file_path):
    # opens gzip, reads IDX header, converts remaining bytes to uint8,
    # returns shape (count, rows, columns)

def read_mnist_labels(file_path):
    # opens gzip, reads IDX header, converts remaining bytes to uint8,
    # returns shape (count,)
```

### RTL-style average pooling

For a single image:

```python
image_16 = train_images[image_index].astype(np.uint16)
pooled_image = (
    image_16[0::2, 0::2]
    + image_16[0::2, 1::2]
    + image_16[1::2, 0::2]
    + image_16[1::2, 1::2]
) >> 2
```

The `uint16` cast is essential so summing four 8-bit pixels cannot overflow before shifting. The user manually confirmed the first 2×2 block average against the pooled `[0,0]` value.

Batch version:

```python
def rtl_average_pool_batch(images):
    images_16 = images.astype(np.uint16)
    pooled = (
        images_16[:, 0::2, 0::2]
        + images_16[:, 0::2, 1::2]
        + images_16[:, 1::2, 0::2]
        + images_16[:, 1::2, 1::2]
    ) >> 2
    return pooled
```

Results:

```text
pooled_train_images shape: (60000, 14, 14)
train_vectors shape: (60000, 196)
Single-image and batch pooling match: True
```

Flattening was verified with row-major NumPy behavior: pooled row 3, column 5 maps to flat index `3*14+5 = 47`.

### Float training representation

The training model uses normalized float inputs, while the RTL-matched model uses original integer pooled pixels:

```python
train_inputs = train_vectors.astype(np.float32) / 255.0
test_inputs = test_vectors.astype(np.float32) / 255.0
```

The model intentionally started with **zero biases** for the cleanest first hardware-matched baseline:

```python
B1_q = np.zeros(32, dtype=np.int8)
B2_q = np.zeros(10, dtype=np.int8)
```

One-hot labels:

```python
def one_hot(labels, number_of_classes=10):
    encoded = np.zeros((len(labels), number_of_classes), dtype=np.float32)
    encoded[np.arange(len(labels)), labels] = 1.0
    return encoded
```

### Float network structure

Weights were initialized with He initialization:

```python
rng = np.random.default_rng(28)
input_features = 196
hidden_neurons = 32
output_neurons = 10

W1 = rng.normal(0, 1, size=(196, 32)).astype(np.float32) * np.sqrt(2 / 196)
W2 = rng.normal(0, 1, size=(32, 10)).astype(np.float32) * np.sqrt(2 / 32)
```

Float forward pass:

```python
def relu_float(values):
    return np.maximum(values, 0.0)

def forward_model(inputs):
    z1 = inputs @ W1
    a1 = relu_float(z1)
    z2 = a1 @ W2
    a2 = relu_float(z2)
    return z1, a1, z2, a2
```

Softmax was used only for training/loss, not for RTL inference:

```python
def softmax(scores):
    shifted = scores - scores.max(axis=1, keepdims=True)
    exp_scores = np.exp(shifted)
    return exp_scores / exp_scores.sum(axis=1, keepdims=True)
```

The user asked why `e^x` is used. Explanation already given: exponentiation makes all values positive and increases separation between higher/lower scores; normalization makes the results sum to one. RTL does not need softmax because `argmax` preserves ordering.

Last-tie argmax matching `select_max.sv`:

```python
def rtl_argmax_last_tie(scores):
    reversed_scores = scores[::-1]
    reversed_max_index = np.argmax(reversed_scores)
    return len(scores) - 1 - reversed_max_index

def argmax_last_tie_batch(scores):
    reversed_scores = scores[:, ::-1]
    reversed_max_indices = np.argmax(reversed_scores, axis=1)
    return scores.shape[1] - 1 - reversed_max_indices
```

### Training and backpropagation

The user only knew gradient descent initially. Backpropagation was explained as repeated chain rule used to calculate the gradient needed by gradient descent.

Cross entropy:

```python
def cross_entropy(probabilities, targets):
    safe_probabilities = np.clip(probabilities, 1e-9, 1.0)
    losses = -np.sum(targets * np.log(safe_probabilities), axis=1)
    return losses.mean()
```

Initial loss was `2.3369668`.

The manual chain was taught:

```text
probabilities − targets
→ output ReLU derivative
→ gradient W2
→ backpropagate through W2
→ hidden ReLU derivative
→ gradient W1
```

One update reduced loss from `2.3369668` to `2.2921824`.

Batch training helper (no biases):

```python
def train_one_batch(inputs, targets, W1, W2, learning_rate):
    batch_size = len(inputs)
    z1 = inputs @ W1
    a1 = relu_float(z1)
    z2 = a1 @ W2
    a2 = relu_float(z2)
    probabilities = softmax(a2)
    loss = cross_entropy(probabilities, targets)

    gradient_z2 = ((probabilities - targets) / batch_size) * (z2 > 0)
    gradient_W2 = a1.T @ gradient_z2
    gradient_a1 = gradient_z2 @ W2.T
    gradient_z1 = gradient_a1 * (z1 > 0)
    gradient_W1 = inputs.T @ gradient_z1

    W1 = W1 - learning_rate * gradient_W1
    W2 = W2 - learning_rate * gradient_W2
    return W1, W2, loss
```

`train_one_epoch` shuffles using `rng.permutation`, loops through mini-batches, calls `train_one_batch`, accumulates batch losses, and returns mean epoch loss.

### Float model results

After the first epoch:

```text
Mean training loss: 0.6293845
Training accuracy: 86.50166666666667%
Test accuracy: 87.38%
```

After ten total epochs:

```text
Epoch 02 | loss=0.4646 | train=88.41% | test=89.16%
Epoch 03 | loss=0.4058 | train=89.25% | test=90.04%
Epoch 04 | loss=0.3742 | train=89.81% | test=90.29%
Epoch 05 | loss=0.3537 | train=90.30% | test=90.79%
Epoch 06 | loss=0.3388 | train=90.59% | test=91.24%
Epoch 07 | loss=0.3271 | train=90.85% | test=91.45%
Epoch 08 | loss=0.3171 | train=91.07% | test=91.71%
Epoch 09 | loss=0.3087 | train=91.33% | test=91.90%
Epoch 10 | loss=0.3011 | train=91.55% | test=91.95%
```

The plot showed steadily decreasing loss and steadily increasing training/test accuracy. Test accuracy was slightly higher than train accuracy; that is not inherently concerning here and no obvious overfitting appeared.

Important stale-variable incident: an old `test_accuracy` variable from epoch 1 (`0.8738`) was accidentally printed during quantization. It was corrected by recomputing final accuracy. The valid final float baseline is:

```text
Final float-model accuracy: 91.95%
```

---

## Weight quantization

Symmetric per-layer int8 quantization was used:

```python
INT8_MAX = 127

def quantize_weights_to_int8(weights):
    largest_magnitude = np.abs(weights).max()
    scale = INT8_MAX / largest_magnitude
    scaled = weights * scale
    clipped = np.clip(scaled, -INT8_MAX, INT8_MAX)
    quantized = np.rint(clipped).astype(np.int8)
    reconstructed = quantized.astype(np.float32) / scale
    return quantized, scale, reconstructed

W1_q, W1_scale, W1_reconstructed = quantize_weights_to_int8(W1)
W2_q, W2_scale, W2_reconstructed = quantize_weights_to_int8(W2)
```

Observed ranges and errors:

```text
W1 float min/max: -0.5484097 / 0.73464364
W1 largest magnitude: 0.73464364
W1 quantization scale: 172.87292
W1 int8 range: -95 to 127
W1 max quantization error: 0.0028918236

W2 float min/max: -1.2326572 / 1.3058618
W2 largest magnitude: 1.3058618
W2 quantization scale: 97.253784
W2 int8 range: -120 to 127
W2 max quantization error: 0.0051330924
```

A reconstructed-weight float inference model (`forward_quantized_float`) was created and gave:

```text
Final float-model accuracy: 0.9195
Int8-weight float-model accuracy: 0.9196
Accuracy change from weight quantization: +0.0001 fraction = +0.01 percentage points
```

This means weight quantization itself had essentially no measurable negative impact in this run.

---

## RTL-matched integer inference reference

The key integer dense helper:

```python
def rtl_dense_integer(inputs, weights, biases):
    accumulator_64 = (
        inputs.astype(np.int64) @ weights.astype(np.int64)
        + biases.astype(np.int64)
    )

    int32_min = -(2 ** 31)
    int32_max = (2 ** 31) - 1

    assert accumulator_64.min() >= int32_min
    assert accumulator_64.max() <= int32_max

    return accumulator_64.astype(np.int32)
```

This deliberately uses `int64` in NumPy for the calculation so the reference cannot overflow invisibly, then asserts all values fit signed 32-bit—the RTL accumulator width.

RTL-matched ReLU helper already used:

```python
def rtl_relu_shift_saturate(accumulator, shift=6):
    nonnegative = np.maximum(accumulator, 0)
    shifted = nonnegative >> shift
    saturated = np.minimum(shifted, np.iinfo(np.int16).max)
    return saturated.astype(np.int16)
```

The inference flow uses **raw, unnormalized pooled pixels** (`test_vectors`), exactly as hardware does:

```python
B1_q = np.zeros(32, dtype=np.int8)
B2_q = np.zeros(10, dtype=np.int8)

test_acc1 = rtl_dense_integer(test_vectors, W1_q, B1_q)
test_act1 = rtl_relu_shift_saturate(test_acc1, shift=6)

test_acc2 = rtl_dense_integer(test_act1, W2_q, B2_q)
test_act2 = rtl_relu_shift_saturate(test_acc2, shift=6)

rtl_matched_predictions = argmax_last_tie_batch(test_act2)
rtl_matched_accuracy = np.mean(rtl_matched_predictions == test_labels)
```

### Current valid integer results

```text
Dense-1 accumulator shape: (10000, 32)
Dense-1 accumulator range: -188009 to 369680
Dense-1 activation shape: (10000, 32)
Dense-1 activation range: 0 to 5776

Dense-2 accumulator shape: (10000, 10)
Dense-2 accumulator range: -931229 to 1527713
Dense-2 activation shape: (10000, 10)
Dense-2 activation range: 0 to 23870

Dense-1 saturated activations: 0
Dense-2 saturated activations: 0

RTL-matched integer-model accuracy: 0.9196
RTL-matched integer-model accuracy: 91.96%
```

This is excellent. Both stages fit in signed int32 and neither stage hits the signed-16 activation clamp. The integer model predicts the first 20 test samples as:

```text
Predicted: [7 2 1 0 4 1 4 9 6 9 0 6 9 0 1 5 9 7 3 4]
Actual:    [7 2 1 0 4 1 4 9 5 9 0 6 9 0 1 5 9 7 3 4]
```

The ninth displayed sample (`index 8`) is a normal classification error: true digit 5, predicted 6. It is not evidence of an RTL mismatch.

### Important interpretation of 91.96%

The 91.96% number is valid for the **Python RTL-matched fixed-point reference**, which uses the same intended arithmetic widths, shifts, zero biases, ReLU saturation, and tie rule.

It must **not yet** be stated as measured RTL accuracy. The current actual SystemVerilog localparam weights are older embedded values. Before claiming RTL accuracy, the exact `W1_q`, `W2_q`, zero biases, and shift settings must be represented in RTL and outputs compared against the reference.

---

## Unresolved diagnostic-cell error

The next planned diagnostic was to compare predictions from:

1. reconstructed-float inference using quantized weights; and
2. RTL-matched integer inference.

The original suggested call was:

```python
_, _, _, quantized_float_scores = forward_quantized_float(test_inputs)
```

It failed with:

```text
ValueError: too many values to unpack (expected 4)
```

This means `forward_quantized_float` returns more than four arrays, likely five (possibly including softmax probabilities) or another count. Do not guess its return contract.

The follow-up suggested taking the final return value:

```python
quantized_forward_result = forward_quantized_float(test_inputs)
print("Number of returned arrays:", len(quantized_forward_result))
quantized_float_scores = quantized_forward_result[-1]
```

The user reported that this also has an error, but did not paste the new traceback before requesting this handover. Therefore, the new chat should first ask the user to paste:

- the exact definition of `forward_quantized_float`, and
- the exact new traceback/output.

Then correct the call precisely. Do not provide a new next-step list until the user asks; they explicitly requested no further steps after this point.

Likely cause to investigate: the function may return a dictionary, a single array, six values, or output ordering different from the assumed one. Inspect rather than assume.

---

## Later technical path, only when the user asks

Do not initiate these steps immediately; the user explicitly asked to stop after resolving the diagnostic issue and wanted this handover first.

1. Resolve the quantized-float vs integer prediction diagnostic.
2. For at least one selected MNIST image, compare intermediate tensors between Python and RTL:
   - pooled 196 values;
   - Dense-1 32 accumulators;
   - ReLU-1 32 values;
   - Dense-2 10 accumulators;
   - ReLU-2 10 scores;
   - selected digit.
3. Export the exact trained `W1_q` and `W2_q` values in the orientation required by RTL. Python matrices are:
   - `W1_q.shape == (196, 32)` (input feature × neuron);
   - `W2_q.shape == (32, 10)` (input feature × neuron).
   RTL weight arrays may use neuron-first ordering; determine actual declaration and transpose only if needed.
4. Add the exact zero biases explicitly to RTL.
5. Generate test vectors in an appropriate format for the existing SystemVerilog testbench. Do not create an export file until the user approves and understands the format.
6. Run full RTL inference on a selected set, then potentially all 10,000 MNIST test images if simulation time is practical. Compare every final prediction, and preferably intermediate values for at least a smoke-test subset.
7. Improve/report measurable hardware numerics only after correct end-to-end verification:
   - measured test accuracy;
   - cycle latency per inference;
   - clock frequency/timing only after synthesis;
   - area/resource utilization only after synthesis/implementation.

Potential architectural improvement for future discussion:

- current Dense-1 uses 32 parallel neuron PEs but each uses serial MAC across 196 features, so latency is dominated by 196 cycles plus handshakes;
- current pooling is 14-cycle row-parallel;
- future improvements could pipeline/parallelize MACs, but would trade resources, routing, and timing. Do not claim a throughput improvement without synthesis/timing evidence.

---

## Resume / LinkedIn positioning (future, evidence-based)

Accurate project title candidate:

**Quantized Feed-Forward Neural Network Accelerator in SystemVerilog**

Once exact RTL-vs-Python verification is completed, a defensible project bullet can say approximately:

> Designed and verified a SystemVerilog MNIST inference accelerator with 2×2 average pooling, 196→32→10 dense layers, signed int8 weights, signed 32-bit MAC accumulation, and saturating fixed-point ReLU; achieved 91.96% MNIST test accuracy in an RTL-matched NumPy reference model.

Only change “RTL-matched NumPy reference model” to “RTL simulation” after actual RTL uses the trained weights and is tested against the full reference.

Other potentially reportable evidence already established:

- modular RTL verification of pooling, neuron, dense layer, ReLU, and argmax;
- full 14-row pooled output produced in 14 cycles by row-parallel pooling design;
- no activation saturation over 10,000 MNIST test images in the current integer reference;
- signed 32-bit accumulator range checks passed in the reference.

Avoid claiming UVM, synthesis timing/Fmax, resource usage, or hardware test accuracy unless those are actually completed and measured.

---

# Copy-paste prompt for a new chat

```text
I am continuing a SystemVerilog MNIST digit-classification accelerator project. Please act as a teaching-oriented RTL/ML co-pilot, not an autonomous editor.

My requirements:
- I write the RTL myself. Do not edit any RTL/testbench/notebook/file unless I explicitly ask.
- Before suggesting an edit or asking permission, explain what you want to do, why it is necessary, and what evidence/result it will produce.
- Do not create new files without first explaining the exact file, purpose, and benefit. I may prefer to create it myself.
- Teach me rather than dumping a full solution. When you provide Python, explain every line. I sometimes prefer 2–3 manageable cells together rather than one at a time.
- Do not suggest further steps unless I ask for them.

Project root: E:\VerilogProjects\Digit_Classification_FFN

Architecture:
28×28 uint8 MNIST → 2×2 stride-2 average pool → 14×14 / 196 → Dense 196→32 → ReLU + >>6 + signed-16 saturation → Dense 32→10 → ReLU + >>6 + signed-16 saturation → select_max.

Numeric contract:
- raw pixels uint8 0..255;
- pooled values nonnegative, carried in 16 bits;
- Dense inputs signed 16-bit;
- weights/biases signed int8;
- accumulator signed int32;
- ReLU: negatives to 0, arithmetic >>6, clamp to 32767, output signed int16;
- argmax ties select the highest index because RTL uses >=.

RTL status:
- User redesigned average pooling into 14 row-parallel PEs and its testbench passes.
- neuron testbench passes (MAC/timing/reset).
- dense_layer testbench passes (parallel across neurons, sequential MAC per neuron; done is registered one clock after combined completion).
- relu testbench passes incl. saturation boundary.
- select_max testbench passes incl. highest-index tie and signed comparisons.
- Do not change the RTL without asking; user writes it.

Colab state:
- Only NumPy 2.0.2 and Matplotlib; no TensorFlow/PyTorch.
- Trained normalized-input (pooled pixels /255) float model with zero biases and 196→32→10 ReLU network for 10 epochs. Final float test accuracy: 91.95%.
- Quantized per layer symmetrically to int8:
  W1_q shape (196,32), scale 172.87292, range -95..127, max quant error .0028918236.
  W2_q shape (32,10), scale 97.253784, range -120..127, max quant error .0051330924.
  Quantized-weight float model accuracy: 91.96%.
- Python RTL-matched inference uses raw pooled test_vectors, zero int8 biases, int64 calculation then asserts signed-int32 bounds, applies the exact ReLU/shift/clamp, then last-tie argmax.
- Results over 10,000 test images:
  Dense1 acc range -188009..369680; act range 0..5776; saturations 0.
  Dense2 acc range -931229..1527713; act range 0..23870; saturations 0.
  RTL-matched integer reference accuracy: 91.96%.

Important: 91.96% is currently a Python RTL-matched integer-reference result, NOT measured RTL accuracy. Actual RTL still has older embedded weights. We must later load the exact W1_q/W2_q values, respect matrix orientation, and compare RTL outputs before claiming it as RTL accuracy.

Immediate issue only — do not propose later steps yet:
I want to compare the reconstructed-float quantized model’s predictions to the RTL-matched integer predictions. The suggested call
    _, _, _, quantized_float_scores = forward_quantized_float(test_inputs)
failed with `ValueError: too many values to unpack (expected 4)`.
A follow-up using `quantized_forward_result = forward_quantized_float(test_inputs)` and taking `[-1]` also errored, but I have not pasted that traceback yet.

First, ask me to paste the exact `forward_quantized_float` definition and the exact new error. Then diagnose it precisely. Do not guess the return format or suggest a next phase until I ask.
```
