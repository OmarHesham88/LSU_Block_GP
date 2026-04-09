`include "VX_define.vh"

package lsu_scoreboard_pkg;
    import VX_gpu_pkg::*;
    import lsu_sequence_item_pkg::*;

    class lsu_scoreboard_class;
        int right_count, wrong_count;
        byte mem [longint];

        function automatic int lsu_size_bytes(input logic [INST_LSU_BITS-1:0] op);
            case (inst_lsu_wsize(op))
                2'd0: return 1;
                2'd1: return 2;
                2'd2: return 4;
                default: return 8;
            endcase
        endfunction

        function automatic logic [63:0] load_raw_bytes(input logic [`XLEN-1:0] addr, input int size);
            logic [63:0] raw;
            raw = '0;
            for (int i = 0; i < size; i++) begin
                longint a = longint'(addr) + longint'(i);
                raw[i*8 +: 8] = mem.exists(a) ? mem[a] : 8'h00;
            end
            return raw;
        endfunction

        function automatic logic [`XLEN-1:0] format_load_data(
            input logic [INST_LSU_BITS-1:0] op,
            input logic [63:0] raw
        );
            logic [`XLEN-1:0] out;
            case (inst_lsu_fmt(op))
                LSU_FMT_B:  out = `XLEN'($signed(raw[7:0]));
                LSU_FMT_H:  out = `XLEN'($signed(raw[15:0]));
                LSU_FMT_BU: out = `XLEN'(raw[7:0]);
                LSU_FMT_HU: out = `XLEN'(raw[15:0]);
            `ifdef XLEN_64
                LSU_FMT_W:  out = `XLEN'($signed(raw[31:0]));
                LSU_FMT_WU: out = `XLEN'(raw[31:0]);
                LSU_FMT_D:  out = `XLEN'($signed(raw[63:0]));
            `else
                LSU_FMT_W:  out = `XLEN'($signed(raw[31:0]));
            `endif
                default:    out = 'x;
            endcase
            return out;
        endfunction

        task automatic scoreboard(input lsu_sequence_item_class item);
            logic [`XLEN-1:0] exp;
            int size;
            size = lsu_size_bytes(item.op_type);
            if (size > LSU_WORD_SIZE)
                size = LSU_WORD_SIZE;

            if (item.is_store) begin
                for (int i = 0; i < size; i++) begin
                    longint a = longint'(item.addr) + longint'(i);
                    mem[a] = item.store_data[i*8 +: 8];
                end
                right_count++;
                $display("[%0t] [PASS] STORE lane=%0d addr=0x%0h data=0x%0h op=0x%0h R:%0d W:%0d",
                    $time, item.lane, item.addr, item.store_data, item.op_type, right_count, wrong_count);
            end else begin
                exp = format_load_data(item.op_type, load_raw_bytes(item.addr, size));
                if (item.observed_valid && (item.observed_data === exp)) begin
                    right_count++;
                    $display("[%0t] [PASS] LOAD lane=%0d addr=0x%0h data=0x%0h exp=0x%0h op=0x%0h R:%0d W:%0d",
                        $time, item.lane, item.addr, item.observed_data, exp, item.op_type, right_count, wrong_count);
                end else begin
                    wrong_count++;
                    $display("[%0t] [FAIL] LOAD lane=%0d addr=0x%0h got=0x%0h exp=0x%0h op=0x%0h R:%0d W:%0d",
                        $time, item.lane, item.addr, item.observed_data, exp, item.op_type, right_count, wrong_count);
                end
            end
        endtask
    endclass

endpackage
