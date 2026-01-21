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
#include "gattapp.h"
#include <zephyr/mgmt/mcumgr/transport/smp_bt.h>

//---------------------defines------------------------------------------------------------------------------//
#define DEVICE_NAME CONFIG_BT_DEVICE_NAME
#define DEVICE_NAME_LEN (sizeof(DEVICE_NAME) - 1)

#define ADV_INTERVAL_MIN 0x0064 // 100ms (100ms / 0.625ms)
#define ADV_INTERVAL_MAX 0x0064 // 100ms (100ms / 0.625ms)
#define TX_POWER_DBM 0			// Transmit power: 0dBm
//---------------------definition of data type--------------------------------------------------------------//

//---------------------definition of global variables------------------------------------------------------//
volatile bmiGATTApp_t GATT_app;
static K_SEM_DEFINE(ble_init_ok, 0, 1);

static struct bt_le_conn_param *conn_param = BT_LE_CONN_PARAM(6, 40, 0, 400); // Minimum Connection Interval 7.5ms~50ms

static const struct bt_data ad[] =
	{
		BT_DATA_BYTES(BT_DATA_FLAGS, (BT_LE_AD_GENERAL | BT_LE_AD_NO_BREDR)),
		// BT_DATA(BT_DATA_NAME_COMPLETE, DEVICE_NAME, DEVICE_NAME_LEN),
		BT_DATA_BYTES(BT_DATA_UUID128_ALL,
					  0x84, 0xaa, 0x60, 0x74, 0x52, 0x8a, 0x8b, 0x86,
					  0xd3, 0x4c, 0xb7, 0x1d, 0x1d, 0xdc, 0x53, 0x8d),
};
/* 扫描响应数据 - 包含设备名称 */
static const struct bt_data sd[] = {
	BT_DATA(BT_DATA_NAME_COMPLETE, DEVICE_NAME, DEVICE_NAME_LEN),
};

//---------------------declaration of global functions -----------------------------------------------------//
#define LOG_MODULE_NAME bmi_ble
LOG_MODULE_REGISTER(LOG_MODULE_NAME);

//----------------------definitions of functions------------------------------------------------------------//
static void exchange_func(struct bt_conn *conn, uint8_t att_err,
						  struct bt_gatt_exchange_params *params)
{
	struct bt_conn_info info = {0};
	int err;

	LOG_INF("MTU exchange %s\n", att_err == 0 ? "successful" : "failed");

	err = bt_conn_get_info(conn, &info);
	if (err)
	{
		LOG_ERR("Failed to get connection info %d", err);
		return;
	}

	if (info.role == BT_CONN_ROLE_CENTRAL)
	{
	}
}

static void request_mtu_exchange(void) // client used
{
	int err;
	static struct bt_gatt_exchange_params exchange_params;
	exchange_params.func = exchange_func;

	err = bt_gatt_exchange_mtu(GATT_app.pConnection, &exchange_params);
	if (err)
	{
		LOG_ERR("MTU exchange failed (err %d)\r\n", err);
	}
	else
	{
		LOG_INF("MTU exchange pending");
	}
}

static void request_data_len_update(void)
{
	int err;
	err = bt_conn_le_data_len_update(GATT_app.pConnection, BT_LE_DATA_LEN_PARAM_MAX);
	if (err)
	{
		LOG_ERR("LE data length update request failed: %d\r\n", err);
	}
	else
	{
		LOG_INF("data_len update!");
	}
}

static void request_phy_update(void)
{
	int err;

	err = bt_conn_le_phy_update(GATT_app.pConnection, BT_CONN_LE_PHY_PARAM_2M);
	if (err)
	{
		LOG_ERR("Phy update request failed: %d\r\n", err);
	}
	else
	{
		LOG_INF("phy update!");
	}
}

static void update_connection_parameters(void)
{
	int err;
	err = bt_conn_le_param_update(GATT_app.pConnection, conn_param);
	if (err)
	{
		LOG_ERR("Cannot update conneciton parameter (err: %d)", err);
	}
	else
	{
		LOG_INF("Cannot update conneciton parameter success!");
	}
}

/**************************************************************************
 *Description:
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
static void connected(struct bt_conn *conn, uint8_t err)
{
	char addr[BT_ADDR_LE_STR_LEN];

	if (err)
	{
		LOG_ERR("Connection failed (err %u)\r\n", err);
		return;
	}

	bt_addr_le_to_str(bt_conn_get_dst(conn), addr, sizeof(addr));
	LOG_INF("Connected %s", addr);

	int ret = bt_le_adv_stop();
	if (ret)
	{
		LOG_INF("Failed to stop advertising (err %d)\n", ret);
	}

	GATT_app.pConnection = bt_conn_ref(conn);

	request_data_len_update();
	request_phy_update();
	request_mtu_exchange();
	update_connection_parameters();

	k_event_post(&event_flags, EVENT_CONNECT);
}

/**************************************************************************
 *Description:
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
static void disconnected(struct bt_conn *conn, uint8_t reason)
{
	char addr[BT_ADDR_LE_STR_LEN];

	bt_addr_le_to_str(bt_conn_get_dst(conn), addr, sizeof(addr));

	LOG_INF("Disconnected: %s (reason %u)", addr, reason);
	// sJumpToSta(SYS_STA_INIT);	//at while(1) to programe fpga

	if (GATT_app.pConnection)
	{
		bt_conn_unref(GATT_app.pConnection);
		GATT_app.pConnection = NULL;
	}

	uint8_t err = bt_le_adv_start(BT_LE_ADV_CONN, ad, ARRAY_SIZE(ad), sd,
								  ARRAY_SIZE(sd));
	if (err)
	{
		LOG_INF("Advertising failed to start (err %d)\r\n", err);
		return;
	}
	k_event_post(&event_flags, EVENT_DISCONNECT);
}

BT_CONN_CB_DEFINE(conn_callbacks) = {
	.connected = connected,
	.disconnected = disconnected,
};

/**************************************************************************
 *Description:
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
static void error(void)
{
	while (true)
	{
		LOG_ERR("Error!\r\n");
		/* Spin for ever */
		k_sleep(K_MSEC(1000)); // 1000ms
	}
}

/**************************************************************************
 *Description:
 *Input:
 *Output:
 *Return:
 *Other:后期需要用户层传入广播间隔、发射功率、连接间隔等参数
 *************************************************************************/
void GATTApp_bleInit(void)
{
	uint8_t err = 0;
	int ret;

	err = bt_enable(NULL);
	if (err)
	{
		error();
	}
	LOG_INF("Bluetooth initialized\n");
	// ret = smp_bt_register();
	// LOG_INF("smp_bt_register return %d", ret);

	k_sem_give(&ble_init_ok);

	if (IS_ENABLED(CONFIG_SETTINGS))
	{
		settings_load();
	}

	err = bt_le_adv_start(BT_LE_ADV_CONN, ad, ARRAY_SIZE(ad), sd,
						  ARRAY_SIZE(sd));
	if (err)
	{
		LOG_INF("Advertising failed to start (err %d)\r\n", err);
		return;
	}
	/* 	Bluetooth stack should be ready in less than 100 msec. 								\
																							\
		We use this semaphore to wait for bt_enable to call bt_ready before we proceed 		\
		to the main loop. By using the semaphore to block execution we allow the RTOS to 	\
		execute other tasks while we wait. */
	err = k_sem_take(&ble_init_ok, K_MSEC(500));

	if (!err)
	{
		LOG_INF("BLE initialization complete in time");
	}
	else
	{
		LOG_INF("BLE initialization did not complete in time\r\n");
		error(); // Catch error
	}

	k_sleep(K_MSEC(500));
}

//============================================================================================================
//  End of file
//============================================================================================================