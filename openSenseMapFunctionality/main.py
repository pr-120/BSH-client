import datetime
from send_to_server import send_measurements_to_server
import time
import requests

RATE_LIMITS_TIME = 20 

def main() -> None:
    """
    Runs main process of recording and sending measurements to the OpenSenseMap.
    live sensor measurements every ten seconds due to rate limits
    """
    # create a single TCP connection
    session = requests.Session()
    
    while True:
	
        try:
            response = send_measurements_to_server(session)
        except requests.exceptions.ConnectionError:
            # renew session
            session = requests.Session()
            response = "-- CONNECTION FAILURE --"
        except requests.exceptions.Timeout:
            print("Request timed out, skipping this cycle")
            response = "-- TIMEOUT --"
         
        print(response,datetime.datetime.now())
        time.sleep(RATE_LIMITS_TIME)


if __name__ == "__main__":
    main()

