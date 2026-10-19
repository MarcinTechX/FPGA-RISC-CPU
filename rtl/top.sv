module top #(
    parameter integer CLK_HZ = 10_000_000,
    parameter integer DISPLAY_REFRESH_COUNT = 10_000,
    parameter integer DEBOUNCE_COUNT = 200_000
) (
    input  logic        clk,
    input  logic [2:0]  KEY,
    output logic [7:0]  SEGMENTS,
    output logic [3:0]  DS
);

    logic raw_rst_btn;
    logic raw_resume_btn;
    logic raw_pause_btn;

    logic debounced_rst_n;
    logic debounced_resume_btn;
    logic debounced_pause_btn;

    logic tick;
    logic paused;

    logic [15:0] cpu_result;
    logic [15:0] pc;
    logic halted;

    assign raw_rst_btn    = KEY[0];
    assign raw_resume_btn = KEY[1];
    assign raw_pause_btn  = KEY[2];

    button_debouncer #(
        .DEBOUNCE_COUNT(DEBOUNCE_COUNT)
    ) rst_debouncer_inst (
        .clk        (clk),
        .rst_n      (1'b1),
        .button_in  (raw_rst_btn),
        .button_out (debounced_rst_n)
    );

    button_debouncer #(
        .DEBOUNCE_COUNT(DEBOUNCE_COUNT)
    ) resume_debouncer_inst (
        .clk        (clk),
        .rst_n      (debounced_rst_n),
        .button_in  (raw_resume_btn),
        .button_out (debounced_resume_btn)
    );

    button_debouncer #(
        .DEBOUNCE_COUNT(DEBOUNCE_COUNT)
    ) pause_debouncer_inst (
        .clk        (clk),
        .rst_n      (debounced_rst_n),
        .button_in  (raw_pause_btn),
        .button_out (debounced_pause_btn)
    );

    logic resume_btn_prev;
    logic pause_btn_prev;

    always_ff @(posedge clk or negedge debounced_rst_n) begin
        if (!debounced_rst_n) begin
            resume_btn_prev <= 1'b1;
            pause_btn_prev  <= 1'b1;
            paused          <= 1'b0;
        end else begin
            resume_btn_prev <= debounced_resume_btn;
            pause_btn_prev  <= debounced_pause_btn;

            if (resume_btn_prev && !debounced_resume_btn) begin
                paused <= 1'b0;
            end else if (pause_btn_prev && !debounced_pause_btn) begin
                paused <= 1'b1;
            end
        end
    end

    clock_divider #(
        .CLK_HZ(CLK_HZ)
    ) divider (
        .clk   (clk),
        .rst_n (debounced_rst_n),
        .tick  (tick)
    );

    logic cpu_step_enable;

    assign cpu_step_enable = tick && !paused;

    cpu processor (
        .clk         (clk),
        .rst_n       (debounced_rst_n),
        .step_enable (cpu_step_enable),
        .result      (cpu_result),
        .halted      (halted),
        .pc_out      (pc)
    );

    logic [6:0] hex0_pattern;
    logic [6:0] hex1_pattern;
    logic [6:0] hex2_pattern;
    logic [6:0] hex3_pattern;

    function automatic logic [6:0] hex_to_7seg(
        input logic [3:0] value
    );
        begin
            case (value)
                4'h0: hex_to_7seg = 7'b0111111;
                4'h1: hex_to_7seg = 7'b0000110;
                4'h2: hex_to_7seg = 7'b1011011;
                4'h3: hex_to_7seg = 7'b1001111;
                4'h4: hex_to_7seg = 7'b1100110;
                4'h5: hex_to_7seg = 7'b1101101;
                4'h6: hex_to_7seg = 7'b1111101;
                4'h7: hex_to_7seg = 7'b0000111;
                4'h8: hex_to_7seg = 7'b1111111;
                4'h9: hex_to_7seg = 7'b1101111;
                4'hA: hex_to_7seg = 7'b1110111;
                4'hB: hex_to_7seg = 7'b1111100;
                4'hC: hex_to_7seg = 7'b0111001;
                4'hD: hex_to_7seg = 7'b1011110;
                4'hE: hex_to_7seg = 7'b1111001;
                4'hF: hex_to_7seg = 7'b1110001;
                default: hex_to_7seg = 7'b0000000;
            endcase
        end
    endfunction

    always_comb begin
        hex0_pattern = hex_to_7seg(cpu_result[3:0]);
        hex1_pattern = hex_to_7seg(cpu_result[7:4]);
        hex2_pattern = hex_to_7seg(cpu_result[11:8]);
        hex3_pattern = hex_to_7seg(cpu_result[15:12]);
    end

    logic show_hex3;
    logic show_hex2;
    logic show_hex1;

    assign show_hex3 = (cpu_result[15:12] != 4'h0);
    assign show_hex2 = show_hex3 || (cpu_result[11:8] != 4'h0);
    assign show_hex1 = show_hex2 || (cpu_result[7:4] != 4'h0);

    logic [31:0] clk_counter;
    logic [1:0] active_digit;

    always_ff @(posedge clk or negedge debounced_rst_n) begin
        if (!debounced_rst_n) begin
            clk_counter  <= 32'd0;
            active_digit <= 2'd0;
        end else begin
            if (clk_counter >= DISPLAY_REFRESH_COUNT - 1) begin
                clk_counter  <= 32'd0;
                active_digit <= active_digit + 1'b1;
            end else begin
                clk_counter <= clk_counter + 1'b1;
            end
        end
    end

    always_comb begin
        DS       = 4'b0000;
        SEGMENTS = 8'b00000000;

        case (active_digit)
            2'b00: begin
                if (show_hex3) begin
                    DS       = 4'b1000;
                    SEGMENTS = {1'b0, hex3_pattern};
                end
            end

            2'b01: begin
                if (show_hex2) begin
                    DS       = 4'b0100;
                    SEGMENTS = {1'b0, hex2_pattern};
                end
            end

            2'b10: begin
                if (show_hex1) begin
                    DS       = 4'b0010;
                    SEGMENTS = {1'b0, hex1_pattern};
                end
            end

            2'b11: begin
                DS       = 4'b0001;
                SEGMENTS = {1'b0, hex0_pattern};
            end

            default: begin
                DS       = 4'b0000;
                SEGMENTS = 8'b00000000;
            end
        endcase

        SEGMENTS[7] = 1'b0;
    end

endmodule