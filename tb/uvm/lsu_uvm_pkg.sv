package lsu_uvm_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import VX_gpu_pkg::*;
    import lsu_sequence_item_pkg::*;
    import lsu_scoreboard_pkg::*;

    `uvm_analysis_imp_decl(_req)
    `uvm_analysis_imp_decl(_rsp)

    class lsu_uvm_item extends uvm_sequence_item;
        rand bit                        is_store;
        rand logic [`XLEN-1:0]          addr;
        rand logic [`XLEN-1:0]          store_data;
        rand logic [INST_LSU_BITS-1:0]  op_type;
        rand int unsigned               lane;
             logic [UUID_WIDTH-1:0]     uuid;

        constraint c_lane {
            lane < `NUM_LSU_LANES;
        }

        constraint c_op {
            if (is_store)
                op_type inside {INST_LSU_SB, INST_LSU_SH, INST_LSU_SW};
            else
                op_type inside {INST_LSU_LB, INST_LSU_LBU, INST_LSU_LH, INST_LSU_LHU, INST_LSU_LW};
        }

        `uvm_object_utils_begin(lsu_uvm_item)
            `uvm_field_int(is_store, UVM_DEFAULT)
            `uvm_field_int(addr, UVM_DEFAULT)
            `uvm_field_int(store_data, UVM_DEFAULT)
            `uvm_field_int(op_type, UVM_DEFAULT)
            `uvm_field_int(lane, UVM_DEFAULT)
            `uvm_field_int(uuid, UVM_DEFAULT | UVM_NOCOMPARE)
        `uvm_object_utils_end

        function new(string name = "lsu_uvm_item");
            super.new(name);
        endfunction
    endclass

    class lsu_uvm_rsp_item extends uvm_object;
        logic [UUID_WIDTH-1:0] uuid;
        logic [`NUM_LSU_LANES-1:0][`XLEN-1:0] data;

        `uvm_object_utils_begin(lsu_uvm_rsp_item)
            `uvm_field_int(uuid, UVM_DEFAULT)
        `uvm_object_utils_end

        function new(string name = "lsu_uvm_rsp_item");
            super.new(name);
        endfunction
    endclass

    class lsu_uvm_cfg extends uvm_object;
        virtual lsu_uvm_ctrl_if             ctrl_vif;
        virtual VX_execute_if #(lsu_exe_t)  exec_vif;
        virtual VX_result_if #(lsu_res_t)   result_vif;
        int unsigned                        random_ops;
        bit                                 enable_fence_tests;

        `uvm_object_utils(lsu_uvm_cfg)

        function new(string name = "lsu_uvm_cfg");
            super.new(name);
            random_ops = 200;
            enable_fence_tests = 1'b1;
        endfunction
    endclass

    class lsu_uvm_base_seq extends uvm_sequence #(lsu_uvm_item);
        `uvm_object_utils(lsu_uvm_base_seq)

        function new(string name = "lsu_uvm_base_seq");
            super.new(name);
        endfunction

        task automatic send_req(
            bit is_store,
            logic [`XLEN-1:0] addr,
            logic [`XLEN-1:0] store_data,
            logic [INST_LSU_BITS-1:0] op_type,
            int unsigned lane
        );
            lsu_uvm_item req;
            req = lsu_uvm_item::type_id::create($sformatf("req_%0d", lane));
            start_item(req);
            req.is_store = is_store;
            req.addr = addr;
            req.store_data = store_data;
            req.op_type = op_type;
            req.lane = lane;
            finish_item(req);
        endtask

        function logic [INST_LSU_BITS-1:0] rand_store_op();
            case ($urandom_range(2, 0))
                0: return INST_LSU_SB;
                1: return INST_LSU_SH;
                default: return INST_LSU_SW;
            endcase
        endfunction

        function logic [INST_LSU_BITS-1:0] rand_load_op();
            case ($urandom_range(4, 0))
                0: return INST_LSU_LB;
                1: return INST_LSU_LBU;
                2: return INST_LSU_LH;
                3: return INST_LSU_LHU;
                default: return INST_LSU_LW;
            endcase
        endfunction

        function int unsigned op_size_bytes(input logic [INST_LSU_BITS-1:0] op);
            case (inst_lsu_wsize(op))
                2'd0: return 1;
                2'd1: return 2;
                2'd2: return 4;
                default: return 8;
            endcase
        endfunction
    endclass

    class lsu_uvm_directed_seq extends lsu_uvm_base_seq;
        `uvm_object_utils(lsu_uvm_directed_seq)

        function new(string name = "lsu_uvm_directed_seq");
            super.new(name);
        endfunction

        task body();
            send_req(1'b1, 32'h100, 32'hDEADBEEF, INST_LSU_SW, 0);
            send_req(1'b0, 32'h100, '0, INST_LSU_LW, 0);

            send_req(1'b1, 32'h108, 32'h00008001, INST_LSU_SH, 1);
            send_req(1'b0, 32'h108, '0, INST_LSU_LH, 1);
            send_req(1'b0, 32'h108, '0, INST_LSU_LHU, 1);

            send_req(1'b1, 32'h10C, 32'h00000080, INST_LSU_SB, 2);
            send_req(1'b0, 32'h10C, '0, INST_LSU_LB, 2);
            send_req(1'b0, 32'h10C, '0, INST_LSU_LBU, 2);

            for (int unsigned lane = 0; lane < `NUM_LSU_LANES; lane++) begin
                logic [`XLEN-1:0] a;
                logic [`XLEN-1:0] d;
                a = 32'h500 + (lane * 16);
                d = 32'h11110000 ^ (lane * 32'h01010101);

                send_req(1'b1, a, d, INST_LSU_SW, lane);
                send_req(1'b0, a, '0, INST_LSU_LW, lane);
                send_req(1'b1, a + 2, 32'h00008080 | lane, INST_LSU_SH, lane);
                send_req(1'b0, a + 2, '0, INST_LSU_LH, lane);
                send_req(1'b0, a + 2, '0, INST_LSU_LHU, lane);
                send_req(1'b1, a + 1, 32'h00000080 | lane, INST_LSU_SB, lane);
                send_req(1'b0, a + 1, '0, INST_LSU_LB, lane);
                send_req(1'b0, a + 1, '0, INST_LSU_LBU, lane);
            end
        endtask
    endclass

    class lsu_uvm_random_seq extends lsu_uvm_base_seq;
        rand int unsigned n_ops;
        bit enable_fence_tests;

        `uvm_object_utils_begin(lsu_uvm_random_seq)
            `uvm_field_int(n_ops, UVM_DEFAULT)
            `uvm_field_int(enable_fence_tests, UVM_DEFAULT)
        `uvm_object_utils_end

        function new(string name = "lsu_uvm_random_seq");
            super.new(name);
            n_ops = 200;
            enable_fence_tests = 1'b1;
        endfunction

        task body();
            logic [INST_LSU_BITS-1:0] op;
            logic [`XLEN-1:0] addr;
            logic [`XLEN-1:0] data;
            int unsigned lane;
            int unsigned size_b;
            bit is_store;

            for (int unsigned i = 0; i < n_ops; i++) begin
                if (enable_fence_tests && ($urandom_range(99, 0) < 5)) begin
                    send_req(1'b0, '0, '0, INST_LSU_FENCE, $urandom_range(`NUM_LSU_LANES-1, 0));
                    continue;
                end

                is_store = ($urandom_range(99, 0) < 45);
                op = is_store ? rand_store_op() : rand_load_op();
                size_b = op_size_bytes(op);
                lane = $urandom_range(`NUM_LSU_LANES-1, 0);
                data = {$urandom(), $urandom()};

                addr = $urandom_range(1023, 0);
                addr = addr * size_b;
                addr = addr & 32'h00000FFF;

                send_req(is_store, addr, data, op, lane);
            end
        endtask
    endclass

    class lsu_uvm_sequencer extends uvm_sequencer #(lsu_uvm_item);
        `uvm_component_utils(lsu_uvm_sequencer)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
    endclass

    class lsu_uvm_driver extends uvm_driver #(lsu_uvm_item);
        `uvm_component_utils(lsu_uvm_driver)

        lsu_uvm_cfg cfg;
        logic [UUID_WIDTH-1:0] uuid_ctr;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(lsu_uvm_cfg)::get(this, "", "cfg", cfg))
                `uvm_fatal("NOCFG", "lsu_uvm_cfg was not provided")
        endfunction
        task run_phase(uvm_phase phase);
            lsu_uvm_item req;
            uuid_ctr = '0;
            cfg.exec_vif.valid <= 1'b0;
            cfg.exec_vif.data  <= '0;
            forever begin
                seq_item_port.get_next_item(req);
                drive_item(req);
                seq_item_port.item_done();
            end
        endtask


        task drive_item(lsu_uvm_item req);
            lsu_exe_t pkt;
            pkt = '0;

            @(posedge cfg.ctrl_vif.clk iff !cfg.ctrl_vif.reset);

            req.uuid                 = uuid_ctr;
            pkt.uuid                 = uuid_ctr;
            pkt.wid                  = '0;
            pkt.tmask                = '0;
            pkt.tmask[req.lane]      = 1'b1;
            pkt.PC                   = '0;
            pkt.op_type              = req.op_type;
            pkt.op_args              = '0;
            pkt.op_args.lsu.is_store = req.is_store;
            pkt.op_args.lsu.is_float = 1'b0;
            pkt.op_args.lsu.offset   = '0;
            pkt.wb                   = (~req.is_store) && (~inst_lsu_is_fence(req.op_type));
            pkt.rd                   = '0;
            pkt.pid                  = '0;
            pkt.sop                  = 1'b1;
            pkt.eop                  = 1'b1;

            for (int i = 0; i < `NUM_LSU_LANES; i++) begin
                pkt.rs1_data[i] = req.addr;
                pkt.rs2_data[i] = req.store_data;
                pkt.rs3_data[i] = '0;
            end

            cfg.exec_vif.data  <= pkt;
            cfg.exec_vif.data  <= pkt;
            cfg.exec_vif.valid <= 1'b1;
            do begin
                @(posedge cfg.ctrl_vif.clk);
            end while (cfg.exec_vif.ready !== 1'b1);
            cfg.exec_vif.valid <= 1'b0;
            cfg.exec_vif.data  <= '0;
            uuid_ctr = uuid_ctr + 1'b1;

            if (!req.is_store && !inst_lsu_is_fence(req.op_type))
                wait_for_result(req.uuid);
            else if (inst_lsu_is_fence(req.op_type))
                repeat (2) @(posedge cfg.ctrl_vif.clk);
        endtask

        task wait_for_result(input logic [UUID_WIDTH-1:0] exp_uuid);
            do begin
                @(posedge cfg.ctrl_vif.clk);
            end while (!(cfg.result_vif.valid && cfg.result_vif.ready && cfg.result_vif.data.wb
                && (cfg.result_vif.data.uuid == exp_uuid)));
        endtask
    endclass

    class lsu_uvm_exec_monitor extends uvm_component;
        `uvm_component_utils(lsu_uvm_exec_monitor)

        lsu_uvm_cfg cfg;
        uvm_analysis_port #(lsu_uvm_item) ap;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            ap = new("ap", this);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(lsu_uvm_cfg)::get(this, "", "cfg", cfg))
                `uvm_fatal("NOCFG", "lsu_uvm_cfg was not provided")
        endfunction

        function int unsigned decode_lane(input logic [`NUM_LSU_LANES-1:0] mask);
            for (int unsigned lane = 0; lane < `NUM_LSU_LANES; lane++) begin
                if (mask[lane])
                    return lane;
            end
            return 0;
        endfunction

        task run_phase(uvm_phase phase);
            lsu_uvm_item item;
            int unsigned lane;
            forever begin
                @(posedge cfg.ctrl_vif.clk);
                if (!cfg.ctrl_vif.reset && cfg.exec_vif.valid && cfg.exec_vif.ready) begin
                    lane = decode_lane(cfg.exec_vif.data.tmask);
                    item = lsu_uvm_item::type_id::create("mon_req");
                    item.uuid = cfg.exec_vif.data.uuid;
                    item.is_store = cfg.exec_vif.data.op_args.lsu.is_store;
                    item.addr = cfg.exec_vif.data.rs1_data[lane];
                    item.store_data = cfg.exec_vif.data.rs2_data[lane];
                    item.op_type = cfg.exec_vif.data.op_type;
                    item.lane = lane;
                    ap.write(item);
                end
            end
        endtask
    endclass

    class lsu_uvm_result_monitor extends uvm_component;
        `uvm_component_utils(lsu_uvm_result_monitor)

        lsu_uvm_cfg cfg;
        uvm_analysis_port #(lsu_uvm_rsp_item) ap;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            ap = new("ap", this);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(lsu_uvm_cfg)::get(this, "", "cfg", cfg))
                `uvm_fatal("NOCFG", "lsu_uvm_cfg was not provided")
        endfunction

        task run_phase(uvm_phase phase);
            lsu_uvm_rsp_item rsp;
            forever begin
                @(posedge cfg.ctrl_vif.clk);
                if (!cfg.ctrl_vif.reset && cfg.result_vif.valid && cfg.result_vif.ready && cfg.result_vif.data.wb) begin
                    rsp = lsu_uvm_rsp_item::type_id::create("rsp");
                    rsp.uuid = cfg.result_vif.data.uuid;
                    rsp.data = cfg.result_vif.data.data;
                    ap.write(rsp);
                end
            end
        endtask
    endclass

    class lsu_uvm_scoreboard extends uvm_component;
        `uvm_component_utils(lsu_uvm_scoreboard)

        uvm_analysis_imp_req #(lsu_uvm_item, lsu_uvm_scoreboard) req_imp;
        uvm_analysis_imp_rsp #(lsu_uvm_rsp_item, lsu_uvm_scoreboard) rsp_imp;

        lsu_scoreboard_class sb;
        lsu_sequence_item_class pending_loads[$];
        logic [`NUM_LSU_LANES-1:0][`XLEN-1:0] orphan_rsp_data[int unsigned];
        int unsigned seen_fences;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            req_imp = new("req_imp", this);
            rsp_imp = new("rsp_imp", this);
            sb = new();
        endfunction

        function lsu_sequence_item_class convert_req(input lsu_uvm_item t);
            lsu_sequence_item_class item;
            item = new();
            item.uuid = t.uuid;
            item.is_store = t.is_store;
            item.addr = t.addr;
            item.store_data = t.store_data;
            item.op_type = t.op_type;
            item.lane = t.lane;
            item.mask = '0;
            item.mask[t.lane] = 1'b1;
            item.observed_valid = 1'b0;
            item.observed_data = '0;
            return item;
        endfunction

        function int find_pending_idx(input logic [UUID_WIDTH-1:0] uuid);
            for (int i = 0; i < pending_loads.size(); i++) begin
                if (pending_loads[i].uuid == uuid)
                    return i;
            end
            return -1;
        endfunction

        function void write_req(lsu_uvm_item t);
            lsu_sequence_item_class item;
            item = convert_req(t);

            if (inst_lsu_is_fence(t.op_type)) begin
                seen_fences++;
                `uvm_info("LSU_SB",
                    $sformatf("Observed fence uuid=%0d lane=%0d", t.uuid, t.lane),
                    UVM_LOW)
                return;
            end

            if (t.is_store) begin
                sb.scoreboard(item);
                return;
            end

            if (orphan_rsp_data.exists(int'(t.uuid))) begin
                item.observed_valid = 1'b1;
                item.observed_data = orphan_rsp_data[int'(t.uuid)][t.lane];
                orphan_rsp_data.delete(int'(t.uuid));
                sb.scoreboard(item);
            end else begin
                pending_loads.push_back(item);
            end
        endfunction

        function void write_rsp(lsu_uvm_rsp_item t);
            int idx;
            idx = find_pending_idx(t.uuid);
            if (idx >= 0) begin
                lsu_sequence_item_class item;
                item = pending_loads[idx];
                pending_loads.delete(idx);
                item.observed_valid = 1'b1;
                item.observed_data = t.data[item.lane];
                sb.scoreboard(item);
            end else begin
                orphan_rsp_data[int'(t.uuid)] = t.data;
            end
        endfunction

        function void check_phase(uvm_phase phase);
            super.check_phase(phase);
            if (pending_loads.size() != 0)
                `uvm_error("LSU_SB", $sformatf("Pending load queue not empty: %0d", pending_loads.size()))
            if (sb.wrong_count != 0)
                `uvm_error("LSU_SB", $sformatf("Scoreboard mismatches detected: %0d", sb.wrong_count))
        endfunction

        function void report_phase(uvm_phase phase);
            super.report_phase(phase);
            `uvm_info("LSU_SB_SUMMARY",
                $sformatf("scoreboard_pass=%0d scoreboard_fail=%0d fences=%0d pending=%0d",
                    sb.right_count, sb.wrong_count, seen_fences, pending_loads.size()),
                UVM_NONE)
        endfunction
    endclass

    class lsu_uvm_agent extends uvm_component;
        `uvm_component_utils(lsu_uvm_agent)

        lsu_uvm_sequencer sequencer;
        lsu_uvm_driver driver;
        lsu_uvm_exec_monitor exec_monitor;
        lsu_uvm_result_monitor result_monitor;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            sequencer = lsu_uvm_sequencer::type_id::create("sequencer", this);
            driver = lsu_uvm_driver::type_id::create("driver", this);
            exec_monitor = lsu_uvm_exec_monitor::type_id::create("exec_monitor", this);
            result_monitor = lsu_uvm_result_monitor::type_id::create("result_monitor", this);
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            driver.seq_item_port.connect(sequencer.seq_item_export);
        endfunction
    endclass

    class lsu_uvm_env extends uvm_component;
        `uvm_component_utils(lsu_uvm_env)

        lsu_uvm_agent agent;
        lsu_uvm_scoreboard scoreboard;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            agent = lsu_uvm_agent::type_id::create("agent", this);
            scoreboard = lsu_uvm_scoreboard::type_id::create("scoreboard", this);
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            agent.exec_monitor.ap.connect(scoreboard.req_imp);
            agent.result_monitor.ap.connect(scoreboard.rsp_imp);
        endfunction
    endclass

    class lsu_uvm_main_test extends uvm_test;
        `uvm_component_utils(lsu_uvm_main_test)

        lsu_uvm_env env;
        lsu_uvm_cfg cfg;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            if (!uvm_config_db#(lsu_uvm_cfg)::get(this, "", "cfg", cfg))
                `uvm_fatal("NOCFG", "lsu_uvm_cfg was not provided by the top module")

            uvm_config_db#(lsu_uvm_cfg)::set(this, "*", "cfg", cfg);
            env = lsu_uvm_env::type_id::create("env", this);
        endfunction

        task run_phase(uvm_phase phase);
            lsu_uvm_directed_seq directed_seq;
            lsu_uvm_random_seq random_seq;

            phase.raise_objection(this);

            directed_seq = lsu_uvm_directed_seq::type_id::create("directed_seq");
            directed_seq.start(env.agent.sequencer);

            random_seq = lsu_uvm_random_seq::type_id::create("random_seq");
            random_seq.n_ops = cfg.random_ops;
            random_seq.enable_fence_tests = cfg.enable_fence_tests;
            random_seq.start(env.agent.sequencer);

            repeat (50) @(posedge cfg.ctrl_vif.clk);
            phase.drop_objection(this);
        endtask
    endclass

endpackage
