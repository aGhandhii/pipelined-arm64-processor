# Create work library
vlib work

# Compile Code
vlog "./*/*.sv"

# Start the Simulator
vsim -voptargs="+acc" -t 1ps -lib work pipelinedProcessor_tb

# Source the wave file
do ./<LOCATION_OF_WAVE_FILE>.do

# Set window types
view wave
view structure
view signals

# Run the simulation
run -all
