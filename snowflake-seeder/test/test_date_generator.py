import pytest
from datetime import datetime
from unittest.mock import patch
from utils.date_generator import random_date


class TestRandomDate:
    """Test suite for date_generator module"""

    def test_random_date_returns_string(self):
        """Test that random_date returns a string"""
        date = random_date()
        assert isinstance(date, str)

    def test_random_date_format(self):
        """Test that random_date returns date in YYYY-MM-DD format"""
        date = random_date()
        
        # Should be able to parse the date
        try:
            parsed = datetime.strptime(date, "%Y-%m-%d")
            assert True
        except ValueError:
            pytest.fail(f"Date '{date}' is not in YYYY-MM-DD format")

    def test_random_date_default_range(self):
        """Test that random_date with default params returns date between 2014 and 2026"""
        date = random_date()
        parsed = datetime.strptime(date, "%Y-%m-%d")
        
        assert parsed.year >= 2014
        assert parsed.year <= 2026

    def test_random_date_custom_range(self):
        """Test that random_date respects custom start and end years"""
        date = random_date(start_year=2020, end_year=2022)
        parsed = datetime.strptime(date, "%Y-%m-%d")
        
        assert parsed.year >= 2020
        assert parsed.year <= 2022

    def test_random_date_single_year(self):
        """Test that random_date works when start_year equals end_year"""
        date = random_date(start_year=2020, end_year=2020)
        parsed = datetime.strptime(date, "%Y-%m-%d")
        
        assert parsed.year == 2020

    def test_random_date_multiple_calls_can_differ(self):
        """Test that multiple calls can generate different dates (randomness check)"""
        dates = [random_date() for _ in range(50)]
        unique_dates = set(dates)
        
        # Should get some variety across 50 calls in a 12-year range
        assert len(unique_dates) > 1, "Should generate different dates across multiple calls"

    def test_random_date_valid_month(self):
        """Test that generated date has valid month (1-12)"""
        date = random_date()
        parsed = datetime.strptime(date, "%Y-%m-%d")
        
        assert 1 <= parsed.month <= 12

    def test_random_date_valid_day(self):
        """Test that generated date has valid day for the month"""
        date = random_date()
        parsed = datetime.strptime(date, "%Y-%m-%d")
        
        # If parsing succeeds, the day is valid for that month/year
        assert 1 <= parsed.day <= 31

    @patch('utils.date_generator.randint')
    def test_random_date_with_mocked_randint(self, mock_randint):
        """Test that random_date correctly uses randint for randomness"""
        # Mock to return 0 days offset (should give start date)
        mock_randint.return_value = 0
        
        date = random_date(start_year=2020, end_year=2020)
        
        assert date == "2020-01-01"
        mock_randint.assert_called_once()

    def test_random_date_leap_year_handling(self):
        """Test that random_date can generate Feb 29 in leap years"""
        # Generate many dates in a leap year range to potentially get Feb 29
        dates = [random_date(start_year=2020, end_year=2020) for _ in range(1000)]
        
        # 2020 is a leap year, so Feb 29 should be possible
        # We're not asserting it appears (too random), just that no error occurs
        assert all(isinstance(date, str) for date in dates)

    def test_random_date_year_boundaries(self):
        """Test that random_date can generate dates at year boundaries"""
        dates = [random_date(start_year=2020, end_year=2020) for _ in range(500)]
        
        # Should be able to generate dates throughout the year
        parsed_dates = [datetime.strptime(d, "%Y-%m-%d") for d in dates]
        months = set(d.month for d in parsed_dates)
        
        # With 500 samples, we should hit multiple months
        assert len(months) > 1, "Should generate dates across different months"

    def test_random_date_no_leading_zeros_in_year(self):
        """Test that year in generated date doesn't have unnecessary leading zeros"""
        date = random_date(start_year=2020, end_year=2020)
        year_part = date.split('-')[0]
        
        assert year_part == "2020"
        assert len(year_part) == 4

# Made with Bob
