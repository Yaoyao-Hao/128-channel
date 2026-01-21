/** \file
    ---------------------------------------------------------------
    Copyright (C) 2023. Panthronics AG - All Rights Reserved.

    This material may not be reproduced, displayed, modified or
    distributed without the express prior written permission of the
    Panthronics AG.

    PLEASE CHECK FURTHER DISCLAIMER IN FILE "PTX_LICENSE.TXT"
    ---------------------------------------------------------------

    Project     : PTX30W
    Module      : CRC
    File        : ptx30w_Crc.h
*/
#ifndef PTX_PTX30W_CRC_H_
#define PTX_PTX30W_CRC_H_

#include <stdbool.h>
#include <stddef.h>
#include "ptxStatus.h"

#ifdef __cplusplus
extern "C"
{
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
typedef enum ptx30wCrcType
{
    ptx30wCrcType_NfcA,
    ptx30wCrcType_NfcB
} ptx30wCrcType_t;

typedef struct
{
    ptx30wCrcType_t Type;
    uint16_t        State;
} ptx30wCrc_t;

/*
 * ####################################################################################################################
 * API FUNCTIONS
 * ####################################################################################################################
 */
/**
 * \brief Initializes the internal context data structure.
 *
 * \param[in] ctx  Valid pointer to a \ref ptx30wCrc_t data structure.
 * \param[in] type CRC type used for calculation (\ref ptx30wCrcType_t).
 *
 * \return Status of the operation see \ref ptxStatus_t
 */
ptxStatus_t ptx30wCrc_Init(ptx30wCrc_t *ctx, ptx30wCrcType_t type);

/**
 * \brief Used to feed new data into the CRC calculation.
 *
 * \param[in] ctx     Pointer to the \ref ptx30wCrc_t data structure.
 * \param[in] data    Pointer to the data, which shall be processed.
 * \param[in] dataLen Length of the data to be processed.
 *
 * \return Status of the operation see \ref ptxStatus_t
 */
ptxStatus_t ptx30wCrc_Update(ptx30wCrc_t *ctx, uint8_t *data, size_t dataLen);

/**
 * \brief Retrieves the result of the CRC calculation.
 *
 * \param[in]  ctx    Pointer to the \ref ptx30wCrc_t data structure.
 * \param[out] result Pointer to store the CRC result.
 *
 * \return Status of the operation see \ref ptxStatus_t
 */
ptxStatus_t ptx30wCrc_Result(ptx30wCrc_t *ctx, uint16_t *result);

#ifdef __cplusplus
}
#endif

#endif /* Guard */
