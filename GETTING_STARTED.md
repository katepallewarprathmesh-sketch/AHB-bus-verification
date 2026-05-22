# I2C Protocol Verification - Getting Started

## Prerequisites

Before running the verification environment, ensure you have:

1. **ModelSim/QuestaSim** installed with SystemVerilog support
2. **UVM 1.2** (usually included with ModelSim)
3. **UNIX-like shell** (bash, sh) for Linux/Mac OR Windows Command Prompt for batch script
4. **Git** configured with GitHub credentials

## Installation Steps

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/I2C-protocol-verification.git
cd I2C-protocol-verification
```

### 2. Verify File Structure
```bash
ls -la
# Expected output:
# -rw-r--r-- LICENSE
# -rw-r--r-- README.md
# -rw-r--r-- IMPLEMENTATION.md
# -rw-r--r-- GETTING_STARTED.md
# -rw-r--r-- Makefile
# -rwxr-xr-x run.sh
# -rw-r--r-- run.bat
# drwxr-xr-x rtl/
# drwxr-xr-x tb/
# drwxr-xr-x sim/
```

### 3. Set ModelSim Path (if needed)
```bash
# Linux/Mac
export PATH=$PATH:/path/to/modelsim/bin

# Windows (PowerShell)
$env:PATH += "C:\path\to\modelsim\bin"
```

## Running Tests

### Option 1: Using Shell Script (Linux/Mac)
```bash
chmod +x run.sh
./run.sh
```

### Option 2: Using Batch Script (Windows)
```cmd
run.bat
```

### Option 3: Using Makefile
```bash
# Compile only
make compile

# Run one test
make simulate

# Run all tests
make test

# Clean artifacts
make clean

# Show help
make help
```

### Option 4: Manual Compilation
```bash
# Create work directory
mkdir -p sim/work

# Compile
vlog -64bit +acc=rw -sv -work sim/work \
    tb/i2c_if.sv \
    tb/i2c_pkg.sv \
    tb/i2c_tb.sv

# Simulate
vsim -64bit -c -work sim/work i2c_tb -t 1ps \
    -do "run -all; quit" \
    +UVM_TESTNAME=i2c_write_test \
    +UVM_VERBOSITY=UVM_MEDIUM \
    +dump_wave
```

## Understanding the Output

### Console Output
```
UVM_INFO @ 0ns : i2c_driver : Sending START condition
UVM_INFO @ 2500ns : i2c_driver : Sending byte: 0xa0
UVM_INFO @ 25000ns : i2c_driver : ACK bit received: 1
==== SCOREBOARD REPORT ====
Write Operations: 5
Read Operations: 0
Error Count: 0
```

### Log Files
Check detailed execution logs:
```bash
cat sim/test_i2c_write_test.log
```

### Waveform Files
View waveforms in graphical format:
```bash
# Using gtkwave (Linux/Mac)
gtkwave sim/i2c_simulation.vcd

# Using ModelSim GUI
vsim -gui -work sim/work i2c_tb
```

## Test Descriptions

### Write Test (`i2c_write_test`)
- **Purpose**: Verify I2C write operations
- **Transactions**: 5 write operations
- **Data**: 4 bytes per transaction
- **Expected**: All ACKs received
- **Duration**: ~200 µs
- **Pass Criteria**: 
  - 5 write operations completed
  - 20 data bytes transmitted
  - 5 ACKs received
  - 0 errors

### Read Test (`i2c_read_test`)
- **Purpose**: Verify I2C read operations
- **Transactions**: 5 read operations  
- **Data**: 2 bytes per transaction
- **Expected**: All bytes received with proper ACK/NACK
- **Duration**: ~200 µs
- **Pass Criteria**:
  - 5 read operations completed
  - 10 data bytes received
  - Proper ACK/NACK sequence

### Random Test (`i2c_random_test`)
- **Purpose**: Stress test with random transactions
- **Transactions**: 10 random operations
- **Variability**: Random addresses, random data sizes
- **Duration**: ~500 µs
- **Pass Criteria**:
  - All transactions complete
  - No protocol violations
  - 0 errors

## Troubleshooting

### Problem: `vlog: command not found`
**Solution**: ModelSim is not in your PATH
```bash
# Add to .bashrc or permanently set PATH
export PATH="/path/to/modelsim/bin:$PATH"
```

### Problem: Compilation errors
**Solution**: Check file paths and ensure all files are present
```bash
ls -la tb/
# Should show: i2c_if.sv i2c_agent.sv i2c_test.sv i2c_pkg.sv i2c_tb.sv
```

### Problem: Simulation timeout
**Solution**: Increase verbosity or check for infinite loops
```bash
+UVM_VERBOSITY=UVM_HIGH
```

### Problem: Waveform file not generated
**Solution**: Ensure `+dump_wave` argument is passed
```bash
vsim ... +dump_wave
```

## Customization Guide

### Change I2C Clock Speed
Edit `i2c_agent.sv`:
```systemverilog
// 100 kHz I2C
parameter SCL_PERIOD_NS = 10000;

// 400 kHz I2C
parameter SCL_PERIOD_NS = 2500;

// 1 MHz I2C
parameter SCL_PERIOD_NS = 1000;
```

### Add New Test Case
1. Create test class in `i2c_test.sv`:
```systemverilog
class i2c_my_test extends i2c_base_test;
    `uvm_component_utils(i2c_my_test)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_run_phase phase);
        i2c_my_seq seq = i2c_my_seq::type_id::create("seq");
        phase.raise_objection(this);
        seq.start(env.agent.sequencer);
        #500_000;
        phase.drop_objection(this);
    endtask
endclass
```

2. Create corresponding sequence:
```systemverilog
class i2c_my_seq extends i2c_base_seq;
    `uvm_object_utils(i2c_my_seq)
    
    function new(string name = "i2c_my_seq");
        super.new(name);
    endfunction
    
    virtual task body();
        // Your sequence logic here
    endtask
endclass
```

3. Register test in run script

### Modify Test Duration
In test run_phase:
```systemverilog
#1_000_000;  // Run for 1 ms
```

## Next Steps

1. **Review the code**: Study `i2c_agent.sv` and `i2c_test.sv`
2. **Run tests**: Execute `./run.sh` or `make test`
3. **Analyze results**: Check logs and waveforms
4. **Extend coverage**: Add new tests based on requirements
5. **Integrate with CI/CD**: Add to your build pipeline

## Support & Documentation

- [Main README](README.md) - Overview and features
- [Implementation Details](IMPLEMENTATION.md) - Architecture and design
- [I2C Specification](https://www.nxp.com/docs/en/user-manual/UM10204.pdf) - I2C protocol reference
- [UVM Cookbook](https://www.accellera.org/) - UVM methodology guide

---

**Happy Verifying!** 🚀

For questions or issues, please open a GitHub issue or contact the project maintainer.
