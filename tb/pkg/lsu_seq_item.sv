`include "VX_define.vh"

package lsu_sequence_item_pkg;
    import VX_gpu_pkg::*;

    class lsu_sequence_item_class;
        logic [UUID_WIDTH-1:0]       uuid;
        logic                        is_store;
        logic [`XLEN-1:0]            addr;
        logic [`XLEN-1:0]            store_data;
        logic [INST_LSU_BITS-1:0]    op_type;
        int unsigned                 lane;
        logic [`NUM_LSU_LANES-1:0]   mask;
        logic                        observed_valid;
        logic [`XLEN-1:0]            observed_data;
    endclass

endpackage
