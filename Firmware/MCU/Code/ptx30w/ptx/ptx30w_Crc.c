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
    File        : ptx30w_Crc.c

    Description : Module implementing CRC calculation.
*/

/*
 * ####################################################################################################################
 * INCLUDES
 * ####################################################################################################################
 */
#include "ptx30w_Crc.h"

#define NFC_A_CRC_INITIAL_STATE (0x6363)
#define NFC_B_CRC_INITIAL_STATE (0xFFFF)

/*
 * ####################################################################################################################
 * API FUNCTIONS
 * ####################################################################################################################
 */

ptxStatus_t ptx30wCrc_Init(ptx30wCrc_t *ctx, ptx30wCrcType_t type)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != ctx)
    {
        ctx->Type = type;

        switch(ctx->Type)
        {
            case ptx30wCrcType_NfcA:
                ctx->State = NFC_A_CRC_INITIAL_STATE;
                break;
            case ptx30wCrcType_NfcB:
                ctx->State = NFC_B_CRC_INITIAL_STATE;
                break;
            default:
               status = ptxStatus_InvalidParameter;
               break;
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wCrc_Update(ptx30wCrc_t *ctx, uint8_t *data, size_t dataLen)
{
    ptxStatus_t status = ptxStatus_Success;

    if ( (NULL != ctx) && (NULL != data) )
    {
        size_t temp_len = dataLen;

        do
        {
            uint8_t b = *data;
            ++data;

            /** Feed the input into the shift registers and XOR with CRC. */
            b = (b ^ (uint8_t)(ctx->State & 0x00FF));
            b = (uint8_t)(b ^ (b << 4));

            /** Calculate the CRC value */
            ctx->State = (uint16_t) ((ctx->State >> 8) ^ (uint32_t)((b << 8) ^ (b << 3) ^ (b >> 4)));
            --temp_len;
        }

        while(0 != temp_len);
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wCrc_Result(ptx30wCrc_t *ctx, uint16_t *result)
{
    ptxStatus_t status = ptxStatus_Success;

    if ( (NULL != ctx) && (NULL != result) )
    {
        switch(ctx->Type)
        {
            case ptx30wCrcType_NfcA:
                *result = ctx->State;
                break;
            case ptx30wCrcType_NfcB:
                *result = ~ctx->State;
                break;
            default:
                status = ptxStatus_InvalidParameter;
                break;
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}
