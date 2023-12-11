using Revise, QWave
using GLMakie

## Enable debug logging

using Logging
debug_logger = ConsoleLogger(stderr, Logging.Debug)
global_logger(debug_logger)

## Connect the spectrometer

sp = Spectrometer("/dev/ttyUSB0")

## Query status of spectrometer (should be idle if just plugged in)

@info get_status(sp)

## Query exposure time (should be 10_000 μs [= 0.01 s] if just plugged in)

@info get_exposure_time(sp)

## Set exporure time to 100 ms

@info set_exposure_time(sp, 100_000)

## Check exposure time

@info get_exposure_time(sp)

## Get status 

@info get_status(sp)

## Reset spectrometer

@info reset_device(sp)

## Start exposure to take a spectrum

@info start_exposure(sp)

## Get status 

@info get_status(sp)

##

data = get_data(sp).value

##

lines(data.data)
