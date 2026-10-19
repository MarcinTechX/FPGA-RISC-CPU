module button_debouncer #(
    parameter integer DEBOUNCE_COUNT = 200_000
) (
    input  logic clk,
    input  logic rst_n,
    input  logic button_in,
    output logic button_out
);

    logic sync_0          = 1'b1;
    logic sync_1          = 1'b1;
    logic debounced_state = 1'b1;

    localparam integer COUNTER_WIDTH =
        (DEBOUNCE_COUNT > 1) ? $clog2(DEBOUNCE_COUNT + 1) : 1;

    logic [COUNTER_WIDTH-1:0] counter = '0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_0 <= 1'b1;
            sync_1 <= 1'b1;
        end else begin
            sync_0 <= button_in;
            sync_1 <= sync_0;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter         <= '0;
            debounced_state <= 1'b1;
        end else begin
            if (sync_1 != debounced_state) begin
                if (counter >= DEBOUNCE_COUNT - 1) begin
                    debounced_state <= sync_1;
                    counter         <= '0;
                end else begin
                    counter <= counter + 1'b1;
                end
            end else begin
                counter <= '0;
            end
        end
    end

    assign button_out = debounced_state;

endmodule