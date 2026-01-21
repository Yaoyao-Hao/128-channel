/** \file
    ---------------------------------------------------------------
    Copyright (C) 2023. Panthronics AG - All Rights Reserved.

    This material may not be reproduced, displayed, modified or
    distributed without the express prior written permission of the
    Panthronics AG.

    PLEASE CHECK FURTHER DISCLAIMER IN FILE "PTX_LICENSE.TXT"
    ---------------------------------------------------------------

    Project     : PTX30W
    Module      : HIP Internal
    File        : ptx30w_Hip_Int.c

    Description : Module implementing the internal Host Interface Protocol (HIP).
*/

/*
 * ####################################################################################################################
 * INCLUDES
 * ####################################################################################################################
 */
#include "ptx30w_Hip_Int.h"
#include "ptx30w_Registers_Int.h"
#include "../plat/ptxPlat.h"
#include <stdio.h>

extern ptxStatus_t buildCommandHeader(uint8_t *command, uint16_t *length, uint8_t opCode);
extern ptxStatus_t sendCmd(uint8_t *command, uint16_t length);
extern ptxStatus_t sendCmdRcvRsp(uint8_t *command, uint16_t length, uint8_t *resp, uint16_t respLen);

/*
 * ####################################################################################################################
 * API FUNCTIONS
 * ####################################################################################################################
 */
ptxStatus_t ptx30wHip_ReadCodeMemory(uint16_t address, uint16_t *data, uint16_t numWords)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != data)
    {
        uint8_t command[HIP_HEADER_FOOTER_SIZE + HIP_ADDR_SIZE + HIP_LENGTH_SIZE];
        uint8_t resp[HIP_HEADER_FOOTER_SIZE + HIP_DATA_CHUNK_SIZE];
        uint16_t length = HIP_HEADER_SIZE;

        /** Add address and number of words - read mem. is asking for nr. of words. */
        command[length] = (uint8_t)(address >> 8);
        ++length;
        command[length] = (uint8_t)(address);
        ++length;
        command[length] = (uint8_t)(numWords >> 8);
        ++length;
        command[length] = (uint8_t)(numWords);
        ++length;
        length = (uint16_t)(length - HIP_HEADER_SIZE);

        /** Add the command header. */
        status = buildCommandHeader(command, &length, FCB_OPCODE_RCM);
        if (ptxStatus_Success == status)
        {
            /** Send data over I2C. */
            status = sendCmdRcvRsp(command, length, resp, (uint16_t)(numWords * 2U));
        }
        if (ptxStatus_Success == status)
        {
            /** Transfer read bytes into read buffer. */
            for (uint8_t i = 0; i < numWords; i++)
            {
                /** Omit the packet header. */
                uint8_t byteIndex = (uint8_t)(HIP_HEADER_SIZE + (i * 2U));
                data[i] = (uint16_t)(
                    ((uint16_t)(resp[byteIndex]) << 8U) + resp[(uint8_t)(byteIndex + 1U)]);
            }
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }
    return status;
}

ptxStatus_t ptx30wHip_WriteCodeMemory(uint16_t address, uint16_t *data, uint16_t numWords, bool verify)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != data)
    {
        for (uint16_t i = 0; (ptxStatus_Success == status) && i < numWords; i++)
        {
            status = ptx30wHip_WritePage(address + i, data[i], verify);
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }
    return status;
}

ptxStatus_t ptx30wHip_WritePage(uint16_t address, uint16_t data, bool verify)
{
    ptxStatus_t status = ptxStatus_Success;

    uint16_t cmdLen = HIP_HEADER_SIZE; /** First we build the command */
    uint8_t command[HIP_HEADER_FOOTER_SIZE + HIP_ADDR_SIZE + MEM_WRITE_PAGE_LEN];

    command[cmdLen] = (uint8_t)(address >> 8);
    ++cmdLen;
    command[cmdLen] = (uint8_t)(address);
    ++cmdLen;
    command[cmdLen] = (uint8_t)(data >> 8);
    ++cmdLen;
    command[cmdLen] = (uint8_t)(data);
    ++cmdLen;

    cmdLen = (uint16_t)(cmdLen - HIP_HEADER_SIZE);

    status = buildCommandHeader(command, &cmdLen, FCB_OPCODE_WCM);
    if (ptxStatus_Success == status)
    {
        status = sendCmd(command, cmdLen);
        ptxPlat_Timer_Delay(1);
    }

    if(verify)
    {
        uint16_t rdata = 0x00;

        if (ptxStatus_Success == status)
        {
            status = ptx30wHip_ReadCodeMemory(address, &rdata, 1);
        }

        if (ptxStatus_Success == status)
        {
            if (data != rdata)
            {
                status = ptxStatus_InternalError;
            }
        }
    }

    return status;
}

ptxStatus_t ptx30wHip_ReadDataMemory(uint16_t address, uint8_t *data, uint16_t numBytes)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != data)
    {
        uint8_t command[HIP_HEADER_FOOTER_SIZE + HIP_ADDR_SIZE + HIP_LENGTH_SIZE];
        uint8_t resp[HIP_HEADER_FOOTER_SIZE + HIP_DATA_CHUNK_SIZE];
        uint16_t length = HIP_HEADER_SIZE;

        command[length] = (uint8_t)(address >> 8);
        ++length;
        command[length] = (uint8_t)(address);
        ++length;
        command[length] = (uint8_t)(numBytes >> 8);
        ++length;
        command[length] = (uint8_t)(numBytes);
        ++length;

        length = (uint16_t)(length - HIP_HEADER_SIZE);
        status = buildCommandHeader(command, &length, FCB_OPCODE_RDM);
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

ptxStatus_t ptx30wHip_WriteDataMemory(uint16_t address, const uint8_t *data, uint16_t numBytes)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != data)
    {
        /** First we build the command. */
        uint16_t length = HIP_HEADER_SIZE;
        uint8_t command[HIP_HEADER_FOOTER_SIZE + HIP_ADDR_SIZE + HIP_DATA_CHUNK_SIZE];

        command[length] = (uint8_t)(address >> 8);
        ++length;
        command[length] = (uint8_t)(address);
        ++length;

        memcpy(&command[length], data, numBytes);
        length = (uint16_t)((uint16_t)(length + numBytes) - HIP_HEADER_SIZE);

        /** After the command is in the buffer, we add the Header and CRC. */
        status = buildCommandHeader(command, &length, FCB_OPCODE_WDM);
        if (ptxStatus_Success == status)
        {
            status = sendCmd(command, length);
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }
    return status;
}

ptxStatus_t ptx30wHip_ReadDbgInterface(uint8_t address, uint8_t *data, uint8_t numBytes)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != data)
    {
        uint8_t command[HIP_HEADER_FOOTER_SIZE + HIP_ADDR_SIZE + HIP_LENGTH_SIZE];
        uint8_t resp[HIP_HEADER_FOOTER_SIZE + HIP_DATA_CHUNK_SIZE];
        uint16_t length = HIP_HEADER_SIZE;

        command[length] = (address);
        ++length;
        command[length] = (numBytes);
        ++length;

        length = (uint16_t)(length - HIP_HEADER_SIZE);
        status = buildCommandHeader(command, &length, FCB_OPCODE_RDBG);

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

ptxStatus_t ptx30wHip_WriteDbgInterface(uint8_t address, const uint8_t *data, uint8_t numBytes)
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
        status = buildCommandHeader(command, &length, FCB_OPCODE_WDBG);
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

ptxStatus_t ptx30wHip_ReadDFTInterface(uint8_t address, uint8_t *data, uint8_t numBytes)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != data)
    {
        uint8_t command[HIP_HEADER_FOOTER_SIZE + HIP_ADDR_SIZE + HIP_LENGTH_SIZE];
        uint8_t resp[HIP_HEADER_FOOTER_SIZE + HIP_DATA_CHUNK_SIZE];
        uint16_t length = HIP_HEADER_SIZE;

        command[length] = (address);
        ++length;
        command[length] = (numBytes);
        ++length;

        length = (uint16_t)(length - HIP_HEADER_SIZE);
        status = buildCommandHeader(command, &length, FCB_OPCODE_RDFT);

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

ptxStatus_t ptx30wHip_WriteDftInterface(uint8_t address, const uint8_t *data, uint8_t numBytes)
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
        status = buildCommandHeader(command, &length, FCB_OPCODE_WDFT);
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
