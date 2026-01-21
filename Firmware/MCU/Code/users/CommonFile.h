/************************************************************************************************************
 *  Copyright:
 *  Description:
 *  1.
 *  2.
 *
 *  Version:
 *   Ver  | yyyy-mmm-dd|  Who  | Description of changes
 *   =====|============|=======|==============================================
 *    1.0 | 2023-04-25 |  sgr  | Original Release.
 *   -----|------------|-------|----------------------------------------------
 *************************************************************************************************************/
#ifndef _COMMON_FILE_H_
#define _COMMON_FILE_H_

// #define ENABLE_TEST
//---------------------defines------------------------------------------------------------------------------//
#define SYS_STA_INIT 0x00
#define SYS_STA_COM 0x01             // RHD data acquisition, BLE communication status
#define SYS_STA_FPGA_PRE_UPDATE 0x02 // clear and mount fs
#define SYS_STA_FPGA_UPDATE 0x03     // BLE  transfers files, MCU saves to flash
#define SYS_STA_iCE40_PROGRAM 0x04   // MCU programs iCE40
#define SYS_STA_MCU_UPDATE 0x05      // MCU update
#define SYS_STA_POWER_OFF 0x06       // power off
#define SYS_STA_READ_STATUS 0x07     // read status
#define SYS_STA_IDLE 0x08            // low power
//---------------------definition of data type--------------------------------------------------------------//
extern uint8_t sys_Sta;

#define sJumpToSta(sta) sys_Sta = (sta)
// K_SEM_DEFINE(event_sem, 0, 1);

//---------------------definition of global variables------------------------------------------------------//
/* 定义事件标志位 */
#define EVENT_CONNECT BIT(0)
#define EVENT_DISCONNECT BIT(1)
#define EVENT_READ_DEVICE_STATUS BIT(2)
#define EVENT_COM BIT(3)
#define EVENT_FPGA_ENABLE BIT(4)
#define EVENT_FPGA_DISABLE BIT(5)
#define EVENT_COM_ENABLE BIT(6)
#define EVENT_CONNECT_NECT BIT(7)
#define EVENT_FPGA_UPDATE_PRE BIT(8)
#define EVENT_FPGA_UPDATE_FRAME_RECEIVE BIT(9)
#define EVENT_FPGA_UPDATE_PROGRAM BIT(10)
#define EVENT_POWER_DOWN BIT(11)

extern struct k_event event_flags;

#endif /*_COMMON_FILE_H_*/
       //============================================================================================================
       //  End of file
       //============================================================================================================