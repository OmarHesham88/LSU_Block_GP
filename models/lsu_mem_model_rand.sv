`include "VX_config.vh"
`include "VX_platform.vh"
`include "VX_define.vh"

import VX_gpu_pkg::*;

module lsu_mem_model_rand #(
    parameter int MEM_BYTES = 4096,
    parameter int MAX_OUTSTANDING = 8,
    parameter int MIN_RSP_LATENCY = 1,
    parameter int MAX_RSP_LATENCY = 5,
    parameter bit ENABLE_REQ_BACKPRESSURE = 1,
    parameter bit ENABLE_OOO_RESPONSES = 1
) (
    input  wire clk,
    input  wire reset,
    VX_lsu_mem_if.slave mem_if
);

    localparam int NUM_LANES = `NUM_LSU_LANES;
    localparam int WORD_BYTES = LSU_WORD_SIZE;

    typedef struct {
        logic [LSU_TAG_WIDTH-1:0]               tag;
        logic [NUM_LANES-1:0]                   mask;
        logic [NUM_LANES-1:0][WORD_BYTES*8-1:0] data;
        int unsigned                            due_cycle;
    } rsp_entry_t;

    byte mem [longint];
    rsp_entry_t rsp_q[$];

    logic rsp_valid_r;
    logic [LSU_TAG_WIDTH-1:0] rsp_tag_r;
    logic [NUM_LANES-1:0] rsp_mask_r;
    logic [NUM_LANES-1:0][WORD_BYTES*8-1:0] rsp_data_r;
    int unsigned cycle_ctr;
    logic req_bp_allow_r;

    function automatic int unsigned rand_between(input int unsigned lo, input int unsigned hi);
        if (hi <= lo)
            return lo;
        return lo + $urandom_range(hi - lo, 0);
    endfunction

    task automatic push_response(
        input logic [LSU_TAG_WIDTH-1:0]               tag,
        input logic [NUM_LANES-1:0]                   mask,
        input logic [NUM_LANES-1:0][WORD_BYTES*8-1:0] data
    );
        rsp_entry_t e;
        int unsigned lat;
        lat = rand_between(MIN_RSP_LATENCY, MAX_RSP_LATENCY);
        e.tag = tag;
        e.mask = mask;
        e.data = data;
        e.due_cycle = cycle_ctr + lat;
        rsp_q.push_back(e);
    endtask

    function automatic int find_ready_rsp();
        int idx;
        int ready_idxs[$];
        for (int i = 0; i < rsp_q.size(); i++) begin
            if (rsp_q[i].due_cycle <= cycle_ctr)
                ready_idxs.push_back(i);
        end
        if (ready_idxs.size() == 0)
            return -1;
        if (ENABLE_OOO_RESPONSES && ready_idxs.size() > 1)
            idx = ready_idxs[$urandom_range(ready_idxs.size()-1, 0)];
        else
            idx = ready_idxs[0];
        return idx;
    endfunction

    assign mem_if.req_ready = (rsp_q.size() < MAX_OUTSTANDING) && req_bp_allow_r;
    assign mem_if.rsp_valid = rsp_valid_r;
    assign mem_if.rsp_data.tag = rsp_tag_r;
    assign mem_if.rsp_data.mask = rsp_mask_r;
    assign mem_if.rsp_data.data = rsp_data_r;

    always @(posedge clk) begin
        if (reset) begin
            cycle_ctr   <= 0;
            rsp_valid_r <= 0;
            rsp_tag_r   <= '0;
            rsp_mask_r  <= '0;
            rsp_data_r  <= '0;
            req_bp_allow_r <= 1'b1;
            rsp_q.delete();
        end else begin
            cycle_ctr <= cycle_ctr + 1;
            req_bp_allow_r <= !ENABLE_REQ_BACKPRESSURE || ($urandom_range(99, 0) >= 20);

            if (rsp_valid_r && mem_if.rsp_ready)
                rsp_valid_r <= 1'b0;

            if (mem_if.req_valid && mem_if.req_ready) begin
                logic [NUM_LANES-1:0][WORD_BYTES*8-1:0] rsp_data_next;
                rsp_data_next = '0;

                for (int l = 0; l < NUM_LANES; l++) begin
                    if (mem_if.req_data.mask[l]) begin
                        longint base;
                        base = longint'(mem_if.req_data.addr[l]) * longint'(WORD_BYTES);

                        if (mem_if.req_data.rw) begin
                            for (int b = 0; b < WORD_BYTES; b++) begin
                                if (mem_if.req_data.byteen[l][b])
                                    mem[base + b] = mem_if.req_data.data[l][b*8 +: 8];
                            end
                        end else begin
                            for (int b = 0; b < WORD_BYTES; b++) begin
                                rsp_data_next[l][b*8 +: 8] = mem.exists(base + b) ? mem[base + b] : 8'h00;
                            end
                        end
                    end
                end

                push_response({mem_if.req_data.tag.uuid, mem_if.req_data.tag.value},
                    mem_if.req_data.mask,
                    rsp_data_next);
            end

            if (!rsp_valid_r) begin
                int sel;
                sel = find_ready_rsp();
                if (sel >= 0) begin
                    rsp_valid_r <= 1'b1;
                    rsp_tag_r   <= rsp_q[sel].tag;
                    rsp_mask_r  <= rsp_q[sel].mask;
                    rsp_data_r  <= rsp_q[sel].data;
                    rsp_q.delete(sel);
                end
            end
        end
    end

endmodule
