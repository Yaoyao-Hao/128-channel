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
#ifndef __SPI_H
#define __SPI_H
//---------------------include------------------------------------------------------------------------------//
#include <zephyr/sys/printk.h>
#include <zephyr/logging/log.h>
#include <assert.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/device.h>
#include <zephyr/devicetree.h>
#include <zephyr/kernel.h>

#include <zephyr/types.h>
#include <stddef.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <errno.h>
#include <soc.h>
#include <zephyr/sys/byteorder.h>

#include <nrfx_timer.h>
#include <nrfx_spim.h>
#include <nrfx_ppi.h>
#include <nrfx_gpiote.h>

#include <zephyr/irq.h>
#include <nrf.h>
#include <nrf52840.h>

#include "../users/CommonFile.h"

//---------------------defines------------------------------------------------------------------------------//
// for test
// #define NRFX_SPIM_SCK_PIN   29
// #define NRFX_SPIM_MOSI_PIN  31
// #define NRFX_SPIM_MISO_PIN  30
// #define NRFX_SPIM_SS_PIN    28

#define NRFX_SPIM_SCK_PIN 5
#define NRFX_SPIM_MOSI_PIN 27
#define NRFX_SPIM_MISO_PIN 8
#define NRFX_SPIM_SS_PIN 4

#define SPI_INSTANCE 3

#define SPI_TX_BUF_SIZE (386 + 4) // 2*空+2*header+ 4*timestage + 1*wiener header + 1*wienervalid + 8*wiener data +15*8*2*raw + 128*1*spike
#define SPI_RX_BUF_SIZE (386 + 4)

#define SPI_CMD_TX_BUF_SIZE 66
#define SPI_CMD_RX_BUF_SIZE 66

#define NOTIFY_SIGNAL_SPIKE_SIZE 147

#define HEADER_SIGNAL 0xC691 // for test
#define HEADER_SPIKE 0x1999
#define HEADER_SPIRUN 0x2702
#define HEADER_WIREIN 0x9B5D
#define HEADER_TRIGGERIN 0xE5C7

#define BMI_FPGA_RUN_HEADER 0x0101
#define HEADER_SIGNAL_HIGH 0xC6
#define HEADER_SIGNAL_LOW 0x91 // for test
//---------------------definition of data type--------------------------------------------------------------//
typedef struct
{
    bool xfer_done;
    uint8_t txBuf[SPI_TX_BUF_SIZE];
    uint8_t rxBuf[SPI_RX_BUF_SIZE];
    uint8_t thresholdBuf[SPI_RX_BUF_SIZE];

    bool spiInitFlag;
    bool timerInitFlag;
} bmiSPI_t;

//---------------------definition of global variables------------------------------------------------------//
extern bmiSPI_t SPI_FpgaData;
extern uint8_t NfyData[NOTIFY_SIGNAL_SPIKE_SIZE];
//---------------------declaration of global functions -----------------------------------------------------//
uint32_t SPI_Init(void);

uint32_t DDI_Spim3_Init(void);
uint32_t BSP_Spim3_TransmitReceive(uint8_t *pTxData, uint16_t TxSize, uint8_t *pRxData, uint16_t RxSize);
uint32_t DDI_Spim3_Uinit(void);

#endif /*__SPI_H*/
       //============================================================================================================
       //  End of file
       //============================================================================================================