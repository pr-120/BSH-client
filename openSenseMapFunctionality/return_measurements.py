
import bme680
from  measurement import measurementClass


def record_measurement() -> measurementClass:
	"""Records and returns the measurement of the bme680 sensor"""

	try:
		sensor = bme680.BME680(bme680.I2C_ADDR_SECONDARY)

		new_measurement = measurementClass(
               		sensor.data.temperature,
               		sensor.data.pressure,
               		sensor.data.humidity,
               		sensor.data.gas_resistance)
		
		print(sensor.data.temperature,
               		sensor.data.pressure,
               		sensor.data.humidity,
               		sensor.data.gas_resistance)
 
       
 
	except (RuntimeError, IOError):
        
		# if the sensor fails during data collection we use replacement values
		print("Sensor connection disrupted -- Using replacement values")
		
		new_measurement = measurementClass(
					"25.23",
					"28.42",
					"959.51",
					"102400000")

	return new_measurement

