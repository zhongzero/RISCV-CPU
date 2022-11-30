`include "/RISCV-CPU/CPU/src/info.v"
// `include "/RISCV-CPU/CPU/src/func/Decode.v"
// `include "/RISCV-CPU/CPU/src/func/IsBranch.v"
// `include "/RISCV-CPU/CPU/src/func/IsLoad.v"
// `include "/RISCV-CPU/CPU/src/func/IsStore.v"
module InstQueue (
	input wire clk,
	input wire rst,
	input wire rdy,

	/* ClearAll */
	input wire Clear_flag,

	/* Get_ins_to_queue() */
	//memctrl
	input wire memctrl_ins_ok,
	input wire [`DATA_WIDTH] memctrl_ins_ans,

	output reg insqueue_to_memctrl_needchange,

	output reg [`DATA_WIDTH] memctrl_ins_addr_,
	output reg [3:0] memctrl_ins_remain_cycle_,

	//   Search_In_ICache()
	//icache
	output reg [`DATA_WIDTH] addr1,
	input wire hit,
	input wire [`DATA_WIDTH] returnInst,

	//   Store_In_ICache()
	//icache
	output reg [`DATA_WIDTH] addr2,
	output reg [`DATA_WIDTH] storeInst,

	//   BranchJudge()
	//BHT
	output reg [`BHT_LR_WIDTH] bht_id1,
	input wire bht_get,


	/* do_ins_queue() */
	//ROB
	output reg [`ROB_LR_WIDTH] h1,
	output reg [`ROB_LR_WIDTH] h2,

	input wire [`ROB_LR_WIDTH] ROB_size,
	input wire [`ROB_LR_WIDTH] ROB_R,
	input wire ROB_s_ready_h1,
	input wire [`DATA_WIDTH] ROB_s_value_h1,
	input wire ROB_s_ready_h2,
	input wire [`DATA_WIDTH] ROB_s_value_h2,

	output reg insqueue_to_ROB_needchange,
	output reg insqueue_to_ROB_size_addflag,
	output reg [`ROB_LR_WIDTH] b1,

	output reg [`ROB_LR_WIDTH] ROB_R_,
	output reg [`DATA_WIDTH] ROB_s_pc_b1_,
	output reg [`DATA_WIDTH] ROB_s_inst_b1_,
	output reg [`INST_TYPE_WIDTH] ROB_s_ordertype_b1_,
	output reg [`INST_REG_WIDTH] ROB_s_dest_b1_,
	output reg [`DATA_WIDTH] ROB_s_jumppc_b1_,
	output reg ROB_s_isjump_b1_,
	output reg ROB_s_ready_b1_,

	//RS
	input wire [`RS_LR_WIDTH] RS_unbusy_pos,

	output reg insqueue_to_RS_needchange,
	output reg [`RS_LR_WIDTH] r2,

	output reg [`DATA_WIDTH] RS_s_vj_r2_,
	output reg [`DATA_WIDTH] RS_s_vk_r2_,
	output reg [`DATA_WIDTH] RS_s_qj_r2_,
	output reg [`DATA_WIDTH] RS_s_qk_r2_,
	output reg [`DATA_WIDTH] RS_s_inst_r2_,
	output reg [`INST_TYPE_WIDTH] RS_s_ordertype_r2_,
	output reg [`DATA_WIDTH] RS_s_pc_r2_,
	output reg [`DATA_WIDTH] RS_s_jumppc_r2_,
	output reg [`DATA_WIDTH] RS_s_A_r2_,
	output reg [`DATA_WIDTH] RS_s_reorder_r2_,
	output reg RS_s_busy_r2_,

	//SLB
	input wire [`SLB_LR_WIDTH] SLB_size,
	input wire [`SLB_LR_WIDTH] SLB_R,

	output reg insqueue_to_SLB_needchange,
	output reg insqueue_to_SLB_size_addflag,
	output reg [`SLB_LR_WIDTH] r1,

	output reg [`SLB_LR_WIDTH] SLB_R_,
	output reg [`DATA_WIDTH] SLB_s_vj_r1_,
	output reg [`DATA_WIDTH] SLB_s_vk_r1_,
	output reg [`DATA_WIDTH] SLB_s_qj_r1_,
	output reg [`DATA_WIDTH] SLB_s_qk_r1_,
	output reg [`DATA_WIDTH] SLB_s_inst_r1_,
	output reg [`DATA_WIDTH] SLB_s_ordertype_r1_,
	output reg [`DATA_WIDTH] SLB_s_pc_r1_,
	output reg [`DATA_WIDTH] SLB_s_A_r1_,
	output reg [`DATA_WIDTH] SLB_s_reorder_r1_,
	output reg SLB_s_ready_r1_,

	//Reg
	output reg [`INST_REG_WIDTH] order_rs1,
	output reg [`INST_REG_WIDTH] order_rs2,

	input wire reg_busy_order_rs1,
	input wire reg_busy_order_rs2,
	input wire [`DATA_WIDTH] reg_reorder_order_rs1,
	input wire [`DATA_WIDTH] reg_reorder_order_rs2,
	input wire [`DATA_WIDTH] reg_reg_order_rs1,
	input wire [`DATA_WIDTH] reg_reg_order_rs2,
	
	output reg insqueue_to_Reg_needchange,
	output reg [`INST_REG_WIDTH] order_rd,

	output reg reg_busy_order_rd_,
	output reg [`DATA_WIDTH] reg_reorder_order_rd_,





	/* do_ROB() */
	//ROB
	input wire ROB_to_insqueue_needchange,
	input wire [`DATA_WIDTH] pc_ // 这个更改pc的优先级高于Get_ins_to_queue()的优先级 !!!
);

//pc
reg [`DATA_WIDTH] pc;

//Ins_queue
reg [`DATA_WIDTH] Ins_queue_s_inst[`MaxIns-1:0];
reg [`DATA_WIDTH] Ins_queue_s_pc[`MaxIns-1:0];
reg [`DATA_WIDTH] Ins_queue_s_jumppc[`MaxIns-1:0];
reg Ins_queue_s_isjump[`MaxIns-1:0];
reg [`INST_TYPE_WIDTH] Ins_queue_s_ordertype[`MaxIns-1:0];
reg [`INSQUEUE_LR_WIDTH] Ins_queue_L,Ins_queue_R,Ins_queue_size;
reg Ins_queue_is_waiting_ins;



//for Get_ins_to_queue()

reg [`DATA_WIDTH] inst;
wire [`INST_TYPE_WIDTH] order_type_0;
wire [`INST_REG_WIDTH] order_rd_0;
wire [`INST_REG_WIDTH] order_rs1_0;
wire [`INST_REG_WIDTH] order_rs2_0;
wire [`DATA_WIDTH] order_imm_0;

Decode u_Decode1(
    .inst ( inst ),
    .order_type ( order_type_0 ),
    .order_rd   ( order_rd_0   ),
    .order_rs1  ( order_rs1_0  ),
    .order_rs2  ( order_rs2_0  ),
    .order_imm  ( order_imm_0  )
);

wire isbranch;
IsBranch u_IsBranch(
    .type ( order_type_0 ),
    .is_Branch  ( isbranch  )
);


//for do_ins_queue()

wire [`INST_TYPE_WIDTH] order_type;
wire [`INST_REG_WIDTH] order_rd_;
wire [`INST_REG_WIDTH] order_rs1_;
wire [`INST_REG_WIDTH] order_rs2_;
wire [`DATA_WIDTH] order_imm;

Decode u_Decode2(
    .inst ( Ins_queue_s_inst[Ins_queue_L] ),
    .order_type ( order_type ),
    .order_rd   ( order_rd_   ),
    .order_rs1  ( order_rs1_  ),
    .order_rs2  ( order_rs2_  ),
    .order_imm  ( order_imm  )
);

always @(*) begin
	order_rd=order_rd_;
	order_rs1=order_rs1_;
	order_rs2=order_rs2_;
end

wire isload;
IsLoad u_IsLoad(
    .type ( Ins_queue_s_ordertype[Ins_queue_L] ),
    .is_Load  ( isload  )
);

wire isstore;
IsStore u_IsStore(
    .type ( Ins_queue_s_ordertype[Ins_queue_L] ),
    .is_Store  ( isstore  )
);

reg insqueue_size_internal_addflag;

integer g;



integer i;


// Get_ins_to_queue() part1
always @(*) begin
	insqueue_size_internal_addflag=0;

	insqueue_to_memctrl_needchange=0;

	if(!Ins_queue_is_waiting_ins&&Ins_queue_size!=`MaxIns) begin
		addr1=pc;
		// hit=hit;
		inst=returnInst;
		// Search_In_ICache(pc;hit;inst);
		if(!hit) begin
			insqueue_to_memctrl_needchange=1;
			memctrl_ins_addr_=pc;
			memctrl_ins_remain_cycle_=4;
		end
	end
	if(memctrl_ins_ok) begin
		inst=memctrl_ins_ans;
		addr2=pc;
		storeInst=memctrl_ins_ans;
		// Store_In_ICache(pc;memctrl_ins_ans);
	end
	if(memctrl_ins_ok||hit) begin
		// Order order=Decode(inst);
		
		g=(Ins_queue_R+1)%`MaxIns;
		insqueue_size_internal_addflag=1;
		// Ins_queue_size++;

		// isBranch(order_type_0,isbranch);
		if(isbranch) begin
			//JAL 直接跳转
			//目前强制pc不跳转；JALR默认不跳转，让它必定预测失败
			if(order_type_0==`JAL);
			else  begin
				if(order_type_0==`JALR);
				else  begin
					bht_id1=Ins_queue_s_inst[g][11:0];
					// BranchJudge(Ins_queue_s_inst[g][11:0]);
				end
			end
		end
	end
end

reg insqueue_size_internal_subflag;

// do_ins_queue() part1
always @(*) begin
	insqueue_size_internal_subflag=0;
	
	insqueue_to_RS_needchange=0;

	insqueue_to_SLB_needchange=0;
	insqueue_to_SLB_size_addflag=0;

	insqueue_to_ROB_needchange=0;
	insqueue_to_ROB_size_addflag=0;
	
	insqueue_to_Reg_needchange=0;


	//InstructionQueue为空，因此取消issue InstructionQueue中的指令
	if(Ins_queue_size==0);
	//ROB满了，因此取消issue InstructionQueue中的指令
	else if(ROB_size==`MaxROB);
	else begin
		// isLoad(Ins_queue_s_ordertype,isload[Ins_queue_L]);
		// isStore(Ins_queue_s_ordertype,isstore[Ins_queue_L]);
		if(isload||isstore) begin //load指令(LB;LH;LW;LBU;LHU) or store指令(SB;SH;SW)
			
			//SLB满了，因此取消issue InstructionQueue中的指令
			if(SLB_size==`MaxSLB);
			else begin
				insqueue_to_SLB_needchange=1;
				insqueue_to_ROB_needchange=1;
				//r为该指令SLB准备存放的位置
				r1=(SLB_R+1)%`MaxSLB;
				SLB_R_=r1;insqueue_to_SLB_size_addflag=1;
				
				//b为该指令ROB准备存放的位置
				b1=(ROB_R+1)%`MaxROB;
				ROB_R_=b1;insqueue_to_ROB_size_addflag=1;

				//将该指令从Ins_queue删去
				insqueue_size_internal_subflag=1;
				// Ins_queue_size--;
				//解码
				// Order order=Decode(Ins_queue_s_inst[Ins_queue_L]);
				
				//修改ROB
				ROB_s_pc_b1_=Ins_queue_s_pc[Ins_queue_L];
				ROB_s_inst_b1_=Ins_queue_s_inst[Ins_queue_L]; ROB_s_ordertype_b1_=Ins_queue_s_ordertype[Ins_queue_L];
				ROB_s_dest_b1_=order_rd ; ROB_s_ready_b1_=0;
				
				//修改SLB


				//根据rs1寄存器的情况决定是否给其renaming(vj;qj)
				//如果rs1寄存器上为busy且其最后一次修改对应的ROB位置还未commit，则renaming
				if(reg_busy_order_rs1) begin
					h1=reg_reorder_order_rs1;
					if(ROB_s_ready_h1) begin
						SLB_s_vj_r1_=ROB_s_value_h1;SLB_s_qj_r1_=-1;
					end
					else SLB_s_qj_r1_=h1;
				end
				else begin
					SLB_s_vj_r1_=reg_reg_order_rs1;SLB_s_qj_r1_=-1;
				end

				if(isstore) begin// store类型  （有rs2的）
					//根据rs2寄存器的情况决定是否给其renaming(vk;qk)
					//如果rs2寄存器上为busy且其最后一次修改对应的ROB位置还未commit，则renaming
					if(reg_busy_order_rs2) begin
						h2=reg_reorder_order_rs2;
						if(ROB_s_ready_h2) begin
							SLB_s_vk_r1_=ROB_s_value_h2;SLB_s_qk_r1_=-1;
						end
						else SLB_s_qk_r1_=h2;
					end
					else SLB_s_vk_r1_=reg_reg_order_rs2;SLB_s_qk_r1_=-1;
				end
				else SLB_s_qk_r1_=-1;
				
				SLB_s_inst_r1_=Ins_queue_s_inst[Ins_queue_L] ; SLB_s_ordertype_r1_=Ins_queue_s_ordertype[Ins_queue_L];
				SLB_s_pc_r1_=Ins_queue_s_pc[Ins_queue_L];
				SLB_s_A_r1_=order_imm ; SLB_s_reorder_r1_=b1;
				
				if(isstore)SLB_s_ready_r1_=0;

				//修改register
				if(!isstore) begin//不为 store指令  (其他都有rd)
					insqueue_to_Reg_needchange=1;
					reg_reorder_order_rd_=b1;reg_busy_order_rd_=1;
				end
			end
		end
		else begin// 计算(LUI;AUIPC;ADD;SUB___) or 无条件跳转(BEQ;BNE;BLE___) or 有条件跳转(JAL;JALR)
			
			//找到一个空的RS的位置，r为找到的空的RS的位置
			r2=RS_unbusy_pos; //找不到返回-1
			// r2=-1;
			// for(i=0;i<`MaxRS;i++) begin
			// 	if(!RS_s_busy[i]) begin
			// 		r2=i;break;
			// 	end
			// end
			//RS满了，因此取消issue InstructionQueue中的指令
			if(r2==-1);
			else begin
				insqueue_to_RS_needchange=1;
				insqueue_to_ROB_needchange=1;
				//b为该指令ROB准备存放的位置
				b1=(ROB_R+1)%`MaxROB;
				ROB_R_=b1;insqueue_to_ROB_size_addflag=1;
				//将该指令从Ins_queue删去
				insqueue_size_internal_subflag=1;
				Ins_queue_size--;
				//解码
				// Order order=Decode(Ins_queue_s_inst[Ins_queue_L]);

				//修改ROB
				
				ROB_s_inst_b1_=Ins_queue_s_inst[Ins_queue_L]; ROB_s_ordertype_b1_=Ins_queue_s_ordertype[Ins_queue_L];
				ROB_s_pc_b1_=Ins_queue_s_pc[Ins_queue_L]; ROB_s_jumppc_b1_=Ins_queue_s_jumppc[Ins_queue_L] ; ROB_s_isjump_b1_=Ins_queue_s_isjump[Ins_queue_L];
				ROB_s_dest_b1_=order_rd ; ROB_s_ready_b1_=0;

				//修改RS
				if( Ins_queue_s_inst[Ins_queue_L][6:0]!=7'h37&&Ins_queue_s_inst[Ins_queue_L][6:0]!=7'h17 && Ins_queue_s_inst[Ins_queue_L][6:0]!=7'h6f ) begin// 不为LUI;AUIPC;JAL (有rs1的)
					//根据rs1寄存器的情况决定是否给其renaming(vj;qj)
					//如果rs1寄存器上为busy且其最后一次修改对应的ROB位置还未commit，则renaming
					if(reg_busy_order_rs1) begin
						h1=reg_reorder_order_rs1;
						if(ROB_s_ready_h1) begin
							RS_s_vj_r2_=ROB_s_value_h1;RS_s_qj_r2_=-1;
						end
						else RS_s_qj_r2_=h1;
					end
					else begin
						RS_s_vj_r2_=reg_reg_order_rs1;RS_s_qj_r2_=-1;
					end
				end
				else RS_s_qj_r2_=-1;

				if( Ins_queue_s_inst[Ins_queue_L][6:0]==7'h33 || Ins_queue_s_inst[Ins_queue_L][6:0]==7'h63) begin// (ADD__AND) or 有条件跳转  （有rs2的）
					//根据rs2寄存器的情况决定是否给其renaming(vk;qk)
					//如果rs2寄存器上为busy且其最后一次修改对应的ROB位置还未commit，则renaming
					if(reg_busy_order_rs2) begin
						h2=reg_reorder_order_rs2;
						if(ROB_s_ready_h2) begin
							RS_s_vk_r2_=ROB_s_value_h2;RS_s_qk_r2_=-1;
						end
						else RS_s_qk_r2_=h2;
					end
					else RS_s_vk_r2_=reg_reg_order_rs2;RS_s_qk_r2_=-1;
				end
				else RS_s_qk_r2_=-1;
				

				RS_s_inst_r2_=Ins_queue_s_inst[Ins_queue_L] ; RS_s_ordertype_r2_=Ins_queue_s_ordertype[Ins_queue_L];
				RS_s_pc_r2_=Ins_queue_s_pc[Ins_queue_L] ; RS_s_jumppc_r2_=Ins_queue_s_jumppc[Ins_queue_L];
				RS_s_A_r2_=order_imm ; RS_s_reorder_r2_=b1;
				RS_s_busy_r2_=1;

				//修改register
				if(Ins_queue_s_inst[Ins_queue_L][6:0]!=7'h63) begin//不为 有条件跳转  (其他都有rd)
					insqueue_to_Reg_needchange=1;
					reg_reorder_order_rd_=b1;reg_busy_order_rd_=1;
				end
			end
		end
	end
end





always @(posedge clk) begin
	if(rst) begin
		//pc
		pc<=0;

		//Ins_queue
		for(i=0;i<`MaxIns;i=i+1) begin
			Ins_queue_s_inst[i]<=0;
			Ins_queue_s_pc[i]<=0;
			Ins_queue_s_jumppc[i]<=0;
			Ins_queue_s_isjump[i]<=0;
			Ins_queue_s_ordertype[i]<=0;
		end
		Ins_queue_L<=1;Ins_queue_R<=0;Ins_queue_size<=0;
		Ins_queue_is_waiting_ins<=0;

	end
	else if(~rdy) begin
	end
	else if(Clear_flag) begin
		Ins_queue_L<=1;Ins_queue_R<=0;Ins_queue_size<=0;Ins_queue_is_waiting_ins<=0;
	end
	else begin
		//for Ins_queue_size
		Ins_queue_size<=Ins_queue_size+insqueue_size_internal_addflag-insqueue_size_internal_subflag;

		// Get_ins_to_queue() part2
		if(!Ins_queue_is_waiting_ins&&Ins_queue_size!=`MaxIns) begin
			if(!hit) begin
				Ins_queue_is_waiting_ins<=1;
			end
		end
		if(memctrl_ins_ok) begin
			Ins_queue_is_waiting_ins<=0;
		end
		if(memctrl_ins_ok||hit) begin
			Ins_queue_R<=g;

			Ins_queue_s_inst[g]<=inst;Ins_queue_s_ordertype[g]<=order_type;Ins_queue_s_pc[g]<=pc;
			if(isbranch) begin
				//JAL 直接跳转
				//目前强制pc不跳转；JALR默认不跳转，让它必定预测失败
				if(order_type==`JAL) begin
					if(!ROB_to_insqueue_needchange)pc<=pc+order_imm_0;
				end
				else  begin
					if(order_type==`JALR) begin
						if(!ROB_to_insqueue_needchange)pc<=pc+4;
					end
					else  begin
						Ins_queue_s_jumppc[g]<=pc+order_imm_0;
						if(bht_get) begin
							if(!ROB_to_insqueue_needchange)pc<=pc+order_imm_0;
							Ins_queue_s_isjump[g]<=1;
						end
						else begin
							if(!ROB_to_insqueue_needchange)pc<=pc+4;
							Ins_queue_s_isjump[g]<=0;
						end
					end
				end
			end
			else begin
				if(!ROB_to_insqueue_needchange)pc<=pc+4;
			end
		end

		// do_ins_queue() part2
		
		//InstructionQueue为空，因此取消issue InstructionQueue中的指令
		if(Ins_queue_size==0);
		//ROB满了，因此取消issue InstructionQueue中的指令
		else if(ROB_size==`MaxROB);
		else begin
			if(isload||isstore) begin //load指令(LB;LH;LW;LBU;LHU) or store指令(SB;SH;SW)
				//SLB满了，因此取消issue InstructionQueue中的指令
				if(SLB_size==`MaxSLB);
				else begin
					//将该指令从Ins_queue删去
					Ins_queue_L<=(Ins_queue_L+1)%`MaxIns;
				end
			end
			else begin// 计算(LUI;AUIPC;ADD;SUB___) or 无条件跳转(BEQ;BNE;BLE___) or 有条件跳转(JAL;JALR)
				if(r2==-1);
				else begin
					//将该指令从Ins_queue删去
					Ins_queue_L<=(Ins_queue_L+1)%`MaxIns;
				end
			end
		end

		// from ROB
		if(ROB_to_insqueue_needchange) begin
			pc<=pc_;
		end

	end
end

endmodule