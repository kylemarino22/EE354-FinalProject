`timescale 1ns / 1ps

module draw(
	input bright,
	input wire [9:0] hCount, vCount,
	output reg [11:0] rgb,
	output reg [2:0] rowIndex, colIndex,
	input wire [3:0] currentPiece,
	
	input wire [2:0] cursorX, cursorY,
	input wire [2:0] selectedX, selectedY,
	input wire select_enable
    );
    
    
    //Define colors used for drawing the board
    localparam BLACK_TILE  = 12'b0110_0011_0001;
    localparam WHITE_TILE  = 12'b1100_1000_0110;
    localparam BLACK_PIECE = 12'b0010_0010_0001;
    localparam WHITE_PIECE = 12'b1100_1100_1011;
    localparam BLACK       = 12'b0000_0000_0000;
    localparam CURSOR      = 12'b0110_1001_1001;
    localparam SELECTED    = 12'b0100_0101_0110;
    
    //Define constants for drawing the chess board background
    localparam row_width = 7'd56;
    localparam col_width = 7'd72;
    localparam h_offset = 10'd160;
    localparam v_offset = 10'd50;
    
    //Pixel art for each piece type
    localparam [62:0] PAWN_PIECE  = { 
        {9'b000000000},
        {9'b000000000},
        {9'b000010000},
        {9'b000111000},
        {9'b000010000},
        {9'b000111000},
        {9'b000000000}
    };
    localparam [62:0] KNIGHT_PIECE  = { 
        {9'b000001000},
        {9'b000111000},
        {9'b001111000},
        {9'b000011000},
        {9'b000011000},
        {9'b001111100},
        {9'b000000000}
    };
    localparam [62:0] BISHOP_PIECE  = { 
        {9'b000010000},
        {9'b000111000},
        {9'b000111000},
        {9'b000010000},
        {9'b000111000},
        {9'b001111100},
        {9'b000000000}
    };
    localparam [62:0] ROOK_PIECE  = { 
        {9'b000000000},
        {9'b001010100},
        {9'b001111100},
        {9'b000111000},
        {9'b000111000},
        {9'b001111100},
        {9'b000000000}
    };
    localparam [62:0] QUEEN_PIECE  = { 
        {9'b001010100},
        {9'b001111100},
        {9'b000111000},
        {9'b000010000},
        {9'b000111000},
        {9'b000111000},
        {9'b001111100}
    };
    localparam [62:0] KING_PIECE  = { 
        {9'b000010000},
        {9'b000111000},
        {9'b000010000},
        {9'b000111000},
        {9'b000111000},
        {9'b000111000},
        {9'b001111100}
    };
    
    //Positions the top left corner to fit the screen
    reg [3:0] xPixel;
    reg [2:0] yPixel;
    reg isPixel;
    reg [2:0] lsb; //used to remove lower 3 bits from pixel index
    
    //Counter for column index
    //Calculates the xPixel index for the square we are currently in
    //Since the pixels used to draw the pieces are an 8x8 square of VGA pixels,
    //we remove the lower 3 bits of the pixel calculation
    always @(*) begin
        if (hCount < col_width + h_offset) begin
            colIndex = 0; {xPixel, lsb} = hCount - h_offset;
        end 
        else if (hCount < col_width*2 + h_offset) begin
            colIndex = 1; {xPixel, lsb} = hCount - h_offset - col_width;
        end
        else if (hCount < col_width*3 + h_offset)begin
            colIndex = 2; {xPixel, lsb} = hCount - h_offset - 2*col_width;
        end
        else if (hCount < col_width*4 + h_offset) begin
            colIndex = 3; {xPixel, lsb} = hCount - h_offset - 3*col_width;
        end
        else if (hCount < col_width*5 + h_offset) begin
            colIndex = 4; {xPixel, lsb} = hCount - h_offset - 4*col_width;
        end
        else if (hCount < col_width*6 + h_offset) begin
            colIndex = 5; {xPixel, lsb} = hCount - h_offset - 5*col_width;
        end
        else if (hCount < col_width*7 + h_offset) begin
            colIndex = 6; {xPixel, lsb} = hCount - h_offset - 6*col_width;
        end
        else begin 
            colIndex = 7; {xPixel, lsb} = hCount - h_offset - 7*col_width;
        end
        
    end
    
    //Counter for row index
    //Calculates the yPixel index for the square we are currently in
    //Since the pixels used to draw the pieces are an 8x8 square of VGA pixels,
    //we remove the lower 3 bits of the pixel calculation
    always @(*) begin
        if (vCount < row_width + v_offset) begin
            rowIndex = 0; {yPixel, lsb} = vCount - v_offset;
        end
        else if (vCount < row_width*2 + v_offset) begin
            rowIndex = 1; {yPixel, lsb} = vCount - v_offset - row_width;
        end
        else if (vCount < row_width*3 + v_offset) begin
            rowIndex = 2; {yPixel, lsb} = vCount - v_offset - 2*row_width;
        end
        else if (vCount < row_width*4 + v_offset) begin
            rowIndex = 3; {yPixel, lsb} = vCount - v_offset - 3*row_width;
        end
        else if (vCount < row_width*5 + v_offset) begin
            rowIndex = 4; {yPixel, lsb} = vCount - v_offset - 4*row_width;
        end
        else if (vCount < row_width*6 + v_offset) begin
            rowIndex = 5; {yPixel, lsb} = vCount - v_offset - 5*row_width;
        end
        else if (vCount < row_width*7 + v_offset) begin
            rowIndex = 6; {yPixel, lsb} = vCount - v_offset - 6*row_width;
        end
        else begin
            rowIndex = 7; {yPixel, lsb} = vCount - v_offset - 7*row_width;
        end
    end
    
    //Determines if a pixel is part of the piece that needs to be drawn
    always@(*) begin
         case(currentPiece [2:0])
            3'd1: isPixel = PAWN_PIECE[62-yPixel*9 - xPixel];
            3'd2: isPixel = KNIGHT_PIECE[62-yPixel*9 - xPixel];
            3'd3: isPixel = BISHOP_PIECE[62-yPixel*9 - xPixel];
            3'd4: isPixel = ROOK_PIECE[62-yPixel*9 - xPixel];
            3'd5: isPixel = QUEEN_PIECE[62-yPixel*9 - xPixel];
            3'd6: isPixel = KING_PIECE[62-yPixel*9 - xPixel];
            default: isPixel = 0;
         endcase
    end
    
    //Determines the color to be drawn
    always @(*) begin
    
        if(~bright ) begin	//force black if not inside the display area
                rgb = BLACK;
        end
        else begin
            if (isPixel) begin //&& rowIndex == 0 && colIndex == 0
                //If piece is black or white
                //if (selectedPiece[3]) begin was if(1)
                if (currentPiece[3]) begin
                    rgb = BLACK_PIECE;
                end else begin
                    rgb = WHITE_PIECE;
                end
            end else begin
                if (select_enable && selectedX == colIndex && selectedY == rowIndex) begin
                    rgb = SELECTED;
                end else if (cursorX == colIndex && cursorY == rowIndex) begin
                    rgb = CURSOR;
                end else if (rowIndex[0]) begin
                    if (colIndex[0]) begin
                        rgb = BLACK_TILE;
                    end else begin
                        rgb = WHITE_TILE;
                    end
                end else begin
                    if (colIndex[0]) begin
                        rgb = WHITE_TILE;
                    end else begin
                        rgb = BLACK_TILE;
                    end
                end
            
            end
            
        end

   end

endmodule
