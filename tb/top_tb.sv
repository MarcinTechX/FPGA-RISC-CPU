`timescale 1ns/1ps

module top_tb;

    localparam integer CLK_HZ = 10;
    localparam integer DISPLAY_REFRESH_COUNT = 10;
    localparam integer DEBOUNCE_COUNT = 2;

    logic clk;
    logic [2:0] KEY;
    logic [7:0] SEGMENTS;
    logic [3:0] DS;

    top #(
        .CLK_HZ(CLK_HZ),
        .DISPLAY_REFRESH_COUNT(DISPLAY_REFRESH_COUNT),
        .DEBOUNCE_COUNT(DEBOUNCE_COUNT)
    ) dut (
        .clk      (clk),
        .KEY      (KEY),
        .SEGMENTS (SEGMENTS),
        .DS       (DS)
    );

    initial clk = 1'b0;
    always #50 clk = ~clk;

    initial begin
        $monitor("%0t KEY=%b paused=%b halted=%b pc=%0d",
                 $time, KEY, dut.paused, dut.halted, dut.pc);
    end

    task automatic load_program;
        int n;
        logic [15:0] prog [0:29];
        begin
            prog[0]  = 16'h43FB;  // MOVI R1, -5
            prog[1]  = 16'h4403;  // MOVI R2, 3
            prog[2]  = 16'h0650;  // ADD R3, R1, R2
            prog[3]  = 16'h1250;  // SUB R1, R1, R2
            prog[4]  = 16'h0650;  // ADD R3, R1, R2
            prog[5]  = 16'h27C8;  // AND R3, R7, R1
            prog[6]  = 16'h38D0;  // OR R4, R3, R2
            prog[7]  = 16'h58C0;  // NOT R4, R3
            prog[8]  = 16'h6B00;  // SHL R5, R4
            prog[9]  = 16'h7D40;  // SHR R6, R5
            prog[10] = 16'h88C0;  // INC R4, R3
            prog[11] = 16'h9D40;  // DEC R6, R5
            prog[12] = 16'h4201;  // MOVI R1, 1
            prog[13] = 16'h45FF;  // MOVI R2, -1
            prog[14] = 16'h0650;  // ADD R3, R1, R2
            prog[15] = 16'h1250;  // SUB R1, R1, R2
            prog[16] = 16'h58C0;  // NOT R4, R3
            prog[17] = 16'h6B00;  // SHL R5, R4
            prog[18] = 16'h7D40;  // SHR R6, R5
            prog[19] = 16'h9D40;  // DEC R6, R5
            prog[20] = 16'h4200;  // MOVI R1, 0
            prog[21] = 16'hC218;  // JZ R1, 24
            prog[22] = 16'h4463;  // MOVI R2, 99 (skipped)
            prog[23] = 16'hB019;  // JMP 25 (skipped)
            prog[24] = 16'h4402;  // MOVI R2, 2
            prog[25] = 16'h4201;  // MOVI R1, 1
            prog[26] = 16'hD21C;  // JNZ R1, 28
            prog[27] = 16'h4463;  // MOVI R2, 99 (skipped)
            prog[28] = 16'hB01D;  // JMP 29
            prog[29] = 16'hF000;  // HALT

            for (n = 0; n < 30; n = n + 1)
                dut.processor.program_memory[n] = prog[n];

            $display("PROGRAM LOADED BY TB: mem[0]=%04h mem[29]=%04h",
                     dut.processor.program_memory[0],
                     dut.processor.program_memory[29]);
        end
    endtask

    task automatic wait_cycles(input integer count);
        repeat (count) @(posedge clk);
        #1;
    endtask

    task automatic check_pc(input logic [15:0] expected);
        begin
            assert (dut.pc == expected)
            else $fatal(1,
                "FAIL: expected PC=%0d, got PC=%0d",
                expected, dut.pc);

            $display("PASS: PC=%0d", expected);
        end
    endtask

    task automatic check_result(input logic [15:0] expected);
        begin
            assert (dut.cpu_result == expected)
            else $fatal(1,
                "FAIL: expected result=0x%04h, got 0x%04h",
                expected, dut.cpu_result);

            $display("PASS: result=0x%04h", expected);
        end
    endtask

    task automatic check_register(
        input integer address,
        input logic [15:0] expected
    );
        begin
            assert (dut.processor.rf.registers[address] == expected)
            else $fatal(1,
                "FAIL: R%0d expected 0x%04h, got 0x%04h",
                address,
                expected,
                dut.processor.rf.registers[address]);

            $display("PASS: R%0d = 0x%04h",
                     address, expected);
        end
    endtask

    task automatic press_button(input integer button_index);
        begin
            @(negedge clk);
            KEY[button_index] = 1'b0;

            wait_cycles(DEBOUNCE_COUNT + 8);

            @(negedge clk);
            KEY[button_index] = 1'b1;

            wait_cycles(DEBOUNCE_COUNT + 8);
        end
    endtask

    task automatic press_reset;
        begin
            $display("TEST: RESET");

            press_button(0);

            check_pc(16'd0);
            check_result(16'h0000);

            assert (dut.halted == 1'b0)
            else $fatal(1, "FAIL: halted not cleared by reset");

            check_register(1, 16'h0000);
            check_register(2, 16'h0000);

            $display("PASS: reset");
        end
    endtask

    task automatic wait_for_pc(
        input logic [15:0] expected_pc,
        input integer max_cycles
    );
        integer count;
        begin
            count = 0;

            while (dut.pc != expected_pc && count < max_cycles) begin
                @(posedge clk);
                #1;
                count = count + 1;
            end

            assert (dut.pc == expected_pc)
            else $fatal(1,
                "FAIL: timeout waiting for PC=%0d, current PC=%0d",
                expected_pc, dut.pc);

            $display("PASS: reached PC=%0d", expected_pc);
        end
    endtask

    task automatic run_until_halt(input integer max_cycles);
        integer count;
        begin
            count = 0;

            while (!dut.halted && count < max_cycles) begin
                @(posedge clk);
                #1;
                count = count + 1;
            end

            assert (dut.halted)
            else $fatal(1,
                "FAIL: CPU did not halt, PC=%0d", dut.pc);

            check_pc(16'd29);
            $display("PASS: CPU halted");
        end
    endtask

    task automatic test_pause_resume;
        logic [15:0] saved_pc;

        begin
            $display("TEST: PAUSE AND RESUME");

            press_button(2);

            assert (dut.paused == 1'b1)
            else $fatal(1, "FAIL: pause button did not pause CPU");

            saved_pc = dut.pc;

            wait_cycles(5 * CLK_HZ);

            assert (dut.pc == saved_pc)
            else $fatal(1, "FAIL: PC changed while paused");

            $display("PASS: CPU paused at PC=%0d", saved_pc);

            press_button(1);

            assert (dut.paused == 1'b0)
            else $fatal(1, "FAIL: resume button did not resume CPU");

            $display("PASS: CPU resumed");
        end
    endtask

    task automatic test_display;
        logic [3:0] seen_digits;
        integer count;

        begin
            $display("TEST: DISPLAY MULTIPLEXING");

            seen_digits = 4'b0000;

            for (count = 0; count < 100; count = count + 1) begin
                @(posedge clk);
                #1;

                if (DS != 4'b0000) begin
                    assert ($onehot(DS))
                    else $fatal(1,
                        "FAIL: invalid digit selection DS=%b", DS);

                    seen_digits = seen_digits | DS;
                end
            end

            assert (seen_digits != 4'b0000)
            else $fatal(1, "FAIL: no display digit was enabled");

            assert (SEGMENTS[7] == 1'b0)
            else $fatal(1, "FAIL: decimal point output should be zero");

            $display("PASS: display multiplexing, active digits=%b",
                     seen_digits);
        end
    endtask

    initial begin
        KEY = 3'b110;

        #1;                 
        load_program();    

        $display("========================================");
        $display("STARTING CPU TOP TESTBENCH");
        $display("========================================");

        wait_cycles(20);
        KEY[0] = 1'b1;
        wait_cycles(10 + DEBOUNCE_COUNT + 8);

        test_pause_resume();

        $display("TEST: RESET BEFORE PROGRAM");
        press_reset();

        $display("TEST: RUN PROGRAM");

        run_until_halt(1000);

        check_register(1, 16'h0001); 
        check_register(2, 16'h0002);
        check_register(3, 16'h0000);
        check_register(4, 16'hFFFF);
        check_register(5, 16'hFFFE);
        check_register(6, 16'hFFFD);

        assert (dut.processor.rf.registers[2] != 16'd99)
        else $fatal(1, "FAIL: skipped instruction changed R2 to 99");

        assert (dut.halted == 1'b1)
        else $fatal(1, "FAIL: CPU is not halted");

        $display("PASS: final register checks");

        test_display();

        $display("========================================");
        $display("ALL TESTS PASSED");
        $display("========================================");

        $finish;
    end

    initial begin
        #1000000;
        $fatal(1, "FAIL: simulation timeout");
    end

endmodule