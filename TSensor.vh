module DHT22_Interface (
    input wire clk,
    input wire reset,
    inout wire data_pin,
    output wire [15:0] temperature,
    output wire [15:0] humidity,
    output wire valid_data
);

reg [3:0] counter;
reg [5:0] bit_counter;
reg [39:0] data_buffer;
reg [15:0] temperature_value;
reg [15:0] humidity_value;
reg data_valid;

// Constants for timing
localparam t_reset_low = 100; // Reset signal duration (100 ms)
localparam t_start = 20; // Start signal duration (20 ms)
localparam t_data_read = 100; // Data read duration (100 ms)

always @(posedge clk or posedge reset) begin
    if (reset) begin
        // Reset signals on reset
        counter <= 4'b0;
        bit_counter <= 6'b0;
        data_buffer <= 40'b0;
        temperature_value <= 16'b0;
        humidity_value <= 16'b0;
        data_valid <= 1'b0;
        data_pin <= 1'bz;
    end else begin
        // State machine for communication with DHT22
        case (counter)
            4'b0000:
                // Hold the data pin low to reset DHT22
                data_pin <= 1'b0;
                if (bit_counter == t_reset_low - 1) begin
                    counter <= counter + 1;
                    bit_counter <= 6'b0;
                end else begin
                    bit_counter <= bit_counter + 1;
                end
            4'b0001:
                // Release the data pin
                data_pin <= 1'bz;
                if (bit_counter == t_start - 1) begin
                    counter <= counter + 1;
                    bit_counter <= 6'b0;
                end else begin
                    bit_counter <= bit_counter + 1;
                end
            4'b0010 to 4'b1010:
                // Read data bits
                if (bit_counter == 6'b0) begin
                    if (data_pin == 1'b0) begin
                        bit_counter <= bit_counter + 1;
                    end
                end else begin
                    data_buffer[bit_counter - 1] <= data_pin;
                    bit_counter <= bit_counter + 1;
                end
            4'b1011:
                // Data transmission complete
                temperature_value <= data_buffer[31:16];
                humidity_value <= data_buffer[15:0];
                data_valid <= 1'b1;
        endcase
    end
end

// Output the results
assign temperature = temperature_value;
assign humidity = humidity_value;
assign valid_data = data_valid;

endmodule
