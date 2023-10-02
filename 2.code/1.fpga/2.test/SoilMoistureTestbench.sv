`timescale 1ns/1ns // Add a default timescale for the entire module

module tb_SoilMoistureSensor;

  // Define testbench signals
  reg clk;
  reg reset;
  reg [7:0] adc_data; // Match port width with SoilMoistureSensor
  wire [7:0] moisture_percentage;

  // Instantiate the module under test
  SoilMoistureSensor dut (
    .clk(clk),
    .reset(reset),
    .adc_data(adc_data),
    .moisture_percentage(moisture_percentage)
  );

  // Clock generation
  always begin
    #5 clk = ~clk; // Toggle the clock every 5 time units
  end

  // Reset generation
  initial begin
    reset = 1;
    #10 reset = 0; // Release reset after 10 time units
  end

  // Stimulus generation
  initial begin
    clk = 0;

    // Provide ADC data values for testing
    adc_data = 8'b00110010; // Change this value as needed

    // Add more test cases with different adc_data values

    // Simulation duration
    #1000 $finish; // Finish the simulation after 1000 time units
  end

  // Display results
  initial begin
    $monitor("Time=%0t, ADC Data=%h, Moisture Percentage=%h", $time, adc_data, moisture_percentage);
  end

endmodule
