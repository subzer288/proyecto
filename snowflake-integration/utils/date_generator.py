from random import randint
from datetime import date, timedelta

def random_date(start_year=2014, end_year=2026):
    start = date(start_year, 1, 1)
    end = date(end_year, 12, 31)

    random_days = randint(0, (end - start).days)
    picked_date = start + timedelta(days=random_days)

    return picked_date.strftime("%Y-%m-%d")