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
#ifndef _GATT_APP_H_
#define _GATT_APP_H_
//---------------------include------------------------------------------------------------------------------//
#include <zephyr/types.h>
#include <stddef.h>
#include <string.h>
#include <stdint.h>
#include <errno.h>
#include <zephyr/sys/printk.h>
#include <zephyr/logging/log.h>
#include <zephyr/sys/byteorder.h>
#include <zephyr/kernel.h>
#include <zephyr/drivers/gpio.h>
#include <soc.h>

#include <zephyr/bluetooth/bluetooth.h>
#include <zephyr/bluetooth/hci.h>
#include <zephyr/bluetooth/conn.h>
#include <zephyr/bluetooth/uuid.h>
#include <zephyr/bluetooth/gatt.h>

#include <zephyr/settings/settings.h>

#include "../users/CommonFile.h"
#include "../users/timer.h"
#include "../ptx30w/user_ptx30w_app.h"
#include "../users/iCE40.h"
//---------------------defines------------------------------------------------------------------------------//



//---------------------definition of data type--------------------------------------------------------------//



//---------------------definition of global variables------------------------------------------------------//
typedef struct
{
    struct bt_conn *pConnection;

}bmiGATTApp_t;

extern volatile bmiGATTApp_t GATT_app;


//---------------------declaration of global functions -----------------------------------------------------//
void GATTApp_bleInit(void);


//----------------------definitions of functions------------------------------------------------------------//


/**************************************************************************
 *Description:
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/



#endif /* _GATT_APP_H_ */
//============================================================================================================
//  End of file
//============================================================================================================