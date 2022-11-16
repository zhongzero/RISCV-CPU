`include "/RISCV-CPU/CPU/src/info.v"

module IF (
	input wire clk,
	input wire rst,
	input wire rdy,

	//MemCtrl
	output reg [`ADDR_WIDTH] pc_to_MemCtrl,
	output reg isNeed_to_MemCtrl,
	input wire [`DATA_WIDTH] inst_from_MemCtrl,
	input wire isOk_from_MemCtrl,

);

reg [`ADDR_WIDTH] pc;

reg [`ADDR_WIDTH] queue[`InstQueue_Size];
reg [`InstQueue_ADDR_WIDTH] head,tail,size;

reg [`DATA_WIDTH] inst;
reg [`INST_TYPE_WIDTH] type;
reg [`INST_REG_WIDTH] rd;
reg [`INST_REG_WIDTH] rs1;
reg [`INST_REG_WIDTH] rs2;
reg [`DATA_WIDTH] im;
assign inst=;

Decode my_Decode(
    .inst ( inst ),
    .type ( type ),
    .rd   ( rd   ),
    .rs1  ( rs1  ),
    .rs2  ( rs2  ),
    .imm  ( imm  )
);


always @(posedge clk) begin
	if(rst) begin
		//pc
		pc<=0;

		//MemCtrl
		pc_to_MemCtrl<=0;
		isNeed_to_MemCtrl<=`FALSE;

		//queue
		head<=1;
		tail<=0;
		size<=0;
	end
	else if(~rdy) begin
	end
	else begin
		if(~isNeed_from_InstQueue) begin
			//MemCtrl
			isNeed_to_MemCtrl<=`FALSE;
		end
		else begin
			//pc
			pc<=pc+4;
			// if() begin
			// 	pc<=pc+4;
			// end
			// else begin
			// 	pc<=;
			// end

			if(isOk_from_MemCtrl) begin
				//inst/isok
				inst<=pc_to_MemCtrl;
				isOk<=`TRUE;

				//MemCtrl
				pc_to_MemCtrl<=pc;
				isNeed_to_MemCtrl<=`TRUE;
			end
			else begin

			end


		end

		//InstQueue
	end

end

endmodule