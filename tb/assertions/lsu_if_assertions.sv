`include "VX_define.vh"

module lsu_if_assertions (
    input wire clk,
    input wire reset,
    VX_execute_if execute_if,
    VX_result_if result_if,
    VX_lsu_mem_if lsu_mem_if
);

    property p_valid_hold(input logic valid_s, input logic ready_s);
        @(posedge clk) disable iff (reset)
            (valid_s && !ready_s) |=> valid_s;
    endproperty

    a_exec_hold: assert property (p_valid_hold(execute_if.valid, execute_if.ready))
        else $error("ASSERT: execute_if.valid dropped before handshake");

    a_mem_req_hold: assert property (p_valid_hold(lsu_mem_if.req_valid, lsu_mem_if.req_ready))
        else $error("ASSERT: lsu_mem_if.req_valid dropped before handshake");

    a_mem_rsp_hold: assert property (p_valid_hold(lsu_mem_if.rsp_valid, lsu_mem_if.rsp_ready))
        else $error("ASSERT: lsu_mem_if.rsp_valid dropped before handshake");

    a_result_hold: assert property (p_valid_hold(result_if.valid, result_if.ready))
        else $error("ASSERT: result_if.valid dropped before handshake");

    a_exec_mask_nonzero: assert property (
        @(posedge clk) disable iff (reset)
        execute_if.valid |-> (execute_if.data.tmask != '0)
    ) else $error("ASSERT: execute_if tmask is zero");

    int pending_req_count;

    always @(posedge clk) begin
        if (reset) begin
            pending_req_count <= 0;
        end else begin
            if (lsu_mem_if.req_valid && lsu_mem_if.req_ready)
                pending_req_count <= pending_req_count + 1;

            if (lsu_mem_if.rsp_valid && lsu_mem_if.rsp_ready) begin
                if (pending_req_count == 0)
                    $error("ASSERT: response without pending request");
                else
                    pending_req_count <= pending_req_count - 1;
            end
        end
    end

endmodule
