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
    File        : ptx30w_Nsc.h
*/
#ifndef PTX_PTX30W_NSC_H_
#define PTX_PTX30W_NSC_H_

#include <stdbool.h>
#include "ptxStatus.h"

#ifdef __cplusplus
extern "C"
{
#endif

#define PTX_NSC_PARAMS_LEN          (12u)   /**< Amount of existing NSC parameters. */
#define PTX_NSC_BUFF_LEN            (128U)  /**< Buffer length for NSC transactions. */
#define PTX_NSC_CMD_OFFSET          (0U)    /**< Position of the command byte in the NSC header. */
#define PTX_NSC_ERR_CODE_OFFSET     (1U)    /**< Position of the error byte in the NSC header. */
#define PTX_NSC_HEADER_LEN          (2U)    /**< Length (in bytes) of the NSC header. */
#define PTX_NSC_OPC_EOC             (0x00)  /**< End of command terminator. */
#define PTX_NSC_OPC_SETOEM          (0x01)  /**< NSC command used to write the OEM parameters. */
#define PTX_NSC_OPC_SETPARAM        (0x02)  /**< NSC command used to write a runtime parameter. */
#define PTX_NSC_OPC_GETPARAM        (0x03)  /**< NSC command used to write a runtime parameter. */
#define PTX_NSC_OPC_DATA_MSK        (0xC0)  /**< Bitmask for NSC_DATA_MSG. */
#define PTX_NSC_OPC_DATA            (0x80)  /**< Opcode for NSC_DATA_MSG. */
#define PTX_NSC_DATA_MSG_LEN        (64U)   /**< Length of the NSC_DATA_MSG. */
#define PTX_NSC_DATA_MSG_PAYLOAD_LEN (63U)  /**< Maximum payload length for NSC_DATA_MSG. */
#define PTX_NSC_DATA_HEADER_LEN     (1U)    /**< Length of the data message header. */
#define PTX_NSC_DATA_LEN_MSK        (0x3F)  /**< Bit mask for retrieving the data message length. */
#define PTX_NSC_NDEF_MSG_MAX_LEN    (144U)  /**< Maximum length of the NSC_SET_PARAM_MSG when setting the custom NDEF message */
#define PTX_NSC_DEFAULT_TIMEOUT     (5U)    /**< Maximum length of the proprietary NDEF message within the OEM parameters. */
#define PTX_NSC_RUNTIME_RX_LEN      (10U)    /**< Expected response length when reading the NSC_RUNTIME params. */

/**
 * Transmit status for TDC.
 */
typedef enum ptxTdcTxStatus
{
    TdcTxStatus_TxIdle,     /**< Tx message was received by the poller. */
    TdcTxStatus_TxPending   /**< Tx message was not (yet) received by the poller. */
} ptxTdcTxStatus_t;

/**
 * Data structure containing the transmit status and also buffered RX messages (if there are any).
 */
typedef struct ptxTdcCtx
{
    uint8_t             rxData[PTX_NSC_DATA_MSG_PAYLOAD_LEN];
    uint8_t             rxDataLen;
    ptxTdcTxStatus_t    txStatus;
} ptxTdcCtx_t;

/** Existing NSC errors. */
typedef enum ptxNscError
{
    ptxNscError_NoError          = 0x00,
    ptxNscError_InvalidCommand   = 0x01,
    ptxNscError_InvalidParameter = 0x02
} ptxNscError_t;

/** Existing NSC parameter IDs. */
typedef enum ptxNscParamType
{
    NscParamType_Eoc                = 0x00,
    NscParamType_BcIchgCtrl         = 0x01,
    NscParamType_BcVtermCtrl        = 0x02,
    NscParamType_BcVtrckCtrl        = 0x03,
    NscParamType_BcVrchgCtrl        = 0x04,
    NscParamType_BcEnable           = 0x05,
    NscParamType_HostWptDurationInt = 0x06,
    NscParamType_CustomNdefMsg      = 0x07,
    NscParamType_ShippingModeEnable = 0x08,
    NscParamType_WptReqSel          = 0x09,
    NscParamType_DetuneEnable       = 0x0A,
    NscParamType_NfcEnable          = 0x0B
} ptxNscParamType_t;

/** NSC parameter access types */
typedef enum ptxNscParamAccessType
{
    NscAccessType_Restricted,
    NscAccessType_Read,
    NscAccessType_Write,
    NscAccessType_ReadWrite
} ptxNscParamAccessType_t;

/** NSC parameter access rights */
typedef struct ptxRuntimeParamRights
{
    ptxNscParamType_t       Type;   /** ID of the NSC parameter */
    ptxNscParamAccessType_t Access; /** Access of the register Read/Write */
} ptxRuntimeParamRights_t;

/** NSC parameter */
typedef struct ptxRuntimeParam
{
    ptxNscParamType_t   Type;   /** ID of the NSC parameter */
    uint8_t             Value;  /** Value of the parameter */
} ptxRuntimeParam_t;

/** NSC System Parameters */
typedef struct ptxRuntimeParameters
{
    uint8_t BcEnable;
    uint8_t RffStatus;
    uint8_t ErrorStatus;
    uint8_t BcStatus;
    uint8_t VdbatAdcVal;
    uint8_t VddcAdcVal;
    uint8_t NtcStatus;
    uint8_t WlcpConnected;
} ptxRuntimeParameters_t;

/** OEM parameters structure */
typedef union ptxOemConfigParam
{
    uint8_t Bytes[35];
    struct
    {
        uint8_t CAP_WT_INT;
        uint8_t NFC_ICHG;
        uint8_t VDBAT_OFFSET_HIGH;
        uint8_t VDBAT_OFFSET_LOW;
        uint8_t RFU1;
        uint8_t CURSENS_TH_SEL;
        uint8_t NFC_RESISTIVE_MODSET;
        uint8_t RFU2;
        uint8_t BC_COMB1;
        uint8_t BC_ENABLE;
        uint8_t BC_VTERM_OFFSET_COLD;
        uint8_t BC_VTERM_OFFSET_HOT;
        uint8_t BC_ICHG_PCT_COLD;
        uint8_t BC_ICHG_PCT_HOT;
        uint8_t BC_ITERM_CTRL;
        uint8_t BC_COMB0;
        uint8_t BC_VRCHG_CTRL;
        uint8_t BC_ICHG_CTRL;
        uint8_t BC_ILIM_SEL;
        uint8_t WPT_RESISTIVE_MODSET;
        uint8_t OEM_VDMCU_MODE;
        uint8_t I2C_SETTINGS;
        uint8_t GPIO_1_CONFIG;
        uint8_t GPIO_0_CONFIG;
        uint8_t VDDC_TH_LOW;
        uint8_t WPT_REQ_SEL;
        uint8_t OSC_EN_NTC_MODE;
        uint8_t ADJ_WPT_DURATION_INT;
        uint8_t TCM_WPT_DURATION_INT;
        uint8_t CCM_WPT_DURATION_INT;
        uint8_t CVM_WPT_DURATION_INT;
        uint8_t TCM_TIMEOUT;
        uint8_t CCM_TIMEOUT;
        uint8_t CVM_TIMEOUT;
        uint8_t DC_CHARGING;
    };
} ptxOemConfigParam_t;

/**
* \brief Initializes the NSC component.
*/
void ptx30wNsc_Init();

/**
* \brief Write OEM parameters into NVM.
*
* \param[in] config Pointer to the OEM parameter written to the 30W's NVM.
*
* \return Status of the operation see \ref ptxStatus_t.
*/
ptxStatus_t ptx30wNsc_WriteOemParameters(const ptxOemConfigParam_t *config);

/**
 * \brief Reads the current runtime parameters during operation.
 *
 * \param[in,out] params Pointer to the runtime parameter data structure containing the Parameter IDs that shall be read.
 * \param[in]     length Number of entries within the runtime parameter data structure.
 *
 * \return Status of the operation see \ref ptxStatus_t
 */
ptxStatus_t ptx30wNsc_ReadRuntimeParameters(ptxRuntimeParameters_t *params);

/**
 * \brief Sets the runtime parameters during device operation.
 *
 * \param[in] params Pointer to the runtime parameter data structure containing the Parameter IDs and values to be set.
 * \param[in] length Number of entries within the runtime parameter data structure.
 *
 * \return Status of the operation see \ref ptxStatus_t
 */
ptxStatus_t ptx30wNsc_WriteRuntimeParameters(ptxRuntimeParam_t *params, uint8_t length);

/**
* \brief Writes the custom NDEF message to the 30W.
*
* \param[in] data Pointer to the buffer to be written.
* \param[in] length Length if the buffer to be written.
*
* \return Status of the operation see \ref ptxStatus_t
*/
ptxStatus_t ptx30wNsc_SetCustomNdefMessage(uint8_t *data, uint8_t length);

/**
 * \brief Sends an NSC message to the PTX device.
 *
 * \param[in] data    Pointer to the NSC message.
 * \param[in] length  Length of the NSC message.
 *
 * \return Status of the operation see \ref ptxStatus_t
 */
ptxStatus_t ptx30wNsc_SendMessage(const uint8_t *data, const uint16_t dataLength);

/**
 * \brief Retrieves an NSC message from the PTX device.
 *
 * \param[in,out] data    Valid pointer to the data buffer, which shall store the NSC message.
 * \param[in,out] length  Pointer for storing the size of the data buffer.
 *
 * \return Status of the operation see \ref ptxStatus_t
 */
ptxStatus_t ptx30wNsc_GetResponse(uint8_t *data, uint16_t *dataLength, uint32_t timeoutMs);

/**
* \brief Reads out pending NSC response and stores them into the data buffer passed as argument.
*           NSC TDC messages are filtered out and handled by ptx30wNsc_Tdc_ProcessMessage().
*
* \param[in,out] data       Valid pointer to the data buffer, which shall store the NSC message.
* \param[in,out] length     Pointer for storing the size of the data buffer.
* \param[in]     timeoutMs  Timeout in milliseconds to wait for an NSC response.
*
* \return Status of the operation see \ref ptxStatus_t
*/
ptxStatus_t ptx30wNsc_HandleResponse(uint8_t *data, uint16_t *dataLength, uint32_t timeoutMs);

/**
* \brief Reads out any pending TDC messages (if there are any), and processes them.
* \return Status of the operation see \ref ptxStatus_t
*/
ptxStatus_t ptx30wNsc_Tdc_Handle();

/**
 * \brief Handles NSC TDC messages and stores the information in the TDC context.
 *
 * \param[in] data          Pointer to the data, to be transmitted
 * \param[in] dataLength    Length of the message
 *
 * \return Status of the operation see \ref ptxStatus_t
 */
ptxStatus_t ptx30wNsc_Tdc_ProcessMessage(uint8_t *data, uint16_t dataLength);

/**
 * \brief This function is used to send data from the Listener to the Poller via the
 *          transparent data channel.
 *
 * \param[in] data    Pointer to the data, to be transmitted
 * \param[in] length  Length of the data
 *
 * \return Status of the operation see \ref ptxStatus_t
 */
ptxStatus_t ptx30wNsc_Tdc_TxMessage(uint8_t *data, uint16_t length);

/**
* \brief Checks if the message contained within the 30W's buffer has been read by the poller.
*
* \param[in] pending    Pointer for storing the information, if the data was received.
*
* \return Status of the operation see \ref ptxStatus_t
*/
ptxStatus_t ptx30wNsc_Tdc_TxMessageReceived(uint8_t *pending);

/**
 * \brief Retrieves the data, sent from the Poller to the Listener via the
 *          transparent data channel.
 *
 * \param[in,out] data    Valid pointer to the data buffer, to store the received data.
 * \param[in,out] length  Pointer for storing the size of the data buffer.
 *
 * \return Status of the operation see \ref ptxStatus_t
 */
ptxStatus_t ptx30wNsc_Tdc_RxMessage(uint8_t *data, uint8_t *length);
#ifdef __cplusplus
}
#endif

#endif /*Guard*/
