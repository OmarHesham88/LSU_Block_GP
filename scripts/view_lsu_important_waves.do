proc add_sig {path} {
    if {[catch {add wave $path} err]} {
        puts "Skipping wave $path: $err"
    }
}

quietly WaveActivateNextPane {} 0

add wave -divider "Clock / Reset"
add_sig sim:/lsu_slice_tb_v2/clk
add_sig sim:/lsu_slice_tb_v2/reset

add wave -divider "Execute Request"
add_sig sim:/lsu_slice_tb_v2/execute_if/valid
add_sig sim:/lsu_slice_tb_v2/execute_if/ready
add_sig sim:/lsu_slice_tb_v2/execute_if/data/uuid
add_sig sim:/lsu_slice_tb_v2/execute_if/data/tmask
add_sig sim:/lsu_slice_tb_v2/execute_if/data/op_type
add_sig sim:/lsu_slice_tb_v2/execute_if/data/op_args/lsu/is_store
add_sig sim:/lsu_slice_tb_v2/execute_if/data/rs1_data
add_sig sim:/lsu_slice_tb_v2/execute_if/data/rs2_data

add wave -divider "Memory Request"
add_sig sim:/lsu_slice_tb_v2/lsu_mem_if/req_valid
add_sig sim:/lsu_slice_tb_v2/lsu_mem_if/req_ready
add_sig sim:/lsu_slice_tb_v2/lsu_mem_if/req_data/mask
add_sig sim:/lsu_slice_tb_v2/lsu_mem_if/req_data/rw
add_sig sim:/lsu_slice_tb_v2/lsu_mem_if/req_data/addr
add_sig sim:/lsu_slice_tb_v2/lsu_mem_if/req_data/byteen
add_sig sim:/lsu_slice_tb_v2/lsu_mem_if/req_data/data
add_sig sim:/lsu_slice_tb_v2/lsu_mem_if/req_data/tag

add wave -divider "Memory Response"
add_sig sim:/lsu_slice_tb_v2/lsu_mem_if/rsp_valid
add_sig sim:/lsu_slice_tb_v2/lsu_mem_if/rsp_ready
add_sig sim:/lsu_slice_tb_v2/lsu_mem_if/rsp_data/mask
add_sig sim:/lsu_slice_tb_v2/lsu_mem_if/rsp_data/data
add_sig sim:/lsu_slice_tb_v2/lsu_mem_if/rsp_data/tag

add wave -divider "Result Writeback"
add_sig sim:/lsu_slice_tb_v2/result_if/valid
add_sig sim:/lsu_slice_tb_v2/result_if/ready
add_sig sim:/lsu_slice_tb_v2/result_if/data/uuid
add_sig sim:/lsu_slice_tb_v2/result_if/data/wb
add_sig sim:/lsu_slice_tb_v2/result_if/data/tmask
add_sig sim:/lsu_slice_tb_v2/result_if/data/data

add wave -divider "TB Observability"
add_sig sim:/lsu_slice_tb_v2/issue_is_store
add_sig sim:/lsu_slice_tb_v2/issue_lane
add_sig sim:/lsu_slice_tb_v2/issue_addr
add_sig sim:/lsu_slice_tb_v2/issue_op

run -all
wave zoom full
