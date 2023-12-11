# QWave

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://jqfeld.github.io/QWave.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://jqfeld.github.io/QWave.jl/dev/)
[![Build Status](https://github.com/jqfeld/QWave.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jqfeld/QWave.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/jqfeld/QWave.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/jqfeld/QWave.jl)

## Installation

If the spectrometer is not automatically detected as an FTDI-serial port (now
file `/dev/ttyUSB*` is created when the spectrometer is plugged in) run 
```sh
sudo sh -c "echo 0403 90cf > /sys/bus/usb-serial/drivers/ftdi_sio/new_id"
```
to add the product id to the `ftdi_sio` driver.
