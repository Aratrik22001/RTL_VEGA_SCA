`timescale 1ns / 1ps

module attack_fsm_fuzzy_tb;

    // Inputs
    reg clk;
    reg rst;
    reg [9:0] energy;
    reg [9:0] peak_power;
    reg [9:0] mean_power;
    reg [7:0] hamming_dist;

    // Output
    wire attack_detected;

    // Instantiate the DUT
    fuzzy_attack_fsm uut (
        .clk(clk),
        .rst(rst),
        .energy(energy),
        .peak_power(peak_power),
        .mean_power(mean_power),
        .hamming_dist(hamming_dist),
        .attack_detected(attack_detected)
    );

    // Clock generation: 100MHz
    always #5 clk = ~clk;

    initial begin
        // Initialization
        clk = 0;
        rst = 1;
        energy = 0;
        peak_power = 0;
        mean_power = 0;
        hamming_dist = 0;

        #20;
        rst = 0;

        // -----------------------------------------------------------------------------
        // Test Vector 1: Normal
        // Original : 3.0394, 0.0757, 0.0535, 0
        // Q3.7 encoded: (3.0394 * 128 ≈ 389), (0.0757 * 128 ≈ 10), (0.0535 * 128 ≈ 7)
        // -----------------------------------------------------------------------------
        #10;
        energy       = 10'd389;
        peak_power   = 10'd10;
        mean_power   = 10'd7;
        hamming_dist = 8'd0;

        #100;
        
        // -----------------------------------------------------------------------------
        // Test Vector 2: Attack
        // Original : 3.4480, 0.1601, 0.0546, 7
        // Q3.7 encoded: (3.4480 * 128 ≈ 441), (0.1601 * 128 ≈ 20), (0.0546 * 128 ≈ 7)
        // -----------------------------------------------------------------------------
        
        #10;
        energy       = 10'd441;
        peak_power   = 10'd20;
        mean_power   = 10'd7;
        hamming_dist = 8'd7;

        #100;
        
        // -----------------------------------------------------------------------------
        // Test Vector 3: Normal
        // Original : 2.8753, 0.0758, 0.0521, 0
        // Q3.7 encoded: (2.8753 * 128 ≈ 368), (0.0758 * 128 ≈ 10), (0.0521 * 128 ≈ 7)
        // -----------------------------------------------------------------------------
        
        #10;
        energy       = 10'd368;
        peak_power   = 10'd10;
        mean_power   = 10'd7;
        hamming_dist = 8'd0;

        #100;
        
        // -----------------------------------------------------------------------------
        // Test Vector 4: Attack
        // Original : 3.6181, 0.1659, 0.0557, 4
        // Q3.7 encoded: (3.6181 * 128 ≈ 463), (0.1659 * 128 ≈ 21), (0.0557 * 128 ≈ 7)
        // -----------------------------------------------------------------------------
        
        #10;
        energy       = 10'd463;
        peak_power   = 10'd21;
        mean_power   = 10'd7;
        hamming_dist = 8'd4;

        #100;
        
        // -----------------------------------------------------------------------------
        // Test Vector 5: Attack
        // Original : 4.16906, 0.1684, 0.0599, 12
        // Q3.7 encoded: (4.16906 * 128 ≈ 534), (0.1684 * 128 ≈ 22), (0.0599 * 128 ≈ 8)
        // -----------------------------------------------------------------------------
        
        #10;
        energy       = 10'd534;
        peak_power   = 10'd22;
        mean_power   = 10'd8;
        hamming_dist = 8'd12;

        #150;
        $finish;
    end
endmodule
