`include "/mnt/e/RISCV-CPU/CPU/src/info.v"
// `include "/RISCV-CPU/CPU/src/info.v"

module EX (
	input wire [`INST_TYPE_WIDTH] ordertype,
	input wire [`DATA_WIDTH] vj,
	input wire [`DATA_WIDTH] vk,
	input wire [`DATA_WIDTH] A,
	input wire [`DATA_WIDTH] pc,
	output reg [`DATA_WIDTH] value,
	output reg [`DATA_WIDTH] jumppc
);
always @(*) begin
	if(ordertype==`LUI)value=A;
	if(ordertype==`AUIPC)value=pc+A;

	if(ordertype==`ADD)value=vj+vk;
	if(ordertype==`SUB)value=vj-vk;
	if(ordertype==`SLL)value=vj<<(vk&5'h1f);
	if(ordertype==`SLT)value=($signed(vj)<$signed(vk))?1:0;
	if(ordertype==`SLTU)value=(vj<vk)?1:0;
	if(ordertype==`XOR)value=vj^vk;
	if(ordertype==`SRL)value=vj>>(vk&5'h1f);
	if(ordertype==`SRA)value=$signed(vj)>>(vk&5'h1f);
	if(ordertype==`OR)value=vj|vk;
	if(ordertype==`AND)value=vj&vk;

	if(ordertype==`JALR) begin
		jumppc=(vj+A)&(~1);
		value=pc+4;
	end


	if(ordertype==`ADDI)value=vj+A;
	if(ordertype==`SLTI)value=($signed(vj)<$signed(A))?1:0;
	if(ordertype==`SLTIU)value=(vj<A)?1:0;
	if(ordertype==`XORI)value=vj^A;
	if(ordertype==`ORI)value=vj|A;
	if(ordertype==`ANDI)value=vj&A;
	if(ordertype==`SLLI)value=vj<<A;
	if(ordertype==`SRLI)value=vj>>A;
	if(ordertype==`SRAI)value=$signed(vj)>>A;
	

	if(ordertype==`JAL) begin
		value=pc+4;
	end


	if(ordertype==`BEQ) begin
		value=(vj==vk?1:0);
	end
	if(ordertype==`BNE) begin
		value=(vj!=vk?1:0);
	end
	if(ordertype==`BLT) begin
		value=($signed(vj)<$signed(vk)?1:0);
	end
	if(ordertype==`BGE) begin
		value=($signed(vj)>=$signed(vk)?1:0);
	end
	if(ordertype==`BLTU) begin
		value=(vj<vk?1:0);
	end
	if(ordertype==`BGEU) begin
		value=(vj>=vk?1:0);
	end
end

endmodule