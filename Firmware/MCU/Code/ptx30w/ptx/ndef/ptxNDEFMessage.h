/** \file
    ---------------------------------------------------------------
    Copyright (C) 2023. Panthronics AG - All Rights Reserved.

    This material may not be reproduced, displayed, modified or
    distributed without the express prior written permission of the
    Panthronics AG.

    PLEASE CHECK FURTHER DISCLAIMER IN FILE "PTX_LICENSE.TXT"
    ---------------------------------------------------------------

    Project     : PTX30W
    Module      : Generic NDEF MESSAGE API
    File        : ptxNDEFMessage.h

    Description : API for creating and parsing NDEF messages into
                  individual records functions.
*/

/**
 * \addtogroup grp_ptx_api_ndef_message Generic NDEF Message API
 *
 * @{
 */

#ifndef APIS_PTX_NDEF_MESSAGE_H_
#define APIS_PTX_NDEF_MESSAGE_H_

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
 * \brief Creates an NDEF Message from individual NDEF records and stores it in a buffer.
 *
 * \param[in]       recordBuffer    Pointer to an existing (and initialized) NDEF record buffer array.
 * \param[in]       recordSize      Size of the NDEF record buffer.
 * \param[in]       dstBuffer       Pointer to an existing buffer, where the data gets written to.
 * \param[in,out]   bufferLen       Pointer to an integer describing the available 'dstBuffer' length (in). Actual written length (out).
 *
 * \return Status, indicating whether the operation was successful.
 */
ptxStatus_t ptxNDEFMessage_Create (ptxNDEFRecord_t *recordBuffer, size_t recordSize, uint8_t *dstBuffer, size_t *bufferLen);

#ifdef __cplusplus
}
#endif

/** @} */

#endif /* Guard */
