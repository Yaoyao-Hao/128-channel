/** \file
    ---------------------------------------------------------------
    Copyright (C) 2023. Panthronics AG - All Rights Reserved.

    This material may not be reproduced, displayed, modified or
    distributed without the express prior written permission of the
    Panthronics AG.

    PLEASE CHECK FURTHER DISCLAIMER IN FILE "PTX_LICENSE.TXT"
    ---------------------------------------------------------------

    Project     : PTX30W
    Module      : NDEF Text Record
    File        : ptxNDEFRecord_Text.c

    Description : NDEF Text record implementation
*/


/*
 * ####################################################################################################################
 * INCLUDES
 * ####################################################################################################################
 */
#include "ptxNDEFRecord_Text.h"

/*
 * ####################################################################################################################
 * API FUNCTIONS
 * ####################################################################################################################
 */
ptxStatus_t ptxNDEFRecordText_Create (ptxNDEFRecord_t *record, uint8_t *workBuffer, size_t *workBufferLen, char *languageCode, char *text)
{
    ptxStatus_t status = ptxStatus_Success;

    /** Parameter checking. */
    if((NULL != record) && (NULL != workBuffer) && (NULL != languageCode) && (NULL != text))
    {
        /** Get length of language code (e.g. "en", "de"). */
        size_t lang_code_len = strlen(languageCode);
        /** Get length of actual text payload. */
        size_t text_len = strlen(text);
        /** Calculate the total payload length. */
        size_t total_len = 1u + lang_code_len + text_len;

        /** Check if the workbuffer is large enough. */
        if(*workBufferLen >= total_len)
        {
            /** Set the payload length. */
            *workBufferLen = total_len;

            /** Copy text record payload data together. */
            workBuffer[0] = 0; // UTF-8 only
            workBuffer[0] = (uint8_t) (workBuffer[0] | (uint8_t) (lang_code_len & 0x3F));

            /** Copy language code (has to be zero terminated). */
            strcpy((char *) &(workBuffer[1]), languageCode);
            /** Copy text. */
            strcpy((char *) &(workBuffer[1 + lang_code_len]), text);

            /** Create the record struct (including record header). */
            status = ptxNDEFRecord_Create(record, TNF_WELL_KNOWN_TYPE, (uint8_t*) TYPE_RTD_TEXT, TYPE_RTD_TEXT_LEN, NULL, 0, workBuffer, total_len);
        }
        else
        {
            /** Workbuffer not large enough. */
            status = ptxStatus_InsufficientResources;
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}
