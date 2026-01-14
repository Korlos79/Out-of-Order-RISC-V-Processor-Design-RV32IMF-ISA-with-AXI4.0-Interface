module hazard_unit (
    input regWrite_M,
    input regFWrite_M,
    input regWrite_W,
    input regFWrite_W,
    input PCSrc_E,
    input resultSrc_E,
    input [4:0] rd_M,
    input [4:0] rd_W,
    input [4:0] rs1_D,
    input [4:0] rs2_D,
    input [4:0] rs3_D,
    input [4:0] rs1_E,
    input [4:0] rs2_E,
    input [4:0] rs3_E,
    input [4:0] rd_E,
    input busyA,
    input doneA, // Done thường không dùng để stall, nhưng có thể dùng để flush nếu cần
	 input busyF,
	 input doneF,
    
    output reg [1:0] forwardAE,
    output reg [1:0] forwardBE,
    output reg [1:0] forwardAFE,
    output reg [1:0] forwardBFE,
    output reg [1:0] forwardCFE,
    output stall,
    output flush
);

    // Forwarding logic cho AE (ALU Source A)
    always @(*) begin
        if (regWrite_M && (rd_M != 0) && (rd_M == rs1_E)) begin
            forwardAE = 2'b10; // Forward từ Memory Stage
        end
        else if (regWrite_W && (rd_W != 0) && (rd_W == rs1_E)) begin // Đã sửa rd_M -> rd_W
            forwardAE = 2'b01; // Forward từ Writeback Stage
        end
        else forwardAE = 2'b00;
    end

    // Forwarding logic cho BE (ALU Source B)
    always @(*) begin
        if (regWrite_M && (rd_M != 0) && (rd_M == rs2_E)) begin
            forwardBE = 2'b10;
        end
        else if (regWrite_W && (rd_W != 0) && (rd_W == rs2_E)) begin // Đã sửa rd_M -> rd_W
            forwardBE = 2'b01;
        end
        else forwardBE = 2'b00;
    end

    // Forwarding logic cho AFE (FPU Source A)
    always @(*) begin
        if (regFWrite_M && (rd_M != 0) && (rd_M == rs1_E)) begin
            forwardAFE = 2'b10;
        end
        else if (regFWrite_W && (rd_W != 0) && (rd_W == rs1_E)) begin // Đã sửa rd_M -> rd_W
            forwardAFE = 2'b01;
        end
        else forwardAFE = 2'b00;
    end

    // Forwarding logic cho BFE (FPU Source B)
    always @(*) begin
        if (regFWrite_M && (rd_M != 0) && (rd_M == rs2_E)) begin
            forwardBFE = 2'b10;
        end
        else if (regFWrite_W && (rd_W != 0) && (rd_W == rs2_E)) begin // Đã sửa rd_M -> rd_W
            forwardBFE = 2'b01;
        end
        else forwardBFE = 2'b00;
    end

    // Forwarding logic cho CFE (FPU Source C - cho lệnh FMA)
    always @(*) begin
        if (regFWrite_M && (rd_M != 0) && (rd_M == rs3_E)) begin
            forwardCFE = 2'b10;
        end
        else if (regFWrite_W && (rd_W != 0) && (rd_W == rs3_E)) begin // Đã sửa rd_M -> rd_W
            forwardCFE = 2'b01;
        end
        else forwardCFE = 2'b00;
    end

    // --- STALL LOGIC ---
    // 1. Load Hazard: Lệnh ở EX là Load (ResultSrc=1), lệnh ở ID cần dùng kết quả đó -> Stall
    wire lwStall = (resultSrc_E == 1'b1) && ((rs1_D == rd_E) || (rs2_D == rd_E) || (rs3_D == rd_E));
    
    // 2. Functional Unit Busy: Nếu bộ Nhân/Chia/AXI đang bận -> Stall pipeline phía trước
    // Lưu ý: KHÔNG stall khi done=1. Khi done=1 nghĩa là đã xong, cần thả stall để pipeline chạy tiếp.
    assign stall = lwStall || busyA || busyF;

    // --- FLUSH LOGIC ---
    // Flush khi nhánh dự đoán sai hoặc nhảy
    assign flush = PCSrc_E;

endmodule