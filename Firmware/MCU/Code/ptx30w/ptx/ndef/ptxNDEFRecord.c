/** \file
    ---------------------------------------------------------------
    Copyright (C) 2023. Panthronics AG - All Rights Reserved.

    This material may not be reproduced, displayed, modified or
    distributed without the express prior written permission of the
    Panthronics AG.

    PLEASE CHECK FURTHER DISCLAIMER IN FILE "PTX_LICENSE.TXT"
    ---------------------------------------------------------------

    Project     : PTX30W
    Module      : NDEF Record
    File        : ptxNDEFRecord.c

    Description : Generic NDEF Record API
*/


/*
 * ####################################################################################################################
 * INCLUDES
 * ####################################################################################################################
 */
#include "ptxNDEFRecord.h"

/*
 * ####################################################################################################################
 * INTERNAL FUNCTIONS / HELPERS
 * ####################################################################################################################
 */

/**
 * \brief Creates the NDEF header flags byte.
 *
 * \param[in]   record  Pointer to the NDEF record container.
 *
 * \return Constructed header byte.
 */
static uint8_t ptxNDEFRecord_ConstructHeaderFlags (ptxNDEFRecord_t *record);

/**
 * \brief Calculated the required buffer size of an NDEF record.
 *
 * \param[in]   record  Pointer to the NDEF record.
 *
 * \return Calculated size of record when written to a buffer.
 */
static size_t ptxNDEFRecord_CalcReqBufferSize(ptxNDEFRecord_t *ndefRecord);

/*
 * ####################################################################################################################
 * API FUNCTIONS
 * ####################################################################################################################
 */
ptxStatus_t ptxNDEFRecord_Init(ptxNDEFRecord_t *record)
{
    ptxStatus_t status = ptxStatus_Success;

    if(NULL != record)
    {
        memset(record, 0, sizeof(ptxNDEFRecord_t));
    } else
    {
      status = ptxStatus_InvalidParameter;
    }

    return status;
}


ptxStatus_t ptxNDEFRecord_Create (ptxNDEFRecord_t *record, ptxNDEFRecord_TNF_t tnf, uint8_t *type,
                                                                                uint8_t typeLen,
                                                                                uint8_t *id,
                                                                                uint8_t idLen,
                                                                                uint8_t *payload,
                                                                                size_t payloadLen)
{
    ptxStatus_t status = ptxStatus_Success;

    if(NULL != record)
    {
        record->HeaderFlags.TNF = (tnf & FLAG_MASK_TNF);

        if(NULL == type)
        {
            record->Type.Length = 0;
        } else
        {
            record->Type.bData = type;
            record->Type.Length = typeLen;
        }

        if(NULL == id)
        {
            record->ID.Length = 0;
        } else
        {
            record->ID.Data = id;
            record->ID.Length = idLen;
        }
        ptxNDEFRecord_SetIL(record, idLen);

        if(NULL == payload)
        {
            record->Payload.Length = 0;
        } else
        {
            record->Payload.Data = payload;
            record->Payload.Length = payloadLen;
        }
    } else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptxNDEFRecord_CreateEmptyRecord (ptxNDEFRecord_t *record)
{
    ptxStatus_t status;

    status = ptxNDEFRecord_Init(record);

    if(ptxStatus_Success == status)
    {
        status = ptxNDEFRecord_Create(record, TNF_EMPTY, NULL, 0u, NULL, 0u, NULL, 0);
    }

    return status;
}

static uint8_t ptxNDEFRecord_ConstructHeaderFlags (ptxNDEFRecord_t *record)
{
    uint8_t header = (uint8_t)  (((record->HeaderFlags.MB) ? FLAG_MASK_MB : 0x00) |
                                ((record->HeaderFlags.ME)  ? FLAG_MASK_ME : 0x00) |
                                ((record->HeaderFlags.CF)  ? FLAG_MASK_CF : 0x00) |
                                ((record->Payload.Length <= 255) ? FLAG_MASK_SR : 0x00) |
                                ((record->ID.Length != 0) ? FLAG_MASK_IL : 0x00)        |
                                (record->HeaderFlags.TNF & FLAG_MASK_TNF));
    return header;
}

static size_t ptxNDEFRecord_CalcReqBufferSize(ptxNDEFRecord_t *ndefRecord)
{
    size_t required_len = 0;
    required_len += 1; // HeaderByte
    required_len += 1; // Type.Length
    required_len += 1; // Payload.Length
    if(ndefRecord->HeaderFlags.IL)
    {
        required_len += 1; // Payload.LengthLength
    }
    required_len += ndefRecord->ID.Length;
    required_len += ndefRecord->Type.Length;
    required_len += ndefRecord->Payload.Length;
    return required_len;
}

ptxStatus_t ptxNDEFRecord_Write(ptxNDEFRecord_t *ndefRecord, uint8_t *dstBuffer, size_t dstBufferSize, size_t *dataWritten)
{
    ptxStatus_t status = ptxStatus_Success;

    if((NULL != dstBuffer) && (ptxNDEFRecord_CalcReqBufferSize(ndefRecord) <= dstBufferSize))
    {
        size_t buffer_prt = 0;
        dstBuffer[buffer_prt] = ptxNDEFRecord_ConstructHeaderFlags(ndefRecord);
        buffer_prt++;
        dstBuffer[buffer_prt] = ndefRecord->Type.Length;
        buffer_prt++;

        if(255u < ndefRecord->Payload.Length)
        {
            dstBuffer[buffer_prt] = (uint8_t) (ndefRecord->Payload.Length >> 24);
            buffer_prt++;
            dstBuffer[buffer_prt] = (uint8_t) (ndefRecord->Payload.Length >> 16);
            buffer_prt++;
            dstBuffer[buffer_prt] = (uint8_t) (ndefRecord->Payload.Length >>  8);
            buffer_prt++;
            dstBuffer[buffer_prt] = (uint8_t) (ndefRecord->Payload.Length >>  0);
            buffer_prt++;
        }
        else
        {
            dstBuffer[buffer_prt] = (uint8_t) ndefRecord->Payload.Length;
            buffer_prt++;
        }

        if(0 < ndefRecord->HeaderFlags.IL)
        {
            dstBuffer[buffer_prt] = (uint8_t) (ndefRecord->ID.Length);
            buffer_prt++;
        }

        if(0 < ndefRecord->Type.Length)
        {
            memcpy(&dstBuffer[buffer_prt], ndefRecord->Type.bData, ndefRecord->Type.Length);
            buffer_prt += ndefRecord->Type.Length;
        }

        if(0 < ndefRecord->ID.Length)
        {
            memcpy(&dstBuffer[buffer_prt], ndefRecord->ID.Data, ndefRecord->ID.Length);
            buffer_prt += ndefRecord->ID.Length;
        }

        if(0 < ndefRecord->Payload.Length)
        {
            memcpy(&dstBuffer[buffer_prt], ndefRecord->Payload.Data, ndefRecord->Payload.Length);
            buffer_prt += ndefRecord->Payload.Length;
        }

        *dataWritten = buffer_prt;
    } else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}
