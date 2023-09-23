module TempTest (
  input clk,
  input rst,
  inout singer_bus,
  output [39:0] dataout,
  output reg tick_done,
  output uart_tx, // UART transmit data output
  output reg uart_tx_en, // UART transmit enable output
  inout uart_tx_pin, // UART transmit pin
  inout uart_rx_pin // UART receive pin
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
  reg [5:0] bit_in, next_bit_in;
  reg [5:0] number_bit, next_number_bit;
  reg oe;
  reg uart_tx_data; // UART transmit data
  reg [3:0] uart_tx_count; // UART transmit count
  reg rx;        // Current state of the receive line
  reg next_rx;   // Next state of the receive line
  wire trigger_condition;

  assign trigger_condition = (rx == 1'b0) && (next_rx == 1'b1);

  assign dataout = data_out;

  // UART parameters (adjust as needed)
  parameter BAUD_RATE = 9600;
  parameter DATA_BITS = 8;
  parameter STOP_BITS = 1; // Define the number of stop bits here
  reg [15:0] baud_divisor;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      baud_divisor <= 16'b0;
    end else begin
      // Calculate the baud rate divisor
      baud_divisor <= (16'h8000 / BAUD_RATE); // Assuming a 16-bit divisor
    end
  end

  // UART state machine states
  reg [2:0] uart_state;

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

      // UART state machine
      uart_tx_en <= (uart_state != 0) ? 1'b1 : 1'b0;
    end
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

    case (state)
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

  // UART TX pin assignment
  assign uart_tx_pin = uart_tx_en ? uart_tx_data : 1'bz;

  // UART state machine
  always @(posedge clk) begin
    case (uart_state)
      0: begin // UART state 0 - Idle
        if (trigger_condition) begin
          // Transition to the next UART state to start transmitting
          uart_state <= 1; // Change to the appropriate state
          uart_tx_data <= 8'hFF; // Set UART transmit data (adjust as needed)
          uart_tx_count <= 4'b0000; // Initialize transmit count (adjust as needed)
        end else begin
          uart_state <= 0; // Stay in the idle state
        end
      end

      1: begin // UART state 1 - Transmitting
        if (uart_tx_count < DATA_BITS) begin
          // Continue transmitting data bits
          uart_tx_data <= data_out[uart_tx_count]; // Assuming data_out is a 40-bit signal
          uart_tx_count <= uart_tx_count + 1'b1;
        end else begin
          // Finished transmitting all data bits, move to the stop bit(s) state
          uart_state <= 2; // Change to the stop bit(s) state
          uart_tx_data <= 1'b0; // Set stop bit(s) value (adjust as needed)
          uart_tx_count <= 4'b0000; // Reset transmit count for stop bit(s)
        end
      end

      2: begin // UART state 2 - Stop bit(s)
        if (uart_tx_count < STOP_BITS) begin
          // Continue transmitting stop bit(s)
          uart_tx_data <= 1'b0; // Set stop bit(s) value (adjust as needed)
          uart_tx_count <= uart_tx_count + 1'b1;
        end else begin
          // Finished transmitting stop bit(s), move to idle state
          uart_state <= 0; // Change to the idle state
          // Optionally, you can reset other UART-related variables here
        end
      end
    endcase
  end

  // Logic for singer_bus
  assign singer_bus = (oe) ? 1'b0 : 1'bz;

endmodule
