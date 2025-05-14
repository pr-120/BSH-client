import random
import bme680


class measurementClass:

	def __init__(self, temperature, pressure, humidity, gas_resistance):
		self.temperature = temperature
		self.pressure = pressure
		self.humidity = humidity
		self.gas_resistance = gas_resistance


def init_sensor() -> bme680.BME680:
    """Initialize and return a BME680 sensor instance."""
    sensor = bme680.BME680(bme680.I2C_ADDR_SECONDARY)
    print("*** Sensor initialized ***")
    return sensor


def create_artificial_measurement() -> measurementClass:
	""" returns measurement with artifical datapoints """
	return measurementClass(round(random.uniform(20.0, 30.0)),
				round(random.uniform(950.0, 1020.0)),
				round(random.uniform(25.0, 60.0)),
				round(random.randint(102400000, 500000000)))


def record_measurement(sensor: bme680.BME680) -> measurementClass:
	"""Records and returns the measurement of the bme680 sensor"""

	try:
		if not sensor.get_sensor_data():
			raise RuntimeError("Failed to read sensor data")

		new_measurement = measurementClass(
               		sensor.data.temperature,
               		sensor.data.pressure,
               		sensor.data.humidity,
               		sensor.data.gas_resistance)
		
		print(sensor.data.temperature,
               		sensor.data.pressure,
               		sensor.data.humidity,
               		sensor.data.gas_resistance)
 
       
 
	except (RuntimeError, IOError) as e:
        
		# if the sensor fails during data collection we use replacement values
		print(f"Sensor read error: {e} -- Using replacement values")
		
		new_measurement = create_artificial_measurement() 	

	
	return new_measurement

