`timescale 1ns / 1ps

module gameboard(
    input wire clk,
    input wire reset,
    
    output reg [3:0] gameState,
    
    input wire [2:0] rowIndex,
    input wire [2:0] colIndex,
    
    output reg [2:0] cursorX, cursorY,
    output reg [2:0] selectedX, selectedY,
    output reg select_enable,
    
    input wire BtnU_db, BtnR_db, BtnL_db, BtnD_db, BtnC_db,
    
    output reg [3:0] currentPiece,
    output reg [3:0] selectedPiece
    );
    
    //Reg array used for the chessBoard. Each piece is stored with 4 bits
    reg [3:0] gameBoard [7:0][7:0];
    reg [3:0] highlightedPiece;
    
    //Define the states of the game
    localparam INITIAL = 4'h1;
    localparam PLAYER1 = 4'h2;
    localparam PLAYER2 = 4'h4;
    
    //Define the piece types
    localparam EMPTY  = 4'd0;
    localparam PAWN   = 3'd1;
    localparam KNIGHT = 3'd2;
    localparam BISHOP = 3'd3;
    localparam ROOK   = 3'd4;
    localparam QUEEN  = 3'd5;
    localparam KING   = 3'd6;
    
    //Define if a piece is black or white
    localparam BLACK  = 1'b1;
    localparam WHITE  = 1'b0;
    
    integer i = 0;
    reg [3:0] gameState_next;
    reg validMove;
    
    //Updates the game state
    always @(posedge clk) begin
        if (reset) begin
            gameState <= INITIAL;
        end else begin
            gameState <= gameState_next;
        end
    end
    
    //Determines the next state for the game
    always @(*) begin
        case (gameState)
            INITIAL: begin
                gameState_next = PLAYER1;
            end
            
            PLAYER1: begin
                //If a piece is selected and the move is valid, the move will be executed and the turns switch
                if (select_enable && BtnC_db && validMove) begin
                    gameState_next = PLAYER2;
                end else begin
                    gameState_next = PLAYER1;
                end
            end
            
            PLAYER2: begin
                 //If a piece is selected and the move is valid, the move will be executed and the turns switch
                if (select_enable && BtnC_db && validMove) begin
                    gameState_next = PLAYER1;
                end else begin
                    gameState_next = PLAYER2;
                end
            end

            default: begin
                gameState_next = INITIAL;
            end
        endcase
    end
    
    //Move the cursor based on button presses
    always @(posedge clk) begin
        if (reset) begin
            cursorX <= 0;
            cursorY <= 0;
        end else if (BtnL_db && cursorX != 0) begin
            cursorX <= cursorX - 1;
        end else if (BtnR_db && cursorX != 7) begin
            cursorX <= cursorX + 1;
        end else if (BtnU_db && cursorY != 0) begin
            cursorY <= cursorY - 1;
        end else if (BtnD_db && cursorY != 7) begin
            cursorY <= cursorY + 1;
        end
    end
    
    //Select a piece to move if it's the player's color
    always @(posedge clk) begin
        if (reset) begin
            select_enable <= 1'b0;
            selectedX <= 0;
            selectedY <= 0;
        end else if (BtnC_db) begin
            select_enable <= 1'b0;
            if (highlightedPiece[2:0] != 3'd0) begin
                selectedX <= cursorX;
                selectedY <= cursorY;
            
                if (highlightedPiece[3] && gameState == PLAYER2) begin 
                    select_enable <= 1'b1;
                end else if (~highlightedPiece[3] && gameState == PLAYER1) begin
                    select_enable <= 1'b1;
                end
            end
        end
    end
    
    //Calculate the difference between the cursor and the selected piece
    wire [3:0] deltaX = cursorX - selectedX;
    wire [3:0] trueDeltaY = selectedY - cursorY;
    wire [3:0] invTrueDeltaY = cursorY - selectedY;
    //Create a deltaY that changes based on the perspective of the player. Positive is away from the player
    wire [3:0] deltaY = selectedPiece[3] ? invTrueDeltaY : trueDeltaY;

    //Check if a vertical move can be done. If a piece is between the cursor and selected piece, then
    //the move cannot be executed.
    reg[7:0] verticalMoveCheckReg;
    always@(*) begin
        verticalMoveCheckReg = 8'b0;
        if (cursorY < selectedY) begin
            for (i = 0; i < 7; i = i+1) begin
                if (i > cursorY && i < selectedY && gameBoard[i][selectedX] != EMPTY) begin
                    //If i is in between the cursor and selected and the piece is not empty
                    verticalMoveCheckReg[i] = 1;
                end else begin
                    verticalMoveCheckReg[i] = 0;
                end
            end
        end else begin
            for (i = 0; i < 7; i = i+1) begin
                if (i < cursorY && i > selectedY && gameBoard[i][selectedX] != EMPTY) begin
                    //If i is in between the cursor and selected and the piece is not empty
                    verticalMoveCheckReg[i] = 1;
                end else begin
                    verticalMoveCheckReg[i] = 0;
                end
            end
        end
    end
    
    //Check if a horizontal move can be done. If a piece is between the cursor and selected piece, then
    //the move cannot be executed.
    reg[7:0] horizontalMoveCheckReg;
    always@(*) begin
        horizontalMoveCheckReg = 8'b0;
        if (cursorX < selectedX) begin
            for (i = 0; i < 7; i = i+1) begin
                if (i > cursorX && i < selectedX && gameBoard[selectedY][i] != EMPTY) begin
                    //If i is in between the cursor and selected and the piece is not empty
                    horizontalMoveCheckReg[i] = 1;
                end else begin
                    horizontalMoveCheckReg[i] = 0;
                end
            end
        end else begin
            for (i = 0; i < 7; i = i+1) begin
                if (i < cursorX && i > selectedX && gameBoard[selectedY][i] != EMPTY) begin
                    //If i is in between the cursor and selected and the piece is not empty
                    horizontalMoveCheckReg[i] = 1;
                end else begin
                    horizontalMoveCheckReg[i] = 0;
                end
            end
        end
    end
    
    
    //Check if a diagonal (with positive slope) move can be done. If a piece is between the cursor
    // and selected piece, then the move cannot be executed.
    reg[7:0] posDiagonalMoveCheckReg;
    //Since the main always block that checks for piece moves makes sure the move is a diagonal,
    //this will project the pieces into a horizontal row to check if there are pieces blocking the move
    always@(*) begin
        posDiagonalMoveCheckReg = 8'b0;
        if (cursorX > selectedX) begin
            for (i = 0; i < 7; i = i+1) begin
                if (i < cursorX && i > selectedX && gameBoard[selectedY+selectedX-i][i] != EMPTY) begin
                    //If i is in between the cursor and selected and the piece is not empty
                    posDiagonalMoveCheckReg[i] = 1;
                end else begin
                    posDiagonalMoveCheckReg[i] = 0;
                end
            end
        end else begin
            for (i = 0; i < 7; i = i+1) begin
                if (i > cursorX && i < selectedX && gameBoard[selectedY+selectedX-i][i] != EMPTY) begin
                    //If i is in between the cursor and selected and the piece is not empty
                    posDiagonalMoveCheckReg[i] = 1;
                end else begin
                    posDiagonalMoveCheckReg[i] = 0;
                end
            end
        end
    end
    
    //Check if a diagonal (with negative slope) move can be done. If a piece is between the cursor
    // and selected piece, then the move cannot be executed.
    reg[7:0] negDiagonalMoveCheckReg;
    //Since the main always block that checks for piece moves makes sure the move is a diagonal,
    //this will project the pieces into a horizontal row to check if there are pieces blocking the move
    always@(*) begin
        negDiagonalMoveCheckReg = 8'b0;
        if (cursorX > selectedX) begin
            for (i = 0; i < 7; i = i+1) begin
                if (i < cursorX && i > selectedX && gameBoard[selectedY-selectedX+i][i] != EMPTY) begin
                    //If i is in between the cursor and selected and the piece is not empty
                    negDiagonalMoveCheckReg[i] = 1;
                end else begin
                    negDiagonalMoveCheckReg[i] = 0;
                end
            end
        end else begin
            for (i = 0; i < 7; i = i+1) begin
                if (i > cursorX && i < selectedX && gameBoard[selectedY-selectedX+i][i] != EMPTY) begin
                    //If i is in between the cursor and selected and the piece is not empty
                    negDiagonalMoveCheckReg[i] = 1;
                end else begin
                    negDiagonalMoveCheckReg[i] = 0;
                end
            end
        end
    end
    

   
    
    //True if the selected piece is not the same color as the highlighted piece
    wire ifNotSameColor = (highlightedPiece[3] != selectedPiece[3] | highlightedPiece == EMPTY);
    //Move validation block. Determines if a move is valid based on piece type.
    always @(*) begin
        validMove = 0;
        case (selectedPiece[2:0])
            PAWN: begin
                //If the highlighted piece is an opponents piece
                if (highlightedPiece[3:0] != EMPTY && highlightedPiece[3] != selectedPiece[3]) begin
                    if (deltaX == 4'hF || deltaX == 4'h1) begin
                        if (deltaY == 1) begin
                            validMove = 1;
                        end
                    end
                end
                else begin
                    //If piece is on the starting row
                    if (deltaX == 0) begin
                        if (selectedY == 3'd1 || selectedY == 3'd6) begin
                            if (deltaY == 1 || deltaY == 2) begin
                                validMove = 1;
                            end
                        end else begin
                            if (deltaY == 1) begin
                                validMove = 1;
                            end
                        end
                    end
                end
            end
            
            ROOK: begin
                if (deltaX == 0 && deltaY != 0) begin
                    if (verticalMoveCheckReg == 0) begin
                        //Don't allow to take piece of same color
                        validMove = ifNotSameColor;
                    end 
                end
                
                if (deltaY == 0 && deltaX != 0) begin
                    if (horizontalMoveCheckReg == 0) begin
                        //Don't allow to take piece of same color
                        validMove = ifNotSameColor;
                    end
                end
            
            end
            
            KNIGHT: begin
                if (deltaY == 4'h2 || deltaY == 4'hE) begin
                    if (deltaX == 4'h1 || deltaX == 4'hF) begin
                        //Don't allow to take piece of same color
                        validMove = ifNotSameColor;
                    end
                end
                
                if (deltaX == 4'h2 || deltaX == 4'hE) begin
                    if (deltaY == 4'h1 || deltaY == 4'hF) begin
                        //Don't allow to take piece of same color
                        validMove = ifNotSameColor;
                    end
                end
            end
            
            BISHOP: begin
                //If move is on positive slope diagonal
                if (deltaX == trueDeltaY) begin
                    if (posDiagonalMoveCheckReg == 0) begin
                        //Don't allow to take piece of same color
                        validMove = ifNotSameColor;
                    end
                end
                
                //Flip sign by adding 8
                if (deltaX == invTrueDeltaY) begin
                    if (negDiagonalMoveCheckReg == 0) begin
                        //Don't allow to take piece of same color
                        validMove = ifNotSameColor;
                    end
                end
            end
            
            QUEEN: begin
                //If move is on positive slope diagonal
                if (deltaX == trueDeltaY) begin
                    if (posDiagonalMoveCheckReg == 0) begin
                        //Don't allow to take piece of same color
                        validMove = ifNotSameColor;
                    end
                end
                
                //Flip sign by adding 8
                if (deltaX == invTrueDeltaY) begin
                    if (negDiagonalMoveCheckReg == 0) begin
                        //Don't allow to take piece of same color
                        validMove = ifNotSameColor;
                    end
                end
                
                if (deltaX == 0 && deltaY != 0) begin
                    if (verticalMoveCheckReg == 0) begin
                        //Don't allow to take piece of same color
                        validMove = ifNotSameColor;
                    end 
                end
                
                if (deltaY == 0 && deltaX != 0) begin
                    if (horizontalMoveCheckReg == 0) begin
                        //Don't allow to take piece of same color
                        validMove = ifNotSameColor;
                    end
                end
            end
            
            KING: begin
                if (deltaY == 4'hF || deltaX == 4'hF || deltaY == 4'h1 || deltaX == 4'h1) begin
                    validMove = ifNotSameColor;
                end
            end
       
            default: validMove = 1;
        endcase
    end
    
    //Updates the gameboard pieces
    always@(posedge clk) begin
        if (gameState == INITIAL) begin
            //Reset the board to the initial state of chess
            gameBoard[0][0] <= {BLACK, ROOK};
            gameBoard[0][1] <= {BLACK, KNIGHT};
            gameBoard[0][2] <= {BLACK, BISHOP};
            gameBoard[0][3] <= {BLACK, QUEEN};
            gameBoard[0][4] <= {BLACK, KING};
            gameBoard[0][5] <= {BLACK, BISHOP};
            gameBoard[0][6] <= {BLACK, KNIGHT};
            gameBoard[0][7] <= {BLACK, ROOK};
            for (i = 0; i < 8; i=i+1) begin
                gameBoard[1][i] <= {BLACK, PAWN};
                gameBoard[6][i] <= {WHITE, PAWN};
                gameBoard[2][i] <= EMPTY;
                gameBoard[3][i] <= EMPTY;
                gameBoard[4][i] <= EMPTY;
                gameBoard[5][i] <= EMPTY;
            end
            gameBoard[7][0] <= {WHITE, ROOK};
            gameBoard[7][1] <= {WHITE, KNIGHT};
            gameBoard[7][2] <= {WHITE, BISHOP};
            gameBoard[7][3] <= {WHITE, QUEEN};
            gameBoard[7][4] <= {WHITE, KING};
            gameBoard[7][5] <= {WHITE, BISHOP};
            gameBoard[7][6] <= {WHITE, KNIGHT};
            gameBoard[7][7] <= {WHITE, ROOK};   
        end else if (gameState == PLAYER1 || gameState == PLAYER2) begin
            if (validMove && select_enable && BtnC_db) begin
                //Move a piece if valid and the button is pressed
                gameBoard[selectedY][selectedX] <= EMPTY;
                gameBoard[cursorY][cursorX] <= gameBoard[selectedY][selectedX];
            end
        end
    end
    
    //Generates the currentPiece as selected by the vga hcount and vcount signals
    //Generates the highlighted piece as selected by the current cursor
    //Generates the selected piece as the piece which was selected by the player
    always @(*) begin
        currentPiece = gameBoard[rowIndex][colIndex];
        highlightedPiece = gameBoard[cursorY][cursorX];
        selectedPiece = gameBoard[selectedY][selectedX];
    end
    
    
endmodule
