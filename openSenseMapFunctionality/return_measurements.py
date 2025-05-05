
import bme680
from  measurement import measurementClass


def record_measurement() -> measurementClass:
    """
    Records and returns the measurement of the bme680 sensor
    """

    try:
        sensor = bme680.BME680(bme680.I2C_ADDR_PRIMARY)
    except (RuntimeError, IOError):
        sensor = bme680.BME680(bme680.I2C_ADDR_SECONDARY)

    if sensor.get_sensor_data():

        new_measurement = measurementClass(
                sensor.data.temperature,
                sensor.data.pressure,
                sensor.data.humidity,
                sensor.data.gas_resistance)
        
        return new_measurement

    else:
        raise ValueError("Sensor couldn't record measurement data")


