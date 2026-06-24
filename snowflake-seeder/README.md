# Snowflake Seeder

A Python utility to seed a Snowflake database with randomly generated customer data for testing and development purposes.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Database Schema](#database-schema)
- [Testing](#testing)
- [Development](#development)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## 🎯 Overview

This tool connects to a Snowflake database and populates a `CUSTOMERS` table with 10 randomly generated customer records. It's designed for:

- **Development environments**: Quickly populate test databases
- **Demo purposes**: Generate realistic sample data
- **Testing**: Validate data pipelines and transformations

## ✨ Features

- ✅ Automatic table creation (if not exists)
- ✅ Generates realistic customer data:
  - Random names (100 first names × 100 last names)
  - Email addresses based on names
  - Social Security Numbers (NSS)
  - Transaction dates (2014-2026)
  - Transaction amounts ($0.00 - $9,999.99)
  - Timestamps
- ✅ Environment-based configuration
- ✅ Comprehensive error handling
- ✅ Full test coverage (34 tests, 100% pass rate)

## 📦 Prerequisites

- **Python**: 3.8 or higher
- **Snowflake Account**: Active account with appropriate permissions
- **Permissions Required**:
  - CREATE TABLE
  - INSERT
  - SELECT (for verification)

## 🚀 Installation

### 1. Clone or Download

```bash
cd snowflake-seeder
```

### 2. Create Virtual Environment (Recommended)

```bash
# Windows
python -m venv .venv
.venv\Scripts\activate

# Linux/Mac
python3 -m venv .venv
source .venv/bin/activate
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

**Dependencies:**
- `snowflake-connector-python` - Snowflake database connector
- `pytest` - Testing framework
- `pytest-mock` - Mocking utilities for tests

## ⚙️ Configuration

The seeder uses environment variables for Snowflake credentials. Set the following variables:

### Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `SNOWFLAKE_USER` | Snowflake username | `john.doe@company.com` |
| `SNOWFLAKE_PASSWORD` | Snowflake password | `SecurePassword123!` |
| `SNOWFLAKE_ACCOUNT` | Snowflake account identifier | `xy12345.us-east-1` |
| `SNOWFLAKE_WAREHOUSE` | Warehouse name | `COMPUTE_WH` |
| `SNOWFLAKE_DATABASE` | Database name | `DEV_DB` |
| `SNOWFLAKE_SCHEMA` | Schema name | `PUBLIC` |
| `SNOWFLAKE_ROLE` | Role name | `DEVELOPER` |

### Setting Environment Variables

**Windows (PowerShell):**
```powershell
$env:SNOWFLAKE_USER="your_username"
$env:SNOWFLAKE_PASSWORD="your_password"
$env:SNOWFLAKE_ACCOUNT="your_account"
$env:SNOWFLAKE_WAREHOUSE="your_warehouse"
$env:SNOWFLAKE_DATABASE="your_database"
$env:SNOWFLAKE_SCHEMA="your_schema"
$env:SNOWFLAKE_ROLE="your_role"
```

**Windows (Command Prompt):**
```cmd
set SNOWFLAKE_USER=your_username
set SNOWFLAKE_PASSWORD=your_password
set SNOWFLAKE_ACCOUNT=your_account
set SNOWFLAKE_WAREHOUSE=your_warehouse
set SNOWFLAKE_DATABASE=your_database
set SNOWFLAKE_SCHEMA=your_schema
set SNOWFLAKE_ROLE=your_role
```

**Linux/Mac:**
```bash
export SNOWFLAKE_USER="your_username"
export SNOWFLAKE_PASSWORD="your_password"
export SNOWFLAKE_ACCOUNT="your_account"
export SNOWFLAKE_WAREHOUSE="your_warehouse"
export SNOWFLAKE_DATABASE="your_database"
export SNOWFLAKE_SCHEMA="your_schema"
export SNOWFLAKE_ROLE="your_role"
```

**Using .env file (Optional):**

Create a `.env` file in the project root:
```env
SNOWFLAKE_USER=your_username
SNOWFLAKE_PASSWORD=your_password
SNOWFLAKE_ACCOUNT=your_account
SNOWFLAKE_WAREHOUSE=your_warehouse
SNOWFLAKE_DATABASE=your_database
SNOWFLAKE_SCHEMA=your_schema
SNOWFLAKE_ROLE=your_role
```

Then load it using `python-dotenv`:
```bash
pip install python-dotenv
```

## 🎮 Usage

### Basic Usage

```bash
python seeder.py
```

### Expected Output

```
Connecting to Snowflake...
Creating table CUSTOMERS if not exists...
Inserting 10 sample records...
Done! 10 records inserted successfully.
```

### Verify Data

Connect to your Snowflake account and run:

```sql
SELECT * FROM CUSTOMERS;
```

## 📁 Project Structure

```
snowflake-seeder/
├── seeder.py              # Main seeder script
├── requirements.txt       # Python dependencies
├── pytest.ini            # Pytest configuration
├── README.md             # This file
├── utils/                # Utility modules
│   ├── __init__.py
│   ├── credentials.py    # Credential management
│   ├── name_generator.py # Random name generation
│   └── date_generator.py # Random date generation
└── test/                 # Test suite
    ├── __init__.py
    ├── conftest.py       # Pytest configuration
    ├── README.md         # Test documentation
    ├── test_credentials.py
    ├── test_name_generator.py
    ├── test_date_generator.py
    └── test_seeder.py
```

## 🗄️ Database Schema

### CUSTOMERS Table

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Auto-generated unique identifier |
| `NAME` | STRING | Customer full name |
| `EMAIL` | STRING | Email address (name@example.com) |
| `NSS` | NUMBER | Social Security Number (1-999999999) |
| `TRANSACTION_DATE` | DATE | Random date between 2014-2026 |
| `AMOUNT` | DECIMAL(6,2) | Transaction amount ($0.00-$9,999.99) |
| `CREATED_AT` | TIMESTAMP_NTZ | Record creation timestamp |

### Sample Data

```sql
id                                   | NAME           | EMAIL                  | NSS       | TRANSACTION_DATE | AMOUNT   | CREATED_AT
-------------------------------------|----------------|------------------------|-----------|------------------|----------|-------------------
550e8400-e29b-41d4-a716-446655440000 | John Smith     | John Smith@example.com | 123456789 | 2020-05-15      | 1234.56  | 2024-01-15 10:30:00
```

## 🧪 Testing

The project includes a comprehensive test suite with 34 tests covering all modules.

### Run All Tests

```bash
pytest
```

### Run with Verbose Output

```bash
pytest -v
```

### Run Specific Test File

```bash
pytest test/test_credentials.py
pytest test/test_name_generator.py
pytest test/test_date_generator.py
pytest test/test_seeder.py
```

### Run with Coverage Report

```bash
pip install pytest-cov
pytest --cov=. --cov-report=html
```

### Test Coverage

- **test_credentials.py** (5 tests): Environment variable handling
- **test_name_generator.py** (11 tests): Name generation and validation
- **test_date_generator.py** (12 tests): Date generation and formatting
- **test_seeder.py** (6 tests): Database operations and error handling

**Current Status**: ✅ 34/34 tests passing (100%)

## 🛠️ Development

### Code Structure

**seeder.py**
- Main entry point
- Handles database connection
- Creates table and inserts records
- Implements proper error handling and cleanup

**utils/credentials.py**
- Loads Snowflake credentials from environment variables
- Returns configuration dictionary

**utils/name_generator.py**
- Contains lists of 100 first names and 100 last names
- Generates random full names

**utils/date_generator.py**
- Generates random dates within specified year range
- Default range: 2014-2026
- Returns dates in YYYY-MM-DD format

### Adding More Records

To insert more than 10 records, modify line 48 in `seeder.py`:

```python
for i in range(100):  # Change from 10 to desired number
```

### Customizing Data

**Change date range:**
```python
# In seeder.py, line 54
"trans_date": random_date(start_year=2020, end_year=2024)
```

**Change amount range:**
```python
# In seeder.py, line 55
"amount": round(random.uniform(100, 5000), 2)  # $100-$5000
```

## 🔧 Troubleshooting

### Common Issues

**1. ModuleNotFoundError: No module named 'snowflake'**
```bash
pip install snowflake-connector-python
```

**2. ValueError: Missing required credential**
- Ensure all environment variables are set
- Check for typos in variable names
- Verify variables are set in current shell session

**3. Connection timeout**
- Verify Snowflake account identifier is correct
- Check network connectivity
- Ensure firewall allows Snowflake connections

**4. Permission denied errors**
- Verify your Snowflake role has CREATE TABLE and INSERT permissions
- Check warehouse is running and accessible

**5. Table already exists with different schema**
```sql
-- Drop and recreate table
DROP TABLE CUSTOMERS;
```

### Debug Mode

Add print statements to see what's happening:

```python
# In seeder.py, after line 17
print(f"Credentials loaded: {credentials}")
```

### Logging

Enable Snowflake connector logging:

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

## 📝 Notes

- The seeder creates the table if it doesn't exist
- Existing data is preserved (no truncation)
- Each run adds 10 new records
- UUIDs are auto-generated by Snowflake
- Timestamps use Snowflake's CURRENT_TIMESTAMP()

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## 📄 License

This project is provided as-is for educational and development purposes.

## 🔗 Related Resources

- [Snowflake Documentation](https://docs.snowflake.com/)
- [Snowflake Python Connector](https://docs.snowflake.com/en/user-guide/python-connector.html)
- [Pytest Documentation](https://docs.pytest.org/)

---

**Made with ❤️ for Snowflake developers**