module SET(clk, rst, en, central, radius, mode, busy, valid, candidate);
input clk;
input rst;
input en;
input [23:0] central;
input [11:0] radius;
input [1:0] mode;
output busy;
output valid;
output [7:0] candidate;

parameter STATE_INPUT = 2'd0;
parameter STATE_CAL = 2'd1;
parameter STATE_OUTPUT = 2'd2;
parameter STATE_IDEL = 2'd3;

reg busy, valid;
reg [7:0] candidate;

reg [1:0] state, next_state;
reg [3:0] x_side, y_side;

reg [23:0] central_reg;
reg [11:0] radius_reg;
reg [1:0] mode_reg;

reg [3:0] x_side_a, x_side_b, x_side_c;
reg [3:0] y_side_a, y_side_b, y_side_c;
reg [8:0] circle_a, circle_b, circle_c;
reg [7:0] radius_a, radius_b, radius_c;

reg cal_valid;

// FSM

always @(posedge clk or posedge rst) begin
	if(rst)
		state <= STATE_INPUT;
	else
		state <= next_state;
end 

always @(*) begin
	case(state)
		STATE_INPUT: begin
			if(en)
				next_state = STATE_CAL;
			else
				next_state = STATE_INPUT;
		end
		STATE_CAL: begin
			if(x_side == 4'd8 && y_side == 4'd8)
				next_state = STATE_OUTPUT;
			else
				next_state = STATE_CAL;
		end
		STATE_OUTPUT: begin
			next_state = STATE_INPUT;
		end
		STATE_IDEL: begin
			next_state = STATE_IDEL;
		end
		default: next_state = STATE_IDEL;
	endcase
end

always @(*) begin
	if(central_reg[23:20] >= x_side)
		x_side_a = central_reg[23:20] - x_side;
	else
		x_side_a = x_side - central_reg[23:20];

	if(central_reg[19:16] >= y_side)
		y_side_a = central_reg[19:16] - y_side;
	else
		y_side_a = y_side - central_reg[19:16];

	if(central_reg[15:12] >= x_side)
		x_side_b = central_reg[15:12] - x_side;
	else
		x_side_b = x_side - central_reg[15:12];

	if(central_reg[11:8] >= y_side)
		y_side_b = central_reg[11:8] - y_side;
	else
		y_side_b = y_side - central_reg[11:8];

	if(central_reg[7:4] >= x_side)
		x_side_c = central_reg[7:4] - x_side;
	else
		x_side_c = x_side - central_reg[7:4];

	if(central_reg[3:0] >= y_side)
		y_side_c = central_reg[3:0] - y_side;
	else
		y_side_c = y_side - central_reg[3:0];
end

always @(*) begin
	circle_a = (x_side_a * x_side_a) + (y_side_a * y_side_a);
	circle_b = (x_side_b * x_side_b) + (y_side_b * y_side_b);
	circle_c = (x_side_c * x_side_c) + (y_side_c * y_side_c);

	radius_a = radius_reg[11:8] * radius_reg[11:8];
	radius_b = radius_reg[7:4] * radius_reg[7:4];
	radius_c = radius_reg[3:0] * radius_reg[3:0];
end

always @(*) begin
	case(mode_reg)
		2'd0: begin
			if((circle_a <= radius_a) == 1'b1)
				cal_valid = 1'b1;
			else
				cal_valid = 1'b0;
		end
		2'd1: begin
			if(((circle_a <= radius_a) & (circle_b <= radius_b)) == 1'b1)
				cal_valid = 1'b1;
			else
				cal_valid = 1'b0;
		end
		2'd2: begin
			if(((circle_a <= radius_a) ^ (circle_b <= radius_b)) == 1'b1)
				cal_valid = 1'b1;
			else
				cal_valid = 1'b0;
		end
		2'd3: begin
			if((~((circle_a <= radius_a) ^ (circle_b <= radius_b) ^ (circle_c <= radius_c))) & ((circle_a <= radius_a) | (circle_b <= radius_b) | (circle_c <= radius_c)) == 1'b1)
				cal_valid = 1'b1;
			else
			 	cal_valid = 1'b0;
		end
		default: cal_valid = 1'b0;
	endcase
end 

always @(posedge clk or posedge rst) begin
	if(rst) begin
		busy <= 1'b0;
		valid <= 1'b0;
		candidate <= 8'd0;
		x_side <= 4'd1;
		y_side <= 4'd1;
	end
	else begin
		case(state)
			STATE_INPUT: begin
				if(en) begin
					central_reg <= central;
					radius_reg <= radius;
					mode_reg <= mode;
					busy <= 1'b0;
					candidate <= 8'd0;
				end
				else begin
					busy <= 1'b0;
					valid <= 1'b0;
				end
			end
			STATE_CAL: begin
				if(x_side == 4'd8 && y_side == 4'd8) begin
					x_side <= 4'd1;
					y_side <= 4'd1;
				end
				else begin
					if(x_side == 4'd8) begin
						y_side <= y_side + 4'd1;
						x_side <= 4'd1;
					end
					else begin
						x_side <= x_side + 4'd1;
					end
				end
				if(cal_valid)
					candidate <= candidate + 8'd1;
			end
			STATE_OUTPUT: begin
				valid <= 1'b1;
			end
		endcase
	end
end

endmodule
