import re
from pathlib import Path
from typing import Optional


class ECFParser:
    def __init__(self):
        self.errors = []

    def parse_asm_file(self, asm_file_path: str) -> Optional[str]:
        """
        Parse ECF ASM file and return cleaned content

        Args:
            asm_file_path: Path to the .ecfASM file

        Returns:
            Cleaned file content as string if successful, None if failed
        """
        try:
            self.errors = []

            asm_path = Path(asm_file_path)
            if not asm_path.exists():
                self.errors.append(f"ASM file not found: {asm_file_path}")
                return None

            # Read and clean the file content
            with open(asm_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()

            cleaned_lines = []
            for line_num, line in enumerate(lines, 1):
                # Remove comments (everything after //)
                if '//' in line:
                    line = line[:line.index('//')]

                # Strip whitespace and normalize spaces
                line = self._normalize_whitespace(line)

                # Skip empty lines
                if not line.strip():
                    continue

                # Convert number formats to base 10
                try:
                    line = self._convert_numbers_to_base10(line, line_num)
                except ValueError as e:
                    self.errors.append(f"Line {line_num}: {e}")
                    return None

                cleaned_lines.append(line)

            content = '\n'.join(cleaned_lines)
            print(f"Successfully parsed ASM file: {asm_file_path}")
            print(f"Processed {len(lines)} -> {len(cleaned_lines)} lines")
            return content

        except Exception as e:
            self.errors.append(f"Error parsing ASM file: {e}")
            return None

    def _normalize_whitespace(self, line: str) -> str:
        """
        Remove tabs, multiple spaces, leading spaces, and trailing spaces

        Args:
            line: Input line

        Returns:
            Normalized line
        """
        # Replace tabs with single space
        line = line.replace('\t', ' ')

        # Replace multiple spaces with single space
        line = re.sub(r' +', ' ', line)

        # Remove leading and trailing whitespace
        line = line.strip()

        return line

    def _convert_numbers_to_base10(self, line: str, line_num: int) -> str:
        """
        Convert all number formats (binary, hex, etc.) to base 10

        Args:
            line: Input line
            line_num: Line number for error reporting

        Returns:
            Line with numbers converted to base 10

        Raises:
            ValueError: If invalid number format found
        """
        # Pattern to match various number formats
        # Matches: 0x1A, 0X1a, 0b1010, 0B1010, regular integers
        number_pattern = r'\b(?:0[xX][0-9a-fA-F]+|0[bB][01]+|\d+(?:\.\d+)?)\b'

        def convert_match(match):
            num_str = match.group(0)

            try:
                # Check for decimal numbers (invalid)
                if '.' in num_str:
                    raise ValueError(f"Decimal numbers not supported: '{num_str}'")

                # Convert based on prefix
                if num_str.lower().startswith('0x'):
                    # Hexadecimal
                    return str(int(num_str, 16))
                elif num_str.lower().startswith('0b'):
                    # Binary
                    return str(int(num_str, 2))
                else:
                    # Already decimal, but validate it's a valid integer
                    int(num_str)  # This will raise ValueError if invalid
                    return num_str

            except ValueError as e:
                if "Decimal numbers not supported" in str(e):
                    raise e
                else:
                    raise ValueError(f"Invalid number format: '{num_str}'")

        try:
            return re.sub(number_pattern, convert_match, line)
        except ValueError as e:
            raise ValueError(str(e))

    def get_errors(self) -> list:
        """Return the list of parsing errors"""
        return self.errors.copy()

    def has_errors(self) -> bool:
        """Check if there are any parsing errors"""
        return len(self.errors) > 0

    def print_errors(self):
        """Print all parsing errors"""
        if self.errors:
            print(f"\n=== PARSER ERRORS ({len(self.errors)} found) ===")
            for i, error in enumerate(self.errors, 1):
                print(f"{i}. {error}")
        else:
            print("No parser errors found.")