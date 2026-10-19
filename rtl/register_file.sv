module register_file (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [2:0]  read_addr_a,
    input  logic [2:0]  read_addr_b,
    output logic [15:0] read_data_a,
    output logic [15:0] read_data_b,

    input  logic        write_enable,
    input  logic [2:0]  write_addr,
    input  logic [15:0] write_data
);

    logic [15:0] registers [0:7];
    integer i;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 8; i = i + 1)
                registers[i] <= 16'h0000;
        end
        else if (write_enable && write_addr != 3'd0) begin
            registers[write_addr] <= write_data;
        end
    end

    always_comb begin
        if (read_addr_a == 3'd0)
            read_data_a = 16'h0000;
        else
            read_data_a = registers[read_addr_a];

        if (read_addr_b == 3'd0)
            read_data_b = 16'h0000;
        else
            read_data_b = registers[read_addr_b];
    end

endmodule