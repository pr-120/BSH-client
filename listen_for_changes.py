import signal
import multiprocessing.shared_memory
import struct
from json import loads
from multiprocessing import Process
from socket import AF_INET, SOCK_STREAM, socket
import sys
import subprocess

# Config struct format (matches C config_t)
CONFIG_FORMAT = 'iiii'
CONFIG_SIZE = struct.calcsize(CONFIG_FORMAT)

# Global shared memory
shm = None

config_socket = None
fp_socket = None


def cleanup(signum, frame):
    global shm, config_socket
    if config_socket:
        config_socket.close()
    if fp_socket:
        fp_socket.close()
    if shm:
        shm.close()
        shm.unlink()
    sys.exit(0)


# execute cleanup function when script is terminated
signal.signal(signal.SIGTERM, cleanup)
signal.signal(signal.SIGINT, cleanup)


def update_existing_config(new_config):
    """Update shared memory with JSON config."""
    global shm
    # Validate required fields
    if not all(field in new_config for field in ["buffer_size", "transfer_frequency", "burst_duration", "burst_pause"]):
        return

    # Extract config values
    try:
        buffer_size = int(new_config["buffer_size"])
        burst_duration = int(new_config["burst_duration"])
        burst_pause = int(new_config["burst_pause"])
        transfer_frequency = int(float(new_config["transfer_frequency"]) * 1000)  # save frequency in ms
        if buffer_size <= 0:
            return
    except (ValueError, TypeError):
        return

    # Create or connect to shared memory
    if shm is None:
        try:
            shm = multiprocessing.shared_memory.SharedMemory(
                name="current_config", create=True, size=CONFIG_SIZE
            )
        except FileExistsError:
            shm = multiprocessing.shared_memory.SharedMemory(
                name="current_config", create=False, size=CONFIG_SIZE
            )
    # Update shared memory
    config_data = struct.pack(CONFIG_FORMAT, buffer_size, transfer_frequency, burst_duration, burst_pause)
    shm.buf[:CONFIG_SIZE] = config_data


def listen_for_config_changes():
    global config_socket
    with socket(AF_INET, SOCK_STREAM) as sock:
        config_socket = sock
        sock.bind(("0.0.0.0", 42666))
        sock.listen(1)

        while True:
            conn, addr = sock.accept()  # keep listening for new connections
            with conn:
                while True:
                    data = conn.recv(1024)  # listen for incoming data of connection
                    if not data:
                        break
                    new_config = loads(data.decode(encoding="utf-8"))
                    print("received", new_config, "\r")
                    update_existing_config(new_config)


def listen_terminate_fingerprinting():
    global fp_socket
    with socket(AF_INET, SOCK_STREAM) as sock:
        fp_socket = sock
        sock.bind(("0.0.0.0", 42667))
        sock.listen(1)

        while True:
            conn, addr = sock.accept()  # keep listening for new connections
            with conn:
                while True:
                    subprocess.call(
                        "ps aux | grep 'SCREEN -dmS fingerprinting' | awk '{print $2}' | xargs sudo kill 2>/dev/null",
                        shell=True, check=True
                        )


if __name__ == "__main__":
    processes = []

    # Start subprocess to integrate config changes
    proc_config = Process(target=listen_for_config_changes)
    proc_config.start()
    processes.append(proc_config)
    print("Listening for config changes...\r")

    proc_terminate_fp = Process(target=listen_terminate_fingerprinting)
    proc_terminate_fp.start()
    processes.append(proc_terminate_fp)
    print("Listen for fp termination")
