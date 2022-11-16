`include "/RISCV-CPU/CPU/src/info.v"

module IsStore (
	input wire [`INST_TYPE_WIDTH] type,
	output reg is_Store
);
always @(*) begin
	if(type==`SB||type==`SH||type==`SW)
		is_Store=`TRUE;
	else is_Store=`FALSE;
end

endmodule