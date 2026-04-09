// Simple simulation model for VX_index_buffer with async read
// Handles X on release_en by treating it as asserted.

`include "VX_platform.vh"

`TRACING_OFF
module VX_index_buffer #(
    parameter DATAW = 1,
    parameter SIZE  = 1,
    parameter LUTRAM = 0,
    parameter ADDRW = `LOG2UP(SIZE)
) (
    input  wire             clk,
    input  wire             reset,

    output wire [ADDRW-1:0] write_addr,
    input  wire [DATAW-1:0] write_data,
    input  wire             acquire_en,

    input  wire [ADDRW-1:0] read_addr,
    output wire [DATAW-1:0] read_data,
    input  wire             release_en,

    output wire             empty,
    output wire             full
);

    reg [DATAW-1:0] mem [0:SIZE-1];
    reg [SIZE-1:0] free_slots;
    reg [ADDRW-1:0] write_addr_r;

    wire acquire_en_eff = (acquire_en === 1'b1);
    wire release_en_eff = (release_en !== 1'b0);

    function automatic [ADDRW-1:0] next_free(input [SIZE-1:0] free_mask);
        next_free = '0;
        for (int i = 0; i < SIZE; i++) begin
            if (free_mask[i]) begin
                next_free = ADDRW'(i);
                break;
            end
        end
    endfunction

    wire [SIZE-1:0] free_slots_rel = release_en_eff ? (free_slots | (SIZE'(1) << read_addr)) : free_slots;
    wire [SIZE-1:0] free_slots_n   = acquire_en_eff ? (free_slots_rel & ~(SIZE'(1) << write_addr_r)) : free_slots_rel;

    always @(posedge clk) begin
        if (reset) begin
            free_slots   <= {SIZE{1'b1}};
            write_addr_r <= '0;
        end else begin
            if (acquire_en_eff) begin
                mem[write_addr_r] <= write_data;
            end
            free_slots <= free_slots_n;
            if (acquire_en_eff || release_en_eff) begin
                write_addr_r <= next_free(free_slots_n);
            end
        end
    end

    assign write_addr = write_addr_r;
    assign read_data  = mem[read_addr];
    assign empty = &free_slots;
    assign full  = ~|free_slots;
    `UNUSED_VAR (LUTRAM)
endmodule
`TRACING_ON
