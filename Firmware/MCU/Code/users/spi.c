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
#include "spi.h"

//---------------------defines------------------------------------------------------------------------------//
#define LOG_MODULE_NAME bmi_peri
LOG_MODULE_REGISTER(LOG_MODULE_NAME);

#define SPIM3_ISR_PRIORITY 1
//---------------------definition of data type--------------------------------------------------------------//

//---------------------definition of global variables------------------------------------------------------//
static const nrfx_spim_t spi3 = NRFX_SPIM_INSTANCE(SPI_INSTANCE);
bmiSPI_t SPI_FpgaData;
uint8_t NfyData[NOTIFY_SIGNAL_SPIKE_SIZE];

//---------------------declaration of global functions -----------------------------------------------------//

//----------------------definitions of functions------------------------------------------------------------//
/**************************************************************************
 *Description:
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
uint32_t SPI_Init(void)
{
    uint32_t err = NRFX_SUCCESS;

    SPI_FpgaData.xfer_done = false;
    memset((void *)SPI_FpgaData.txBuf, 0, SPI_TX_BUF_SIZE);
    memset((void *)SPI_FpgaData.rxBuf, 0, SPI_RX_BUF_SIZE);

    err = DDI_Spim3_Init();
    SPI_FpgaData.spiInitFlag = true;

    return err;
}
/**************************************************************************
 *Description:
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
void spim3_event_handler(nrfx_spim_evt_t const *p_event, void *p_context)
{
    SPI_FpgaData.xfer_done = true;
    k_event_post(&event_flags, EVENT_COM);
}

/**************************************************************************
 *Description:
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
uint32_t DDI_Spim3_Init(void)
{
    uint32_t err = NRFX_SUCCESS;
    nrfx_spim_config_t spi_config = NRFX_SPIM_DEFAULT_CONFIG(NRFX_SPIM_SCK_PIN, NRFX_SPIM_MOSI_PIN, NRFX_SPIM_MISO_PIN, NRFX_SPIM_SS_PIN);
    spi_config.frequency = NRF_SPIM_FREQ_8M;
    spi_config.bit_order = SPIM_CONFIG_ORDER_MsbFirst;
    spi_config.mode = NRF_SPIM_MODE_3;
    spi_config.use_hw_ss = true;
    err = nrfx_spim_init(&spi3, &spi_config, spim3_event_handler, NULL);

    IRQ_CONNECT(NRFX_IRQ_NUMBER_GET(NRF_SPIM3), SPIM3_ISR_PRIORITY, nrfx_isr, nrfx_spim_3_irq_handler, 0);

    return err;
}

/**************************************************************************
 *Description:
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
uint32_t BSP_Spim3_TransmitReceive(uint8_t *pTxData, uint16_t TxSize, uint8_t *pRxData, uint16_t RxSize)
{
    uint32_t err = NRFX_SUCCESS;

    nrfx_spim_xfer_desc_t xfer_desc = NRFX_SPIM_XFER_TRX(pTxData, TxSize, pRxData, RxSize);

    err = nrfx_spim_xfer(&spi3, &xfer_desc, 0);

    return err;
}

uint32_t DDI_Spim3_Uinit(void)
{
    uint32_t err = NRFX_SUCCESS;

    nrfx_spim_uninit(&spi3);
    SPI_FpgaData.spiInitFlag = false;
    return err;
}

//============================================================================================================
//  End of file
//============================================================================================================