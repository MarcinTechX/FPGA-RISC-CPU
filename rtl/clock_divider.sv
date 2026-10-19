module clock_divider #(
    parameter integer CLK_HZ = 10_000_000
) (
    input  logic clk,
    input  logic rst_n,
    output logic tick
);

    logic [31:0] counter;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 32'd0;
            tick    <= 1'b0;
        end
        else if (counter == CLK_HZ - 1) begin
            counter <= 32'd0;
            tick    <= 1'b1;
        end
        else begin
            counter <= counter + 32'd1;
            tick    <= 1'b0;
        end
    end

endmodule