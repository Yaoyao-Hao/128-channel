/** \file
    ---------------------------------------------------------------
    Copyright (C) 2023. Panthronics AG - All Rights Reserved.

    This material may not be reproduced, displayed, modified or
    distributed without the express prior written permission of the
    Panthronics AG.

    PLEASE CHECK FURTHER DISCLAIMER IN FILE "PTX_LICENSE.TXT"
    ---------------------------------------------------------------

    Project     : PTX30W
    Module      : NSC
    File        : ptx30w_Nsc.c

    Description : Module implementing the NSC communication.
*/

/*
 * ####################################################################################################################
 * INCLUDES
 * ####################################################################################################################
 */
#include "ptx30w_Hip.h"
#include "ptx30w_Nsc.h"
#include "../plat/ptxPlat.h"

static volatile ptxTdcCtx_t s_TdcCtx;

const ptxRuntimeParamRights_t ptxNscRegisterDescriptor[PTX_NSC_PARAMS_LEN] =
{
    /** EOC                   */ {.Type = NscParamType_Eoc,                 .Access = NscAccessType_Restricted},
    /** BC_ICHG_CTRL          */ {.Type = NscParamType_BcIchgCtrl,          .Access = NscAccessType_Write},
    /** BC_VTERM_CTRL         */ {.Type = NscParamType_BcVtermCtrl,         .Access = NscAccessType_Write},
    /** BC_VTRK_CTRL          */ {.Type = NscParamType_BcVtrckCtrl,         .Access = NscAccessType_Write},
    /** BC_VRCHG_CTRL         */ {.Type = NscParamType_BcVrchgCtrl,         .Access = NscAccessType_Write},
    /** BC_ENABLE             */ {.Type = NscParamType_BcEnable,            .Access = NscAccessType_ReadWrite},
    /** HOST_WPT_DURATION_INT */ {.Type = NscParamType_HostWptDurationInt,  .Access = NscAccessType_Write},
    /** CUSTOM_NDEF_MESSAGE   */ {.Type = NscParamType_CustomNdefMsg,       .Access = NscAccessType_Write},
    /** SHIPPING_MODE_ENABLE  */ {.Type = NscParamType_ShippingModeEnable,  .Access = NscAccessType_Write},
    /** WPT_REQ_SEL           */ {.Type = NscParamType_WptReqSel,           .Access = NscAccessType_Write},
    /** DETUNE_ENABLE         */ {.Type = NscParamType_DetuneEnable,        .Access = NscAccessType_Write},
    /** NFC_ENABLE            */ {.Type = NscParamType_NfcEnable,           .Access = NscAccessType_Write}
};

/*
 * ####################################################################################################################
 * API FUNCTIONS
 * ####################################################################################################################
 */

void ptx30wNsc_Init()
{
    memset((ptxTdcCtx_t*) &s_TdcCtx, 0, sizeof(ptxTdcCtx_t));
}

 ptxStatus_t ptx30wNsc_WriteOemParameters(const ptxOemConfigParam_t *config)
 {
     ptxStatus_t status = ptxStatus_Success;

     if (NULL != config)
     {
         uint8_t index = 0;
         uint8_t txBuffer[sizeof(ptxOemConfigParam_t)]; /**< + 1 because of OPCODE byte. */

         /** Build the buffer. */
         txBuffer[index] = PTX_NSC_OPC_SETOEM;
         ++index;

         memcpy(&txBuffer[index], config, sizeof(ptxOemConfigParam_t) - 1U);
         index = (uint8_t)(index + sizeof(ptxOemConfigParam_t) - 1U);

         /** Send the assembled message. */
         status = ptx30wNsc_SendMessage(txBuffer, index);

         if (ptxStatus_Success == status)
         {
             /** Reserve memory for the response. */
             uint8_t resp[2];
             uint16_t resp_len = sizeof(resp);

             /** Receive the response. */
             status = ptx30wNsc_HandleResponse(resp, &resp_len, 20);

             if (ptxStatus_Success == status)
             {
                 /** Check the response, and its status code. */
                if( (2U == resp_len) && (PTX_NSC_OPC_SETOEM == resp[0]) )
                {
                    switch(resp[1])
                    {
                        case 0x00:
                            /** Reset the system to take over the new parameters. */
                            status = ptx30wHip_SystemReset(DFYS_SysResetDfyOn);
                            break;
                        case 0x01:
                            status = ptxStatus_InvalidCommand;
                            break;
                        case 0x03:
                            status = ptxStatus_NvmError;
                            break;
                        default:
                            status = ptxStatus_InternalError;
                            break;
                    }
                }
                else
                {
                    status = ptxStatus_NscProtocolError;
                }
             }
         }
     }
     else
     {
         status = ptxStatus_InvalidParameter;
     }

     return status;
 }

ptxStatus_t ptx30wNsc_ReadRuntimeParameters(ptxRuntimeParameters_t *params)
{
    ptxStatus_t status = ptxStatus_Success;
    if (NULL != params)
    {
        /** Send the NSC read command request. */
        uint8_t trxBuffer[PTX_NSC_BUFF_LEN];
        uint8_t index = 0U;

        /** Build the command. */
        trxBuffer[index] = PTX_NSC_OPC_GETPARAM;
        ++index;

        /** Send the assembled message. */
        status = ptx30wNsc_SendMessage(trxBuffer, index);

        /** Reserve memory for the response. */
        uint16_t rxBufferLen = sizeof(trxBuffer);

        if (ptxStatus_Success == status)
        {
            /** If the IRQ was triggered, then we can read data. */
            status = ptx30wNsc_HandleResponse(trxBuffer, &rxBufferLen, PTX_NSC_DEFAULT_TIMEOUT);
        }

        if (ptxStatus_Success == status)
        {
            /** Check the response, the status code and copy the received data. */
            if( (rxBufferLen == PTX_NSC_RUNTIME_RX_LEN) && (ptxNscError_NoError == trxBuffer[1]) )
            {
                uint8_t rx_index = 2U;
                params->BcEnable = trxBuffer[rx_index];
                ++rx_index;
                params->RffStatus = trxBuffer[rx_index];
                ++rx_index;
                params->ErrorStatus = trxBuffer[rx_index];
                ++rx_index;
                params->BcStatus = trxBuffer[rx_index];
                ++rx_index;
                params->VdbatAdcVal = trxBuffer[rx_index];
                ++rx_index;
                params->VddcAdcVal = trxBuffer[rx_index];
                ++rx_index;
                params->NtcStatus = trxBuffer[rx_index];
                ++rx_index;
                params->WlcpConnected = trxBuffer[rx_index];
            }
            else
            {
                status = ptxStatus_NscProtocolError;
            }
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wNsc_WriteRuntimeParameters(ptxRuntimeParam_t *params, uint8_t length)
{
    ptxStatus_t status = ptxStatus_Success;
    if (NULL != params)
    {
        /** Make sure that the requested parameters are in range and they have the rights. */
        for (uint8_t index = 0U; ((index < length) && (ptxStatus_Success == status)); index++)
        {
            if (NscParamType_NfcEnable < params[index].Type)
            {
                status = ptxStatus_InvalidParameter;
                break;
            }

            /** Check for rights. */
            if ((ptxNscRegisterDescriptor[params[index].Type].Access != NscAccessType_Write) &&
                (ptxNscRegisterDescriptor[params[index].Type].Access != NscAccessType_ReadWrite))
            {
                status = ptxStatus_NotPermitted;
                break;
            }
        }

        if (ptxStatus_Success == status)
        {
            /** Send the NSC read command request. */
            uint8_t txBuffer[PTX_NSC_BUFF_LEN];
            uint8_t index = 0U;

            /** Build the buffer. */
            txBuffer[index] = PTX_NSC_OPC_SETPARAM;
            ++index;

            for (uint8_t i = 0U; i < length; i++)
            {
                txBuffer[index] = params[i].Type;
                ++index;
                txBuffer[index] = params[i].Value;
                ++index;
            }
            txBuffer[index++] = PTX_NSC_OPC_EOC;

            status = ptx30wNsc_SendMessage(txBuffer, index);
        }

        /** Read back the requested data. */
        if (ptxStatus_Success == status)
        {
            uint8_t resp[2];
            uint16_t resp_len = sizeof(resp);
            status = ptx30wNsc_HandleResponse(resp, &resp_len, PTX_NSC_DEFAULT_TIMEOUT);

            if (ptxStatus_Success == status)
            {
                if( (2U == resp_len) && (PTX_NSC_OPC_SETPARAM == resp[0]) )
                {
                    if(ptxNscError_NoError != resp[1])
                    {
                        status = ptxStatus_InternalError;
                    }
                }
                else
                {
                    status = ptxStatus_NscProtocolError;
                }
            }
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }
    return status;
}

ptxStatus_t ptx30wNsc_SetCustomNdefMessage(uint8_t *data, uint8_t length)
{
    ptxStatus_t status = ptxStatus_Success;

    /** Validate all parameters. */
    if ( (NULL != data) && (0 != length) && (144 >= length) )
    {
        uint8_t txBuffer[148];
        uint8_t index = 0U;

        /** Build the buffer. */
        txBuffer[index] = PTX_NSC_OPC_SETPARAM;
        ++index;
        txBuffer[index] = NscParamType_CustomNdefMsg;
        ++index;
        txBuffer[index] = length;
        ++index;

        memcpy(&txBuffer[index], data, length);
        index = (uint8_t)(index + length);

        txBuffer[index] = PTX_NSC_OPC_EOC;
        ++index;

        status = ptx30wNsc_SendMessage(txBuffer, index);

        /** Read back the requested data. */
        if (ptxStatus_Success == status)
        {
            uint8_t response[PTX_NSC_HEADER_LEN];
            uint16_t responseLen = PTX_NSC_HEADER_LEN;
            status = ptx30wNsc_HandleResponse(response, &responseLen, PTX_NSC_DEFAULT_TIMEOUT);

            if (ptxStatus_Success == status)
            {
                if( (2U == responseLen) && (PTX_NSC_OPC_SETPARAM == response[0]) )
                {
                    if(ptxNscError_NoError != response[1])
                    {
                        status = ptxStatus_InternalError;
                    }
                }
                else
                {
                    status = ptxStatus_NscProtocolError;
                }
            }
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wNsc_SendMessage(const uint8_t *data, const uint16_t dataLength)
{
    ptxStatus_t status = ptxStatus_Success;

    /** Validate all parameters. */
    if ( (NULL != data) && (0U != dataLength) )
    {
        /** Write the message (currently only message buffer 0 is in use). */
        status = ptx30wHip_WriteMessage(0x00, data, dataLength);
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wNsc_GetResponse(uint8_t *data, uint16_t *dataLength, uint32_t timeoutMs)
{
    ptxStatus_t status = ptxStatus_Success;

    /** Validate all parameters. */
    if ( (NULL != data) && (NULL != dataLength) && (0U != *dataLength) )
    {
        /** Wait for the IRQ pin to go high. */
        status = ptxPlat_IRQ_WaitForIrq(timeoutMs);

        if (ptxStatus_Success == status)
        {
            /** Read the message. */
            status = ptx30wHip_ReadMessage(data, dataLength);
        }
        else
        {
            /** Explicitly set the variable to zero, in case we ran into an error. */
            *dataLength = 0;
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wNsc_HandleResponse(uint8_t *data, uint16_t *dataLength, uint32_t timeoutMs)
{
    ptxStatus_t status = ptxStatus_Success;

    /** Reserve memory (the NSC_DATA_MESSAGE is the longest message we can possibly receive!) */
    uint8_t response_data[PTX_NSC_DATA_MSG_LEN];
    uint16_t response_data_len = sizeof(response_data);

    /** The maximum length of an NSC message is 64 bytes (see NSC_DATA_MSG). */
    status = ptx30wNsc_GetResponse(response_data, &response_data_len, timeoutMs);

    /** An NSC_DATA_MSG can intercept any other message (e.g. response of a certain NSC_CMD) */
    if (ptxStatus_Success == status)
    {
        /** We always have to check if the received message was an NSC_DATA_MSG. */
        status = ptx30wNsc_Tdc_ProcessMessage(response_data, response_data_len);
    }

    if(ptxStatus_Success == status)
    {
        /**If the previous message was an NSC_DATA_MSG, we now need to retrieve the actual message! */
        status = ptx30wNsc_GetResponse(data, dataLength, timeoutMs);
    }
    else
    {
        /** If the previous message wasn't an NSC_DATA_MSG,  we just need to copy the data to the correct buffer! */
        if(*dataLength >= response_data_len)
        {
            memcpy(data, response_data, response_data_len);
            *dataLength = response_data_len;
            status = ptxStatus_Success;
        }
        else
        {
            /** Receive buffer not large enough, message will be lost! */
            status = ptxStatus_InsufficientResources;
        }
    }

    return status;
}

ptxStatus_t ptx30wNsc_Tdc_Handle()
{
    ptxStatus_t status = ptxStatus_Success;

    /** Reserve memory. */
    uint8_t msg_buffer[PTX_NSC_DATA_MSG_LEN];
    uint16_t msg_buffer_len = sizeof(msg_buffer);

    /** Check if interrupt pin is high. If so, read the message. */
    (void) ptx30wNsc_GetResponse(msg_buffer, &msg_buffer_len, 0u);

    /** Check if we have successfully received something. */
    if (0 != msg_buffer_len)
    {
        /** Check for TDC messages (either acknowledge or payload). */
        status = ptx30wNsc_Tdc_ProcessMessage(msg_buffer, msg_buffer_len);
    }

    return status;
}

ptxStatus_t ptx30wNsc_Tdc_ProcessMessage(uint8_t *data, uint16_t dataLength)
{
    ptxStatus_t status = ptxStatus_Success;

    /** Validate all parameters. */
    if ( (NULL != data) && (0 != dataLength) )
    {
        if( PTX_NSC_OPC_DATA == (data[0] & PTX_NSC_OPC_DATA_MSK) )
        {
            /** We either received an NSC_DATA_MSG_ACK or an NSC_DATA_MSG containing actual payload. */
            uint8_t payload_len = (data[0] & PTX_NSC_DATA_LEN_MSK);

            if(0 == payload_len)
            {
                /**
                 * We received an acknowledge message, indicating that the
                 * poller read the previous message we sent to it.
                 */
                s_TdcCtx.txStatus = TdcTxStatus_TxIdle;
            }
            else
            {
                /** Copy the data into the static TDC context. */
                memcpy((uint8_t*) s_TdcCtx.rxData, &data[PTX_NSC_DATA_HEADER_LEN], payload_len);
                s_TdcCtx.rxDataLen = (uint8_t) payload_len;
            }
        }
        else
        {
            status = ptxStatus_ProtocolError;
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wNsc_Tdc_TxMessage(uint8_t *data, uint16_t length)
{
    ptxStatus_t status = ptxStatus_Success;

    /** Validate all parameters. */
    if ( (NULL != data) && (0U < length) && (PTX_NSC_DATA_MSG_LEN > length) )
    {
        /** Reserve memory. */
        uint8_t txBuffer[PTX_NSC_DATA_MSG_LEN];

        /** First byte contains opcode and length of message. */
        txBuffer[0] = (uint8_t) (PTX_NSC_OPC_DATA | (PTX_NSC_DATA_LEN_MSK & length));

        /** Copy the payload into the reserved memory area. */
        memcpy(&txBuffer[PTX_NSC_DATA_HEADER_LEN], data, length);

        /** Send the message to the device. */
        status = ptx30wNsc_SendMessage(txBuffer, (length + PTX_NSC_DATA_HEADER_LEN));

        if(ptxStatus_Success == status)
        {
            /** If message was successfully sent, set txStatus to pending. */
            s_TdcCtx.txStatus = TdcTxStatus_TxPending;
            /**
             * As soon as the message was read by the poller, we will get an acknowledge message,
             * causing the txStatus to go back into "Idle" state.
             */
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wNsc_Tdc_TxMessageReceived(uint8_t *received)
{
    ptxStatus_t status = ptxStatus_Success;

    /** Validate the parameter. */
    if (NULL != received)
    {
        /** Explicitly set the variable to zero first. */
        *received = 0;

        /** Check if there are any pending TDC messages to be read. */
        status = ptx30wNsc_Tdc_Handle();

        if( (ptxStatus_Success == status) && (TdcTxStatus_TxIdle == s_TdcCtx.txStatus) )
        {
            /** In case txStatus is set back to "Idle" state, the message was received by the poller. */
            *received = 1u;
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wNsc_Tdc_RxMessage(uint8_t *data, uint8_t *length)
{
    ptxStatus_t status = ptxStatus_Success;

    /** Validate all parameters. */
    if ( (NULL != data) && (NULL != length) && (0U != *length) )
    {
        /** Check if there is payload in our context variable, which we have not read yet. */
        if(0 != s_TdcCtx.rxDataLen)
        {
            /** Check if there is payload in our context variable, which we have not read yet. */
            if(*length >= s_TdcCtx.rxDataLen)
            {
                /** Copy the payload. */
                memcpy(data, (uint8_t*) s_TdcCtx.rxData, s_TdcCtx.rxDataLen);
                /** Set the payload length. */
                *length = s_TdcCtx.rxDataLen;
                /** Set the payload length to zero within the context. */
                s_TdcCtx.rxDataLen = 0;
            }
            else
            {
                status = ptxStatus_InsufficientResources;
            }
        }
        else
        {
            /** Explicitly set the variable to zero, in case we didn't receive anything. */
            *length = 0;
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}
