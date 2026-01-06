module tb_top;

    reg clk;
    reg rst;

    //instantiate top
    top_inst dut (
        .clk(clk),
        .rst(rst)
    );

    initial clk = 0;
    always #2.5 clk = ~clk;

    initial 
    begin
        rst = 1;
        #10 rst = 0;
    end

    //monitor signals
    initial 
    begin
        $dumpfile("top_inst.vcd");
        $dumpvars(0, dut);
    end

    initial 
    begin
        #200 $finish;
    end

endmodule
