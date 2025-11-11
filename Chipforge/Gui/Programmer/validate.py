import tkinter as tk
from tkinter import messagebox
from Gui.RibbonFunctions.Programmer import get_connection_status
import time


def create_validate_interface(parent, colors):
    """
    Create the Validation interface.
    """
    # Main frame
    main_frame = tk.Frame(parent, bg=colors['bg'])
    main_frame.pack(fill='both', expand=True, padx=20, pady=20)

    # Title
    title_label = tk.Label(
        main_frame,
        text="Validation Mode",
        font=('Arial', 14, 'bold'),
        bg=colors['bg'],
        fg=colors['fg']
    )
    title_label.pack(pady=(0, 10))

    # Info label
    info_label = tk.Label(
        main_frame,
        text="ℹ Validate programmed memory",
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
        text="Set to Validation",
        command=lambda: set_mode("VAL", response_label),
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

    # Validation button frame
    validation_button_frame = tk.Frame(main_frame, bg=colors['bg'])
    validation_button_frame.pack(pady=20)

    # Validate Device Button
    validate_button = tk.Button(
        validation_button_frame,
        text="Validate Device",
        command=lambda: validate_whole_device(response_label),
        bg=colors['bg'],
        fg=colors['fg'],
        font=('Arial', 11, 'bold'),
        padx=30,
        pady=12
    )
    validate_button.pack()

    return main_frame


def set_mode(mode_code, response_label):
    """
    Send mode command over UART and display response.
    Shows warning for VAL mode before sending.
    """
    is_connected, port, ser = get_connection_status()

    if not is_connected or not ser:
        messagebox.showerror("Not Connected", "Please connect to the programmer first.")
        response_label.config(text="ERROR: Not connected to programmer")
        return

    # Show warning for validation mode
    if mode_code == "VAL":
        result = messagebox.askokcancel(
            "Warning",
            "⚠ Warning: FPGA MUST be disconnected to avoid multiple drivers on pins!\n\nProceed with validation mode?",
            icon='warning'
        )
        if not result:
            response_label.config(text="Validation mode cancelled by user")
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


def validate_whole_device(response_label):
    """
    Validate the entire device against the .ecfROM file.
    Reads each address from the device using VA command and compares with the ROM file.
    Stops on first mismatch and reports the error.
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

    # Confirmation dialog with FPGA warning
    result = messagebox.askyesno(
        "Validate Device",
        f"Validate device against:\n{rom_file_path}\n\n⚠ ENSURE FPGA IS DISCONNECTED!\n\nContinue?",
        icon='warning'
    )

    if not result:
        response_label.config(text="Validation cancelled by user")
        return

    try:
        # Read ROM file
        with open(rom_file_path, 'r') as f:
            rom_data = f.readlines()

        total_bytes = len(rom_data)
        print(f"Validating {total_bytes} bytes from {rom_file_path}")
        response_label.config(text=f"Validating {total_bytes} bytes...")

        mismatches = []

        # Validate each address
        for address, line in enumerate(rom_data):
            expected_byte = int(line.strip())

            # Validate expected byte
            if expected_byte < 0 or expected_byte > 255:
                error_msg = f"Invalid byte value {expected_byte} in ROM file at address {address}"
                messagebox.showerror("Invalid Data", error_msg)
                response_label.config(text=error_msg)
                return

            # Send VA command to read address
            command = f"VA;{address}\n"
            ser.write(command.encode('ascii'))

            # Wait for response
            response = ser.readline().decode('ascii').strip()
            time.sleep(0.01)  # Small delay between reads

            # Parse the response - format: "VA: Addr=2 Data=255 (0xFF)"
            try:
                # Extract the Data value from the response
                if "Data=" in response:
                    # Split by "Data=" and take the part after it
                    data_part = response.split("Data=")[1]
                    # Split by space and take first part (the decimal value)
                    actual_byte = int(data_part.split()[0])
                else:
                    raise ValueError(f"Unexpected response format: {response}")
            except (ValueError, IndexError) as e:
                error_msg = f"Invalid response at address {address}: {response}"
                messagebox.showerror("Validation Error", error_msg)
                response_label.config(text=error_msg)
                print(f"Parse error: {e}")
                return

            # Compare values
            if actual_byte != expected_byte:
                mismatch_msg = f"MISMATCH at address {address}: Expected {expected_byte}, Got {actual_byte}"
                print(mismatch_msg)
                response_label.config(text=mismatch_msg)

                # Show detailed error and stop validation
                messagebox.showerror(
                    "Validation Failed",
                    f"Memory validation failed!\n\n"
                    f"Address: {address}\n"
                    f"Expected: {expected_byte} (0x{expected_byte:02X})\n"
                    f"Actual: {actual_byte} (0x{actual_byte:02X})\n\n"
                    f"Validation stopped at first mismatch."
                )
                return

            # Update progress every 100 bytes
            if address % 100 == 0:
                response_label.config(
                    text=f"Validating... {address}/{total_bytes} ({int(address / total_bytes * 100)}%)")
                response_label.update()

            print(f"Address {address}: Expected {expected_byte}, Got {actual_byte} ✓")

        # All addresses matched - success!
        response_label.config(text=f"✓ Validation successful! All {total_bytes} bytes verified")
        messagebox.showinfo(
            "Validation Successful",
            f"Device validation completed successfully!\n\n"
            f"Verified {total_bytes} bytes\n"
            f"All values match the ROM file."
        )
        print(f"Validation complete: {total_bytes} bytes verified successfully")

    except FileNotFoundError:
        error_msg = f"ROM file not found: {rom_file_path}"
        response_label.config(text=error_msg)
        messagebox.showerror("File Error", error_msg)

    except ValueError as e:
        error_msg = f"Invalid data in ROM file: {str(e)}"
        response_label.config(text=error_msg)
        messagebox.showerror("Data Error", error_msg)

    except Exception as e:
        error_msg = f"Validation error: {str(e)}"
        response_label.config(text=error_msg)
        messagebox.showerror("Validation Error", error_msg)
        print(f"Error: {e}")