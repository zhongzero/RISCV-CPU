`include "/RISCV-CPU/CPU/src/info.v"
module Reg (
	input wire clk,
	input wire rst,
	input wire rdy,

	/* ClearAll */
	input wire Clear_flag,

	/* do_ins_queue() */
	// insQueue
	input wire [`INST_REG_WIDTH] order_rs1,
	input wire [`INST_REG_WIDTH] order_rs2,

	output reg reg_busy_order_rs1,
	output reg reg_busy_order_rs2,
	output reg [`DATA_WIDTH] reg_reorder_order_rs1,
	output reg [`DATA_WIDTH] reg_reorder_order_rs2,
	output reg [`DATA_WIDTH] reg_reg_order_rs1,
	output reg [`DATA_WIDTH] reg_reg_order_rs2,

	output reg insqueue_to_Reg_needchange,
	output reg [`INST_REG_WIDTH] order_rd,

	input wire reg_busy_order_rd_,
	input wire [`DATA_WIDTH] reg_reorder_order_rd_,

	/* do_ROB() */
	//ROB
	input wire [`INST_REG_WIDTH] commit_rd,

	output reg reg_busy_commit_rd,
	output reg [`ROB_LR_WIDTH] reg_reorder_commit_rd,
	
	input wire ROB_to_Reg_needchange,
	
	input wire [`DATA_WIDTH] reg_reg_commit_rd_,
	input wire reg_busy_commit_rd_
);

reg [`DATA_WIDTH] reg_reg[`MaxReg-1:0];
reg [`DATA_WIDTH] reg_reorder[`MaxReg-1:0];
reg reg_busy[`MaxReg-1:0];


integer i;

always @(*) begin
	reg_busy_order_rs1=reg_busy[order_rs1];
	reg_busy_order_rs2=reg_busy[order_rs2];
	reg_reorder_order_rs1=reg_reorder[order_rs1];
	reg_reorder_order_rs2=reg_reorder[order_rs2];
	reg_reg_order_rs1=reg_reg[order_rs1];
	reg_reg_order_rs2=reg_reg[order_rs2];
end

always @(*) begin
	reg_busy_commit_rd=reg_busy[commit_rd];
	reg_reorder_commit_rd=reg_reorder[commit_rd];
end

always @(posedge clk) begin
	if(rst) begin
		// Reg
		for(i=0;i<`MaxReg;i=i+1) begin
			reg_reg[i]<=0;
			reg_reorder[i]<=0;
			reg_busy[i]<=0;
		end

	end
	else if(~rdy) begin
	end
	else if(Clear_flag) begin
		for(i=0;i<`MaxReg;i++)reg_busy[i]<=0;
	end
	else begin
		// from insqueue
		if(insqueue_to_Reg_needchange) begin
			reg_busy[order_rd]<=reg_busy_order_rd_;
			reg_reorder[order_rd]<=reg_reorder_order_rd_;
		end

		// from ROB
		if(ROB_to_Reg_needchange) begin
			reg_reg[commit_rd]<=reg_reg_commit_rd_;
			reg_busy[commit_rd]<=reg_busy_commit_rd_;
		end
	end

end



endmodule