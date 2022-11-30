`include "/RISCV-CPU/CPU/src/info.v"
module Mem (
	input wire clk,
	input wire rst,
	input wire rdy,

	/* ClearAll */
	input wire Clear_flag,

	/* Get_ins_to_queue() */
	//insqueue
	output reg memctrl_ins_ok__,
	output reg [`DATA_WIDTH] memctrl_ins_ans__,

	input wire insqueue_to_memctrl_needchange,

	input wire [`DATA_WIDTH] memctrl_ins_addr_,
	input wire [3:0] memctrl_ins_remain_cycle_,

	/* do_SLB() */
	//SLB
	output reg memctrl_data_ok__,
	output reg [`DATA_WIDTH] memctrl_data_ans__,

	input wire SLB_to_memctrl_needchange,//load
	input wire SLB_to_memctrl_needchange2,//store
	
	input wire [`INST_TYPE_WIDTH] SLB_to_memctrl_ordertype,
	input wire [`DATA_WIDTH] SLB_to_memctrl_vj,
	input wire [`DATA_WIDTH] SLB_to_memctrl_vk,
	input wire [`DATA_WIDTH] SLB_to_memctrl_A
);


//memctrl
reg [`DATA_WIDTH] memctrl_ins_addr;
reg [3:0] memctrl_ins_remain_cycle;
reg [3:0] memctrl_ins_current_pos;
reg [`DATA_WIDTH] memctrl_ins_ans;// to InstructionQueue
reg memctrl_ins_ok;

reg memctrl_data_l_or_s;//0:load,1:store
reg [`DATA_WIDTH] memctrl_data_addr;
reg [3:0] memctrl_data_remain_cycle;
reg [3:0] memctrl_data_current_pos;
reg [`DATA_WIDTH] memctrl_data_in;//for_store
reg [`DATA_WIDTH] memctrl_data_ans;//for_load
reg memctrl_data_ok;





integer i;

reg [`DATA_WIDTH] pos;


reg flag1;
reg [`RAM_DATA_WIDTH] data_in,data_ans;
reg [`RAM_DATA_WIDTH] ins_in,ins_ans;// ins_in : meaningless

reg en_in;
reg r_nw_in;
reg [16:0] a_in;
reg d_in;
reg d_out;

ram#(
    .ADDR_WIDTH ( 17 )
)u_ram(
    .clk_in  ( clk  ),
    .en_in   ( en_in   ),
    .r_nw_in ( r_nw_in ),
    .a_in    ( a_in    ),
    .d_in    ( d_in    ),
    .d_out   ( d_out   )
);

// do_memctrl() part1
always @(*) begin

	flag1=!( (1<=memctrl_ins_remain_cycle&&memctrl_ins_remain_cycle<=3)||memctrl_ins_remain_cycle==5 )  
		&&memctrl_data_remain_cycle;
	if(flag1) begin//ins不在读，且mem可读
		if(memctrl_data_l_or_s==0) begin//load
			en_in=(1<=memctrl_data_remain_cycle&&memctrl_data_remain_cycle<=4);
			r_nw_in=0;
			a_in=memctrl_data_addr[16:0];
			d_in=data_in;
			data_ans=d_out;
			// mem_ram(need;0;memctrl_data_addr;data_in;data_ans);
		end
		else  begin//store
			if(memctrl_data_current_pos==0) begin
				data_in=memctrl_data_in[7:0];//[7:0]
			end
			if(memctrl_data_current_pos==1) begin
				data_in=memctrl_data_in[15:8];//[15:8]
			end
			if(memctrl_data_current_pos==2) begin
				data_in=memctrl_data_in[23:16];//[23:16]
			end
			if(memctrl_data_current_pos==3) begin
				data_in=memctrl_data_in[31:24];//[31:24]
			end

			en_in=(1<=memctrl_data_remain_cycle&&memctrl_data_remain_cycle<=4);
			r_nw_in=1;
			a_in=memctrl_data_addr[16:0];
			d_in=data_in;
			data_ans=d_out;
			// mem_ram(need;1;memctrl_data_addr;data_in;data_ans);
		end
	end
	else if(memctrl_ins_remain_cycle) begin
		en_in=(1<=memctrl_ins_remain_cycle&&memctrl_ins_remain_cycle<=4);
		r_nw_in=0;
		a_in=memctrl_ins_addr[16:0];
		d_in=ins_in;
		ins_ans=d_out;
		// mem_ram(need;0;memctrl_ins_addr;ins_in;ins_ans);
	end
end

always @(*) begin
	memctrl_ins_ok__=memctrl_ins_ok;
	memctrl_ins_ans__=memctrl_ins_ans;
end

always @(*) begin
	memctrl_data_ok__=memctrl_data_ok;
	memctrl_data_ans__=memctrl_data_ans;
end

always @(posedge clk) begin
	if(rst) begin
		//memctrl
		memctrl_ins_addr<=0;
		memctrl_ins_remain_cycle<=0;
		memctrl_ins_current_pos<=0;
		memctrl_ins_ans<=0;
		memctrl_ins_ok<=0;

		memctrl_data_l_or_s<=0;
		memctrl_data_addr<=0;
		memctrl_data_remain_cycle<=0;
		memctrl_data_current_pos<=0;
		memctrl_data_in<=0;
		memctrl_data_ans<=0;
		memctrl_data_ok<=0;
	end
	else if(~rdy) begin
	end
	else if(Clear_flag) begin
		memctrl_ins_remain_cycle<=0;memctrl_ins_current_pos<=0;memctrl_ins_ok<=0;
		memctrl_data_remain_cycle<=0;memctrl_data_current_pos<=0;memctrl_data_ok<=0;
	end
	else begin
		// do_memctrl() part2
		if(!(flag1&&memctrl_data_l_or_s==0&&memctrl_data_remain_cycle==5)&&
			!(flag1&&memctrl_data_l_or_s==1&&memctrl_data_remain_cycle==1) ) begin
			memctrl_data_ok<=0;
		end
		if( ! (!flag1&&memctrl_ins_remain_cycle&&memctrl_ins_remain_cycle==5) ) begin
			memctrl_ins_ok<=0;
		end
		
		if(flag1) begin//ins不在读，且mem可读
			if(memctrl_data_l_or_s==0) begin//load
				if(memctrl_data_remain_cycle==4) begin
					memctrl_data_remain_cycle<=3;
					memctrl_data_current_pos<=memctrl_data_current_pos+1;
					memctrl_data_addr<=memctrl_data_addr+1;
				end
				if(memctrl_data_remain_cycle==3) begin
					memctrl_data_remain_cycle<=2;
					memctrl_data_current_pos<=memctrl_data_current_pos+1;
					memctrl_data_addr<=memctrl_data_addr+1;
				end
				if(memctrl_data_remain_cycle==2) begin
					memctrl_data_remain_cycle<=1;
					memctrl_data_current_pos<=memctrl_data_current_pos+1;
					memctrl_data_addr<=memctrl_data_addr+1;
				end
				if(memctrl_data_remain_cycle==1) begin
					memctrl_data_remain_cycle<=5;
					memctrl_data_current_pos<=memctrl_data_current_pos+1;
					memctrl_data_addr<=memctrl_data_addr+1;
				end
				if(memctrl_data_remain_cycle==5) begin
					memctrl_data_remain_cycle<=0;
					memctrl_data_current_pos<=0;
					memctrl_data_ok<=1;
				end

				if(memctrl_data_current_pos==1) begin
					memctrl_data_ans[7:0]<=data_ans;//[7:0]
				end
				if(memctrl_data_current_pos==2) begin
					memctrl_data_ans[15:8]<=data_ans;//[15:8]
				end
				if(memctrl_data_current_pos==3) begin
					memctrl_data_ans[23:16]<=data_ans;//[23:16]
				end
				if(memctrl_data_current_pos==4) begin
					memctrl_data_ans[31:24]<=data_ans;//[31:24]
				end

			end
			else  begin//store
				if(memctrl_data_remain_cycle==4) begin
					memctrl_data_remain_cycle<=3;
					memctrl_data_current_pos<=memctrl_data_current_pos+1;
					memctrl_data_addr<=memctrl_data_addr+1;
				end
				if(memctrl_data_remain_cycle==3) begin
					memctrl_data_remain_cycle<=2;
					memctrl_data_current_pos<=memctrl_data_current_pos+1;
					memctrl_data_addr<=memctrl_data_addr+1;
				end
				if(memctrl_data_remain_cycle==2) begin
					memctrl_data_remain_cycle<=1;
					memctrl_data_current_pos<=memctrl_data_current_pos+1;
					memctrl_data_addr<=memctrl_data_addr+1;
				end
				if(memctrl_data_remain_cycle==1) begin
					memctrl_data_remain_cycle<=0;
					memctrl_data_current_pos<=0;
					memctrl_data_ok<=1;
				end
			end
		end
		else if(memctrl_ins_remain_cycle) begin
			if(memctrl_ins_remain_cycle==4) begin
				memctrl_ins_remain_cycle<=3;
				memctrl_ins_current_pos<=memctrl_ins_current_pos+1;
				memctrl_ins_addr<=memctrl_ins_addr+1;
			end
			if(memctrl_ins_remain_cycle==3) begin
				memctrl_ins_remain_cycle<=2;
				memctrl_ins_current_pos<=memctrl_ins_current_pos+1;
				memctrl_ins_addr<=memctrl_ins_addr+1;
			end
			if(memctrl_ins_remain_cycle==2) begin
				memctrl_ins_remain_cycle<=1;
				memctrl_ins_current_pos<=memctrl_ins_current_pos+1;
				memctrl_ins_addr<=memctrl_ins_addr+1;
			end
			if(memctrl_ins_remain_cycle==1) begin
				memctrl_ins_remain_cycle<=5;
				memctrl_ins_current_pos<=memctrl_ins_current_pos+1;
				memctrl_ins_addr<=memctrl_ins_addr+1;
			end
			if(memctrl_ins_remain_cycle==5) begin
				memctrl_ins_remain_cycle<=0;
				memctrl_ins_current_pos<=0;
				memctrl_ins_ok<=1;
			end

			if(memctrl_ins_current_pos==1) begin
				memctrl_ins_ans[7:0]<=ins_ans;//[7:0]
			end
			if(memctrl_ins_current_pos==2) begin
				memctrl_ins_ans[15:8]<=ins_ans;//[15:8]
			end
			if(memctrl_ins_current_pos==3) begin
				memctrl_ins_ans[23:16]<=ins_ans;//[23:16]
			end
			if(memctrl_ins_current_pos==4) begin
				memctrl_ins_ans[31:24]<=ins_ans;//[31:24]
			end

		end

		// from insqueue
		if(insqueue_to_memctrl_needchange) begin
			memctrl_ins_addr<=memctrl_ins_addr_;
			memctrl_ins_remain_cycle<=memctrl_ins_remain_cycle_;
		end

		// from ROB
		//      LoadData()
		if(SLB_to_memctrl_needchange) begin //load
			memctrl_data_l_or_s=0;
			if(SLB_to_memctrl_ordertype==`LB) begin
				pos<=SLB_to_memctrl_vj+SLB_to_memctrl_A;
				memctrl_data_addr<=pos;
				memctrl_data_remain_cycle<=1;
			end
			if(SLB_to_memctrl_ordertype==`LH) begin
				pos<=SLB_to_memctrl_vj+SLB_to_memctrl_A;
				memctrl_data_addr<=pos;
				memctrl_data_remain_cycle<=2;
			end
			if(SLB_to_memctrl_ordertype==`LW) begin
				pos<=SLB_to_memctrl_vj+SLB_to_memctrl_A;
				memctrl_data_addr<=pos;
				memctrl_data_remain_cycle<=4;
			end
			if(SLB_to_memctrl_ordertype==`LBU) begin
				pos<=SLB_to_memctrl_vj+SLB_to_memctrl_A;
				memctrl_data_addr<=pos;
				memctrl_data_remain_cycle<=1;
			end
			if(SLB_to_memctrl_ordertype==`LHU) begin
				pos<=SLB_to_memctrl_vj+SLB_to_memctrl_A;
				memctrl_data_addr<=pos;
				memctrl_data_remain_cycle<=2;
			end
		end
		//      StoreData()
		if(SLB_to_memctrl_needchange2) begin  //store
			memctrl_data_l_or_s=1;
			memctrl_data_in=SLB_to_memctrl_vk;
			if(SLB_to_memctrl_ordertype==`SB) begin
				pos<=SLB_to_memctrl_vj+SLB_to_memctrl_A;
				memctrl_data_addr<=pos;
				memctrl_data_remain_cycle<=1;
			end
			if(SLB_to_memctrl_ordertype==`SH) begin
				pos<=SLB_to_memctrl_vj+SLB_to_memctrl_A;
				memctrl_data_addr<=pos;
				memctrl_data_remain_cycle<=2;
			end
			if(SLB_to_memctrl_ordertype==`SW) begin
				pos<=SLB_to_memctrl_vj+SLB_to_memctrl_A;
				memctrl_data_addr<=pos;
				memctrl_data_remain_cycle<=4;
			end
		end
	end

end



endmodule