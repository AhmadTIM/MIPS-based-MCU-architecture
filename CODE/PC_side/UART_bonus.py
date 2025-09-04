import time
import serial as ser

# ---------------- UART Setup ----------------
def init_uart():
    global s
    s = ser.Serial('COM3', baudrate=115200, bytesize=ser.EIGHTBITS,
                   parity=ser.PARITY_NONE, stopbits=ser.STOPBITS_ONE,
                   timeout=1)
    s.reset_input_buffer()
    s.reset_output_buffer()


def Transmit_Char(char):
    global s
    s.write(bytes(char, 'ascii'))
    time.sleep(0.05)


def Recieve_Msg():
    chr = b''
    while chr[-1:] != b'\n':
        chr += s.read(1)
        if chr == b'':
            break
    return chr.decode('ascii')


# ---------------- Menu ----------------
def show_menu():
    print("\n================ MENU ================\n")
    print("1. Count up from 0x00 onto LEDG with delay ~0.5sec")
    print("2. Count down from 0xFF onto LEDR with delay ~0.5sec")
    print("3. Clear all LEDs")
    print('4. On each KEY1 pressed, send the message "I love my Negev"')
    print("5. Show Menu\n")


def main():
    init_uart()
    show_menu()

    while True:
        choice = input("Enter your choice: ").strip().upper()

        if choice == '1':
            Transmit_Char('2')
            print("Counting up from 0x00 onto LEDs...")
        elif choice == '2':
            Transmit_Char('3')
            print("Counting down from 0xFF onto LEDs...")
        elif choice == '3':
            Transmit_Char('1')
            print("Cleared all LEDs")
        elif choice == '4':
            Transmit_Char('4')
            print('Waiting for KEY1 presses to send...')
            try:
                while True:
                    msg = Recieve_Msg()
                    if msg:
                        print(msg, end='')
                    # allow exit by user input
                    if input("Press Enter to continue sending, type X to stop: ").strip().upper() == 'X':
                        break
            except KeyboardInterrupt:
                print("\nStopped listening for KEY1.")
        elif choice == '5':
            show_menu()
        else:
            print("Invalid choice! Try again.")


if __name__ == "__main__":
    main()
