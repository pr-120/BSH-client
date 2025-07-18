from measurement import record_measurement, measurementClass
import requests
from dotenv import load_dotenv
import os
import time


# load app data
current_folder = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(current_folder, "../config/app_data.config"))

SENSE_BOX_ID = os.getenv("sensor_box_id")
HUMIDITY_SENSOR_ID = os.getenv("humidity_sensor_id")
TEMPERATURE_SENSOR_ID = os.getenv("temperature_sensor_id")
AIR_PRESSURE_SENSOR_ID = os.getenv("air_pressure_sensor_id")
GAS_RESISTANCE_SENSOR_ID = os.getenv("gas_resistance_sensor_id")

def send_measurements_to_server(session: requests.Session, measurement: measurementClass) -> int:

    opensensemap_url = "https://api.opensensemap.org/boxes/"
    adjusted_url = opensensemap_url + SENSE_BOX_ID + "/data"

    body = {HUMIDITY_SENSOR_ID: [measurement.humidity],
            TEMPERATURE_SENSOR_ID: [measurement.temperature],
            AIR_PRESSURE_SENSOR_ID: [measurement.pressure],
            GAS_RESISTANCE_SENSOR_ID: [measurement.gas_resistance]
            }
    
    response = session.post(adjusted_url, json=body, timeout=10) 

    return response

