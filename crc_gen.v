`timescale 1ns/100ps
module crc_gen
#(
parameter C_DWIDTH      = 8            ,       //input data width
parameter C_GEN_WIDTH   = 32           ,       //generator polynomial width
parameter C_GEN_SEQ     = 32'h04c11db7 ,       //generator polynomial
parameter C_INIT        = 32'hffff_ffff,       //initial value
parameter C_IN_INVERT   = 0            ,       //input data invert,high valid
parameter C_BIT_REVERSE = 0            ,       //output bit reverse,high valid
parameter C_BYTE_INVERT = 0            ,       //output invert in byte,high valid
parameter C_REG         = 0                    //output throught register
)
(
input                        I_clk          ,  //clock
input                        I_rst          ,  //sync reset,high valid
input      [C_DWIDTH-1:0]    I_data         ,  //input data
input                        I_data_v       ,  //input data valid
input                        I_start_pulse  ,  //a pulse to initalize calculation before data
output     [C_GEN_WIDTH-1:0] O_crc          ,  //crc result
output                       O_crc_v           //a pulse to indicate crc result valid
);

//----------crc table----------------
//crc32  
//x^32+x^26+x^23+x^22+x^16+x^12+x^11+x^10+x^8+x^7+x^5+x^4+x^2+x+1
//crc-ccitt
// x^16+x^12+x^5+1
//crc4
//x^4+x+1
//-----------------------------------

reg  [C_GEN_WIDTH-1:0] S_crc = 0    ;
reg                    S_data_v = 0 ;
wire [C_DWIDTH-1:0]    S_data       ;
wire [C_GEN_WIDTH-1:0] S_crc_reverse;
wire [C_GEN_WIDTH-1:0] S_crc_out    ;
wire                   S_crc_v      ;

assign S_data = C_IN_INVERT ? F_data_invert(I_data) : I_data;
assign S_crc_out = C_BIT_REVERSE ? ~S_crc : S_crc;
assign S_crc_v = (!I_data_v) && S_data_v;

always @(posedge I_clk)
begin
    if(I_start_pulse)
        S_crc <= C_INIT;
    else if(I_data_v)
        S_crc <= F_crc_gen(S_crc,S_data);
    S_data_v <= I_data_v;
end

generate
if(C_REG == 1)
begin:reg_out

reg [C_GEN_WIDTH-1:0] S_crc_reg = 0;
reg S_crc_v_reg = 0;

always @(posedge I_clk)
begin
    S_crc_reg <= C_BYTE_INVERT ? F_byte_inv(S_crc_out) : S_crc_out;
    S_crc_v_reg <= S_crc_v;
end
assign O_crc = S_crc_reg;
assign O_crc_v = S_crc_v_reg;

end
else
begin
    
assign O_crc = C_BYTE_INVERT ? F_byte_inv(S_crc_out) : S_crc_out;
assign O_crc_v = S_crc_v;   
    
end

endgenerate


function [C_GEN_WIDTH-1:0] F_byte_inv;
input [C_GEN_WIDTH-1:0] I_data;
integer i,j;
begin
    for(i=0;i<C_GEN_WIDTH/8;i=i+1)
    for(j=0;j<8;j=j+1)
        F_byte_inv[i*8+j] = I_data[i*8+7-j];
end
endfunction

function [C_GEN_WIDTH-1:0] F_crc_gen;
input [C_GEN_WIDTH-1:0] I_data1;
input [C_DWIDTH-1:0] I_data2;
integer i,j;
reg [C_GEN_WIDTH-1:0] S_data1;
begin
    F_crc_gen = I_data1;
    for(i=0;i<C_DWIDTH;i=i+1)
    begin   
        F_crc_gen[C_GEN_WIDTH-1:0] = {F_crc_gen[C_GEN_WIDTH-2:0],1'b0} ^ ({C_GEN_WIDTH{F_crc_gen[C_GEN_WIDTH-1] ^ I_data2[i]}} & C_GEN_SEQ[C_GEN_WIDTH-1:0]);
    end
end
endfunction

function [C_DWIDTH-1:0] F_data_invert;
input [C_DWIDTH-1:0] I_data;
integer i;
begin
    for(i=0;i<C_DWIDTH;i=i+1)
        F_data_invert[i] = I_data[C_DWIDTH-1-i];
end
endfunction


endmodule




