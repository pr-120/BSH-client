# BSH-client

Bachelor thesis on Backdoor Optimized with RL for Resource-constrained devices.
The official title of this thesis is *AI-powered Backdoor to stay hidden* (**BSH** from here on out).

It is generally advised to first consult the corresponding report of this master thesis. The report motivates the thesis
and introduces the required background. It further explains the development, and reasoning of the backdoor extension in
great detail.

This repository contains the underlying backdoor of the thesis. There
is [another repository](https://github.com/pr-120/BSH-server) for the RL Agent and command and control (C&C) part.

## Setup

First of all, a compatible python instance should be installed on the device. The client application side was developed
with python 3.11.2. Compatability with other versions is not guaranteed.

The application can be installed by executing the `installation.sh` script located in the root of the application. The
python virtual environment needed for the openSenseMap will be installed as well as any other system packages needed.
The application was designed for raspberry Pis which used the Debian 12 (bookworm) distribution, again, compatability
with other versions is not guaranteed. When using another distribution the user might need to install a number of
additional packages.

As the project uses the BME688 sensor to measure environmental data, this requires
additional [setup](waveshare.com/wiki/BME680_Environmental_Sensor#Python) steps.


## Structure

**Important files**:

| File                    | Contains                                                                                                                                    |
|-------------------------|---------------------------------------------------------------------------------------------------------------------------------------------|
| `fingerprinter.sh`      | Contains all functionality of recording and sending fingerprints to C&C                                                                     |
| `listen_for_changes.py` | Creates sockets for commands from the C&C regarding configuration changes or to stop fingerprinting                                         |
| `startup.sh`            | Key script that starts all other necessary processes on client device. When the `-b` flag is given additional benign behaviors are started. |
| `installation.sh`       | Automates installation and compilation process for a clean and effortless setup of the application                                          |

**Folders**:

| Folder                        | Contains                                                                                                                   |
|-------------------------------|----------------------------------------------------------------------------------------------------------------------------|
| `thetick`                     | Logic for the backdoor.                                                                                                    |
| `openSenseMap_functionality`  | Code for the regular posting of environmental data to the *openSenseMap.org*                                               |
| `additional_benign_behaviors` | Scripts and functionality for the execution of two additional benign behaviors: *package_installation* and *ping_behavior* |
| `config` (DANGER!)            | Stores important data used throughout the application                                                                      |

## CONFIGURATION

The configuration folder contains the `folder_paths.config` and `preliminary_app_data.config` files.
`folder_paths.config` is used to locate folders and files throughout the project without having to rely on relative
paths. This induces that when the application structure is changed, this file needs to be adjusted as well.

The `preliminary_app_data.config` contains filler values which define how the client device interacts with the C&C
server as well as the openSenseMap application. The ip address as well as the port at which the remote shell is
listening on the C&C server must be adjusted for individual use. Additionally the ID of the sensor given by the
openSenseMap must be added as well as the IDs of the individual sensor parts. Without this the client device cannot
upload the data and simulate the workings of an IoT device.

!IMPORTANT!: After adding this information to the `preliminary_app_data.config` file, the file must be renamed. The
application expects the file to be called `app_data.config`.

## BACKDOOR (THE TICK)

The files which can be exfiltrated are limited by file-size. Files
must be smaller than int32 meaning around 4GB. The application will fail silently if this is the case. If support for
files larger than this limit is required, the integer size
of the **length** parameter can be increased in `src\parser.c` in the *parser_begin_response()* function.

    // Send a command response header. Data should be sent by the caller.
    void parser_begin_response(Parser *parser, uint8_t status, uint32_t length) {
        
        RESP_HEADER resp;
    
        resp.status = status;
        resp.data_len = htonl(length);
        send_block(parser->fd, (const char *) &resp, sizeof(resp));

    }
