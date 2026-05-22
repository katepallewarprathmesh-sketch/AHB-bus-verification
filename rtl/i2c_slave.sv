// I2C Slave Module
// Implements I2C protocol with open-drain outputs and a simple state machine
module i2c_slave(
    input logic clk,
    input logic rst_n,
    
    // I2C Bus Interface (Open Drain)
    inout wire sda,
    inout wire scl,
    
    // Slave Control
    input logic [6:0] slave_address,  // 7-bit I2C slave address
    output logic sda_en,              // 1 = pull low, 0 = release
    output logic slave_active,        // Indicates slave is active
    
    // Data Interface (optional)
    output logic [7:0] data_out,      // Data from master
    input logic [7:0] data_in,        // Data to send to master
    output logic data_valid,          // Data received is valid
    output logic read_request         // Master is requesting read
);
    
    // State machine definition
    typedef enum {
        IDLE,
        WAIT_ADDRESS,
        ADDRESS_RX,
        ACK_ADDRESS,
        WAIT_DATA,
        DATA_RX,
        ACK_DATA,
        DATA_TX,
        ACK_RX
    } slave_state_e;
    
    slave_state_e state, next_state;
    
    // Synchronized bus signals
    logic sda_in, scl_in;
    logic sda_in_r, scl_in_r;
    logic sda_in_rr, scl_in_rr;
    
    // Bus condition detection
    wire start_condition = sda_in_rr && ~sda_in_r && scl_in_rr;
    wire stop_condition = ~sda_in_rr && sda_in_r && scl_in_rr;
    wire scl_rise = ~scl_in_rr && scl_in_r;
    wire scl_fall = scl_in_rr && ~scl_in_r;
    
    // Synchronize bus inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_in_r <= 1'b1;
            scl_in_r <= 1'b1;
            sda_in_rr <= 1'b1;
            scl_in_rr <= 1'b1;
        end else begin
            sda_in_r <= sda_in;
            scl_in_r <= sda_in_r;
            sda_in_rr <= sda_in_r;
            
            scl_in_r <= scl_in;
            scl_in_rr <= scl_in_r;
        end
    end
    
    assign sda_in = sda;
    assign scl_in = scl;
    
    // Internal registers
    logic [7:0] shift_reg;
    logic [2:0] bit_count;
    logic [6:0] received_address;
    logic received_rw;  // 1 = read, 0 = write
    
    // Open-drain driver
    assign sda = sda_en ? 1'b0 : 1'bz;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            sda_en <= 1'b0;
            bit_count <= 3'h0;
            shift_reg <= 8'h0;
            data_valid <= 1'b0;
            read_request <= 1'b0;
            slave_active <= 1'b0;
            data_out <= 8'h0;
        end else begin
            state <= next_state;
            data_valid <= 1'b0;
            read_request <= 1'b0;
            
            case (state)
                IDLE: begin
                    sda_en <= 1'b0;
                    slave_active <= 1'b0;
                    bit_count <= 3'h0;
                end
                
                WAIT_ADDRESS: begin
                    slave_active <= 1'b1;
                    if (scl_rise) begin
                        shift_reg[7 - bit_count] <= sda_in;
                    end
                end
                
                ADDRESS_RX: begin
                    if (bit_count == 3'h7) begin
                        received_address <= shift_reg[7:1];
                        received_rw <= shift_reg[0];
                        data_out <= shift_reg;
                        read_request <= shift_reg[0];
                    end
                end
                
                ACK_ADDRESS: begin
                    // Check if address matches
                    if (received_address == slave_address) begin
                        sda_en <= 1'b1;  // Pull SDA low to ACK
                    end
                end
                
                WAIT_DATA: begin
                    sda_en <= 1'b0;  // Release SDA after ACK
                    if (scl_rise && bit_count < 3'h7) begin
                        shift_reg[7 - bit_count] <= sda_in;
                    end
                end
                
                DATA_RX: begin
                    if (bit_count == 3'h7) begin
                        data_out <= shift_reg;
                        data_valid <= 1'b1;
                    end
                end
                
                ACK_DATA: begin
                    // Simple ACK logic - always ACK for demo
                    sda_en <= 1'b1;
                end
                
                DATA_TX: begin
                    sda_en <= 1'b0;  // Release after ACK
                end
                
                default: begin
                    sda_en <= 1'b0;
                    slave_active <= 1'b0;
                end
            endcase
            
            // Bit counter management
            if (scl_fall && (state == WAIT_ADDRESS || state == WAIT_DATA)) begin
                if (bit_count == 3'h7) begin
                    bit_count <= 3'h0;
                end else begin
                    bit_count <= bit_count + 1;
                end
            end
        end
    end
    
    // Next state logic
    always_comb begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (start_condition)
                    next_state = WAIT_ADDRESS;
            end
            
            WAIT_ADDRESS: begin
                if (bit_count == 3'h7 && scl_fall)
                    next_state = ADDRESS_RX;
            end
            
            ADDRESS_RX: begin
                next_state = ACK_ADDRESS;
            end
            
            ACK_ADDRESS: begin
                if (scl_fall)
                    next_state = WAIT_DATA;
            end
            
            WAIT_DATA: begin
                if (bit_count == 3'h7 && scl_fall)
                    next_state = DATA_RX;
                else if (stop_condition)
                    next_state = IDLE;
            end
            
            DATA_RX: begin
                next_state = ACK_DATA;
            end
            
            ACK_DATA: begin
                if (scl_fall)
                    next_state = WAIT_DATA;
            end
            
            DATA_TX: begin
                if (stop_condition)
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
endmodule : i2c_slave
