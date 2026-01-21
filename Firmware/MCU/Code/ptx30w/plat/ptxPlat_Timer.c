#include <zephyr/kernel.h>
#include <nrf.h>
#include <nrf52840.h>
#include <nrfx_timer.h>
#include "ptxPlat.h"

#define TIMER_TICKS_PER_MS (100000U)

#define TIMER1_PERIOD   100000
#define TIMER1_ISR_PRIORITY  1

const nrfx_timer_t  Timer1_Instance = NRFX_TIMER_INSTANCE(1);
nrfx_timer_config_t Timer1_config = NRFX_TIMER_DEFAULT_CONFIG;

ptxStatus_t ptxPlat_Timer_Init(nrfx_timer_event_handler_t callback)
{
    ptxStatus_t status = ptxStatus_Success;
    /** Initialize General Purpose Timer (GPT) driver. */
    Timer1_config.bit_width = NRF_TIMER_BIT_WIDTH_32;
    nrfx_err_t err = nrfx_timer_init(&Timer1_Instance, &Timer1_config, callback);
    if(err != NRFX_SUCCESS)
    {
        status = ptxStatus_InternalError;            
    }
    // if(err == NRFX_SUCCESS)
    // {
    //     IRQ_CONNECT(NRFX_IRQ_NUMBER_GET(NRF_TIMER1), TIMER1_ISR_PRIORITY, nrfx_isr, nrfx_timer_1_irq_handler, 0);                   
    // }
    // else
    // {
    //     status = ptxStatus_InternalError;
    // }
    return status;
}

ptxStatus_t ptxPlat_Timer_Deinit(void)
{
    ptxStatus_t status = ptxStatus_Success;

    nrfx_timer_uninit(&Timer1_Instance);
    return status;
}

ptxStatus_t ptxPlat_Timer_Start(uint32_t time)
{
    ptxStatus_t status = ptxStatus_Success;
    uint32_t timer_ticks;

    /** Set the timeout & start the timer 100 000ms*/
    timer_ticks = nrfx_timer_ms_to_ticks(&Timer1_Instance, time); 

    nrfx_timer_extended_compare(&Timer1_Instance, NRF_TIMER_CC_CHANNEL0, timer_ticks, NRF_TIMER_SHORT_COMPARE0_STOP_MASK, true);

    nrfx_timer_enable(&Timer1_Instance);   

    return status;
}

ptxStatus_t ptxPlat_Timer_Stop(void)
{
    ptxStatus_t status = ptxStatus_Success;

    nrfx_timer_disable(&Timer1_Instance);

    return status;
}

ptxStatus_t ptxPlat_Timer_SetCb(void *callback)
{
    ptxStatus_t status = ptxStatus_Success;

    return status;
}

ptxStatus_t ptxPlat_Timer_StartSafeguardTimer(void *callback, uint32_t timeout)
{
    ptxStatus_t status = ptxStatus_Success;
    status = ptxPlat_Timer_Init(callback);

    if (ptxStatus_Success == status)
    {
        status = ptxPlat_Timer_Start(timeout);
    }

    return status;
}

ptxStatus_t ptxPlat_Timer_StopSafeguardTimer()
{
    ptxStatus_t status = ptxStatus_Success;

    status = ptxPlat_Timer_Deinit();

    return status;
}

void ptxPlat_Timer_Delay(uint32_t delayMs)
{
    k_sleep(K_MSEC(delayMs));
}
