from typing import Optional, List, Dict, Any
from .addresser.org_handler import ORGHandler
from .addresser.db_handler import DBHandler
from .addresser.lbl_handler import LBLHandler


class ECFAddresser:
    """
    ECF Addresser class to handle the addressing/resolution of spaced ASM content
    Separates addressing logic from the main compiler
    """

    def __init__(self, instructions: Dict[int, Dict[str, Any]],
                 write_addresses: Dict[int, Dict[str, Any]],
                 read_addresses: Dict[int, Dict[str, Any]]):
        """
        Initialize the addresser with instruction and address definitions

        Args:
            instructions: Dictionary of instruction definitions from compiler
            write_addresses: Dictionary of write address definitions from compiler
            read_addresses: Dictionary of read address definitions from compiler
        """
        self.instructions = instructions
        self.write_addresses = write_addresses
        self.read_addresses = read_addresses
        self.errors = []

        # Initialize handlers
        self.org_handler = ORGHandler()
        self.db_handler = DBHandler()
        self.lbl_handler = LBLHandler()
        self.lbl_handler = LBLHandler(self.instructions)

    def address_code(self, spaced_content: str) -> Optional[str]:
        """
        Process spaced ASM content and generate addressed code
        Handles DB (Data Byte) line expansion, ORG command validation and addressing

        Args:
            spaced_content: The spaced ASM content from spacer

        Returns:
            Addressed code content as string if successful, None if failed
        """
        try:
            self.errors = []  # Clear previous errors
            self._clear_handler_errors()

            lines = spaced_content.splitlines()

            # First pass: validate ORG commands
            if not self.org_handler.validate_org_commands(lines):
                self._collect_handler_errors()
                return None  # Error occurred in ORG validation

            # Second pass: process lines and handle ORG addressing
            address_counter = 0
            addressed_array = []
            max_address = 0

            for line_num, line in enumerate(lines, 1):
                original_line = line
                line = line.strip()

                # Check if this is an ORG line
                if self.org_handler.is_org_line(line):
                    # Extract ORG address and set counter
                    org_address = self.org_handler.extract_org_address(line)
                    if org_address is not None:
                        address_counter = org_address
                        # ORG lines themselves don't get added to output
                        continue
                    else:
                        # This should have been caught in validation, but just in case
                        self.errors.append(f"Line {line_num}: Invalid ORG address in line '{line}'")
                        return None

                # Handle empty lines
                if not line:
                    # Extend array if needed and add 0
                    self._extend_array_to_address(addressed_array, address_counter)
                    addressed_array[address_counter] = "0"
                    address_counter += 1
                    max_address = max(max_address, address_counter - 1)
                    continue

                # Handle DB (Data Byte) lines
                if self.db_handler.is_db_line(line):
                    processed_bytes = self.db_handler.process_db_line(line, line_num)
                    if processed_bytes is None:
                        self._collect_handler_errors()
                        return None  # Error occurred

                    # Add each byte to the addressed array
                    for byte_value in processed_bytes:
                        self._extend_array_to_address(addressed_array, address_counter)
                        addressed_array[address_counter] = byte_value
                        address_counter += 1
                        max_address = max(max_address, address_counter - 1)
                else:
                    # Regular line - add to array at current address
                    self._extend_array_to_address(addressed_array, address_counter)
                    addressed_array[address_counter] = line
                    address_counter += 1
                    max_address = max(max_address, address_counter - 1)

            # Third pass: Find and process labels from bottom to top
            label_addresses = self.lbl_handler.find_and_process_labels(addressed_array)

            # Check for label processing errors
            if self.lbl_handler.has_errors():
                self._collect_handler_errors()
                return None

            # Print the stored dictionary
            print(f"\n=== LABEL ADDRESSES DICTIONARY ===")
            print(f"Total labels processed: {len(label_addresses)}")
            for label_name, address in label_addresses.items():
                print(f"'{label_name}' -> {address}")
            print("=" * 40)

            # Convert array to output format without address numbers
            result_lines = []
            for i in range(len(addressed_array)):
                result_lines.append(addressed_array[i])

            return '\n'.join(result_lines)

        except Exception as e:
            self.errors.append(f"Error in address_code processing: {e}")
            return None

    def _extend_array_to_address(self, array: List[str], target_address: int) -> None:
        """
        Extend the array with zeros up to the target address if needed

        Args:
            array: The addressed array to extend
            target_address: The address we need to reach
        """
        while len(array) <= target_address:
            array.append("0")

    def _clear_handler_errors(self) -> None:
        """Clear errors from all handlers"""
        self.db_handler.clear_errors()
        self.lbl_handler.clear_errors()
        # ORG handler doesn't have a clear_errors method, errors are cleared in validate_org_commands

    def _collect_handler_errors(self) -> None:
        """Collect errors from all handlers into the main error list"""
        if self.org_handler.has_errors():
            self.errors.extend(self.org_handler.get_errors())

        if self.db_handler.has_errors():
            self.errors.extend(self.db_handler.get_errors())

        if self.lbl_handler.has_errors():
            self.errors.extend(self.lbl_handler.get_errors())

    def get_errors(self) -> List[str]:
        """Return the list of addressing errors"""
        # Always collect current handler errors before returning
        self._collect_handler_errors()
        return self.errors.copy()

    def has_errors(self) -> bool:
        """Check if there are any addressing errors"""
        # Check both main errors and handler errors
        return (len(self.errors) > 0 or
                self.org_handler.has_errors() or
                self.db_handler.has_errors() or
                self.lbl_handler.has_errors())

    def get_org_handler(self) -> ORGHandler:
        """Get the ORG handler instance"""
        return self.org_handler

    def get_db_handler(self) -> DBHandler:
        """Get the DB handler instance"""
        return self.db_handler

    def get_lbl_handler(self) -> LBLHandler:
        """Get the LBL handler instance"""
        return self.lbl_handler