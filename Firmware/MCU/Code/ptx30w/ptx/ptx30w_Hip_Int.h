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
    File        : ptx30w_Hip_Int.h
*/
#ifndef PTX_PTX30W_HIP_INT_H_
#define PTX_PTX30W_HIP_INT_H_

#include "ptxStatus.h"
#include "ptx30w_Hip.h"

#ifdef __cplusplus
extern "C"
{
#endif
/*
 * ####################################################################################################################
 * DEFINES
 * ####################################################################################################################
 */
/** Defines for PTX30W FCB. */
#define FCB_OPCODE_WCM  (0x05)
#define FCB_OPCODE_WDM  (0x0A)
#define FCB_OPCODE_RDM  (0x0B)
#define FCB_OPCODE_WDBG (0x0C)
#define FCB_OPCODE_RDBG (0x0D)
#define FCB_OPCODE_WDFT (0x0E)
#define FCB_OPCODE_RDFT (0x0F)

#define MEM_WRITE_PAGE_LEN (2u)

/*
 * ####################################################################################################################
 * TYPES
 * ####################################################################################################################
 */

/*
 * ####################################################################################################################
 * API FUNCTIONS
 * ####################################################################################################################
 */
/**
 * \brief Command is used to read 16-bit data words from the code memory of PTX30W.
 * NVM is 2 bytes aligned MSB first, LSB second
 *
 * \param[in]  address    Address from the NVM where data should be written. Must be even
 * \param[out] data       Pointer to the read buffer
 * \param[in]  numWords   Number of bytes to be read. Must be an even number.
 *
 * \return  Status of the operation see \ref ptxStatus_t
 */
ptxStatus_t ptx30wHip_ReadCodeMemory(uint16_t address, uint16_t *data, uint16_t numWords);

/**
 * \brief Command used to write 16-bit a word in the code memory of the PTX device.
 * NVM is 2 bytes aligned MSB first, LSB second.
 * This operation is slow (3ms) as the PTX30W chip has a low writing time 800us/ 16 bits
 *
 * \param[in] address    Address from the NVM where data should be written. Must be even
 * \param[in] data       Pointer to data that should be written. 2 bytes aligned MSB first
 * \param[in] verify     Verify written content if set to true.
 *
 * \return Status of the operation see \ref ptxStatus_t
 */
ptxStatus_t ptx30wHip_WriteCodeMemory(uint16_t address, uint16_t *data, uint16_t numWords, bool verify);

/**
 * \brief Writes a page of the NVM (16 bit).
 *
 * \param[in] address   NVM address to write the data to.
 * \param[in] data      Data word to be written.
 * \param[in] verify    Verify written content if set to true.
 *
 * \return Status of the operation see \ref ptxStatus_t
 */
ptxStatus_t ptx30wHip_WritePage(uint16_t address, uint16_t data, bool verify);

/**
 * \brief Command used to read data from an arbitrary memory address of the PTX device.
 *
 * \param[in]  address    Address from which data should be read
 * \param[out] data       Pointer to read data
 * \param[in]  numBytes   Number of bytes to be read
 *
 * \return Status of the operation see \ref ptxStatus_t
 */
ptxStatus_t ptx30wHip_ReadDataMemory(uint16_t address, uint8_t *data, uint16_t numBytes);

/**
 * \brief Command used to write data to an arbitrary memory address of the PTX device.
 *
 * \param[in] address    Address of the data that must be written
 * \param[in] data       Pointer to data that must be read
 * \param[in] numWords   Number of words that must be read
 *
 * \return Status of the operation see \ref ptxStatus_t
 */
ptxStatus_t ptx30wHip_WriteDataMemory(uint16_t address, const uint8_t *data, uint16_t numBytes);

/**
* \brief Command used to  read  data from the debug interface.
*
* \param[in]  address    Address from which data should be read
* \param[out] data       Pointer to read data
* \param[in]  numBytes   Number of bytes to be read
*
* \return Status of the operation see \ref ptxStatus_t
*/
ptxStatus_t ptx30wHip_ReadDbgInterface(uint8_t address, uint8_t *data, uint8_t numBytes);

/**
* \brief Command used to write data to the debug interface.
*
* \param[in] address    Address of the data that must be written
* \param[in] data       Pointer to data that must be written
* \param[in] numBytes   Number of bytes that must be written
*
* \return Status of the operation see \ref ptxStatus_t
*/
ptxStatus_t ptx30wHip_WriteDbgInterface(uint8_t address, const uint8_t *data, uint8_t numBytes);

/**
 * \brief Command used to  read  data from the Design-for-Test interface.
 *
 * \param[in]  address    Address from which data should be read
 * \param[out] data       Pointer to read data
 * \param[in]  numBytes   Number of bytes to be read
 *
 * \return Status of the operation see \ref ptxStatus_t
 */
ptxStatus_t ptx30wHip_ReadDFTInterface(uint8_t address, uint8_t *data, uint8_t numBytes);

/**
 * \brief Command used to write data to the Design-for-Test interface.
 *
 * \param[in] address    Address of the data that must be written
 * \param[in] data       Pointer to data that must be written
 * \param[in] numBytes   Number of bytes that must be written
 *
 * \return Status of the operation see \ref ptxStatus_t
 */
ptxStatus_t ptx30wHip_WriteDftInterface(uint8_t address, const uint8_t *data, uint8_t numBytes);

#ifdef __cplusplus
}
#endif

#endif /* Guard */
