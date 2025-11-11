/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2025 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"
#include "usb_device.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include "rom_data.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "usbd_cdc_if.h"
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/

/* USER CODE BEGIN PV */

extern volatile uint8_t EmulateMode;

/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
/* USER CODE BEGIN PFP */
void UART_ProcessReceivedData(void);
void UART_TransmitMessage(const char *message);
/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */


// ============================================================================
// ADDRESS BUS READING
// ============================================================================

uint16_t GetAddressBusValue(void)
{
    uint16_t addr = 0;

    // Read GPIO ports
    uint32_t portA = GPIOA->IDR;
    uint32_t portB = GPIOB->IDR;

    // A1-A11 all on GPIOA
    addr |= ((portA & A1_Pin)  ? (1 << 0)  : 0);
    addr |= ((portA & A2_Pin)  ? (1 << 1)  : 0);
    addr |= ((portA & A3_Pin)  ? (1 << 2)  : 0);
    addr |= ((portA & A4_Pin)  ? (1 << 3)  : 0);
    addr |= ((portA & A5_Pin)  ? (1 << 4)  : 0);
    addr |= ((portA & A6_Pin)  ? (1 << 5)  : 0);
    addr |= ((portA & A7_Pin)  ? (1 << 6)  : 0);
    addr |= ((portA & A8_Pin)  ? (1 << 7)  : 0);
    addr |= ((portA & A9_Pin)  ? (1 << 8)  : 0);
    addr |= ((portA & A10_Pin) ? (1 << 9)  : 0);
    addr |= ((portA & A11_Pin) ? (1 << 10) : 0);

    // A12-A13 on GPIOB
    addr |= ((portB & A12_Pin) ? (1 << 11) : 0);
    addr |= ((portB & A13_Pin) ? (1 << 12) : 0);

    return addr;
}

// ============================================================================
// DATA BUS WRITING
// ============================================================================

static void SetDataBusValue(uint8_t data)
{
    // Your pin mapping:
    // PB0 -> D1 (bit 0)
    // PB1 -> D2 (bit 1)
    // PB2 -> D3 (bit 2)
    // PB3 -> D8 (bit 7)
    // PB4 -> D7 (bit 6)
    // PB5 -> D6 (bit 5)
    // PB6 -> D5 (bit 4)
    // PB7 -> D4 (bit 3)

    uint32_t output = GPIOB->ODR;

    // Clear data pins while preserving A12, A13
    output &= ~(D1_Pin | D2_Pin | D3_Pin | D4_Pin | D5_Pin | D6_Pin | D7_Pin | D8_Pin);

    // Map each data bit to its corresponding pin
    if (data & (1 << 0)) output |= D1_Pin;  // D1
    if (data & (1 << 1)) output |= D2_Pin;  // D2
    if (data & (1 << 2)) output |= D3_Pin;  // D3
    if (data & (1 << 3)) output |= D4_Pin;  // D4
    if (data & (1 << 4)) output |= D5_Pin;  // D5
    if (data & (1 << 5)) output |= D6_Pin;  // D6
    if (data & (1 << 6)) output |= D7_Pin;  // D7
    if (data & (1 << 7)) output |= D8_Pin;  // D8

    GPIOB->ODR = output;
}

/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{

  /* USER CODE BEGIN 1 */

  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_USB_DEVICE_Init();
  /* USER CODE BEGIN 2 */

  HAL_GPIO_WritePin(DIR_STM_GPIO_Port, DIR_STM_Pin, GPIO_PIN_RESET); //From Eeprom to Datalines
  HAL_GPIO_WritePin(CE_STM_GPIO_Port, CE_STM_Pin, GPIO_PIN_RESET); //Enable Eeprom
  HAL_GPIO_WritePin(OE_STM_GPIO_Port, OE_STM_Pin, GPIO_PIN_RESET); //Enable Output
  HAL_GPIO_WritePin(WE_STM_GPIO_Port, WE_STM_Pin, GPIO_PIN_SET); //Disable Writing

  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
	  if (currentState == STATE_EMULATOR)
	      {
	          // Get current 13-bit address
	          uint16_t address = GetAddressBusValue();

	          // Bounds check for safety
	          if (address < ROM_DATA_SIZE)
	          {
	              uint8_t data = rom_data[address];
	              SetDataBusValue(data);
	          }
	          else
	          {
	              // Output 0xFF for out-of-bounds addresses (typical for unprogrammed ROM)
	              SetDataBusValue(0xFF);
	          }
	      }

  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Configure the main internal regulator output voltage
  */
  __HAL_RCC_PWR_CLK_ENABLE();
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;
  RCC_OscInitStruct.HSEState = RCC_HSE_ON;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSE;
  RCC_OscInitStruct.PLL.PLLM = 25;
  RCC_OscInitStruct.PLL.PLLN = 192;
  RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV2;
  RCC_OscInitStruct.PLL.PLLQ = 4;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV2;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV1;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_1) != HAL_OK)
  {
    Error_Handler();
  }
}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};
  /* USER CODE BEGIN MX_GPIO_Init_1 */

  /* USER CODE END MX_GPIO_Init_1 */

  /* GPIO Ports Clock Enable */
  __HAL_RCC_GPIOC_CLK_ENABLE();
  __HAL_RCC_GPIOH_CLK_ENABLE();
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOB_CLK_ENABLE();

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(GPIOC, Sanity_led_Pin|WE_STM_Pin|OE_STM_Pin, GPIO_PIN_RESET);

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(GPIOB, DIR_STM_Pin|CE_STM_Pin, GPIO_PIN_RESET);

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(A11_GPIO_Port, A11_Pin, GPIO_PIN_RESET);

  /*Configure GPIO pins : Sanity_led_Pin WE_STM_Pin OE_STM_Pin */
  GPIO_InitStruct.Pin = Sanity_led_Pin|WE_STM_Pin|OE_STM_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);

  /*Configure GPIO pins : A1_Pin A2_Pin A3_Pin A4_Pin
                           A5_Pin A6_Pin A7_Pin A8_Pin
                           A9_Pin A10_Pin */
  GPIO_InitStruct.Pin = A1_Pin|A2_Pin|A3_Pin|A4_Pin
                          |A5_Pin|A6_Pin|A7_Pin|A8_Pin
                          |A9_Pin|A10_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

  /*Configure GPIO pins : D1_Pin D2_Pin D3_Pin A12_Pin
                           A13_Pin D8_Pin D7_Pin D6_Pin
                           D5_Pin D4_Pin */
  GPIO_InitStruct.Pin = D1_Pin|D2_Pin|D3_Pin|A12_Pin
                          |A13_Pin|D8_Pin|D7_Pin|D6_Pin
                          |D5_Pin|D4_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

  /*Configure GPIO pins : DIR_STM_Pin CE_STM_Pin */
  GPIO_InitStruct.Pin = DIR_STM_Pin|CE_STM_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

  /*Configure GPIO pin : A11_Pin */
  GPIO_InitStruct.Pin = A11_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(A11_GPIO_Port, &GPIO_InitStruct);

  /* USER CODE BEGIN MX_GPIO_Init_2 */

  /* USER CODE END MX_GPIO_Init_2 */
}

/* USER CODE BEGIN 4 */



/* USER CODE END 4 */

/**
  * @brief  Period elapsed callback in non blocking mode
  * @note   This function is called  when TIM1 interrupt took place, inside
  * HAL_TIM_IRQHandler(). It makes a direct call to HAL_IncTick() to increment
  * a global variable "uwTick" used as application time base.
  * @param  htim : TIM handle
  * @retval None
  */
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
{
  /* USER CODE BEGIN Callback 0 */

  /* USER CODE END Callback 0 */
  if (htim->Instance == TIM1)
  {
    HAL_IncTick();
  }
  /* USER CODE BEGIN Callback 1 */

  /* USER CODE END Callback 1 */
}

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}
#ifdef USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
