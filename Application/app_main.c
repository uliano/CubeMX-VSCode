
#include "app_main.h"
//#include "gpio.h"

#include <stdio.h>
#include <inttypes.h>

void app_main(void)
{
 uint32_t tick_counter = 0;
  printf("STM32G071 started! Printf redirection working!\n");

  while (1)
  {
    printf("Tick: %" PRIu32 "\n", tick_counter++);
    HAL_GPIO_TogglePin(LED_GREEN_GPIO_Port, LED_GREEN_Pin);
    HAL_Delay(1000);
  }
}
