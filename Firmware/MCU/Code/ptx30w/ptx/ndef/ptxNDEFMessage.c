/** \file
    ---------------------------------------------------------------
    Copyright (C) 2023. Panthronics AG - All Rights Reserved.

    This material may not be reproduced, displayed, modified or
    distributed without the express prior written permission of the
    Panthronics AG.

    PLEASE CHECK FURTHER DISCLAIMER IN FILE "PTX_LICENSE.TXT"
    ---------------------------------------------------------------

    Project     : PTX30W
    Module      : Generic NDEF Message API
    File        : ptxNDEFMessage.c

    Description : Generic NDEF Message API
*/

/*
 * ####################################################################################################################
 * INCLUDES
 * ####################################################################################################################
 */
#include "ptxNDEFMessage.h"

/*
 * ####################################################################################################################
 * API FUNCTIONS
 * ####################################################################################################################
 */
ptxStatus_t ptxNDEFMessage_Create (ptxNDEFRecord_t *recordBuffer, size_t recordSize, uint8_t *dstBuffer, size_t *bufferLen)
{
    ptxStatus_t status = ptxStatus_Success;

    /** Parameter checking. */
    if( (NULL != recordBuffer) && (NULL != dstBuffer) && (NULL != bufferLen) )
    {
        size_t record_num = 0u;
        size_t data_written = 0u;
        uint8_t *buffer_cpy = dstBuffer;
        size_t bufferLenCpy = *bufferLen;

        /** Iterate over available records. */
        while(record_num < recordSize)
        {
            /** In case of the very first record, we have to set the Message Begin (MB) flag in its header.  */
            if(0u == record_num)
            {
                ptxNDEFRecord_SetMB(&recordBuffer[record_num], 1u);
            }

            size_t record_size;
            /** Write the record to the destination buffer. */
            status = ptxNDEFRecord_Write(&recordBuffer[record_num], &buffer_cpy[data_written], bufferLenCpy - data_written, &record_size);

            /** Check if everything went well. */
            if(ptxStatus_Success != status)
            {
                break;
            }

            /** Increment the amount of successfully written data. */
            data_written += record_size;
            ++record_num;
        }

        if(ptxStatus_Success == status)
        {
            *bufferLen = data_written;
        }
    }
    else
    {
       status = ptxStatus_InvalidParameter;
    }

    return status;
}
