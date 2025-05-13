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
            time.sleep(RATE_LIMITS_TIME)        
        except requests.exceptions.ConnectionError:
            # renew session
            session = requests.Session()
            print("-- CONNECTION FAILURE --")
        time.sleep(RATE_LIMITS_TIME)


if __name__ == "__main__":
    main()

