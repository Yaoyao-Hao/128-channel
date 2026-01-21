/** \file
    ---------------------------------------------------------------
    Copyright (C) 2023. Panthronics AG - All Rights Reserved.

    This material may not be reproduced, displayed, modified or
    distributed without the express prior written permission of the
    Panthronics AG.

    PLEASE CHECK FURTHER DISCLAIMER IN FILE "PTX_LICENSE.TXT"
    ---------------------------------------------------------------

    Project     : PTX30W
    Module      : PTX30W API
    File        : ptx30w.c

    Description : Main API
*/

/*
 * ####################################################################################################################
 * INCLUDES
 * ####################################################################################################################
 */
#include "../plat/ptxPlat.h"
#include "ptx30w.h"
#include "ptx30w_Hip.h"
#include "ptx30w_Hip_Int.h"
#include "ptx30w_Nsc.h"
#include <string.h>

/**
 * \brief Converts the digital value from the voltage monitor into millivolts.
 *
 * \param adcVal Digital value measured by the VoltageMonitor.
 * \return Voltage in millivolts.
 */
static uint16_t adcToMv(uint8_t adcVal);

/*
 * ####################################################################################################################
 * API FUNCTIONS
 * ####################################################################################################################
 */

ptxStatus_t ptx30w_Init(uint8_t address, bool crc, bool ack)
{
    ptxStatus_t status;

    status = ptxPlat_I2C_Init();

    if (ptxStatus_Success == status)
    {
        status = ptxPlat_IRQ_Init();
    }

    if (ptxStatus_Success == status)
    {
        /** Configure the PTX30W Command interface. */
        const ptx30wHif_t ptx30wHifCfg =
        {
            .ChainingBit = false,
            .AkPresent = ack,
            .CrcPresent = crc,
            .I2cAddr = address
        };

        status = ptx30wHip_InitHifParameters(&ptx30wHifCfg);
    }

    ptxDeviceInformation_t device_information;
    memset(&device_information, 0, sizeof(ptxDeviceInformation_t));

    if (ptxStatus_Success == status)
    {
        (void) ptx30wNsc_Init();

        /** Dummy communication to test if communication via I2C bus. */
        status = ptx30w_GetDeviceInformation(&device_information);
    }

    if ((ptxStatus_Success == status) && (PTX30W_HW_VERSION != device_information.HardwareVersion))
    {
        status = ptx30wHip_ReadDataMemory(0x37, &device_information.HardwareVersion, 1);

        if((ptxStatus_Success == status) && (PTX30W_HW_VERSION != device_information.HardwareVersion))
        {
            status = ptxStatus_WrongHardware;
        }
    }

    return status;
}

void ptx30w_Deinit()
{
    (void) ptxPlat_IRQ_Deinit();
    (void) ptxPlat_I2C_Deinit();
}

ptxStatus_t ptx30w_GetDeviceInformation(ptxDeviceInformation_t *deviceInfo)
{
    ptxStatus_t status = ptxStatus_Success;

    if(NULL != deviceInfo)
    {
        uint8_t req_len = PTX30W_DEVICEINFO_LEN;
        uint8_t buffer[req_len];

        memset(buffer, 0, req_len);

        status = ptx30wHip_ReadSystemStatus(buffer, req_len);

        if(ptxStatus_Success == status)
        {
            /** Map the parameters. */
            deviceInfo->CommandStatus = buffer[0];
            deviceInfo->HardwareVersion = buffer[1];
            deviceInfo->FirmwareVersion = (uint16_t) ((((uint16_t)buffer[2]) << 8U) | ((uint16_t)buffer[3]));
            memcpy(deviceInfo->DieInfo, &buffer[4], PTX30W_DIEINFO_LEN);
            deviceInfo->OemValid = buffer[20];
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30w_GetSystemStatus(ptxSystemStatus_t *systemStatus)
{
    ptxStatus_t status = ptxStatus_Success;

    if(NULL != systemStatus)
    {
        memset(systemStatus, 0, sizeof(ptxSystemStatus_t));

        ptxRuntimeParam_t parameters[PTX30W_SYS_GET_PARAM_CNT];
        memset(parameters, 0, sizeof(ptxRuntimeParam_t) * PTX30W_SYS_GET_PARAM_CNT);

        ptxRuntimeParameters_t system_params;

        status = ptx30wNsc_ReadRuntimeParameters(&system_params);

        if(ptxStatus_Success == status)
        {
            /** Remap the parameters. */
            systemStatus->ChargerEnabled    = (0U != system_params.BcEnable ? true : false);
            systemStatus->RfFieldDetected   = (0U != system_params.RffStatus ? true : false);
            systemStatus->Error             = (ptxErrorStatus_t) system_params.ErrorStatus;
            systemStatus->ChargerStatus     = (ptxBcStatus_t) system_params.BcStatus;
            systemStatus->VddBat            = adcToMv(system_params.VdbatAdcVal);
            systemStatus->VddC              = adcToMv(system_params.VddcAdcVal);
            systemStatus->NtcStatus         = (ptxNtcStatus_t) system_params.NtcStatus;
            systemStatus->WlcpStatus        = (system_params.WlcpConnected & PTX30W_WLCP_STATUS_MASK);
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30w_SetChargingParams(ptxChargingParams_t *chargingParams)
{
    ptxStatus_t status = ptxStatus_Success;

    if(NULL != chargingParams)
    {
        ptxRuntimeParam_t parameters[5];
        memset(parameters, 0, sizeof(parameters));

        /** Define all the parameters we want to retrieve from the device. */
        parameters[0].Type = NscParamType_BcIchgCtrl;
        parameters[0].Value = (uint8_t) (MASK_BC_ICHG_CTRL & (((chargingParams->ChargeCurrent - 1U) >> 1U) << POS_BC_ICHG_CTRL));

        parameters[1].Type = NscParamType_BcVtermCtrl;
        parameters[1].Value = (uint8_t) (MASK_BC_VTERM_CTRL & (chargingParams->TerminationVoltage << POS_BC_VTERM_CTRL));

        parameters[2].Type = NscParamType_BcVtrckCtrl;
        parameters[2].Value = (uint8_t) (MASK_BC_VTRK_CTRL & (chargingParams->TrickleVoltage << POS_BC_VTRK_CTRL));

        parameters[3].Type = NscParamType_BcVrchgCtrl;
        parameters[3].Value = (uint8_t) (MASK_BC_VRCHG_CTRL & (chargingParams->RechargeVoltage << POS_BC_VRCHG_CTRL));

        parameters[4].Type = NscParamType_BcEnable;
        parameters[4].Value = chargingParams->EnableCharging;

        status = ptx30wNsc_WriteRuntimeParameters(parameters, 5);
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30w_SetHostWptDuration(ptx30wWptDuration_t wptDuration)
{
    ptxRuntimeParam_t parameters[1];
    memset(parameters, 0, sizeof(parameters));

    parameters[0].Type = NscParamType_HostWptDurationInt;
    parameters[0].Value = (MASK_CCM_WPT_DURATION_INT & (wptDuration << POS_CCM_WPT_DURATION_INT));

    ptxStatus_t status = ptx30wNsc_WriteRuntimeParameters(parameters, 1);

    return status;
}

ptxStatus_t ptx30w_EnterShippingMode()
{
    ptxRuntimeParam_t parameters[1];
    memset(parameters, 0, sizeof(parameters));

    parameters[0].Type = NscParamType_ShippingModeEnable;
    parameters[0].Value = 1u;

    ptxStatus_t status = ptx30wNsc_WriteRuntimeParameters(parameters, 1);

    return status;
}

ptxStatus_t ptx30w_SetWptReqSel(ptx30wWptReqSel_t wptReqSel)
{
    ptxRuntimeParam_t parameters[1];
    memset(parameters, 0, sizeof(parameters));

    parameters[0].Type = NscParamType_WptReqSel;
    parameters[0].Value = (MASK_WPT_REQ_SEL & (wptReqSel << POS_WPT_REQ_SEL));

    ptxStatus_t status = ptx30wNsc_WriteRuntimeParameters(parameters, 1);

    return status;
}

ptxStatus_t ptx30w_EnableDetuning(bool enable)
{
    ptxRuntimeParam_t parameters[1];
    memset(parameters, 0, sizeof(parameters));

    parameters[0].Type = NscParamType_DetuneEnable;
    parameters[0].Value = ( enable ? 1U : 0U );

    ptxStatus_t status = ptx30wNsc_WriteRuntimeParameters(parameters, 1);

    return status;
}

ptxStatus_t ptx30w_EnableNfc(bool enable)
{
    ptxRuntimeParam_t parameters[1];
    memset(parameters, 0, sizeof(parameters));

    parameters[0].Type = NscParamType_NfcEnable;
    parameters[0].Value = ( enable ? 1U : 0U );

    ptxStatus_t status = ptx30wNsc_WriteRuntimeParameters(parameters, 1);

    return status;
}

ptxStatus_t ptx30w_SetCustomNdefMessage(ptxNDEFRecord_t *records, uint8_t recordsLen)
{
    ptxStatus_t status = ptxStatus_Success;

    if( (NULL != records) && (0 != recordsLen) )
    {
        uint8_t rec_data[144];
        size_t rec_data_len = sizeof(rec_data);

        status = ptxNDEFMessage_Create(records, recordsLen, rec_data,  &rec_data_len);

        if (ptxStatus_Success == status)
        {
            status = ptx30wNsc_SetCustomNdefMessage(rec_data, (uint8_t) rec_data_len);
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30w_WriteOemParameters(const ptxOemConfigParam_t *oemParameters)
{
    ptxStatus_t status = ptx30wNsc_WriteOemParameters(oemParameters);

    if(0 == oemParameters->DC_CHARGING)
    {
        ptxDeviceInformation_t device_information;
        memset(&device_information, 0, sizeof(ptxDeviceInformation_t));

        if(ptxStatus_Success == status)
        {
            status = ptx30w_GetDeviceInformation(&device_information);
        }

        if((ptxStatus_Success == status) && (5123 == device_information.FirmwareVersion))
        {
           uint16_t address = 0x0828;
           uint16_t data = 0xE912;
           status = ptx30wHip_WriteCodeMemory(address, &data, 1, true);
        }
    }

    return status;
}

ptxStatus_t ptx30w_TDC_Read(uint8_t *rxData, uint8_t *rxDataLen, uint32_t rxTimeoutMs)
{
    ptxStatus_t status = ptxStatus_Success;

    ptxStatus_t temp_status = ptxPlat_IRQ_WaitForIrq(rxTimeoutMs);

    if(ptxStatus_Success == temp_status)
    {
        (void) ptx30wNsc_Tdc_Handle();
    }

    status = ptx30wNsc_Tdc_RxMessage(rxData, rxDataLen);

    return status;
}

ptxStatus_t ptx30w_TDC_Write(uint8_t *txData, uint8_t txDataLen, uint32_t ackTimeoutMs)
{
    ptxStatus_t status = ptxStatus_Success;

    status = ptx30wNsc_Tdc_TxMessage(txData, txDataLen);

    if( (0 != ackTimeoutMs) && (ptxStatus_Success == status) )
    {
        uint8_t is_received = 0;

        status = ptxPlat_IRQ_WaitForIrq(ackTimeoutMs);

        if(ptxStatus_Success == status)
        {
            status = ptx30wNsc_Tdc_TxMessageReceived(&is_received);
        }

        if( (ptxStatus_Success == status) && (0 == is_received))
        {
            status = ptxStatus_TimeOut;
        }
    }

    return status;
}

ptxStatus_t ptx30w_TDC_IsReceived(uint8_t *received)
{
    return ptx30wNsc_Tdc_TxMessageReceived(received);
}

static uint16_t adcToMv(uint8_t adcVal)
{
    return (uint16_t) ( PTX30W_VMON_OFFSET_MV + ( (((uint16_t) adcVal) * PTX30W_VMON_UV_PER_LSB) / 10U) );
}
