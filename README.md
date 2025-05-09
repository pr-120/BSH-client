# BSH-client
Client side of BSH application

# INSTALLATION
The application can be installed by executing the `installation.sh` script located in the root of the application. The python virtual environment needed for the openSenseMap will be installed as well as any other system packages needed. As the application was designed for raspberry Pis which used the Debian 12 (bookworm) distribution, the only necessary package was the `libcurl4-openssl-dev`. When using another distribution the user might need to install any additional necessary packages.

As the project uses the BME688 sensor to measure environmental data, the installation also incorporates the setup and installation of said sensor. This would also need to be adjusted if another sensor were used. The code to be changed is located at the end of `installation.sh`. Additionally to this installation a few settings must be changed. The kernel driver of the I2C and SPI need to be enabled through the configuration settings of the raspberry pi. There is a nice tutorial on this at [waveshare.com/wiki/BME680_Environmental_Sensor#Python].

