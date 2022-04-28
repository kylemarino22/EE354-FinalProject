`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:27:11 12/07/2017 
// Design Name: 
// Module Name:    DisplayController 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created

// Additional Comments:  https://learn.digilentinc.com/Documents/269
// - Use Bahavioural Modelling (always, initial)
// - Use the Following: clock divider, two counters(horizontal counter, vertical
// counter), 
//////////////////////////////////////////////////////////////////////////////////
module display_controller(
	input clk,
	output hSync, vSync,
	output reg bright,
	output reg[9:0] hCount, 
	output reg [9:0] vCount // Covers 800, width of the screen, because it's 2^10
	);
	
	reg pulse;
	reg clk25;
	
	initial begin // Set all of them initially to 0
		clk25 = 0;
		pulse = 0;
	end
	
	always @(posedge clk)
		pulse = ~pulse;
	always @(posedge pulse)
		clk25 = ~clk25;
		
	always @ (posedge clk25)
		begin
		if (hCount < 10'd799)
			begin
			hCount <= hCount + 1;
			end
		else if (vCount < 10'd524)
			begin
			hCount <= 0;
			vCount <= vCount + 1;
			end
		else
			begin
			hCount <= 0;
			vCount <= 0;
			end
		end
		
	assign hSync = (hCount < 96) ? 0:1;
	assign vSync = (vCount < 2) ? 0:1;
	
	localparam row_width = 7'd56;
    localparam col_width = 7'd72;
    localparam h_offset = 10'd160;
    localparam v_offset = 10'd50;
		
	always @(posedge clk25)
		begin
		if(hCount > h_offset && hCount < col_width*8+h_offset && vCount > v_offset && vCount < row_width*8+v_offset)
			bright <= 1;
		else
			bright <= 0;
		end	
		
endmodule
