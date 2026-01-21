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
#ifndef _ICE40_UPDATE_SERVICE_H_
#define _ICE40_UPDATE_SERVICE_H_
//---------------------include------------------------------------------------------------------------------//
#include <zephyr/types.h>
#include <stddef.h>
#include <string.h>
#include <errno.h>
#include <zephyr/kernel.h>
#include <soc.h>

#include <zephyr/bluetooth/bluetooth.h>
#include <zephyr/bluetooth/hci.h>
#include <zephyr/bluetooth/conn.h>
#include <zephyr/bluetooth/uuid.h>
#include <zephyr/bluetooth/gatt.h>

#include <zephyr/sys/reboot.h>
#include <zephyr/device.h>
#include <zephyr/drivers/flash.h>
#include <zephyr/storage/flash_map.h>
#include <zephyr/fs/nvs.h>
#include <zephyr/logging/log.h>

//---------------------defines------------------------------------------------------------------------------//
#define ICE40_UPDATE_SERVICE_UUID \
	BT_UUID_128_ENCODE(0xf046097f, 0xa921, 0x431c, 0xa749, 0x81d17f1add88)

#define RX_CHARACTERISTIC_UUID \
	BT_UUID_128_ENCODE(0x39ce7243, 0xd128, 0x48f6, 0x8a0b, 0x0d32f948e464)

#define FLAG_CHARACTERISTIC_UUID \
    BT_UUID_128_ENCODE(0xc3a02d50, 0xa3d7, 0x4e5d, 0xb8b2, 0xd7b34655023e)

#define FPGA_FILE_RECEIVE_START     0
#define FPGA_FILE_RECEIVE_STOP      1

//---------------------definition of data type--------------------------------------------------------------//
/** @brief Callback type for when new data is received. */
typedef void (*data_rx_cb_t)(uint8_t *data, uint8_t length);

/** @brief Callback struct used by the my_service Service. */
struct iCE40_service_cb 
{
	/** Data received callback. */
	data_rx_cb_t    data_rx_cb;

	int (*rxReceived)(struct bt_conn *conn,
			 const uint8_t *data, uint16_t len);

	int (*flagReceived)(struct bt_conn *conn,
			 const uint8_t *data, uint16_t len);
};

typedef struct
{
    uint16_t        nvs_id;
	bool 			fileReceiveFinishFlag;
	bool			frameReceiveFinishFlag;
	bool			frameNvsWriteFinishFlag;

	uint8_t     	fileValue[256];
	bool			start;
}bmiFlashSVC_t;

//---------------------definition of global variables------------------------------------------------------//
extern bmiFlashSVC_t	FPGA_UPDATE_State;


//---------------------declaration of global functions -----------------------------------------------------//



//----------------------definitions of functions------------------------------------------------------------//
int bt_iCE40s_init(struct iCE40_service_cb  *callbacks);

void iCE40_update_service_send(struct bt_conn *conn, const uint8_t *data, uint16_t len);

#endif /* _ICE40_UPDATE_SERVICE_H_ */                   
//============================================================================================================
//  End of file
//============================================================================================================