/** \file
    ---------------------------------------------------------------
    Copyright (C) 2023. Panthronics AG - All Rights Reserved.

    This material may not be reproduced, displayed, modified or
    distributed without the express prior written permission of the
    Panthronics AG.

    PLEASE CHECK FURTHER DISCLAIMER IN FILE "PTX_LICENSE.TXT"
    ---------------------------------------------------------------

    Project     : PTX30W
    Module      : Registers
    File        : ptx30w_Registers_Int.c

    Description : List of addresses.
*/
#ifndef PTX_PTX30W_REGISTERS_INT_H_
#define PTX_PTX30W_REGISTERS_INT_H_

#ifdef __cplusplus
extern "C"
{
#endif

/** OEM params start address within NVM. */
#define NVM_OEM_PARAMS_START                (0xFCA)
#define NVM_OEM_PARAMS_LENGTH               (17U)   // 17 Words (= 34 Bytes)

/** PTX params start address within NVM. */
#define NVM_PTX_PARAMS_START                (0xFDD)
#define NVM_PTX_PARAMS_LENGTH               (32U)   // 32 Words (= 64 Bytes)

/** Defines for HW_VERSION_REG */
#define HW_VERSION_REG                      (0x37)
#define HW_VERSION_REG_RST                  (0x21)
#define HW_VERSION_REG_HW_VERSION_MASK      (0xFF)

/** Defines for SYS_CONTROL_REG */
#define SYS_CONTROL_REG                     (0x0000)

/** Defines for ANA_PLL_REG */
#define ANA_PLL_REG                         (0x0042)
#define ANA_PLL_REG_PLL_MODE_MASK           (2U)
#define OSC_FREQ_SEL_MASK                   (0x70)

/** Defines for ANA_LDO_REG */
#define ANA_LDO_REG                         (0x0046)
#define ANA_LDO_REG_WATCHDOG_EN_N_MASK      (0x20)

/** DFT registers */
#define DFT_CMD_REG_CMD_ENTER_NVM_MODE      (0x10)
#define DFT_CMD_REG_CMD_EXIT_MODE           (0x80)
#define DFT_CMD_REG_CMD_ABORT               (0x81)

/** DFT command register address. */
#define DFT_CMD_REG                         (0x00)

/** DFT status register address. */
#define DFT_STATUS_REG                      (0x01)
#define NVM_STATUS_ACTIVE_BUSY              (0x21)
#define NVM_STATUS_IDLE                     (0x10)

/** NVM command register address. */
#define NVM_CMD_REG                         (0x11)

/** NVM configuration register address. */
#define NVM_CONFIG_REG                      (0x10)
#define NVM_CONFIG_REG_CMD_ENABLE_AUTO_VPP_SWITCHING    (0x41)

/** System test register 4 address . */
#define SYS_TEST_CONTROL4_REG   (0x35)
#define NVM_PROG_LEN_MASK       (0x0F)

/** Firmware start address. */
#define PTX_UCODE_START_ADDR    (0x800)

/** Address of the PTX valid flag within the NVM. */
#define PTX_VALID_FLAG_ADDR     (0xFFD)

/** Address of the OEM valid flag within the NVM. */
#define OEM_VALID_FLAG_ADDR     (0xFFE)

/** Address of the firmware version within the NVM. */
#define FW_VERSION_ADDR         (0xFEC)

/** Address of the CRC within the NVM. */
#define FW_CRC_ADDR             (0xFFF)

/** Flag used to mark that memory is valid. */
#define VALID_FLAG_VALUE        (0x5AC3)

#define NVM_DEFAULT_STATE       (0xFFFF)

#ifdef __cplusplus
}
#endif

#endif /* Guard */
