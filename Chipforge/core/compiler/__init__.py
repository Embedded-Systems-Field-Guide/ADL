"""
ECF Compiler Package

This package contains helper modules for the ECF compiler:
- parser: ASM file parsing
- spacer: Code spacing and formatting
- addresser: Address resolution and symbolic reference handling
- implementation: Final machine code generation with comments
- file_loader: Generic file loading with validation
- debug_manager: Debug output management
"""

__version__ = "1.0.0"
__author__ = "Your Name"

# You can expose commonly used classes at package level if desired
from .parser import ECFParser
from .spacer import ECFSpacer
from .addresser_main import ECFAddresser
from .implementation import ECFImplementation
from .file_loader import ECFFileLoader, ADDW_SCHEMA, ADDR_SCHEMA, INST_SCHEMA
from .debug_manager import DebugManager

__all__ = [
    'ECFParser',
    'ECFSpacer',
    'ECFAddresser',
    'ECFImplementation',
    'DebugManager',
    'ECFFileLoader',
    'ADDW_SCHEMA',
    'ADDR_SCHEMA',
    'INST_SCHEMA'
]