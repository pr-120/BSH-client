import datetime
from send_to_server import send_measurements_to_server
import time

RATE_LIMITS_TIME = 10 

def main() -> None:
    """
    Runs main process of recording and sending measurements to the OpenSenseMap.
    live sensor measurements every ten seconds due to rate limits
    """

    while True:
        response = send_measurements_to_server()

        print(response, datetime.datetime.now())
        
        time.sleep(RATE_LIMITS_TIME)


if __name__ == "__main__":
    main()


