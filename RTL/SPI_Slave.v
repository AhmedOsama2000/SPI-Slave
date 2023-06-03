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
    reg read_flag;

    // Flag to Check serial <==> parallel is done
    wire conv_flag;
    reg  count_rst;
    reg  count_en;

    // Counter to convert serial <==> parallel
    reg [4:0] conv_counter;

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

    always @(posedge CLK,negedge rst_n) begin
        
        if (!rst_n) begin 
            read_flag <= 0;
        end
        else if (CS == READ_DATA && conv_counter == 0) begin   
            read_flag <= 0;
        end
        else if (CS == READ_ADDR && conv_counter == 8) begin   
            read_flag <= 1;
        end

    end

    //Output Logic 
    always @(*) begin

        count_rst = 0;
        count_en = 0;
        
        if (CS == CHK_CMD) begin
            count_rst = 1;
        end
        else if ( (CS == WRITE || (CS == READ_DATA) || CS == READ_ADDR) && !conv_flag) begin
            count_en = 1;
        end

        else begin 
            count_rst = 0;
            count_en = 0;
        end

    end

    // Output Logic
    always @(posedge CLK , negedge rst_n) begin

        if (!rst_n) begin
            rx_data <= 0;
            MISO    <= 0;
        end
        else if ( (CS == WRITE) || (CS == READ_ADDR) || (CS == READ_DATA && !tx_valid) ) begin
            rx_data[conv_counter-9] <= MOSI;
        end
        else if (CS == READ_DATA && tx_valid && !conv_flag) begin
            MISO <= tx_data[conv_counter];
        end

    end

    always @(posedge CLK,negedge rst_n) begin
        
        if (!rst_n) begin            
            conv_counter <= 18;
        end
        else if (count_rst) begin            
            conv_counter <= 18;
        end
        else if (count_en) begin            
            conv_counter <= conv_counter - 1;
        end

    end

    assign rx_valid  = (conv_counter == 8)? 1'b1 : 1'b0;
    assign conv_flag = ( (conv_counter == 8 && !read_flag) || (conv_counter == 0 && read_flag) )? 1'b1:1'b0;
    
endmodule
