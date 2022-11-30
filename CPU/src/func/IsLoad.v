`include "/RISCV-CPU/CPU/src/info.v"

module IsLoad (
	input wire [`INST_TYPE_WIDTH] type,
	output reg is_Load
);
always @(*) begin
	if(type==`LB||type==`LH||type==`LW||type==`LBU||type==`LHU)
		is_Load=`TRUE;
	else is_Load=`FALSE;
end

endmodule