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
    File        : ptxNDEFRecord_Text.h

    Description : NDEF Text record API
*/

/**
 * \addtogroup grp_ptx_api_ndef_record_text NDEF Text Record API
 *
 * @{
 */

#ifndef APIS_PTX_NDEF_RECORD_TEXT_H_
#define APIS_PTX_NDEF_RECORD_TEXT_H_

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
* \brief Record type definition for text record.
*/
#define TYPE_RTD_TEXT           ("T")
#define TYPE_RTD_TEXT_LEN       (1u)

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
/**
 * \brief Creates a text record from a specified language code and a given text.
 *
 * \param[in,out]   record          Pointer to an uninitialized NDEF record structure.
 * \param[in,out]   workBuffer      Pointer to a buffer for storing the assembled payload.
 * \param[in,out]   workBufferLen   Pointer to a variable containing the available buffer length.
 * \param[in]       languageCode    Language code of the record.
 * \param[in]       text            The actual text content.
 *
 * \return Status, indicating whether the operation was successful.
 */
ptxStatus_t ptxNDEFRecordText_Create (ptxNDEFRecord_t *record, uint8_t *workBuffer, size_t *workBufferLen, char *languageCode, char *text);

#ifdef __cplusplus
}
#endif

/** @} */

#endif /* Guard */
