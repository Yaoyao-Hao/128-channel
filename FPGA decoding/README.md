# Project Introduction
This project is aimed at implementing 128-channel neural signal acquisition on FPGA.

It includes FPGA implementations of Wiener, LSTM, and Kalman trajectory decoding algorithms.
 
# Environment-dependent
 Lattice Radiant
 python 3.11

# Directory Structure Description
    |—— ReadMe.md          // help
    
    |—— ESA_data           // Handwritten Chinese Character Dataset
    
        Dataset Overview
        
        This dataset is designed for neural signal decoding and behavioral trajectory prediction, and is suitable for training and evaluating models such as Wiener filters, Kalman filters, and LSTM networks.
        
        The data are stored in MATLAB 5.0 format and loaded as a dictionary , with the following main fields:
        
        Core Data Fields
    |   |—— bined_spk — Neural Feature Matrix
        
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
        
    |   |—— trial_target — Trial Target Indices
        
            Shape: (90, 1)
        
            Description: Target class index for each trial (e.g., 1–30).
        
    |   |—— target_hanzi — Target Character Labels
        
            Shape: (1, 30)
        
            Description: Chinese character labels corresponding to each target class, indicating this is a brain–computer interface handwriting task.
        
    |   |—— break_ind — Trial Boundary Indicators
        
            Shape: (1, 12600)
        
            Description: Marks inter-trial boundaries for segmenting the data.
    
    |—— python             // python Decoding Algorithm
        
    |   |—— kalman     // kalman train&test&Parameter File Generation
    
    |   |—— LSTM       // LSTM train&test&Parameter File Generation
    
    |   |—— Wiener     // Wiener train&test&Parameter File Generation

    |—— RTL_code             // FPGA code
        
    |   |—— kalman     // kalman RTL code&IP

    |       |—— 01_Kalman    // kalman cal top&Matrix mult

    |       |—— 02_LDL       // LDL Inv Module
    
    |       |—— 03_TB        // Test bench
    
    |       |—— 04_Initfile  // INIT para file    
    
    |   |—— LSTM       // LSTM RTL code&IP
    
    |       |—— 01_dypll     // clock gen 

    |       |—— 02_top       // TOP

    |       |—— 03_hyRam     // hyram phy    

    |       |—— 04_constr    // IO

    |       |—— 05_UART      // UART phy&Agreement

    |       |—— 06_LSTM      // LSTM cal 

    |       |—— 07_ipcore    // IP CORE

    |       |—— 08_TB        // Test bench
    
    |       |—— 09_Initfile  // INIT para file    
    
    |   |—— Wiener     // Wiener RTL code&IP

    |       |—— 01_Wiener     // Wiener filter

    |       |—— 02_TB         // Test bench

    |       |—— 03_init_file  // init file 

    |           |—— W_q.hex   // Wiener parameter 

    |           |—— X_q.txt   // testfile 

 
# Version
###### v1.0.0: 
    1. 128-channel neural signal acquisition
    2. spike cal
    3. Wiener&LSTM&Kalman cal
    4. channel RMS cal
    

 
 