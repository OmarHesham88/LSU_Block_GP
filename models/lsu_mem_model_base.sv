`include "../../vortex-master/vortex-master/hw/rtl/VX_config.vh"
`include "../../vortex-master/vortex-master/hw/rtl/VX_platform.vh"
`include "../../vortex-master/vortex-master/hw/rtl/VX_define.vh"

import VX_gpu_pkg::*;

module lsu_simple_mem #(
    parameter MEM_BYTES = 4096
) (
    input  wire clk,
    input  wire reset,

    VX_lsu_mem_if.slave mem_if
);

    localparam NUM_LANES = `NUM_LSU_LANES;

    // simple byte-addressable RAM
    byte mem [0:MEM_BYTES-1];

    initial begin
        for (int i = 0; i < MEM_BYTES; ++i)
            mem[i] = 0;
    end

    // response registers (two-stage valid to align with index-buffer read)
    reg rsp_valid_r;
    reg rsp_valid_d;
    reg [LSU_TAG_WIDTH-1:0] rsp_tag_r;
    reg [NUM_LANES-1:0] rsp_mask_r;
    reg [NUM_LANES-1:0][LSU_WORD_SIZE*8-1:0] rsp_data_r;

    assign mem_if.req_ready = !(rsp_valid_r || rsp_valid_d); // single outstanding (with 1-cycle response delay)
    assign mem_if.rsp_valid = rsp_valid_d;
    assign mem_if.rsp_data.tag  = rsp_tag_r;
    assign mem_if.rsp_data.mask = rsp_mask_r;
    assign mem_if.rsp_data.data = rsp_data_r;

    always @(posedge clk) begin
        if (reset) begin
            rsp_valid_r <= 0;
            rsp_valid_d <= 0;
            rsp_tag_r   <= '0;
            rsp_mask_r  <= '0;
            rsp_data_r  <= '0;
        end else begin
            // consume response (output stage) - drop after one cycle
            if (rsp_valid_d) begin
                rsp_valid_d <= 0;
            end

            // accept request
            if (mem_if.req_valid && mem_if.req_ready) begin
                rsp_tag_r  <= {mem_if.req_data.tag.uuid, mem_if.req_data.tag.value};
                rsp_mask_r <= mem_if.req_data.mask;

                // process per lane
                for (int l = 0; l < NUM_LANES; l++) begin
                    rsp_data_r[l] <= '0;

                    if (mem_if.req_data.mask[l]) begin
                        int base;
                        base = mem_if.req_data.addr[l] * LSU_WORD_SIZE;

                        if (mem_if.req_data.rw) begin
                            // STORE
                            for (int b = 0; b < LSU_WORD_SIZE; b++) begin
                                if (mem_if.req_data.byteen[l][b]) begin
                                    mem[base + b]
                                        <= mem_if.req_data.data[l][b*8 +: 8];
                                end
                            end
                        end else begin
                            // LOAD
                            for (int b = 0; b < LSU_WORD_SIZE; b++) begin
                                rsp_data_r[l][b*8 +: 8]
                                    <= mem[base + b];
                            end
                        end
                    end
                end

                rsp_valid_r <= 1'b1;
            end

            // advance to output stage
            if (rsp_valid_r && !rsp_valid_d) begin
                rsp_valid_d <= 1'b1;
                rsp_valid_r <= 1'b0;
            end
        end
    end

endmodule
