/** \file
    ---------------------------------------------------------------
    Copyright (C) 2023. Panthronics AG - All Rights Reserved.

    This material may not be reproduced, displayed, modified or
    distributed without the express prior written permission of the
    Panthronics AG.

    PLEASE CHECK FURTHER DISCLAIMER IN FILE "PTX_LICENSE.TXT"
    ---------------------------------------------------------------

    Project     : PTX30W
    Module      : Generic NDEF RECORD API
    File        : ptxNDEFRecord.h

    Description : API for common NDEF record functions.
*/

/**
 * \addtogroup grp_ptx_api_ndef_record Generic NDEF Record API
 *
 * @{
 */

#ifndef APIS_PTX_NDEF_RECORD_H_
#define APIS_PTX_NDEF_RECORD_H_

/*
 * ####################################################################################################################
 * INCLUDES
 * ####################################################################################################################
 */

#include <stdint.h>
#include <string.h>
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
 * \brief Message begin flag
 */
#define FLAG_MASK_MB    (0x80)

/**
 * \brief Message end flag
 */
#define FLAG_MASK_ME    (0x40)

/**
 * \brief Chunked flag
 */
#define FLAG_MASK_CF    (0x20)

/**
 * \brief Short record flag
 */
#define FLAG_MASK_SR    (0x10)

/**
 * \brief ID length flag
 */
#define FLAG_MASK_IL    (0x08)

/**
 * \brief Type name field mask
 */
#define FLAG_MASK_TNF   (0x07)

/*
 * ####################################################################################################################
 * TYPES
 * ####################################################################################################################
 */

/**
 * \brief  Type Name Format Field Options
 */
typedef enum ptxNDEFRecord_TNF
{
    TNF_EMPTY           = 0x00,
    TNF_WELL_KNOWN_TYPE = 0x01,
    TNF_MEDIA_TYPE      = 0x02,
    TNF_ABSOLUTE_URI    = 0x03,
    TNF_EXTERNAL_TYPE   = 0x04,
    TNF_UNKNOWN         = 0x05,
    TNF_UNCHANGED       = 0x06
} ptxNDEFRecord_TNF_t;

typedef struct ptxNDEFRecord_Type
{
    uint8_t Length;
    union
    {
        char*    sData;
        uint8_t* bData;
    };
} ptxNDEFRecord_Type_t;

typedef struct ptxNDEFRecord_Id
{
    uint8_t Length;
    uint8_t* Data;
} ptxNDEFRecord_Id_t;

typedef struct ptxNDEFRecord_Payload
{
    size_t Length;
    uint8_t* Data;
} ptxNDEFRecord_Payload_t;

/**
 * \brief NDEF Record Header Flags
 */
typedef struct ptxNDEFRecord_HeaderFlags
{
    uint8_t MB;    /**< Message Begin Flag */
    uint8_t ME;    /**< Message End Flag */
    uint8_t CF;    /**< Chunk Flag */
    uint8_t SR;    /**< Short Record Flag */
    uint8_t IL;    /**< ID Length Flag */
    uint8_t TNF;   /**< Type Name Format Field */
} ptxNDEFRecord_HeaderFlags_t;

/**
 * \brief Generic NDEF Record container struct.
 */
typedef struct ptxNDEF_Record
{
    ptxNDEFRecord_HeaderFlags_t HeaderFlags;    /**< Record Header Byte */
    ptxNDEFRecord_Type_t        Type;           /**< Type Field */
    ptxNDEFRecord_Id_t          ID;             /**< ID Field */
    ptxNDEFRecord_Payload_t     Payload;        /**< Payload Field */
} ptxNDEFRecord_t;

/*
 * ####################################################################################################################
 * API FUNCTIONS
 * ####################################################################################################################
 */

/**
 * \brief Setter for NDEF record message begin flag.
 *
 * \param[in]   record  Pointer to the NDEF record container.
 * \param[in]   MB      Enable/Disable message begin flag.
 *
 * \return void
 */
static inline void ptxNDEFRecord_SetMB (ptxNDEFRecord_t *record, uint8_t MB)
{
    record->HeaderFlags.MB = (MB > 0 ? 1 : 0);
}

/**
 * \brief Setter for NDEF record message end flag.
 *
 * \param[in]   record  Pointer to the NDEF record container.
 * \param[in]   ME      Enable/Disable message end flag.
 *
 * \return void
 */
static inline void ptxNDEFRecord_SetME (ptxNDEFRecord_t *record, uint8_t ME)
{
    record->HeaderFlags.ME = (ME > 0 ? 1 : 0);
}

/**
 * \brief Setter for NDEF record chunked flag.
 *
 * \param[in]   record  Pointer to the NDEF record container.
 * \param[in]   CF      Enable/Disable chunked flag.
 *
 * \return void
 */
static inline void ptxNDEFRecord_SetCF(ptxNDEFRecord_t *record, uint8_t CF)
{
    record->HeaderFlags.CF = (CF > 0 ? 1 : 0);
}

/**
 * \brief Setter for NDEF record short record flag.
 *
 * \param[in]   record  Pointer to the NDEF record container.
 * \param[in]   SR      Enable/Disable short record flag.
 *
 * \return void
 */
static inline void ptxNDEFRecord_SetSR(ptxNDEFRecord_t *record, uint8_t SR)
{
    record->HeaderFlags.SR = (SR > 0 ? 1 : 0);
}

/**
 * \brief Setter for NDEF record ID length flag.
 *
 * \param[in]   record  Pointer to the NDEF record container.
 * \param[in]   MB      Enable/Disable ID length flag.
 *
 * \return void
 */
static inline void ptxNDEFRecord_SetIL(ptxNDEFRecord_t *record, uint8_t IL)
{
    record->HeaderFlags.IL = (IL > 0 ? 1 : 0);
}

/**
 * \brief Setter for NDEF record TNF byte.
 *
 * \param[in]   record  Pointer to the NDEF record container.
 * \param[in]   TNF     TNF byte to be written to the record
 *
 * \return void
 */
static inline void ptxNDEFRecord_SetTNF(ptxNDEFRecord_t *record, uint8_t TNF)
{
    record->HeaderFlags.TNF = TNF & FLAG_MASK_TNF;
}

/**
 * \brief Initializes NDEF record container.
 *
 * \param[in]   record  Pointer to the NDEF record container to be initialized.
 *
 * \return Status, indicating whether the operation was successful.
 */
ptxStatus_t ptxNDEFRecord_Init(ptxNDEFRecord_t *record);

/**
 * \brief Creates an NDEF record container from the given parameters.
 *
 * \param[in,out]   record      Pointer to an uninitialized NDEF record structure.
 * \param[in]       tnf         Type Name Format Field.
 * \param[in]       type        Pointer to the NDEF record type.
 * \param[in]       typeLen     Record type length.
 * \param[in]       id          Pointer to the NDEF Record ID.
 * \param[in]       idLen       Record ID length.
 * \param[in]       payload     Pointer to the payload data.
 * \param[in]       payloadLen  Payload data length.
 *
 * \return Status, indicating whether the operation was successful.
 */
ptxStatus_t ptxNDEFRecord_Create (ptxNDEFRecord_t *record, ptxNDEFRecord_TNF_t tnf, uint8_t *type,
                                                                                uint8_t typeLen,
                                                                                uint8_t *id,
                                                                                uint8_t idLen,
                                                                                uint8_t *payload,
                                                                                size_t payloadLen);

/**
 * \brief Prepares the ptxNDEFRecord_t struct to create an empty NDEF record.
 *
 * \param[in,out]   record  Pointer to the NDEF record container to be initialized as empty record.
 *
 * \return Status, indicating whether the operation was successful.
 */
ptxStatus_t ptxNDEFRecord_CreateEmptyRecord (ptxNDEFRecord_t *record);

/**
 * \brief Writes an ptxNDEFRecord_t struct to a given buffer.
 *
 * \param[in]       ndefRecord      Initialized NDEF record.
 * \param[in]       dstBuffer       Pointer to the buffer, which will contain the written data.
 * \param[in,out]   dstBufferSize   Length of the provided buffer.
 * \param[in,out]   dataWritten     Valid pointer to an integer, that will contain the actual amount of written data.
 *
 * \return Status, indicating whether the operation was successful.
 */
ptxStatus_t ptxNDEFRecord_Write(ptxNDEFRecord_t *ndefRecord, uint8_t *dstBuffer, size_t dstBufferSize, size_t *dataWritten);

#ifdef __cplusplus
}
#endif

/** @} */

#endif /* Guard */
