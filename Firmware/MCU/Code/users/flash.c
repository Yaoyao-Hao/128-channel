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

//---------------------include------------------------------------------------------------------------------//
#include "flash.h"


//---------------------defines------------------------------------------------------------------------------//



//---------------------definition of data type--------------------------------------------------------------//



//---------------------definition of global variables------------------------------------------------------//
bmiNvs_t	flash_Para;
struct nvs_fs fs;


//---------------------declaration of global functions -----------------------------------------------------//



//----------------------definitions of functions------------------------------------------------------------//


/**************************************************************************
 *Description:
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
nvsStatus_t fs_init(void)
{
	int rc = 0;
	struct flash_pages_info info;
    nvsStatus_t status = nvsStatus_Success;

	/* define the nvs file system by settings with:
	 *	sector_size equal to the pagesize,
	 *	3 sectors
	 *	starting at NVS_PARTITION_OFFSET
	 */
	fs.flash_device = NVS_PARTITION_DEVICE;
	if (!device_is_ready(fs.flash_device)) {
		status = nvsStatus_DeviceError;
		// printk("Flash device %s is not ready\n", fs.flash_device->name);		
	}

	fs.offset = NVS_PARTITION_OFFSET;	
	rc = flash_get_page_info_by_offs(fs.flash_device, fs.offset, &info);
	if (rc) {
		status = nvsStatus_InvalidFlashPage;
		// printk("Unable to get page info\n");
	}
	fs.sector_size = info.size;	
	fs.sector_count = 30U;

	rc = nvs_mount(&fs);
	if (rc) {
		status = nvsStatus_NvsMountError;
		// printk("Flash Init failed\n");		
	}

    return status;
}

/**************************************************************************
 *Description:
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
nvsStatus_t fs_clear(void)
{
    int rc = 0;
    nvsStatus_t status = nvsStatus_Success;

    rc = nvs_clear(&fs);	
	if(rc)
	{
		status = nvsStatus_NvsClearError;	
	}

    rc = nvs_mount(&fs);	//flash清楚区域后重新挂载
	if (rc) {
		status = nvsStatus_NvsMountError;
	}

    return status;
}

//============================================================================================================
//  End of file
//============================================================================================================