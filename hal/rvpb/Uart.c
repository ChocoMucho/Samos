#include "stdint.h"
#include "Uart.h"
#include "HalUart.h"

extern volatile PL011_t* Uart;

void Hal_uart_init(void)
{
	// Enable UART
	Uart ->uartcr.bits.UARTEN = 0;
	Uart ->uartcr.bits.TXE = 1;
	Uart ->uartcr.bits.RXE = 1;
	Uart ->uartcr.bits.UARTEN = 1;
}

void Hal_uart_put_char(uint8_t ch)
{
	while(Uart->uartfr.bits.TXFF);
	Uart->uartdr.all = (ch & 0xFF);

}

uint8_t Hal_uart_get_char(void)
{
	uint8_t data;
	while(Uart->uartfr.bits.RXFF);

	//Check for an error flag
	if(Uart->uartdr.bits.BE || Uart->uartdr.bits.FE ||
			Uart->uartdr.bits.OE || Uart->uartdr.bits.PE)
	{
		Uart->uartrsr.bits.BE = 1;
		Uart->uartrsr.bits.FE = 1;
		Uart->uartrsr.bits.OE = 1;
		Uart->uartrsr.bits.PE = 1;
		return 0;
	}

	data = Uart->uartdr.bits.DATA;
	return data;
} 
