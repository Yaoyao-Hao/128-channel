# Version

FPGA_128_Firmware.bin # 128 channel system firmware with Wiener filter integrated for ICE40UP FPGA

128 channel system FPGA

    |       |—— 01_RHD        // Communication module with RHD2164

    |       |—— 02_thre       // RMS value calculation and thresholding

    |       |—— 03_Wiener     // Wiener Filter module

    |       |—— 04_Spikecal   // Spike module

    |       |—— 05_MCU        // Communication module with MCU 

    |       |—— 06_TB         // Test bench