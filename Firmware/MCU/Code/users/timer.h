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
#ifndef __TIMER_H
#define __TIMER_H
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
#include "../users/spi.h"

//---------------------defines------------------------------------------------------------------------------//
#define TIMER3_PERIOD   80


//---------------------definition of data type--------------------------------------------------------------//



//---------------------definition of global variables------------------------------------------------------//
extern struct k_timer spi_data_cap_timer;


//---------------------declaration of global functions -----------------------------------------------------//
uint32_t DDI_TIMER3_Init(void);


//----------------------definitions of functions------------------------------------------------------------//


/**************************************************************************
 *Description:
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/



#endif /*__TIMER_H*/
//============================================================================================================
//  End of file
//============================================================================================================