
module control_unit (
    input  logic [3:0] opcode,

    output logic [3:0] alu_op,
    output logic       use_immediate,
    output logic       reg_write,
    output logic       halt,

    output logic       jump,
    output logic       jump_zero,
    output logic       jump_not_zero
);

    always_comb begin
        alu_op        = 4'b0000;
        use_immediate = 1'b0;
        reg_write     = 1'b0;
        halt          = 1'b0;

        jump          = 1'b0;
        jump_zero     = 1'b0;
        jump_not_zero = 1'b0;

        case (opcode)
            4'h0: begin
                alu_op    = 4'b0000;
                reg_write = 1'b1;
            end

            4'h1: begin
                alu_op    = 4'b0001;
                reg_write = 1'b1;
            end

            4'h2: begin
                alu_op    = 4'b0010;
                reg_write = 1'b1;
            end

            4'h3: begin
                alu_op    = 4'b0011;
                reg_write = 1'b1;
            end

            4'h4: begin
                use_immediate = 1'b1;
                reg_write     = 1'b1;
            end

            4'h5: begin
                alu_op    = 4'b0100;
                reg_write = 1'b1;
            end

            4'h6: begin
                alu_op    = 4'b0101;
                reg_write = 1'b1;
            end

            4'h7: begin
                alu_op    = 4'b0110;
                reg_write = 1'b1;
            end

            4'h8: begin
                alu_op    = 4'b0111;
                reg_write = 1'b1;
            end

            4'h9: begin
                alu_op    = 4'b1000;
                reg_write = 1'b1;
            end

            4'hA: begin
                alu_op    = 4'b1001;
                reg_write = 1'b1;
            end

            4'hB: begin
                jump = 1'b1;          
            end

            4'hC: begin
                jump_zero = 1'b1;     
            end

            4'hD: begin
                jump_not_zero = 1'b1;
            end

            4'hF: begin
                halt = 1'b1;
            end

            default: begin
            end
        endcase
    end

endmodule
