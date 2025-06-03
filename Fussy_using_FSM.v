`timescale 1ns / 1ps

// Triangular Membership Function Module 
module triangular_mf #(
    parameter WIDTH = 10
)(
    input  [WIDTH-1:0] x,
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input  [WIDTH-1:0] c,
    output reg [10:0] y
);
    wire signed [WIDTH:0] sx = $signed(x);
    wire signed [WIDTH:0] sa = $signed(a);
    wire signed [WIDTH:0] sb = $signed(b);
    wire signed [WIDTH:0] sc = $signed(c);

    wire signed [WIDTH:0] num1 = sx - sa;
    wire signed [WIDTH:0] den1 = sb - sa;
    wire signed [WIDTH:0] num2 = sc - sx;
    wire signed [WIDTH:0] den2 = sc - sb;

    wire signed [2*WIDTH-1:0] div1 = (den1 != 0) ? (num1 <<< 7) / den1 : 0;
    wire signed [2*WIDTH-1:0] div2 = (den2 != 0) ? (num2 <<< 7) / den2 : 0;

    always @(*) begin
        if (sx <= sa || sx >= sc)
            y = 11'd0;
        else if (sx <= sb)
            y = (div1 < 0) ? 11'd0 : div1[10:0];
        else
            y = (div2 < 0) ? 11'd0 : div2[10:0];
    end
endmodule

// Fuzzifier Module (Q3.7)
module fuzzifier (
    input [9:0] energy,
    input [9:0] peak_power,
    input [9:0] mean_power,
    input [7:0] hamming_dist,
    output [10:0] energy_low_deg, energy_med_deg, energy_high_deg,
    output [10:0] peak_low_deg, peak_med_deg, peak_high_deg,
    output [10:0] mean_low_deg, mean_med_deg, mean_high_deg,
    output [10:0] ham_low_deg, ham_med_deg, ham_high_deg
);
    //Corner Values of TMFs to be stored in memory
    localparam [9:0] ENERGY_A_L = 10'd0,    ENERGY_B_L = 10'd294, ENERGY_C_L = 10'd358;
    localparam [9:0] ENERGY_A_M = 10'd345,  ENERGY_B_M = 10'd429, ENERGY_C_M = 10'd512;
    localparam [9:0] ENERGY_A_H = 10'd486,  ENERGY_B_H = 10'd576, ENERGY_C_H = 10'd768;

    localparam [9:0] PEAK_A_L = 10'd0,      PEAK_B_L = 10'd8,     PEAK_C_L = 10'd14;
    localparam [9:0] PEAK_A_M = 10'd12,     PEAK_B_M = 10'd16,    PEAK_C_M = 10'd20;
    localparam [9:0] PEAK_A_H = 10'd19,     PEAK_B_H = 10'd23,    PEAK_C_H = 10'd25;

    localparam [9:0] MEAN_A_L = 10'd0,      MEAN_B_L = 10'd6,     MEAN_C_L = 10'd6;
    localparam [9:0] MEAN_A_M = 10'd6,      MEAN_B_M = 10'd7,     MEAN_C_M = 10'd7;
    localparam [9:0] MEAN_A_H = 10'd7,      MEAN_B_H = 10'd7,     MEAN_C_H = 10'd8;

    localparam [7:0] HAM_A_L = 8'd0, HAM_B_L = 8'd1, HAM_C_L = 8'd1;
    localparam [7:0] HAM_A_M = 8'd2, HAM_B_M = 8'd3, HAM_C_M = 8'd3;
    localparam [7:0] HAM_A_H = 8'd3, HAM_B_H = 8'd4, HAM_C_H = 8'd15;

    triangular_mf #(10) energy_low (.x(energy), .a(ENERGY_A_L), .b(ENERGY_B_L), .c(ENERGY_C_L), .y(energy_low_deg));
    triangular_mf #(10) energy_med (.x(energy), .a(ENERGY_A_M), .b(ENERGY_B_M), .c(ENERGY_C_M), .y(energy_med_deg));
    triangular_mf #(10) energy_high(.x(energy), .a(ENERGY_A_H), .b(ENERGY_B_H), .c(ENERGY_C_H), .y(energy_high_deg));

    triangular_mf #(10) peak_low (.x(peak_power), .a(PEAK_A_L), .b(PEAK_B_L), .c(PEAK_C_L), .y(peak_low_deg));
    triangular_mf #(10) peak_med (.x(peak_power), .a(PEAK_A_M), .b(PEAK_B_M), .c(PEAK_C_M), .y(peak_med_deg));
    triangular_mf #(10) peak_high(.x(peak_power), .a(PEAK_A_H), .b(PEAK_B_H), .c(PEAK_C_H), .y(peak_high_deg));

    triangular_mf #(10) mean_low (.x(mean_power), .a(MEAN_A_L), .b(MEAN_B_L), .c(MEAN_C_L), .y(mean_low_deg));
    triangular_mf #(10) mean_med (.x(mean_power), .a(MEAN_A_M), .b(MEAN_B_M), .c(MEAN_C_M), .y(mean_med_deg));
    triangular_mf #(10) mean_high(.x(mean_power), .a(MEAN_A_H), .b(MEAN_B_H), .c(MEAN_C_H), .y(mean_high_deg));

    triangular_mf #(8) ham_low (.x(hamming_dist), .a(HAM_A_L), .b(HAM_B_L), .c(HAM_C_L), .y(ham_low_deg));
    triangular_mf #(8) ham_med (.x(hamming_dist), .a(HAM_A_M), .b(HAM_B_M), .c(HAM_C_M), .y(ham_med_deg));
    triangular_mf #(8) ham_high(.x(hamming_dist), .a(HAM_A_H), .b(HAM_B_H), .c(HAM_C_H), .y(ham_high_deg));
endmodule

// FSM Using Fuzzy Logic
module fuzzy_attack_fsm (
    input clk,
    input rst,
    input [9:0] energy, peak_power, mean_power,
    input [7:0]  hamming_dist,
    output reg attack_detected
);
    wire [10:0] energy_low_deg, energy_med_deg, energy_high_deg;
    wire [10:0] peak_low_deg, peak_med_deg, peak_high_deg;
    wire [10:0] mean_low_deg, mean_med_deg, mean_high_deg;
    wire [10:0] ham_low_deg, ham_med_deg, ham_high_deg;

    localparam [10:0] DEGREE_THRESH = 11'd8;

    fuzzifier fuzz_inst (
        .energy(energy), .peak_power(peak_power), .mean_power(mean_power), .hamming_dist(hamming_dist),
        .energy_low_deg(energy_low_deg), .energy_med_deg(energy_med_deg), .energy_high_deg(energy_high_deg),
        .peak_low_deg(peak_low_deg), .peak_med_deg(peak_med_deg), .peak_high_deg(peak_high_deg),
        .mean_low_deg(mean_low_deg), .mean_med_deg(mean_med_deg), .mean_high_deg(mean_high_deg),
        .ham_low_deg(ham_low_deg), .ham_med_deg(ham_med_deg), .ham_high_deg(ham_high_deg)
    );

    parameter S_START = 3'd0, S_HAMMING = 3'd1, S_ENERGY = 3'd2, S_PEAK = 3'd3, S_MEAN = 3'd4, S_ATTACK = 3'd5, S_NORMAL = 3'd6;
    reg [2:0] state, next_state;

    always @(posedge clk or posedge rst) begin
        if (rst) state <= S_START;
        else state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            S_START: next_state = S_HAMMING;
            S_HAMMING:
                next_state = (ham_high_deg > DEGREE_THRESH && ham_high_deg >= ham_med_deg && ham_high_deg >= ham_low_deg) ? S_ATTACK :
                             (ham_low_deg > DEGREE_THRESH && ham_low_deg >= ham_med_deg && ham_low_deg >= ham_high_deg) ? S_NORMAL : S_ENERGY;
            S_ENERGY:
                next_state = (energy_high_deg > DEGREE_THRESH && energy_high_deg >= energy_med_deg && energy_high_deg >= energy_low_deg) ? S_ATTACK :
                             (energy_low_deg > DEGREE_THRESH && energy_low_deg >= energy_med_deg && energy_low_deg >= energy_high_deg) ? S_NORMAL : S_PEAK;
            S_PEAK:
                next_state = (peak_high_deg > DEGREE_THRESH && peak_high_deg >= peak_med_deg && peak_high_deg >= peak_low_deg) ? S_ATTACK :
                             (peak_low_deg > DEGREE_THRESH && peak_low_deg >= peak_med_deg && peak_low_deg >= peak_high_deg) ? S_NORMAL : S_MEAN;
            S_MEAN:
                next_state = (mean_high_deg > DEGREE_THRESH && mean_high_deg >= mean_med_deg && mean_high_deg >= mean_low_deg) ? S_ATTACK : S_NORMAL;
            S_ATTACK, S_NORMAL: next_state = S_START;
            default: next_state = S_START;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) attack_detected <= 0;
        else if (state == S_NORMAL) attack_detected <= 0;
        else if (state == S_ATTACK) attack_detected <= 1;
        else if (state == S_START) attack_detected <= 0;
    end
endmodule
