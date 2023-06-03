import wrapper_package::*;
module spi_Wrapper_tb;

	bit	  clk_tb;
	logic rst_n_tb;
	logic MOSI_tb;
	logic MISO_tb;
	logic SS_n_tb;

	// FSM states
	fsm_states fsm;

	// Arbitrary signal to indicate when to start/stop sampling of MOSI_COMM bit which refer to all possible CMDs.
	bit REQ_COMM = 0;

	// Create object from class
	spi_data spiData;

	// DUT instantiation
	SPI_Wrapper DUT (
		.CLK(clk_tb),
		.rst_n(rst_n_tb),
		.MOSI(MOSI_tb),
		.MISO(MISO_tb),
		.SS_n(SS_n_tb)
	);

	// store write/read addresses 
	logic [7:0] addr_sent2RAM [];
	logic [7:0] data_sent2RAM_assoc [int];
	logic [7:0] data_retrieved [];

	integer correct = 0;
	integer incorrect = 0;

	localparam test_cases = 5;

    always begin
        #5
        clk_tb = ~clk_tb;
        spiData.clk = clk_tb;
    end 

	initial begin

		spiData = new;
		addr_sent2RAM  = new[test_cases];
		data_retrieved = new[test_cases];
        
        // Initialize the inputs
		MOSI_tb = 1'b0;
		SS_n_tb = 1'b0;
		
		// Perform a RST
		RST;
		
		// Perform write operation with random addresses and random data
		for (int i = 0;i < test_cases;i++) begin
 			
 			WRT_ADDR;

			for (int j = 0; j < 8;j++) begin				
				assert(spiData.randomize);
				@(negedge clk_tb)
				MOSI_tb = spiData.MOSI;
				addr_sent2RAM[i][j] = MOSI_tb;				
			end

			END_COMM;

			$display("Address created = %b",addr_sent2RAM[i]);
 			WRT_DATA;

			for (int j = 0; j < 8;j++) begin
				assert(spiData.randomize);
				@(negedge clk_tb)
				MOSI_tb = spiData.MOSI;
				data_sent2RAM_assoc[addr_sent2RAM[i]][j] = MOSI_tb;				
			end

			$display("Data created   = %b",data_sent2RAM_assoc[addr_sent2RAM[i]]);
			
			END_COMM;

		end

		// Perform Read operation with addresses and data created
		for (int i = 0;i < test_cases;i++) begin
			
 			RD_ADDR;

			for (int j = 0; j < 8;j++) begin
				
				@(negedge clk_tb)
				MOSI_tb = addr_sent2RAM[i][j];
				
			end

			END_COMM;

 			RD_DATA;

			for (int j = 0; j < 8;j++) begin
				// Dummy Data
				assert(spiData.randomize);
				@(negedge clk_tb)
				MOSI_tb = spiData.MOSI;

			end

			// Give time for ram to assert tx_valid to high and assert the data on tx_data bus
			@(negedge clk_tb)
			@(negedge clk_tb)

			$display("DATA_NUM = %0d",i+1);
			// data will be retrieved from slave
			for(int j = 0;j < 8;j++) begin
				@(negedge clk_tb)
				if (j == 6) begin
					
					data_retrieved[i][j] = MISO_tb;
					END_COMM;

				end
				else begin
					
					data_retrieved[i][j] = MISO_tb;

				end
				
			end
			CHK_READ(data_retrieved[i],data_sent2RAM_assoc[addr_sent2RAM[i]]);

		end

		// Perform a reset
		RST;

		$display("================================================");
		$display("Now CMDs are excuted in parallel");
		$display("================================================");

		// Perform write & Read operation with random addresses and random data
		for (int i = 0;i < test_cases;i++) begin
 			
 			WRT_ADDR;

			for (int j = 0; j < 8;j++) begin
				
				assert(spiData.randomize);
				@(negedge clk_tb)
				MOSI_tb = spiData.MOSI;
				addr_sent2RAM[i][j] = MOSI_tb;
				
			end

			END_COMM;

			$display("Address created = %b",addr_sent2RAM[i]);
 			WRT_DATA;

			for (int j = 0; j < 8;j++) begin
				assert(spiData.randomize);
				@(negedge clk_tb)
				MOSI_tb = spiData.MOSI;
				data_sent2RAM_assoc[addr_sent2RAM[i]][j] = MOSI_tb;
				
			end

			$display("Data created   = %b",data_sent2RAM_assoc[addr_sent2RAM[i]]);
		
			END_COMM;

			RD_ADDR;

			for (int j = 0; j < 8;j++) begin
				@(negedge clk_tb)
				MOSI_tb = addr_sent2RAM[i][j];
			end

			END_COMM;

			RD_DATA;

			for (int j = 0; j < 8;j++) begin
				// Dummy Data
				assert(spiData.randomize);
				@(negedge clk_tb)
				MOSI_tb = spiData.MOSI;
			end

			// Give time for ram to assert tx_valid to high and assert the data on tx_data bus
			@(negedge clk_tb)
			@(negedge clk_tb)

			$display("DATA_NUM = %0d",i+1);
			// data will be sent from slave
			for(int j = 0;j < 8;j++) begin
				@(negedge clk_tb)
				if (j == 6) begin
					
					data_retrieved[i][j] = MISO_tb;
					END_COMM;

				end
				else begin
					
					data_retrieved[i][j] = MISO_tb;

				end
				
			end
			CHK_READ(data_retrieved[i],data_sent2RAM_assoc[addr_sent2RAM[i]]);
	
	end

	// Perform a reset
	RST;

	$display("================================================");
	$display("==================== TEST CASES ================");
	$display("================================================");
	$display("Correct Cases   = %0d",correct);
	$display("Incorrect Cases = %0d",incorrect);

	$stop;
end

	always @(posedge REQ_COMM) begin
		
		spiData.covgrp_2.start;

	end

	always @(posedge clk_tb) begin

		if (REQ_COMM) begin	
			spiData.MOSI_COMM = MOSI_tb;
		end

		spiData.covgrp_2.sample;

	end

	always @(negedge REQ_COMM) begin
		
		spiData.covgrp_2.stop;

	end

	task RST;
        rst_n_tb = 0;
        spiData.rst_n = rst_n_tb;
        fsm = IDLE;
        spiData.state = fsm;
        repeat (20) @(negedge clk_tb);
        rst_n_tb = 1;
        spiData.rst_n = rst_n_tb;
	endtask

	task START_COMM;
		@(negedge clk_tb)
		SS_n_tb = 0;
		spiData.SS_n = SS_n_tb;
		fsm = CHK_CMD;
		spiData.state = fsm;
		@(negedge clk_tb);
	endtask

	task END_COMM;
		@(negedge clk_tb)
		SS_n_tb = 1;
		spiData.SS_n = SS_n_tb;
		fsm = IDLE;
		spiData.state = fsm;
	endtask

	task WRT_ADDR;
		REQ_COMM = 1;
		
		START_COMM;
		MOSI_tb = 0;
		@(negedge clk_tb)
	    fsm = WRITE_ADDR;
		spiData.state = fsm;
		MOSI_tb = 0;
		@(negedge clk_tb)
		MOSI_tb = 0;

		REQ_COMM = 0;
	endtask

	task WRT_DATA;
		REQ_COMM = 1;
		
		START_COMM;
		MOSI_tb = 0;
		@(negedge clk_tb)
		fsm = WRITE_DATA;
		spiData.state = fsm;
		MOSI_tb = 0;
		@(negedge clk_tb)
		MOSI_tb = 1;

		REQ_COMM = 0;	
	endtask

	task RD_ADDR;
		REQ_COMM = 1;
		
		START_COMM;
		MOSI_tb = 1;
		@(negedge clk_tb)
		fsm = READ_ADDR;
		spiData.state = fsm;
		MOSI_tb = 1;
		@(negedge clk_tb)
		MOSI_tb = 0;
		
		REQ_COMM = 0;
	endtask

	task RD_DATA;
		REQ_COMM = 1;

		START_COMM;
		MOSI_tb = 1;
		@(negedge clk_tb)
		fsm = READ_DATA;
		spiData.state = fsm;
		MOSI_tb = 1;
		@(negedge clk_tb)
		MOSI_tb = 1;

		REQ_COMM = 0;		
	endtask

	task CHK_READ (input [7:0] data_retrieved,data_expected);
		if (data_retrieved == data_expected) begin
			
			$display("At time %0t data value = %b which equals expected %b",$time,data_retrieved,data_expected);
			correct ++;

		end
		else begin
			
			$display("At time %0t data value = %b which NOT equals expected %b",$time,data_retrieved,data_expected);
			incorrect ++;

		end

	endtask

endmodule // spi_slave_tb



