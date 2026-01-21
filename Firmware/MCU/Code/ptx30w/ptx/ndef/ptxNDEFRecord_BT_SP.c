/** \file
    ---------------------------------------------------------------
    Copyright (C) 2023. Panthronics AG - All Rights Reserved.

    This material may not be reproduced, displayed, modified or
    distributed without the express prior written permission of the
    Panthronics AG.

    PLEASE CHECK FURTHER DISCLAIMER IN FILE "PTX_LICENSE.TXT"
    ---------------------------------------------------------------

    Project     : PTX30W
    Module      : NDEF Bluetooth Record Simple Pairing
    File        : ptxNDEFRecord_BT_SP.c

    Description : NDEF BT SP record API
*/


/*
 * ####################################################################################################################
 * INCLUDES
 * ####################################################################################################################
 */
#include "ptxNDEFRecord_BT_SP.h"

/*
 * ####################################################################################################################
 * API FUNCTIONS
 * ####################################################################################################################
 */
ptxStatus_t ptxNDEFRecordBTSP_Create (ptxNDEFRecord_t* record, uint8_t* workBuffer, size_t* workBufferLen, uint8_t* btDeviceAddress, char* btDeviceName)
{
   ptxStatus_t status = ptxStatus_MAX;

    if((NULL != record) && (NULL != btDeviceAddress) && (NULL != workBuffer))
    {
        uint8_t payload_len = (uint8_t) (BT_OOB_DATA_LEN_BYTES + MAC_ADDRESS_LEN + BT_EIR_DATA_BYTES + ((uint8_t) strlen(btDeviceName)));
        uint8_t index = 0;

        if (*workBufferLen >= payload_len)
        {
            /* Flip oob data length. 2 bytes needed but only one in use, sufficient here. (device name would have to exceed 245 bytes) */
            workBuffer[index] = payload_len;
            index++;
            workBuffer[index] = 0x00;
            index++;

            /* Flip BT MAC address */
            for (uint8_t i = 0; i < MAC_ADDRESS_LEN; ++i)
            {
                workBuffer[index] = btDeviceAddress[MAC_ADDRESS_LEN - (i + 1)];
                index++;
            }

            /* EIR data length: length BT name + 1 (data type) */
            workBuffer[index] = (uint8_t) (strlen(btDeviceName) + 1);
            index++;

            /* EIR data type: Complete local name */
            workBuffer[index] = 0x09;
            index++;

            /* BT local device name */
            strcpy((char *) &workBuffer[index], btDeviceName);
            index = (uint8_t) (index + strlen(btDeviceName));

            status = ptxNDEFRecord_Create(record, TNF_MEDIA_TYPE, (uint8_t*) TYPE_RTD_BT, TYPE_RTD_BT_LEN, (uint8_t*) PAYLOAD_ID, 1u, workBuffer, payload_len);
        }
        else 
        {
            status = ptxStatus_InsufficientResources;
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}
