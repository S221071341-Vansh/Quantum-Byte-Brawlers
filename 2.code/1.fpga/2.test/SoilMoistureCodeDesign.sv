module SoilMoistureSensor(
  input wire clk, // Clock signal
  input wire reset, // Reset signal
  input wire adc_data, // Digital data from ADC
  output reg [7:0] moisture_percentage // Moisture percentage (0-100)
);

  reg [9:0] adc_value; // Internal storage for ADC data

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      adc_value <= 10'b0; // Reset ADC value to 0
    end else begin
      // Read ADC data on the rising edge of the clock
      adc_value <= adc_data;
    end
  end

  // Map ADC data to moisture percentage (adjust calibration values)
  always @(posedge clk) begin
    case(adc_value)
      10'd0: moisture_percentage <= 8'b0; // Dry soil
      // Add more cases for different ADC values and corresponding percentages
      default: moisture_percentage <= 8'b100; // Assume 100% for unknown value
    endcase
  end

endmodule
