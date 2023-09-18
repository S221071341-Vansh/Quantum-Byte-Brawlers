import matplotlib.pyplot as plt
import matplotlib.animation as animation

def live_plot(humidity_data, soil_moisture_data, interval=1000):
    """
    Display live line charts for humidity and soil moisture.

    Parameters:
    - humidity_data: a generator that yields humidity data points.
    - soil_moisture_data: a generator that yields soil moisture data points.
    - interval: time (in ms) between updates.
    """

    # Set up the figure, the axis, and the plot elements
    fig, (ax1, ax2) = plt.subplots(2, 1, sharex=True)
    
    ax1.set_title("Humidity Over Time")
    ax1.set_ylabel("Humidity (%)")

    ax2.set_title("Soil Moisture Over Time")
    ax2.set_xlabel("Time")
    ax2.set_ylabel("Soil Moisture (%)")

    # This line is only to set the limits of the plot for better visualization
    # You can adjust it based on your requirements
    ax1.set_ylim(0, 100)
    ax2.set_ylim(0, 100)

    # These lists will store the data and help in updating the plots
    humidity, = ax1.plot([], [], 'b-')
    soil_moisture, = ax2.plot([], [], 'r-')
    time_data = []

    # Initialization function
    def init():
        humidity.set_data([], [])
        soil_moisture.set_data([], [])
        return humidity, soil_moisture,

    # Animation function which updates the figure
    def update(num):
        time_data.append(num)
        humidity.set_data(time_data, [next(humidity_data) for _ in time_data])
        soil_moisture.set_data(time_data, [next(soil_moisture_data) for _ in time_data])
        return humidity, soil_moisture,

    ani = animation.FuncAnimation(fig, update, init_func=init, frames=100, blit=True, interval=interval)

    plt.tight_layout()
    plt.show()

# Example usage:
# For the sake of this demonstration, let's use random data generators for humidity and soil moisture.
import random

def humidity_generator():
    while True:
        yield random.randint(40, 60)

def soil_moisture_generator():
    while True:
        yield random.randint(20, 50)

live_plot(humidity_generator(), soil_moisture_generator())
