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
    File        : ptxNDEFRecord_BT_SP.h

    Description : NDEF BT SP record API
*/

/**
 * \addtogroup grp_ptx_api_ndef_record_bluetooth NDEF Bluetooth Record API
 *
 * @{
 */

#ifndef APIS_PTX_NDEF_RECORD_BT_H_
#define APIS_PTX_NDEF_RECORD_BT_H_

/*
 * ####################################################################################################################
 * INCLUDES
 * ####################################################################################################################
 */

#include "ptxNDEFRecord.h"
#include "../ptxStatus.h"

#ifdef __cplusplus
extern "C" {
#endif
/*
 * ####################################################################################################################
 * DEFINES
 * ####################################################################################################################
 */
#define TYPE_RTD_BT             ("application/vnd.bluetooth.ep.oob")
#define TYPE_RTD_BT_LEN         (32u)
#define PAYLOAD_ID              ("0")
#define MAC_ADDRESS_LEN         (6u) /* expected size of MAC address*/
#define BT_OOB_DATA_LEN_BYTES   (2u) /* bytes used for OOB data length */
#define BT_EIR_DATA_BYTES       (2u) /* bytes used for one EIR, data length and data type */   

/*
* ####################################################################################################################
* TYPES
* ####################################################################################################################
*/

/*
 * ####################################################################################################################
 * API FUNCTIONS
 * ####################################################################################################################
 */

ptxStatus_t ptxNDEFRecordBTSP_Create (ptxNDEFRecord_t *record, uint8_t *workBuffer, size_t *workBufferLen, uint8_t* btDeviceAddressLen, char* btDeviceName);

#ifdef __cplusplus
}
#endif

/** @} */

#endif /* Guard */
