# Fuzzy Logic Based Attack Detection System in Verilog

## Overview

This repository implements a Fuzzy Logic-based FSM (Finite State Machine) for detecting Side-Channel Attack based on four key signal features:
- **Energy**
- **Peak Power**
- **Mean Power**
- **Hamming Distance**

The fuzzy inference mechanism uses triangular membership functions (TMFs) to calculate the degree of membership for each input feature across multiple linguistic categories (Low, Medium, High). These degrees are then used in a multi-stage FSM to infer whether an **attack** is detected or not.

---

## Modules Description

### 1. `triangular_mf`

This module implements the Triangular Membership Function (TMF), a common fuzzy logic function used to express how much an input value belongs to a fuzzy set.

#### Mathematical Expression:

Given parameters \( a < b < c \), and input \( x \):

```text
μ(x) = {
         0                    , x ≤ a
         (x - a) / (b - a)    , a < x ≤ b
         (c - x) / (c - b)    , b < x < c
         0                    , x ≥ c
       }
```
where μ(x) is the membership function for each linguistic variable for the extracted features.


#### Verilog Behavior:

- Uses fixed-point Q3.7 representation with 10-bit width (i.e., \( x \in [0, 1023] \)).
- Performs left-shift by 7 (`<<< 7`) to scale up for fixed-point division.
- Ensures no division by zero.
- Outputs 11-bit membership degree `y`.

---

### 2. `fuzzifier`

This module instantiates TMFs for all combinations of features and linguistic categories. The following are the raw values which are to be converted into Q3.7 Fixed-Point Binary Format for using in the Verilog Code.

| Feature        | Low         | Medium       | High         |
|----------------|-------------|--------------|---------------|
| **Energy**     | (0, 2.3, 2.8) | (2.7, 3.35, 4.0) | (3.8, 4.5, 6) |
| **Peak Power** | (0, 0.065, 0.11)    | (0.10, 0.13, 0.16)   | (0.15, 0.18, 0.2)   |
| **Mean Power** | (0, 0.048, 0.052)     | (0.051, 0.055, 0.059)      | (0.058, 0.061, 0.065)      |
| **Hamming Distance** | (0, 1, 1)     | (2, 3, 3)      | (3, 4, 15)      |

Each set of parameters corresponds to a fuzzy rule's membership function.

#### Output:
- For each feature and level (Low/Med/High), outputs an 11-bit fuzzy degree signal.

---

### 3. `fuzzy_attack_fsm`

This is the main FSM that takes the fuzzy degrees and evaluates them in stages to infer an attack. The FSM transitions through the following states:

| State        | Description |
|--------------|-------------|
| `S_START`    | Initialization |
| `S_HAMMING`  | Evaluate `hamming_dist` degrees |
| `S_ENERGY`   | Evaluate `energy` degrees |
| `S_PEAK`     | Evaluate `peak_power` degrees |
| `S_MEAN`     | Evaluate `mean_power` degrees |
| `S_ATTACK`   | Attack Detected |
| `S_NORMAL`   | Normal Condition |

#### Decision Rules:

- In each stage, the FSM compares degrees (`low`, `med`, `high`) for the respective feature.
- A degree is considered *significant* if it exceeds the threshold (`DEGREE_THRESH = 8`).
- Priority is given to the category with the highest degree that surpasses the threshold.

#### Output:

- `attack_detected = 1` → If FSM reaches `S_ATTACK`.
- `attack_detected = 0` → If FSM reaches `S_NORMAL` or on reset.

---

## Dataset Usage & Testbench Preparation

A `.csv` file is provided in this repository containing test cases of the following features:

- Hamming Distance
- Energy
- Peak Power
- Mean Power

Each feature is assumed to be in **floating-point** format. For use in the Verilog testbench, **each value must be converted to Q3.7 unsigned fixed-point representation**.

### Conversion Steps:

1. **Multiply the value by 128 (i.e., \( 2^7 \))**.
2. **Round off the result to the nearest integer**.
3. **Ensure the final result fits within the required bit-width (10 bits for Energy, Peak, and Mean; 8 bits for Hamming).**

#### Example:

| Feature        | Float Value | Q3.7 Conversion |
|----------------|-------------|------------------|
| Energy         | 3.24        | 3.24 * 128 = 414.72 ~ 415 |
| Peak Power     | 0.12        | 0.12 * 128 = 15.36 ~ 15 |
| Mean Power     | 0.08        | 0.08 * 128 = 10.24 ~ 10 |


Use the converted integers as direct 10-bit/8-bit inputs in your testbench for simulation.

---

## Simulation Instructions

1. Convert dataset values using the Q3.7 method as described.
2. Write a testbench module that applies the converted values to the `fuzzy_attack_fsm` module.
3. Simulate using your preferred simulator (ModelSim, Icarus Verilog, Vivado, etc.).
4. Monitor `attack_detected` output for each test case.

---

## Clock Constraints

The design is synthesized with a 100 MHz clock. A constraints file (.xdc) is included to define this clock input. It is essential to include this during synthesis and implementation in tools like Vivado or Quartus.

---

## File Structure

├── triangular_mf.v        // Triangular Membership Function Module

├── fuzzifier.v            // Fuzzification logic

├── fuzzy_attack_fsm.v     // Fuzzy logic FSM for attack detection

├── Fuzzy_Classification_Result.csv     // Dataset for testbench input generation

├── testbench.v            // (To be created by user using dataset instructions)

├── constraints.xdc        // 100 MHz clock constraint file





