/** \file
    ---------------------------------------------------------------
    Copyright (C) 2023. Panthronics AG - All Rights Reserved.

    This material may not be reproduced, displayed, modified or
    distributed without the express prior written permission of the
    Panthronics AG.

    PLEASE CHECK FURTHER DISCLAIMER IN FILE "PTX_LICENSE.TXT"
    ---------------------------------------------------------------

    Project     : PTX30W
    Module      : STATUS
    File        : ptxStatus.h

    Description : Status codes
*/
#ifndef COMPS_PTXSTATUS_H_
#define COMPS_PTXSTATUS_H_

#include <stdint.h>

#define SHT4X_ADDR    (0x44)
/**
 * \brief Status Code Definitions
 */
typedef enum ptxStatus_Values
{
    ptxStatus_Success,                 /**< Internal The operation completed successfully. */
    ptxStatus_InvalidParameter,        /**< Invalid value(s) for function parameter(s). */
    ptxStatus_InternalError,           /**< There has been internal error in the function processing. */
    ptxStatus_NotImplemented,          /**< The function/command is not implemented. */
    ptxStatus_TimeOut,                 /**< The operation has timed out. */
    ptxStatus_InterfaceError,          /**< The interface (I/O line, UART, ...) is not accessible or an error
                                             has occurred. */
    ptxStatus_NotPermitted,            /**< The operation is not permitted. */
    ptxStatus_NscProtocolError,        /**< Error at NSC protocol. */
    ptxStatus_InsufficientResources,   /**< Insufficient Resources Error. */
    ptxStatus_ProtocolError,           /**< General protocol error. */
    ptxStatus_InvalidCommand,          /**< Command not supported at this point in time. */
    ptxStatus_NvmError,                /**< Error writing into the NVM. */
    ptxStatus_WrongHardware,           /**< The hardware version of the PTX30W doesn't match. */
    ptxStatus_NoAcknowledge,           /**< No ACK-Frame received. */
    ptxStatus_MAX                      /**< Maximum count. */
} ptxStatus_t;

typedef enum shtStatus_Values
{
    ntcStatus_Success,                 
    ntcStatus_AdcdevNoReady,
    ntcStatus_AdcChannelError,
    ntcStatus_AdcReadError,
    ntcStatus_AdcMvAcquireError
} shtStatus_t;



#endif /* Guard */
