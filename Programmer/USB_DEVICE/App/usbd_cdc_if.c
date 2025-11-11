/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : usbd_cdc_if.c
  * @version        : v1.0_Cube
  * @brief          : Usb device for Virtual Com Port.
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
#include "usbd_cdc_if.h"

/* USER CODE BEGIN INCLUDE */
#include "string.h"
#include "stdlib.h"
#include "stdio.h"


/* USER CODE END INCLUDE */

/* Private typedef -----------------------------------------------------------*/
/* Private define ------------------------------------------------------------*/
/* Private macro -------------------------------------------------------------*/

/* USER CODE BEGIN PV */
/* Private variables ---------------------------------------------------------*/
#define RX_BUFFER_SIZE 2048

static char rxBuffer[RX_BUFFER_SIZE];
static uint8_t rxIndex = 0;



// ============================================================================
// STATE MACHINE DEFINITIONS
// ============================================================================

SystemState_t currentState = STATE_SNIFFER;  // Safe startup state
/* USER CODE END PV */

/** @addtogroup STM32_USB_OTG_DEVICE_LIBRARY
  * @brief Usb device library.
  * @{
  */

/** @addtogroup USBD_CDC_IF
  * @{
  */

/** @defgroup USBD_CDC_IF_Private_TypesDefinitions USBD_CDC_IF_Private_TypesDefinitions
  * @brief Private types.
  * @{
  */

/* USER CODE BEGIN PRIVATE_TYPES */

/* USER CODE END PRIVATE_TYPES */

/**
  * @}
  */

/** @defgroup USBD_CDC_IF_Private_Defines USBD_CDC_IF_Private_Defines
  * @brief Private defines.
  * @{
  */

/* USER CODE BEGIN PRIVATE_DEFINES */
/* USER CODE END PRIVATE_DEFINES */

/**
  * @}
  */

/** @defgroup USBD_CDC_IF_Private_Macros USBD_CDC_IF_Private_Macros
  * @brief Private macros.
  * @{
  */

/* USER CODE BEGIN PRIVATE_MACRO */

/* USER CODE END PRIVATE_MACRO */

/**
  * @}
  */

/** @defgroup USBD_CDC_IF_Private_Variables USBD_CDC_IF_Private_Variables
  * @brief Private variables.
  * @{
  */
/* Create buffer for reception and transmission           */
/* It's up to user to redefine and/or remove those define */
/** Received data over USB are stored in this buffer      */
uint8_t UserRxBufferFS[APP_RX_DATA_SIZE];

/** Data to send over USB CDC are stored in this buffer   */
uint8_t UserTxBufferFS[APP_TX_DATA_SIZE];

/* USER CODE BEGIN PRIVATE_VARIABLES */

/* USER CODE END PRIVATE_VARIABLES */

/**
  * @}
  */

/** @defgroup USBD_CDC_IF_Exported_Variables USBD_CDC_IF_Exported_Variables
  * @brief Public variables.
  * @{
  */

extern USBD_HandleTypeDef hUsbDeviceFS;

/* USER CODE BEGIN EXPORTED_VARIABLES */

/* USER CODE END EXPORTED_VARIABLES */

/**
  * @}
  */

/** @defgroup USBD_CDC_IF_Private_FunctionPrototypes USBD_CDC_IF_Private_FunctionPrototypes
  * @brief Private functions declaration.
  * @{
  */

static int8_t CDC_Init_FS(void);
static int8_t CDC_DeInit_FS(void);
static int8_t CDC_Control_FS(uint8_t cmd, uint8_t* pbuf, uint16_t length);
static int8_t CDC_Receive_FS(uint8_t* pbuf, uint32_t *Len);
static int8_t CDC_TransmitCplt_FS(uint8_t *pbuf, uint32_t *Len, uint8_t epnum);

/* USER CODE BEGIN PRIVATE_FUNCTIONS_DECLARATION */
static void USB_SendString(const char* str);
// Forward declaration
void USB_ProcessReceivedData(void);

static void ValidateAddress(uint16_t address);

static void ReadDataBus(void);
static void SetDataBusValue(uint8_t data);
static void WriteDataBus(uint8_t value);
static uint8_t GetDataBusValue(void);

static void ReadAddressBus(void);
static uint16_t GetAddressBusValue(void);
static void ProgramAddress(uint16_t address, uint8_t data);
static inline void delay_short(void);
/* USER CODE END PRIVATE_FUNCTIONS_DECLARATION */

/**
  * @}
  */

USBD_CDC_ItfTypeDef USBD_Interface_fops_FS =
{
  CDC_Init_FS,
  CDC_DeInit_FS,
  CDC_Control_FS,
  CDC_Receive_FS,
  CDC_TransmitCplt_FS
};

/* Private functions ---------------------------------------------------------*/
/**
  * @brief  Initializes the CDC media low layer over the FS USB IP
  * @retval USBD_OK if all operations are OK else USBD_FAIL
  */
static int8_t CDC_Init_FS(void)
{
  /* USER CODE BEGIN 3 */
  /* Set Application Buffers */
  USBD_CDC_SetTxBuffer(&hUsbDeviceFS, UserTxBufferFS, 0);
  USBD_CDC_SetRxBuffer(&hUsbDeviceFS, UserRxBufferFS);
  return (USBD_OK);
  /* USER CODE END 3 */
}

/**
  * @brief  DeInitializes the CDC media low layer
  * @retval USBD_OK if all operations are OK else USBD_FAIL
  */
static int8_t CDC_DeInit_FS(void)
{
  /* USER CODE BEGIN 4 */
  return (USBD_OK);
  /* USER CODE END 4 */
}

/**
  * @brief  Manage the CDC class requests
  * @param  cmd: Command code
  * @param  pbuf: Buffer containing command data (request parameters)
  * @param  length: Number of data to be sent (in bytes)
  * @retval Result of the operation: USBD_OK if all operations are OK else USBD_FAIL
  */
static int8_t CDC_Control_FS(uint8_t cmd, uint8_t* pbuf, uint16_t length)
{
  /* USER CODE BEGIN 5 */
  switch(cmd)
  {
    case CDC_SEND_ENCAPSULATED_COMMAND:

    break;

    case CDC_GET_ENCAPSULATED_RESPONSE:

    break;

    case CDC_SET_COMM_FEATURE:

    break;

    case CDC_GET_COMM_FEATURE:

    break;

    case CDC_CLEAR_COMM_FEATURE:

    break;

  /*******************************************************************************/
  /* Line Coding Structure                                                       */
  /*-----------------------------------------------------------------------------*/
  /* Offset | Field       | Size | Value  | Description                          */
  /* 0      | dwDTERate   |   4  | Number |Data terminal rate, in bits per second*/
  /* 4      | bCharFormat |   1  | Number | Stop bits                            */
  /*                                        0 - 1 Stop bit                       */
  /*                                        1 - 1.5 Stop bits                    */
  /*                                        2 - 2 Stop bits                      */
  /* 5      | bParityType |  1   | Number | Parity                               */
  /*                                        0 - None                             */
  /*                                        1 - Odd                              */
  /*                                        2 - Even                             */
  /*                                        3 - Mark                             */
  /*                                        4 - Space                            */
  /* 6      | bDataBits  |   1   | Number Data bits (5, 6, 7, 8 or 16).          */
  /*******************************************************************************/
    case CDC_SET_LINE_CODING:

    break;

    case CDC_GET_LINE_CODING:

    break;

    case CDC_SET_CONTROL_LINE_STATE:

    break;

    case CDC_SEND_BREAK:

    break;

  default:
    break;
  }

  return (USBD_OK);
  /* USER CODE END 5 */
}

/**
  * @brief  Data received over USB OUT endpoint are sent over CDC interface
  *         through this function.
  *
  *         @note
  *         This function will issue a NAK packet on any OUT packet received on
  *         USB endpoint until exiting this function. If you exit this function
  *         before transfer is complete on CDC interface (ie. using DMA controller)
  *         it will result in receiving more data while previous ones are still
  *         not sent.
  *
  * @param  Buf: Buffer of data to be received
  * @param  Len: Number of data received (in bytes)
  * @retval Result of the operation: USBD_OK if all operations are OK else USBD_FAIL
  */
static int8_t CDC_Receive_FS(uint8_t* Buf, uint32_t *Len)
{
  /* USER CODE BEGIN 6 */
    for (uint32_t i = 0; i < *Len; i++)
    {
        char c = Buf[i];

        if (c == '\n' || c == '\r' || rxIndex >= RX_BUFFER_SIZE - 1)
        {
            rxBuffer[rxIndex] = '\0';   // null terminate
            USB_ProcessReceivedData();  // parse the command
            rxIndex = 0;                // reset buffer
        }
        else
        {
            rxBuffer[rxIndex++] = c;    // store incoming char
        }
    }

    // Prepare USB for next packet
    USBD_CDC_SetRxBuffer(&hUsbDeviceFS, Buf);
    USBD_CDC_ReceivePacket(&hUsbDeviceFS);

    return (USBD_OK);
  /* USER CODE END 6 */
}

/**
  * @brief  CDC_Transmit_FS
  *         Data to send over USB IN endpoint are sent over CDC interface
  *         through this function.
  *         @note
  *
  *
  * @param  Buf: Buffer of data to be sent
  * @param  Len: Number of data to be sent (in bytes)
  * @retval USBD_OK if all operations are OK else USBD_FAIL or USBD_BUSY
  */
uint8_t CDC_Transmit_FS(uint8_t* Buf, uint16_t Len)
{
  uint8_t result = USBD_OK;
  /* USER CODE BEGIN 7 */
  USBD_CDC_HandleTypeDef *hcdc = (USBD_CDC_HandleTypeDef*)hUsbDeviceFS.pClassData;
  if (hcdc->TxState != 0){
    return USBD_BUSY;
  }
  USBD_CDC_SetTxBuffer(&hUsbDeviceFS, Buf, Len);
  result = USBD_CDC_TransmitPacket(&hUsbDeviceFS);
  /* USER CODE END 7 */
  return result;
}

/**
  * @brief  CDC_TransmitCplt_FS
  *         Data transmitted callback
  *
  *         @note
  *         This function is IN transfer complete callback used to inform user that
  *         the submitted Data is successfully sent over USB.
  *
  * @param  Buf: Buffer of data to be received
  * @param  Len: Number of data received (in bytes)
  * @retval Result of the operation: USBD_OK if all operations are OK else USBD_FAIL
  */
static int8_t CDC_TransmitCplt_FS(uint8_t *Buf, uint32_t *Len, uint8_t epnum)
{
  uint8_t result = USBD_OK;
  /* USER CODE BEGIN 13 */
  UNUSED(Buf);
  UNUSED(Len);
  UNUSED(epnum);
  /* USER CODE END 13 */
  return result;
}

/* USER CODE BEGIN PRIVATE_FUNCTIONS_IMPLEMENTATION */


// ============================================================================
// GPIO CONFIGURATION FOR EACH STATE
// ============================================================================

static void ConfigureGPIO_Sniffer(void)
{
    // All pins as INPUT (high impedance)
    GPIO_InitTypeDef GPIO_InitStruct = {0};

    // Data pins D1-D8 on GPIOB as INPUT
    GPIO_InitStruct.Pin = D1_Pin|D2_Pin|D3_Pin|D4_Pin|D5_Pin|D6_Pin|D7_Pin|D8_Pin;
    GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

    // Address pins A1-A11 on GPIOA as INPUT
    GPIO_InitStruct.Pin = A1_Pin|A2_Pin|A3_Pin|A4_Pin|A5_Pin|A6_Pin|A7_Pin|A8_Pin|A9_Pin|A10_Pin|A11_Pin;
    GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

    // Address pins A12-A13 on GPIOB as INPUT
    GPIO_InitStruct.Pin = A12_Pin|A13_Pin;
    GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);
}

static void ConfigureGPIO_Emulator(void)
{
    // Address pins: INPUT (listen to incoming addresses)
    // Data pins: OUTPUT (respond with data)
    GPIO_InitTypeDef GPIO_InitStruct = {0};

    // Data pins D1-D8 on GPIOB as OUTPUT
    GPIO_InitStruct.Pin = D1_Pin|D2_Pin|D3_Pin|D4_Pin|D5_Pin|D6_Pin|D7_Pin|D8_Pin;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_HIGH;
    HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

    // Address pins A1-A11 on GPIOA as INPUT
    GPIO_InitStruct.Pin = A1_Pin|A2_Pin|A3_Pin|A4_Pin|A5_Pin|A6_Pin|A7_Pin|A8_Pin|A9_Pin|A10_Pin|A11_Pin;
    GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

    // Address pins A12-A13 on GPIOB as INPUT
    GPIO_InitStruct.Pin = A12_Pin|A13_Pin;
    GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);
}

static void ConfigureGPIO_Programmer(void)
{
    // All pins as OUTPUT (drive address and data buses)
    GPIO_InitTypeDef GPIO_InitStruct = {0};

    // Data pins D1-D8 on GPIOB as OUTPUT
    GPIO_InitStruct.Pin = D1_Pin|D2_Pin|D3_Pin|D4_Pin|D5_Pin|D6_Pin|D7_Pin|D8_Pin;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_HIGH;
    HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

    // Address pins A1-A11 on GPIOA as OUTPUT
    GPIO_InitStruct.Pin = A1_Pin|A2_Pin|A3_Pin|A4_Pin|A5_Pin|A6_Pin|A7_Pin|A8_Pin|A9_Pin|A10_Pin|A11_Pin;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_HIGH;
    HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

    // Address pins A12-A13 on GPIOB as OUTPUT
    GPIO_InitStruct.Pin = A12_Pin|A13_Pin;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_HIGH;
    HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

}

static void ConfigureGPIO_Validator(void)
{
    // Address pins: OUTPUT (generate addresses to read)
    // Data pins: INPUT (read back data from EEPROM)
    GPIO_InitTypeDef GPIO_InitStruct = {0};

    // Data pins D1-D8 on GPIOB as INPUT
    GPIO_InitStruct.Pin = D1_Pin|D2_Pin|D3_Pin|D4_Pin|D5_Pin|D6_Pin|D7_Pin|D8_Pin;
    GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

    // Address pins A1-A11 on GPIOA as OUTPUT
    GPIO_InitStruct.Pin = A1_Pin|A2_Pin|A3_Pin|A4_Pin|A5_Pin|A6_Pin|A7_Pin|A8_Pin|A9_Pin|A10_Pin|A11_Pin;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_HIGH;
    HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

    // Address pins A12-A13 on GPIOB as OUTPUT
    GPIO_InitStruct.Pin = A12_Pin|A13_Pin;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_HIGH;
    HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);
}

static void ConfigureGPIO_Debug(void)
{
    // Data pins: OUTPUT (write test data)
    // Address pins: INPUT (read what's being addressed)
    GPIO_InitTypeDef GPIO_InitStruct = {0};

    // Data pins D1-D8 on GPIOB as OUTPUT
    GPIO_InitStruct.Pin = D1_Pin|D2_Pin|D3_Pin|D4_Pin|D5_Pin|D6_Pin|D7_Pin|D8_Pin;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_HIGH;
    HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

    // Address pins A1-A11 on GPIOA as INPUT
    GPIO_InitStruct.Pin = A1_Pin|A2_Pin|A3_Pin|A4_Pin|A5_Pin|A6_Pin|A7_Pin|A8_Pin|A9_Pin|A10_Pin|A11_Pin;
    GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

    // Address pins A12-A13 on GPIOB as INPUT
    GPIO_InitStruct.Pin = A12_Pin|A13_Pin;
    GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);
}


// ============================================================================
// STATE TRANSITION FUNCTION
// ============================================================================

static void TransitionToState(SystemState_t newState)
{
    if (currentState == newState)
    {
        USB_SendString("Already in requested state\r\n");
        return;
    }

    HAL_GPIO_WritePin(WE_STM_GPIO_Port, WE_STM_Pin, GPIO_PIN_SET); //Disable Writing
    // Configure GPIO for new state
    switch (newState)
    {
        case STATE_SNIFFER:
            ConfigureGPIO_Sniffer();
            currentState = STATE_SNIFFER;
            USB_SendString("STATE: Sniffer Mode\r\n");
            HAL_GPIO_WritePin(DIR_STM_GPIO_Port, DIR_STM_Pin, GPIO_PIN_RESET); //From Eeprom to Datalines
            HAL_GPIO_WritePin(CE_STM_GPIO_Port, CE_STM_Pin, GPIO_PIN_RESET); //Enable Eeprom
            HAL_GPIO_WritePin(OE_STM_GPIO_Port, OE_STM_Pin, GPIO_PIN_RESET); //Enable Output
            break;

        case STATE_EMULATOR:
            ConfigureGPIO_Emulator();
            currentState = STATE_EMULATOR;
            USB_SendString("STATE: Emulator Mode\r\n");
            HAL_GPIO_WritePin(DIR_STM_GPIO_Port, DIR_STM_Pin, GPIO_PIN_RESET); //From Eeprom to Datalines
            HAL_GPIO_WritePin(CE_STM_GPIO_Port, CE_STM_Pin, GPIO_PIN_SET); //Disable Eeprom
            HAL_GPIO_WritePin(OE_STM_GPIO_Port, OE_STM_Pin, GPIO_PIN_SET); //Disable Output
            break;

        case STATE_PROGRAMMER:
            ConfigureGPIO_Programmer();
            currentState = STATE_PROGRAMMER;
            USB_SendString("STATE: Programmer Mode\r\n");
            HAL_GPIO_WritePin(DIR_STM_GPIO_Port, DIR_STM_Pin, GPIO_PIN_SET); //From Datalines to Eeprom
            HAL_GPIO_WritePin(CE_STM_GPIO_Port, CE_STM_Pin, GPIO_PIN_RESET); //Enable Eeprom
            HAL_GPIO_WritePin(OE_STM_GPIO_Port, OE_STM_Pin, GPIO_PIN_SET); //Disable Output
            break;

        case STATE_VALIDATOR:
            ConfigureGPIO_Validator();
            currentState = STATE_VALIDATOR;
            USB_SendString("STATE: Validator Mode\r\n");
            HAL_GPIO_WritePin(DIR_STM_GPIO_Port, DIR_STM_Pin, GPIO_PIN_RESET); //From Eeprom to Datalines
            HAL_GPIO_WritePin(CE_STM_GPIO_Port, CE_STM_Pin, GPIO_PIN_RESET); //Enable Eeprom
            HAL_GPIO_WritePin(OE_STM_GPIO_Port, OE_STM_Pin, GPIO_PIN_RESET); //Enable Output
            break;

        case STATE_DEBUG:
            ConfigureGPIO_Debug();
            currentState = STATE_DEBUG;
            USB_SendString("STATE: Debug Mode\r\n");
            HAL_GPIO_WritePin(DIR_STM_GPIO_Port, DIR_STM_Pin, GPIO_PIN_RESET); //From Eeprom to Datalines
            HAL_GPIO_WritePin(CE_STM_GPIO_Port, CE_STM_Pin, GPIO_PIN_SET); //Disable Eeprom
            HAL_GPIO_WritePin(OE_STM_GPIO_Port, OE_STM_Pin, GPIO_PIN_SET); //Disable Output
            break;

        default:
            USB_SendString("ERROR: Invalid state\r\n");
            break;
    }
}



void USB_ProcessReceivedData(void)
{
    // Convert to uppercase for easier comparison
    char cmd[16];
    strncpy(cmd, rxBuffer, sizeof(cmd) - 1);
    cmd[sizeof(cmd) - 1] = '\0';

    // Convert to uppercase
    for (int i = 0; cmd[i]; i++)
    {
        if (cmd[i] >= 'a' && cmd[i] <= 'z')
            cmd[i] = cmd[i] - 'a' + 'A';
    }

    // Parse state change commands
    if (strcmp(cmd, "SNF") == 0)
    {
        TransitionToState(STATE_SNIFFER);
    }
    else if (strcmp(cmd, "EMU") == 0)
    {
        TransitionToState(STATE_EMULATOR);
    }
    else if (strcmp(cmd, "PRG") == 0)
    {
        TransitionToState(STATE_PROGRAMMER);
    }
    else if (strcmp(cmd, "VAL") == 0)
    {
        TransitionToState(STATE_VALIDATOR);
    }
    else if (strcmp(cmd, "DBG") == 0)
    {
        TransitionToState(STATE_DEBUG);
    }
    else if (strcmp(cmd, "RDA") == 0) //Read Address
    {
    	ReadAddressBus();
    }
    else if (strcmp(cmd, "RDD") == 0) //Read Data
    {
    	ReadDataBus();
    }else if (strncmp(cmd, "PA", 2) == 0)  // Program Address
    {
        // Expected format: "PA;4096;215" or "PA;5;4"

        // Quick state check before parsing
        if (currentState != STATE_PROGRAMMER)
        {
            USB_SendString("ERROR: PA command only available in Programmer mode\r\n");
            return;
        }

        char *token1 = strchr(cmd, ';');
        if (token1 == NULL)
        {
            USB_SendString("ERROR: Format is PA;ADDRESS;DATA (e.g., PA;4096;215)\r\n");
            return;
        }
        token1++;  // Move past first ';'

        char *token2 = strchr(token1, ';');
        if (token2 == NULL)
        {
            USB_SendString("ERROR: Format is PA;ADDRESS;DATA (e.g., PA;4096;215)\r\n");
            return;
        }
        token2++;  // Move past second ';'

        // Parse address and data
        uint32_t address = strtoul(token1, NULL, 10);
        uint32_t data = strtoul(token2, NULL, 10);

        // Bounds checking
        if (address > 8191)
        {
            USB_SendString("ERROR: Address must be 0-8191\r\n");
            return;
        }

        if (data > 255)
        {
            USB_SendString("ERROR: Data must be 0-255\r\n");
            return;
        }

        ProgramAddress((uint16_t)address, (uint8_t)data);
    }
    else if (strncmp(cmd, "WDB", 3) == 0)  // Write Data Bus
    {
        // Expected format: "WDB;123" or "WDB;0xFF"
        char *separator = strchr(cmd, ';');

        if (separator == NULL)
        {
            USB_SendString("ERROR: Format is WDB;VALUE (e.g., WDB;123 or WDB;0xFF)\r\n");
            return;
        }

        separator++;  // Move past the ';'

        // Parse the value (supports decimal and hex with 0x prefix)
        uint32_t value = 0;

        if (strncmp(separator, "0X", 2) == 0 || strncmp(separator, "0x", 2) == 0)
        {
            // Hex format
            value = strtoul(separator, NULL, 16);
        }
        else
        {
            // Decimal format
            value = strtoul(separator, NULL, 10);
        }

        // Bounds check
        if (value > 255)
        {
            USB_SendString("ERROR: Value must be 0-255\r\n");
            return;
        }

        WriteDataBus((uint8_t)value);
    }else if (strncmp(cmd, "VA", 2) == 0)  // Validate Address
    {
        // Expected format: "VA;4096" or "VA;0"

        // Quick state check before parsing
        if (currentState != STATE_VALIDATOR)
        {
            USB_SendString("ERROR: VA command only available in Validator mode\r\n");
            return;
        }

        char *token = strchr(cmd, ';');
        if (token == NULL)
        {
            USB_SendString("ERROR: Format is VA;ADDRESS (e.g., VA;4096)\r\n");
            return;
        }
        token++;  // Move past ';'

        // Parse address
        uint32_t address = strtoul(token, NULL, 10);

        // Bounds checking
        if (address > 8191)
        {
            USB_SendString("ERROR: Address must be 0-8191\r\n");
            return;
        }

        ValidateAddress((uint16_t)address);
    }
    else if (strcmp(cmd, "STATUS") == 0 || strcmp(cmd, "?") == 0)
    {
        // Report current state
        const char* stateNames[] = {"Sniffer", "Emulator", "Programmer", "Validator", "Debug"};
        char response[64];
        snprintf(response, sizeof(response), "Current State: %s\r\n", stateNames[currentState]);
        USB_SendString(response);
    }
    else
    {
        USB_SendString("ERROR: Unknown command\r\n");
    }
}


static void USB_SendString(const char* str)
{
    CDC_Transmit_FS((uint8_t*)str, strlen(str));
}


static uint16_t GetAddressBusValue(void)
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


static void ReadAddressBus(void)
{
    uint16_t address = GetAddressBusValue();  // Reuse your existing function!

    char binary[18];  // "0000 0000 0000" + space for grouping
    int idx = 0;

    // Format as 13-bit binary with spacing every 4 bits
    // Bits 12-9 (4 bits)
    for (int i = 12; i >= 9; i--)
    {
        binary[idx++] = (address & (1 << i)) ? '1' : '0';
    }
    binary[idx++] = ' ';

    // Bits 8-5 (4 bits)
    for (int i = 8; i >= 5; i--)
    {
        binary[idx++] = (address & (1 << i)) ? '1' : '0';
    }
    binary[idx++] = ' ';

    // Bits 4-1 (4 bits)
    for (int i = 4; i >= 1; i--)
    {
        binary[idx++] = (address & (1 << i)) ? '1' : '0';
    }
    binary[idx++] = ' ';

    // Bit 0 (1 bit)
    binary[idx++] = (address & (1 << 0)) ? '1' : '0';
    binary[idx] = '\0';

    char response[64];
    snprintf(response, sizeof(response), "RDA: %s (%u)\r\n", binary, address);
    USB_SendString(response);
}


static uint8_t GetDataBusValue(void)
{
    // Read data pins from GPIOB and map to actual data value
    uint32_t portB = GPIOB->IDR;
    uint8_t dataValue = 0;

    // Map pins to data bits according to your layout
    if (portB & D1_Pin) dataValue |= (1 << 0);
    if (portB & D2_Pin) dataValue |= (1 << 1);
    if (portB & D3_Pin) dataValue |= (1 << 2);
    if (portB & D4_Pin) dataValue |= (1 << 3);
    if (portB & D5_Pin) dataValue |= (1 << 4);
    if (portB & D6_Pin) dataValue |= (1 << 5);
    if (portB & D7_Pin) dataValue |= (1 << 6);
    if (portB & D8_Pin) dataValue |= (1 << 7);

    return dataValue;
}

static void ReadDataBus(void)
{

    uint8_t dataValue = GetDataBusValue();



    // Format as 8-bit binary
    char binary[12];  // "0000 0000" + null
    int idx = 0;

    // Bits 7-4
    for (int i = 7; i >= 4; i--)
    {
        binary[idx++] = (dataValue & (1 << i)) ? '1' : '0';
    }
    binary[idx++] = ' ';

    // Bits 3-0
    for (int i = 3; i >= 0; i--)
    {
        binary[idx++] = (dataValue & (1 << i)) ? '1' : '0';
    }
    binary[idx] = '\0';

    char response[64];
    snprintf(response, sizeof(response), "RDD: %s (%u/0x%02X)\r\n", binary, dataValue, dataValue);
    USB_SendString(response);
}


static void WriteDataBus(uint8_t value)
{
    // State check - only allow in DEBUG mode
    if (currentState != STATE_DEBUG)
    {
        USB_SendString("ERROR: WDB command only available in Debug mode\r\n");
        return;
    }

    // Write value using the proper pin mapping
    SetDataBusValue(value);  // Reuse your existing function!

    char response[64];
    snprintf(response, sizeof(response), "WDB: Written %u (0x%02X) to data bus\r\n", value, value);
    USB_SendString(response);
}

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


static void SetAddressBusValue(uint16_t address)
{
    // Write to GPIOA (A1-A11)
    uint32_t outputA = GPIOA->ODR;

    // Clear address pins while preserving other pins
    outputA &= ~(A1_Pin | A2_Pin | A3_Pin | A4_Pin | A5_Pin | A6_Pin |
                 A7_Pin | A8_Pin | A9_Pin | A10_Pin | A11_Pin);

    // Map each address bit to its corresponding pin
    if (address & (1 << 0))  outputA |= A1_Pin;
    if (address & (1 << 1))  outputA |= A2_Pin;
    if (address & (1 << 2))  outputA |= A3_Pin;
    if (address & (1 << 3))  outputA |= A4_Pin;
    if (address & (1 << 4))  outputA |= A5_Pin;
    if (address & (1 << 5))  outputA |= A6_Pin;
    if (address & (1 << 6))  outputA |= A7_Pin;
    if (address & (1 << 7))  outputA |= A8_Pin;
    if (address & (1 << 8))  outputA |= A9_Pin;
    if (address & (1 << 9))  outputA |= A10_Pin;
    if (address & (1 << 10)) outputA |= A11_Pin;

    GPIOA->ODR = outputA;

    // Write to GPIOB (A12-A13)
    uint32_t outputB = GPIOB->ODR;

    // Clear A12-A13 while preserving data pins
    outputB &= ~(A12_Pin | A13_Pin);

    if (address & (1 << 11)) outputB |= A12_Pin;
    if (address & (1 << 12)) outputB |= A13_Pin;

    GPIOB->ODR = outputB;
}

// ============================================================================
// PROGRAM ADDRESS COMMAND WITH EEPROM WRITE CYCLE
// ============================================================================

static void ProgramAddress(uint16_t address, uint8_t data)
{
    // State check
    if (currentState != STATE_PROGRAMMER)
    {
        USB_SendString("ERROR: PA command only available in Programmer mode\r\n");
        return;
    }

    // Bounds check
    if (address > 8191)
    {
        USB_SendString("ERROR: Address must be 0-8191\r\n");
        return;
    }

    // Write address and data to buses
    SetAddressBusValue(address);
    SetDataBusValue(data);

    // Use short delays instead of HAL_Delay
    delay_short();  // Small setup time

    // ===== EEPROM WRITE CYCLE =====
    HAL_GPIO_WritePin(CE_STM_GPIO_Port, CE_STM_Pin, GPIO_PIN_RESET);
    delay_short();

    HAL_GPIO_WritePin(WE_STM_GPIO_Port, WE_STM_Pin, GPIO_PIN_RESET);
    delay_short();

    HAL_GPIO_WritePin(WE_STM_GPIO_Port, WE_STM_Pin, GPIO_PIN_SET);
    delay_short();

    HAL_GPIO_WritePin(CE_STM_GPIO_Port, CE_STM_Pin, GPIO_PIN_SET);

    // For the write cycle completion, we might need a longer delay
    // But do it AFTER responding to USB

    HAL_GPIO_TogglePin(Sanity_led_GPIO_Port, Sanity_led_Pin);


    char response[64];
    snprintf(response, sizeof(response), "DB:%u AB: %u\r\n", data, address);
    USB_SendString(response);
}


static inline void delay_short(void)
{
    for (volatile int i = 0; i < 10000; i++);  // ~few microseconds
}

static void ValidateAddress(uint16_t address)
{
    // State check - only allow in VALIDATOR mode
    if (currentState != STATE_VALIDATOR)
    {
        USB_SendString("ERROR: VA command only available in Validator mode\r\n");
        return;
    }

    // Bounds check
    if (address > 8191)
    {
        USB_SendString("ERROR: Address must be 0-8191\r\n");
        return;
    }

    // Set the address on the address bus
    SetAddressBusValue(address);

    // Small delay for address to propagate and EEPROM to respond
    for (volatile int i = 0; i < 100; i++);

    // Read the data from the data bus
    uint8_t data = GetDataBusValue();

    char responseBuffer[64];
    // Send response using static buffer
    snprintf(responseBuffer, sizeof(responseBuffer), "VA: Addr=%u Data=%u (0x%02X)\r\n",
             address, data, data);
    USB_SendString(responseBuffer);
}

/* USER CODE END PRIVATE_FUNCTIONS_IMPLEMENTATION */

/**
  * @}
  */

/**
  * @}
  */
