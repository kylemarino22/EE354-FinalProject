`timescale 1ns / 1ps

module chess_top(
	input ClkPort,
	
	//Buttons from Nexus 4 Board
	input BtnC,
	input BtnU,
	input BtnR,
	input BtnL,
	input BtnD,
	input btnCpuReset, // Button used as reset
	//VGA signal
	output hSync, vSync,
	output [3:0] vgaR, vgaG, vgaB,
	
	//SSG signal 
	output An0, An1, An2, An3, An4, An5, An6, An7,
	output Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,
	
	output MemOE, MemWR, RamCS, QuadSpiFlashCS
	);
	
	// disable mamory ports
	assign {MemOE, MemWR, RamCS, QuadSpiFlashCS} = 4'b1111;
	
	//Rename button input to Reset (active high)
	wire Reset;
	assign Reset=~btnCpuReset;
	
	//Variables for VGA display
	wire bright;
	wire[9:0] hc, vc;
	wire [11:0] rgb;
	
	//Varibles for SSD
	reg [3:0]	SSD;
	wire [3:0]	SSD3, SSD2, SSD1, SSD0;
	reg [7:0]  	SSD_CATHODES;
	wire [1:0] 	ssdscan_clk;
    wire [3:0] anode;
	
	//Create a slower clock to be used throughout the design
	reg [27:0]	DIV_CLK;
	always @ (posedge ClkPort)  
	begin : CLOCK_DIVIDER
	   DIV_CLK <= DIV_CLK + 1'b1;
	end
	wire move_clk;
	assign move_clk=DIV_CLK[19]; //slower clock to drive the movement of objects on the vga screen
	
	//Debounced button signals
    wire BtnU_db, BtnR_db, BtnL_db, BtnD_db, BtnC_db;

    //Variables for game logic
	wire [2:0] rowIndex, colIndex;
	wire [3:0] selectedPiece, currentPiece;
	wire [2:0] cursorX, cursorY, selectedX, selectedY;
	wire select_enable;
	
	//Create VGA RGB output signals
	assign vgaR = rgb[11 : 8];
	assign vgaG = rgb[7  : 4];
	assign vgaB = rgb[3  : 0];
	
	//Generates signals for VGA
	display_controller dc(
	   .clk(ClkPort),
	   .hSync(hSync), 
	   .vSync(vSync), 
	   .bright(bright), 
	   .hCount(hc), 
	   .vCount(vc));
	
	//Calculates RGB value based on the game configuration
    draw d(
        .bright(bright), 
        .hCount(hc), 
        .vCount(vc), 
        .rgb(rgb), 
        .rowIndex(rowIndex), 
        .colIndex(colIndex), 
        .currentPiece(currentPiece),
        .cursorX(cursorX),
        .cursorY(cursorY),
        .selectedX(selectedX),
        .selectedY(selectedY),
        .select_enable(select_enable)
    );
    
    wire [3:0] gameState;
    //Performs the game logic based on button inputs. Stores the reg array used for the game board.
    gameboard g(
        .clk(move_clk), 
        .reset(Reset), 
        .gameState(gameState), 
        .rowIndex(rowIndex), 
        .colIndex(colIndex), 
        .cursorX(cursorX), 
        .cursorY(cursorY), 
        .BtnU_db(BtnU_db),
        .BtnR_db(BtnR_db),
        .BtnL_db(BtnL_db),
        .BtnD_db(BtnD_db),
        .BtnC_db(BtnC_db),
        .selectedPiece(selectedPiece),
        .currentPiece(currentPiece),
        .selectedX(selectedX),
        .selectedY(selectedY),
        .select_enable(select_enable)
    );
   
    //Debounce buttons and create a SCEN per button
    ee201_debouncer #(.N_dc(4)) btnU_debouncer (.CLK(move_clk), .RESET(Reset), .PB(BtnU), .DPB(), .SCEN(BtnU_db), .MCEN(), .CCEN());
    ee201_debouncer #(.N_dc(4)) btnR_debouncer (.CLK(move_clk), .RESET(Reset), .PB(BtnR), .DPB(), .SCEN(BtnR_db), .MCEN(), .CCEN());
    ee201_debouncer #(.N_dc(4)) btnL_debouncer (.CLK(move_clk), .RESET(Reset), .PB(BtnL), .DPB(), .SCEN(BtnL_db), .MCEN(), .CCEN());
    ee201_debouncer #(.N_dc(4)) btnD_debouncer (.CLK(move_clk), .RESET(Reset), .PB(BtnD), .DPB(), .SCEN(BtnD_db), .MCEN(), .CCEN());
    ee201_debouncer #(.N_dc(4)) btnC_debouncer (.CLK(move_clk), .RESET(Reset), .PB(BtnC), .DPB(), .SCEN(BtnC_db), .MCEN(), .CCEN());
	
    // SSD (Seven Segment Display)

	//SSDs display 
	//Display the state of the game in SSD1 and the selected piece in SSD0
	assign SSD3 = 4'h0;
	assign SSD2 = 4'h0;
	assign SSD1 = gameState;
	assign SSD0 = selectedPiece;


	// need a scan clk for the seven segment display 
	
	// 100 MHz / 2^18 = 381.5 cycles/sec ==> frequency of DIV_CLK[17]
	// 100 MHz / 2^19 = 190.7 cycles/sec ==> frequency of DIV_CLK[18]
	// 100 MHz / 2^20 =  95.4 cycles/sec ==> frequency of DIV_CLK[19]
	
	// 381.5 cycles/sec (2.62 ms per digit) [which means all 4 digits are lit once every 10.5 ms (reciprocal of 95.4 cycles/sec)] works well.
	
	//                  --|  |--|  |--|  |--|  |--|  |--|  |--|  |--|  |   
    //                    |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | 
	//  DIV_CLK[17]       |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|
	//
	//               -----|     |-----|     |-----|     |-----|     |
    //                    |  0  |  1  |  0  |  1  |     |     |     |     
	//  DIV_CLK[18]       |_____|     |_____|     |_____|     |_____|
	//
	//         -----------|           |-----------|           |
    //                    |  0     0  |  1     1  |           |           
	//  DIV_CLK[19]       |___________|           |___________|
	//

	assign ssdscan_clk = DIV_CLK[19:18];
	assign An0	= !(~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 00
	assign An1	= !(~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 01
	assign An2	=  !((ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 10
	assign An3	=  !((ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 11
	// Turn off another 4 anodes
	assign {An7, An6, An5, An4} = 4'b1111;
	
	always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
				  2'b00: SSD = SSD0;
				  2'b01: SSD = SSD1;
				  2'b10: SSD = SSD2;
				  2'b11: SSD = SSD3;
		endcase 
	end

	// Following is Hex-to-SSD conversion
	always @ (SSD) 
	begin : HEX_TO_SSD
		case (SSD) // in this solution file the dot points are made to glow by making Dp = 0
		    //                                                                abcdefg,Dp
			4'b0000: SSD_CATHODES = 8'b00000010; // 0
			4'b0001: SSD_CATHODES = 8'b10011110; // 1
			4'b0010: SSD_CATHODES = 8'b00100100; // 2
			4'b0011: SSD_CATHODES = 8'b00001100; // 3
			4'b0100: SSD_CATHODES = 8'b10011000; // 4
			4'b0101: SSD_CATHODES = 8'b01001000; // 5
			4'b0110: SSD_CATHODES = 8'b01000000; // 6
			4'b0111: SSD_CATHODES = 8'b00011110; // 7
			4'b1000: SSD_CATHODES = 8'b00000000; // 8
			4'b1001: SSD_CATHODES = 8'b00001000; // 9
			4'b1010: SSD_CATHODES = 8'b00010000; // A
			4'b1011: SSD_CATHODES = 8'b11000000; // B
			4'b1100: SSD_CATHODES = 8'b01100010; // C
			4'b1101: SSD_CATHODES = 8'b10000100; // D
			4'b1110: SSD_CATHODES = 8'b01100000; // E
			4'b1111: SSD_CATHODES = 8'b01110000; // F    
			default: SSD_CATHODES = 8'bXXXXXXXX; // default is not needed as we covered all cases
		endcase
	end	
	
	// reg [7:0]  SSD_CATHODES;
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES};

endmodule
