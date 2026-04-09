# =========================================================
#  Vortex LSU Slice Verification v2 (Independent Workspace)
# =========================================================

+incdir+../../vortex-master/vortex-master/hw/rtl
+incdir+../../vortex-master/vortex-master/hw/rtl/interfaces
+incdir+../../vortex-master/vortex-master/hw/rtl/core
+incdir+../../vortex-master/vortex-master/hw/rtl/libs
+incdir+../../vortex-master/vortex-master/hw/rtl/mem
+incdir+tb
+incdir+tb/pkg
+incdir+tb/assertions
+incdir+models
+incdir+tb/tests

../../vortex-master/vortex-master/hw/rtl/VX_config.vh
../../vortex-master/vortex-master/hw/rtl/VX_platform.vh
../../vortex-master/vortex-master/hw/rtl/VX_define.vh
../../vortex-master/vortex-master/hw/rtl/VX_types.vh
../../vortex-master/vortex-master/hw/rtl/VX_scope.vh

../../vortex-master/vortex-master/hw/rtl/VX_gpu_pkg.sv
../../vortex-master/vortex-master/hw/rtl/VX_trace_pkg.sv

../../vortex-master/vortex-master/hw/rtl/interfaces/VX_execute_if.sv
../../vortex-master/vortex-master/hw/rtl/interfaces/VX_result_if.sv
../../vortex-master/vortex-master/hw/rtl/mem/VX_lsu_mem_if.sv
../../vortex-master/vortex-master/hw/rtl/mem/VX_mem_bus_if.sv

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
../../vortex-master/vortex-master/hw/rtl/libs/VX_dp_ram.sv

# Local copied modules (independent from other Verification files)
tb/VX_index_buffer.sv
tb/VX_lsu_slice.sv

../../vortex-master/vortex-master/hw/rtl/libs/VX_mem_scheduler.sv

tb/pkg/lsu_seq_item.sv
tb/pkg/lsu_scoreboard.sv
tb/pkg/lsu_monitor.sv
models/lsu_mem_model_rand.sv
tb/tests/vx_lsu_slice_tb_v2.sv
tb/tests/vx_lsu_slice_tb_misaligned_neg.sv
