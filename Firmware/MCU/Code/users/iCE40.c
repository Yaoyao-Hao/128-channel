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
#include "iCE40.h"

//---------------------defines------------------------------------------------------------------------------//

#define FrameCount 407		   // package count of FPGA bin file
#define LastFrameByteCount 221 // the last packet's bytes number

#define ICE40_TX_BUF_SIZE 256

//---------------------definition of data type--------------------------------------------------------------//
static uint8_t ice40_tx_buf[ICE40_TX_BUF_SIZE];

//---------------------definition of global variables------------------------------------------------------//

//---------------------declaration of global functions -----------------------------------------------------//

//----------------------definitions of functions------------------------------------------------------------//

/**************************************************************************
 *Description:Initialize the gpio for iCE40 programming
 *Input:
 *Output:
 *Return:nvs initialization error
 *Other:
 *************************************************************************/
void fpga_InitPowerPin(void)
{

	nrf_gpio_cfg(FPGA_P1_2_PIN,
				 NRF_GPIO_PIN_DIR_OUTPUT,
				 NRF_GPIO_PIN_INPUT_CONNECT,
				 NRF_GPIO_PIN_NOPULL,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	nrf_gpio_cfg(FPGA_P3_3_PIN,
				 NRF_GPIO_PIN_DIR_OUTPUT,
				 NRF_GPIO_PIN_INPUT_CONNECT,
				 NRF_GPIO_PIN_NOPULL,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	nrf_gpio_cfg(FPGA_RESET_PIN,
				 NRF_GPIO_PIN_DIR_OUTPUT,
				 NRF_GPIO_PIN_INPUT_CONNECT,
				 NRF_GPIO_PIN_NOPULL,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);
}

void fpga_3_3PowerEnable(void)
{
	nrf_gpio_pin_write(FPGA_P3_3_PIN, 1);
}

void fpga_3_3PowerDisable(void)
{
	nrf_gpio_pin_write(FPGA_P3_3_PIN, 0);
}

void fpga_1_2PowerEnable(void)
{
	nrf_gpio_pin_write(FPGA_P1_2_PIN, 1);
}

void fpga_1_2PowerDisable(void)
{
	nrf_gpio_pin_write(FPGA_P1_2_PIN, 0);
}

void fpga_reset_low(void)
{
	nrf_gpio_pin_write(FPGA_RESET_PIN, 0); // 0917 update for LP
}

void fpga_reset_high(void)
{
	nrf_gpio_pin_write(FPGA_RESET_PIN, 1);
}

void fpga_low_power(void)
{
	nrf_gpio_cfg(FPGA_P1_2_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_CONNECT,
				 NRF_GPIO_PIN_PULLUP,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);
	nrf_gpio_cfg(FPGA_P3_3_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_CONNECT,
				 NRF_GPIO_PIN_PULLUP,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);
}

void fpga_UinitPowerPin(void)
{
	nrf_gpio_pin_write(FPGA_P3_3_PIN, 0);
	nrf_gpio_pin_write(FPGA_P1_2_PIN, 0);
	nrf_gpio_pin_clear(FPGA_P1_2_PIN);
	nrf_gpio_pin_clear(FPGA_P3_3_PIN);
}

void iCE40_InitPins(void)
{
	// initiate sck pin
	nrf_gpio_pin_write(ICE40_SCK_PIN, 1);
	nrf_gpio_cfg(ICE40_SCK_PIN,
				 NRF_GPIO_PIN_DIR_OUTPUT,
				 NRF_GPIO_PIN_INPUT_CONNECT,
				 NRF_GPIO_PIN_NOPULL,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	// init mosi pin
	nrf_gpio_pin_write(ICE40_MOSI_PIN, 0);
	nrf_gpio_cfg(ICE40_MOSI_PIN,
				 NRF_GPIO_PIN_DIR_OUTPUT,
				 NRF_GPIO_PIN_INPUT_DISCONNECT,
				 NRF_GPIO_PIN_NOPULL,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	// init miso pin
	nrf_gpio_cfg(ICE40_MISO_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_CONNECT,
				 NRF_GPIO_PIN_NOPULL,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	// init ss pin
	nrf_gpio_pin_write(ICE40_SS_PIN, 1);
	nrf_gpio_cfg(ICE40_SS_PIN,
				 NRF_GPIO_PIN_DIR_OUTPUT,
				 NRF_GPIO_PIN_INPUT_DISCONNECT,
				 NRF_GPIO_PIN_NOPULL,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	// CRESET Pin Init
	nrf_gpio_pin_write(ICE40_CRESET_PIN, 0);
	nrf_gpio_cfg(ICE40_CRESET_PIN,
				 NRF_GPIO_PIN_DIR_OUTPUT,
				 NRF_GPIO_PIN_INPUT_CONNECT,
				 NRF_GPIO_PIN_NOPULL,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	// CDONE Pin init
	nrf_gpio_cfg(ICE40_CDONE_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_CONNECT,
				 NRF_GPIO_PIN_NOPULL,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);
}

/**************************************************************************
 *Description:uinit the gpio for iCE40 programming
 *Input:
 *Output:
 *Return:nvs initialization error
 *Other:
 *************************************************************************/
void iCE40_UinitPins(void)
{
	nrf_gpio_pin_clear(ICE40_SS_PIN);
	nrf_gpio_pin_clear(ICE40_MISO_PIN);
	nrf_gpio_pin_clear(ICE40_MOSI_PIN);
	nrf_gpio_pin_clear(ICE40_SCK_PIN);
	/*low power test*/
	// 程序下载之后将reset配置为上拉输入，保持高电平同时可以随时进入低功耗
	// 验证过后该方法不行，切换配置的过程中reset引脚会被拉低，导致FPGA跑不起来
	//  nrf_gpio_cfg(ICE40_CRESET_PIN,
	//  		NRF_GPIO_PIN_DIR_INPUT,
	//  		NRF_GPIO_PIN_INPUT_CONNECT,
	//  		NRF_GPIO_PIN_PULLUP,
	//  		NRF_GPIO_PIN_S0S1,
	//  		NRF_GPIO_PIN_NOSENSE);
}

void gpio_low_power(void)
{
	nrf_gpio_cfg(ICE40_SCK_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_DISCONNECT,
				 NRF_GPIO_PIN_PULLDOWN,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	nrf_gpio_cfg(ICE40_MOSI_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_DISCONNECT,
				 NRF_GPIO_PIN_PULLDOWN,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	nrf_gpio_cfg(ICE40_MISO_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_DISCONNECT,
				 NRF_GPIO_PIN_PULLDOWN,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	nrf_gpio_cfg(ICE40_SS_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_DISCONNECT,
				 NRF_GPIO_PIN_PULLDOWN,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	nrf_gpio_cfg(ICE40_CRESET_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_DISCONNECT,
				 NRF_GPIO_PIN_PULLDOWN,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	nrf_gpio_cfg(ICE40_CDONE_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_DISCONNECT,
				 NRF_GPIO_PIN_PULLDOWN,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	nrf_gpio_cfg(FPGA_P1_2_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_DISCONNECT,
				 NRF_GPIO_PIN_PULLDOWN,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	nrf_gpio_cfg(FPGA_P3_3_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_DISCONNECT,
				 NRF_GPIO_PIN_PULLDOWN,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	nrf_gpio_cfg(FPGA_RESET_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_DISCONNECT,
				 NRF_GPIO_PIN_PULLDOWN,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);
}

void gpio_no_pull(void)
{
	nrf_gpio_cfg(ICE40_SCK_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_DISCONNECT,
				 NRF_GPIO_PIN_PULLUP,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	nrf_gpio_cfg(ICE40_MOSI_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_DISCONNECT,
				 NRF_GPIO_PIN_PULLUP,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	nrf_gpio_cfg(ICE40_MISO_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_DISCONNECT,
				 NRF_GPIO_PIN_PULLUP,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	nrf_gpio_cfg(ICE40_SS_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_DISCONNECT,
				 NRF_GPIO_PIN_PULLUP,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	nrf_gpio_cfg(ICE40_CRESET_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_DISCONNECT,
				 NRF_GPIO_PIN_PULLUP,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	nrf_gpio_cfg(ICE40_CDONE_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_DISCONNECT,
				 NRF_GPIO_PIN_PULLUP,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	nrf_gpio_cfg(FPGA_P1_2_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_DISCONNECT,
				 NRF_GPIO_PIN_NOPULL,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	nrf_gpio_cfg(FPGA_P3_3_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_DISCONNECT,
				 NRF_GPIO_PIN_NOPULL,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	nrf_gpio_cfg(FPGA_RESET_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_DISCONNECT,
				 NRF_GPIO_PIN_NOPULL,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);
}

void fpga_spi_gpio_low_power(void)
{
	nrf_gpio_pin_write(ICE40_SCK_PIN, 0);
	nrf_gpio_cfg(ICE40_SCK_PIN,
				 NRF_GPIO_PIN_DIR_OUTPUT,
				 NRF_GPIO_PIN_INPUT_CONNECT,
				 NRF_GPIO_PIN_NOPULL,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	// init mosi pin
	nrf_gpio_pin_write(ICE40_MOSI_PIN, 0);
	nrf_gpio_cfg(ICE40_MOSI_PIN,
				 NRF_GPIO_PIN_DIR_OUTPUT,
				 NRF_GPIO_PIN_INPUT_DISCONNECT,
				 NRF_GPIO_PIN_NOPULL,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	// init miso pin
	nrf_gpio_cfg(ICE40_MISO_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_CONNECT,
				 NRF_GPIO_PIN_NOPULL,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	// init ss pin
	nrf_gpio_pin_write(ICE40_SS_PIN, 0);
	nrf_gpio_cfg(ICE40_SS_PIN,
				 NRF_GPIO_PIN_DIR_OUTPUT,
				 NRF_GPIO_PIN_INPUT_DISCONNECT,
				 NRF_GPIO_PIN_NOPULL,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	nrf_gpio_pin_clear(ICE40_SS_PIN);
	nrf_gpio_pin_clear(ICE40_MISO_PIN);
	nrf_gpio_pin_clear(ICE40_MOSI_PIN);
	nrf_gpio_pin_clear(ICE40_SCK_PIN);
	// nrf_gpio_cfg(ICE40_SCK_PIN,
	// 			 NRF_GPIO_PIN_DIR_INPUT,
	// 			 NRF_GPIO_PIN_INPUT_DISCONNECT,
	// 			 NRF_GPIO_PIN_PULLDOWN,
	// 			 NRF_GPIO_PIN_S0S1,
	// 			 NRF_GPIO_PIN_NOSENSE);

	// nrf_gpio_cfg(ICE40_MOSI_PIN,
	// 			 NRF_GPIO_PIN_DIR_INPUT,
	// 			 NRF_GPIO_PIN_INPUT_DISCONNECT,
	// 			 NRF_GPIO_PIN_PULLDOWN,
	// 			 NRF_GPIO_PIN_S0S1,
	// 			 NRF_GPIO_PIN_NOSENSE);

	// nrf_gpio_cfg(ICE40_MISO_PIN,
	// 			 NRF_GPIO_PIN_DIR_INPUT,
	// 			 NRF_GPIO_PIN_INPUT_DISCONNECT,
	// 			 NRF_GPIO_PIN_PULLDOWN,
	// 			 NRF_GPIO_PIN_S0S1,
	// 			 NRF_GPIO_PIN_NOSENSE);

	// nrf_gpio_cfg(ICE40_SS_PIN,
	// 			 NRF_GPIO_PIN_DIR_INPUT,
	// 			 NRF_GPIO_PIN_INPUT_DISCONNECT,
	// 			 NRF_GPIO_PIN_PULLDOWN,
	// 			 NRF_GPIO_PIN_S0S1,
	// 			 NRF_GPIO_PIN_NOSENSE);
}

void fpga_spi_gpio_no_pull(void)
{
	// nrf_gpio_cfg(ICE40_SCK_PIN,
	// 			 NRF_GPIO_PIN_DIR_INPUT,
	// 			 NRF_GPIO_PIN_INPUT_DISCONNECT,
	// 			 NRF_GPIO_PIN_PULLUP,
	// 			 NRF_GPIO_PIN_S0S1,
	// 			 NRF_GPIO_PIN_NOSENSE);

	// nrf_gpio_cfg(ICE40_MOSI_PIN,
	// 			 NRF_GPIO_PIN_DIR_INPUT,
	// 			 NRF_GPIO_PIN_INPUT_DISCONNECT,
	// 			 NRF_GPIO_PIN_PULLUP,
	// 			 NRF_GPIO_PIN_S0S1,
	// 			 NRF_GPIO_PIN_NOSENSE);

	// nrf_gpio_cfg(ICE40_MISO_PIN,
	// 			 NRF_GPIO_PIN_DIR_INPUT,
	// 			 NRF_GPIO_PIN_INPUT_DISCONNECT,
	// 			 NRF_GPIO_PIN_PULLUP,
	// 			 NRF_GPIO_PIN_S0S1,
	// 			 NRF_GPIO_PIN_NOSENSE);

	// nrf_gpio_cfg(ICE40_SS_PIN,
	// 			 NRF_GPIO_PIN_DIR_INPUT,
	// 			 NRF_GPIO_PIN_INPUT_DISCONNECT,
	// 			 NRF_GPIO_PIN_PULLUP,
	// 			 NRF_GPIO_PIN_S0S1,
	// 			 NRF_GPIO_PIN_NOSENSE);
	nrf_gpio_cfg(ICE40_SCK_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_DISCONNECT,
				 NRF_GPIO_PIN_NOPULL,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	nrf_gpio_cfg(ICE40_MOSI_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_DISCONNECT,
				 NRF_GPIO_PIN_NOPULL,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	nrf_gpio_cfg(ICE40_MISO_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_DISCONNECT,
				 NRF_GPIO_PIN_NOPULL,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);

	nrf_gpio_cfg(ICE40_SS_PIN,
				 NRF_GPIO_PIN_DIR_INPUT,
				 NRF_GPIO_PIN_INPUT_DISCONNECT,
				 NRF_GPIO_PIN_NOPULL,
				 NRF_GPIO_PIN_S0S1,
				 NRF_GPIO_PIN_NOSENSE);
}

/**************************************************************************
 *Description: send clock
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
void SendClocks(int numClock)
{
	for (int i = 0; i < numClock; i++)
	{
		nrf_gpio_pin_write(ICE40_SCK_PIN, PIN_SET_LOW);	 // Set SPI_CLK low
		k_sleep(K_NSEC(50));							 // Delay 50 nsec
		nrf_gpio_pin_write(ICE40_SCK_PIN, PIN_SET_HIGH); // Set SPI_CLK high
		k_sleep(K_NSEC(50));							 // Delay 50 nsec
	}
}

/**************************************************************************
 *Description: Delay function via NOP
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
static void delay(int count)
{
	for (int i = 0; i < count; i++)
	{
		__NOP();
	}
}

/**************************************************************************
 *Description:GPIO simulates SPI communication;Send one byte
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
void iCE40_SendByte(uint8_t value)
{
	NRF_GPIO_Type *reg = NRF_P0;

	for (uint8_t i = 0; i < 8; i++)
	{
		// set MOSI
		if (value & (1 << (7 - i)))
		{
			// nrf_gpio_pin_set(NRFX_SPIM_MOSI_PIN);
			reg->OUTSET = 1UL << ICE40_MOSI_PIN;
		}
		else
		{
			// nrf_gpio_pin_clear(NRFX_SPIM_MOSI_PIN);
			reg->OUTCLR = 1UL << ICE40_MOSI_PIN;
		}

		// nrf_gpio_pin_clear(ICE40_SCK_PIN);
		reg->OUTCLR = 1UL << ICE40_SCK_PIN;
		delay(2);

		// nrf_gpio_pin_set(ICE40_SCK_PIN);
		reg->OUTSET = 1UL << ICE40_SCK_PIN;
	}
}

/**************************************************************************
 *Description: MCU sends a programmable file to the FPGA
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
nvsStatus_t iCE40_SendProgrammeFile(void)
{
	nvsStatus_t status = nvsStatus_Success;
	int rc = 0;

	uint16_t spimWriteLen = ICE40_TX_BUF_SIZE;
	for (int i = 3; i <= flash_Para.frameCount; i++)
	{
		if (i == flash_Para.frameCount)
		{
			spimWriteLen = flash_Para.lastFrameBytes;
		}
		rc = nvs_read(&fs, i, &ice40_tx_buf, ICE40_TX_BUF_SIZE);
		if (rc <= 0)
		{
			return nvsStatus_InvalidAddrss;
		}

		for (int j = 0; j < spimWriteLen; j++)
		{
			iCE40_SendByte(ice40_tx_buf[j]);
		}
	}
	return status;
}

/**************************************************************************
 *Description: process to update the iCE40
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
nvsStatus_t iCE40_Programme(void)
{
	nvsStatus_t status = nvsStatus_Success;
	// Reset the iCE40 Device
	nrf_gpio_pin_write(ICE40_SS_PIN, PIN_SET_LOW);	   // Set SPI_SS low
	nrf_gpio_pin_write(ICE40_CRESET_PIN, PIN_SET_LOW); // Set CRESET low
	nrf_gpio_pin_write(ICE40_SCK_PIN, PIN_SET_HIGH);   // Set SPI_CLK high
	k_sleep(K_NSEC(200));							   // Delay minimum 200 nsec

	nrf_gpio_pin_write(ICE40_CRESET_PIN, PIN_SET_HIGH); // Set CRESET high
	// nrf_gpio_pin_write(NRFX_SPIM_CRESET_PIN, PIN_SET_LOW);// Set CRESET low

	k_sleep(K_USEC(1200));							// Delay 1200 usec
	nrf_gpio_pin_write(ICE40_SS_PIN, PIN_SET_HIGH); // Set SPI_SS high
	SendClocks(8);									// Send 8 clocks
	nrf_gpio_pin_write(ICE40_SS_PIN, PIN_SET_LOW);	// Set SPI_SS low

	// Send bin file
	status = iCE40_SendProgrammeFile();
	if (nvsStatus_Success == status)
	{
		SendClocks(100); // Send 100 clocks

		// Verify successful configuration
		nrf_gpio_pin_write(ICE40_SS_PIN, PIN_SET_HIGH); // Set SPI_SS high
		if (nrf_gpio_pin_read(ICE40_CDONE_PIN))
		{
			status = nvsStatus_Success;
		}
		else
		{
			status = nvsStatus_ConfigError;
		}
	}
	return status;
}

/**************************************************************************
 *Description: iCE40 configuration
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
nvsStatus_t iCE40_Configuration(void)
{
	nvsStatus_t status = nvsStatus_Success;
	int rc = 0;

	rc = nvs_read(&fs, FLASH_FRAME_COUNT, &flash_Para.frameCount, sizeof(flash_Para.frameCount));
	if (rc < 0)
	{
		return nvsStatus_InvalidFrameCount;
	}

	rc = nvs_read(&fs, FLASH_LAST_FRAME_BYTES, &flash_Para.lastFrameBytes, sizeof(flash_Para.lastFrameBytes));
	if (rc < 0)
	{
		return nvsStatus_InvalidLastFrameBytes;
	}

	iCE40_InitPins();

	status = iCE40_Programme();

	iCE40_UinitPins();

	return status;
}

/**************************************************************************
 *Description: iCE40 work status test
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
nvsStatus_t iCE40_WorkStatusTest(void)
{
	nvsStatus_t status = nvsStatus_Success;
	uint16_t signalHearder = HEADER_SIGNAL;

	SPI_FpgaData.xfer_done = false;

	memset((void *)&SPI_FpgaData.txBuf, 0, SPI_TX_BUF_SIZE);
	memset((void *)&SPI_FpgaData.rxBuf, 0, SPI_TX_BUF_SIZE);
	SPI_FpgaData.txBuf[0] = 0xE5;
	SPI_FpgaData.txBuf[1] = 0xC7;
	SPI_FpgaData.txBuf[2] = 0x49;
	SPI_FpgaData.txBuf[3] = 0x00;
	BSP_Spim3_TransmitReceive(SPI_FpgaData.txBuf, SPI_TX_BUF_SIZE, SPI_FpgaData.rxBuf, SPI_RX_BUF_SIZE);

	k_sleep(K_MSEC(5000)); // Wait for the FPGA to calculate the threshold

	SPI_FpgaData.xfer_done = false;
	memset((void *)&SPI_FpgaData.txBuf, 0, SPI_TX_BUF_SIZE);
	memset((void *)&SPI_FpgaData.rxBuf, 0, SPI_TX_BUF_SIZE);
	SPI_FpgaData.txBuf[0] = signalHearder;
	SPI_FpgaData.txBuf[1] = signalHearder >> 8;

	BSP_Spim3_TransmitReceive(SPI_FpgaData.txBuf, SPI_TX_BUF_SIZE, SPI_FpgaData.rxBuf, SPI_TX_BUF_SIZE);

	while (!SPI_FpgaData.xfer_done)
	{
		__WFE();
	}

	if ((SPI_FpgaData.rxBuf[2] != 0x91) || (SPI_FpgaData.rxBuf[3] != 0xC6))
	{
		status = nvsStatus_FPGAProcedurError;
	}

	return status;
}

//============================================================================================================
//  End of file
//============================================================================================================