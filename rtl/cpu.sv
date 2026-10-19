
module cpu (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        step_enable,

    output logic [15:0] result,
    output logic        halted,
    output logic [15:0] pc_out
);

    logic [15:0] pc;
    logic [15:0] instruction;

    logic [15:0] program_memory [0:255];

    logic [3:0] opcode;
    logic [2:0] rd;
    logic [2:0] rs1;
    logic [2:0] rs2;

    logic [3:0] alu_op;
    logic       use_immediate;
    logic       reg_write;
    logic       halt;

    logic       jump;
    logic       jump_zero;
    logic       jump_not_zero;

    logic [15:0] reg_a;
    logic [15:0] reg_b;
    logic [15:0] alu_b;
    logic [15:0] alu_result;
    logic [15:0] writeback_data;
    logic [15:0] immediate_value;

    logic        take_branch;

    initial begin
        for (int i = 0; i < 256; i = i + 1)
            program_memory[i] = 16'hF000;

        $readmemh("../program.txt", program_memory);
    end

    always_comb begin
        if (pc < 16'd256)
            instruction = program_memory[pc[7:0]];
        else
            instruction = 16'hF000;
    end

    assign opcode = instruction[15:12];
    assign rd     = instruction[11:9];
    assign rs1    = instruction[8:6];
    assign rs2    = instruction[5:3];

    register_file rf (
        .clk           (clk),
        .rst_n         (rst_n),

        .read_addr_a   ((opcode == 4'hC || opcode == 4'hD)
                        ? rd : rs1),
        .read_addr_b   (rs2),
        .read_data_a   (reg_a),
        .read_data_b   (reg_b),

        .write_enable  (step_enable && !halted && reg_write),
        .write_addr    (rd),
        .write_data    (writeback_data)
    );

    assign immediate_value =
        {{7{instruction[8]}}, instruction[8:0]};

    control_unit control (
        .opcode        (opcode),
        .alu_op        (alu_op),
        .use_immediate (use_immediate),
        .reg_write     (reg_write),
        .halt          (halt),
        .jump           (jump),
        .jump_zero      (jump_zero),
        .jump_not_zero  (jump_not_zero)
    );

    assign alu_b = use_immediate
                 ? immediate_value
                 : reg_b;

    alu alu_unit (
        .a      (reg_a),
        .b      (alu_b),
        .alu_op (alu_op),
        .result (alu_result)
    );

    assign writeback_data = use_immediate
                          ? immediate_value
                          : alu_result;

    always_comb begin
        take_branch = 1'b0;

        if (jump)
            take_branch = 1'b1;
        else if (jump_zero && reg_a == 16'h0000)
            take_branch = 1'b1;
        else if (jump_not_zero && reg_a != 16'h0000)
            take_branch = 1'b1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc     <= 16'd0;
            halted <= 1'b0;
        end
        else if (step_enable && !halted) begin
            if (halt) begin
                halted <= 1'b1;
            end
            else if (take_branch) begin
                pc <= {8'd0, instruction[7:0]};
            end
            else begin
                pc <= pc + 16'd1;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 16'h0000;
        end
        else if (step_enable && !halted && reg_write && rd != 3'd0) begin
            result <= writeback_data;
        end
    end

    assign pc_out = pc;

endmodule
