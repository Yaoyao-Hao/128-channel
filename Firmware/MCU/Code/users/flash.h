/************************************************************************************************************
 *  Copyright:
 *  Description:
 *  1.
 *  2.
 *
 *  Version:
 *   Ver  | yyyy-mmm-dd|  Who  | Description of changes
 *   =====|============|=======|==============================================
 *    1.0 | 2023-07-28 |  sgr  | Original Release.
 *   -----|------------|-------|----------------------------------------------
*************************************************************************************************************/
#ifndef _FLASH_H_
#define _FLASH_H_
//---------------------include------------------------------------------------------------------------------//
#include <zephyr/kernel.h>
#include <zephyr/sys/reboot.h>
#include <string.h>
#include <zephyr/drivers/flash.h>
#include <zephyr/storage/flash_map.h>
#include <zephyr/fs/nvs.h>
#include <zephyr/logging/log.h>

//---------------------defines------------------------------------------------------------------------------//
#define NVS_PARTITION		    user_storage
#define NVS_PARTITION_DEVICE	FIXED_PARTITION_DEVICE(NVS_PARTITION)
#define NVS_PARTITION_OFFSET	FIXED_PARTITION_OFFSET(NVS_PARTITION)


#define FLASH_FRAME_COUNT 		1	/*flash ID 1 stores fpga bin file's packages number*/
#define FLASH_LAST_FRAME_BYTES 	2	/*flash ID 2 stores the number of bytes in the last frame*/

//---------------------definition of data type--------------------------------------------------------------//
typedef struct
{
    uint16_t        frameCount;
    uint8_t         lastFrameBytes;

}bmiNvs_t;

typedef enum nvsStatus_Values
{
    nvsStatus_Success,                 /**< Internal The operation completed successfully. */
    nvsStatus_InvalidAddrss,        /**< Invalid value(s) for function parameter(s). */
    nvsStatus_ConfigError,           /**< There has been internal error in the function processing. */
    nvsStatus_InvalidFrameCount,          /**< The function/command is not implemented. */
    nvsStatus_InvalidLastFrameBytes,                 /**< The operation has timed out. */
    nvsStatus_FPGAProcedurError,          /**< The interface (I/O line, UART, ...) is not accessible or an error
                                             has occurred. */
    nvsStatus_DeviceError,            /**< The operation is not permitted. */
    nvsStatus_InvalidFlashPage,        /**< Error at NSC protocol. */
    nvsStatus_NvsMountError,   /**< Insufficient Resources Error. */
    nvsStatus_NvsClearError
} nvsStatus_t;

//---------------------definition of global variables------------------------------------------------------//
extern bmiNvs_t	flash_Para;
extern struct nvs_fs fs;


//---------------------declaration of global functions -----------------------------------------------------//
nvsStatus_t fs_init(void);
nvsStatus_t fs_clear(void);

//----------------------definitions of functions------------------------------------------------------------//



#endif /* _FLASH_H_ */ 
//============================================================================================================
//  End of file
//============================================================================================================