`include "VX_define.vh"

module lsu_if_assertions (
    input wire clk,
    input wire reset,
    VX_execute_if execute_if,
    VX_result_if result_if,
    VX_lsu_mem_if lsu_mem_if
);

    a_exec_hold: assert property (
        @(posedge clk) disable iff (reset)
        (execute_if.valid && !execute_if.ready) |=>
            (execute_if.valid && $stable(execute_if.data))
    ) else $error("ASSERT: execute_if payload changed before handshake");

    a_mem_req_hold: assert property (
        @(posedge clk) disable iff (reset)
        (lsu_mem_if.req_valid && !lsu_mem_if.req_ready) |=>
            (lsu_mem_if.req_valid && $stable(lsu_mem_if.req_data))
    ) else $error("ASSERT: lsu_mem_if request payload changed before handshake");

    a_mem_rsp_hold: assert property (
        @(posedge clk) disable iff (reset)
        (lsu_mem_if.rsp_valid && !lsu_mem_if.rsp_ready) |=>
            (lsu_mem_if.rsp_valid && $stable(lsu_mem_if.rsp_data))
    ) else $error("ASSERT: lsu_mem_if response payload changed before handshake");

    a_result_hold: assert property (
        @(posedge clk) disable iff (reset)
        (result_if.valid && !result_if.ready) |=>
            (result_if.valid && $stable(result_if.data))
    ) else $error("ASSERT: result_if payload changed before handshake");

    a_exec_mask_nonzero: assert property (
        @(posedge clk) disable iff (reset)
        execute_if.valid |-> (execute_if.data.tmask != '0)
    ) else $error("ASSERT: execute_if tmask is zero");

    a_exec_mask_onehot: assert property (
        @(posedge clk) disable iff (reset)
        execute_if.valid |-> $onehot(execute_if.data.tmask)
    ) else $error("ASSERT: execute_if tmask is not one-hot");

    int pending_req_count;

    always @(posedge clk) begin
        if (reset) begin
            pending_req_count <= 0;
        end else begin
            case ({lsu_mem_if.req_valid && lsu_mem_if.req_ready,
                   lsu_mem_if.rsp_valid && lsu_mem_if.rsp_ready})
                2'b10: pending_req_count <= pending_req_count + 1;
                2'b01: begin
                    if (pending_req_count == 0)
                        $error("ASSERT: response without pending request");
                    else
                        pending_req_count <= pending_req_count - 1;
                end
                default: pending_req_count <= pending_req_count;
            endcase
        end
    end

endmodule
