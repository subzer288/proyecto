import pytest
from unittest.mock import Mock, patch, MagicMock, call
import snowflake.connector
from seeder import main, TABLE_NAME


class TestSeeder:
    """Test suite for seeder module"""

    @patch('seeder.snowflake.connector.connect')
    @patch('seeder.get_credentials')
    @patch('seeder.generate_random_name')
    @patch('seeder.random_date')
    @patch('seeder.random.randint')
    @patch('seeder.random.uniform')
    def test_main_creates_table_and_inserts_records(
        self, 
        mock_uniform, 
        mock_randint, 
        mock_random_date, 
        mock_generate_name, 
        mock_get_credentials, 
        mock_connect
    ):
        """Test that main function creates table and inserts 10 records"""
        # Setup mocks
        mock_get_credentials.return_value = {
            'user': 'test_user',
            'password': 'test_pass',
            'account': 'test_account',
            'warehouse': 'test_warehouse',
            'database': 'test_db',
            'schema': 'test_schema',
            'role': 'test_role'
        }
        
        mock_cursor = Mock()
        mock_conn = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_connect.return_value = mock_conn
        
        mock_generate_name.return_value = "John Doe"
        mock_random_date.return_value = "2024-01-15"
        mock_randint.return_value = 123456789
        mock_uniform.return_value = 99.99
        
        # Execute
        main()
        
        # Verify connection was established with credentials
        mock_connect.assert_called_once()
        
        # Verify cursor was created
        mock_conn.cursor.assert_called_once()
        
        # Verify table creation SQL was executed
        assert mock_cursor.execute.call_count == 11  # 1 CREATE + 10 INSERTs
        
        # Verify CREATE TABLE was called
        create_call = mock_cursor.execute.call_args_list[0]
        assert 'CREATE TABLE IF NOT EXISTS' in create_call[0][0]
        assert TABLE_NAME in create_call[0][0]
        
        # Verify 10 INSERT statements were executed
        insert_calls = [call for call in mock_cursor.execute.call_args_list[1:]]
        assert len(insert_calls) == 10
        
        for insert_call in insert_calls:
            assert 'INSERT INTO' in insert_call[0][0]
            assert TABLE_NAME in insert_call[0][0]
        
        # Verify cursor and connection were closed
        mock_cursor.close.assert_called_once()
        mock_conn.close.assert_called_once()

    @patch('seeder.snowflake.connector.connect')
    @patch('seeder.get_credentials')
    def test_main_closes_connection_on_error(self, mock_get_credentials, mock_connect):
        """Test that connection is closed even if an error occurs"""
        mock_get_credentials.return_value = {
            'user': 'test_user',
            'password': 'test_pass',
            'account': 'test_account',
            'warehouse': 'test_warehouse',
            'database': 'test_db',
            'schema': 'test_schema',
            'role': 'test_role'
        }
        
        mock_cursor = Mock()
        mock_cursor.execute.side_effect = Exception("Database error")
        mock_conn = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_connect.return_value = mock_conn
        
        # Execute and expect exception
        with pytest.raises(Exception, match="Database error"):
            main()
        
        # Verify connection was still closed
        mock_conn.close.assert_called_once()

    @patch('seeder.snowflake.connector.connect')
    @patch('seeder.get_credentials')
    def test_main_handles_cursor_not_created(self, mock_get_credentials, mock_connect):
        """Test that main handles case where cursor creation fails"""
        mock_get_credentials.return_value = {
            'user': 'test_user',
            'password': 'test_pass',
            'account': 'test_account',
            'warehouse': 'test_warehouse',
            'database': 'test_db',
            'schema': 'test_schema',
            'role': 'test_role'
        }
        
        mock_conn = Mock()
        mock_conn.cursor.side_effect = Exception("Cursor creation failed")
        mock_connect.return_value = mock_conn
        
        # Execute and expect exception
        with pytest.raises(Exception, match="Cursor creation failed"):
            main()
        
        # Verify connection was still closed (cursor.close should not be called)
        mock_conn.close.assert_called_once()

    @patch('seeder.snowflake.connector.connect')
    @patch('seeder.get_credentials')
    def test_main_validates_credentials(self, mock_get_credentials, mock_connect):
        """Test that main validates required credentials"""
        # Missing 'user' credential
        mock_get_credentials.return_value = {
            'user': None,
            'password': 'test_pass',
            'account': 'test_account',
            'warehouse': 'test_warehouse',
            'database': 'test_db',
            'schema': 'test_schema',
            'role': 'test_role'
        }
        
        # Execute and expect ValueError
        with pytest.raises(ValueError, match="Missing required credential: user"):
            main()
        
        # Connection should not be attempted
        mock_connect.assert_not_called()

    @patch('seeder.snowflake.connector.connect')
    @patch('seeder.get_credentials')
    def test_main_validates_all_required_credentials(self, mock_get_credentials, mock_connect):
        """Test that main validates all required credential fields"""
        required_fields = ['user', 'password', 'account', 'warehouse', 'database', 'schema', 'role']
        
        for field in required_fields:
            # Create credentials dict with one missing field
            credentials: dict[str, str | None] = {
                'user': 'test_user',
                'password': 'test_pass',
                'account': 'test_account',
                'warehouse': 'test_warehouse',
                'database': 'test_db',
                'schema': 'test_schema',
                'role': 'test_role'
            }
            credentials[field] = None
            
            mock_get_credentials.return_value = credentials
            
            # Execute and expect ValueError
            with pytest.raises(ValueError, match=f"Missing required credential: {field}"):
                main()
            
            # Connection should not be attempted
            mock_connect.assert_not_called()

    @patch('seeder.snowflake.connector.connect')
    @patch('seeder.get_credentials')
    @patch('seeder.generate_random_name')
    @patch('seeder.random_date')
    def test_main_generates_unique_records(
        self,
        mock_random_date,
        mock_generate_name,
        mock_get_credentials,
        mock_connect
    ):
        """Test that main generates records with varying data"""
        mock_get_credentials.return_value = {
            'user': 'test_user',
            'password': 'test_pass',
            'account': 'test_account',
            'warehouse': 'test_warehouse',
            'database': 'test_db',
            'schema': 'test_schema',
            'role': 'test_role'
        }
        
        mock_cursor = Mock()
        mock_conn = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_connect.return_value = mock_conn
        
        # Return different names for each call
        mock_generate_name.side_effect = [f"Person{i}" for i in range(10)]
        mock_random_date.return_value = "2024-01-15"
        
        # Execute
        main()
        
        # Verify generate_random_name was called 10 times
        assert mock_generate_name.call_count == 10
        
        # Verify each INSERT has different name
        insert_calls = mock_cursor.execute.call_args_list[1:]  # Skip CREATE TABLE
        for i, insert_call in enumerate(insert_calls):
            assert f"Person{i}" in insert_call[0][0]

# Made with Bob
