/************************************************************************************************************
 *  Copyright:
 *  Description:
 *  1.
 *  2.
 *
 *  Version:
 *   Ver  | yyyy-mmm-dd|  Who  | Description of changes
 *   =====|============|=======|==============================================
 *    1.0 | 2023-08-26 |  sgr  | Original Release.
 *   -----|------------|-------|----------------------------------------------
*************************************************************************************************************/

//---------------------include------------------------------------------------------------------------------//
#include "user_ptx30w_app.h"


//---------------------defines------------------------------------------------------------------------------//



//---------------------definition of data type--------------------------------------------------------------//



//---------------------definition of global variables------------------------------------------------------//
ptxSystemStatus_t         	USER_ptx30w_Status;
volatile shtData_t 			SHT_SysData;
//---------------------declaration of global functions -----------------------------------------------------//
#define LOG_MODULE_NAME bmi_ptx30w
LOG_MODULE_REGISTER(LOG_MODULE_NAME);


//----------------------definitions of functions------------------------------------------------------------//
#if 0
static void ptx30wMemoryDump(void);

/**************************************************************************
 *Description:Output all memory information of PTX30
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
static void ptx30wMemoryDump(void)
{
	ptxStatus_t status = ptxStatus_Success;
	uint16_t data[8];

	for (uint16_t i = 0x800; (i < 0xfff) && (ptxStatus_Success == status); i += 8)
	{
		status = ptx30wHip_ReadCodeMemory(i, &data[0], 8);
		LOG_INF("/* 0x%04X:*/ 0x%04X, 0x%04X, 0x%04X, 0x%04X, 0x%04X, 0x%04X, 0x%04X,0x%04X ,0x%04X\n", i,data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7],status);
	}
}
#endif

/**************************************************************************
 *Description:
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
uint16_t adcToMv(uint8_t adcVal)
{
    return (uint16_t) ( PTX30W_VMON_OFFSET_MV + ( (((uint16_t) adcVal) * PTX30W_VMON_UV_PER_LSB) / 10U) );
}


/**************************************************************************
 *Description:init ptx30w and print version information
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
ptxStatus_t PTX30W_Init(void)
{
	ptxStatus_t status;
    ptxDeviceInformation_t deviceInfo;

	status = ptx30w_Init(0x4B, true, true);

	ptxDeviceInformation_t device_information;
    memset(&device_information, 0, sizeof(ptxDeviceInformation_t));

    if (ptxStatus_WrongHardware != status)
	{
		/*Read hardware version */
		status = ptx30wHip_ReadDataMemory(0x37, &deviceInfo.HardwareVersion, 1);

		if (ptxStatus_Success == status)
		{
			/*Read software version*/
			status = ptx30wHip_ReadCodeMemory(0xFEC, &deviceInfo.FirmwareVersion, 1);
			LOG_INF("PTX HW version: %x PTX FW version: %x status: %d",deviceInfo.HardwareVersion,deviceInfo.FirmwareVersion,status);
		}
		else
		{
			LOG_ERR("PTX init failed");
		}
	}

	// ptx30wMemoryDump();

	return status;
}

ptxStatus_t IIC_LowPower(void)
{
	ptxStatus_t status;
	status = ptxPlat_I2C_Deinit();
	return status;
}

/**************************************************************************
 *Description:get ptx30W status
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
ptxStatus_t PTX30W_readSystemStatus(void)
{
	ptxStatus_t status;

	status = ptx30w_GetSystemStatus(&USER_ptx30w_Status);

	return status;
}

/**************************************************************************
 *Description:power off
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
void PTX30W_powerOff(void)
{
	ptx30w_EnterShippingMode();
}

/**************************************************************************
 *Description:power off
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
ptxStatus_t PTX30W_DisableShippingMode(void)
{
	ptxRuntimeParam_t parameters[1];
    memset(parameters, 0, sizeof(parameters));

    parameters[0].Type = NscParamType_ShippingModeEnable;
    parameters[0].Value = 0u;

    ptxStatus_t status = ptx30wNsc_WriteRuntimeParameters(parameters, 1);

    return status;
}

shtStatus_t sht4x_read_temp_humid(void){
    shtStatus_t status = ntcStatus_Success;
	uint8_t receive_data[6];
    uint32_t temprature_byte;
    uint32_t humidity_byte;

	sht40_I2C_TRx(SHT4X_CMD_MEASURE_LPM, receive_data);
	temprature_byte = receive_data[0]<<8 | receive_data[1];
    humidity_byte = receive_data[3]<<8 | receive_data[4];

    SHT_SysData.temperature = -45 + 175 * temprature_byte/65535.0;
    SHT_SysData.humidity = -6 + 125 * humidity_byte/65535.0;

    return status;
}

//============================================================================================================
//  End of file
//============================================================================================================