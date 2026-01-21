/************************************************************************************************************
 *  Copyright:
 *  Description:
 *  1.
 *  2.
 *
 *  Version:
 *   Ver  | yyyy-mmm-dd|  Who  | Description of changes
 *   =====|============|=======|==============================================
 *    1.0 | 2023-07-07 |  sgr  | Original Release.
 *   -----|------------|-------|----------------------------------------------
 *************************************************************************************************************/

//---------------------include------------------------------------------------------------------------------//
#include <zephyr/kernel.h>
#include <zephyr/sys/reboot.h>
#include <string.h>
#include <zephyr/drivers/flash.h>
#include <zephyr/storage/flash_map.h>
#include <zephyr/fs/nvs.h>
#include <zephyr/sys/printk.h>
#include <assert.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/device.h>
#include <zephyr/devicetree.h>

#include <zephyr/logging/log.h>

#include <zephyr/types.h>
#include <stddef.h>
#include <stdint.h>
#include <errno.h>
#include <soc.h>
#include <zephyr/sys/byteorder.h>

#include <nrfx_timer.h>
#include <nrfx_spim.h>
#include <nrfx_ppi.h>
#include <nrfx_gpiote.h>
#include <hal/nrf_gpio.h>

#include <zephyr/irq.h>
#include <nrf.h>
#include <nrf52840.h>

#include "spi.h"
#include "flash.h"
#include "CommonFile.h"

//---------------------defines------------------------------------------------------------------------------//

//---------------------definition of data type--------------------------------------------------------------//
#define ICE40_SCK_PIN 5
#define ICE40_MOSI_PIN 8
#define ICE40_MISO_PIN 27
#define ICE40_SS_PIN 4
#define ICE40_CRESET_PIN 6 // Used for FPGA firmware upgrades reset
#define ICE40_CDONE_PIN 7  // Used for FPGA firmware upgrades done

#define PIN_SET_LOW 0
#define PIN_SET_HIGH 1

#define PASS true
#define FAIL false

#define FPGA_P1_2_PIN 3
#define FPGA_P3_3_PIN 37 // P1.5
#define FPGA_RESET_PIN 12
//---------------------definition of global variables------------------------------------------------------//
// typedef enum
// {
//     NOERR,                  /*!< no error. */
//     DEVERR,                 /*!< Flash device is not ready. */
//     PAGEERR,                /*!< Unable to get page info. */
//     MOUNTERR                /*!< Flash Init failed. */
// } iCE40ErrorCode;

//---------------------declaration of global functions -----------------------------------------------------//
uint8_t iCE40_InitFs(void);
void fpga_3_3PowerEnable(void);
void fpga_3_3PowerDisable(void);
void fpga_1_2PowerEnable(void);
void fpga_1_2PowerDisable(void);
void fpga_low_power(void);
void fpga_InitPowerPin(void);
void fpga_UinitPowerPin(void);
void iCE40_InitPins(void);
void iCE40_UinitPins(void);
void SendClocks(int numClock);
void iCE40_SendByte(uint8_t value);
nvsStatus_t iCE40_SendProgrammeFile(void);
nvsStatus_t iCE40_Programme(void);
nvsStatus_t iCE40_Configuration(void);
nvsStatus_t iCE40_WorkStatusTest(void);
void gpio_low_power(void);
void gpio_no_pull(void);
void fpga_reset_low(void);
void fpga_reset_high(void);

//============================================================================================================
//  End of file
//============================================================================================================