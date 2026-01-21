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
#include "../services/fpgarelated_service.h"
#include "../services/iCE40update_service.h"
#include "../services/deviceinfo_service.h"
#include "../services/gattapp.h"
#include "../users/spi.h"
#include "../users/timer.h"
#include "../users/iCE40.h"
#include "../users/flash.h"
#include "../ptx30w/user_ptx30w_app.h"
#include <zephyr/pm/pm.h>

#define LOG_MODULE_NAME bmi_main
LOG_MODULE_REGISTER(LOG_MODULE_NAME);

// static uint32_t previous_timestamp = 0xFFFFFFFF; // 初始化标记值
// uint32_t current_timestamp = 0;
struct k_timer ble_connect_timer;

struct k_event event_flags;

void ble_connect_timer_event_handler(struct k_timer *timer)
{
	k_timer_stop(&ble_connect_timer);
	k_event_post(&event_flags, EVENT_CONNECT_NECT);
}

static int bt_rx_receive_cb(struct bt_conn *conn, const uint8_t *data,
							uint16_t len)
{
	const uint8_t *buffer = data;

	if (FPGA_UPDATE_State.nvs_id == 0)
	{
		return BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET);
	}
	else
	{
		FPGA_UPDATE_State.frameReceiveFinishFlag = 1;

		LOG_DBG("data: %d %d %d", buffer[0], buffer[1], len);
		flash_Para.lastFrameBytes = len;

		for (int i = 0; i < 256; i++)
		{
			FPGA_UPDATE_State.fileValue[i] = buffer[i];
		}

		LOG_DBG("fpgaFileValue: %d %d", FPGA_UPDATE_State.fileValue[0], FPGA_UPDATE_State.fileValue[1]);
		k_event_post(&event_flags, EVENT_FPGA_UPDATE_FRAME_RECEIVE);

		while (1)
		{
			if (!FPGA_UPDATE_State.frameNvsWriteFinishFlag)
			{
				k_sleep(K_MSEC(5));
				if (FPGA_UPDATE_State.frameNvsWriteFinishFlag)
				{
					FPGA_UPDATE_State.frameNvsWriteFinishFlag = 0;
					FPGA_UPDATE_State.frameReceiveFinishFlag = 0;
					FPGA_UPDATE_State.nvs_id++;
					flash_Para.frameCount++;
					LOG_DBG("write success!");
					return BT_GATT_ERR(BT_ATT_ERR_SUCCESS);
				}
			}
		}
	}
}

static int bt_flag_receive_cb(struct bt_conn *conn, const uint8_t *data,
							  uint16_t len)
{
	const uint8_t *buffer = data;
	LOG_DBG("receive flag");

	if (*buffer == FPGA_FILE_RECEIVE_START)
	{

		FPGA_UPDATE_State.start = true;
		FPGA_UPDATE_State.nvs_id = 3;
		flash_Para.frameCount = 3;
		FPGA_UPDATE_State.fileReceiveFinishFlag = 0;
		k_event_post(&event_flags, EVENT_FPGA_UPDATE_PRE);
		k_timer_stop(&spi_data_cap_timer);

		BLE_fpgaSvc.timerEnableFlag = false;
	}
	else if (*buffer == FPGA_FILE_RECEIVE_STOP)
	{
		FPGA_UPDATE_State.start = false;
		FPGA_UPDATE_State.nvs_id = 0;
		FPGA_UPDATE_State.fileReceiveFinishFlag = 1;
		k_event_post(&event_flags, EVENT_FPGA_UPDATE_FRAME_RECEIVE);
	}
	else
	{
		return BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET);
	}

	return len;
}

static struct iCE40_service_cb iCE40s_cb = {
	.rxReceived = bt_rx_receive_cb,
	.flagReceived = bt_flag_receive_cb,
};

static void variablesInit(void)
{
	BLE_fpgaSvc.nfyType = NOTIFY_SIGNAL_RAW_SPIKE;
	BLE_fpgaSvc.timerEnableFlag = false;
	BLE_fpgaSvc.thresholdEnableFlag = false;
	SPI_FpgaData.spiInitFlag = false;
}

void main(void)
{
	int peripheral_status = NRFX_SUCCESS;
	ptxStatus_t ptx30w_status;
	shtStatus_t ntc_status;
	nvsStatus_t nvs_status;
	int rc = 0;

	LOG_INF("build time: " __DATE__ " " __TIME__ "\n");
	variablesInit();
	/*********************************************************************0312test********************************************************/
#ifdef ENABLE_TEST
	fpga_InitPowerPin();
	fpga_3_3PowerEnable();
	fpga_1_2PowerEnable();
	k_sleep(K_MSEC(100));

	nvs_status = fs_init();
	if (nvs_status != nvsStatus_Success)
	{
		LOG_ERR("Flash init failed, return err %d", nvs_status);
	}
	else
	{
		LOG_INF("fs init success");
	}
	nvs_status = iCE40_Configuration();
	if (nvs_status != nvsStatus_Success)
	{
		LOG_ERR("iCE40 conofiguration failed, return err %d", nvs_status);
	}
	else
	{
		LOG_INF("iCE40 program success");
	}

	peripheral_status = SPI_Init();
	if (peripheral_status != NRFX_SUCCESS)
	{
		LOG_ERR("spi init not success return err %d", peripheral_status);
	}

	peripheral_status = DDI_TIMER3_Init();
	if (peripheral_status != NRFX_SUCCESS)
	{
		LOG_ERR("timmer initialization was not successful, return err %d", peripheral_status);
	}
	LOG_INF("spi timer init finish");
#endif
	/*********************************************************************0312test********************************************************/

	k_event_init(&event_flags);
	LOG_INF("board start!");

	GATTApp_bleInit();
	bt_iCE40s_init(&iCE40s_cb);
	gpio_low_power();
	/* 启动时使系统进入低功耗状态 */
	// pm_state_force(0, &(struct pm_state_info){PM_STATE_SUSPEND_TO_DISK, 0, 0});

	while (1)
	{
		uint32_t events = k_event_wait(&event_flags, EVENT_CONNECT | EVENT_DISCONNECT | EVENT_READ_DEVICE_STATUS | EVENT_COM | EVENT_FPGA_ENABLE | EVENT_FPGA_DISABLE | EVENT_FPGA_UPDATE_PRE | EVENT_FPGA_UPDATE_FRAME_RECEIVE | EVENT_FPGA_UPDATE_PROGRAM | EVENT_POWER_DOWN | EVENT_CONNECT_NECT, false, K_FOREVER);

		if (events & EVENT_COM)
		{
			if (BLE_fpgaSvc.timerEnableFlag)
			{

				if ((SPI_FpgaData.rxBuf[3] == 0x91) && (SPI_FpgaData.rxBuf[4] == 0xC6))
				{
					SPI_FpgaData.rxBuf[2] = BLE_fpgaSvc.nfyType;
					// LOG_INF("notify begin------------------------------------------------------");
					// LOG_INF("%x", SPI_FpgaData.rxBuf[9]);
					// LOG_INF("data 12: %x", SPI_FpgaData.rxBuf[10]);

					if (BLE_fpgaSvc.nfyType == NOTIFY_SIGNAL_RAW_SPIKE)
					{
						FPGASVC_SignalNfy(GATT_app.pConnection, &SPI_FpgaData.rxBuf[BMI_FPGA_SIGNAL_BUF_OFFSET], (BMI_FPGA_SIGNAL_BUF_SIZE_MAX + 1));
						// for (int i = 2; i < 386; i += 2) {
						// 	LOG_INF("notify rhd data: %02x%02x", SPI_FpgaData.rxBuf[i+1], SPI_FpgaData.rxBuf[i]);
						// }
					}
					else if (BLE_fpgaSvc.nfyType == NOTIFY_SIGNAL_RAW)
					{
						// LOG_INF("nfyType %d", 2);
						FPGASVC_SignalNfy(GATT_app.pConnection, &SPI_FpgaData.rxBuf[BMI_FPGA_SIGNAL_BUF_OFFSET], (BMI_FPGA_SIGNAL_RAW_LEN + 1));
					}
					else if (BLE_fpgaSvc.nfyType == NOTIFY_SIGNAL_SPIKE)
					{
						// LOG_INF("nfyType %d", 3);
						memcpy(&NfyData[0], &SPI_FpgaData.rxBuf[2], BMI_FPGA_SIGNAL_RAW_OFFSET);
						memcpy(&NfyData[BMI_FPGA_SIGNAL_RAW_OFFSET], &SPI_FpgaData.rxBuf[BMI_FPGA_SIGNAL_SPIKE_OFFSET], BMI_FPGA_SIGNAL_SPIKE_LEN);
						FPGASVC_SignalNfy(GATT_app.pConnection, &NfyData[0], NOTIFY_SIGNAL_SPIKE_SIZE);
					}
				}
				SPI_FpgaData.xfer_done = false;
			}
			k_event_clear(&event_flags, EVENT_COM);
		}

		if (events & EVENT_CONNECT)
		{
			k_timer_init(&ble_connect_timer, ble_connect_timer_event_handler, NULL);
			k_timer_start(&ble_connect_timer, K_SECONDS(2), K_SECONDS(2));
			gpio_no_pull();
			k_event_clear(&event_flags, EVENT_CONNECT);
			// pm_state_force(0, &(struct pm_state_info){PM_STATE_SUSPEND_TO_DISK, 0, 0});
			LOG_INF("Enter the low-power state and wait for the Bluetooth event");
		}

		if (events & EVENT_CONNECT_NECT)
		{
			fpga_InitPowerPin();
			fpga_reset_low();
			fpga_1_2PowerEnable();
			k_sleep(K_MSEC(50));
			fpga_3_3PowerEnable();
			LOG_INF("FPGA power on");
			k_sleep(K_MSEC(100));

			/*连接后烧写FPGA*/
			LOG_INF("Enter the connection event and prepare to flash the FPGA");
#ifndef ENABLE_TEST
			nvs_status = fs_init();
			if (nvs_status != nvsStatus_Success)
			{
				LOG_ERR("Flash init failed, return err %d", nvs_status);
			}
			else
			{
				LOG_INF("fs init success");
			}
			nvs_status = iCE40_Configuration();
			if (nvs_status != nvsStatus_Success)
			{
				LOG_ERR("iCE40 conofiguration failed, return err %d", nvs_status);
			}
			else
			{
				LOG_INF("iCE40 program success");
			}
#endif
			fpga_reset_high();
			fpga_3_3PowerDisable();
			k_event_clear(&event_flags, EVENT_CONNECT_NECT);
		}

		if (events & EVENT_READ_DEVICE_STATUS)
		{
			if (BLE_fpgaSvc.fpgaBusyState == FPGA_BUSY)
			{
				k_event_clear(&event_flags, EVENT_READ_DEVICE_STATUS);
			}
			else
			{
				ptx30w_status = PTX30W_Init();
				if (ptx30w_status != ptxStatus_Success)
				{
					LOG_ERR("ptx30w initialization was not successful, return err %d", ptx30w_status);
				}
				ptx30w_status = PTX30W_readSystemStatus();
				ntc_status = sht4x_read_temp_humid();
				if ((ptxStatus_Success == ptx30w_status) || (ntcStatus_Success == ntc_status) || (BLE_deviceInfoSvc.statusInfoNotifyEnable))
				{
					DEVICEINFO_DataNfy();
				}

				IIC_LowPower();
				k_event_clear(&event_flags, EVENT_READ_DEVICE_STATUS);
				// pm_state_force(0, &(struct pm_state_info){PM_STATE_SUSPEND_TO_DISK, 0, 0});
			}
		}

		if (events & EVENT_FPGA_ENABLE)
		{
			fpga_spi_gpio_no_pull();
			k_msleep(100);
			fpga_3_3PowerEnable();
			fpga_reset_low();
			BLE_fpgaSvc.fpgaBusyState = FPGA_BUSY;
#ifndef ENABLE_TEST
			if (!SPI_FpgaData.spiInitFlag)
			{
				peripheral_status = SPI_Init();
				if (peripheral_status != NRFX_SUCCESS)
				{
					LOG_ERR("spi init not success return err %d", peripheral_status);
				}
				else
				{
					LOG_INF("spi init succ");
				}
			}

			if (!SPI_FpgaData.timerInitFlag)
			{
				peripheral_status = DDI_TIMER3_Init();
				if (peripheral_status != NRFX_SUCCESS)
				{
					LOG_ERR("timmer init not success return err %d", peripheral_status);
				}
			}
#endif

			k_event_clear(&event_flags, EVENT_FPGA_ENABLE);
			// pm_state_force(0, &(struct pm_state_info){PM_STATE_SUSPEND_TO_IDLE, 0, 0});
			k_msleep(500);
			FPGASVC_FPGASTART_Nfy();
		}

		if (events & EVENT_FPGA_DISABLE)
		{
#ifndef ENABLE_TEST
			if (SPI_FpgaData.spiInitFlag)
			{
				peripheral_status = DDI_Spim3_Uinit();
				if (peripheral_status != NRFX_SUCCESS)
				{
					LOG_ERR("spi uinit was not successful, return err %d", peripheral_status);
				}
				else
				{
					LOG_INF("spi uinit succ");
				}
			}
#endif
			BLE_fpgaSvc.fpgaBusyState = FPGA_IDLE;
			fpga_reset_high();
			fpga_3_3PowerDisable();
			fpga_spi_gpio_low_power();
			FPGASVC_FPGASTART_Nfy();
			k_event_clear(&event_flags, EVENT_FPGA_DISABLE);
			// pm_state_force(0, &(struct pm_state_info){PM_STATE_SUSPEND_TO_DISK, 0, 0});
		}

		if (events & EVENT_DISCONNECT)
		{
#ifndef ENABLE_TEST
			fpga_UinitPowerPin();
			LOG_ERR("fpga power down");
#endif
			gpio_low_power();
			k_event_clear(&event_flags, EVENT_DISCONNECT);
			// pm_state_force(0, &(struct pm_state_info){PM_STATE_SUSPEND_TO_DISK, 0, 0});
		}

		if (events & EVENT_FPGA_UPDATE_PRE)
		{
			// pm_state_force(0, &(struct pm_state_info){PM_STATE_RUNTIME_IDLE, 0, 0});
			fpga_3_3PowerEnable();
			LOG_INF("pre update");
			nvs_status = fs_init();
			if (nvs_status != nvsStatus_Success)
			{
				LOG_ERR("fpga pre update, flash init failed, return err %d", nvs_status);
			}
			nvs_status = fs_clear();
			if (nvs_status != nvsStatus_Success)
			{
				LOG_ERR("fpga pre update, flash fs clear failed, return err %d", nvs_status);
			}
			else
			{
				LOG_INF("FPGA update start");
			}

			k_event_clear(&event_flags, EVENT_FPGA_UPDATE_PRE);
		}

		if (events & EVENT_FPGA_UPDATE_FRAME_RECEIVE)
		{
			if (FPGA_UPDATE_State.fileReceiveFinishFlag == 0)
			{
				if (FPGA_UPDATE_State.frameReceiveFinishFlag == 1)
				{
					LOG_DBG("nvs write");
					rc = nvs_write(&fs, FPGA_UPDATE_State.nvs_id, &FPGA_UPDATE_State.fileValue, sizeof(FPGA_UPDATE_State.fileValue));
					for (int i = 0; i < 2; i++)
					{
						LOG_DBG("ID:%d, count:%d, value:%d\n", FPGA_UPDATE_State.nvs_id, i, FPGA_UPDATE_State.fileValue[i]);
					}
					if (rc >= 0)
					{
						FPGA_UPDATE_State.frameNvsWriteFinishFlag = 1;
						FPGA_UPDATE_State.frameReceiveFinishFlag = 0;
					}
				}
			}
			else
			{
				flash_Para.frameCount--;
				rc = nvs_write(&fs, FLASH_FRAME_COUNT, &flash_Para.frameCount, sizeof(flash_Para.frameCount));
				if (rc < 0)
				{
					LOG_ERR("FLASH_FRAME_COUNT stores fail");
				}
				rc = nvs_write(&fs, FLASH_LAST_FRAME_BYTES, &flash_Para.lastFrameBytes, sizeof(flash_Para.lastFrameBytes));
				if (rc < 0)
				{
					LOG_ERR("FLASH_LAST_FRAME_BYTES stores fail");
				}
				LOG_INF("52840 flash finish");
				k_event_post(&event_flags, EVENT_FPGA_UPDATE_PROGRAM);
			}
			k_event_clear(&event_flags, EVENT_FPGA_UPDATE_FRAME_RECEIVE);
		}

		if (events & EVENT_FPGA_UPDATE_PROGRAM)
		{
			LOG_INF("enter EVENT_FPGA_UPDATE_PROGRAM event");
			if (SPI_FpgaData.spiInitFlag)
			{
				peripheral_status = DDI_Spim3_Uinit();
				if (peripheral_status != NRFX_SUCCESS)
				{
					LOG_ERR("spi uinit failed");
				}
			}
			nvs_status = iCE40_Configuration();
			if (nvs_status != nvsStatus_Success)
			{
				LOG_ERR("iCE40 conofiguration failed, return err %d", nvs_status);
			}
			else
			{
				LOG_ERR("iCE40 conofiguration succeed");
			}
#ifdef ENABLE_TEST
			peripheral_status = SPI_Init();
			if (peripheral_status != NRFX_SUCCESS)
			{
				LOG_ERR("after iCE40 programe, spi initialization was not successful");
			}
#endif
			fpga_3_3PowerDisable();
			// pm_state_force(0, &(struct pm_state_info){PM_STATE_SUSPEND_TO_DISK, 0, 0});
			k_event_clear(&event_flags, EVENT_FPGA_UPDATE_PROGRAM);
		}

		if (events & EVENT_POWER_DOWN)
		{
			ptx30w_status = PTX30W_Init();
			if (ptx30w_status != ptxStatus_Success)
			{
				LOG_ERR("ptx30w initialization was not successful, return err %d", ptx30w_status);
			}
			ptx30w_status = ptx30w_EnterShippingMode();
			if (ptx30w_status != ptxStatus_Success)
			{
				LOG_ERR("ptx30w enter shipping mode fail!");
			}
			else
			{
				LOG_ERR("ptx30w enter shipping mode sucess!");
			}
			k_event_clear(&event_flags, EVENT_POWER_DOWN);
		}
	}
}
