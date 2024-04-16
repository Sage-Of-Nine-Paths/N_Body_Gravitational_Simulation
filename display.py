# Authored by :: Aniruddha Date
# Date Created:: 14 March 2024

from multiprocessing import Process
import sys
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import numpy as np
import matplotlib.cm as cm
import tkinter as tk

# Load data from data.txt into a DataFrame
data = pd.read_csv('data.txt', sep=r'\s+')

# Get number of bodies from command-line argument
num_bodies = int(sys.argv[1])

# Define a function to update the plot for each frame
def graph1():
    def update_plot(frame):
        ax.cla()  # Clear the previous plot

        frame_data = data[data['Time'] <= frame * 0.01]  # Select data up to current frame time

        # Generate a colormap for unique colors
        cmap = plt.get_cmap('tab10')
        colors = cmap(np.linspace(0, 1, num_bodies))

        for i in range(num_bodies):
            body_label = f'Body {i+1}'
            body_data = frame_data[frame_data['Body'] == i+1]  # Filter data for the current body
            ax.scatter(body_data['Sx'], body_data['Sy'], label=body_label, marker='o', color=colors[i], alpha=0.7, s=3)

        ax.set_xlabel('X Position')
        ax.set_ylabel('Y Position')
        ax.set_title(f'Time: {frame * 0.01:.6f} sec')
        ax.legend()

    # Create a figure and axis for the plot
    fig, ax = plt.subplots()

    # Set up distinct colors for each body
    plt.rcParams['axes.prop_cycle'] = plt.cycler(color=plt.cm.tab10.colors[:num_bodies])

    # Animate the plot using FuncAnimation
    ani = animation.FuncAnimation(fig, update_plot, frames=len(data) // num_bodies, interval=1)

    # Show the animation
    manager = plt.get_current_fig_manager()
    manager.window.setGeometry(0, 0, 760, 760)
    plt.show()

# def graph2():
#     # Read data from the file
#     data = pd.read_csv('data.txt', delim_whitespace=True)

#     # Get the number of bodies
#     num_bodies = data['Body'].nunique()

#     # Create a colormap with different colors for each body
#     colors = cm.rainbow(np.linspace(0, 1, num_bodies))

#     # Create a figure
#     fig, axs = plt.subplots(nrows=1, ncols=2, figsize=(12, 6))

#     # Iterate over bodies
#     for i, body_id in enumerate(data['Body'].unique()):
#         # Filter data for the current body
#         body_data = data[data['Body'] == body_id]

#         # Plot acceleration (ax) vs time
#         axs[0].plot(body_data['Time'], body_data['Ax'], color=colors[i], label=f'Body {body_id}')
#         axs[0].set_title('Acceleration (ax) vs Time')
#         axs[0].set_xlabel('Time')
#         axs[0].set_ylabel('Acceleration (ax)')

#         # Plot velocity (ux) vs time
#         axs[1].plot(body_data['Time'], body_data['Ux'], color=colors[i], label=f'Body {body_id}')
#         axs[1].set_title('Velocity (ux) vs Time')
#         axs[1].set_xlabel('Time')
#         axs[1].set_ylabel('Velocity (ux)')

#     # Add legends
#     axs[0].legend()
#     axs[1].legend()

#     # Adjust spacing between subplots
#     plt.subplots_adjust(wspace=0.3)

#     # Show the plot
#     manager = plt.get_current_fig_manager()
#     manager.window.setGeometry(600, 0, 600, 400)
#     plt.show()

# if __name__ == '__main__':
#     p1 = Process(target=graph1)
#     p2 = Process(target=graph2)
    
#     p1.start()
#     p2.start()
    
#     p1.join()
#     p2.join()

def graph2():
    # Read data from the file
    data = pd.read_csv('data.txt', sep=r'\s+')

    # Get the number of bodies
    num_bodies = data['Body'].nunique()

    # Create a colormap with different colors for each body
    colors = cm.rainbow(np.linspace(0, 1, num_bodies))

    # Create a figure
    fig, axs = plt.subplots(nrows=1, ncols=2, figsize=(12, 6))

    # Set titles and labels for both plots
    axs[0].set_title('Acceleration (ax) vs Time')
    axs[0].set_xlabel('Time')
    axs[0].set_ylabel('Acceleration (ax)')

    axs[1].set_title('Velocity (ux) vs Time')
    axs[1].set_xlabel('Time')
    axs[1].set_ylabel('Velocity (ux)')

    # Adjust spacing between subplots
    plt.subplots_adjust(wspace=0.3)

    # Define a function to update the plot for each frame
    def update_plot(frame):
        # Clear previous plot
        axs[0].cla()
        axs[1].cla()

        frame_data = data[data['Time'] <= frame * 0.01]  # Select data up to current frame time

        for i, body_id in enumerate(data['Body'].unique()):
            body_data = frame_data[frame_data['Body'] == body_id]

            # Plot acceleration (ax) vs time
            axs[0].plot(body_data['Time'], body_data['Ax'], color=colors[i], label=f'Body {body_id}')

            # Plot velocity (ux) vs time
            axs[1].plot(body_data['Time'], body_data['Ux'], color=colors[i], label=f'Body {body_id}')

        # Add legends
        axs[0].legend()
        axs[1].legend()

        # Set titles
        axs[0].set_title(f'Acceleration (ax) vs Time (Frame {frame})')
        axs[1].set_title(f'Velocity (ux) vs Time (Frame {frame})')

    # Animate the plot using FuncAnimation
    ani = animation.FuncAnimation(fig, update_plot, frames=len(data) // num_bodies, interval=1)

    # Show the plot
    manager = plt.get_current_fig_manager()
    manager.window.setGeometry(760, 30, 760, 760)
    plt.show()


if __name__ == '__main__':
    p1 = Process(target=graph1)
    p2 = Process(target=graph2)

    p1.start()
    p2.start()

    p1.join()
    p2.join()
