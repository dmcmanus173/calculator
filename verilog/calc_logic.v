 `timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University College Dublin
// Engineer: Oluwademilade Oke, Daniel McManus
// 
// Create Date: 15.11.2018 10:39:16
// Design Name: 
// Module Name: myCalc
// Project Name: LAST LAB WAHOOOOO!
// Target Devices: XC7A100TCSG324-1
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module calc_logic(
   input clk,
   input rst,
   input [4:0] keycode,
   input newkey,
   output [15:0] Xdisplay,
   output LED_NEG_digit,
   output LED_OVW
   );
   
   //MAPPING KEYS
   localparam[4:0] KEY_CE = 5'b01100,
                   KEY_CA = 5'b00100,
                   KEY_MULTI = 5'b01001,
                   KEY_SUB = 5'b01010,
                   KEY_ADD = 5'b01011,
                   KEY_SQR = 5'b00001,
                   KEY_CH_SIGN = 5'b00010,
                   KEY_EQUALS = 5'b00011;
                   
   
   //reg signals
   reg signed [17:0] X, nextX, Y, nextY, ANS;
   reg [1:0] OP, nextOP;
   
   
   //CONTROL SIGNALS
   wire ADD = (OP == KEY_ADD [1:0]);
   wire SUB = (OP == KEY_SUB [1:0]);
   wire MULTI = (OP == KEY_MULTI [1:0]);        
   wire OP_T2 = (newkey && (keycode[4:2] == 3'b010) );
   wire CA = (newkey && (keycode == KEY_CA) );             
   wire CE = (newkey && (keycode == KEY_CE) );
   wire digit = (newkey && (keycode[4] == 1'b1) );
   wire EQUALS = (newkey && (keycode == KEY_EQUALS) );
   wire SQR = (newkey && (keycode == KEY_SQR) );
   wire CH_SIGN = (newkey && (keycode == KEY_CH_SIGN) );
   wire [6:0] CONTROL = {CE, CA, OP_T2, digit, EQUALS, SQR, CH_SIGN}; //creating control signal to be used in NEXTX multiplexer
   
   //OPERATION SIGNALS
   wire signed [17:0] ANS_ADD, ANS_MULTI, ANS_SUB, ANS_SQR, ANS_CH_SIGN;
   
   //OPERATIONS
   assign ANS_ADD = X+Y;
   assign ANS_SUB = Y-X;
   assign ANS_MULTI = X*Y;
   assign ANS_SQR = X*X;
   assign ANS_CH_SIGN = X*-1; //this can never cause overflow
   
   //OUTPUT SIGNALS
   assign LED_OVW = X[16]; 
   assign Xdisplay = X[15:0];
   assign LED_NEG_digit = X[17]; //negative light
   
   
   //MULTIPLEXER ANS
   always @ (ADD, MULTI, SUB, ANS_ADD, ANS_MULTI, ANS_SUB, X)
       case({ADD, SUB, MULTI})
           3'b100: ANS = ANS_ADD;
           3'b010: ANS = ANS_SUB;
           3'b001: ANS = ANS_MULTI;
           default: ANS = X;
       endcase   
   
   
   //MULTIPLEXER NEXTX
   always @ (CONTROL, X, keycode, ANS, ANS_SQR, ANS_CH_SIGN)
       casez(CONTROL)
           7'b1000000: nextX = 18'b0;
           7'b?1?????: nextX = 18'b0;
           7'b0010000: nextX = 18'b0;
           7'b0001000: nextX = {X[12:0], keycode[3:0]}; //shifting keycode into register
           7'b0000100: nextX = ANS;
           7'b0000010: nextX = ANS_SQR;
           7'b0000001: nextX = ANS_CH_SIGN;
           default: nextX = X;
       endcase
       
       
   //regX
   always @ (posedge clk or posedge rst)
   begin
       if(rst) X <= 18'b0;
       else X <= nextX;
   end
   
   
   //Multiplexer for Next Y
   always @ (OP_T2, CA, Y, X)
       case({OP_T2, CA})
           2'b00: nextY = Y;
           2'b10: nextY = X;
           default: nextY = 18'b0;
       endcase
       
       
   //REG Y
   always @ (posedge clk or posedge rst)
     begin
         if(rst) Y <= 18'b0;
         else Y <= nextY;
     end

     
   //Multiplexer for nextOP
   always @ (OP_T2, CA, keycode, OP)
       case({OP_T2, CA})
           2'b00: nextOP = OP;
           2'b10: nextOP = keycode[1:0];
           default: nextOP = 2'b0;
       endcase
       
       
   //REG OP
   always @ (posedge clk or posedge rst)
     begin
         if(rst) OP <= 2'b0;
         else OP <= nextOP;
     end
     
     
   endmodule
