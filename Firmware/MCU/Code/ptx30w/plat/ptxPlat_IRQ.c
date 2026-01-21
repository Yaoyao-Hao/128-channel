#include <zephyr/kernel.h>
#include <zephyr/drivers/gpio.h>
#include "ptxPlat.h"

#define WAIT_FOR_IRQ_TIMEOUT (20U) /** Timeout for waiting for an IRQ. */
#define BSP_IO_LEVEL_LOW        0

#define PTX30W_IRQ_NODE DT_ALIAS(gpiocus0)
static const struct gpio_dt_spec ptx30wIrq = GPIO_DT_SPEC_GET_OR(PTX30W_IRQ_NODE, gpios, {0});
static struct gpio_callback ptx30w_cb_data;

static void safeguardCallback(nrf_timer_event_t event_type, void* p_context);
static enum { IrqStatus_Wait, IrqStatus_Triggered, IrqStatus_Timeout } sIrqStatus;

void PtxIrq_Callback(const struct device *dev, struct gpio_callback *cb,
		    uint32_t pins)
{
    sIrqStatus = IrqStatus_Triggered;
}

ptxStatus_t ptxPlat_IRQ_Init(void)
{
    ptxStatus_t status = ptxStatus_Success;
    int ret;

    if (!device_is_ready(ptx30wIrq.port)) 
    {	
        status = ptxStatus_InternalError;
		return status;
	}

    ret = gpio_pin_configure_dt(&ptx30wIrq, GPIO_INPUT);
    if (ret != 0) 
    {		
        status = ptxStatus_InternalError;

		return status;
	}

    ret = gpio_pin_interrupt_configure_dt(&ptx30wIrq, GPIO_INT_EDGE_TO_ACTIVE);
    if (ret != 0) 
    {		
        status = ptxStatus_InternalError;

		return status;
	}

    gpio_init_callback(&ptx30w_cb_data, PtxIrq_Callback, BIT(ptx30wIrq.pin));

    gpio_add_callback(ptx30wIrq.port, &ptx30w_cb_data);

    return status;
}

ptxStatus_t ptxPlat_IRQ_Deinit(void)
{
    ptxStatus_t status = ptxStatus_Success;   

    return status;
}

ptxStatus_t ptxPlat_IRQ_WaitForIrq(uint32_t timeoutMs)
{
    ptxStatus_t status = ptxStatus_Success;
    int ret;

    sIrqStatus = IrqStatus_Wait;

    /** Read the pin level first. */    
    ret = gpio_pin_get_dt(&ptx30wIrq);
    /** If the IRQ is not yet triggered, wait for timeout. */
    if (BSP_IO_LEVEL_LOW == ret)
    {
        if(0 != timeoutMs)
        {
            status = ptxPlat_Timer_StartSafeguardTimer(safeguardCallback, timeoutMs);
            if (ptxStatus_Success == status)
            {
                while (IrqStatus_Wait == sIrqStatus)
                {
                    __DSB();
                    __WFI();
                    __ISB();
                }

                if (IrqStatus_Timeout == sIrqStatus)
                {
                    status = ptxStatus_TimeOut;
                }
            }
            (void)ptxPlat_Timer_StopSafeguardTimer();
        }
        else
        {
            status = ptxStatus_TimeOut;
        }
    }

    return status;
}


static void safeguardCallback(nrf_timer_event_t event_type, void* p_context)
{
    // FSP_PARAMETER_NOT_USED(ctx);
    sIrqStatus = IrqStatus_Timeout;
}
