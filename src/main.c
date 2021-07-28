#include <libopencm3/stm32/rcc.h>
#include <libopencm3/stm32/gpio.h>

/* Set STM32 to 24 MHz. */
static void clock_setup(void)
{
    rcc_clock_setup_pll(&rcc_hse_configs[RCC_CLOCK_HSE8_24MHZ]);

    /* Enable GPIOC clock. */
    rcc_periph_clock_enable(RCC_GPIOC);
}

static void gpio_setup(void)
{
    gpio_set_mode(GPIOC, GPIO_MODE_OUTPUT_50_MHZ,
                  GPIO_CNF_OUTPUT_PUSHPULL, GPIO13);
}

int main(void)
{
    int i;

    clock_setup();
    gpio_setup();

    while (1) {
        gpio_toggle(GPIOC, GPIO13);     /* Toggle LEDs. */
        for (i = 0; i < 2000000; i++)   /* Wait a bit. */
            __asm__("nop");
    }

    return 0;
}
