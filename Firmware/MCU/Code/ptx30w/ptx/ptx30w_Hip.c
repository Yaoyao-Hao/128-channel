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
    File        : ptx30w_Hip.c

    Description : Module implementing the Host Interface Protocol (HIP).
*/

/*
 * ####################################################################################################################
 * INCLUDES
 * ####################################################################################################################
 */
#include "../plat/ptxPlat.h"
#include "ptx30w_Hip.h"
#include "ptx30w_Crc.h"

ptxStatus_t sendCmd(uint8_t *command, uint16_t length);
ptxStatus_t sendCmdRcvRsp(uint8_t *command, uint16_t length, uint8_t *resp, uint16_t respLen);
ptxStatus_t readMessageData(uint8_t *data, uint16_t numBytes);
ptxStatus_t readMessageLength(uint16_t *messageLength);
ptxStatus_t buildCommandHeader(uint8_t *command, uint16_t *length, uint8_t opCode);

static ptx30wHif_t sPtx30wHif;

/*
 * ####################################################################################################################
 * API FUNCTIONS
 * ####################################################################################################################
 */

ptxStatus_t ptx30wHip_InitHifParameters(const ptx30wHif_t *interface)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != interface)
    {
        memcpy(&sPtx30wHif, interface, sizeof(ptx30wHif_t));
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wHip_SystemReset(DFYS_t dfys)
{
    ptxStatus_t status = ptxStatus_Success;

    uint8_t command[HIP_HEADER_FOOTER_SIZE + 1U];
    uint16_t length = HIP_HEADER_SIZE;
    memset(command, 0, sizeof(command));

    command[length] = dfys;
    ++length;

    length = (uint16_t)(length - HIP_HEADER_SIZE);
    status = buildCommandHeader(command, &length, FCB_OPCODE_RST);

    if (ptxStatus_Success == status)
    {
        /** Send command trough I2C. */
        status = sendCmd(command, length);
    }

    if((DFYS_SysResetDfyOn) || (DFYS_NoSysResetDfyOn == dfys))
    {
        /** Give the system some time to boot up. */
        ptxPlat_Timer_Delay(PTX30W_SYSTEM_BOOTUP_DURATION);
    }

    return status;
}

ptxStatus_t ptx30wHip_ReadSystemStatus(uint8_t* systemStatus, uint8_t systemStatusLen)
{
    ptxStatus_t status = ptxStatus_Success;

    if( (NULL != systemStatus) && (0 != systemStatusLen))
    {
        uint8_t command[HIP_HEADER_FOOTER_SIZE + 2];
        uint16_t length = HIP_HEADER_SIZE;
        memset(command, 0, sizeof(command));

        command[length] = systemStatusLen;
        ++length;

        length = (uint16_t)(length - HIP_HEADER_SIZE);
        status = buildCommandHeader(command, &length, FCB_OPCODE_RSS);

        if (ptxStatus_Success == status)
        {
            /** Send command trough I2C. */
            uint8_t resp[HIP_DATA_CHUNK_SIZE];
            status = sendCmdRcvRsp(command, length, resp, systemStatusLen);

            if (ptxStatus_Success == status)
            {
                memcpy(systemStatus, &resp[HIP_HEADER_SIZE], systemStatusLen);
            }
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wHip_WriteMessage(uint8_t address, const uint8_t *data, uint16_t numBytes)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != data)
    {
        /** First we build the command. */
        uint16_t length = HIP_HEADER_SIZE;
        uint8_t command[HIP_HEADER_FOOTER_SIZE + HIP_ADDR_SIZE + HIP_DATA_CHUNK_SIZE];

        command[length] = address;
        ++length;

        memcpy(&command[length], data, numBytes);
        length = (uint16_t)((uint16_t)(length + numBytes) - HIP_HEADER_SIZE);

        /** After the command is in the buffer, we add the Header and CRC. */
        status = buildCommandHeader(command, &length, FCB_OPCODE_WMSG);
        if (ptxStatus_Success == status)
        {
            /** Send command trough I2C. */
            status = sendCmd(command, length);
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wHip_ReadMessage(uint8_t *data, uint16_t *numBytes)
{
    ptxStatus_t status = ptxStatus_Success;

    if ( (NULL != data) && (NULL != numBytes) && (0 < *numBytes) )
    {
        uint16_t temp_length = 0U;

        uint8_t retry = HIP_RETRY_CNT;
        do
        {
            status = readMessageLength(&temp_length);
            /** Wait a little bit before retrying. */
            if (0 == temp_length)
            {
                ptxPlat_Timer_Delay(1);
            }
            retry--;
        } while ((ptxStatus_Success != status) && (0 == temp_length) && (0 != retry));

        if(*numBytes >= temp_length)
        {
            *numBytes = temp_length;
        }
        else
        {
            status = ptxStatus_InsufficientResources;
        }

        if (ptxStatus_Success == status)
        {
            status = readMessageData(data, *numBytes);
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t readMessageData(uint8_t *data, uint16_t numBytes)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != data)
    {
        uint8_t command[HIP_HEADER_FOOTER_SIZE + HIP_ADDR_SIZE + HIP_LENGTH_SIZE];
        uint8_t resp[HIP_HEADER_FOOTER_SIZE + HIP_DATA_CHUNK_SIZE];
        uint16_t length = HIP_HEADER_SIZE;

        command[length] = (uint8_t)(numBytes >> 8);
        ++length;
        command[length] = (uint8_t)(numBytes);
        ++length;

        length = (uint16_t)(length - HIP_HEADER_SIZE);
        status = buildCommandHeader(command, &length, FCB_OPCODE_RMSG);

        if (ptxStatus_Success == status)
        {
            status = sendCmdRcvRsp(command, length, resp, numBytes);
        }

        if (ptxStatus_Success == status)
        {
            /** Transfer read bytes into read buffer. */
            memcpy(data, &resp[HIP_HEADER_SIZE], numBytes);
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t readMessageLength(uint16_t *messageLength)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != messageLength)
    {
        uint8_t command[HIP_HEADER_FOOTER_SIZE + HIP_ADDR_SIZE + HIP_LENGTH_SIZE];
        uint8_t resp[HIP_HEADER_FOOTER_SIZE + sizeof(uint16_t)];

        uint16_t length = 0;
        status = buildCommandHeader(command, &length, FCB_OPCODE_RML);

        if (ptxStatus_Success == status)
        {
            status = sendCmdRcvRsp(command, length, resp, sizeof(uint16_t));
        }

        if (ptxStatus_Success == status)
        {
            /** Decode the length. */
            *messageLength = (uint16_t)(
                ((uint16_t)(resp[HIP_HEADER_SIZE]) << 8U) | resp[(uint8_t)(HIP_HEADER_SIZE + 1)]);
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

/** Append the header to the command and also the CRC at the end of the command if it's the case. */
ptxStatus_t buildCommandHeader(uint8_t *command, uint16_t *length, uint8_t opCode)
{
    /** LEN (2 bytes) | FCB | ... Payload... | CRC (2 bytes) */
    ptxStatus_t status = ptxStatus_Success;

    uint8_t fcb;
    uint16_t index = 0;
    uint16_t len_field = 0;

    /** Let's calculate the length of the command. */
    /** Length of payload + 1 */
    len_field = (uint16_t) (*length + 1);

    if (sPtx30wHif.CrcPresent)
    {
        len_field = (uint16_t)(len_field + HIP_CRC_SIZE);
    }

    /** Let's build the header */
    sPtx30wHif.ChainingBit ? (fcb = 0x01) : (fcb = 0x00);
    sPtx30wHif.CrcPresent ? (fcb |= 0x02) : (fcb |= 0x00);
    sPtx30wHif.AkPresent ? (fcb |= 0x04) : (fcb |= 0x00);
    fcb = (uint8_t)(fcb | (opCode << 4));

    /** Put the header in the command. */
    command[index] = (uint8_t)(len_field >> 8);
    ++index;
    command[index] = (uint8_t)(len_field);
    ++index;
    command[index] = fcb;
    ++index;

    index = (uint16_t)(index + *length);

    if (sPtx30wHif.CrcPresent)
    {
        uint16_t crc;

        ptx30wCrc_t crcCtx;
        ptx30wCrc_Init(&crcCtx, ptx30wCrcType_NfcB);
        ptx30wCrc_Update(&crcCtx, command, index);
        ptx30wCrc_Result(&crcCtx, &crc);

        command[index] = (uint8_t)(crc);
        ++index;
        command[index] = (uint8_t)(crc >> 8);
        ++index;
    }

    *length = index;
    return status;
}

ptxStatus_t sendCmd(uint8_t *command, uint16_t length)
{
    ptxStatus_t status = ptxStatus_Success;

    status = ptxPlat_I2C_SetSlaveAddress(sPtx30wHif.I2cAddr);
    if (ptxStatus_Success == status)
    {
        uint8_t resp[HIP_RESP_SIZE];
        uint8_t respLen = 0;

        if (sPtx30wHif.AkPresent)
        {
           /** LEN (2 bytes) | FCB | ACK | CRC (2 bytes) => 6 bytes */
            respLen = HIP_RESP_SIZE;

            if (!sPtx30wHif.CrcPresent)
            {
                /** LEN (2 bytes) | FCB | ACK => 4 bytes */
               respLen = (uint8_t) (respLen - HIP_CRC_SIZE);
            }
        }

        status = ptxPlat_I2C_TRx_Retry(command, length, (respLen != 0 ? true : false), resp, respLen);

        if ( (ptxStatus_Success == status) && (sPtx30wHif.AkPresent) )
        {
            if(COMMAND_ACK != resp[HIP_HEADER_SIZE])
            {
                status = ptxStatus_NoAcknowledge;
            }
        }
    }

    return status;
}

ptxStatus_t sendCmdRcvRsp(uint8_t *command, uint16_t length, uint8_t *resp, uint16_t respLen)
{
    ptxStatus_t status = ptxStatus_Success;
    uint16_t expectedRx_len;

    status = ptxPlat_I2C_SetSlaveAddress(sPtx30wHif.I2cAddr);

    if (ptxStatus_Success == status)
    {
        if (sPtx30wHif.CrcPresent)
        {
            /** LEN (2 bytes) | FCB | CRC (2 bytes) + payload */
            expectedRx_len = (uint16_t)(HIP_HEADER_FOOTER_SIZE + respLen);

            status = ptxPlat_I2C_TRx_Retry(command, length, true, resp, expectedRx_len);

            if (ptxStatus_Success == status)
            {
                uint16_t calculated_crc;
                uint16_t received_crc = (uint16_t) ((resp[expectedRx_len - 1] << 8) | resp[expectedRx_len - 2]);

                ptx30wCrc_t crcCtx;
                ptx30wCrc_Init(&crcCtx, ptx30wCrcType_NfcB);
                ptx30wCrc_Update(&crcCtx, resp, expectedRx_len - HIP_CRC_SIZE);
                ptx30wCrc_Result(&crcCtx, &calculated_crc);

                if(received_crc != calculated_crc)
                {
                    status = ptxStatus_InterfaceError;
                }
            }
        }
        else
        {
            expectedRx_len = (uint16_t)(HIP_HEADER_SIZE + respLen);

            status = ptxPlat_I2C_TRx_Retry(command, length, true, resp, expectedRx_len);
        }
    }

    return status;
}

