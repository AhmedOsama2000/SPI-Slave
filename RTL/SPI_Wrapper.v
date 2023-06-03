// SPI Wrapper
module SPI_Wrapper 

#(
    parameter  in_RAM_width  = 10, 
    parameter  out_RAM_width = 8 
) 
(
    input  wire CLK,
    input  wire rst_n,
    input  wire SS_n,
    input  wire MOSI,
    output wire MISO
);

    wire [in_RAM_width-1:0]  rx_data;
    wire [out_RAM_width-1:0] tx_data;
    wire                     rx_valid;
    wire                     tx_valid;

    SPI_SLAVE SLAVE (
        .CLK(CLK),
        .rst_n(rst_n),
        .SS_n(SS_n),
        .MOSI(MOSI),
        .MISO(MISO),
        .rx_data(rx_data),
        .tx_data(tx_data),
        .rx_valid(rx_valid),
        .tx_valid(tx_valid)
    );
    RAM RAM (
        .CLK(CLK),
        .rst_n(rst_n),
        .din(rx_data),
        .dout(tx_data),
        .rx_valid(rx_valid),
        .tx_valid(tx_valid)
    );

endmodule