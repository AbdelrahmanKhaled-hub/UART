# UART
UART with FIFOs and Baud Rate Generator
Overview
This Universal Asynchronous Receiver/Transmitter (UART) design provides reliable serial communication with built-in TX (transmitter) and RX (receiver) modules, FIFO buffers for data storage, and a baud rate generator for flexible speed configuration. It is suitable for embedded systems, SoCs, and FPGA designs.

Features
UART Transmitter (TX):

Sends serial data frames (start bit, data bits, optional parity, stop bit(s)).

Uses a TX FIFO to store outgoing data and ensure smooth transmission.

Automatically pulls data from FIFO and shifts out serially.

UART Receiver (RX):

Receives serial data frames, detects start bit, samples data bits at the configured baud rate.

Uses an RX FIFO to store incoming data for later reading.

Includes error detection:

Parity Error (PE) – Wrong parity bit detected.

Framing Error (FE) – Missing or invalid stop bit.

Overrun Error (OE) – FIFO overflow.

Baud Rate Generator:

Generates the sampling clock based on the desired baud rate.

Configurable divisor to support various baud rates (e.g., 9600, 115200).

Ensures synchronized data sampling.
