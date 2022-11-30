`include "/RISCV-CPU/CPU/src/info.v"
module BHT (
	input wire clk,
	input wire rst,
	input wire rdy,

	/* ClearAll */
	input wire Clear_flag,

	/* Get_ins_to_queue() */
	//   BranchJudge()
	//insqueue
	input wire [`BHT_LR_WIDTH] bht_id1,	
	output reg bht_get,

	/* do_ROB() */
	//ROB
	input wire ROB_to_BHT_needchange, // predict wrong
	input wire ROB_to_BHT_needchange2, // predict correct
	input wire [`BHT_LR_WIDTH] bht_id2
);


reg BHT_s[`MaxBHT-1:0][1:0];// 00 强不跳； 01 弱不跳； 10 弱跳； 11 弱不跳


integer i;

// BranchJudge()
always @(*) begin
	if(BHT_s[bht_id1][0]==0)bht_get=0;
	else bht_get=1;
end



always @(posedge clk) begin
	if(rst) begin
		// BHT
		for(i=0;i<`MaxBHT;i=i+1) begin
			BHT_s[i][0]<=0;
			BHT_s[i][1]<=0;
		end
	end
	else if(~rdy) begin
	end
	else if(Clear_flag) begin
	end
	else begin
		// from ROB
		if(ROB_to_BHT_needchange) begin //predict wrong
			if(BHT_s[bht_id2][0]==0&&BHT_s[bht_id2][1]==0) begin
				BHT_s[bht_id2][0]<=0;BHT_s[bht_id2][1]<=1;
			end
			if(BHT_s[bht_id2][0]==0&&BHT_s[bht_id2][1]==1) begin
				BHT_s[bht_id2][0]<=1;BHT_s[bht_id2][1]<=0;
			end
			if(BHT_s[bht_id2][0]==1&&BHT_s[bht_id2][1]==0) begin
				BHT_s[bht_id2][0]<=0;BHT_s[bht_id2][1]<=1;
			end
			if(BHT_s[bht_id2][0]==1&&BHT_s[bht_id2][1]==1) begin
				BHT_s[bht_id2][0]<=1;BHT_s[bht_id2][1]<=0;
			end
			
		end
		if(ROB_to_BHT_needchange2) begin //predict correct
			if(BHT_s[bht_id2][0]==0&&BHT_s[bht_id2][1]==0) begin
				BHT_s[bht_id2][0]<=0;BHT_s[bht_id2][1]<=0;
			end
			if(BHT_s[bht_id2][0]==0&&BHT_s[bht_id2][1]==1) begin
				BHT_s[bht_id2][0]<=0;BHT_s[bht_id2][1]<=0;
			end
			if(BHT_s[bht_id2][0]==1&&BHT_s[bht_id2][1]==0) begin
				BHT_s[bht_id2][0]<=1;BHT_s[bht_id2][1]<=1;
			end
			if(BHT_s[bht_id2][0]==1&&BHT_s[bht_id2][1]==1) begin
				BHT_s[bht_id2][0]<=1;BHT_s[bht_id2][1]<=1;
			end
		end
	end

end



endmodule