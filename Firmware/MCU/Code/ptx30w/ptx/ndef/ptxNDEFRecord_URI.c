/** \file
    ---------------------------------------------------------------
    Copyright (C) 2023. Panthronics AG - All Rights Reserved.

    This material may not be reproduced, displayed, modified or
    distributed without the express prior written permission of the
    Panthronics AG.

    PLEASE CHECK FURTHER DISCLAIMER IN FILE "PTX_LICENSE.TXT"
    ---------------------------------------------------------------

    Project     : PTX30W
    Module      : NDEF URI Record
    File        : ptxNDEFRecord_URI.c

    Description : NDEF URI record implementation
*/


/*
 * ####################################################################################################################
 * INCLUDES
 * ####################################################################################################################
 */
#include "ptxNDEFRecord_URI.h"

/*
 * ####################################################################################################################
 * API FUNCTIONS
 * ####################################################################################################################
 */
ptxStatus_t ptxNDEFRecordUri_Create (ptxNDEFRecord_t *record, uint8_t *workBuffer, size_t *workBufferLen, ptxURIRecord_Identifier_t idf, char *uri)
{
    ptxStatus_t status = ptxStatus_Success;

    if((NULL != record) && (NULL != uri) && (NULL != workBuffer))
    {
        /** Get length of the URI. (char array has to be zero terminated!) */
        size_t uri_len = strlen(uri);
        /** Calculate record payload length. We need one additional byte for the record identifier. */
        size_t total_len = 1 + uri_len;

        /** Check if the workbuffer is large enough. */
        if(*workBufferLen >= total_len)
        {
            /** Set the payload length. */
            *workBufferLen = total_len;
            /** Set the URI record identifier. */
            workBuffer[0] = idf;
            /** Copy the actual URI (char array has to be zero terminated!) */
            strcpy((char *) &(workBuffer[1]), uri);

            /** Create the record struct (including record header). */
            status = ptxNDEFRecord_Create(record, TNF_WELL_KNOWN_TYPE, (uint8_t*) TYPE_RTD_URI, TYPE_RTD_URI_LEN, NULL, 0, workBuffer, total_len);
        }
        else
        {
            /** Workbuffer not large enough. */
            status = ptxStatus_InsufficientResources;
        }

    } else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}
