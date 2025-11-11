import tkinter as tk
from tkinter import messagebox
from Gui.RibbonFunctions.Programmer import get_connection_status


def create_emulate_interface(parent, colors):
    """
    Create the Emulation interface.
    """
    # Main frame
    main_frame = tk.Frame(parent, bg=colors['bg'])
    main_frame.pack(fill='both', expand=True, padx=20, pady=20)

    # Title
    title_label = tk.Label(
        main_frame,
        text="Emulation Mode",
        font=('Arial', 14, 'bold'),
        bg=colors['bg'],
        fg=colors['fg']
    )
    title_label.pack(pady=(0, 10))

    # Info label
    info_label = tk.Label(
        main_frame,
        text="ℹ Emulate requires rom_data.h to be programmed onto programmer\nand can only emulate this fixed value",
        font=('Arial', 10, 'italic'),
        bg=colors['bg'],
        fg=colors['fg'],
        wraplength=600,
        justify='center'
    )
    info_label.pack(pady=(0, 20))

    # Buttons frame
    button_frame = tk.Frame(main_frame, bg=colors['bg'])
    button_frame.pack(pady=10)

    # Set Mode Button
    set_button = tk.Button(
        button_frame,
        text="Set to Emulation",
        command=lambda: set_mode("EMU", response_label),
        bg=colors['bg'],
        fg=colors['fg'],
        font=('Arial', 12, 'bold'),
        padx=30,
        pady=15
    )
    set_button.pack(side='left', padx=5)

    # Read Address Bus Button
    read_addr_button = tk.Button(
        button_frame,
        text="Read Address Bus",
        command=lambda: read_bus("RDA", response_label),
        bg=colors['bg'],
        fg=colors['fg'],
        font=('Arial', 11),
        padx=20,
        pady=15
    )
    read_addr_button.pack(side='left', padx=5)

    # Read Data Bus Button
    read_data_button = tk.Button(
        button_frame,
        text="Read Data Bus",
        command=lambda: read_bus("RDD", response_label),
        bg=colors['bg'],
        fg=colors['fg'],
        font=('Arial', 11),
        padx=20,
        pady=15
    )
    read_data_button.pack(side='left', padx=5)

    # Response display
    response_frame = tk.LabelFrame(
        main_frame,
        text="Device Response",
        bg=colors['bg'],
        fg=colors['fg'],
        font=('Arial', 10)
    )
    response_frame.pack(fill='x', pady=20)

    response_label = tk.Label(
        response_frame,
        text="No response yet",
        bg=colors['input_bg'],
        fg=colors['input_fg'],
        font=('Consolas', 11),
        anchor='w',
        padx=10,
        pady=10,
        relief='sunken'
    )
    response_label.pack(fill='x', padx=10, pady=10)

    return main_frame


def set_mode(mode_code, response_label):
    """
    Send mode command over UART and display response.
    Shows warning for EMU mode before sending.
    """
    is_connected, port, ser = get_connection_status()

    if not is_connected or not ser:
        messagebox.showerror("Not Connected", "Please connect to the programmer first.")
        response_label.config(text="ERROR: Not connected to programmer")
        return

    # Show warning for emulation mode
    if mode_code == "EMU":
        result = messagebox.askokcancel(
            "Warning",
            "⚠ Warning: External EEPROM MUST be in High-Z state!\n\nProceed with emulation mode?",
            icon='warning'
        )
        if not result:
            response_label.config(text="Emulation mode cancelled by user")
            return

    try:
        # Send command with newline
        command = f"{mode_code}\n"
        ser.write(command.encode('ascii'))
        print(f"Sent: {mode_code}")

        # Read response (with timeout handled by serial settings)
        response = ser.readline().decode('ascii').strip()

        if response:
            response_label.config(text=f"Response: {response}")
            print(f"Received: {response}")
        else:
            response_label.config(text="No response received (timeout)")
            print("No response received")

    except Exception as e:
        error_msg = f"Communication error: {str(e)}"
        response_label.config(text=error_msg)
        messagebox.showerror("Communication Error", error_msg)
        print(f"Error: {e}")


def read_bus(bus_command, response_label):
    """
    Read Address Bus (RDA) or Data Bus (RDD) and display response.
    Expected format:
    - RDA: 0000 0000 0000 0 (0)
    - RDD: 1111 1111 (255/0xFF)
    """
    is_connected, port, ser = get_connection_status()

    if not is_connected or not ser:
        messagebox.showerror("Not Connected", "Please connect to the programmer first.")
        response_label.config(text="ERROR: Not connected to programmer")
        return

    try:
        # Send command with newline
        command = f"{bus_command}\n"
        ser.write(command.encode('ascii'))
        print(f"Sent: {bus_command}")

        # Read response
        response = ser.readline().decode('ascii').strip()

        if response:
            response_label.config(text=response)
            print(f"Received: {response}")
        else:
            response_label.config(text="No response received (timeout)")
            print("No response received")

    except Exception as e:
        error_msg = f"Communication error: {str(e)}"
        response_label.config(text=error_msg)
        messagebox.showerror("Communication Error", error_msg)
        print(f"Error: {e}")