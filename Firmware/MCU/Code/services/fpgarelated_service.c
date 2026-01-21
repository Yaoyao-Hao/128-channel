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

//---------------------include------------------------------------------------------------------------------//
#include "fpgarelated_service.h"

//---------------------defines------------------------------------------------------------------------------//
#define BT_UUID_FPGA_RELATED_SERVICE BT_UUID_DECLARE_128(FPGA_RELATED_SERVICE_UUID)
#define BT_UUID_FPGA_RELATED_SERVICE_SIGNAL BT_UUID_DECLARE_128(SIGNAL_CHARACTERISTIC_UUID)
#define BT_UUID_FPGA_RELATED_SERVICE_CMD BT_UUID_DECLARE_128(CMD_CHARACTERISTIC_UUID)
#define BT_UUID_FPGA_RELATED_SERVICE_THRESHOLD BT_UUID_DECLARE_128(THRESHOLD_CHARACTERISTIC_UUID)

//---------------------definition of data type--------------------------------------------------------------//

//---------------------definition of global variables------------------------------------------------------//
volatile fpgaRelated_t BLE_fpgaSvc;
uint8_t sys_Sta = SYS_STA_INIT;
// struct k_timer threshold_timer;

//---------------------declaration of global functions -----------------------------------------------------//
LOG_MODULE_DECLARE(bmi_ble); // 声明当前文件的日志属于bmi_ble模块

//----------------------definitions of functions------------------------------------------------------------//

/**************************************************************************
 *Other:This function is called whenever the CCCD register has been changed by the client
 *************************************************************************/
void signal_ccc_cfg_changed(const struct bt_gatt_attr *attr, uint16_t value)
{
    ARG_UNUSED(attr);

    BLE_fpgaSvc.signalNotifyEnable = (value == BT_GATT_CCC_NOTIFY);
}

/**************************************************************************
 *Other:This function is called whenever the CCCD register has been changed by the client
 *************************************************************************/
void cmd_ccc_cfg_changed(const struct bt_gatt_attr *attr, uint16_t value)
{
    ARG_UNUSED(attr);

    BLE_fpgaSvc.cmdNotifyEnable = (value == BT_GATT_CCC_NOTIFY);
}

/**************************************************************************
 *Other:This function is called whenever the CCCD register has been changed by the client
 *************************************************************************/
void threshold_ccc_cfg_changed(const struct bt_gatt_attr *attr, uint16_t value)
{
    ARG_UNUSED(attr);

    BLE_fpgaSvc.thresholdNotifyEnable = (value == BT_GATT_CCC_NOTIFY);
}

/**************************************************************************
 *Description:Receive commands sent from the PC to the FPGA
 *Input:
 *Output:
 *Return:
 *Other: Characteristic Attribute write callback
 *************************************************************************/
static ssize_t FPGASVC_AcquireSignals(struct bt_conn *conn,
                                      const struct bt_gatt_attr *attr,
                                      const void *buf, uint16_t len, uint16_t offset,
                                      uint8_t flags)
{
    const uint8_t *buffer = buf;
    uint8_t opcode = 0, value = 0;

    LOG_INF("receive signal character data %d", *buffer);
    if (len == 1)
    {
        opcode = buffer[0];
    }
    else if (len == 2)
    {
        opcode = buffer[0];
        value = buffer[1];
    }
    else
    {
        return BT_GATT_ERR(BT_ATT_ERR_INVALID_ATTRIBUTE_LEN);
    }

    if (opcode == SIGNAL_CHANNEL_START_COLLECT) // 启动采集
    {
        LOG_INF("start com timer nfyType %d", value);
        if (value == 0x01)
        {
            BLE_fpgaSvc.nfyType = NOTIFY_SIGNAL_RAW_SPIKE;
        }
        else if (value == 0x02)
        {
            BLE_fpgaSvc.nfyType = NOTIFY_SIGNAL_RAW;
        }
        else if (value == 0x03)
        {
            BLE_fpgaSvc.nfyType = NOTIFY_SIGNAL_SPIKE;
        }
        else
        {
            BLE_fpgaSvc.nfyType = NOTIFY_SIGNAL_RAW_SPIKE;
        }

        k_timer_start(&spi_data_cap_timer, K_USEC(8300), K_USEC(8300));
        BLE_fpgaSvc.timerEnableFlag = true;
        SPI_FpgaData.xfer_done = false;
    }
    else if (opcode == SIGNAL_CHANNEL_STOP_COLLECT) // 结束采集
    {
        LOG_INF("stop com timer");
        k_timer_stop(&spi_data_cap_timer);
        BLE_fpgaSvc.timerEnableFlag = false;
    }
    else if (opcode == SIGNAL_CHANNEL_START_FPGA) // 启动FPGA
    {
        LOG_INF("start fpga");
        k_event_post(&event_flags, EVENT_FPGA_ENABLE);
    }
    else if (opcode == SIGNAL_CHANNEL_STOP_FPGA) // 关闭FPGA
    {
        LOG_INF("stop fpga");
        k_event_post(&event_flags, EVENT_FPGA_DISABLE);
    }
    else if (opcode == SIGNAL_CHANNEL_START_IMPTEST) // 启动阻抗测试
    {
        BLE_fpgaSvc.nfyType = NOTIFY_SIGNAL_RAW;
        k_timer_start(&spi_data_cap_timer, K_MSEC(8), K_MSEC(8));
        BLE_fpgaSvc.timerEnableFlag = true;
        SPI_FpgaData.xfer_done = false;
    }
    else if (opcode == SIGNAL_CHANNEL_STOP_IMPTEST) // 关闭阻抗测试
    {
        k_timer_stop(&spi_data_cap_timer);
        BLE_fpgaSvc.timerEnableFlag = false;
    }
    else
    {
        return BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET);
    }

    return len;
}

/**************************************************************************
 *Description:Receive commands sent from the PC to the FPGA
 *Input:
 *Output:
 *Return:
 *Other: Send WireIn and TriggerIn command to FPGA
 *************************************************************************/
static ssize_t FPGASVC_WriteCmd(struct bt_conn *conn,
                                const struct bt_gatt_attr *attr,
                                const void *buf, uint16_t len, uint16_t offset,
                                uint8_t flags)
{

    // const uint8_t *buffer = buf;
    // LOG_INF("receive cmd character data %d", *buffer);

    if (offset + len > sizeof(SPI_FpgaData.txBuf))
    {
        return BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET);
    }

    if (SPI_FpgaData.spiInitFlag == true)
    {
        LOG_INF("receive %d data", len);
        memcpy(&SPI_FpgaData.txBuf, buf, len);
        BSP_Spim3_TransmitReceive(SPI_FpgaData.txBuf, len, SPI_FpgaData.rxBuf, len);

        /********************************************0916 teset***********************************************/
        // LOG_HEXDUMP_INF(buf, len, "Received data:");
        /********************************************0916 teset end***********************************************/
    }
    else
    {
        return BT_GATT_ERR(BT_ATT_ERR_WRITE_NOT_PERMITTED);
    }

    return len;
}

/**************************************************************************
 *Description:Receive commands sent from the PC to the FPGA
 *Input:
 *Output:
 *Return:
 *Other: Send WireIn and TriggerIn command to FPGA
 *************************************************************************/
static ssize_t FPGASVC_AcquireThreshold(struct bt_conn *conn,
                                        const struct bt_gatt_attr *attr,
                                        const void *buf, uint16_t len, uint16_t offset,
                                        uint8_t flags)
{
    const uint8_t *buffer = buf;
    uint16_t signalHearder = HEADER_SIGNAL;

    if (*buffer != 0)
    {

        SPI_FpgaData.xfer_done = false;

        memset((void *)&SPI_FpgaData.txBuf, 0, SPI_TX_BUF_SIZE);
        memset((void *)&SPI_FpgaData.rxBuf, 0, SPI_TX_BUF_SIZE);
        SPI_FpgaData.txBuf[0] = signalHearder;
        SPI_FpgaData.txBuf[1] = signalHearder >> 8;
        BSP_Spim3_TransmitReceive(SPI_FpgaData.txBuf, SPI_TX_BUF_SIZE, SPI_FpgaData.rxBuf, SPI_RX_BUF_SIZE);
        while (!SPI_FpgaData.xfer_done)
        {
            __WFE();
        }

        if ((SPI_FpgaData.rxBuf[3] == 0x55) && (SPI_FpgaData.rxBuf[4] == 0xAA))
        {
            FPGASVC_ThresholdNfy(GATT_app.pConnection, &SPI_FpgaData.rxBuf[BMI_FPGA_THRESHOLD_BUF_OFFSET], BMI_FPGA_THRESHOLD_BUF_SIZE_MAX);
        }
        SPI_FpgaData.xfer_done = false;
        return BT_GATT_ERR(BT_ATT_ERR_SUCCESS);
    }
    else
    {
        return BT_GATT_ERR(BT_ATT_ERR_INVALID_HANDLE);
    }
}

/**************************************************************************
 *Description:read threshole callback
 *Input:
 *Output:
 *Return:
 *Other: Send WireIn and TriggerIn command to FPGA
 *************************************************************************/
static ssize_t read_Threshole(struct bt_conn *conn,
                              const struct bt_gatt_attr *attr,
                              void *buf, uint16_t len, uint16_t offset)
{
    uint16_t signalHearder = HEADER_SIGNAL;

    memset(&SPI_FpgaData.txBuf, 0, SPI_TX_BUF_SIZE);
    memset(&SPI_FpgaData.rxBuf, 0, SPI_TX_BUF_SIZE);
    SPI_FpgaData.txBuf[0] = signalHearder;
    SPI_FpgaData.txBuf[1] = signalHearder >> 8;

    BSP_Spim3_TransmitReceive(SPI_FpgaData.txBuf, SPI_TX_BUF_SIZE, SPI_FpgaData.rxBuf, SPI_TX_BUF_SIZE);

    while (!SPI_FpgaData.xfer_done)
    {
        __WFE();
    }
    memcpy(&SPI_FpgaData.thresholdBuf, &SPI_FpgaData.rxBuf, sizeof(SPI_FpgaData.rxBuf));

    bt_gatt_attr_read(conn, attr, buf, len, offset, &SPI_FpgaData.thresholdBuf[BMI_FPGA_THRESHOLD_BUF_OFFSET], BMI_FPGA_THRESHOLD_BUF_SIZE_MAX);

    BLE_fpgaSvc.thresholdEnableFlag = true;

    SPI_FpgaData.xfer_done = false;

    return BT_GATT_ERR(BT_ATT_ERR_SUCCESS);
}

/************************************************************************************************************
 *  Description:register service
 *
 *  Attribute table:
 *   attr  | Description
 *   ======|===================================================================
 *    0    | Service declaration attribute (service declaration has only one attribute)
 *    1    | BT_UUID_FPGA_RELATED_SERVICE_SIGNAL characteristic declaration attribute
 *    2    | Characteristic value for the above characteristic declaration.
 *    3    | signal_ccc_cfg_changed declaration attribute.
 *    4    | BT_UUID_FPGA_RELATED_SERVICE_CMD characteristic declaration attribute
 *    5    | Characteristic value for the above characteristic declaration.
 *    6    | cmd_ccc_cfg_changed declaration attribute.
 *    7    | BT_UUID_FPGA_RELATED_SERVICE_THRESHOLD declaration attribute.
 *    8    | Characteristic value for the above characteristic declaration.
 *    9    | threshold_ccc_cfg_changed declaration attribute.
 *
 *************************************************************************************************************/
BT_GATT_SERVICE_DEFINE(fpgarelated_service,
                       BT_GATT_PRIMARY_SERVICE(BT_UUID_FPGA_RELATED_SERVICE),
                       BT_GATT_CHARACTERISTIC(BT_UUID_FPGA_RELATED_SERVICE_SIGNAL,
                                              (BT_GATT_CHRC_WRITE | BT_GATT_CHRC_WRITE_WITHOUT_RESP | BT_GATT_CHRC_NOTIFY),
                                              BT_GATT_PERM_READ | BT_GATT_PERM_WRITE,
                                              NULL, FPGASVC_AcquireSignals, NULL),
                       BT_GATT_CCC(signal_ccc_cfg_changed,
                                   BT_GATT_PERM_READ | BT_GATT_PERM_WRITE),

                       BT_GATT_CHARACTERISTIC(BT_UUID_FPGA_RELATED_SERVICE_CMD,
                                              (BT_GATT_CHRC_WRITE | BT_GATT_CHRC_WRITE_WITHOUT_RESP | BT_GATT_CHRC_NOTIFY),
                                              BT_GATT_PERM_READ | BT_GATT_PERM_WRITE,
                                              NULL, FPGASVC_WriteCmd, NULL),
                       BT_GATT_CCC(cmd_ccc_cfg_changed,
                                   BT_GATT_PERM_READ | BT_GATT_PERM_WRITE),

                       BT_GATT_CHARACTERISTIC(BT_UUID_FPGA_RELATED_SERVICE_THRESHOLD,
                                              (BT_GATT_CHRC_READ | BT_GATT_CHRC_WRITE | BT_GATT_CHRC_WRITE_WITHOUT_RESP | BT_GATT_CHRC_NOTIFY),
                                              BT_GATT_PERM_READ | BT_GATT_PERM_WRITE,
                                              read_Threshole, FPGASVC_AcquireThreshold, NULL),
                       BT_GATT_CCC(threshold_ccc_cfg_changed,
                                   BT_GATT_PERM_READ | BT_GATT_PERM_WRITE), );

/**************************************************************************
 *Description:
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
void FPGASVC_SignalNfy(struct bt_conn *conn, const uint8_t *data, uint16_t len)
{
    const struct bt_gatt_attr *attr = &fpgarelated_service.attrs[ATTR_FPGA_RELATED_SERVICE_SIGNAL_CHARACTER_DECLARA];

    struct bt_gatt_notify_params params =
        {
            .uuid = BT_UUID_FPGA_RELATED_SERVICE_SIGNAL,
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

/**************************************************************************
 *Description:
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
void FPGASVC_CmdNfy(struct bt_conn *conn, const uint8_t *data, uint16_t len)
{
    const struct bt_gatt_attr *attr = &fpgarelated_service.attrs[ATTR_FPGA_RELATED_SERVICE_CMD_CHARACTER_DECLARA];

    struct bt_gatt_notify_params params =
        {
            .uuid = BT_UUID_FPGA_RELATED_SERVICE_CMD,
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

/**************************************************************************
 *Description:
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
void FPGASVC_ThresholdNfy(struct bt_conn *conn, const uint8_t *data, uint16_t len)
{
    const struct bt_gatt_attr *attr = &fpgarelated_service.attrs[ATTR_FPGA_RELATED_SERVICE_THRESHOLD_CHARACTER_DECLARA];

    struct bt_gatt_notify_params params =
        {
            .uuid = BT_UUID_FPGA_RELATED_SERVICE_THRESHOLD,
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

/**************************************************************************
 *Description:
 *Input:
 *Output:
 *Return:
 *Other: 数据处理过程
 *************************************************************************/
void FPGASVC_DataProsess(void)
{
    FPGASVC_SignalNfy(GATT_app.pConnection, (uint8_t *)&SPI_FpgaData.rxBuf[BMI_FPGA_SIGNAL_BUF_OFFSET], BMI_FPGA_SIGNAL_BUF_SIZE_MAX);
}

void FPGASVC_FPGASTART_Nfy(void)
{
    uint8_t data[1];
    data[0] = 0x00;

    FPGASVC_SignalNfy(GATT_app.pConnection, data, 1);
}

//============================================================================================================
//  End of file
//============================================================================================================