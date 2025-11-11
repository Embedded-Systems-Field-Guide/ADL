import tkinter as tk
from tkinter import ttk, messagebox
import serial
import serial.tools.list_ports

# Connection state
is_connected = False
current_port = None
serial_connection = None


def on_programmer_click():
    """
    Handle programmer button click - connect or disconnect.
    """
    global is_connected

    if is_connected:
        disconnect_programmer()
    else:
        show_connection_dialog()


def show_connection_dialog():
    """
    Show dialog to select and connect to programmer.
    """
    dialog = tk.Toplevel()
    dialog.title("Connect to Programmer")
    dialog.geometry("500x350")
    dialog.resizable(False, False)

    # Make dialog modal
    dialog.transient()
    dialog.grab_set()

    # Main frame
    main_frame = tk.Frame(dialog, padx=20, pady=20)
    main_frame.pack(fill='both', expand=True)

    # Title
    title_label = tk.Label(main_frame, text="Select Programmer Port", font=('Arial', 12, 'bold'))
    title_label.pack(pady=(0, 10))

    # Auto-detect section
    detect_frame = tk.LabelFrame(main_frame, text="Auto-Detect", padx=10, pady=10)
    detect_frame.pack(fill='x', pady=(0, 10))

    detect_status = tk.Label(detect_frame, text="Click 'Scan' to search for ECF_PRG device", fg='gray')
    detect_status.pack(pady=5)

    def scan_for_programmer():
        detect_status.config(text="Scanning...", fg='blue')
        dialog.update()

        # Get all ports for debugging
        all_ports = serial.tools.list_ports.comports()
        # print("\n=== COM Port Scan Debug ===")
        # print(f"Found {len(all_ports)} total COM ports:")
        # for port in all_ports:
        #     print(f"\nPort: {port.device}")
        #     print(f"  Description: {port.description}")
        #     print(f"  Manufacturer: {port.manufacturer}")
        #     print(f"  Product: {port.product}")
        #     print(f"  VID: {port.vid}")
        #     print(f"  PID: {port.pid}")
        #     print(f"  Serial Number: {port.serial_number}")
        # print("========================\n")

        ecf_ports = find_ecf_programmer()

        if ecf_ports:
            port_list.delete(0, tk.END)
            for port_info in ecf_ports:
                port_list.insert(tk.END, f"{port_info['port']} - {port_info['description']}")
            port_list.selection_set(0)
            detect_status.config(text=f"Found {len(ecf_ports)} ECF_PRG device(s)", fg='green')
            print(f"Found {len(ecf_ports)} ECF_PRG devices")
        else:
            detect_status.config(text="No ECF_PRG devices found", fg='red')
            print("No ECF_PRG devices found - check debug output above")

    scan_btn = tk.Button(detect_frame, text="Scan for ECF_PRG", command=scan_for_programmer,
                         bg='#0078d4', fg='white', padx=20, pady=5)
    scan_btn.pack()

    # Manual selection section
    manual_frame = tk.LabelFrame(main_frame, text="Manual Selection", padx=10, pady=10)
    manual_frame.pack(fill='both', expand=True, pady=(0, 10))

    # Port list with scrollbar
    list_frame = tk.Frame(manual_frame)
    list_frame.pack(fill='both', expand=True)

    scrollbar = tk.Scrollbar(list_frame)
    scrollbar.pack(side='right', fill='y')

    port_list = tk.Listbox(list_frame, yscrollcommand=scrollbar.set, height=8)
    port_list.pack(side='left', fill='both', expand=True)
    scrollbar.config(command=port_list.yview)

    # Bind double-click to connect
    def on_port_double_click(event):
        connect_selected()

    port_list.bind('<Double-Button-1>', on_port_double_click)

    # Populate with all available ports
    def refresh_ports():
        port_list.delete(0, tk.END)
        ports = serial.tools.list_ports.comports()
        for port in ports:
            port_list.insert(tk.END, f"{port.device} - {port.description}")
        if ports:
            port_list.selection_set(0)

    refresh_btn = tk.Button(manual_frame, text="Refresh List", command=refresh_ports, padx=10, pady=3)
    refresh_btn.pack(pady=(5, 0))

    # Initial port population
    refresh_ports()

    # Connect button
    def connect_selected():
        selection = port_list.curselection()
        if not selection:
            messagebox.showwarning("No Selection", "Please select a COM port")
            return

        port_text = port_list.get(selection[0])
        port_name = port_text.split(' - ')[0]

        if connect_programmer(port_name):
            dialog.destroy()

    button_frame = tk.Frame(main_frame)
    button_frame.pack(fill='x')

    connect_btn = tk.Button(button_frame, text="Connect", command=connect_selected,
                            bg='#28a745', fg='white', padx=30, pady=8, font=('Arial', 10, 'bold'))
    connect_btn.pack(side='left', padx=(0, 5))

    cancel_btn = tk.Button(button_frame, text="Cancel", command=dialog.destroy,
                           padx=30, pady=8)
    cancel_btn.pack(side='left')


def find_ecf_programmer():
    """
    Scan for COM ports with 'ECF_PRG' in the product string, or STM32 by VID/PID.
    VID: 0x0483 (1155 decimal) - STMicroelectronics
    PID: 0x5740 (22336 decimal) - STM32 Virtual COM Port
    Returns list of matching ports.
    """
    ecf_ports = []
    ports = serial.tools.list_ports.comports()

    # STM32 identifiers
    STM32_VID = 0x0483  # 1155 decimal
    STM32_PID = 0x5740  # 22336 decimal

    print("\n=== Searching for ECF_PRG / STM32 Programmer ===")
    for port in ports:
        print(f"Checking {port.device}:")
        print(f"  VID: {port.vid} (0x{port.vid:04X} if port.vid else 'None')")
        print(f"  PID: {port.pid} (0x{port.pid:04X} if port.pid else 'None')")
        print(f"  Product: '{port.product}'")
        print(f"  Description: '{port.description}'")

        match_found = False
        match_reason = ""

        # Check for ECF_PRG in product string
        if port.product and 'ECF_PRG' in port.product.upper():
            match_found = True
            match_reason = "Product string contains ECF_PRG"
        # Check for ECF_PRG in description
        elif 'ECF_PRG' in port.description.upper():
            match_found = True
            match_reason = "Description contains ECF_PRG"
        # Check for STM32 VID/PID
        elif port.vid == STM32_VID and port.pid == STM32_PID:
            match_found = True
            match_reason = "STM32 VID/PID match (0x0483:0x5740)"

        if match_found:
            print(f"  -> MATCH: {match_reason}")
            ecf_ports.append({
                'port': port.device,
                'description': f"{port.description} [{match_reason}]",
                'product': port.product if port.product else 'STM32 Device'
            })
        else:
            print(f"  -> No match")

    print(f"=== Found {len(ecf_ports)} programmer device(s) ===\n")
    return ecf_ports


def connect_programmer(port_name):
    """
    Attempt to connect to the programmer on the specified port.
    """
    global is_connected, current_port, serial_connection

    try:
        # Attempt to open serial connection
        serial_connection = serial.Serial(
            port=port_name,
            baudrate=115200,
            timeout=1
        )

        # Connection successful
        is_connected = True
        current_port = port_name

        # Update button appearance
        update_programmer_button()

        messagebox.showinfo("Connected", f"Successfully connected to programmer on {port_name}")
        print(f"Connected to programmer: {port_name}")
        return True

    except serial.SerialException as e:
        messagebox.showerror("Connection Failed", f"Failed to connect to {port_name}\n\n{str(e)}")
        print(f"Connection failed: {e}")
        return False


def disconnect_programmer():
    """
    Disconnect from the programmer.
    """
    global is_connected, current_port, serial_connection

    if serial_connection and serial_connection.is_open:
        serial_connection.close()

    port_name = current_port
    is_connected = False
    current_port = None
    serial_connection = None

    # Update button appearance
    update_programmer_button()

    messagebox.showinfo("Disconnected", f"Disconnected from programmer on {port_name}")
    print(f"Disconnected from programmer: {port_name}")


def update_programmer_button():
    """
    Update the programmer button text and color based on connection state.
    """
    from Gui.Ribbon import get_programmer_button
    from Gui.Tabs import get_theme_colors, detect_windows_theme

    button = get_programmer_button()
    if button:
        if is_connected:
            button.config(text='Disconnect from Programmer', bg='#dc3545', fg='white',
                          activebackground='#c82333', activeforeground='white')
        else:
            # Get current theme colors
            is_dark = detect_windows_theme()
            colors = get_theme_colors(is_dark)
            button.config(text='Connect to Programmer', bg=colors['tab_bg'], fg=colors['fg'],
                          activebackground=colors['tab_selected'], activeforeground=colors['fg'])


def get_connection_status():
    """
    Get current connection status.
    Returns: (is_connected, port_name, serial_connection)
    """
    return is_connected, current_port, serial_connection