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
#include "iCE40update_service.h"
 

//---------------------defines------------------------------------------------------------------------------//
#define BT_UUID_ICE40_UPDATE_SERVICE        BT_UUID_DECLARE_128(ICE40_UPDATE_SERVICE_UUID)
#define BT_UUID_ICE40_UPDATE_SERVICE_RX     BT_UUID_DECLARE_128(RX_CHARACTERISTIC_UUID)
#define BT_UUID_ICE40_UPDATE_SERVICE_FLAG   BT_UUID_DECLARE_128(FLAG_CHARACTERISTIC_UUID)


//---------------------definition of data type--------------------------------------------------------------//
bmiFlashSVC_t	FPGA_UPDATE_State;
static struct iCE40_service_cb iCE40s_cb;


//---------------------definition of global variables------------------------------------------------------//
LOG_MODULE_DECLARE(bmi_ble);


//---------------------declaration of global functions -----------------------------------------------------//



//----------------------definitions of functions------------------------------------------------------------//

/**************************************************************************
 *Description:This function is called whenever the RX Characteristic has been written to by a Client
 *Input:
 *Output:
 *Return:
 *Other: 
 *************************************************************************/
static ssize_t rx_receive(struct bt_conn *conn,
			  const struct bt_gatt_attr *attr,
			  const void *buf,
			  uint16_t len,
			  uint16_t offset,
			  uint8_t flags)
{
	if (iCE40s_cb.rxReceived) 
    {
		iCE40s_cb.rxReceived(conn, buf, len);
    }  
    return len;	
}

/**************************************************************************
 *Description:This function is called whenever the flag Characteristic has been written to by a Client
 *Input:
 *Output:
 *Return:
 *Other: 
 *************************************************************************/
static ssize_t flag_receive(struct bt_conn *conn,
			  const struct bt_gatt_attr *attr,
			  const void *buf,
			  uint16_t len,
			  uint16_t offset,
			  uint8_t flags)
{
    if (iCE40s_cb.flagReceived) 
    {
		iCE40s_cb.flagReceived(conn, buf, len);
    } 
    return len;
}


/**************************************************************************
 *Other:This function is called whenever the CCCD register has been changed by the client
 *************************************************************************/
void on_cccd_changed(const struct bt_gatt_attr *attr, uint16_t value)
{
    ARG_UNUSED(attr);
    switch(value)
    {
        case BT_GATT_CCC_NOTIFY: 
            // Start sending stuff!
            break;

        case BT_GATT_CCC_INDICATE: 
            // Start sending stuff via indications
            break;

        case 0: 
            // Stop sending stuff
            break;
        
        default: 
            LOG_ERR("Error, CCCD has been set to an invalid value");     
    }
}

BT_GATT_SERVICE_DEFINE(iCE40_update_service,
BT_GATT_PRIMARY_SERVICE(BT_UUID_ICE40_UPDATE_SERVICE),
BT_GATT_CHARACTERISTIC(BT_UUID_ICE40_UPDATE_SERVICE_RX,
			       BT_GATT_CHRC_WRITE | BT_GATT_CHRC_WRITE_WITHOUT_RESP,
			       BT_GATT_PERM_READ | BT_GATT_PERM_WRITE, 
                   NULL, rx_receive, NULL),
BT_GATT_CHARACTERISTIC(BT_UUID_ICE40_UPDATE_SERVICE_FLAG,
			       BT_GATT_CHRC_WRITE | BT_GATT_CHRC_WRITE_WITHOUT_RESP,
			       BT_GATT_PERM_READ | BT_GATT_PERM_WRITE,
                   NULL, flag_receive, NULL),
BT_GATT_CCC(on_cccd_changed,
        BT_GATT_PERM_READ | BT_GATT_PERM_WRITE),
);

/**************************************************************************
 *Description:
 *Input:
 *Output:
 *Return:
 *Other:
 *************************************************************************/
int bt_iCE40s_init(struct iCE40_service_cb  *callbacks)
{
	if (callbacks) {
		iCE40s_cb.rxReceived = callbacks->rxReceived;
		iCE40s_cb.flagReceived = callbacks->flagReceived;
	}

    FPGA_UPDATE_State.nvs_id = 0;
    FPGA_UPDATE_State.fileReceiveFinishFlag = 0;
    FPGA_UPDATE_State.frameNvsWriteFinishFlag = 0;
    FPGA_UPDATE_State.frameReceiveFinishFlag = 0;
    
	return 0;
}
//============================================================================================================
//  End of file
//============================================================================================================