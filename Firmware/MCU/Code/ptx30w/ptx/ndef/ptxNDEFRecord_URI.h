/** \file
    ---------------------------------------------------------------
    Copyright (C) 2023. Panthronics AG - All Rights Reserved.

    This material may not be reproduced, displayed, modified or
    distributed without the express prior written permission of the
    Panthronics AG.

    PLEASE CHECK FURTHER DISCLAIMER IN FILE "PTX_LICENSE.TXT"
    ---------------------------------------------------------------

    Project     : PTX30W
    Module      : URI NDEF RECORD API
    File        : ptxNDEFRecord_URI.h

    Description : API for URI NDEF record functions.
*/

/**
 * \addtogroup grp_ptx_api_ndef_record_uri NDEF URI Record API
 *
 * @{
 */
#ifndef APIS_PTX_NDEF_RECORD_URI_H_
#define APIS_PTX_NDEF_RECORD_URI_H_

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
/**
* \brief Record type definition for URI record.
*/
#define TYPE_RTD_URI            ("U")
#define TYPE_RTD_URI_LEN        (1u)

/*
* ####################################################################################################################
* TYPES
* ####################################################################################################################
*/
/**
 * \brief URI Identifier Codes
 */
typedef enum ptxURIRecord_Identifier
{
    NONE,
    HTTP_WWW,
    HTTPS_WWW,
    HTTP,
    HTTPS,
    TEL,
    MAILTO,
    FTP_ANONYMOUS,
    FTP_FTP,
    FTPS,
    SFTP,
    SMB,
    NFS,
    FTP,
    DAV,
    NEWS,
    TELNET,
    IMAP,
    RTSP,
    URN,
    POP,
    SIP,
    SIPS,
    TFTP,
    BTSPP,
    BTL2CAP,
    BTGOEP,
    TCPOBEX,
    IRDAOBEX,
    FILE,
    URN_EPC_ID,
    URN_EPC_TAG,
    URN_EPC_PAT,
    URN_EPC_RAW,
    URN_EPC,
    URN_NFC
} ptxURIRecord_Identifier_t;

/*
 * ####################################################################################################################
 * API FUNCTIONS
 * ####################################################################################################################
 */
/**
 * \brief Creates an NDEF URI record from a specified URI and URI Record identifier.
 *
 * \param[in,out]   record          Pointer to an uninitialized NDEF record structure.
 * \param[in,out]   workBuffer      Pointer to a buffer for storing the assembled payload.
 * \param[in,out]   workBufferLen   Pointer to a variable containing the available buffer length.
 * \param[in]       idf         URI record identifier option.
 * \param[in]       uri         Pointer to the character array describing the URI.
 *
 * \return Status, indicating whether the operation was successful.
 */
ptxStatus_t ptxNDEFRecordUri_Create (ptxNDEFRecord_t *record, uint8_t *workBuffer, size_t *workBufferLen, ptxURIRecord_Identifier_t idf, char *uri);

#ifdef __cplusplus
}
#endif

/** @} */

#endif /* Guard */
