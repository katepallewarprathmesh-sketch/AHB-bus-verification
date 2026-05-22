// I2C Master Module
// Implements I2C protocol with open-drain outputs
module i2c_master(
    input logic clk,
    input logic rst_n,
    
    // I2C Bus Interface (Open Drain)
    inout wire sda,
    inout wire scl,
    
    // Control Signals
    input logic sda_en,      // 1 = pull low, 0 = release
    input logic scl_en,      // 1 = pull low, 0 = release
    
    // Status Signals
    output logic sda_out,    // Current SDA line state
    output logic scl_out,    // Current SCL line state
    output logic bus_busy    // Indicates I2C bus is in use
);
    
    // Open-drain implementation
    assign sda = sda_en ? 1'b0 : 1'bz;
    assign scl = scl_en ? 1'b0 : 1'bz;
    
    // Bus state monitoring
    assign sda_out = sda;
    assign scl_out = scl;
    
    // Simple bus busy detection
    // Bus is busy if either line is being held low
    assign bus_busy = ~sda | ~scl;
    
    // Synchronize bus signals with clock domain
    logic sda_sync, scl_sync;
    logic sda_sync_r, scl_sync_r;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_sync <= 1'b1;
            scl_sync <= 1'b1;
            sda_sync_r <= 1'b1;
            scl_sync_r <= 1'b1;
        end else begin
            // Double-flop synchronization for metastability
            sda_sync <= sda;
            scl_sync <= scl;
            sda_sync_r <= sda_sync;
            scl_sync_r <= scl_sync;
        end
    end
    
endmodule : i2c_master
