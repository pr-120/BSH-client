from return_measurements import record_measurement
import requests
from dotenv import load_dotenv
import os

# load app data
current_folder = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(current_folder, "../config/app_data.config"))

SENSE_BOX_ID = os.getenv("sensor_box_id")
HUMIDITY_SENSOR_ID = os.getenv("humidity_sensor_id")
TEMPERATURE_SENSOR_ID = os.getenv("temperature_sensor_id")
AIR_PRESSURE_SENSOR_ID = os.getenv("air_pressure_sensor_id")
GAS_RESISTANCE_SENSOR_ID = os.getenv("gas_resistance_sensor_id")

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
        response = "-- CONNECTION FAILURE --"
	sleep 60
	
    return response

