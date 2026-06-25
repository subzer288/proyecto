import pytest
from unittest.mock import patch
from utils.name_generator import generate_random_name, FIRST_NAMES, LAST_NAMES


class TestGenerateRandomName:
    """Test suite for name_generator module"""

    def test_generate_random_name_returns_string(self):
        """Test that generate_random_name returns a string"""
        name = generate_random_name()
        assert isinstance(name, str)

    def test_generate_random_name_format(self):
        """Test that generated name has correct format (FirstName LastName)"""
        name = generate_random_name()
        parts = name.split()
        
        assert len(parts) == 2, "Name should have exactly 2 parts (first and last)"
        assert parts[0][0].isupper(), "First name should start with uppercase"
        assert parts[1][0].isupper(), "Last name should start with uppercase"

    def test_generate_random_name_uses_valid_first_name(self):
        """Test that generated name uses a valid first name from FIRST_NAMES"""
        name = generate_random_name()
        first_name = name.split()[0]
        assert first_name in FIRST_NAMES

    def test_generate_random_name_uses_valid_last_name(self):
        """Test that generated name uses a valid last name from LAST_NAMES"""
        name = generate_random_name()
        last_name = name.split()[1]
        assert last_name in LAST_NAMES

    def test_generate_random_name_multiple_calls_can_differ(self):
        """Test that multiple calls can generate different names (randomness check)"""
        names = [generate_random_name() for _ in range(50)]
        unique_names = set(names)
        
        # With 100 first names and 100 last names, we should get some variety in 50 calls
        assert len(unique_names) > 1, "Should generate different names across multiple calls"

    @patch('utils.name_generator.random.choice')
    def test_generate_random_name_with_mocked_choice(self, mock_choice):
        """Test that generate_random_name correctly uses random.choice"""
        mock_choice.side_effect = ['John', 'Doe']
        
        name = generate_random_name()
        
        assert name == 'John Doe'
        assert mock_choice.call_count == 2

    def test_first_names_list_not_empty(self):
        """Test that FIRST_NAMES list is not empty"""
        assert len(FIRST_NAMES) > 0

    def test_last_names_list_not_empty(self):
        """Test that LAST_NAMES list is not empty"""
        assert len(LAST_NAMES) > 0

    def test_first_names_all_strings(self):
        """Test that all entries in FIRST_NAMES are strings"""
        assert all(isinstance(name, str) for name in FIRST_NAMES)

    def test_last_names_all_strings(self):
        """Test that all entries in LAST_NAMES are strings"""
        assert all(isinstance(name, str) for name in LAST_NAMES)

    def test_generate_random_name_no_extra_spaces(self):
        """Test that generated name has no extra spaces"""
        name = generate_random_name()
        assert '  ' not in name, "Should not have double spaces"
        assert not name.startswith(' '), "Should not start with space"
        assert not name.endswith(' '), "Should not end with space"

# Made with Bob
