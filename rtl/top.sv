
module top (
    input  logic        CLOCK_10,
    input  logic        KEY,
    output logic [7:0]  SEGMENTS,
    output logic [3:0]  DS
);

    logic rst_n;
    logic tick;

    logic [15:0] cpu_result;
    logic [15:0] pc;
    logic halted;

    assign rst_n = KEY;

    clock_divider #(
        .CLK_HZ(10_000_000)
    ) divider (
        .clk   (CLOCK_10),
        .rst_n (rst_n),
        .tick  (tick)
    );

    cpu processor (
        .clk         (CLOCK_10),
        .rst_n       (rst_n),
        .step_enable (tick),
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

    logic [13:0] clk_counter;
    logic [1:0]  active_digit;

    always_ff @(posedge CLOCK_10 or negedge rst_n) begin
        if (!rst_n) begin
            clk_counter  <= 14'd0;
            active_digit <= 2'd0;
        end else begin
            if (clk_counter >= 14'd10000) begin
                clk_counter  <= 14'd0;
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
