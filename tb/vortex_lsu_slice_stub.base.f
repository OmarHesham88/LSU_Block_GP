# =========================================================
#  Vortex RTL – LSU Slice Testbench (Full GPU Package)
# =========================================================

# ---------- Include paths
+incdir+../../vortex-master/vortex-master/hw/rtl
+incdir+../../vortex-master/vortex-master/hw/rtl/interfaces
+incdir+../../vortex-master/vortex-master/hw/rtl/core
+incdir+../../vortex-master/vortex-master/hw/rtl/libs
+incdir+../../vortex-master/vortex-master/hw/rtl/mem

# ---------- Configuration (MUST come first)
../../vortex-master/vortex-master/hw/rtl/VX_config.vh
../../vortex-master/vortex-master/hw/rtl/VX_platform.vh

# ---------- Global headers
../../vortex-master/vortex-master/hw/rtl/VX_define.vh
../../vortex-master/vortex-master/hw/rtl/VX_types.vh
../../vortex-master/vortex-master/hw/rtl/VX_scope.vh

# ---------- Core packages
../../vortex-master/vortex-master/hw/rtl/VX_gpu_pkg.sv
../../vortex-master/vortex-master/hw/rtl/VX_trace_pkg.sv

# ---------- Interfaces
../../vortex-master/vortex-master/hw/rtl/interfaces/VX_execute_if.sv
../../vortex-master/vortex-master/hw/rtl/interfaces/VX_result_if.sv
../../vortex-master/vortex-master/hw/rtl/mem/VX_lsu_mem_if.sv
../../vortex-master/vortex-master/hw/rtl/mem/VX_mem_bus_if.sv

# ---------- Libraries
../../vortex-master/vortex-master/hw/rtl/libs/VX_find_first.sv
../../vortex-master/vortex-master/hw/rtl/libs/VX_lzc.sv
../../vortex-master/vortex-master/hw/rtl/libs/VX_priority_encoder.sv
../../vortex-master/vortex-master/hw/rtl/libs/VX_priority_arbiter.sv
../../vortex-master/vortex-master/hw/rtl/libs/VX_elastic_buffer.sv
../../vortex-master/vortex-master/hw/rtl/libs/VX_pipe_buffer.sv
../../vortex-master/vortex-master/hw/rtl/libs/VX_stream_buffer.sv
../../vortex-master/vortex-master/hw/rtl/libs/VX_fifo_queue.sv
../../vortex-master/vortex-master/hw/rtl/libs/VX_generic_arbiter.sv
../../vortex-master/vortex-master/hw/rtl/libs/VX_stream_pack.sv
../../vortex-master/vortex-master/hw/rtl/libs/VX_stream_unpack.sv
../../vortex-master/vortex-master/hw/rtl/libs/VX_stream_arb.sv
../../vortex-master/vortex-master/hw/rtl/libs/VX_allocator.sv
VX_index_buffer.sv
../../vortex-master/vortex-master/hw/rtl/libs/VX_dp_ram.sv

# ---------- Memory
../../vortex-master/vortex-master/hw/rtl/libs/VX_mem_scheduler.sv

# ---------- Unit under test
../../vortex-master/vortex-master/hw/rtl/core/VX_lsu_slice.sv

# ---------- Testbench support
lsu_seq_item.sv
lsu_scoreboard.sv
lsu_monitor.sv
vx_lsu_mem_model.sv
vx_lsu_slice_tb.sv
