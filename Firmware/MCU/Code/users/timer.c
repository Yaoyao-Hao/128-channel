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

//---------------------include------------------------------------------------------------------------------//
#include "timer.h"
//---------------------defines------------------------------------------------------------------------------//

//---------------------definition of data type--------------------------------------------------------------//

//---------------------definition of global variables------------------------------------------------------//
struct k_timer spi_data_cap_timer;

//---------------------declaration of global functions -----------------------------------------------------//

//----------------------definitions of functions------------------------------------------------------------//
/**************************************************************************
 *Description:
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
void spi_cap_timer_event_handler(struct k_timer *timer)
{
    uint16_t signalHearder = HEADER_SIGNAL;
    SPI_FpgaData.xfer_done = false;

    memset((void *)&SPI_FpgaData.txBuf, 0, SPI_TX_BUF_SIZE);
    // memset((void*)&SPI_FpgaData.rxBuf, 0, SPI_TX_BUF_SIZE);
    SPI_FpgaData.txBuf[0] = signalHearder;
    SPI_FpgaData.txBuf[1] = signalHearder >> 8;
    // SPI_FpgaData.txBuf[0] = signalHearder >> 8;
    // SPI_FpgaData.txBuf[1] = signalHearder;
    BSP_Spim3_TransmitReceive(SPI_FpgaData.txBuf, SPI_TX_BUF_SIZE, SPI_FpgaData.rxBuf, SPI_RX_BUF_SIZE);
}

/**************************************************************************
 *Description:
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
uint32_t DDI_TIMER3_Init(void)
{
    uint32_t err = NRFX_SUCCESS;

    k_timer_init(&spi_data_cap_timer, spi_cap_timer_event_handler, NULL);
    SPI_FpgaData.timerInitFlag = true;

    return err;
}

//============================================================================================================
//  End of file
//============================================================================================================