module testbench_alu;
  reg [31:0] a, b;
  reg [3:0] aluSel;	
  wire [31:0] result;

alu alu(.a(a),.b(b),.aluSel(aluSel),.result(result));
initial
    begin
     a[31:27]= 5'b01000;
     a[26:0]= $random();
     b=32'b01000010110010001110100110010011;
     aluSel= 4'd11; 
end
/*initial
 begin
   runtest();
   $finish;
 end*/
endmodule