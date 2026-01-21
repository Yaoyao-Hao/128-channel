/************************************************************************************************************
 *  Copyright:
 *  Description:
 *  1.
 *  2.
 *
 *  Version:
 *   Ver  | yyyy-mmm-dd|  Who  | Description of changes
 *   =====|============|=======|==============================================
 *    1.0 | 2023-08-24 |  sgr  | Original Release.
 *   -----|------------|-------|----------------------------------------------
 *************************************************************************************************************/

//---------------------include------------------------------------------------------------------------------//
#include "deviceinfo_service.h"

//---------------------defines------------------------------------------------------------------------------//
#define BT_UUID_DEVICEINFO_SERVICE BT_UUID_DECLARE_128(DEVICEINFO_SERVICE_UUID)
#define BT_UUID_DEVICEINFO_SERVICE_STATUS_INFO BT_UUID_DECLARE_128(STATUS_INFO_CHARACTERISTIC_UUID)
#define BT_UUID_DEVICEINFO_SERVICE_POWER_CONTROL BT_UUID_DECLARE_128(POWER_CONTROL_CHARACTERISTIC_UUID)

//---------------------definition of data type--------------------------------------------------------------//

//---------------------definition of global variables------------------------------------------------------//
volatile deviceInfo_t BLE_deviceInfoSvc;
static uint8_t m_tx_data[STATUS_INFO_SIZE_MAX];

//---------------------declaration of global functions -----------------------------------------------------//
LOG_MODULE_DECLARE(bmi_ble);

void pack_float(float val, uint8_t *p_data)
{
    uint32_t *val_ptr = (uint32_t *)&val;
    uint32_t int_val = *val_ptr;

    p_data[0] = (int_val >> 24) & 0xFF;
    p_data[1] = (int_val >> 16) & 0xFF;
    p_data[2] = (int_val >> 8) & 0xFF;
    p_data[3] = int_val & 0xFF;
}

void pack_u16(uint16_t val, uint8_t *p_data)
{
    p_data[0] = (val >> 8) & 0xFF;
    p_data[1] = val & 0xFF;
}

bool bmi_pdu_pack(uint8_t opcode, uint16_t *offset, uint8_t *p_data, uint16_t data_len)
{
    // Pack data
    m_tx_data[(*offset)++] = opcode;
    memcpy(&m_tx_data[*offset], p_data, data_len);
    (*offset) += data_len;

    return true;
}

//----------------------definitions of functions------------------------------------------------------------//
/**************************************************************************
 *Other:This function is called whenever the CCCD register has been changed by the client
 *************************************************************************/
void status_info_ccc_cfg_changed(const struct bt_gatt_attr *attr, uint16_t value)
{
    ARG_UNUSED(attr);

    BLE_deviceInfoSvc.statusInfoNotifyEnable = (value == BT_GATT_CCC_NOTIFY);
}

/**************************************************************************
 *Description:Receive commands sent from the PC to the FPGA
 *Input:
 *Output:
 *Return:
 *Other: Characteristic Attribute write callback
 *************************************************************************/
static ssize_t DEVICEINFOSVC_ReadStatusInfo(struct bt_conn *conn,
                                            const struct bt_gatt_attr *attr,
                                            void *buf, uint16_t len, uint16_t offset)
{
    k_event_post(&event_flags, EVENT_READ_DEVICE_STATUS);
    return BT_GATT_ERR(BT_ATT_ERR_SUCCESS);
}

/**************************************************************************
 *Description:Receive commands sent from the PC to the FPGA
 *Input:
 *Output:
 *Return:
 *Other: Send WireIn and TriggerIn command to FPGA
 *************************************************************************/
static ssize_t DEVICEINFOSVC_WritePowerControl(struct bt_conn *conn,
                                               const struct bt_gatt_attr *attr,
                                               const void *buf, uint16_t len, uint16_t offset,
                                               uint8_t flags)
{
    const uint8_t buffer = *((uint8_t *)buf);
    if (buffer == 1)
    {
        LOG_INF("receive DEVICEINFOSVC_WritePowerControl character data %d", buffer);
        k_event_post(&event_flags, EVENT_POWER_DOWN);
    }
    else
    {
        return BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET);
    }

    return BT_GATT_ERR(BT_ATT_ERR_SUCCESS);
}

/************************************************************************************************************
 *  Description:register service
 *
 *  Attribute table:
 *   attr  | Description
 *   ======|===================================================================
 *    0    | Service declaration attribute (service declaration has only one attribute)
 *
 *    1    | BT_UUID_DEVICEINFO_SERVICE_STATUS_INFO characteristic declaration attribute
 *    2    | Characteristic value for the above characteristic declaration.
 *    3    | status_info_ccc_cfg_changed declaration attribute.
 *
 *    4    | BT_UUID_DEVICEINFO_SERVICE_POWER_CONTROL declaration attribute.
 *    5    | Characteristic value for the above characteristic declaration.
 *************************************************************************************************************/
BT_GATT_SERVICE_DEFINE(deviceinfo_service,
                       BT_GATT_PRIMARY_SERVICE(BT_UUID_DEVICEINFO_SERVICE),
                       BT_GATT_CHARACTERISTIC(BT_UUID_DEVICEINFO_SERVICE_STATUS_INFO,
                                              (BT_GATT_CHRC_READ | BT_GATT_CHRC_NOTIFY),
                                              BT_GATT_PERM_READ | BT_GATT_PERM_WRITE,
                                              DEVICEINFOSVC_ReadStatusInfo, NULL, NULL),
                       BT_GATT_CCC(status_info_ccc_cfg_changed,
                                   BT_GATT_PERM_READ | BT_GATT_PERM_WRITE),

                       BT_GATT_CHARACTERISTIC(BT_UUID_DEVICEINFO_SERVICE_POWER_CONTROL,
                                              (BT_GATT_CHRC_WRITE | BT_GATT_CHRC_WRITE_WITHOUT_RESP),
                                              BT_GATT_PERM_READ | BT_GATT_PERM_WRITE,
                                              NULL, DEVICEINFOSVC_WritePowerControl, NULL), );

/**************************************************************************
 *Description:
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
void DEVICEINFOSVC_StatusInfoNfy(struct bt_conn *conn, const uint8_t *data, uint16_t len)
{
    const struct bt_gatt_attr *attr = &deviceinfo_service.attrs[ATTR_DEVICEINFO_SERVICE_STATUS_INFO_CHARACTERISTIC_DECLARA];

    struct bt_gatt_notify_params params =
        {
            .uuid = BT_UUID_DEVICEINFO_SERVICE_STATUS_INFO,
            .attr = attr,
            .data = data,
            .len = len,
            .func = NULL};

    // Check whether notifications are enabled or not
    if (bt_gatt_is_subscribed(conn, attr, BT_GATT_CCC_NOTIFY))
    {
        // Send the notification
        if (bt_gatt_notify_cb(conn, &params))
        {
            LOG_ERR("Error, unable to send notification\n");
        }
    }
}

void DEVICEINFO_DataNfy(void)
{
    uint16_t offset = 0;
    uint8_t data[4];

    pack_u16(USER_ptx30w_Status.VddBat, &data[0]);
    bmi_pdu_pack(0x00, &offset, data, sizeof(uint16_t));
    bmi_pdu_pack(0x01, &offset, (uint8_t *)&USER_ptx30w_Status.ChargerEnabled, sizeof(uint8_t));
    pack_float(SHT_SysData.temperature, &data[0]);
    bmi_pdu_pack(0x02, &offset, data, sizeof(float));
    pack_float(SHT_SysData.humidity, &data[0]);
    bmi_pdu_pack(0x03, &offset, data, sizeof(float));

    DEVICEINFOSVC_StatusInfoNfy(GATT_app.pConnection, (const uint8_t *)&m_tx_data, offset);
}

//============================================================================================================
//  End of file
//============================================================================================================