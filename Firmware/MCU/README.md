# MCU Firmware

## Project Overview

Based on the Nordic nRF52840 microcontroller, utilizing Zephyr RTOS (NCS 2.3.0) as the software framework. The MCU controls the FPGA to perform neural signal acquisition, impedance testing, and threshold reading via Bluetooth interaction commands from the host computer. It also supports FPGA programming and Bluetooth OTA upgrade functionality.

## Hardware Platform

-   Main Controller: Nordic nRF52840 SoC

    -   ARM Cortex-M4F processor

    -   Supports Bluetooth 5.0

    -   1MB Flash and 256KB RAM

-   Peripherals:

    -   SPI interface for FPGA communication

    -   PTX30W power management IC

    -   SHT4x temperature and humidity sensor

## Software Architecture

-   Development Environment

    -   SDK: Nordic Connect SDK (NCS) 2.3.0

    -   RTOS: Zephyr RTOS

    -   Programming Language: C

-   Event-Driven Architecture
    | Event | Description | Action |
    |-----|-----|-----|
    | EVENT_CONNECT | Bluetooth connection established | FPGA power preparation |
    | EVENT_DISCONNECT | Bluetooth disconnection | FPGA power off, enter low power mode |
    | EVENT_COM | SPI Communication complete | Process FPGA data |
    | EVENT_FPGA_ENABLE | Enable FPGA | Initialize SPI/Timer, start FPGA |
    | EVENT_FPGA_DISABLE | disable FPGA | Disable FPGA Release resources, Power Down FPGA |
    | EVENT_READ_DEVICE_STATUS | Read Device Status | Collect temperature, humidity, and power status |
    | EVENT_FPGA_UPDATE_PRE | FPGA Update Preparation | Initialize Flash, Clear Old Data |
    | EVENT_FPGA_UPDATE_FRAME_RECEIVE | Receive Update Frame | Write to Flash, Manage frame count. |
    | EVENT_FPGA_UPDATE_PROGRAM | FPGA programming | Execute FPGA programming to configure FPGA from Flash. |
    | EVENT_POWER_DOWN | System shutdown | enter transport mode |

## Bluetooth Service Architecture

1. FPGA-related services (fpgarelated_service) manage interaction with the FPGA:

    Signal Acquisition Control: Start/stop FPGA data acquisition.

    Data Notification: Supports three data modes:

    Status Notification: FPGA operational status feedback

2. iCE40 Update Service (iCE40update_service) implements remote FPGA firmware updates:

    Frame-based Reception: Receives FPGA configuration data via Bluetooth

    Flash Storage: Writes configuration data to SPI Flash

    Online Programming: Dynamically configures FPGA logic

    Resumable Transfer: Supports firmware update interruption recovery

3. Device Information Service (deviceinfo_service) provides device status monitoring:

    Power Status: Monitored via PTX30W chip

    Environmental Parameters: Temperature and humidity sensor data

    System Status: FPGA busy/idle status, connection status, etc.

    Device Information: Firmware version, hardware details, etc.
