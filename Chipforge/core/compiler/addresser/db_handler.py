from typing import List, Optional


class DBHandler:
    """
    Handles DB (Data Byte) line processing and validation
    """

    def __init__(self):
        self.errors = []

    def is_db_line(self, line: str) -> bool:
        """
        Check if a line is a DB (Data Byte) command

        Args:
            line: The line to check

        Returns:
            True if it's a DB line, False otherwise
        """
        return line.strip().upper().startswith('DB ')

    def process_db_line(self, line: str, line_num: int) -> Optional[List[str]]:
        """
        Process a DB (Data Byte) line by expanding it vertically

        Args:
            line: The DB line to process (e.g., "DB 0 36 186 182 116 230 94 164 254 244")
            line_num: Line number for error reporting

        Returns:
            List of individual byte values as strings, or None if error
        """
        try:
            # Remove the "DB " prefix (case insensitive)
            content = line[3:].strip()  # Remove first 3 characters ("DB ")

            if not content:
                self.errors.append(f"Line {line_num}: DB line has no data bytes")
                return None

            # Split by whitespace to get individual byte values
            byte_strings = content.split()
            result_lines = []

            for i, byte_str in enumerate(byte_strings):
                byte_str = byte_str.strip()
                if not byte_str:
                    continue  # Skip empty strings from multiple spaces

                # Validate that each value is a valid byte (0-255)
                try:
                    byte_value = int(byte_str)
                    if byte_value < 0 or byte_value > 255:
                        self.errors.append(f"Line {line_num}: Byte value {byte_value} is out of range (0-255)")
                        return None
                    result_lines.append(str(byte_value))
                except ValueError:
                    self.errors.append(f"Line {line_num}: '{byte_str}' is not a valid integer")
                    return None

            if not result_lines:
                self.errors.append(f"Line {line_num}: No valid byte values found in DB line")
                return None

            return result_lines

        except Exception as e:
            self.errors.append(f"Line {line_num}: Error processing DB line: {e}")
            return None

    def validate_byte_value(self, value_str: str) -> bool:
        """
        Validate if a string represents a valid byte value (0-255)

        Args:
            value_str: The string to validate

        Returns:
            True if valid byte value, False otherwise
        """
        try:
            value = int(value_str)
            return 0 <= value <= 255
        except ValueError:
            return False

    def parse_db_content(self, db_content: str) -> Optional[List[int]]:
        """
        Parse the content part of a DB line into individual byte values

        Args:
            db_content: The content after "DB " (e.g., "0 36 186 182")

        Returns:
            List of byte values as integers, or None if invalid
        """
        try:
            if not db_content.strip():
                return None

            byte_strings = db_content.split()
            byte_values = []

            for byte_str in byte_strings:
                byte_str = byte_str.strip()
                if not byte_str:
                    continue

                if not self.validate_byte_value(byte_str):
                    return None

                byte_values.append(int(byte_str))

            return byte_values if byte_values else None

        except Exception:
            return None

    def get_errors(self) -> List[str]:
        """Return the list of DB processing errors"""
        return self.errors.copy()

    def has_errors(self) -> bool:
        """Check if there are any DB processing errors"""
        return len(self.errors) > 0

    def clear_errors(self) -> None:
        """Clear all accumulated errors"""
        self.errors = []