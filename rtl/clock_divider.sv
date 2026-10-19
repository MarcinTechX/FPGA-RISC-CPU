module clock_divider #(
    parameter integer CLK_HZ = 10_000_000
) (
    input  logic clk,
    input  logic rst_n,
    output logic tick
);

    localparam integer COUNTER_WIDTH =
        (CLK_HZ > 1) ? $clog2(CLK_HZ) : 1;

    logic [COUNTER_WIDTH-1:0] counter = '0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= '0;
            tick    <= 1'b0;
        end else begin
            if (counter >= CLK_HZ - 1) begin
                counter <= '0;
                tick    <= 1'b1;   
            end else begin
                counter <= counter + 1'b1;
                tick    <= 1'b0;
            end
        end
    end

endmodule