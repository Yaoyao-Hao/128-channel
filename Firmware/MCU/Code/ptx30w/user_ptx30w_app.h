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
#ifndef _USER_PTX30W_APP_H_
#define _USER_PTX30W_APP_H_
//---------------------include------------------------------------------------------------------------------//
#include <zephyr/kernel.h>
#include <stdbool.h>
#include <stdint.h>
#include <zephyr/logging/log.h>
#include "../ptx30w/ptx/ptxStatus.h"
#include "../ptx30w/ptx/ptx30w.h"
#include "../ptx30w/plat/ptxPlat.h"
#include "../ptx30w/ptx/ptx30w_ConfigHelper.h"
#include "../ptx30w/ptx/ndef/ptxNDEFRecord_URI.h"
#include "../ptx30w/ptx/ndef/ptxNDEFRecord_Text.h"
#include "../ptx30w/ptx/ndef/ptxNDEFRecord_BT_SP.h"
#include "../ptx30w/ptx/ndef/ptxNDEFMessage.h"
#include "../ptx30w/ptx/ptx30w_Nvm_Int.h"
#include "../ptx30w/ptx/ptx30w_Hip_Int.h"


//---------------------defines------------------------------------------------------------------------------//
#define SHT4X_CMD_MEASURE_HPM (0xFD)
#define SHT4X_CMD_MEASURE_LPM (0xE0)
#define SHT4X_CMD_READ_SERIAL (0x89)

//---------------------definition of data type--------------------------------------------------------------//


//---------------------definition of global variables------------------------------------------------------//
extern ptxSystemStatus_t         USER_ptx30w_Status;

typedef struct
{
    float	temperature;
    float   humidity;
} shtData_t;
extern volatile shtData_t SHT_SysData;
//---------------------declaration of global functions -----------------------------------------------------//



//----------------------definitions of functions------------------------------------------------------------//
uint16_t adcToMv(uint8_t adcVal);
ptxStatus_t PTX30W_Init(void);
ptxStatus_t IIC_LowPower(void);
ptxStatus_t PTX30W_readSystemStatus(void);
void PTX30W_powerOff(void);
ptxStatus_t PTX30W_DisableShippingMode(void);
shtStatus_t sht4x_read_temp_humid(void);





#endif  /*_USER_PTX30W_APP_H_*/
//============================================================================================================
//  End of file
//============================================================================================================