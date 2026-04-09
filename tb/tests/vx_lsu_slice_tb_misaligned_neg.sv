`include "VX_config.vh"
`include "VX_platform.vh"
`include "VX_define.vh"

import VX_gpu_pkg::*;

module lsu_slice_tb_misaligned_neg;

    localparam int NUM_LANES = `NUM_LSU_LANES;

    logic clk;
    logic reset;
    logic [UUID_WIDTH-1:0] uuid_ctr;

    VX_execute_if #(lsu_exe_t) execute_if();
    VX_result_if #(lsu_res_t) result_if();
    VX_lsu_mem_if #(
        .NUM_LANES (NUM_LANES),
        .DATA_SIZE (LSU_WORD_SIZE),
        .TAG_WIDTH (LSU_TAG_WIDTH)
    ) lsu_mem_if();

    always #5 clk = ~clk;

    VX_lsu_slice dut (
        .clk(clk),
        .reset(reset),
        .execute_if(execute_if),
        .result_if(result_if),
        .lsu_mem_if(lsu_mem_if)
    );

    lsu_mem_model_rand #(
        .MEM_BYTES(4096),
        .MAX_OUTSTANDING(4),
        .MIN_RSP_LATENCY(1),
        .MAX_RSP_LATENCY(2),
        .ENABLE_REQ_BACKPRESSURE(0),
        .ENABLE_OOO_RESPONSES(0)
    ) mem (
        .clk(clk),
        .reset(reset),
        .mem_if(lsu_mem_if)
    );

    function int unsigned op_size_bytes(input logic [INST_LSU_BITS-1:0] op);
        case (inst_lsu_wsize(op))
            2'd0: return 1;
            2'd1: return 2;
            2'd2: return 4;
            default: return 8;
        endcase
    endfunction

    // Negative-test checker: this assertion is expected to fail in this testbench.
    always @(posedge clk) begin
        if (!reset && execute_if.valid && execute_if.ready && execute_if.data.tmask[0]) begin
            int unsigned sz;
            sz = op_size_bytes(execute_if.data.op_type);
            if ((execute_if.data.rs1_data[0] % sz) != 0) begin
                $error("MISALIGN_DETECTED: addr=0x%0h size=%0d", execute_if.data.rs1_data[0], sz);
            end
        end
    end

    task issue_misaligned_lw();
        lsu_exe_t req;
        req = '0;

        req.uuid                 = uuid_ctr;
        req.tmask                = '0;
        req.tmask[0]             = 1'b1;
        req.op_type              = INST_LSU_LW;
        req.op_args              = '0;
        req.op_args.lsu.is_store = 1'b0;
        req.op_args.lsu.offset   = '0;
        req.wb                   = 1'b1;
        req.sop                  = 1'b1;
        req.eop                  = 1'b1;
        req.rs1_data             = '0;
        req.rs1_data[0]          = 32'h102; // intentionally misaligned for LW

        execute_if.data  <= req;
        execute_if.valid <= 1'b1;
        do begin
            @(posedge clk);
        end while (execute_if.ready !== 1'b1);
        execute_if.valid <= 1'b0;
        execute_if.data  <= '0;
    endtask

    initial begin
        clk = 0;
        reset = 1;
        execute_if.valid = 0;
        execute_if.data  = '0;
        result_if.ready  = 1;
        uuid_ctr = '0;

        repeat (5) @(posedge clk);
        reset = 0;
        repeat (2) @(posedge clk);

        issue_misaligned_lw();
        repeat (60) @(posedge clk);

        $display("MISALIGNED_NEG_DONE");
        $finish;
    end

endmodule
