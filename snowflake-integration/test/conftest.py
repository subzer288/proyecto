"""
Pytest configuration file for snowflake-seeder tests.
This file contains shared fixtures and configuration for all tests.
"""

import sys
from pathlib import Path

# Add parent directory to path so tests can import from utils and main modules
sys.path.insert(0, str(Path(__file__).parent.parent))

# Made with Bob
