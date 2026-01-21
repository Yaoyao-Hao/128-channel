# Project Introduction
This project is aimed at implementing 128-channel neural signal acquisition on FPGA.

It includes FPGA implementations of Wiener, LSTM, and Kalman trajectory decoding algorithms.
 
# Environment-dependent
 Lattice Radiant
 python 3.11

# Directory Structure Description
    ©À©¤©¤ ReadMe.md           // help
    
    ©À©¤©¤ ESA_data           // Handwritten Chinese Character Dataset
    
    ©À©¤©¤ python             // python Decoding Algorithm
        
    ©¦   ©À©¤©¤ kalman     // kalman train&test£¬Parameter File Generation
    
    ©¦   ©À©¤©¤ LSTM       // LSTM train&test£¬Parameter File Generation
    
    ©¦   ©À©¤©¤ Wiener     // Wiener train&test£¬Parameter File Generation

    ©À©¤©¤ RTL_code             // FPGA code
        
    ©¦   ©À©¤©¤ kalman     // kalman RTL code&IP

    ©¦       ©À©¤©¤ 01_Kalman    // kalman cal top&Matrix mult

    ©¦       ©À©¤©¤ 02_LDL       // LDL Inv Module
    
    ©¦       ©À©¤©¤ 03_TB        // Test bench
    
    ©¦       ©À©¤©¤ 04_Initfile  // INIT para file    
    
    ©¦   ©À©¤©¤ LSTM       // LSTM RTL code&IP
    
    ©¦       ©À©¤©¤ 01_dypll     // clock gen 

    ©¦       ©À©¤©¤ 02_top       // TOP

    ©¦       ©À©¤©¤ 03_hyRam     // hyram phy    

    ©¦       ©À©¤©¤ 04_constr    // IO

    ©¦       ©À©¤©¤ 05_UART      // UART phy&Agreement

    ©¦       ©À©¤©¤ 06_LSTM      // LSTM cal 

    ©¦       ©À©¤©¤ 07_ipcore    // IP CORE

    ©¦       ©À©¤©¤ 08_TB        // Test bench
    
    ©¦       ©À©¤©¤ 09_Initfile  // INIT para file    
    
    ©¦   ©À©¤©¤ Wiener     // Wiener RTL code&IP

    ©¦       ©À©¤©¤ 01_RHD        // RHD phy

    ©¦       ©À©¤©¤ 02_thre       // thre rec&RMS cal

    ©¦       ©À©¤©¤ 03_Wiener     // Wiener cal    

    ©¦       ©À©¤©¤ 04_Spikecal   // spike cal

    ©¦       ©À©¤©¤ 05_MCU        // MCU <-----> FPGA Communication 

    ©¦       ©À©¤©¤ 06_TB         // Test bench

 
# Version
###### v1.0.0: 
    1. 128-channel neural signal acquisition
    2. spike cal
    3. Wiener&LSTM&Kalman cal
    4. channel RMS cal
    

 
 