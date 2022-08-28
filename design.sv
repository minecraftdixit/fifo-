
module fifo_ver(
  input rst  , clk,
  input wren , rden,
  input [7:0] data_in,
  output reg [7:0] data_out,
  
  output full , empty
);
  reg [7:0] mem [31:0];
  reg [4:0] rdptr ,wrptr;
  
  always @(posedge clk )
    begin
      if(rst)    //active high
        begin
          data_out<=0;
          rdptr<=0;
          wrptr<=0;         
          for(int i=0 ;i<32; i++)
            begin
              mem[i] <= 0;
            end
        end
      else
        begin	
      
          if((wren==1'b1)&& (empty==0))
            begin
              mem[wrptr] <= data_in;
              wrptr=wrptr+1;
            end
          
          if((rden==1'b1)&& (full==0))
            begin
              data_out <= mem[rdptr];
               
          rdptr =rdptr+1;
            end
        end
    end
  
  
          assign full =	((wrptr - rdptr)==31) ? 1'b1:1'b0;
          assign empty =((wrptr - rdptr)==0) ? 1'b1:1'b0;
endmodule
 

interface fifo_if ;
 logic rst  , clk;
  logic wren , rden;
  logic [7:0] data_in;
  logic [7:0] data_out;
  logic  full , empty;
  
endinterface 