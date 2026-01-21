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
#ifndef _DEVICE_INFO_SERVICE_H_
#define _DEVICE_INFO_SERVICE_H_
//---------------------include------------------------------------------------------------------------------//
#include <zephyr/kernel.h>
#include <zephyr/types.h>
#include <stddef.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <errno.h>
#include <soc.h>
#include <zephyr/sys/printk.h>
#include <zephyr/logging/log.h>
#include <zephyr/sys/byteorder.h>


#include <zephyr/bluetooth/bluetooth.h>
#include <zephyr/bluetooth/hci.h>
#include <zephyr/bluetooth/conn.h>
#include <zephyr/bluetooth/uuid.h>
#include <zephyr/bluetooth/addr.h>
#include <zephyr/bluetooth/gatt.h>

#include "../ptx30w/user_ptx30w_app.h"
#include "../services/gattapp.h"
#include "../users/CommonFile.h"


//---------------------defines------------------------------------------------------------------------------//
#define DEVICEINFO_SERVICE_UUID \
	BT_UUID_128_ENCODE(0x855d2600, 0xbdef, 0x51a9, 0xb626, 0x739b4e5b0cd5)

#define STATUS_INFO_CHARACTERISTIC_UUID \
	BT_UUID_128_ENCODE(0x62957be9, 0xeff6, 0x5424, 0x871a, 0xdf61e8ef9653)

#define POWER_CONTROL_CHARACTERISTIC_UUID \
	BT_UUID_128_ENCODE(0x1fae4fa8, 0xbb46, 0x54f8, 0x97d9, 0x675d632ae901)

#define HAEDWARE_REVISION   "V1.0.0"
#define FIRMWARE_REVISION   "V1.0.0"
#define REVISION_NAME_SIZE_MAX  20
#define STATUS_INFO_SIZE_MAX	15
//---------------------definition of data type--------------------------------------------------------------//
#define ATTR_DEVICEINFO_SERVICE                                                 0
#define ATTR_DEVICEINFO_SERVICE_STATUS_INFO_CHARACTERISTIC_DECLARA            	1
#define ATTR_DEVICEINFO_SERVICE_STATUS_INFO_CHARACTERISTIC_VALUE              	2
#define ATTR_DEVICEINFO_SERVICE_STATUS_INFO_CCC                               	3

#define ATTR_DEVICEINFO_SERVICE_POWER_CONTROL_CHARACTERISTIC_DECLARA            4
#define ATTR_DEVICEINFO_SERVICE_POWER_CONTROL_CHARACTERISTIC_VALUE              5
//---------------------definition of global variables------------------------------------------------------//
typedef struct
{
    bool        statusInfoNotifyEnable;
	bool 		chargeEnable;
       
}deviceInfo_t;
extern volatile deviceInfo_t BLE_deviceInfoSvc;

//---------------------declaration of global functions -----------------------------------------------------//



//----------------------definitions of functions------------------------------------------------------------//
void DEVICEINFOSVC_StatusInfoNfy(struct bt_conn *conn, const uint8_t *data, uint16_t len);
void DEVICEINFO_DataNfy(void);

#endif /* _DEVICE_INFO_SERVICE_H_ */                   
//============================================================================================================
//  End of file
//============================================================================================================