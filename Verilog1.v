module Verilog1 (
	clk, 		
	nreset, 	
	start,
	message_addr,	
	message_size, 	
	rle_addr, 	
	rle_size, 	
	done, 		
	port_A_clk,
        port_A_data_in,
        port_A_data_out,
        port_A_addr,
        port_A_we
	);
input	clk;

input	nreset;
// Initializes the RLE module

input	start;
// Tells RLE to start compressing the given frame

input 	[31:0] message_addr;
// Starting address of the plaintext frame
// i.e., specifies from where RLE must read the plaintext frame

input	[31:0] message_size;
// Length of the plain text in bytes

input	[31:0] rle_addr;
// Starting address of the ciphertext frame
// i.e., specifies where RLE must write the ciphertext frame

input   [31:0] port_A_data_out;
// read data from the dpsram (plaintext)

output  [31:0] port_A_data_in;
// write data to the dpsram (ciphertext)

output reg [15:0] port_A_addr;
// address of dpsram being read/written

output  port_A_clk;
// clock to dpsram (drive this with the input clk)

output  port_A_we;
// read/write selector for dpsram

output reg	[31:0] rle_size;
// Length of the compressed text in bytes

output	done; // done is a signal to indicate that encryption of the frame is complete
// assume read into read1 through readx and is ready for us to use
//only declared 4 because it will take 4 cycle to process 4x2 number pairs per 32 bit sequence.

reg [63:0] readin;
reg [31:0] messagestart;
reg [31:0] rleplace;
reg startreg; //for start 
reg [47:0] temp;
reg [7:0] bytecount;		//counts how many bytes we've processed (compares to message size)
reg [1:0] shiftcount;	//counts when to shift readin
reg waitcheck;
reg done;
reg port_A_we;
reg [1:0] state;
reg firsttime;

assign port_A_clk = clk;
assign port_A_data_in = temp [31:0];

always @(posedge port_A_clk) begin
	if (! nreset) begin
		temp <= 0; //initiallizing output
		done <= 0;	//initiallizing done statement
		bytecount <= 0; //keep track of how many bytes we've read in 
		rle_size <=0; //size of output 
		shiftcount <= 0;	//see if we need to shift in second word
		readin <= 0;	//temp to store words
		firsttime <= 1;
		state <= 3;
		$disp("We've reached the beginning and completed initializashen");
	end
	if (start) begin //detects start impulse, sets up the things that are dependent on the input
		startreg<=1; 
		port_A_we <=0;	//set to read
		port_A_addr <= message_addr;	//give initial reading address
		messagestart <= message_addr; //keep track of message_addr 
		rleplace <= rle_addr; //keep track of rle_addr
	end
	if (startreg) begin 
		case(state)
		0: //readstate (read into second half) 
		begin 
			port_A_addr <= messagestart + 4;
			messagestart <= messagestart + 4;
			readin[39:32] <= port_A_data_out[31:24];
			readin[47:40] <= port_A_data_out[23:16];
			readin[55:48] <= port_A_data_out[15:8];
			readin[63:56] <= port_A_data_out[7:0];
			state <= 1; 
		end 
		1: //comparestate (this will also be our check state. We didn't write code for check yet)
		begin 
			bytecount <= bytecount + 1; 
			shiftcount <= shiftcount + 1; 
			readin[55:0] <= readin[63:8];//shifts
			if (shiftcount == 3) begin 
				shiftcount <= 0; 
				state <= 1; //read into second half
			end 
			if (bytecount == message_size) begin 
				done <= 1;
				port_A_we <= 1;
				port_A_addr <= rleplace;
				rleplace <= rleplace + 4; 
				rle_size <= rle_size + 2;
			end
			case(readin[7:0] == temp[47:40])
				0: 
				begin 
					temp[31:0] <= temp[47:16];
					//temp[15:0] <= temp[31:16]; 
					temp[47:40] <= readin[7:0];
					temp[39:32] <= temp[39:32] + 1;
					if (temp[7:0] != 0) begin
						port_A_we <= 1;
						write <= 1;
						port_A_addr <= rleplace;
						rleplace <= rleplace + 4;
						temp[7:0] <= 0;
						rle_size <= rle_size + 4;
						//maybe need a counter
					end
				end //for readin = 0 
				1: 
				begin 
					temp[39:32] <= temp[39:32] + 1;
					if (temp[7:0] != 0) begin
					port_A_we <= 1;
					write <= 1;
					port_A_addr <= rleplace;
					rleplace <= rleplace + 4;
					temp[7:0] <= 0;
					rle_size <= rle_size + 4;
					//maybe need a counter
					end
				end //for readin = 1
			endcase //for readin case
		
		
		
		
		end 
		2: //writestate 
		begin 
			
		
		end 
		3: //initializingstate
		begin 
			readin[7:0] <= port_A_data_out[31:24];
			readin[15:8] <= port_A_data_out[23:16];
			readin[23:16] <= port_A_data_out[15:8];
			readin[31:24] <= port_A_data_out[7:0];
			messagestart <= messagestart + 4;
			port_A_addr <= messagestart + 4;
			state <= 0;
		end 
	end 
	
	
end
endmodule