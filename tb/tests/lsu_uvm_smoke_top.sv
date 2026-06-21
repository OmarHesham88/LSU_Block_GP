`include "VX_config.vh"
`include "VX_platform.vh"
`include "VX_define.vh"

import uvm_pkg::*;
import VX_gpu_pkg::*;
import lsu_uvm_pkg::*;

module lsu_uvm_smoke_top;

    localparam int NUM_LANES = `NUM_LSU_LANES;

    logic clk;
    logic reset;
    lsu_uvm_cfg cfg;

    lsu_uvm_ctrl_if ctrl_if();
    VX_execute_if #(lsu_exe_t) execute_if();
    VX_result_if #(lsu_res_t) result_if();
    VX_lsu_mem_if #(
        .NUM_LANES (NUM_LANES),
        .DATA_SIZE (LSU_WORD_SIZE),
        .TAG_WIDTH (LSU_TAG_WIDTH)
    ) lsu_mem_if();

    always #5 clk = ~clk;
    assign ctrl_if.clk = clk;
    assign ctrl_if.reset = reset;

    VX_lsu_slice dut (
        .clk(clk),
        .reset(reset),
        .execute_if(execute_if),
        .result_if(result_if),
        .lsu_mem_if(lsu_mem_if)
    );

    lsu_mem_model_rand #(
        .MEM_BYTES(4096),
        .MAX_OUTSTANDING(8),
        .MIN_RSP_LATENCY(1),
        .MAX_RSP_LATENCY(5),
        .ENABLE_REQ_BACKPRESSURE(1),
        .ENABLE_OOO_RESPONSES(0)
    ) mem (
        .clk(clk),
        .reset(reset),
        .mem_if(lsu_mem_if)
    );

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        execute_if.valid = 1'b0;
        execute_if.data  = '0;
        result_if.ready  = 1'b1;

        repeat (5) @(posedge clk);
        reset = 1'b0;
    end

    initial begin
        cfg = lsu_uvm_cfg::type_id::create("cfg");
        cfg.ctrl_vif = ctrl_if;
        cfg.exec_vif = execute_if;
        cfg.result_vif = result_if;
        cfg.random_ops = 120;
        cfg.enable_fence_tests = 1'b1;
        uvm_pkg::uvm_config_db#(lsu_uvm_cfg)::set(null, "*", "cfg", cfg);
        uvm_pkg::run_test("lsu_uvm_main_test");
    end

endmodule
