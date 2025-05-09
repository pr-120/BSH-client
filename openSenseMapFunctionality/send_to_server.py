from return_measurements import record_measurement
import requests

SENSE_BOX_ID = "67c45a7f390e780007681ede"
HUMIDITY_SENSOR_ID = "67e52c1b85a76200089ef136"
TEMPERATURE_SENSOR_ID = "67c45a7f390e780007681edf"
AIR_PRESSURE_SENSOR_ID = "67e5329b85a7620008aa3bcc"
GAS_RESISTANCE_SENSOR_ID = "67e5329b85a7620008aa3bce"

def send_measurements_to_server() -> int:

    opensensemap_url = "https://api.opensensemap.org/boxes/"
    adjusted_url = opensensemap_url + SENSE_BOX_ID + "/data"

    measurement = record_measurement()

    body = {HUMIDITY_SENSOR_ID: [measurement.humidity],
            TEMPERATURE_SENSOR_ID: [measurement.temperature],
            AIR_PRESSURE_SENSOR_ID: [measurement.pressure],
            GAS_RESISTANCE_SENSOR_ID: [measurement.gas_resistance]
            }
    
    try:
        response = requests.post(adjusted_url, json=body)
    except requests.exceptions.ConnectionError:
        print("Temporary connection failure, try again in next post");	
	
    return response

