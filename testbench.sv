// Code your testbench here
///////////////////////////////////////transactions
class transaction ;
  rand bit rden, wren;
  rand bit  [7:0] data_in;
  
  
  bit full,empty;
  bit [7:0] data_out;
  constraint wr_end{
    
   rden != wren;
    wren dist {0:/50 , 1:/ 50};
    rden dist {0:/50 , 1:/ 50} ;
    
    
  }
  constraint data_cons	{
  data_in > 1 ;
    data_in < 5;
  }
  function void display(input string tag);
   $display( "[%0s]: wren :%0b  \t rden:%0b \t datawr:%0d \t datard:%0d \t Full:%0b \t, Empty :%0b \t @ %0t ", tag , wren, rden,data_in , data_out ,full,empty,$time);
  endfunction 
  
  function transaction copy();
    copy =  new();
    copy.rden = this.rden ;
    copy.wren = this.wren;
    copy.data_in = this.data_in;
    copy.data_out = this.data_out;
    copy.full = this.full;
    copy.empty = this.empty;
      endfunction
  
  
endclass
 
/*
module tb;
  transaction tr ;
  initial begin 
    tr = new();
    tr.display("TOP");
    
    
  end
  
endmodule
*/
//////////////////////////////////////////////generator
class generator;
  

  transaction tr ;
  mailbox #(transaction)  mbx;
  int count =0;
  event done;         //conveys completion of transaction
  event next;         //conveys next transaaction
  
  function new(mailbox #(transaction) mbx);
    this.mbx  = mbx;
    tr = new();
  endfunction 
  
  
  task run();
    repeat(count)
      begin
        assert(tr.randomize)else $error("Randomization failed!!!");
        mbx.put(tr.copy);
        tr.display("GEN");
        @(next);
        
      end
    ->done;
  endtask
  
endclass 

//////////////////////////////////////////driver
class driver;
  
  virtual fifo_if vif; 
  mailbox #(transaction) mbx ;
   
   
  transaction datac;
  event next;
  
  function new(mailbox #(transaction) mbx);
    this.mbx  = mbx;
     
  endfunction 
  
  task reset();
    
    vif.rst <= 1'b1;

    vif.rden <= 1'b0;
    vif.wren <= 1'b0;
    vif.data_in <= 1'b0;
    repeat(5) @(posedge vif.clk);
    vif.rst <= 1'b0;
    $display("{DUT}: RESET HAS BEEN DONE!!   ");
    
  endtask
   //Applying random stimulus in dut
  task run();
    
    forever begin 
      mbx.get(datac);
      datac.display("DRV");
      vif.rden <= datac.rden ;
      vif.wren <= datac.wren ;
      vif.data_in <= datac.data_in ;
      repeat(2)  @(posedge vif.clk);
      ->next;
      
      
    end
    endtask
  
endclass

/////////////////////////////////////////monitor 
    class monitor;
     
       virtual fifo_if vif;
      
       mailbox #(transaction) mbx;
      
       transaction tr;
    
      
      
        function new(mailbox #(transaction) mbx);
          this.mbx = mbx;     
       endfunction
      
      
      task run();
        tr = new();
        
        forever begin
          repeat(2) @(posedge vif.clk);
          tr.wren = vif.wren;
          tr.rden = vif.rden;
          tr.data_in = vif.data_in;
          tr.data_out = vif.data_out;
          tr.full = vif.full;
          tr.empty = vif.empty;
          
          
          mbx.put(tr);
          
          tr.display("MON");
         
          
        end
        
      endtask
      
     
      
    endclass
  
 


/////////////////////////////////////////scoreboard
class scoreboard;
 mailbox #(transaction) mbx;
   
  transaction tr;
  event next;
  
  bit [7:0] din[$];
  bit [7:0] temp ;
  
  
  function new(mailbox #(transaction) mbx);
    this.mbx  = mbx;
     
  endfunction 

  task run();
    forever begin
      mbx.get(tr);
      tr.display("SCO");
      if(tr.wren==1'b1) begin
        din.push_front(tr.data_in);
        $display("data stored in the queue [SCO]:%0d",tr.data_in);
                 
      end
      if(tr.rden == 1'b1) 
        begin 
          if(tr.empty == 1'b0)
            begin
              temp =din.pop_back();
              if(tr.data_out == temp)
                $display("DATA MATCH [SCO]");
              else 
                $error("DATA NOT MATCH [SCO]");
            end
          else
            begin
              $display("FIFO IS EMPTY");
          
        
      end
        end
      
      ->next;
    end
  endtask
endclass

 
 
///////////////////////////////////////////////////environment
class environment ;
  generator gen;
  driver drv;
  monitor mon;
  scoreboard sco;
  
  mailbox #(transaction) gdmbx; //mailbox between generator and driver 
   
  mailbox #(transaction) msmbx; // mailbox between monitor and scoreboard
  
  event nextgs;
  
   virtual fifo_if vif;
  function new(virtual fifo_if vif);
    gdmbx =new();
    gen =new(gdmbx);
    drv =  new(gdmbx);
    
    msmbx = new();
    mon = new(msmbx);
    sco=  new(msmbx);
  this.vif = vif;
    drv.vif = this.vif;
    mon.vif = this.vif;
    
    gen.next = nextgs;
    sco.next = nextgs;
  endfunction
 

  task pre_test();
    drv.reset();
  endtask
  task test();
    fork 
      gen.run();
      drv.run();
      mon.run();
      sco.run();
join_any
    
  endtask

  task post_test();
    wait(gen.done.triggered);
    $finish();
  endtask

  
  task run();
    pre_test();
    test();
    post_test();
endtask
endclass


 //////////////////////////////////tb


module tb;
  
  fifo_if vif();
  

  fifo_ver UUT( vif.rst, vif.clk ,vif.wren , vif.rden , vif.data_in, vif.data_out, vif.full , vif.empty);
  
  initial begin 
    vif.clk <= 0 ;
    
  end
  
  always #10 vif.clk <= ~vif.clk;
  environment env;
  
  initial begin 
    env = new(vif);
  env.gen.count =40 ;
    env.run();
    
  end
  
  
initial begin 
  $dumpfile("dump.vcd");
  
 $dumpvars;
    #1000 ;
  $finish;
  
end
endmodule