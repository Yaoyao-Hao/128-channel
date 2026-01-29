# 128-channel
A 128-channel fully implantable system with COTS components for intracortical neural sensing and decoding
    
    |—— Electrode          
    
    // design files for silicon probe and flexible cable
    
    |—— FPGA decoding      
    
        // FPGA implementation of 3 decoding algorithms: Wiener Filter, Kalman Filter and LSTM
    
        // along with testing neural data and Python implementation
        
    |—— bined_spk — Neural Feature Matrix
        
            Shape: (96, 12600)
        
            Description: Binned spike features from 96 neural channels across 12,600 time windows.
        
            This serves as the main input feature matrix X.
        
    |   |—— trial_velocity — Target Output (Velocity Trajectories)
        
            Shape: (2, 12600)
        
            Description: Two-dimensional velocity signals (e.g., x- and y-direction hand movement velocities).
        
            This is the supervised target Y.
        
    |   |—— trial_mask — Valid Sample Mask
        
            Shape: (1, 12600)
        
            Description: Indicates whether each time point belongs to a valid trial segment (1 = valid, 0 = invalid/inter-trial interval).
        
            Used to filter out non-trial data during training and evaluation.
        
    |   |—— trial_breakNum — Trial Lengths
        
            Shape: (1, 90)
        
            Description: Number of time steps in each of the 90 trials.
        
            Used to segment continuous data into individual trials.
        
