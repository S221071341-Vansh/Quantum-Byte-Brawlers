module DHT22_Interface(
    input wire clk,
    input wire rst,
    input wire data_ready, // Trigger signal from microcontroller
    input wire [7:0] sensor_data,
    output wire [7:0] temperature_data
);

    // Registers to store sensor data
    reg [7:0] temperature_data_reg;

    // State machine states
    parameter IDLE = 0; //LOW
    parameter READ_DATA = 1; //HIGH

    // State machine
    reg [1:0] state;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            temperature_data_reg <= 0;
        end else begin
            case (state)
                IDLE: begin
                    // Wait for the data_ready signal to go high
                    if (data_ready) begin
                        state <= READ_DATA;
                    end
                end

                READ_DATA: begin
                    // Read sensor data from the sensor_data bus
                    temperature_data_reg <= sensor_data;

                    // Transition back to IDLE state
                    state <= IDLE;
                end
            endcase
        end
    end

    // Output the temperature data
    assign temperature_data = temperature_data_reg;

endmodule
