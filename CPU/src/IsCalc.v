`include "/RISCV-CPU/CPU/src/info.v"

module IsCalc (
	input wire [`INST_TYPE_WIDTH] type,
	output reg is_Calc
);
always @(*) begin
	if(type==`LUI||type==`AUIPC||type==`ADD||type==`SUB||type==`SLL||type==`SLT||type==`SLTU||
		type==`XOR||type==`SRL||type==`SRA||type==`OR||type==`AND||type==`ADDI||type==`SLTI||type==`SLTIU||
		type==`XORI||type==`ORI||type==`ANDI||type==`SLLI||type==`SRLI||type==`SRAI)
		is_Calc=`TRUE;
end

endmodule