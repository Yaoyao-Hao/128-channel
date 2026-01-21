/** \file
    ---------------------------------------------------------------
    Copyright (C) 2023. Panthronics AG - All Rights Reserved.

    This material may not be reproduced, displayed, modified or
    distributed without the express prior written permission of the
    Panthronics AG.

    PLEASE CHECK FURTHER DISCLAIMER IN FILE "PTX_LICENSE.TXT"
    ---------------------------------------------------------------

    Project     : PTX30W
    Module      : ConfigurationHelper
    File        : ptx30w_ConfigHelper.c

    Description : Module implementing helper functions to do
                    an initial setup of the OEM parameters.
*/

/*
 * ####################################################################################################################
 * INCLUDES
 * ####################################################################################################################
 */
#include "ptx30w_ConfigHelper.h"
#include <string.h>

/*
 * ####################################################################################################################
 * API FUNCTIONS
 * ####################################################################################################################
 */

ptxStatus_t ptx30wOemConfig_Init(ptxOemConfigParam_t *config)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
        memset(config, 0x00, sizeof(ptxOemConfigParam_t));
        config->OSC_EN_NTC_MODE = MASK_OSC_MODE;
        config->DC_CHARGING = 0x01;
        config->RFU1 = 0xFF;
        config->RFU2 = 0xFF;
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetCapWtInt(ptxOemConfigParam_t *config, ptx30wWptDuration_t capWtInt)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
       config->CAP_WT_INT = (uint8_t) (MASK_CAP_WT_INT & (capWtInt << POS_CAP_WT_INT));
    }
    else
    {
       status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetVdBatOffsetHigh(ptxOemConfigParam_t *config, uint16_t mV)
{
    ptxStatus_t status = ptxStatus_Success;

    if ( NULL != config )
    {
        config->VDBAT_OFFSET_HIGH = (uint8_t) (MASK_VDBAT_OFFSET_HIGH & (((mV * 10U) / 125U) << POS_VDBAT_OFFSET_HIGH));
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetVdBatOffsetLow(ptxOemConfigParam_t *config, uint16_t mV)
{
    ptxStatus_t status = ptxStatus_Success;

    if ( NULL != config )
    {
        config->VDBAT_OFFSET_LOW = (uint8_t) (MASK_VDBAT_OFFSET_LOW & (((mV * 10U) / 125U) << POS_VDBAT_OFFSET_LOW));
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetISensorThresh(ptxOemConfigParam_t *config, ptx30wIThreshSel_t sel)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
        config->CURSENS_TH_SEL = (uint8_t) (MASK_CURSENS_TH_SEL & (sel << POS_CURSENS_TH_SEL));
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetBcUvlo(ptxOemConfigParam_t *config, ptx30wBcUvlo_t uvlo)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
        switch(uvlo)
        {
            case ptx30wBcUvlo_Disabled:
                config->BC_COMB1 = (uint8_t) (config->BC_COMB1 & ~MASK_BC_UVLO_EN);
                break;
            case ptx30wBcUvlo_3V0:
                config->BC_COMB1 = (uint8_t) (config->BC_COMB1 | MASK_BC_UVLO_EN);
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

ptxStatus_t ptx30wOemConfig_SetBcILimBatEnable(ptxOemConfigParam_t *config, uint8_t enable)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
        config->BC_COMB1 = (uint8_t) (config->BC_COMB1 & ~MASK_BC_ILIMBAT_EN);
        config->BC_COMB1 = (uint8_t) (config->BC_COMB1 | (0 == enable ? 0U : MASK_BC_ILIMBAT_EN));
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetBcEnable(ptxOemConfigParam_t *config, uint8_t enable)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
        config->BC_ENABLE = (uint8_t) (0 == enable ? 0U : MASK_BC_ENABLE);
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetBcVTermCold(ptxOemConfigParam_t *config, ptx30wVTermReduction_t reduction)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
        config->BC_VTERM_OFFSET_COLD = (uint8_t) (MASK_BC_VTERM_OFFSET_COLD & (reduction << POS_BC_VTERM_OFFSET_COLD));
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetBcVTermHot(ptxOemConfigParam_t *config, ptx30wVTermReduction_t reduction)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
        config->BC_VTERM_OFFSET_HOT = (uint8_t) (MASK_BC_VTERM_OFFSET_HOT & (reduction << POS_BC_VTERM_OFFSET_HOT));
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetBcIChargeCold(ptxOemConfigParam_t *config, ptx30wIChargePercent_t chargeCurrent)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
        config->BC_ICHG_PCT_COLD = (uint8_t) (MASK_BC_ICHG_PCT_COLD & (chargeCurrent << POS_BC_ICHG_PCT_COLD));
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetBcIChargeHot(ptxOemConfigParam_t *config, ptx30wIChargePercent_t chargeCurrent)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
        config->BC_ICHG_PCT_HOT = (uint8_t) (MASK_BC_ICHG_PCT_HOT & (chargeCurrent << POS_BC_ICHG_PCT_HOT));
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetBcITerm(ptxOemConfigParam_t *config, uint8_t mA)
{
    ptxStatus_t status = ptxStatus_Success;

    if ( (NULL != config) && (mA >= 2) && (mA <= 87) )
    {
        config->BC_ITERM_CTRL = (uint8_t) (MASK_BC_ITERM_CTRL & (((((mA * 100U) + 34U) / 139U) + 1U) << POS_BC_ITERM_CTRL));
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetBcVTrickle(ptxOemConfigParam_t *config, ptx30wVTrickle_t trickleVoltage)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
        config->BC_COMB0 = (uint8_t) (config->BC_COMB0 & ~MASK_BC_VTRK_CTRL);
        config->BC_COMB0 = (uint8_t) (config->BC_COMB0 | (MASK_BC_VTRK_CTRL & (trickleVoltage << POS_BC_VTRK_CTRL)));
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetBcVTerm(ptxOemConfigParam_t *config, ptx30wVTerm_t terminationVoltage)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
        config->BC_COMB0 = (uint8_t) (config->BC_COMB0 & ~MASK_BC_VTERM_CTRL);
        config->BC_COMB0 = (uint8_t) (config->BC_COMB0 | (MASK_BC_VTERM_CTRL & (terminationVoltage << POS_BC_VTERM_CTRL)));
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetBcVRecharge(ptxOemConfigParam_t *config, ptx30wVRecharge_t rechargeVoltage)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
        config->BC_VRCHG_CTRL = (uint8_t) (MASK_BC_VRCHG_CTRL & (rechargeVoltage << POS_BC_VRCHG_CTRL));
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetBcICharge(ptxOemConfigParam_t *config, uint8_t mAwpt, uint8_t mAnfc)
{
    ptxStatus_t status = ptxStatus_Success;

    if ( (NULL != config) && (mAwpt >= 5) && (mAnfc >= 5) && (mAnfc <= mAwpt))
    {
        config->BC_ICHG_CTRL = (uint8_t) (MASK_BC_ICHG_CTRL & (((mAwpt - 1U) >> 1U) << POS_BC_ICHG_CTRL));

        if(mAnfc < 2)
        {
            config->NFC_ICHG = 0;
        }
        else
        {
            config->NFC_ICHG = (uint8_t) (MASK_BC_ICHG_CTRL & ((((mAnfc > mAwpt ? mAwpt : mAnfc) - 1U) >> 1U) << POS_BC_ICHG_CTRL));
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetBcILimSel(ptxOemConfigParam_t *config, uint8_t reg)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
        config->BC_ILIM_SEL = (uint8_t) (MASK_BC_ILIM_SEL & reg);
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetBcLoBatOffEn(ptxOemConfigParam_t *config, uint8_t enable)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
        config->BC_COMB1 = (uint8_t) (config->BC_COMB1 & ~MASK_BC_LO_BATOFF_EN);
        config->BC_COMB1 = (uint8_t) (config->BC_COMB1 | (0 == enable ? 0U : MASK_BC_LO_BATOFF_EN));
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }
    return status;
}

ptxStatus_t ptx30wOemConfig_SetVdMcuMode(ptxOemConfigParam_t *config, ptx30wVdMcuMode_t mode)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
        config->OEM_VDMCU_MODE = (uint8_t) (MASK_VDMCU_MODE & (mode << POS_VDMCU_MODE));
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}


ptxStatus_t ptx30wOemConfig_SetI2cAddress(ptxOemConfigParam_t *config, uint8_t address)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
       config->I2C_SETTINGS = (uint8_t) (config->I2C_SETTINGS & ~MASK_I2C_ADDR);
       config->I2C_SETTINGS = (uint8_t) (config->I2C_SETTINGS | (address & MASK_I2C_ADDR));
    }
    else
    {
       status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetIrqPolarity(ptxOemConfigParam_t *config, ptx30wIrqPolarity_t polarity)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
        config->I2C_SETTINGS = (uint8_t) (config->I2C_SETTINGS & ~MASK_IRQ_POLARITY);
        config->I2C_SETTINGS = (uint8_t) (config->I2C_SETTINGS | (MASK_IRQ_POLARITY & (polarity << POS_IRQ_POLARITY)));
    }
    else
    {
       status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetGpio1Config(ptxOemConfigParam_t *config, ptx30wGpio1Config_t gpioConfig)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
       config->GPIO_1_CONFIG = (uint8_t) (MASK_GPIO_1_CONFIG & (gpioConfig << POS_GPIO_1_CONFIG));
    }
    else
    {
       status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetGpio0Config(ptxOemConfigParam_t *config, ptx30wGpio0Config_t gpioConfig)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
       config->GPIO_0_CONFIG = (uint8_t) (MASK_GPIO_0_CONFIG & (gpioConfig << POS_GPIO_0_CONFIG));
    }
    else
    {
       status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetVddCThLow(ptxOemConfigParam_t *config, uint16_t mV)
{
    ptxStatus_t status = ptxStatus_Success;

    if ( (NULL != config) && (mV >= VOLTAGE_MON_TH_LOW) && (mV <= VOLTAGE_MON_TH_HIGH))
    {
        config->VDDC_TH_LOW = (uint8_t) (MASK_VDDC_TH_LOW & ((((mV - VOLTAGE_MON_TH_LOW) * 10U) / 125U) << POS_VDDC_TH_LOW));
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetWptReqSel(ptxOemConfigParam_t *config, ptx30wWptReqSel_t sel)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
        config->WPT_REQ_SEL = (uint8_t) (MASK_WPT_REQ_SEL & (sel << POS_WPT_REQ_SEL));
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetAdjWptDurationInt(ptxOemConfigParam_t *config, ptx30wWptDuration_t adjWptDurationInt)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
       config->ADJ_WPT_DURATION_INT = (uint8_t) (MASK_ADJ_WPT_DURATION_INT & (adjWptDurationInt << POS_ADJ_WPT_DURATION_INT));
    }
    else
    {
       status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetTcmWptDurationInt(ptxOemConfigParam_t *config, ptx30wWptDuration_t tcmWptDurationInt)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
       config->TCM_WPT_DURATION_INT = (uint8_t) (MASK_TCM_WPT_DURATION_INT & (tcmWptDurationInt << POS_TCM_WPT_DURATION_INT));
    }
    else
    {
       status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetCcmWptDurationInt(ptxOemConfigParam_t *config, ptx30wWptDuration_t ccmWptDurationInt)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
        config->CCM_WPT_DURATION_INT = (uint8_t) (MASK_CCM_WPT_DURATION_INT & (ccmWptDurationInt << POS_CCM_WPT_DURATION_INT));
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetCvmWptDurationInt(ptxOemConfigParam_t *config, ptx30wWptDuration_t cvmWptDurationInt)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
        config->CVM_WPT_DURATION_INT = (uint8_t) (MASK_CVM_WPT_DURATION_INT & (cvmWptDurationInt << POS_CVM_WPT_DURATION_INT));
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetTcmTimeout(ptxOemConfigParam_t *config, uint8_t durationMultiplier)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
        config->TCM_TIMEOUT = (uint8_t) (MASK_TCM_TIMEOUT_INT & (durationMultiplier << POS_TCM_TIMEOUT_INT));
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetCcmTimeout(ptxOemConfigParam_t *config, uint8_t durationMultiplier)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
        config->CCM_TIMEOUT = (uint8_t) (MASK_CCM_TIMEOUT_INT & (durationMultiplier << POS_CCM_TIMEOUT_INT));
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetCvmTimeout(ptxOemConfigParam_t *config, uint8_t durationMultiplier)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
       config->CVM_TIMEOUT = (uint8_t) (MASK_CVM_TIMEOUT_INT & (durationMultiplier << POS_CVM_TIMEOUT_INT));
    }
    else
    {
       status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetNfcResistiveMod(ptxOemConfigParam_t *config, ptx30wResistorSetting_t resistor)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
       config->NFC_RESISTIVE_MODSET = (uint8_t) (config->NFC_RESISTIVE_MODSET & ~MASK_RESISTOR_MOD);
       config->NFC_RESISTIVE_MODSET = (uint8_t) (config->NFC_RESISTIVE_MODSET | (MASK_RESISTOR_MOD & (resistor << POS_RESISTOR_MOD)));
    }
    else
    {
       status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetNfcResistiveSet(ptxOemConfigParam_t *config, ptx30wResistorSetting_t resistor)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
       config->NFC_RESISTIVE_MODSET = (uint8_t) (config->NFC_RESISTIVE_MODSET & ~MASK_RESISTOR_IDLE);
       config->NFC_RESISTIVE_MODSET = (uint8_t) (config->NFC_RESISTIVE_MODSET | (MASK_RESISTOR_IDLE & (resistor << POS_RESISTOR_IDLE)));
    }
    else
    {
       status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetWptResistiveMod(ptxOemConfigParam_t *config, ptx30wResistorSetting_t resistor)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
       config->WPT_RESISTIVE_MODSET = (uint8_t) (config->WPT_RESISTIVE_MODSET & ~MASK_RESISTOR_MOD);
       config->WPT_RESISTIVE_MODSET = (uint8_t) (config->WPT_RESISTIVE_MODSET | (MASK_RESISTOR_MOD & (resistor << POS_RESISTOR_MOD)));
    }
    else
    {
       status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetWptResistiveSet(ptxOemConfigParam_t *config, ptx30wResistorSetting_t resistor)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
        config->WPT_RESISTIVE_MODSET = (uint8_t) (config->WPT_RESISTIVE_MODSET & ~MASK_RESISTOR_IDLE);
        config->WPT_RESISTIVE_MODSET = (uint8_t) (config->WPT_RESISTIVE_MODSET | (MASK_RESISTOR_IDLE & (resistor << POS_RESISTOR_IDLE)));
    }
    else
    {
       status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetNtcMode(ptxOemConfigParam_t *config, ptx30wNtcMode_t mode)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
        config->OSC_EN_NTC_MODE = (uint8_t) (config->OSC_EN_NTC_MODE & ~MASK_NTC_MODE);
        config->OSC_EN_NTC_MODE = (uint8_t) (config->OSC_EN_NTC_MODE | (MASK_NTC_MODE & (mode << POS_NTC_MODE)));
    }
    else
    {
       status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptx30wOemConfig_SetDcChargingEnable(ptxOemConfigParam_t *config, uint8_t enable)
{
    ptxStatus_t status = ptxStatus_Success;

    if (NULL != config)
    {
        config->DC_CHARGING = enable;
    }
    else
    {
       status = ptxStatus_InvalidParameter;
    }

    return status;
}
