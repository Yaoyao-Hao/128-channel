/** \file
    ---------------------------------------------------------------
    Copyright (C) 2023. Panthronics AG - All Rights Reserved.

    This material may not be reproduced, displayed, modified or
    distributed without the express prior written permission of the
    Panthronics AG.

    PLEASE CHECK FURTHER DISCLAIMER IN FILE "PTX_LICENSE.TXT"
    ---------------------------------------------------------------

    Project     : PTX30W
    Module      : NVM
    File        : ptx30w_Nvm_Int.c

    Description : Module for updating the uCode.
*/

/*
 * ####################################################################################################################
 * INCLUDES
 * ####################################################################################################################
 */
#include "../plat/ptxPlat.h"
#include "ptx30w_Hip.h"
#include "ptx30w_Hip_Int.h"
#include "ptx30w_Nvm_Int.h"
#include "ptx30w_Registers_Int.h"
#include "ptx30w_uCode_Int.h"

#define OSC_FREQ_SEL_OFFSET     (3U)
#define OSC_FREQ_SEL_SHIFT      (8U)
#define NVM_PROG_LEN_OFFSET     (4U)
#define NVM_PROG_LEN_SHIFT      (8U)
#define NVM_FW_VERSION_OFFSET   (15U)

const MemoryMapping_t OemMemMap[] =
{
    /** CAP_WT_INT */               {.Address = 0xFCA, .BitMask = 0xFF, .Offset = 8},
    /** NFC_ICHG */                 {.Address = 0xFCA, .BitMask = 0x7F, .Offset = 0},
    /** VDBAT_OFFSET_HIGH */        {.Address = 0xFCB, .BitMask = 0xFF, .Offset = 8},
    /** VDBAT_OFFSET_LOW */         {.Address = 0xFCB, .BitMask = 0xFF, .Offset = 0},
    /** RFU */                      {.Address = 0xFCC, .BitMask = 0xFF, .Offset = 8},
    /** CURSENS_TH_SEL */           {.Address = 0xFCC, .BitMask = 0x0C, .Offset = 0},
    /** NFC_RESISTIVE_(MOD/SET) */  {.Address = 0xFCD, .BitMask = 0xFF, .Offset = 8},
    /** BC_UVLO_CTRL */             {.Address = 0xFCD, .BitMask = 0x01, .Offset = 0},
    /** BC_ILIMBAT|UVLO|BATOFF*/    {.Address = 0xFCE, .BitMask = 0x86, .Offset = 8},
    /** BC_ENABLE */                {.Address = 0xFCE, .BitMask = 0x01, .Offset = 0},
    /** BC_VTERM_OFFSET_COLD */     {.Address = 0xFCF, .BitMask = 0x07, .Offset = 8},
    /** BC_VTERM_OFFSET_HOT */      {.Address = 0xFCF, .BitMask = 0x07, .Offset = 0},
    /** BC_ICHG_PCT_COLD */         {.Address = 0xFD0, .BitMask = 0x07, .Offset = 8},
    /** BC_ICHG_PCT_HOT */          {.Address = 0xFD0, .BitMask = 0x07, .Offset = 0},
    /** BC_ITERM_CTRL */            {.Address = 0xFD1, .BitMask = 0x3F, .Offset = 8},
    /** BC_(VTRK/VTERM)_CTRL */     {.Address = 0xFD1, .BitMask = 0xFF, .Offset = 0},
    /** BC_VRCHG_CTRL */            {.Address = 0xFD2, .BitMask = 0x0F, .Offset = 8},
    /** BC_ICHG_CTRL */             {.Address = 0xFD2, .BitMask = 0x7F, .Offset = 0},
    /** BC_ILIM_SEL */              {.Address = 0xFD3, .BitMask = 0x07, .Offset = 8},
    /** WPT_RESISTIVE_(MOD/SET) */  {.Address = 0xFD3, .BitMask = 0xFF, .Offset = 0},
    /** OEM_VDMCU_MODE */           {.Address = 0xFD4, .BitMask = 0x03, .Offset = 8},
    /** I2C_ADDR + IRQ_POL */       {.Address = 0xFD4, .BitMask = 0xFF, .Offset = 0},
    /** GPIO_1_CONFIG */            {.Address = 0xFD5, .BitMask = 0x0F, .Offset = 8},
    /** GPIO_0_CONFIG */            {.Address = 0xFD5, .BitMask = 0x0F, .Offset = 0},
    /** VDDC_TH_LOW */              {.Address = 0xFD6, .BitMask = 0xFF, .Offset = 8},
    /** WPT_REQ_SEL */              {.Address = 0xFD6, .BitMask = 0x03, .Offset = 0},
    /** WPT_OSC_MODE_EN*/           {.Address = 0xFD7, .BitMask = 0x02, .Offset = 8},
    /** ADJ_WPT_DURATION_INT */     {.Address = 0xFD7, .BitMask = 0x1F, .Offset = 0},
    /** TCM_WPT_DURATION_INT */     {.Address = 0xFD8, .BitMask = 0x1F, .Offset = 8},
    /** CCM_WPT_DURATION_INT */     {.Address = 0xFD8, .BitMask = 0x1F, .Offset = 0},
    /** CVM_WPT_DURATION_INT */     {.Address = 0xFD9, .BitMask = 0x1F, .Offset = 8},
    /** TCM_TIMEOUT */              {.Address = 0xFD9, .BitMask = 0xFF, .Offset = 0},
    /** CCM_TIMEOUT */              {.Address = 0xFDA, .BitMask = 0xFF, .Offset = 8},
    /** CVM_TIMEOUT */              {.Address = 0xFDA, .BitMask = 0xFF, .Offset = 0}
};

/*
 * ####################################################################################################################
 * API FUNCTIONS
 * ####################################################################################################################
 */

ptxStatus_t ptx30wNvm_UpdateMemory (ptxOemConfigParam_t *oemParams)
{
    ptxStatus_t status = ptxStatus_Success;

    uint16_t ptx_params[NVM_PTX_PARAMS_LENGTH];
    memset(&ptx_params, 0x00, sizeof(ptx_params));

    uint8_t hw_version = 0x00;
    status = ptx30wHip_ReadDataMemory(HW_VERSION_REG, &hw_version, 1);

    if(ptxStatus_Success == status)
    {
        /** Check if the hardware version is correct. */
        if(HW_VERSION_REG_RST != hw_version)
        {
            status = ptxStatus_NotPermitted;
        }
    }

    if(ptxStatus_Success == status)
    {
        /** Read content of ANA_LDO_REG */
        uint8_t ana_ldo_reg = 0x00;
        status = ptx30wHip_ReadDataMemory(ANA_LDO_REG, &ana_ldo_reg, 1);

        /** Make sure to disable the watchdog! */
        ana_ldo_reg |= ANA_LDO_REG_WATCHDOG_EN_N_MASK;

        /** Reapply content of ANA_LDO_REG */
        status |= ptx30wHip_WriteDataMemory(ANA_LDO_REG, &ana_ldo_reg, 1);
    }

    if (ptxStatus_Success == status)
    {
        /** Stop DFY */
        status = ptx30wHip_SystemReset(DFYS_NoSysResetDfyOff);
    }

    if (ptxStatus_Success == status)
    {
        /** Read PTX params */
        status = ptx30wHip_ReadCodeMemory(NVM_PTX_PARAMS_START, ptx_params, NVM_PTX_PARAMS_LENGTH);
        ptx_params[NVM_FW_VERSION_OFFSET] = NVM_DEFAULT_STATE; /**< 'Clear' previous FW version. */
    }

    if (ptxStatus_Success == status)
    {
        /** Erase the whole memory */
        status = ptx30wNvm_EraseMemory((uint8_t) (ptx_params[OSC_FREQ_SEL_OFFSET] >> OSC_FREQ_SEL_SHIFT),
                                       (uint8_t) (ptx_params[NVM_PROG_LEN_OFFSET] >> NVM_PROG_LEN_SHIFT));
    }

    /** We write PTX params in ANY(!) case, even if previous steps may have failed.
     *  We must not lose those parameters.
     */
    status = ptx30wHip_WriteCodeMemory(NVM_PTX_PARAMS_START, ptx_params, NVM_PTX_PARAMS_LENGTH, true);

    if (ptxStatus_Success == status)
    {
        status = ptx30wHip_WritePage(PTX_VALID_FLAG_ADDR, VALID_FLAG_VALUE, true);
    }

    if (ptxStatus_Success == status)
    {
        status = ptx30wHip_WriteCodeMemory(PTX_UCODE_START_ADDR, (uint16_t*) ptx30w_uCode, SIZE_OF_UCODE_SECTION, true);
    }

    if (ptxStatus_Success == status)
    {
        status = ptx30wHip_WritePage(FW_VERSION_ADDR, ptx30w_uCode_SRC_REV, true);
    }

    if (ptxStatus_Success == status && NULL != oemParams)
    {
        status = ptx30wNvm_WriteOemParameters(oemParams);

        if (ptxStatus_Success == status)
        {
            status = ptx30wHip_WritePage(OEM_VALID_FLAG_ADDR, VALID_FLAG_VALUE, true);
        }
    }

    if (ptxStatus_Success == status)
    {
        status = ptx30wHip_SystemReset(DFYS_SysResetDfyOn);
    }

    return status;
}

ptxStatus_t ptx30wNvm_ReadOemParameters(ptxOemConfigParam_t *config)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
        uint16_t startAddress = NVM_OEM_PARAMS_START;

        uint16_t memData[NVM_OEM_PARAMS_LENGTH];
        memset(memData, 0x00, sizeof(memData));

        uint8_t entries = sizeof(OemMemMap) / sizeof(OemMemMap[0]);

        status = ptx30wHip_ReadCodeMemory(startAddress, memData, NVM_OEM_PARAMS_LENGTH);

        if (ptxStatus_Success == status)
        {
            uint8_t dstPos = 0;
            for(uint8_t i = 0; i < entries; ++i)
            {
                uint16_t idx = OemMemMap[i].Address - startAddress;

                uint8_t parameter = (uint8_t) ((memData[idx] >> OemMemMap[i].Offset) & OemMemMap[i].BitMask);
                config->Bytes[dstPos] = parameter;
                dstPos++;
            }
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wNvm_WriteOemParameters(ptxOemConfigParam_t *config)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
        uint16_t memData[NVM_OEM_PARAMS_LENGTH];
        memset(memData, 0x00, sizeof(memData));

        uint16_t entries = sizeof(OemMemMap) / sizeof(OemMemMap[0]);

        for(uint8_t i = 0; i < entries; ++i)
        {
            uint16_t idx = OemMemMap[i].Address - NVM_OEM_PARAMS_START;

            memData[idx] = (uint16_t) (memData[idx] | ((config->Bytes[i] & OemMemMap[i].BitMask) << OemMemMap[i].Offset));
        }

        status = ptx30wHip_WriteCodeMemory(NVM_OEM_PARAMS_START, memData, NVM_OEM_PARAMS_LENGTH, true);
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wNvm_OemParametersValid(uint8_t *valid)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != valid)
    {
        *valid = 0;

        uint16_t data = 0x00;
        status = ptx30wHip_ReadCodeMemory(OEM_VALID_FLAG_ADDR, &data, 1);

        if ( (ptxStatus_Success == status) && (VALID_FLAG_VALUE == data) )
        {
            *valid = 1;
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wNvm_EraseMemory(uint8_t oscFreqSel, uint8_t nvmProgLen)
{
    ptxStatus_t status = ptxStatus_Success;
    uint8_t response;
    uint8_t command;
    uint8_t timeout = ERASE_MEM_TIMEOUT;

    status = ptx30wHip_SystemReset(DFYS_NoSysResetDfyOff);

    uint8_t register_setting;
    if (ptxStatus_Success == status)
    {
        status = ptx30wHip_ReadDataMemory(ANA_PLL_REG, &register_setting, 1U);
    }

    if (ptxStatus_Success == status)
    {
        register_setting = (uint8_t) (register_setting & ~OSC_FREQ_SEL_MASK);
        register_setting = (uint8_t) (register_setting & ~ANA_PLL_REG_PLL_MODE_MASK);
        register_setting = (uint8_t) (register_setting | oscFreqSel);
        status = ptx30wHip_WriteDataMemory(ANA_PLL_REG, &register_setting, 1U);
    }

    if (ptxStatus_Success == status)
    {
        status = ptx30wHip_ReadDataMemory(SYS_TEST_CONTROL4_REG, &register_setting, 1U);
    }

    if (ptxStatus_Success == status)
    {
        register_setting = (uint8_t) (register_setting & ~NVM_PROG_LEN_MASK);
        register_setting = (uint8_t) (register_setting | nvmProgLen);
        status = ptx30wHip_WriteDataMemory(SYS_TEST_CONTROL4_REG, &register_setting, 1U);
    }

    if (ptxStatus_Success == status)
    {
        /** Enter in NVM mode. */
        command = DFT_CMD_REG_CMD_ENTER_NVM_MODE;
        status = ptx30wHip_WriteDftInterface(DFT_CMD_REG, &command, 1U);
    }

    if (ptxStatus_Success == status)
    {
        /** Start erase procedure. */
        command = NVM_CONFIG_REG_CMD_ENABLE_AUTO_VPP_SWITCHING;
        status = ptx30wHip_WriteDftInterface(NVM_CMD_REG, &command, 1U);
    }

    if (ptxStatus_Success == status)
    {
        /** We need to wait at least 250 ms for erase procedure to be completed. */
        ptxPlat_Timer_Delay(ERASE_MEM_TIME);
        status = ptx30wHip_ReadDFTInterface(DFT_STATUS_REG, &response, 1U);

        /** Read the status. */
        while ((response == NVM_STATUS_ACTIVE_BUSY) && (ptxStatus_Success == status) && (timeout))
        {
            status = ptx30wHip_ReadDFTInterface(DFT_STATUS_REG, &response, 1U);
            ptxPlat_Timer_Delay(ERASE_MEM_EXTRA_TIME);
            timeout--;
        }

        if (NVM_STATUS_IDLE != response)
        {
            status = ptxStatus_InternalError;
        }
    }

    /** Exit NVM mode. */
    if (ptxStatus_Success == status)
    {
        command = DFT_CMD_REG_CMD_EXIT_MODE;
        status = ptx30wHip_WriteDftInterface(DFT_CMD_REG, &command, 1U);
    }

    if (ptxStatus_Success == status)
    {
        /** Check if NVM is in idle state. */
        status = ptx30wHip_ReadDFTInterface(DFT_STATUS_REG, &response, 1U);

        if (0U != response)
        {
            status = ptxStatus_InternalError;
        }
    }

    return status;
}

