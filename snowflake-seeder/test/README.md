# Snowflake Seeder Tests

This directory contains pytest tests for the snowflake-seeder project.

## Test Structure

- `test_credentials.py` - Tests for the credentials module
- `test_name_generator.py` - Tests for the name generator module
- `test_date_generator.py` - Tests for the date generator module
- `test_seeder.py` - Tests for the main seeder module
- `conftest.py` - Pytest configuration and shared fixtures
- `__init__.py` - Package initialization

## Running Tests

### Install Dependencies

```bash
cd snowflake-seeder
pip install -r requirements.txt
```

### Run All Tests

```bash
pytest
```

### Run Specific Test File

```bash
pytest test/test_credentials.py
pytest test/test_name_generator.py
pytest test/test_date_generator.py
pytest test/test_seeder.py
```

### Run Specific Test Class or Function

```bash
pytest test/test_credentials.py::TestGetCredentials
pytest test/test_credentials.py::TestGetCredentials::test_get_credentials_with_all_env_vars
```

### Run with Coverage

```bash
pip install pytest-cov
pytest --cov=. --cov-report=html
```

### Run with Verbose Output

```bash
pytest -v
```

### Run Only Fast Tests (exclude slow tests)

```bash
pytest -m "not slow"
```

## Test Coverage

The test suite covers:

- **credentials.py**: Environment variable loading, missing credentials handling
- **name_generator.py**: Random name generation, format validation, data source validation
- **date_generator.py**: Date format, range validation, randomness, edge cases
- **seeder.py**: Database connection, table creation, record insertion, error handling, cleanup

## Writing New Tests

When adding new tests:

1. Follow the naming convention: `test_*.py` for files, `Test*` for classes, `test_*` for functions
2. Use descriptive test names that explain what is being tested
3. Use mocks for external dependencies (database, environment variables)
4. Add docstrings to test classes and methods
5. Group related tests in classes
6. Use pytest fixtures for common setup/teardown

## Mocking Strategy

- **Database connections**: Mock `snowflake.connector.connect`
- **Environment variables**: Use `@patch.dict(os.environ, ...)`
- **Random functions**: Mock `random.choice`, `random.randint`, `random.uniform`
- **Utility functions**: Mock imported functions like `get_credentials()`, `generate_random_name()`

## Notes

- Tests use `unittest.mock` for mocking
- The `conftest.py` file adds the parent directory to the Python path for imports
- Type checking errors in test files (like snowflake.connector imports) are expected when the package isn't installed