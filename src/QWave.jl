"""
Package to control QWave spectrometers via the ShortLink protocol
"""
module QWave

export Spectrometer, close
export get_status, get_data, start_exposure, reset_device, get_exposure_time,
  set_exposure_time, isvalid

using LibSerialPort

struct Spectrometer
  serial_port::SerialPort
end

function Spectrometer(port_name::String, baudrate=3_000_000)
  serial_port = LibSerialPort.open(port_name, baudrate)

  # the flow control defaults of the operating system might not agree with the
  # settings for the spectrometer. Therefore, set flow control settings to the
  # default of LibSerialPort.jl which is compatible with the spectrometer.
  set_flow_control(serial_port)
  Spectrometer(serial_port)
end

Base.close(s::Spectrometer) = Base.close(s.serial_port)


# abstract type CmdReturnCode end
# struct CmdSuccess <: CmdReturnCode end
# struct CmdInvalid <: CmdReturnCode end
# struct ParameterError <: CmdReturnCode end
# struct ValueInvalid <: CmdReturnCode end
# struct CodeInvalid <: CmdReturnCode end
# struct DeviceLocked <: CmdReturnCode end
# struct FunctionNotSupported <: CmdReturnCode end
# struct ComTimeOut <: CmdReturnCode end
# struct ValueNotAvailable <: CmdReturnCode end
# struct DeviceNotResetted <: CmdReturnCode end
# return_codes = Dict(
#   '0' => CmdSuccess(),
#   '1' => CmdInvalid(),
#   '2' => ParameterError(),
#   '3' => ValueInvalid(),
#   '4' => CodeInvalid(),
#   '5' => DeviceLocked(),
#   '6' => FunctionNotSupported(),
#   '7' => ComTimeOut(),
#   '8' => ValueNotAvailable(),
#   '9' => DeviceNotResetted()
# )
#

@enum CmdReturnCode begin
  CmdSuccess = 0
  CmdInvalid = 1
  ParameterError = 2
  ValueInvalid = 3
  CodeInvalid = 4
  DeviceLocked = 5
  FunctionNotSupported = 6
  ComTimeOut = 7
  ValueNotAvailable = 8
  DeviceNotResetted = 9
end

Base.parse(::Type{CmdReturnCode}, str) = CmdReturnCode(parse(Int, str))


@enum StatusCode begin
  Idle = 0
  WaitingForTrigger = 1
  TakingSpectrum = 2
  HasData = 3
  Error = -1
end
Base.parse(::Type{StatusCode}, str) = StatusCode(parse(Int, str))

struct SpectrumData
  data::Vector{UInt16}
  checksum::UInt16
end

# Base.isvalid(sd::SpectrumData) = (sum(reinterpret(UInt8, sd.data)) % 256) == sd.checksum

function SpectrumData(data::Vector{UInt8})
  if (sum(data[1:end-1]) % 256) != data[end]
    error("spectrum data did not match checksum")
  end
  converted_data = reinterpret(UInt16, data[1:end-1])
  checksum = data[end]
  SpectrumData(converted_data, checksum)
end
Base.parse(::Type{SpectrumData}, str) = SpectrumData(Vector{UInt8}(str))


struct CmdResult{C<:CmdReturnCode,T}
  code::C
  value::T
end

function send_cmd(s::Spectrometer, cmd;
  timeout=10.0)
  # sp_flush(s.serial_port, SP_BUF_BOTH)
  flush(s.serial_port)
  set_write_timeout(s.serial_port, timeout)
  write(s.serial_port, "$cmd\r\n")
  clear_write_timeout(s.serial_port)
end

function parse_response(s::Spectrometer, type=nothing;
  timeout=10.0)
  set_read_timeout(s.serial_port, timeout)
  return_code = parse(CmdReturnCode, read(s.serial_port, Char))
  @debug return_code
  return_value = nothing
  if return_code == CmdSuccess
    data = readuntil(s.serial_port, "\r\n") |> lstrip

    @debug data
    @debug length(data)

    return_value = if isnothing(type)
      nothing
    else
      parse(type, data)
    end
  end
  clear_read_timeout(s.serial_port)

  CmdResult(
    return_code,
    return_value
  )
end

function get_status(s::Spectrometer)
  send_cmd(s, "s?")
  parse_response(s, StatusCode;)
end

function get_data(s::Spectrometer)
  send_cmd(s, "r?")
  parse_response(s, SpectrumData)
end

function start_exposure(s::Spectrometer)
  send_cmd(s, "st")
  parse_response(s)
end


function reset_device(s::Spectrometer)
  send_cmd(s, "res")
  # parse_response(s, StatusCode, from_string=true)
  parse_response(s, nothing)
end

function get_exposure_time(s::Spectrometer)
  send_cmd(s, "T?")
  parse_response(s, Int;)
end

function set_exposure_time(s::Spectrometer, time_μs)
  send_cmd(s, "T=$time_μs")
  parse_response(s, nothing)
end

end
