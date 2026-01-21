/** \file
    ---------------------------------------------------------------
    Copyright (C) 2023. Panthronics AG - All Rights Reserved.

    This material may not be reproduced, displayed, modified or
    distributed without the express prior written permission of the
    Panthronics AG.

    PLEASE CHECK FURTHER DISCLAIMER IN FILE "PTX_LICENSE.TXT"
    ---------------------------------------------------------------

    Project     : PTX30W
    Module      : HIP
    File        : ptx30w_Hip.h
*/
#ifndef PTX_PTX30W_HIP_H_
#define PTX_PTX30W_HIP_H_

#include <stdbool.h>
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
#define HIP_DATA_CHUNK_SIZE             (256U)  /** Max. number of payload transmitted at once. */
#define HIP_CRC_SIZE                    (2U)    /** Size of the CRC from the command. */
#define HIP_LENGTH_SIZE                 (2U)    /** Size of the length from the command. */
#define HIP_ADDR_SIZE                   (2U)    /** Size of the address from the command. */
#define HIP_HEADER_SIZE                 (3U)    /** Size of the packet header. */
#define HIP_HEADER_FOOTER_SIZE          (HIP_HEADER_SIZE + HIP_CRC_SIZE) /** Size of the header of the command + CRC footer. */
#define HIP_RESP_SIZE                   (6U)    /** LEN (2 bytes) | FCB | ACK | CRC (2 bytes) => 6 bytes */
#define HIP_RETRY_CNT                   (2U)    /** Retry count for NSC CMDs */

/** Defines for PTX30W command set */
#define COMMAND_ACK                     (0x00)
#define COMMAND_NAK_INVALID_CMD         (0x01)
#define COMMAND_NAK_INVALID_LEN         (0x02)
#define COMMAND_NAK_CRC_ERROR           (0x03)
#define COMMAND_NAK_INVALID_PARAM       (0x04)
#define COMMAND_NAK_WRITE_BUFFER_FULL   (0x05)

/** Defines for PTX30W FCB. */
#define FCB_OPCODE_RST                  (0x01)
#define FCB_OPCODE_RSS                  (0x02)
#define FCB_OPCODE_RCM                  (0x06)
#define FCB_OPCODE_WMSG                 (0x07)
#define FCB_OPCODE_RMSG                 (0x08)
#define FCB_OPCODE_RML                  (0x09)

#define PTX30W_SYSTEM_BOOTUP_DURATION   (10)

/*
 * ####################################################################################################################
 * TYPES
 * ####################################################################################################################
 */
typedef enum ptxCommandStatus
{
    DeviceState_OK           = COMMAND_ACK,
    DeviceState_InvalidCmd   = COMMAND_NAK_INVALID_CMD,
    DeviceState_InvalidLen   = COMMAND_NAK_INVALID_LEN,
    DeviceState_CrcError     = COMMAND_NAK_CRC_ERROR,
    DeviceState_InvalidParam = COMMAND_NAK_INVALID_PARAM,
    DeviceState_BufferFull   = COMMAND_NAK_WRITE_BUFFER_FULL,
    DeviceState_Max
} ptxCommandStatus_t;

/** System reset DFY states */
typedef enum
{
    DFYS_SysResetDfyOff,   /** Perform system reset and disable DFY afterwards. */
    DFYS_SysResetDfyOn,    /** Perform system reset and enable DFY afterwards. */
    DFYS_NoSysResetDfyOff, /** Disable DFY without system reset. */
    DFYS_NoSysResetDfyOn   /** Enable DFY without system reset. */
} DFYS_t;

/** Initialization parameters for HIF */
typedef struct
{
    uint8_t I2cAddr;        /** I2C address of the PTX30W chip. */
    bool    CrcPresent;     /** Flag indicating that the CRC check is present in the message. */
    bool    AkPresent;      /** Flag informing PTX chip that it must return ACK. */
    bool    ChainingBit;    /** Flag indicating that there is a chained transmission. */
} ptx30wHif_t;

/*
 * ####################################################################################################################
 * API FUNCTIONS
 * ####################################################################################################################
 */
/**
 * \brief Initializes the HIF parameters.
 *
 * \param[in] interface Pointer to initialized interface parameters.
 *
 * \return Status of the operation see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wHip_InitHifParameters(const ptx30wHif_t *interface);

/**
 * \brief Perform software reset of the PTX30W.
 *
 * \param[in] dfys Type of the reset (\ref DFYS_t).
 *
 * \return Status of the operation see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wHip_SystemReset(DFYS_t dfys);

/**
 * \brief Reads the system status of the PTX30W.
 *
 * \param TODO (not yet specified).
 *
 * \return Status of the operation see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wHip_ReadSystemStatus(uint8_t* systemStatus, uint8_t systemStatusLen);

/**
 * \brief  Write message is used to send an NSC message to the PTX device.
 *
 * \param[in] address  8-bit logical address of the PTX devices' input buffer.
 * \param[in] data     pointer to the content of the message.
 * \param[in] numBytes length of the message.
 *
 * \return Status of the operation see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wHip_WriteMessage(uint8_t address, const uint8_t *data, uint16_t numBytes);

/**
 * \brief  Read message is used to retrieve a message from the PTX device. Reading
 *          messages only makes sense, if the PTX device indicates a new message
 *          via its IRQ pin.
 *
 * \param[in,out] data     Pointer where the message shall be stored
 * \param[in,out] numBytes Length of the message
 *
 * \return Status of the operation see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wHip_ReadMessage(uint8_t *data, uint16_t *numBytes);

#ifdef __cplusplus
}
#endif

#endif /* Guard */
