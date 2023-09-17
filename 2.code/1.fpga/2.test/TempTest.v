module TempTest (
  input clk,
  input rst,
  inout singer_bus,
  output [39:0] dataout,
  output reg tick_done,
  output reg tx_data, // UART Transmit Data
  output reg tx_ready // UART Transmit Ready
);

  parameter CLK_PERIOD_NS = 83; // 12MHz
  parameter N = 40;

  reg DELAY_1_MS = (1000000 / CLK_PERIOD_NS) + 1;
  reg DELAY_40_US = (40000 / CLK_PERIOD_NS) + 1;
  reg DELAY_80_US = (80000 / CLK_PERIOD_NS) + 1;
  reg DELAY_50_US = (50000 / CLK_PERIOD_NS) + 1;
  reg TIME_70_US = (80000 / CLK_PERIOD_NS) + 1; // bit > 70 us
  reg TIME_28_US = (30000 / CLK_PERIOD_NS) + 1; // bit 0 > 28 us
  reg MAX_DELAY = (5000000 / CLK_PERIOD_NS) + 1; // 5 ms

  reg [2:0] state, next_state;
  reg [31:0] index, next_index;
  reg [39:0] data_out, next_data_out;
  reg [5:0]bit_in, next_bit_in;
  reg [5:0] number_bit, next_number_bit;
  reg oe;

  assign dataout = data_out;

  // Register
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= 0;
      index <= MAX_DELAY;
      number_bit <= 0;
      bit_in <= 1'b1;
      data_out <= 40'b0;
    end else begin
      state <= next_state;
      index <= next_index;
      number_bit <= next_number_bit;
      bit_in <= next_bit_in;
      data_out <= next_data_out;
    end
  end
  
    // UART Transmit Registers
  reg [7:0] tx_data_reg;  // Data to be transmitted
  reg [2:0] tx_state;     // UART Transmit State Machine
  reg [3:0] tx_counter;   // UART Transmit Counter

  // Initialize UART Transmit Registers
  initial begin
    tx_data_reg = 8'b0;
    tx_state = 3'b000;
    tx_counter = 4'b0000;
  end
	
  // State machine process
  always @(posedge clk) begin
    tick_done <= 1'b0;
    next_data_out = data_out;
    next_number_bit = number_bit;
    next_state = state;
    next_data_out = data_out;
    next_index = index;
    oe = 1'b0;
    next_bit_in = bit_in;

    case(state)
      0: begin // reset
        if (index == 0) begin
          next_state = 1;
          next_index = DELAY_1_MS;
          next_number_bit = N-1;
        end else begin
          next_state = 0;
          next_index = index - 1;
        end
      end

      1: begin // start_m
        if (index == 0) begin
          next_state = 2;
          next_index = DELAY_40_US;
        end else begin
          oe = 1'b1;
          next_state = 1;
          next_index = index - 1;
        end
      end

      // Other state cases
      2: begin // wait_res_sl
        if (bit_in == 1'b1 && next_bit_in == 1'b0) begin
          next_state = 3;
        end else begin
          next_state = 2;
        end
      end
		
		3: begin // response_sl
        if (bit_in == 1'b0 && next_bit_in == 1'b1) begin
          next_state = 4;
          next_index = DELAY_80_US; // Use DELAY_80_US here
        end else begin
          next_state = 3;
        end
      end
		
		4: begin // delay_sl
        if (bit_in == 1'b1 && next_bit_in == 1'b0) begin
          next_state = 5;
        end else begin
          next_state = 4;
        end
      end
		
		5: begin // start_sl
        if (bit_in == 1'b0 && next_bit_in == 1'b1) begin
          next_state = 6;
          next_index = 6'b0;
        end else if (number_bit == 0) begin
          next_state = 10; // end_sl
          next_index = DELAY_50_US;
        end else begin
          next_state = 5;
        end
      end
		
		6: begin // consider_logic
        next_index = index + 1;
        next_bit_in = singer_bus;
        if (bit_in == 1'b1 && next_bit_in == 1'b0) begin
          next_number_bit = number_bit - 1;
          if (index < TIME_28_US) begin
            next_data_out = {data_out[N-2:0], 1'b0};
          end else if (index < TIME_70_US) begin
            next_data_out = {data_out[N-2:0], 1'b1};
          end
          next_state = 5; // start_sl
          next_index = DELAY_50_US;
        end else if (bit_in == 1'b1 && next_bit_in == 1'b1) begin
          next_state = 6; // consider_logic
        end else begin
          next_state = 6; // consider_logic
        end
      end

      default: begin
        // Handle undefined states here, if necessary
		  next_state = 0; // Set to the reset state
        next_index = MAX_DELAY; // Set other default values if needed
        next_number_bit = 0; // Set other default values if needed
        next_bit_in = 1'b1; // Set other default values if needed
        next_data_out = 40'b0; // Set other default values if needed
      end
    endcase
  end
  
	// UART Transmit State Machine
	always @(posedge clk) begin
	  case (tx_state)
		 3'b000: begin // IDLE state
			if (tx_counter > 8) begin
			  tx_state <= 3'b001; // Move to the TRANSMITTING state
			  tx_data_reg <= dataout; // Load temperature data
			end
		 end
		 3'b001: begin // TRANSMITTING state
			if (tx_counter < 8) begin
			  tx_data <= tx_data_reg[tx_counter]; // Transmit one bit at a time
			  tx_ready <= 1'b1; // Set UART ready
			  tx_counter <= tx_counter + 1; // Increment counter
			end else begin
			  tx_ready <= 1'b0; // Clear UART ready when all bits are transmitted
			  tx_state <= 3'b000; // Return to IDLE state
			end
		 end
	  endcase
	end

	// Logic for singer_bus
  assign singer_bus = (oe) ? 1'b0 : 1'bz;

endmodule
