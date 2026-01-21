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
    File        : ptx30w_Nvm_Int.h
*/
#ifndef PTX_PTX30W_NVM_INT_H_
#define PTX_PTX30W_NVM_INT_H_

#include <stdbool.h>
#include <stdint.h>

#include "ptx30w_ConfigHelper.h"
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
#define ERASE_MEM_EXTRA_TIME    (10U)   /** Extra time to wait until checking erase status. */
#define ERASE_MEM_TIMEOUT       (5U)    /** Add 5x 10 ms extra time to the PTX chip to erase. */
#define ERASE_MEM_TIME          (260U)  /** Time required to erase the chip memory. */

/*
 * ####################################################################################################################
 * TYPES
 * ####################################################################################################################
 */
typedef struct MemoryMapping
{
    uint16_t Address;
    uint16_t BitMask;
    uint8_t  Offset;
} MemoryMapping_t;

/*
 * ####################################################################################################################
 * API FUNCTIONS
 * ####################################################################################################################
 */
/**
 * \brief Writes the FW to the device, and allows the update of the OEM parameters.
 *
 * \param[in] oemParams Pointer to new OEM parameter configuration (set to NULL if not used).
 *
 * \return Status of the operation see \ref ptxStatus_t
 */
ptxStatus_t ptx30wNvm_UpdateMemory (ptxOemConfigParam_t *oemParams);

/**
 * \brief Retrieves the OEM parameters from the devive and maps them into the corresponding data structure.
 *
 * \param[in,out] config Pointer to the data structure to be filled with the read data.
 *
 * \return Status of the operation see \ref ptxStatus_t
 */
ptxStatus_t ptx30wNvm_ReadOemParameters(ptxOemConfigParam_t *config);

/**
 * \brief Writes the OEM parameters to the device.
 *
 * \param[in] config Pointer to the data structure to be written.
 *
 * \return Status of the operation see \ref ptxStatus_t
 */
ptxStatus_t ptx30wNvm_WriteOemParameters(ptxOemConfigParam_t *config);

/**
* \brief Checks if the OEM magic word is set.
*
* \param[in] valid Pointer to store the flag, indicating valid OEM paramters.
*
* \return Status of the operation see \ref ptxStatus_t
*/
ptxStatus_t ptx30wNvm_OemParametersValid(uint8_t *valid);

/**
 * \brief Erases the COMPLETE NVM of the 30W. Only use this function if you are
 *          absolutely sure what you are doing! You can loose all calibration data!
 *
 * \param[in] oscFreqSel
 * \param[in] nvmProgLen
 *
 * \return Status of the operation see \ref ptxStatus_t
 */
ptxStatus_t ptx30wNvm_EraseMemory(uint8_t oscFreqSel, uint8_t nvmProgLen);

#ifdef __cplusplus
}
#endif

#endif /* Guard */
