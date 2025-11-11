import tkinter as tk
from tkinter import messagebox, simpledialog
from Gui.RibbonFunctions.Programmer import get_connection_status
import time


def create_programming_interface(parent, colors):
    """
    Create the Programming interface.
    """
    # Main frame
    main_frame = tk.Frame(parent, bg=colors['bg'])
    main_frame.pack(fill='both', expand=True, padx=20, pady=20)

    # Title
    title_label = tk.Label(
        main_frame,
        text="Programming Mode",
        font=('Arial', 14, 'bold'),
        bg=colors['bg'],
        fg=colors['fg']
    )
    title_label.pack(pady=(0, 10))

    # Info label
    info_label = tk.Label(
        main_frame,
        text="ℹ Program external memory",
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
        text="Set to Programming",
        command=lambda: set_mode("PRG", response_label),
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

    # Programming buttons frame
    prog_button_frame = tk.Frame(main_frame, bg=colors['bg'])
    prog_button_frame.pack(pady=20)

    # Program Single Address Button
    prog_single_button = tk.Button(
        prog_button_frame,
        text="Program Single Address",
        command=lambda: program_single_address(response_label),
        bg=colors['bg'],
        fg=colors['fg'],
        font=('Arial', 11, 'bold'),
        padx=25,
        pady=12
    )
    prog_single_button.pack(side='left', padx=10)

    # Program Whole Device Button (placeholder)
    prog_whole_button = tk.Button(
        prog_button_frame,
        text="Program Whole Device",
        command=lambda: program_whole_device(response_label),
        bg=colors['bg'],
        fg=colors['fg'],
        font=('Arial', 11, 'bold'),
        padx=25,
        pady=12
    )
    prog_whole_button.pack(side='left', padx=10)

    return main_frame


def set_mode(mode_code, response_label):
    """
    Send mode command over UART and display response.
    Shows warning for PRG mode before sending.
    """
    is_connected, port, ser = get_connection_status()

    if not is_connected or not ser:
        messagebox.showerror("Not Connected", "Please connect to the programmer first.")
        response_label.config(text="ERROR: Not connected to programmer")
        return

    # Show warning for programming mode
    if mode_code == "PRG":
        result = messagebox.askokcancel(
            "Warning",
            "⚠ Warning: ECF8F24 MUST be disconnected or unpowered for programming!\n\nProceed with programming mode?",
            icon='warning'
        )
        if not result:
            response_label.config(text="Programming mode cancelled by user")
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


def program_single_address(response_label):
    """
    Program a single address with a byte value.
    Prompts user for address and byte, then sends PA;Address;Byte command.
    """
    is_connected, port, ser = get_connection_status()

    if not is_connected or not ser:
        messagebox.showerror("Not Connected", "Please connect to the programmer first.")
        response_label.config(text="ERROR: Not connected to programmer")
        return

    # Create custom dialog for address and byte input
    dialog = tk.Toplevel()
    dialog.title("Program Single Address")
    dialog.geometry("350x200")
    dialog.resizable(False, False)
    dialog.transient()
    dialog.grab_set()

    # Address input
    tk.Label(dialog, text="Address (0-8191):", font=('Arial', 10)).pack(pady=(20, 5))
    address_entry = tk.Entry(dialog, font=('Arial', 11), width=20)
    address_entry.pack(pady=5)
    address_entry.focus()

    # Byte input
    tk.Label(dialog, text="Byte (0-255):", font=('Arial', 10)).pack(pady=(10, 5))
    byte_entry = tk.Entry(dialog, font=('Arial', 11), width=20)
    byte_entry.pack(pady=5)

    result = {'cancelled': True}

    def on_ok():
        try:
            address = int(address_entry.get())
            byte_val = int(byte_entry.get())

            # Validate inputs
            if address < 0 or address > 8191:
                messagebox.showerror("Invalid Address", "Address must be between 0 and 8191")
                return

            if byte_val < 0 or byte_val > 255:
                messagebox.showerror("Invalid Byte", "Byte must be between 0 and 255")
                return

            result['address'] = address
            result['byte'] = byte_val
            result['cancelled'] = False
            dialog.destroy()

        except ValueError:
            messagebox.showerror("Invalid Input", "Please enter valid numbers")

    def on_cancel():
        dialog.destroy()

    # Buttons
    button_frame = tk.Frame(dialog)
    button_frame.pack(pady=20)

    ok_button = tk.Button(button_frame, text="OK", command=on_ok, bg='#28a745', fg='white',
                          font=('Arial', 10, 'bold'), padx=20, pady=5)
    ok_button.pack(side='left', padx=5)

    cancel_button = tk.Button(button_frame, text="Cancel", command=on_cancel,
                              font=('Arial', 10), padx=20, pady=5)
    cancel_button.pack(side='left', padx=5)

    # Wait for dialog to close
    dialog.wait_window()

    if result['cancelled']:
        response_label.config(text="Programming cancelled by user")
        return

    # Send programming command
    address = result['address']
    byte_val = result['byte']

    try:
        # Send PA;Address;Byte
        command = f"PA;{address};{byte_val}\n"
        ser.write(command.encode('ascii'))
        print(f"Sent: PA;{address};{byte_val}")
        response_label.config(text=f"Programming address {address} with byte {byte_val}...")

        # Read response
        response = ser.readline().decode('ascii').strip()
        print(f"Received: {response}")

        # Send SNF
        ser.write(b"SNF\n")
        print("Sent: SNF")
        snf_response = ser.readline().decode('ascii').strip()
        print(f"Received: {snf_response}")

        # Send PRG
        ser.write(b"PRG\n")
        print("Sent: PRG")
        prg_response = ser.readline().decode('ascii').strip()
        print(f"Received: {prg_response}")

        response_label.config(text=f"Complete: {response} | Reset to PRG mode")

    except Exception as e:
        error_msg = f"Communication error: {str(e)}"
        response_label.config(text=error_msg)
        messagebox.showerror("Communication Error", error_msg)
        print(f"Error: {e}")


def program_whole_device(response_label):
    """
    Program the entire device from the .ecfROM file.
    Reads the file line by line and programs each address sequentially.
    """
    is_connected, port, ser = get_connection_status()

    # Check if programmer is connected
    if not is_connected or not ser:
        messagebox.showerror("Not Connected", "Please connect to the programmer first.")
        response_label.config(text="ERROR: Not connected to programmer")
        return

    # Get current project info
    import sys
    ecf_module = sys.modules.get('__main__')

    if ecf_module is None:
        messagebox.showerror("Error", "Could not access project state.")
        return

    current_project_dir = getattr(ecf_module, 'current_project_dir', None)
    current_project_name = getattr(ecf_module, 'current_project_name', None)

    # Check if project is open
    if current_project_dir is None or current_project_name is None:
        messagebox.showerror("No Project", "Please open or create a project first.")
        response_label.config(text="ERROR: No project open")
        return

    # Build path to .ecfROM file
    import os
    rom_file_path = os.path.join(current_project_dir, "Output", f"{current_project_name}.ecfROM")

    # Check if file exists
    if not os.path.exists(rom_file_path):
        messagebox.showerror("File Not Found",
                             f"Could not find ROM file:\n{rom_file_path}\n\nPlease compile the project first.")
        response_label.config(text=f"ERROR: {current_project_name}.ecfROM not found")
        return

    # Confirmation dialog
    result = messagebox.askyesno(
        "Program Whole Device",
        f"Program entire device from:\n{rom_file_path}\n\n⚠ This will overwrite all memory!\n\nContinue?",
        icon='warning'
    )

    if not result:
        response_label.config(text="Programming cancelled by user")
        return

    try:
        # Read ROM file
        with open(rom_file_path, 'r') as f:
            rom_data = f.readlines()

        total_bytes = len(rom_data)
        print(f"Programming {total_bytes} bytes from {rom_file_path}")
        response_label.config(text=f"Programming {total_bytes} bytes...")

        # Program each address
        for address, line in enumerate(rom_data):
            byte_val = int(line.strip())

            # Validate byte
            if byte_val < 0 or byte_val > 255:
                error_msg = f"Invalid byte value {byte_val} at address {address}"
                messagebox.showerror("Invalid Data", error_msg)
                response_label.config(text=error_msg)
                return

            # Send PA command
            command = f"PA;{address};{byte_val}\n"
            ser.write(command.encode('ascii'))

            # Wait for response
            response = ser.readline().decode('ascii').strip()
            time.sleep(0.01)  # 100 microseconds = 0.0001 seconds

            # Update progress every 100 bytes
            if address % 100 == 0:
                response_label.config(
                    text=f"Programming... {address}/{total_bytes} ({int(address / total_bytes * 100)}%)")
                response_label.update()

            print(f"Address {address}: {byte_val} -> {response}")

        # Reset programmer FSM
        response_label.config(text="Programming complete, resetting programmer...")

        # Send SNF
        ser.write(b"SNF\n")
        snf_response = ser.readline().decode('ascii').strip()
        print(f"SNF Response: {snf_response}")

        # Send PRG
        ser.write(b"PRG\n")
        prg_response = ser.readline().decode('ascii').strip()
        print(f"PRG Response: {prg_response}")

        # Success message
        response_label.config(text=f"✓ Successfully programmed {total_bytes} bytes")
        messagebox.showinfo("Success", f"Device programmed successfully!\n\nProgrammed {total_bytes} bytes")
        print(f"Programming complete: {total_bytes} bytes")

    except FileNotFoundError:
        error_msg = f"ROM file not found: {rom_file_path}"
        response_label.config(text=error_msg)
        messagebox.showerror("File Error", error_msg)

    except ValueError as e:
        error_msg = f"Invalid data in ROM file: {str(e)}"
        response_label.config(text=error_msg)
        messagebox.showerror("Data Error", error_msg)

    except Exception as e:
        error_msg = f"Programming error: {str(e)}"
        response_label.config(text=error_msg)
        messagebox.showerror("Programming Error", error_msg)
        print(f"Error: {e}")
