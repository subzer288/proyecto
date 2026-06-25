import pytest
import os
from unittest.mock import patch
from utils.credentials import get_credentials


class TestGetCredentials:
    """Test suite for credentials module"""

    @patch.dict(os.environ, {
        'SNOWFLAKE_USER': 'test_user',
        'SNOWFLAKE_PASSWORD': 'test_password',
        'SNOWFLAKE_ACCOUNT': 'test_account',
        'SNOWFLAKE_WAREHOUSE': 'test_warehouse',
        'SNOWFLAKE_DATABASE': 'test_database',
        'SNOWFLAKE_SCHEMA': 'test_schema',
        'SNOWFLAKE_ROLE': 'test_role'
    })
    def test_get_credentials_with_all_env_vars(self):
        """Test that get_credentials returns correct dict when all env vars are set"""
        credentials = get_credentials()
        
        assert credentials['user'] == 'test_user'
        assert credentials['password'] == 'test_password'
        assert credentials['account'] == 'test_account'
        assert credentials['warehouse'] == 'test_warehouse'
        assert credentials['database'] == 'test_database'
        assert credentials['schema'] == 'test_schema'
        assert credentials['role'] == 'test_role'

    @patch.dict(os.environ, {}, clear=True)
    def test_get_credentials_with_no_env_vars(self):
        """Test that get_credentials returns None values when env vars are not set"""
        credentials = get_credentials()
        
        assert credentials['user'] is None
        assert credentials['password'] is None
        assert credentials['account'] is None
        assert credentials['warehouse'] is None
        assert credentials['database'] is None
        assert credentials['schema'] is None
        assert credentials['role'] is None

    @patch.dict(os.environ, {
        'SNOWFLAKE_USER': 'partial_user',
        'SNOWFLAKE_PASSWORD': 'partial_password'
    }, clear=True)
    def test_get_credentials_with_partial_env_vars(self):
        """Test that get_credentials returns mixed values when only some env vars are set"""
        credentials = get_credentials()
        
        assert credentials['user'] == 'partial_user'
        assert credentials['password'] == 'partial_password'
        assert credentials['account'] is None
        assert credentials['warehouse'] is None
        assert credentials['database'] is None
        assert credentials['schema'] is None
        assert credentials['role'] is None

    def test_get_credentials_returns_dict(self):
        """Test that get_credentials always returns a dictionary"""
        credentials = get_credentials()
        assert isinstance(credentials, dict)

    def test_get_credentials_has_all_required_keys(self):
        """Test that get_credentials returns dict with all required keys"""
        credentials = get_credentials()
        required_keys = ['user', 'password', 'account', 'warehouse', 'database', 'schema', 'role']
        
        for key in required_keys:
            assert key in credentials

# Made with Bob
