//SPI Slave
module SPI_SLAVE

#(
    parameter  in_RAM_width  = 10, 
    parameter  out_RAM_width = 8 
) 
(
    input  wire                     CLK,
    input  wire                     rst_n,
    input  wire                     MOSI,
    input  wire                     SS_n,
    input  wire [out_RAM_width-1:0] tx_data,
    input  wire                     tx_valid,
    output reg                      MISO,
    output reg  [in_RAM_width-1:0]  rx_data,
    output wire                     rx_valid
);

    // FSM States
    localparam IDLE      = 3'b000;
    localparam CHK_CMD   = 3'b001;
    localparam WRITE     = 3'b010;
    localparam READ_ADDR = 3'b011;
    localparam READ_DATA = 3'b100;
    
    // to check wether read data or send read address
    reg       read_flag;

    // En rx/tx serializers , enable ser counter
    reg rx_rec_en;
    reg tx_ser_en;

    // Counter to convert serial <==> parallel
    reg [3:0] ser_cnt;

    // Current and Next state bits
    reg [2:0] CS;
    reg [2:0] NS;

    // State Memory
    always @(posedge CLK , negedge rst_n) begin
        if (!rst_n) begin
            CS <= IDLE;
        end
        else begin
            CS <= NS;
        end
    end

    // Next State Logic
    always @(*) begin
        case (CS)
        IDLE : begin

            if (!SS_n) begin
                NS = CHK_CMD;
            end
            else begin               
                NS = IDLE;
            end
        end
        CHK_CMD : begin
            if (!SS_n && !MOSI) begin
                NS = WRITE;
            end
            else if (!SS_n && MOSI && read_flag) begin                
                NS = READ_DATA;
            end
            else if (!SS_n && MOSI && !read_flag) begin
                NS = READ_ADDR;
            end
            else begin                
                NS = IDLE;
            end
        end
        WRITE : begin
            if(!SS_n) begin

                NS = WRITE;
            end
            else begin
                NS = IDLE;
            end
        end
        READ_ADDR : begin
            if (!SS_n) begin
                NS = READ_ADDR;
            end
            else begin               
                NS = IDLE;
            end
        end
        READ_DATA : begin
            if (!SS_n) begin
                NS = READ_DATA;
            end
            else begin               
                NS = IDLE;
            end
        end
        default : NS = IDLE;

        endcase

    end

    // Couunter to Detect address has been recieved and transit to recieve data state
    always @(posedge CLK,negedge rst_n) begin
        if (!rst_n) begin 
            read_flag     <= 1'b0;
        end
        else if (CS == READ_ADDR) begin   
            read_flag     <= 1'b1;
        end
        else if (CS == READ_DATA) begin
            read_flag     <= 1'b0;
        end
    end

    //Output Logic 
    always @(*) begin
        rx_rec_en  = 1'b0;
        tx_ser_en  = 1'b0;

        if ((CS == WRITE || CS == READ_ADDR) || (CS == READ_DATA && !tx_valid)) begin
            rx_rec_en = 1'b1;
        end
        else if (CS == READ_DATA && tx_valid) begin
            tx_ser_en = 1'b1;
        end
        else begin 
            rx_rec_en  = 1'b0;
            tx_ser_en  = 1'b0;
        end
    end

    // Output Logic
    always @(posedge CLK , negedge rst_n) begin
        if (!rst_n) begin
            rx_data       <= 10'b0;
            ser_cnt       <= 4'b0;
            MISO          <= 1'b0;
        end
        else if (rx_rec_en && ser_cnt != 10) begin
            rx_data       <= {rx_data[8:0],MOSI};
            ser_cnt       <= ser_cnt + 1'b1;
        end
        else if (tx_ser_en && ser_cnt != 4'd8) begin
            MISO          <= tx_data[7-ser_cnt];
            ser_cnt       <= ser_cnt + 1'b1;
        end
        else begin
            ser_cnt       <= 4'b0;
        end
    end
    
    assign rx_valid = (ser_cnt == 4'd10)? 1'b1:1'b0;

endmodule
