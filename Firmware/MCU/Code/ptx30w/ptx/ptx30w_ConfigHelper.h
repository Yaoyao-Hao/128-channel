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
    File        : ptx30w_ConfigHelper.h
*/
#ifndef PTX_PTX30W_CONFIG_H_
#define PTX_PTX30W_CONFIG_H_

#include <stdint.h>
#include <stddef.h>
#include "ptxStatus.h"
#include "ptx30w_Nsc.h"

#ifdef __cplusplus
extern "C"
{
#endif
/*
 * ####################################################################################################################
 * DEFINES
 * ####################################################################################################################
 */
#define VOLTAGE_MON_TH_LOW          (2400u)
#define VOLTAGE_MON_TH_HIGH         (5600)

#define MASK_BC_ICHG_CTRL           (0x7F)
#define POS_BC_ICHG_CTRL            (0U)

#define MASK_BC_ICHG_PCT_COLD       (0x07)
#define POS_BC_ICHG_PCT_COLD        (0U)

#define MASK_BC_ICHG_PCT_HOT        (0x07)
#define POS_BC_ICHG_PCT_HOT         (0U)

#define MASK_BC_VTERM_CTRL          (0x1F)
#define POS_BC_VTERM_CTRL           (0U)

#define MASK_BC_VTERM_OFFSET_COLD   (0x07)
#define POS_BC_VTERM_OFFSET_COLD    (0U)

#define MASK_BC_VTERM_OFFSET_HOT    (0x07)
#define POS_BC_VTERM_OFFSET_HOT     (0U)

#define MASK_BC_VTRK_CTRL           (0xE0)
#define POS_BC_VTRK_CTRL            (5U)

#define MASK_BC_VRCHG_CTRL          (0x0F)
#define POS_BC_VRCHG_CTRL           (0U)

#define MASK_BC_ITERM_CTRL          (0x3F)
#define POS_BC_ITERM_CTRL           (0U)

#define MASK_BC_ILIM_SEL            (0x07)
#define POS_BC_ILIM_SEL             (0U)

#define MASK_BC_ILIMBAT_EN          (0x80)
#define POS_BC_ILIMBAT_EN           (7U)

#define MASK_BC_LO_BATOFF_EN        (0x2)
#define POS_BC_LO_BATOFF_EN         (1U)

#define MASK_BC_ENABLE              (0x01)
#define POS_BC_ENABLE               (0U)

#define MASK_VDMCU_MODE             (0x03)
#define POS_VDMCU_MODE              (0U)

#define MASK_CURSENS_TH_SEL         (0x0C)
#define POS_CURSENS_TH_SEL          (2U)

#define MASK_VDDC_TH_LOW            (0xFF)
#define POS_VDDC_TH_LOW             (0U)

#define MASK_VDBAT_OFFSET_LOW       (0xFF)
#define POS_VDBAT_OFFSET_LOW        (0U)

#define MASK_VDBAT_OFFSET_HIGH      (0xFF)
#define POS_VDBAT_OFFSET_HIGH       (0U)

#define MASK_BC_ICHG_OFFSET         (0x7F)
#define POS_BC_ICHG_OFFSET          (0U)

#define MASK_I2C_ADDR               (0x7F)
#define POS_I2C_ADDR                (0U)

#define MASK_ADJ_WPT_DURATION_INT   (0x1F)
#define POS_ADJ_WPT_DURATION_INT    (0U)

#define MASK_TCM_WPT_DURATION_INT   (0x1F)
#define POS_TCM_WPT_DURATION_INT    (0U)

#define MASK_CVM_WPT_DURATION_INT   (0x1F)
#define POS_CVM_WPT_DURATION_INT    (0U)

#define MASK_CCM_WPT_DURATION_INT   (0x1F)
#define POS_CCM_WPT_DURATION_INT    (0U)

#define MASK_TCM_TIMEOUT_INT        (0xFF)
#define POS_TCM_TIMEOUT_INT         (0U)

#define MASK_CCM_TIMEOUT_INT        (0xFF)
#define POS_CCM_TIMEOUT_INT         (0U)

#define MASK_CVM_TIMEOUT_INT        (0xFF)
#define POS_CVM_TIMEOUT_INT         (0U)

#define MASK_CAP_WT_INT             (0x0F)
#define POS_CAP_WT_INT              (0U)

#define MASK_GPIO_0_CONFIG          (0x0F)
#define POS_GPIO_0_CONFIG           (0U)

#define MASK_GPIO_1_CONFIG          (0x0F)
#define POS_GPIO_1_CONFIG           (0U)

#define MASK_BC_UVLO_EN             (0x04)
#define POS_BC_UVLO_EN              (2U)

#define MASK_WPT_REQ_SEL            (0x03)
#define POS_WPT_REQ_SEL             (0U)

#define MASK_OSC_MODE               (0x02)
#define POS_OSC_MODE                (1U)

#define MASK_CUSTOM_NDEF_MSG_LEN    (0xFF)
#define POS_CUSTOM_NDEF_MSG_LEN     (0U)
#define CUSTOM_NDEF_MSG_MAX_LEN     (144U)

#define MASK_IRQ_POLARITY           (0x80)
#define POS_IRQ_POLARITY            (7U)

#define MASK_RESISTOR_MOD           (0xF0)
#define POS_RESISTOR_MOD            (4u)

#define MASK_RESISTOR_IDLE          (0x0F)
#define POS_RESISTOR_IDLE           (0u)

#define MASK_NTC_MODE               (0x01)
#define POS_NTC_MODE                (0u)

/*
 * ####################################################################################################################
 * TYPES
 * ####################################################################################################################
 */
typedef enum ptx30wIChargePercent
{
    ptx30wIChargePercent_100 = 0x00, /** 100% of the charging current */
    ptx30wIChargePercent_75  = 0x01, /**  75% of the charging current */
    ptx30wIChargePercent_50  = 0x02, /**  50% of the charging current */
    ptx30wIChargePercent_25  = 0x03, /**  25% of the charging current */
    ptx30wIChargePercent_0   = 0x04  /**   0% of the charging current */
} ptx30wIChargePercent_t;

typedef enum ptx30wVTerm
{
    ptx30wVTerm_3V59 = 0x00, /** Termination voltage threshold @ 3.59V */
    ptx30wVTerm_3V62 = 0x01, /** Termination voltage threshold @ 3.62V */
    ptx30wVTerm_3V65 = 0x02, /** Termination voltage threshold @ 3.65V */
    ptx30wVTerm_3V67 = 0x03, /** Termination voltage threshold @ 3.67V */
    ptx30wVTerm_3V70 = 0x04, /** Termination voltage threshold @ 3.70V */
    ptx30wVTerm_3V73 = 0x05, /** Termination voltage threshold @ 3.73V */
    ptx30wVTerm_3V75 = 0x06, /** Termination voltage threshold @ 3.75V */
    ptx30wVTerm_3V81 = 0x07, /** Termination voltage threshold @ 3.81V */
    ptx30wVTerm_3V83 = 0x08, /** Termination voltage threshold @ 3.83V */
    ptx30wVTerm_3V86 = 0x09, /** Termination voltage threshold @ 3.86V */
    ptx30wVTerm_3V91 = 0x0A, /** Termination voltage threshold @ 3.91V */
    ptx30wVTerm_3V94 = 0x0B, /** Termination voltage threshold @ 3.94V */
    ptx30wVTerm_3V97 = 0x0C, /** Termination voltage threshold @ 3.97V */
    ptx30wVTerm_4V02 = 0x0D, /** Termination voltage threshold @ 4.02V */
    ptx30wVTerm_4V08 = 0x0E, /** Termination voltage threshold @ 4.08V */
    ptx30wVTerm_4V13 = 0x0F, /** Termination voltage threshold @ 4.13V */
    ptx30wVTerm_4V16 = 0x10, /** Termination voltage threshold @ 4.16V */
    ptx30wVTerm_4V18 = 0x11, /** Termination voltage threshold @ 4.18V */
    ptx30wVTerm_4V24 = 0x12, /** Termination voltage threshold @ 4.24V */
    ptx30wVTerm_4V26 = 0x13, /** Termination voltage threshold @ 4.26V */
    ptx30wVTerm_4V29 = 0x14, /** Termination voltage threshold @ 4.29V */
    ptx30wVTerm_4V32 = 0x15, /** Termination voltage threshold @ 4.32V */
    ptx30wVTerm_4V34 = 0x16, /** Termination voltage threshold @ 4.34V */
    ptx30wVTerm_4V40 = 0x17, /** Termination voltage threshold @ 4.40V */
    ptx30wVTerm_4V42 = 0x18, /** Termination voltage threshold @ 4.42V */
    ptx30wVTerm_4V45 = 0x19, /** Termination voltage threshold @ 4.45V */
    ptx30wVTerm_4V51 = 0x1A, /** Termination voltage threshold @ 4.51V */
    ptx30wVTerm_4V53 = 0x1B, /** Termination voltage threshold @ 4.53V */
    ptx30wVTerm_4V56 = 0x1C, /** Termination voltage threshold @ 4.56V */
    ptx30wVTerm_4V59 = 0x1D, /** Termination voltage threshold @ 4.59V */
    ptx30wVTerm_4V61 = 0x1E, /** Termination voltage threshold @ 4.61V */
    ptx30wVTerm_4V65 = 0x1F  /** Termination voltage threshold @ 4.65V */
} ptx30wVTerm_t;

typedef enum ptx30wVRecharge
{
   ptx30wVRecharge_2V91 = 0x00, /** Recharge voltage threshold @ 2.91V */
   ptx30wVRecharge_3V02 = 0x01, /** Recharge voltage threshold @ 3.02V */
   ptx30wVRecharge_3V13 = 0x02, /** Recharge voltage threshold @ 3.13V */
   ptx30wVRecharge_3V23 = 0x03, /** Recharge voltage threshold @ 3.23V */
   ptx30wVRecharge_3V34 = 0x04, /** Recharge voltage threshold @ 3.34V */
   ptx30wVRecharge_3V44 = 0x05, /** Recharge voltage threshold @ 3.44V */
   ptx30wVRecharge_3V55 = 0x06, /** Recharge voltage threshold @ 3.55V */
   ptx30wVRecharge_3V66 = 0x07, /** Recharge voltage threshold @ 3.66V */
   ptx30wVRecharge_3V73 = 0x08, /** Recharge voltage threshold @ 3.73V */
   ptx30wVRecharge_3V77 = 0x09, /** Recharge voltage threshold @ 3.77V */
   ptx30wVRecharge_3V82 = 0x0A, /** Recharge voltage threshold @ 3.82V */
   ptx30wVRecharge_3V87 = 0x0B, /** Recharge voltage threshold @ 3.87V */
   ptx30wVRecharge_4V04 = 0x0C, /** Recharge voltage threshold @ 4.04V */
   ptx30wVRecharge_4V20 = 0x0D, /** Recharge voltage threshold @ 4.20V */
   ptx30wVRecharge_4V30 = 0x0E, /** Recharge voltage threshold @ 4.30V */
   ptx30wVRecharge_4V42 = 0x0F  /** Recharge voltage threshold @ 4.42V */
} ptx30wVRecharge_t;

typedef enum ptx30wVTermReduction
{
    ptx30wVTermReduction_None  = 0x00,  /** No reduction **/
    ptx30wVTermReduction_1Step = 0x01, /** Reduction of BC_VTERM_CTRL by 1 step (see \ref ptx30wVTerm_t)  **/
    ptx30wVTermReduction_2Step = 0x02, /** Reduction of BC_VTERM_CTRL by 2 steps (see \ref ptx30wVTerm_t) **/
    ptx30wVTermReduction_3Step = 0x03, /** Reduction of BC_VTERM_CTRL by 3 steps (see \ref ptx30wVTerm_t) **/
    ptx30wVTermReduction_4Step = 0x04, /** Reduction of BC_VTERM_CTRL by 4 steps (see \ref ptx30wVTerm_t) **/
    ptx30wVTermReduction_5Step = 0x05, /** Reduction of BC_VTERM_CTRL by 5 steps (see \ref ptx30wVTerm_t) **/
    ptx30wVTermReduction_6Step = 0x06, /** Reduction of BC_VTERM_CTRL by 6 steps (see \ref ptx30wVTerm_t) **/
    ptx30wVTermReduction_7Step = 0x07  /** Reduction of BC_VTERM_CTRL by 7 steps (see \ref ptx30wVTerm_t) **/
} ptx30wVTermReduction_t;

typedef enum ptx30wVTrickle
{
    ptx30wVTrickle_3V0 = 0x00, /** Trickle charge voltage threshold @ 3.0V */
    ptx30wVTrickle_2V5 = 0x01, /** Trickle charge voltage threshold @ 2.5V */
    ptx30wVTrickle_2V6 = 0x02, /** Trickle charge voltage threshold @ 2.6V */
    ptx30wVTrickle_2V7 = 0x03, /** Trickle charge voltage threshold @ 2.7V */
    ptx30wVTrickle_2V8 = 0x04, /** Trickle charge voltage threshold @ 2.8V */
    ptx30wVTrickle_2V9 = 0x05, /** Trickle charge voltage threshold @ 2.9V */
    ptx30wVTrickle_3V1 = 0x06, /** Trickle charge voltage threshold @ 3.1V */
    ptx30wVTrickle_3V2 = 0x07  /** Trickle charge voltage threshold @ 3.2V */
} ptx30wVTrickle_t;

typedef enum ptx30wVdMcuMode
{
    ptx30wVdMcuMode_Output_1V8 = 0x01,  /** VddMcu is an output @ 1.8V */
    ptx30wVdMcuMode_Output_3V3 = 0x02,  /** VddMcu is an output @ 3.3V */
    ptx30wVdMcuMode_Input      = 0x03,  /** VddMcu is an input */
    ptx30wVdMcuMode_RFU                 /** RFU */
} ptx30wVdMcuMode_t;

typedef enum ptx30wIThreshSel
{
    ptx30wIThreshSel_2mA,
    ptx30wIThreshSel_5mA,
    ptx30wIThreshSel_10mA,
    ptx30wIThreshSel_20mA
} ptx30wIThreshSel_t;

typedef enum ptx30wGpio0Config
{
    ptx30wGpio0Config_Disabled          = 0x00, /** GPIO disabled               */
    ptx30wGpio0Config_ErrorStatus       = 0x01, /** Error status (out)          */
    ptx30wGpio0Config_ChgStatus         = 0x02, /** Charging status (out)       */
    ptx30wGpio0Config_NfcField          = 0x03, /** NFC field present (out)     */
    ptx30wGpio0Config_WlcpDetected      = 0x04, /** WLC-P device connected (out)*/
    ptx30wGpio0Config_WlcpCtrl          = 0x05, /** WLC-P controlled (out)      */
    ptx30wGpio0Config_StartUpCircuit    = 0x06  /** Startup circuit enable (out)*/
} ptx30wGpio0Config_t;

typedef enum ptx30wGpio1Config
{
    ptx30wGpio1Config_Disabled          = 0x00, /** GPIO disabled               */
    ptx30wGpio1Config_ErrorStatus       = 0x01, /** Error status (out)          */
    ptx30wGpio1Config_ChgStatus         = 0x02, /** Charging status (out)       */
    ptx30wGpio1Config_NfcField          = 0x03, /** NFC field present (out)     */
    ptx30wGpio1Config_WlcpDetected      = 0x04, /** WLC-P device connected (out)*/
    ptx30wGpio1Config_WlcpCtrl          = 0x05  /** WLC-P controlled (out)      */
} ptx30wGpio1Config_t;

typedef enum ptx30wBcUvlo
{
    ptx30wBcUvlo_Disabled = 0x00,   /**  Under-voltage lockout disabled. */
    ptx30wBcUvlo_3V0      = 0x03    /**  Under-voltage lockout threshold @ 3.0V. */
} ptx30wBcUvlo_t;

typedef enum ptx30wWptReqSel
{
    ptx30wWptReqSel_BcControlled = 0x00, /** WPT Request controlled by internal battery charger. */
    ptx30wWptReqSel_Disabled     = 0x01, /** WPT Request permanently disabled. */
    ptx30wWptReqSel_Enabled      = 0x02  /** WPT Request permanently enabled. */
} ptx30wWptReqSel_t;

typedef enum ptx30wNtcMode
{
    ptx30wNtcMode_Period1ms         = 0x00, /** PTX30W shall update the NTC_STATUS parameter with a period of 1ms. */
    ptx30wNtcMode_PeriodOncePerWpt  = 0x01  /** PTX30W shall update the NTC_STATUS parameter once before each WPT cycle. */
} ptx30wNtcMode_t;


typedef enum ptx30wWptDuration
{
    ptx30wWptDuration_8ms       = 0x00, /** WPT Duration 8ms.       */
    ptx30wWptDuration_16ms      = 0x01, /** WPT Duration 16ms.      */
    ptx30wWptDuration_32ms      = 0x02, /** WPT Duration 32ms.      */
    ptx30wWptDuration_64ms      = 0x03, /** WPT Duration 64ms.      */
    ptx30wWptDuration_128ms     = 0x04, /** WPT Duration 128ms.     */
    ptx30wWptDuration_256ms     = 0x05, /** WPT Duration 256ms.     */
    ptx30wWptDuration_512ms     = 0x06, /** WPT Duration 512ms.     */
    ptx30wWptDuration_1024ms    = 0x07, /** WPT Duration 1024ms.    */
    ptx30wWptDuration_2048ms    = 0x08, /** WPT Duration 2048ms.    */
    ptx30wWptDuration_4096ms    = 0x09, /** WPT Duration 4096ms.    */
    ptx30wWptDuration_8192ms    = 0x0A, /** WPT Duration 8192ms.    */
    ptx30wWptDuration_16384ms   = 0x0B, /** WPT Duration 16384ms.   */
    ptx30wWptDuration_32768ms   = 0x0C, /** WPT Duration 32768ms.   */
    ptx30wWptDuration_65536ms   = 0x0D, /** WPT Duration 65536ms (~1.1 min.).   */
    ptx30wWptDuration_131072ms  = 0x0E, /** WPT Duration 131072ms (~2.2 min.).  */
    ptx30wWptDuration_262144ms  = 0x0F, /** WPT Duration 262144ms (~4.4 min.).  */
    ptx30wWptDuration_524288ms  = 0x10, /** WPT Duration 524288ms (~8.7 min.).  */
    ptx30wWptDuration_1048576ms = 0x11, /** WPT Duration 1048576ms (~17.5 min.).*/
    ptx30wWptDuration_2097152ms = 0x12, /** WPT Duration 2097152ms (~35 min.).  */
    ptx30wWptDuration_4194304ms = 0x13, /** WPT Duration 4194304ms (~70 min.).  */
    ptx30wWptDuration_Reset     = 0x1F  /** Resets the WPT duration back to what's specified in the OEM parameters. */
} ptx30wWptDuration_t;

typedef enum ptx30wIrqPolarity
{
    ptx30wIrqPolarity_ActiveHigh    = 0x00, /** Active high. */
    ptx30wIrqPolarity_ActiveLow     = 0x01  /** Active low. */
} ptx30wIrqPolarity_t;

typedef enum ptx30wResistorSetting
{
    ptx30wResistorSetting_Disabled  = 0x00, /** Resistor value of modulator set to 'open'. */
    ptx30wResistorSetting_170Ohm    = 0x01, /** Resistor value of modulator set to 170 Ohm.*/
    ptx30wResistorSetting_85Ohm     = 0x02, /** Resistor value of modulator set to 85 Ohm. */
    ptx30wResistorSetting_57Ohm     = 0x03, /** Resistor value of modulator set to 57 Ohm. */
    ptx30wResistorSetting_43Ohm     = 0x04, /** Resistor value of modulator set to 43 Ohm. */
    ptx30wResistorSetting_34Ohm     = 0x05, /** Resistor value of modulator set to 34 Ohm. */
    ptx30wResistorSetting_27Ohm     = 0x06, /** Resistor value of modulator set to 27 Ohm. */
    ptx30wResistorSetting_24Ohm     = 0x07, /** Resistor value of modulator set to 24 Ohm. */
    ptx30wResistorSetting_21Ohm     = 0x08, /** Resistor value of modulator set to 21 Ohm. */
    ptx30wResistorSetting_19Ohm     = 0x09, /** Resistor value of modulator set to 19 Ohm. */
    ptx30wResistorSetting_17Ohm     = 0x0A, /** Resistor value of modulator set to 17 Ohm. */
    ptx30wResistorSetting_15Ohm     = 0x0B, /** Resistor value of modulator set to 15 Ohm. */
    ptx30wResistorSetting_14Ohm     = 0x0C, /** Resistor value of modulator set to 14 Ohm. */
    ptx30wResistorSetting_13Ohm     = 0x0D, /** Resistor value of modulator set to 13 Ohm. */
    ptx30wResistorSetting_12Ohm     = 0x0E, /** Resistor value of modulator set to 12 Ohm. */
    ptx30wResistorSetting_11Ohm     = 0x0F  /** Resistor value of modulator set to 11 Ohm. */
} ptx30wResistorSetting_t;

/*
 * ####################################################################################################################
 * API FUNCTIONS
 * ####################################################################################################################
 */
/**
 * \brief Initialize ptxOemConfigParam_t parameters to a defined state.
 *
 * \param[in] config    Pointer to the configuration parameters structure.
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_Init(ptxOemConfigParam_t *config);

/**
 * \brief Defines the time for which the WLCP has to wait before re-reading the WLC_CAP message.
 *
 * \param[in] config    Pointer to the configuration parameters structure.
 * \param[in] capWtInt  Waiting time between 8ms and ~70 min.
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetCapWtInt(ptxOemConfigParam_t *config, ptx30wWptDuration_t capWtInt);

/**
 * \brief Sets the VDBAT power regulation offset (high).
 *
 * \param[in] config    Pointer to the configuration parameters structure.
 * \param[in] mV        Offset. (Min = 0; Max = 3188)
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetVdBatOffsetHigh(ptxOemConfigParam_t *config, uint16_t mV);

/**
 * \brief Sets the VDBAT power regulation offset (low).
 *
 * \param[in] config    Pointer to the configuration parameters structure.
 * \param[in] mV        Offset. (Min = 0; Max = 3188)
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetVdBatOffsetLow(ptxOemConfigParam_t *config, uint16_t mV);

/**
 * \brief Sets the RF-current sensor threshold.
 *
 * \param[in] config    Pointer to the configuration parameters structure.
 * \param[in] sel       Threshold selection.
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetISensorThresh(ptxOemConfigParam_t *config, ptx30wIThreshSel_t sel);

/**
 * \brief Sets the battery charger under-voltage lockout voltage threshold.
 *
 * \param[in] config    Pointer to the configuration parameters structure.
 * \param[in] thres     UVLO threshold
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetBcUvlo(ptxOemConfigParam_t *config, ptx30wBcUvlo_t thres);

/**
 * \brief If enabled, Battery charger ILimit block is active.
 *
 * \param[in] config    Pointer to the configuration parameters structure.
 * \param[in] enable    Enable / Disable ILimit block.
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetBcILimBatEnable(ptxOemConfigParam_t *config, uint8_t enable);

/**
 * \brief If enabled, charging is enabled.
 *
 * \param[in] config    Pointer to the configuration parameters structure.
 * \param[in] enable    Enable / Disable battery charging.
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetBcEnable(ptxOemConfigParam_t *config, uint8_t enable);

/**
 * \brief Sets the termination voltage offset (BC_VTERM_CTRL) in steps for the temperature range
 *        0C < T < +10C.
 *
 * \param[in] config    Pointer to the configuration parameters structure.
 * \param[in] reduction Desired termination voltage reduction. (Min = 0 Steps; Max = 7 Steps)
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetBcVTermCold(ptxOemConfigParam_t *config, ptx30wVTermReduction_t reduction);

/**
 * \brief Sets the termination voltage offset (BC_VTERM_CTRL) in steps for the temperature range
 *        45C < T < +60C.
 *
 * \param[in] config    Pointer to the configuration parameters structure.
 * \param[in] reduction Desired termination voltage reduction.  (Min = 0 Steps; Max = 7 Steps)
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetBcVTermHot(ptxOemConfigParam_t *config, ptx30wVTermReduction_t reduction);

/**
 * \brief Percentage of the charging current (BC_ICHG_CTRL) for the temperature range
 *        0C < T < +10C.
 *
 * \param[in] config        Pointer to the configuration parameters structure.
 * \param[in] chargeCurrent Desired percentage of charge current for the temperature range.  (Min = 0%; Max = 100%)
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetBcIChargeCold(ptxOemConfigParam_t *config, ptx30wIChargePercent_t chargeCurrent);

/**
 * \brief Percentage of the charging current (BC_ICHG_CTRL) for the temperature range
 *        +45C < T < +60C.
 *
 * \param[in] config        Pointer to the configuration parameters structure.
 * \param[in] chargeCurrent Desired percentage of charge current for the temperature range. (Min = 0%; Max = 100%)
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetBcIChargeHot(ptxOemConfigParam_t *config, ptx30wIChargePercent_t chargeCurrent);

/**
 * \brief Sets the termination current threshold.
 *
 * \param[in] config    Pointer to the configuration parameters structure.
 * \param[in] mA        Desired termination current in milliamperes. (Min = 2mA; Max = 87mA)
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetBcITerm(ptxOemConfigParam_t *config, uint8_t mA);

/**
 * \brief Sets trickle voltage threshold.
 *
 * \param[in] config            Pointer to the configuration parameters structure.
 * \param[in] trickleVoltage    Desired trickle voltage threshold. (Min = 2.5V; Max = 3.2V)
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetBcVTrickle(ptxOemConfigParam_t *config, ptx30wVTrickle_t trickleVoltage);

/**
 * \brief Sets charging termination voltage.
 *
 * \param[in] config        Pointer to the configuration parameters structure.
 * \param[in] termVoltage   Desired termination voltage. (Min = 3.59V; Max = 4.65V)
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetBcVTerm(ptxOemConfigParam_t *config, ptx30wVTerm_t terminationVoltage);

/**
 * \brief Sets the recharge voltage threshold.
 *
 * \param[in] config            Pointer to the configuration parameters structure.
 * \param[in] rechargeVoltage   Desired recharge voltage threshold. (Min = 2.91V; Max = 4.42V)
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetBcVRecharge(ptxOemConfigParam_t *config, ptx30wVRecharge_t rechargeVoltage);

/**
 * \brief Calculates the register value for the desired fast charge current.
 *
 * \param[in] config    Pointer to the configuration parameters structure.
 * \param[in] mAwpt     Desired charge current in milliamperes for WPT phase. (Min = 5mA; Max = 250mA)
 * \param[in] mAnfc     Desired charge current in milliamperes for NFC phase. (Value 0: BC disabled during NFC phase; Value 1: Keep the WPT charging current; also any value between 5 and 250 mA possible).
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetBcICharge(ptxOemConfigParam_t *config, uint8_t mAwpt, uint8_t mAnfc);

/**
 * \brief Sets current limit drawn from the battery (VDBAT to VDDC).
 *
 * \param[in] config    Pointer to the configuration parameters structure.
 * \param[in] reg       0b000: 437mA (max); 0b100: 297mA; 0b111: 195mA (min)
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetBcILimSel(ptxOemConfigParam_t *config, uint8_t reg);

/**
 * \brief If set, Lock-out, Battery off Flag is enabled.
 *
 * \param[in] config    Pointer to the configuration parameters structure.
 * \param[in] enable    Enable/disable
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetBcLoBatOffEn(ptxOemConfigParam_t *config, uint8_t enable);

/**
 * \brief Sets the operation mode of VDD_MCU.
 *
 * \param[in] config    Pointer to the configuration parameters structure.
 * \param[in] mode      Operational mode.
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetVdMcuMode(ptxOemConfigParam_t *config, ptx30wVdMcuMode_t mode);

/**
 * \brief Sets the I2C address of the system.
 *
 * \param[in] config    Pointer to the configuration parameters structure.
 * \param[in] address   System I2C address. (Default value is 0x4B.)
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetI2cAddress(ptxOemConfigParam_t *config, uint8_t address);

/**
 * \brief Sets the polarity of the PTX30Ws IRQ line.
 *
 * \param[in] config    Pointer to the configuration parameters structure.
 * \param[in] polarity  Polarity of the IRQ line (active high or low)
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetIrqPolarity(ptxOemConfigParam_t *config, ptx30wIrqPolarity_t polarity);

/**
 * \brief Defines the configuration of GPIO1.
 *
 * \param[in] config        Pointer to the configuration parameters structure.
 * \param[in] gpioConfig    GPIO1 configuration.
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetGpio1Config(ptxOemConfigParam_t *config, ptx30wGpio1Config_t gpioConfig);

/**
 * \brief Defines the configuration of GPIO0.
 *
 * \param[in] config        Pointer to the configuration parameters structure.
 * \param[in] gpioConfig    GPIO0 configuration.
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetGpio0Config(ptxOemConfigParam_t *config, ptx30wGpio0Config_t gpioConfig);

/**
 * \brief Sets the VDDC power regulation threshold.
 *
 * \param[in] config    Pointer to the configuration parameters structure.
 * \param[in] mV        Offset. (Min = 2400; Max = 5588)
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetVddCThLow(ptxOemConfigParam_t *config, uint16_t mV);

/**
 * \brief Defines the WPT_REQ functionality.
 *
 * \param[in] config    Pointer to the configuration parameters structure.
 * \param[in] sel       WPT_REQ selection.
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetWptReqSel(ptxOemConfigParam_t *config, ptx30wWptReqSel_t sel);

/**
 * \brief Sets the adjustment charge cycle duration.
 *
 * \param[in] config    Pointer to the configuration parameters structure.
 * \param[in] duration  ADJ_WPT_DURATION
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetAdjWptDurationInt(ptxOemConfigParam_t *config, ptx30wWptDuration_t adjWptDurationInt);

/**
 * \brief Sets the trickle charge cycle duration.
 *
 * \param[in] config    Pointer to the configuration parameters structure.
 * \param[in] duration  TCM_WPT_DURATION
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetTcmWptDurationInt(ptxOemConfigParam_t *config, ptx30wWptDuration_t tcmWptDurationInt);

/**
 * \brief Sets the constant current charge cycle duration.
 *
 * \param[in] config    Pointer to the configuration parameters structure.
 * \param[in] duration  CCM_WPT_DURATION
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetCcmWptDurationInt(ptxOemConfigParam_t *config, ptx30wWptDuration_t ccmWptDurationInt);

/**
 * \brief Sets the constant voltage charge cycle duration.
 *
 * \param[in] config    Pointer to the configuration parameters structure.
 * \param[in] duration  CVM_WPT_DURATION
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetCvmWptDurationInt(ptxOemConfigParam_t *config, ptx30wWptDuration_t cvmWptDurationInt);

/**
 * \brief Defines the TCM_TIMEOUT value.
 *
 * \param[in] config                Pointer to the configuration parameters structure.
 * \param[in] timeout               Timeout value in units of 65535ms (~1.1min).
 *                                  (Timeout is disabled, if set to zero)
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetTcmTimeout(ptxOemConfigParam_t *config, uint8_t timeout);

/**
 * \brief Defines the CCM_TIMEOUT value.
 *
 * \param[in] config                Pointer to the configuration parameters structure.
 * \param[in] timeout               Timeout value in units of 65535ms (~1.1min).
 *                                  (Timeout is disabled, if set to zero)
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetCcmTimeout(ptxOemConfigParam_t *config, uint8_t timeout);

/**
 * \brief Defines the CVM_TIMEOUT value.
 *
 * \param[in] config                Pointer to the configuration parameters structure.
 * \param[in] timeout               Timeout value in units of 65535ms (~1.1min).
 *                                  (Timeout is disabled, if set to zero)
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetCvmTimeout(ptxOemConfigParam_t *config, uint8_t timeout);

/**
 * \brief Defines the used resistor value during NFC phase, when modulating. Note: RESISTIVE_MOD must be different from RESISTIVE_SET to see modulation!
 *
 * \param[in] config                Pointer to the configuration parameters structure.
 * \param[in] resistor              Used resistor values.
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetNfcResistiveMod(ptxOemConfigParam_t *config, ptx30wResistorSetting_t resistor);

/**
 * \brief Defines the used resistor value during NFC phase, when not modulating (idle). Note: RESISTIVE_SET must be different from RESISTIVE_MOD to see modulation!
 *
 * \param[in] config                Pointer to the configuration parameters structure.
 * \param[in] resistor              Used resistor values.
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetNfcResistiveSet(ptxOemConfigParam_t *config, ptx30wResistorSetting_t resistor);

/**
 * \brief Defines the used resistor value during WPT phase, when modulating. Note: RESISTIVE_MOD must be different from RESISTIVE_SET to see modulation!
 *
 * \param[in] config                Pointer to the configuration parameters structure.
 * \param[in] resistor              Used resistor values.
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetWptResistiveMod(ptxOemConfigParam_t *config, ptx30wResistorSetting_t resistor);

/**
 * \brief Defines the used resistor value during WPT phase, when not modulating (idle). Note: RESISTIVE_SET must be different from RESISTIVE_MOD to see modulation!
 *
 * \param[in] config                Pointer to the configuration parameters structure.
 * \param[in] resistor              Used resistor values.
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetWptResistiveSet(ptxOemConfigParam_t *config, ptx30wResistorSetting_t resistor);

/**
 * \brief Defines read out period of the NTC.
 *
 * \param[in] config                Pointer to the configuration parameters structure.
 * \param[in] mode                  Operation mode of the NTC.
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetNtcMode(ptxOemConfigParam_t *config, ptx30wNtcMode_t mode);

/**
 * \brief Enables/Disables DC-charging.
 *
 * \param[in] config                Pointer to the configuration parameters structure.
 * \param[in] enable                Enable/Disable DC-charging.
 *
 * \return Status of the operation, see \ref ptxStatus_t.
 */
ptxStatus_t ptx30wOemConfig_SetDcChargingEnable(ptxOemConfigParam_t *config, uint8_t enable);

#ifdef __cplusplus
}
#endif

#endif /*Guard */
