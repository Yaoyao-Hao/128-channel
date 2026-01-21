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
#ifndef _FPGA_RELATED_SERVICE_H_
#define _FPGA_RELATED_SERVICE_H_
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

#include "../services/gattapp.h"
#include "../users/CommonFile.h"
#include "../users/spi.h"
#include "../users/timer.h"
#include "../users/iCE40.h"

//---------------------defines------------------------------------------------------------------------------//
#define FPGA_RELATED_SERVICE_UUID \
    BT_UUID_128_ENCODE(0x230b741d, 0x26cf, 0x4daa, 0xac6c, 0x802f5de699be)

#define SIGNAL_CHARACTERISTIC_UUID \
    BT_UUID_128_ENCODE(0x8a2c6538, 0x4041, 0x5d83, 0x906c, 0x0408bfc7e4f9)

#define CMD_CHARACTERISTIC_UUID \
    BT_UUID_128_ENCODE(0x1f393840, 0x1711, 0x5955, 0x86e6, 0xc1b77090e7fe)

#define THRESHOLD_CHARACTERISTIC_UUID \
    BT_UUID_128_ENCODE(0x88925663, 0xd236, 0x4757, 0xa167, 0x4a7d58637b24)

//---------------------definition of data type--------------------------------------------------------------//
#define ATTR_FPGA_RELATED_SERVICE 0
#define ATTR_FPGA_RELATED_SERVICE_SIGNAL_CHARACTER_DECLARA 1
#define ATTR_FPGA_RELATED_SERVICE_SIGNAL_CHARACTER_VALUE 2
#define ATTR_FPGA_RELATED_SERVICE_SIGNAL_CCC 3
#define ATTR_FPGA_RELATED_SERVICE_CMD_CHARACTER_DECLARA 4
#define ATTR_FPGA_RELATED_SERVICE_CMD_CHARACTER_VALUE 5
#define ATTR_FPGA_RELATED_SERVICE_CMD_CCC 6
#define ATTR_FPGA_RELATED_SERVICE_THRESHOLD_CHARACTER_DECLARA 7
#define ATTR_FPGA_RELATED_SERVICE_THRESHOLD_CHARACTER_VALUE 8
#define ATTR_FPGA_RELATED_SERVICE_THRESHOLD_CCC 9

#define BMI_FPGA_CMD_BUF_SIZE_MAX 66

#define BMI_FPGA_SIGNAL_BUF_SIZE_MAX 386 // for test
#define BMI_FPGA_SIGNAL_BUF_OFFSET 2
#define BMI_FPGA_SIGNAL_RAW_LEN 258
#define BMI_FPGA_SIGNAL_SPIKE_LEN 128
#define BMI_FPGA_SIGNAL_RAW_OFFSET 19
#define BMI_FPGA_SIGNAL_SPIKE_OFFSET 261

#define BMI_FPGA_THRESHOLD_BUF_OFFSET 7
#define BMI_FPGA_THRESHOLD_BUF_SIZE_MAX 128 // for test

#define SIGNAL_CHANNEL_STOP_COLLECT 0x00
#define SIGNAL_CHANNEL_START_COLLECT 0x01
#define SIGNAL_CHANNEL_START_FPGA 0x02
#define SIGNAL_CHANNEL_STOP_FPGA 0x03
#define SIGNAL_CHANNEL_START_IMPTEST 0x04
#define SIGNAL_CHANNEL_STOP_IMPTEST 0x05

#define FPGA_BUSY true
#define FPGA_IDLE false

#define NOTIFY_SIGNAL_RAW_SPIKE 0x01
#define NOTIFY_SIGNAL_RAW 0x02
#define NOTIFY_SIGNAL_SPIKE 0x03
//---------------------definition of global variables------------------------------------------------------//
typedef struct
{
    bool signalNotifyEnable;
    bool cmdNotifyEnable;
    bool thresholdNotifyEnable;

    bool fpgaBusyState;

    bool timerEnableFlag;
    bool thresholdEnableFlag;

    uint8_t nfyType;
} fpgaRelated_t;

extern volatile fpgaRelated_t BLE_fpgaSvc;
//---------------------declaration of global functions -----------------------------------------------------//
void FPGASVC_SignalNfy(struct bt_conn *conn, const uint8_t *data, uint16_t len);
void FPGASVC_CmdNfy(struct bt_conn *conn, const uint8_t *data, uint16_t len);
void FPGASVC_DataProsess(void);
void FPGASVC_FPGASTART_Nfy(void);
void FPGASVC_SignalNfy(struct bt_conn *conn, const uint8_t *data, uint16_t len);
void FPGASVC_CmdNfy(struct bt_conn *conn, const uint8_t *data, uint16_t len);
void FPGASVC_ThresholdNfy(struct bt_conn *conn, const uint8_t *data, uint16_t len);

//----------------------definitions of functions------------------------------------------------------------//

#endif /* _FPGA_RELATED_SERVICE_H_ */
       //============================================================================================================
       //  End of file
       //============================================================================================================