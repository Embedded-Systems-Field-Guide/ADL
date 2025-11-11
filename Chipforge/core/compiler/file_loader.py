from pathlib import Path
from typing import Dict, List, Callable, Any, Optional
from dataclasses import dataclass


@dataclass
class FileSchema:
    """Defines the expected structure of a file"""
    name: str
    required_fields: int
    field_names: List[str]
    field_types: List[type]
    validator: Optional[Callable] = None


class ECFFileLoader:
    """
    Generic file loader for ECF address and instruction files
    Handles validation, duplicate checking, and data loading
    """

    def __init__(self):
        self.errors = []

    def load_tabbed_file(self, file_path: Path, schema: FileSchema) -> Dict[int, Dict[str, Any]]:
        """
        Load a tab-separated file with validation

        Args:
            file_path: Path to the file
            schema: FileSchema defining the file structure

        Returns:
            Dictionary keyed by address with data dictionaries
        """
        self.errors = []

        if not file_path.exists():
            self.errors.append(f"{schema.name} file not found: {file_path}")
            return {}

        seen_addresses = set()
        seen_names = set()
        line_num = 0
        data = {}

        try:
            with open(file_path, 'r') as f:
                for line in f:
                    line_num += 1
                    line = line.strip()
                    if not line:
                        continue

                    if not self._validate_line(line, line_num, schema, seen_addresses, seen_names):
                        continue

                    parts = line.split('\t')
                    address = int(parts[0])

                    # Build data dictionary based on schema
                    entry = {}
                    for i, field_name in enumerate(schema.field_names):
                        if i == 0:
                            # First field is always the address (already converted to int)
                            entry[field_name] = address
                        elif i < len(parts):
                            value = parts[i]
                            # Convert to appropriate type
                            if schema.field_types[i] == int:
                                try:
                                    value = int(value)
                                except ValueError:
                                    self.errors.append(f"{schema.name} Line {line_num}: Invalid {field_name} '{value}'")
                                    continue
                            entry[field_name] = value
                        else:
                            # Optional field, use empty string or default
                            entry[field_name] = "" if schema.field_types[i] == str else 0

                    # Custom validation if provided
                    if schema.validator and not schema.validator(entry, line_num, self.errors):
                        continue

                    seen_addresses.add(address)
                    if 'name' in entry:
                        seen_names.add(entry['name'])
                    data[address] = entry

        except Exception as e:
            self.errors.append(f"Error loading {schema.name} file: {e}")

        return data

    def _validate_line(self, line: str, line_num: int, schema: FileSchema,
                       seen_addresses: set, seen_names: set) -> bool:
        """Validate a single line from the file"""
        parts = line.split('\t')

        if len(parts) < schema.required_fields:
            self.errors.append(f"{schema.name} Line {line_num}: Incomplete line - missing required fields")
            return False

        try:
            address = int(parts[0])
        except ValueError:
            self.errors.append(f"{schema.name} Line {line_num}: Invalid address '{parts[0]}'")
            return False

        # Check for reserved address 0
        if address == 0:
            self.errors.append(f"{schema.name} Line {line_num}: Address 0 is reserved and cannot be used")
            return False

        # Check for duplicate addresses
        if address in seen_addresses:
            self.errors.append(f"{schema.name} Line {line_num}: Duplicate address {address}")
            return False

        # Check for duplicate names (if name field exists)
        if len(parts) > 1 and parts[1] in seen_names:
            self.errors.append(f"{schema.name} Line {line_num}: Duplicate name '{parts[1]}'")
            return False

        return True

    def get_errors(self) -> List[str]:
        """Get list of validation errors"""
        return self.errors.copy()

    def has_errors(self) -> bool:
        """Check if there are validation errors"""
        return len(self.errors) > 0


# Predefined schemas for ECF files
def instruction_validator(entry: Dict[str, Any], line_num: int, errors: List[str]) -> bool:
    """Custom validator for instruction entries"""
    # Additional validation logic for instructions can go here
    return True


ADDW_SCHEMA = FileSchema(
    name="ADDW",
    required_fields=2,
    field_names=['address', 'name', 'description'],
    field_types=[int, str, str]
)

ADDR_SCHEMA = FileSchema(
    name="ADDR",
    required_fields=2,
    field_names=['address', 'name', 'description'],
    field_types=[int, str, str]
)

INST_SCHEMA = FileSchema(
    name="INST",
    required_fields=5,
    field_names=['address', 'name', 'length', 'leading_nops', 'format', 'description'],
    field_types=[int, str, int, int, str, str],
    validator=instruction_validator
)