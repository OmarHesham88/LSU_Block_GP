package lsu_uvm_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import VX_gpu_pkg::*;

    class lsu_uvm_item extends uvm_sequence_item;
        rand bit                        is_store;
        rand logic [`XLEN-1:0]          addr;
        rand logic [`XLEN-1:0]          store_data;
        rand logic [INST_LSU_BITS-1:0]  op_type;
        rand int unsigned               lane;
        logic [UUID_WIDTH-1:0]          uuid;
        logic                           observed_valid;
        logic [`XLEN-1:0]               observed_data;

        constraint c_lane {
            lane < `NUM_LSU_LANES;
        }

        constraint c_op {
            if (is_store)
                op_type inside {INST_LSU_SB, INST_LSU_SH, INST_LSU_SW};
            else
                op_type inside {INST_LSU_LB, INST_LSU_LBU, INST_LSU_LH, INST_LSU_LHU, INST_LSU_LW, INST_LSU_FENCE};
        }

        `uvm_object_utils_begin(lsu_uvm_item)
            `uvm_field_int(is_store, UVM_DEFAULT)
            `uvm_field_int(addr, UVM_DEFAULT)
            `uvm_field_int(store_data, UVM_DEFAULT)
            `uvm_field_int(op_type, UVM_DEFAULT)
            `uvm_field_int(lane, UVM_DEFAULT)
            `uvm_field_int(uuid, UVM_DEFAULT)
            `uvm_field_int(observed_valid, UVM_DEFAULT | UVM_NOCOMPARE)
            `uvm_field_int(observed_data, UVM_DEFAULT | UVM_NOCOMPARE)
        `uvm_object_utils_end

        function new(string name = "lsu_uvm_item");
            super.new(name);
        endfunction
    endclass

    class lsu_uvm_cfg extends uvm_object;
        virtual VX_execute_if #(lsu_exe_t) exec_vif;
        virtual VX_result_if #(lsu_res_t)  result_vif;
        bit enable_fence = 1'b1;
        int unsigned timeout_cycles = 800;

        `uvm_object_utils(lsu_uvm_cfg)

        function new(string name = "lsu_uvm_cfg");
            super.new(name);
        endfunction
    endclass

    class lsu_uvm_smoke_seq extends uvm_sequence #(lsu_uvm_item);
        `uvm_object_utils(lsu_uvm_smoke_seq)

        function new(string name = "lsu_uvm_smoke_seq");
            super.new(name);
        endfunction

        task body();
            lsu_uvm_item req;

            req = lsu_uvm_item::type_id::create("store_req");
            start_item(req);
            req.is_store = 1'b1;
            req.addr = 32'h100;
            req.store_data = 32'hDEADBEEF;
            req.op_type = INST_LSU_SW;
            req.lane = 0;
            finish_item(req);

            req = lsu_uvm_item::type_id::create("load_req");
            start_item(req);
            req.is_store = 1'b0;
            req.addr = 32'h100;
            req.store_data = '0;
            req.op_type = INST_LSU_LW;
            req.lane = 0;
            finish_item(req);

            req = lsu_uvm_item::type_id::create("fence_req");
            start_item(req);
            req.is_store = 1'b0;
            req.addr = '0;
            req.store_data = '0;
            req.op_type = INST_LSU_FENCE;
            req.lane = 0;
            finish_item(req);
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

        virtual VX_execute_if #(lsu_exe_t) exec_vif;
        logic [UUID_WIDTH-1:0] uuid_ctr;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual VX_execute_if #(lsu_exe_t))::get(this, "", "exec_vif", exec_vif))
                `uvm_fatal("NOVIF", "exec_vif was not provided")
        endfunction

        task run_phase(uvm_phase phase);
            lsu_uvm_item req;
            exec_vif.valid <= 1'b0;
            exec_vif.data  <= '0;
            forever begin
                seq_item_port.get_next_item(req);
                drive_item(req);
                seq_item_port.item_done();
            end
        endtask

        task drive_item(lsu_uvm_item req);
            lsu_exe_t pkt;
            pkt = '0;

            req.uuid               = uuid_ctr;
            pkt.uuid               = uuid_ctr;
            pkt.wid                = '0;
            pkt.tmask              = '0;
            pkt.tmask[req.lane]    = 1'b1;
            pkt.PC                 = '0;
            pkt.op_type            = req.op_type;
            pkt.op_args            = '0;
            pkt.op_args.lsu.is_store = req.is_store;
            pkt.op_args.lsu.is_float = 1'b0;
            pkt.op_args.lsu.offset = '0;
            pkt.wb                 = (~req.is_store) && (~inst_lsu_is_fence(req.op_type));
            pkt.rd                 = '0;
            pkt.pid                = '0;
            pkt.sop                = 1'b1;
            pkt.eop                = 1'b1;

            for (int i = 0; i < `NUM_LSU_LANES; i++) begin
                pkt.rs1_data[i] = req.addr;
                pkt.rs2_data[i] = req.store_data;
                pkt.rs3_data[i] = '0;
            end

            exec_vif.data  <= pkt;
            exec_vif.valid <= 1'b1;
            wait (exec_vif.ready === 1'b1);
            #1;
            exec_vif.valid <= 1'b0;
            exec_vif.data  <= '0;
            uuid_ctr <= uuid_ctr + 1'b1;
        endtask
    endclass

    class lsu_uvm_result_monitor extends uvm_component;
        `uvm_component_utils(lsu_uvm_result_monitor)

        virtual VX_result_if #(lsu_res_t) result_vif;
        uvm_analysis_port #(lsu_uvm_item) ap;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            ap = new("ap", this);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual VX_result_if #(lsu_res_t))::get(this, "", "result_vif", result_vif))
                `uvm_fatal("NOVIF", "result_vif was not provided")
        endfunction

        task run_phase(uvm_phase phase);
            lsu_uvm_item rsp;
            forever begin
                wait (result_vif.valid && result_vif.ready && result_vif.data.wb);
                rsp = lsu_uvm_item::type_id::create("rsp");
                rsp.uuid = result_vif.data.uuid;
                rsp.observed_valid = 1'b1;
                rsp.observed_data = result_vif.data.data[0];
                ap.write(rsp);
                wait (!(result_vif.valid && result_vif.ready));
            end
        endtask
    endclass

    class lsu_uvm_scoreboard extends uvm_component;
        `uvm_component_utils(lsu_uvm_scoreboard)

        uvm_analysis_imp #(lsu_uvm_item, lsu_uvm_scoreboard) result_imp;
        int unsigned seen_results;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            result_imp = new("result_imp", this);
        endfunction

        function void write(lsu_uvm_item t);
            seen_results++;
            `uvm_info("LSU_SB",
                $sformatf("Observed response uuid=%0d data=0x%0h", t.uuid, t.observed_data),
                UVM_MEDIUM)
        endfunction
    endclass

    class lsu_uvm_agent extends uvm_component;
        `uvm_component_utils(lsu_uvm_agent)

        lsu_uvm_sequencer sequencer;
        lsu_uvm_driver driver;
        lsu_uvm_result_monitor result_monitor;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            sequencer = lsu_uvm_sequencer::type_id::create("sequencer", this);
            driver = lsu_uvm_driver::type_id::create("driver", this);
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
            agent.result_monitor.ap.connect(scoreboard.result_imp);
        endfunction
    endclass

    class lsu_uvm_smoke_test extends uvm_test;
        `uvm_component_utils(lsu_uvm_smoke_test)

        lsu_uvm_env env;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            env = lsu_uvm_env::type_id::create("env", this);
        endfunction

        task run_phase(uvm_phase phase);
            lsu_uvm_smoke_seq seq;
            phase.raise_objection(this);
            seq = lsu_uvm_smoke_seq::type_id::create("seq");
            seq.start(env.agent.sequencer);
            #500;
            phase.drop_objection(this);
        endtask
    endclass

endpackage

