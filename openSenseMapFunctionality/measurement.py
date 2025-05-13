import random


class measurementClass:

	def __init__(self, temperature, pressure, humidity, gas_resistance):
		self.temperature = temperature
		self.pressure = pressure
		self.humidity = humidity
		self.gas_resistance = gas_resistance


def create_artificial_measurement():
	return measurementClass(round(random.uniform(20.0, 30.0)),
				round(random.uniform(950.0, 1020.0)),
				round(random.uniform(25.0, 60.0)),
				round(random.randint(102400000, 500000000)))
