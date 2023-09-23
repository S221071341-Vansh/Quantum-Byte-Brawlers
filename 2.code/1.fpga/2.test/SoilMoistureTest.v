module SoilMoistureSensor(
  input clk,     // Clock input
  input rst,     // Reset input
  output reg sensor_data // Soil moisture sensor data output
);

  reg [15:0] counter;     // Counter to keep track of moisture level
  reg sensor_output;      // Output signal indicating soil moisture level

  parameter THRESHOLD = 8'h7F; // Threshold for moisture level detection

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      counter <= 16'h0000;  // Initialize counter
      sensor_output <= 1'b0; // Initialize sensor output
    end else begin
      if (counter < THRESHOLD) begin
        counter <= counter + 1'b1;    // Increment counter
        sensor_output <= 1'b0;        // Set sensor output low (dry)
      end else begin
        counter <= 16'h0000;          // Reset counter
        sensor_output <= 1'b1;        // Set sensor output high (wet)
      end
    end
  end

  assign sensor_data = sensor_output;  // Output sensor data

endmodule
