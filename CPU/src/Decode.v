`include "/RISCV-CPU/CPU/src/info.v"

module Decode (
	input wire [`DATA_WIDTH] inst,
	output reg [`INST_TYPE_WIDTH] type,
	output reg [`INST_REG_WIDTH] rd,
	output reg [`INST_REG_WIDTH] rs1,
	output reg [`INST_REG_WIDTH] rs2,
	output reg [`DATA_WIDTH] imm
);
wire [6:0] type1;
wire [2:0] type2;
wire [6:0] type3;
assign type1=inst[6:0];
assign type2=inst[14:12];
assign type3=inst[31:25];
always @(*) begin
	rd=inst[11:7];
	rs1=inst[19:15];
	rs2=inst[24:20];
	if(type1==7'h37||type1==7'h17) begin //U类型
		if(type1==7'h37)type=`LUI;
		if(type1==7'h17)type=`AUIPC;
		imm={inst[31:12],12'b0};
	end

	if(type1==7'h33) begin //R类型
		if(type2==3'h0) begin
			if(type3==7'h00)type=`ADD;
			if(type3==7'h20)type=`SUB;
		end
		if(type2==3'h1)type=`SLL;
		if(type2==3'h2)type=`SLT;
		if(type2==3'h3)type=`SLTU;
		if(type2==3'h4)type=`XOR;
		if(type2==3'h5) begin
			if(type3==7'h00)type=`SRL;
			if(type3==7'h20)type=`SRA;
		end
		if(type2==3'h6)type=`OR;
		if(type2==3'h7)type=`AND;
	end

	if(type1==7'h67||type1==7'h03||type1==7'h13) begin //I类型
		if(type1==7'h67)type=`JALR;
		if(type1==7'h03) begin
			if(type2==3'h0)type=`LB;
			if(type2==3'h1)type=`LH;
			if(type2==3'h2)type=`LW;
			if(type2==3'h4)type=`LBU;
			if(type2==3'h5)type=`LHU;
		end
		if(type1==7'h13) begin
			if(type2==3'h0)type=`ADDI;
			if(type2==3'h2)type=`SLTI;
			if(type2==3'h3)type=`SLTIU;
			if(type2==3'h4)type=`XORI;
			if(type2==3'h6)type=`ORI;
			if(type2==3'h7)type=`ANDI;
			if(type2==3'h1)type=`SLLI;
			if(type2==3'h5) begin
				if(type3==7'h00)type=`SRLI;
				if(type3==7'h20)type=`SRAI;
			end
		end
		imm[31:0]={20'b0,inst[31:20]};
	end

	if(type1==7'h23) begin //S类型
		if(type2==3'h0)type=`SB;
		if(type2==3'h1)type=`SH;
		if(type2==3'h2)type=`SW;
		imm[31:0]={20'b0,inst[31:25],inst[11:7]};
	end

	if(type1==7'h6f) begin //J类型
		type=`JAL;
		imm[31:0]={11'b0,inst[31],inst[19:12],inst[20],inst[30:21],1'b0};
	end

	if(type1==7'h63) begin //B类型
		if(type2==3'h0)type=`BEQ;
		if(type2==3'h1)type=`BNE;
		if(type2==3'h4)type=`BLT;
		if(type2==3'h5)type=`BGE;
		if(type2==3'h6)type=`BLTU;
		if(type2==3'h7)type=`BGEU;
		imm[31:0]={19'd0,inst[31],inst[7],inst[30:25],inst[11:8],1'b0};
	end

	if(type==`JALR||type==`LB||type==`LH||type==`LW||type==`LBU||type==`LHU) begin
		if(imm>>11)imm=imm|32'hfffff000;
	end
	if(type==`ADDI||type==`SLTI||type==`SLTIU||type==`XORI||type==`ORI||type==`ANDI) begin
		if(imm>>11)imm|=32'hfffff000;
	end
	if(type==`SB||type==`SH||type==`SW) begin
		if(imm>>11)imm|=32'hfffff000;
	end
	if(type==`JAL) begin
		if(imm>>20)imm|=32'hfff00000;
	end
	if(type==`BEQ||type==`BNE||type==`BLT||type==`BGE||type==`BLTU||type==`BGEU) begin
		if(imm>>12)imm|=32'hffffe000;
	end


end

endmodule