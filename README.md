# RISCV-CPU

acm班大二上大作业



**tomasulo** 

`Instruction queue size:32` 

`RS size:16` 

`SLB size:16` 

`ROB size:16` 

`BHT size:256` 

`Icache size:128` 





**for simulation** 

需要把 src/unit/SLB.v中 

```
// do_SLB() part1
always @(*) begin
	r3=0;//for_latch
end
```

r3=0这行删去，否则会导致simulation死循环(why?：no idea)