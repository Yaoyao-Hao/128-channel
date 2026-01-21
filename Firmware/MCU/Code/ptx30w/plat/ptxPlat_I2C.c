#include <errno.h>
#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <zephyr/drivers/i2c.h>
#include <zephyr/sys/util.h>
#include "ptxPlat.h"
#include <zephyr/pm/pm.h>
#include <zephyr/pm/device.h>
#include <zephyr/pm/device_runtime.h>
#include <hal/nrf_gpio.h>

#include <string.h>

#define I2C_COM_RETRY (2U)

#define i2CTransferSuccess  0

const struct device *const i2c_dev = DEVICE_DT_GET(DT_NODELABEL(i2c0));

static uint16_t ptx30wAddress;

#define SHT4X_ADDR    (0x44)


ptxStatus_t ptxPlat_I2C_Init(void)
{
    ptxStatus_t status = ptxStatus_Success; 

    /** Initialize I2C driver. */    

    if (!device_is_ready(i2c_dev)) 
    {
        status = ptxStatus_InternalError;
	}

    int err = i2c_configure(i2c_dev, I2C_SPEED_SET(I2C_SPEED_STANDARD));
    if(err != 0)
    {
        status = ptxStatus_InternalError;
    }

    return status;
}

ptxStatus_t ptxPlat_I2C_Deinit(void)
{
    ptxStatus_t status = ptxStatus_Success;

    pm_device_runtime_put(i2c_dev); 

    return status;
}


//important function
ptxStatus_t ptxPlat_I2C_TRx(const uint8_t *txBuf, size_t txLen, uint8_t restart, uint8_t *rxBuf, size_t rxLen)
{
    ptxStatus_t status = ptxStatus_Success;
    /** Let's see if there is something to write. */
    if ((NULL != txBuf) && (0 < txLen))
    {
        if((NULL != rxBuf) && (0 < rxLen))
        {
            if(restart == true)
            {
                if(i2CTransferSuccess != i2c_write_read(i2c_dev, ptx30wAddress, (uint8_t *)txBuf, txLen, rxBuf, rxLen))
                {
                    status = ptxStatus_InterfaceError;
                }
            }
            else
            {
                if(i2CTransferSuccess == i2c_write(i2c_dev, (uint8_t *)txBuf, txLen, ptx30wAddress))
                {
                    if(i2CTransferSuccess != i2c_read(i2c_dev, rxBuf, rxLen, ptx30wAddress))
                    {
                        status = ptxStatus_InterfaceError;
                    }
                }
                else
                {
                    status = ptxStatus_InterfaceError;
                }                
            }            
        }
    }
    else
    {
        status = ptxStatus_InvalidParameter;
    }

    return status;
}

ptxStatus_t ptxPlat_I2C_TRx_Retry(
    const uint8_t *txBuf, size_t txLen, uint8_t restart, uint8_t *rxBuf, size_t rxLen)
{
    ptxStatus_t status = ptxStatus_Success;
    uint8_t retry = I2C_COM_RETRY;
    do
    {
        status = ptxPlat_I2C_TRx(txBuf, txLen, restart, rxBuf, rxLen);
        /** If there is a failure, we must wait a bit until the PTX30W boots up and retry. */
        if (ptxStatus_Success != status)
        {
            k_sleep(K_MSEC(1));
        }
        retry--;
    } while ((ptxStatus_Success != status) && (0 != retry));

    return status;
}

ptxStatus_t ptxPlat_I2C_SetSlaveAddress(uint16_t slaveAddress)
{
    ptxStatus_t status = ptxStatus_Success;
    
    /** Sets the address for the I2C slave device. */
    ptx30wAddress = slaveAddress;

    return status;
}

ptxStatus_t ptxPlat_I2C_Reset(void)
{
    ptxStatus_t status = ptxStatus_Success;

    /** Deinitialize and reinitialize the I2C HW module. */
    status = ptxPlat_I2C_Deinit();

    if (ptxStatus_Success == status)
    {
        status = ptxPlat_I2C_Init();
    }

    return status;
}

shtStatus_t sht40_I2C_TRx(uint8_t reg, uint8_t *p_data){
    shtStatus_t status = ntcStatus_Success;

    i2c_write(i2c_dev, &reg, 1, SHT4X_ADDR);
    k_msleep(10);
    i2c_read(i2c_dev, p_data, 6, SHT4X_ADDR);

    return status;
}

#if 0
static void safeguardCallback(nrf_timer_event_t event_type, void* p_context);

static ptxPlat_I2CTRxStatus_t sCallbackEvent;
/** Callback of safeguard timer. */
static void safeguardCallback(nrf_timer_event_t event_type, void* p_context)
{
    //  FSP_PARAMETER_NOT_USED(ctx);
    sCallbackEvent = TRX_TIMEOUT;
}
#endif
