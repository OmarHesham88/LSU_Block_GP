package lsu_monitor_pkg;
    import lsu_sequence_item_pkg::*;
    import lsu_scoreboard_pkg::*;

    class lsu_monitor_class;
        lsu_scoreboard_class scoreboard = new();

        task automatic monitor(input lsu_sequence_item_class item);
            scoreboard.scoreboard(item);
        endtask
    endclass

endpackage
