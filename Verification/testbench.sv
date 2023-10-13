import wrapper_package::*;
module spi_Wrapper_tb;

	bit	  clk_tb;
	logic rst_n_tb;
	logic MOSI_tb;
	logic MISO_tb;
	logic SS_n_tb;

	parameter MEM_DEPTH = 256;

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

		for (int i = 0; i < MEM_DEPTH;i++) begin
			DUT.RAM.RAM[i] = $random;
		end

		spiData = new;
		addr_sent2RAM  = new[test_cases];
		data_retrieved = new[test_cases];
        
        // Initialize the inputs
		MOSI_tb = 1'b1;
		SS_n_tb = 1'b1;
		
		// Perform a RST
		RST;
		
		// Perform write operation with random addresses and random data
		for (int i = 0;i < test_cases;i++) begin	
 			WRT_ADDR(i);
 			WRT_DATA(addr_sent2RAM[i]);
		end

		// Perform Read operation with addresses and data created
		for (int i = 0;i < test_cases;i++) begin
 			RD_ADDR(i);
 			RD_DATA(i,addr_sent2RAM[i]);

			CHK_READ(data_retrieved[i],data_sent2RAM_assoc[addr_sent2RAM[i]]);
		end

		// Perform a reset
		RST;

		$display("================================================");
		$display("Now CMDs are excuted in parallel");
		$display("================================================");

		// Perform write & Read operation with random addresses and random data
		for (int i = 0;i < test_cases;i++) begin
 			WRT_ADDR(i);
 			WRT_DATA(addr_sent2RAM[i]);
			RD_ADDR(i);
 			RD_DATA(i,addr_sent2RAM[i]);
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
		@(negedge clk_tb);
		SS_n_tb = 0;
		spiData.SS_n = SS_n_tb;
		fsm = CHK_CMD;
		spiData.state = fsm;
		@(negedge clk_tb);
	endtask

	task END_COMM;
		SS_n_tb = 1;
		spiData.SS_n = SS_n_tb;
		fsm = IDLE;
		spiData.state = fsm;
	endtask

	task automatic WRT_ADDR(input [7:0] ram_addr);

		int addr_index_cnt;

		$display("Initiate Address @ time \t %0t",$time);

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

		// Randomize and capture the address
		while (!SS_n_tb) begin
			assert(spiData.randomize);
			@(negedge clk_tb);
			MOSI_tb = spiData.MOSI;
			addr_sent2RAM[ram_addr][7-addr_index_cnt] = MOSI_tb;
			addr_index_cnt++;
			if (addr_index_cnt == 9) begin
				END_COMM();
			end
		end
		$display("Address created = %b",addr_sent2RAM[ram_addr]);
		$display("An Address has been initiated @ time \t %0t",$time);
			
	endtask

	task automatic WRT_DATA(input [7:0] ram_addr);

		int data_index_cnt = 0;

		$display("Initiate Data @ time \t %0t",$time);

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

		// Randomize and capture the address
		while (!SS_n_tb) begin
			assert(spiData.randomize);
			@(negedge clk_tb)
			MOSI_tb = spiData.MOSI;
			data_sent2RAM_assoc[ram_addr][7-data_index_cnt] = MOSI_tb;	
			data_index_cnt++;
			if (data_index_cnt == 9) begin
				END_COMM();
			end
		end

		$display("Data created = %b",data_sent2RAM_assoc[ram_addr]);
		$display("Data has been initiated @ time \t %0t",$time);
	endtask

	task automatic RD_ADDR(input [7:0] ram_addr);

		int addr_index_cnt;

		$display("Reading Address %0b @time \t",addr_sent2RAM[ram_addr],$time);

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

		while (!SS_n_tb) begin
			@(negedge clk_tb)
			MOSI_tb = addr_sent2RAM[ram_addr][7-addr_index_cnt];
			addr_index_cnt++;
			if (addr_index_cnt == 9) begin
				END_COMM();
			end
		end

		$display("Finish Reading Address @time \t",$time);

	endtask

	task automatic RD_DATA(input [7:0] ram_addr_rec,input [7:0] ram_addr);

		int data_index_cnt = 0;

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

		while (!SS_n_tb) begin
			assert(spiData.randomize);
			@(negedge clk_tb);

			// Insert Dummy Data to complete the frame
			MOSI_tb = spiData.MOSI;
			data_index_cnt++;
			if (data_index_cnt == 9) begin
				@(posedge DUT.RAM.tx_valid);
				$display("Reading Data %0b @time \t",data_sent2RAM_assoc[ram_addr],$time);

				// Get Data From Ram
				@(negedge clk_tb);

				// Capture Data by data_recieved
				for (int i = 0; i < 8;i++) begin
					@(negedge clk_tb);
					data_retrieved[ram_addr_rec][7-i] = MISO_tb;
				end
				END_COMM();
			end
		end

		$display("Finish Reading Data %0b @time \t",data_retrieved[ram_addr_rec],$time);

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



