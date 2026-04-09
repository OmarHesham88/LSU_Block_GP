`include "VX_config.vh"
`include "VX_platform.vh"
`include "VX_define.vh"

import VX_gpu_pkg::*;

module lsu_slice_tb_v2;

    localparam int NUM_LANES = `NUM_LSU_LANES;

    logic clk;
    logic reset;
    logic [UUID_WIDTH-1:0] uuid_ctr;
    event load_done_ev;

    int unsigned cfg_seed;
    int unsigned cfg_num_ops;
    int unsigned cfg_timeout_cycles;
    bit cfg_enable_fence_tests;

    lsu_sequence_item_pkg::lsu_sequence_item_class pending_load_items[$];
    lsu_monitor_pkg::lsu_monitor_class mon;
    logic [NUM_LANES-1:0][`XLEN-1:0] orphan_rsp_data[int unsigned];

    VX_execute_if #(lsu_exe_t) execute_if();
    VX_result_if #(lsu_res_t) result_if();
    VX_lsu_mem_if #(
        .NUM_LANES (NUM_LANES),
        .DATA_SIZE (LSU_WORD_SIZE),
        .TAG_WIDTH (LSU_TAG_WIDTH)
    ) lsu_mem_if();

    logic issue_is_store;
    int unsigned issue_lane;
    logic [`XLEN-1:0] issue_addr;
    logic [INST_LSU_BITS-1:0] issue_op;

    logic prev_exec_valid, prev_exec_ready;
    logic prev_mem_req_valid, prev_mem_req_ready;
    logic prev_mem_rsp_valid, prev_mem_rsp_ready;
    logic prev_res_valid, prev_res_ready;

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
        .MAX_OUTSTANDING(16),
        .MIN_RSP_LATENCY(1),
        .MAX_RSP_LATENCY(10),
        .ENABLE_REQ_BACKPRESSURE(1),
        .ENABLE_OOO_RESPONSES(0)
    ) mem (
        .clk(clk),
        .reset(reset),
        .mem_if(lsu_mem_if)
    );

    always @(posedge clk) begin
        if (reset) begin
            prev_exec_valid <= 0;
            prev_exec_ready <= 0;
            prev_mem_req_valid <= 0;
            prev_mem_req_ready <= 0;
            prev_mem_rsp_valid <= 0;
            prev_mem_rsp_ready <= 0;
            prev_res_valid <= 0;
            prev_res_ready <= 0;
        end else begin
            if (prev_exec_valid && !prev_exec_ready)
                assert (execute_if.valid) else $error("ASSERT: execute_if.valid dropped before handshake");
            if (prev_mem_req_valid && !prev_mem_req_ready)
                assert (lsu_mem_if.req_valid) else $error("ASSERT: lsu_mem_if.req_valid dropped before handshake");
            if (prev_mem_rsp_valid && !prev_mem_rsp_ready)
                assert (lsu_mem_if.rsp_valid) else $error("ASSERT: lsu_mem_if.rsp_valid dropped before handshake");
            if (prev_res_valid && !prev_res_ready)
                assert (result_if.valid) else $error("ASSERT: result_if.valid dropped before handshake");
            if (execute_if.valid)
                assert (execute_if.data.tmask != '0) else $error("ASSERT: execute_if tmask is zero");

            prev_exec_valid <= execute_if.valid;
            prev_exec_ready <= execute_if.ready;
            prev_mem_req_valid <= lsu_mem_if.req_valid;
            prev_mem_req_ready <= lsu_mem_if.req_ready;
            prev_mem_rsp_valid <= lsu_mem_if.rsp_valid;
            prev_mem_rsp_ready <= lsu_mem_if.rsp_ready;
            prev_res_valid <= result_if.valid;
            prev_res_ready <= result_if.ready;
        end
    end

    covergroup cg_issue;
        option.per_instance = 1;

        cp_is_store : coverpoint issue_is_store {
            bins load = {0};
            bins store = {1};
        }

        cp_lane : coverpoint issue_lane {
            bins lane_bins[] = {[0:NUM_LANES-1]};
        }

        cp_align : coverpoint issue_addr[2:0] {
            bins a0 = {0};
            bins a1 = {1};
            bins a2 = {2};
            bins a3 = {3};
        `ifdef XLEN_64
            bins a4 = {4};
            bins a5 = {5};
            bins a6 = {6};
            bins a7 = {7};
        `endif
        }

        cp_op : coverpoint issue_op {
            bins b_lw  = {INST_LSU_LW};
            bins b_lb  = {INST_LSU_LB};
            bins b_lbu = {INST_LSU_LBU};
            bins b_lh  = {INST_LSU_LH};
            bins b_lhu = {INST_LSU_LHU};
            bins b_sw  = {INST_LSU_SW};
            bins b_sb  = {INST_LSU_SB};
            bins b_sh  = {INST_LSU_SH};
            bins b_fence = {INST_LSU_FENCE};
        `ifdef XLEN_64
            bins b_ld  = {INST_LSU_LD};
            bins b_lwu = {INST_LSU_LWU};
            bins b_sd  = {INST_LSU_SD};
        `endif
        }

        cx_op_lane : cross cp_op, cp_lane;
        cx_store_op: cross cp_is_store, cp_op;
    endgroup

    cg_issue issue_cov = new();

    function int unsigned op_size_bytes(input logic [INST_LSU_BITS-1:0] op);
        case (inst_lsu_wsize(op))
            2'd0: return 1;
            2'd1: return 2;
            2'd2: return 4;
            default: return 8;
        endcase
    endfunction

    function logic [INST_LSU_BITS-1:0] rand_store_op();
        int unsigned r;
        r = $urandom_range(2, 0);
        case (r)
            0: return INST_LSU_SB;
            1: return INST_LSU_SH;
            default: return INST_LSU_SW;
        endcase
    endfunction

    function logic [INST_LSU_BITS-1:0] rand_load_op();
        int unsigned r;
        r = $urandom_range(4, 0);
        case (r)
            0: return INST_LSU_LB;
            1: return INST_LSU_LBU;
            2: return INST_LSU_LH;
            3: return INST_LSU_LHU;
            default: return INST_LSU_LW;
        endcase
    endfunction

    task issue_lsu_op(
        input  logic                     is_store,
        input  logic [`XLEN-1:0]         addr,
        input  logic [`XLEN-1:0]         store_data,
        input  logic [INST_LSU_BITS-1:0] op_type,
        input  int unsigned              lane,
        output lsu_sequence_item_pkg::lsu_sequence_item_class item
    );
        lsu_exe_t req;

        req = '0;
        item = new();

        item.uuid           = uuid_ctr;
        item.is_store       = is_store;
        item.addr           = addr;
        item.store_data     = store_data;
        item.op_type        = op_type;
        item.lane           = lane;
        item.mask           = '0;
        item.mask[lane]     = 1'b1;
        item.observed_valid = 1'b0;
        item.observed_data  = '0;

        req.uuid                 = uuid_ctr;
        req.wid                  = '0;
        req.tmask                = item.mask;
        req.PC                   = '0;
        req.op_type              = op_type;
        req.op_args              = '0;
        req.op_args.lsu.is_store = is_store;
        req.op_args.lsu.is_float = 1'b0;
        req.op_args.lsu.offset   = '0;
        req.wb                   = (~is_store) && (~inst_lsu_is_fence(op_type));
        req.rd                   = '0;
        req.pid                  = '0;
        req.sop                  = 1'b1;
        req.eop                  = 1'b1;

        for (int i = 0; i < NUM_LANES; i++) begin
            req.rs1_data[i] = addr;
            req.rs2_data[i] = store_data;
            req.rs3_data[i] = '0;
        end

        uuid_ctr = uuid_ctr + 1'b1;

        execute_if.data  <= req;
        execute_if.valid <= 1'b1;
        do begin
            @(posedge clk);
        end while (execute_if.ready !== 1'b1);

        execute_if.valid <= 1'b0;
        execute_if.data  <= '0;

        issue_is_store = is_store;
        issue_lane = lane;
        issue_addr = addr;
        issue_op = op_type;
        issue_cov.sample();
    endtask

    task do_fence(input int unsigned lane);
        lsu_sequence_item_pkg::lsu_sequence_item_class it;
        issue_lsu_op(1'b0, '0, '0, INST_LSU_FENCE, lane, it);
    endtask

    task wait_for_load(input int unsigned timeout_cycles);
        int unsigned cycles;
        cycles = 0;
        fork
            begin
                @load_done_ev;
            end
            begin
                while (cycles < timeout_cycles) begin
                    @(posedge clk);
                    cycles++;
                end
                $fatal(1, "Timeout waiting for load response");
            end
        join_any
        disable fork;
    endtask

    task do_store(
        input logic [INST_LSU_BITS-1:0] op_type,
        input logic [`XLEN-1:0] addr,
        input logic [`XLEN-1:0] data,
        input int unsigned lane
    );
        lsu_sequence_item_pkg::lsu_sequence_item_class it;
        issue_lsu_op(1'b1, addr, data, op_type, lane, it);
        mon.monitor(it);
    endtask

    task do_load(
        input logic [INST_LSU_BITS-1:0] op_type,
        input logic [`XLEN-1:0] addr,
        input int unsigned lane
    );
        lsu_sequence_item_pkg::lsu_sequence_item_class it;
        int unsigned key;
        issue_lsu_op(1'b0, addr, '0, op_type, lane, it);
        key = int'(it.uuid);
        if (orphan_rsp_data.exists(key)) begin
            it.observed_valid = 1'b1;
            it.observed_data = orphan_rsp_data[key][lane];
            orphan_rsp_data.delete(key);
            mon.monitor(it);
        end else begin
            pending_load_items.push_back(it);
            wait_for_load(cfg_timeout_cycles);
        end
    endtask

    task run_directed_tests();
        // Core format tests
        do_store(INST_LSU_SW, 32'h100, 32'hDEADBEEF, 0);
        do_load (INST_LSU_LW, 32'h100, 0);

        do_store(INST_LSU_SH, 32'h108, 32'h00008001, 1);
        do_load (INST_LSU_LH, 32'h108, 1);
        do_load (INST_LSU_LHU,32'h108, 1);

        do_store(INST_LSU_SB, 32'h10C, 32'h00000080, 2);
        do_load (INST_LSU_LB, 32'h10C, 2);
        do_load (INST_LSU_LBU,32'h10C, 2);

        do_store(INST_LSU_SW, 32'h3F8, 32'hA5A5A5A5, 3);
        do_load (INST_LSU_LW, 32'h3F8, 3);
        do_store(INST_LSU_SH, 32'h3FC, 32'h0000F00F, 0);
        do_load (INST_LSU_LH, 32'h3FC, 0);
        do_store(INST_LSU_SB, 32'h3FF, 32'h000000FF, 1);
        do_load (INST_LSU_LBU, 32'h3FF, 1);

        // Lane-sweep tests for all lanes
        for (int unsigned lane = 0; lane < NUM_LANES; lane++) begin
            logic [`XLEN-1:0] a;
            logic [`XLEN-1:0] d;
            a = 32'h500 + (lane * 16);
            d = 32'h11110000 ^ (lane * 32'h01010101);
            do_store(INST_LSU_SW, a, d, lane);
            do_load (INST_LSU_LW, a, lane);

            do_store(INST_LSU_SH, a + 2, 32'h00008080 | lane, lane);
            do_load (INST_LSU_LH, a + 2, lane);
            do_load (INST_LSU_LHU, a + 2, lane);

            do_store(INST_LSU_SB, a + 1, 32'h00000080 | lane, lane);
            do_load (INST_LSU_LB, a + 1, lane);
            do_load (INST_LSU_LBU, a + 1, lane);
        end
    endtask

    task run_fence_tests();
        // Basic fence ordering scenario in directed traffic
        for (int unsigned lane = 0; lane < NUM_LANES; lane++) begin
            logic [`XLEN-1:0] a;
            logic [`XLEN-1:0] d1;
            logic [`XLEN-1:0] d2;
            a  = 32'h700 + (lane * 8);
            d1 = 32'hA5000000 | lane;
            d2 = 32'h5A000000 | lane;

            do_store(INST_LSU_SW, a, d1, lane);
            do_fence(lane);
            do_load (INST_LSU_LW, a, lane);
            do_store(INST_LSU_SW, a, d2, lane);
            do_fence(lane);
            do_load (INST_LSU_LW, a, lane);
        end
    endtask

    task run_random_tests(input int unsigned n_ops);
        logic [INST_LSU_BITS-1:0] op;
        logic [`XLEN-1:0] addr;
        logic [`XLEN-1:0] data;
        int unsigned lane;
        int unsigned size_b;
        bit is_store;

        for (int unsigned i = 0; i < n_ops; i++) begin
            if (cfg_enable_fence_tests && ($urandom_range(99, 0) < 5)) begin
                do_fence($urandom_range(NUM_LANES-1, 0));
                continue;
            end

            is_store = ($urandom_range(99, 0) < 45);
            if (is_store)
                op = rand_store_op();
            else
                op = rand_load_op();

            size_b = op_size_bytes(op);
            lane = $urandom_range(NUM_LANES-1, 0);
            data = {$urandom(), $urandom()};

            addr = $urandom_range(1023, 0);
            addr = addr * size_b;
            addr = addr & 32'h00000FFF;

            if (is_store)
                do_store(op, addr, data, lane);
            else
                do_load(op, addr, lane);
        end
    endtask

    always @(posedge clk) begin
        if (reset) begin
            pending_load_items.delete();
            orphan_rsp_data.delete();
        end else if (result_if.valid && result_if.ready && result_if.data.wb) begin
            int idx;
            idx = -1;

            for (int i = 0; i < pending_load_items.size(); i++) begin
                if (pending_load_items[i].uuid == result_if.data.uuid) begin
                    idx = i;
                    break;
                end
            end

            if (idx >= 0) begin
                lsu_sequence_item_pkg::lsu_sequence_item_class rsp_item;
                rsp_item = pending_load_items[idx];
                pending_load_items.delete(idx);

                rsp_item.observed_valid = 1'b1;
                rsp_item.observed_data = result_if.data.data[rsp_item.lane];
                mon.monitor(rsp_item);
                -> load_done_ev;
            end else begin
                orphan_rsp_data[int'(result_if.data.uuid)] = result_if.data.data;
            end
        end
    end

    initial begin
        clk = 0;
        reset = 1;
        execute_if.valid = 0;
        execute_if.data  = '0;
        result_if.ready  = 1;
        uuid_ctr = '0;
        mon = new();

        cfg_seed = 32'h1;
        cfg_num_ops = 500;
        cfg_timeout_cycles = 800;
        cfg_enable_fence_tests = 1'b1;

        if (!$value$plusargs("SEED=%d", cfg_seed))
            cfg_seed = 32'h1;
        if (!$value$plusargs("NUM_OPS=%d", cfg_num_ops))
            cfg_num_ops = 500;

        void'($urandom(cfg_seed));

        repeat (5) @(posedge clk);
        reset = 0;
        repeat (2) @(posedge clk);

        run_directed_tests();
        if (cfg_enable_fence_tests)
            run_fence_tests();
        run_random_tests(cfg_num_ops);

        repeat (50) @(posedge clk);

        if (pending_load_items.size() != 0)
            $fatal(1, "LSU_V2 FAILED pending load queue not empty: %0d", pending_load_items.size());

        $display("SCOREBOARD total=%0d pass=%0d fail=%0d",
            mon.scoreboard.right_count + mon.scoreboard.wrong_count,
            mon.scoreboard.right_count,
            mon.scoreboard.wrong_count);
        $display("COVERAGE issue_cov=%0.2f%%", issue_cov.get_inst_coverage());

        if (mon.scoreboard.wrong_count != 0)
            $fatal(1, "LSU_V2 FAILED (fails=%0d)", mon.scoreboard.wrong_count);

        if (issue_cov.get_inst_coverage() < 80.0)
            $fatal(1, "LSU_V2 FAILED coverage below target: %0.2f%%", issue_cov.get_inst_coverage());

        $display("LSU_V2 PASSED");
        $finish;
    end

endmodule
