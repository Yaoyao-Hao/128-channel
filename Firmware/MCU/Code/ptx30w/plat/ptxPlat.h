#ifndef PTXPLAT_H_
#define PTXPLAT_H_

#include <zephyr/kernel.h>
#include <stddef.h>
#include <string.h>
#include <stdlib.h>
#include "../ptx/ptxStatus.h"

#include <nrfx_timer.h>
#ifdef __cplusplus
extern "C"
{
#endif

#define PTX_PLAT_I2C_TIMEOUT (200U) /** 200ms Timeout for I2C operation. */

    /**
     * I2C transfer status.
     */
    typedef enum ptxPlat_I2CTRxStatus
    {
        TRX_NOT_STARTED     = 0,
        TRX_TX_INPROGRESS   = 1u,
        TRX_TX_DONE         = 2u,
        TRX_RX_INPROGRESS   = 3u,
        TRX_RX_DONE         = 4u,
        TRX_TIMEOUT         = 5u,
        TRX_ERROR           = 6u
    } ptxPlat_I2CTRxStatus_t;

    int ptxPlat_I2C_Write_Read(uint8_t *txBuf, size_t txLen,uint8_t *rxBuf, size_t rxLen);

    /**
     * \brief Get an initialized I2C Interface.
     *
     * \note This function shall be successfully executed before any other call to the functions in
     * this module. It initializes I2C hardware.
     *
     * \return Status, indicating whether the operation was successful. See \ref ptxStatus_t.
     */
    ptxStatus_t ptxPlat_I2C_Init(void);
    /**
     * \brief De-initialize the I2C.
     *
     * \note This function shall be called once that the caller has finished with I2C.
     *
     * \return Status, indicating whether the operation was successful. See \ref ptxStatus_t.
     */
    ptxStatus_t ptxPlat_I2C_Deinit(void);
    /**
     * \brief I2C transmit and receive function.
     *
     *
     * \param[in]       txBuf           Buffer of data to send to peripheral device.
     * \param[in]       txLen           Length of Tx buffer: the number of data to send.
     * \param[in]       restart         If set, no stop condition is generated after Tx operation:
     * new start condition is generated instead. If 0, stop condition is generated after txBuf data
     * has been sent.
     * \param[out]      rxBuf           Buffer to receive data from peripheral
     * device.
     * \param[in,out]   rxLen           The number of bytes to receive in rxBuf. \param[in]
     *
     * \return Status, indicating whether the operation was successful. See \ref ptxStatus_t.
     */
    ptxStatus_t ptxPlat_I2C_TRx(
        const uint8_t *txBuf, size_t txLen, uint8_t restart, uint8_t *rxBuf, size_t rxLen);
    /**
     * \brief I2C transmit and receive function with retry mechanism.
     * This function should be used for communication with the PTX30W chip to use the wake up
     * mechanism. In case the PTX30W chip is not in the RF field it will go enter in sleep mode.
     * First I2C communication attempt will wake up the PTX30W and the second one should make the
     * communication possible
     *
     *
     * \param[in]       txBuf           Buffer of data to send to peripheral device.
     * \param[in]       txLen           Length of Tx buffer: the number of data to send.
     * \param[in]       restart         If set, no stop condition is generated after Tx operation:
     * new start condition is generated instead. If 0, stop condition is generated after txBuf data
     * has been sent.
     * \param[out]      rxBuf           Buffer to receive data from peripheral
     * device.
     * \param[in,out]   rxLen           The number of bytes to receive in rxBuf. \param[in]
     * \return Status, indicating whether the operation was successful. See \ref ptxStatus_t.
     */
    ptxStatus_t ptxPlat_I2C_TRx_Retry(
        const uint8_t *txBuf, size_t txLen, uint8_t restart, uint8_t *rxBuf, size_t rxLen);
    /**
     * \brief Set the address of the device that will be used for all further communication on the
     * i2c bus.
     *
     * \note This address will be active until this function is called again with another slave
     * address.
     *
     * \param[in]       slaveAddress     Address of the device to communicate with.
     *
     * \return Status, indicating whether the operation was successful. See \ref ptxStatus_t.
     */
    ptxStatus_t ptxPlat_I2C_SetSlaveAddress(uint16_t slaveAddress);
    /**
     * \brief Reset the I2C interface.
     *
     * \note I2C interface must be already initialized when calling this API.
     *     *
     * \return Status, indicating whether the operation was successful. See \ref ptxStatus_t.
     */
    ptxStatus_t ptxPlat_I2C_Reset(void);
    /**
     * \brief Initialize the external IRG connected to the PTX30W chip
     *
     * \return Status of the operation see \ref ptxStatus_t
     */
    ptxStatus_t ptxPlat_IRQ_Init(void);
    /**
     * \brief Deinitialize the external IRG connected to the PTX30W chip
     *
     * \return Status of the operation see \ref ptxStatus_t
     */
    ptxStatus_t ptxPlat_IRQ_Deinit(void);
    /**
     * \brief Wait for irq to be triggered. This function is blocking for the specified timeout duration.
     *
     * \return Status of the operation see \ref ptxStatus_t
     */
    ptxStatus_t ptxPlat_IRQ_WaitForIrq(uint32_t timeoutMs);
    /**
     * \brief Initialize a timer instance
     *
     * \return Status, indicating whether the operation was successful. See \ref ptxStatus_t.
     */
    ptxStatus_t ptxPlat_Timer_Init(nrfx_timer_event_handler_t callback);
    /**
     * \brief Deinitialize timer instance
     *
     * \return Status, indicating whether the operation was successful. See \ref ptxStatus_t.
     */
    ptxStatus_t ptxPlat_Timer_Deinit(void);
    /**
     * \brief Start periodic timer with a defined interval
     *
     * \param time[in] Timer interval in ms
     *
     * \return Status, indicating whether the operation was successful. See \ref ptxStatus_t.
     */
    ptxStatus_t ptxPlat_Timer_Start(uint32_t time);
    /**
     * \brief Stop the periodic timer
     *
     * \return Status, indicating whether the operation was successful. See \ref ptxStatus_t.
     */
    ptxStatus_t ptxPlat_Timer_Stop(void);
    /**
     * \brief Set the periodic timer callback function
     *
     * \param callback [in] pointer to the callback function
     * \return Status, indicating whether the operation was successful. See \ref ptxStatus_t.
     */
    ptxStatus_t ptxPlat_Timer_SetCb(void *callback);
    /**
     * \brief Start a  safeguard timer by initializing a periodic hardware timer and providing a
     * interrupt callback
     *
     * \param callback [in] Pointer to callback function
     * \param timeout [in] Period of the timer in ms
     * \return Status, indicating whether the operation was successful. See \ref ptxStatus_t.
     */
    ptxStatus_t ptxPlat_Timer_StartSafeguardTimer(void *callback, uint32_t timeout);
    /**
     * \brief Stop the safeguard timer by stopping the hardware timer and clearing the callback
     *
     * \return Status, indicating whether the operation was successful. See \ref ptxStatus_t.
     */
    ptxStatus_t ptxPlat_Timer_StopSafeguardTimer();
    /**
     * \brief Busy wait implementation. Only use for very small delays!
     */
    void ptxPlat_Timer_Delay(uint32_t delayMs);

    shtStatus_t sht40_I2C_TRx(uint8_t reg, uint8_t *p_data);
#ifdef __cplusplus
}
#endif

#endif /*Guard*/
