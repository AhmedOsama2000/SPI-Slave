// Dual Port RAM
module RAM

#(
    parameter IN_WIDTH  = 10,
    parameter OUT_WIDTH = 8,
    parameter MEM_DEPTH = 256,
    parameter ADDR_SIZE = 8
) 

(
    input  wire                CLK,
    input  wire                rst_n,
    input  wire [IN_WIDTH-1:0] din,
    input  wire                rx_valid,
    output reg                 tx_valid,
    output reg [OUT_WIDTH-1:0] dout

);

integer i;

// RAM REGISTERS
reg [ADDR_SIZE-1:0] RAM [MEM_DEPTH-1:0];

// RAM ADDRESS
reg [ADDR_SIZE-1:0] address;

always @(posedge CLK , negedge rst_n) begin

    if (!rst_n) begin 
        address  <= 8'b0;
        dout     <= 8'b0;
        tx_valid <= 0;
    end
    else if (rx_valid) begin
        case (din[9:8]) 
            // Write Address
            2'b00: begin address      <= din[7:0];     tx_valid <= 0; end
            // Write Data 
            2'b01: begin RAM[address] <= din[7:0];     tx_valid <= 0; end
            // Read Address
            2'b10: begin address      <= din[7:0];     tx_valid <= 0; end
            // Read Data
            2'b11: begin dout         <= RAM[address]; tx_valid <= 1; end
        endcase
    end
end

endmodule