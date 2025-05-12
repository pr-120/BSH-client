# BSH-client
Client side of BSH application

# INSTALLATION
The application can be installed by executing the `installation.sh` script located in the root of the application. The python virtual environment needed for the openSenseMap will be installed as well as any other system packages needed. As the application was designed for raspberry Pis which used the Debian 12 (bookworm) distribution, the only necessary package was the `libcurl4-openssl-dev`. When using another distribution the user might need to install any additional necessary packages. Additionally, the code for the backdoor is compiled in `thetick\src`. If any changes are made to the files in this folder the user will need to recompile by executing """make clean\n make""".

As the project uses the BME688 sensor to measure environmental data, the installation also incorporates the setup and installation of said sensor. This would also need to be adjusted if another sensor were used. The code to be changed is located at the end of `installation.sh`. Additionally to this installation a few settings must be changed. The kernel driver of the I2C and SPI need to be enabled through the configuration settings of the raspberry pi. There is a nice tutorial on this at [waveshare.com/wiki/BME680_Environmental_Sensor#Python].


## CONFIGURATION

The configuration folder contain the `folder_paths.config` and `preliminary_app_data.config` files. `folder_paths.config` is used to locate folders and files throughout the project without having to rely on relative paths. This induces that when the application structure is changed, this file needs to be adjusted as well. 

The `preliminary_app_data.config` contains filler values which define how the client device interacts with the C&C server as well as the openSenseMap application. The ip address as well as the port at which the remote shell is listening on the C&C server must be adjusted for individual use. Additionally the ID of the sensor given by the openSenseMap must be added as well as the IDs of the individual sensor parts. Without this the client device cannot upload the data and simulate the workings of an IoT device.

!IMPORTANT!: After adding this information to the `preliminary_app_data.config` file, the file must be renamed. The application expects the file to be called `app_data.config`.
