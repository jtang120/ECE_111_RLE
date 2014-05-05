module rle (
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
//reg [31:0] readtemp;		//stores port_A_data_out to use in always
reg [31:0] messagestart;
reg [31:0] rleplace;
reg startreg; //for start 
reg [47:0] temp;
reg [7:0] bytecount;		//counts how many bytes we've processed (compares to message size)
reg [7:0] shiftcount;	//counts when to shift readin
reg [2:0] initialcounter;
reg write;
reg done;
reg port_A_we;
reg readcheck; //create idle state to stabilize readin data
reg startcheck;

assign port_A_clk = clk;
assign port_A_data_in = temp [31:0];

/*the TA told me that we can't add 32 to message_addr or rle_addr and that we need to add 4 cuz even though we move in
one word at a time, the memory pointer is shifted one byte at a time; however, he did say that our logic seemed good */ 

always @(posedge port_A_clk)begin 
	if (! nreset) begin 
		startreg <= 1;
		startcheck <=0;
		$disp("Hey"); 
	end 
	else
		begin
		if (start) begin
				startcheck <=1;
				$disp("I've been here"); 
		end
		if (startreg) begin
	end
		if (startcheck) begin
			$disp("Im here"); 
			case(startcheck) 
				0: begin
					if (readcheck) begin 
						readcheck <= 0; 
						port_A_addr <= messagestart; 
					end
					else begin 
						case (initialcounter)
							0: begin 
								bytecount <= bytecount + 1;
								readin[23:0] <= readin[31:8];//shifts
								shiftcount <= shiftcount + 1;
								if (shiftcount == 3) begin //move second half to first half 
									readin[31:0] <= readin[63:32];
									shiftcount <= 0; //reinitialize 
									readin[39:32] <= port_A_data_out[31:24]; //read in next word 
									readin[47:40] <= port_A_data_out[23:16];
									readin[55:48] <= port_A_data_out[15:8];
									readin[63:56] <= port_A_data_out[7:0];
									messagestart <= messagestart + 4;
									readcheck <= 1; 
								end
								if (write) begin
									write <= 0;
									port_A_we <=0;
									readcheck <= 1; //I THINK THIS NEEDS TO BE HERE...LET'S TEST :D 
									//port_A_addr <= messagestart; //just added not sure if we need or not 
									//might be wrong time to change to 0 
								end
								if (bytecount == message_size) begin 
									done <= 1;
									write <= 1;
									port_A_we <= 1;
									port_A_addr <= rleplace; 
									rle_size <= rle_size + 2;
								end
								case(readin[7:0] == temp[47:40])
									0: begin 
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
									1: begin 
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
							end //for initialcounter = 0
							1: begin 
								readin[39:32] <= port_A_data_out[31:24];
								readin[47:40] <= port_A_data_out[23:16];
								readin[55:48] <= port_A_data_out[15:8];
								readin[63:56] <= port_A_data_out[7:0];
								messagestart <= messagestart + 4;
								initialcounter <= 0;
								readcheck <= 1; 
							end //for initialcounter = 1	
							2: begin 
								readin[7:0] <= port_A_data_out[31:24];
								readin[15:8] <= port_A_data_out[23:16];
								readin[23:16] <= port_A_data_out[15:8];
								readin[31:24] <= port_A_data_out[7:0];
								messagestart <= messagestart + 4;
								initialcounter <= 1;
								readcheck <= 1;
							end //for initialcounter = 2
						endcase //for initial counter case 
					end 
				end 	// for reset = 0 
				1: begin 
					initialcounter <= 2;
					temp <= 0; //mite b xtra
					port_A_we <=0;
					port_A_addr <= message_addr;
					messagestart <= message_addr; //keep track of message_addr 
					rleplace <= rle_addr; //keep track of rle_addr 
					write <= 0;
					done <= 0;
					bytecount <= 0; //keep track of how many bytes we've read in 
					rle_size <=0; //size of output 
					shiftcount <= 0;
					readcheck <= 1; //new stuff
					readin <= 0; 
					//readtemp <= 0;
				
					startreg <= 1; 
					
				end //for reset = 1
			endcase //for reset case 
		end //for startreg = 1 
	end
	
end 
 
endmodule 