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


abstract type CmdReturnCode end
struct CmdSuccess <: CmdReturnCode end
struct CmdInvalid <: CmdReturnCode end
struct ParameterError <: CmdReturnCode end
struct ValueInvalid <: CmdReturnCode end
struct CodeInvalid <: CmdReturnCode end
struct DeviceLocked <: CmdReturnCode end
struct FunctionNotSupported <: CmdReturnCode end
struct ComTimeOut <: CmdReturnCode end
struct ValueNotAvailable <: CmdReturnCode end
struct DeviceNotResetted <: CmdReturnCode end
return_codes = Dict(
  '0' => CmdSuccess(),
  '1' => CmdInvalid(),
  '2' => ParameterError(),
  '3' => ValueInvalid(),
  '4' => CodeInvalid(),
  '5' => DeviceLocked(),
  '6' => FunctionNotSupported(),
  '7' => ComTimeOut(),
  '8' => ValueNotAvailable(),
  '9' => DeviceNotResetted()
)


abstract type StatusCode end
struct Idle <: StatusCode end
struct WaitingForTrigger <: StatusCode end
struct TakingSpectrum <: StatusCode end
struct HasData <: StatusCode end
struct Error <: StatusCode end
status_codes = Dict(
  "0" => Idle(),
  "1" => WaitingForTrigger(),
  "2" => TakingSpectrum(),
  "3" => HasData(),
  "-1" => Error() # not used according to manual 
)
StatusCode(c) = status_codes[c]
Base.parse(::Type{StatusCode}, str) = status_codes[str]

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
  from_string=false,
  timeout=10.0)
  set_read_timeout(s.serial_port, timeout)
  return_code = return_codes[read(s.serial_port, Char)]
  @debug return_code
  return_value = nothing
  if return_code == CmdSuccess()
    # data = UInt8[]
    #read data up to "\r\n"
    # stop = false
    # while stop == false
    #   bytes = read(s.serial_port)
    #   @debug bytes
    #   append!(data, bytes)
    #   if (length(data) >= 2) && data[end-1:end] == [0x0d, 0x0a] 
    #     deleteat!(data, length(data)-1:length(data)) 
    #     stop = true
    #   end
    #   sleep(0.1)
    # end
    data_str = readuntil(s.serial_port, "\r\n")
    data = Vector{UInt8}(lstrip(data_str))

    # clean data: remove white space at the beginning
    # if !isnothing(type) && first(data) == 0x20
    #   popfirst!(data)
    # end

    @debug data
    @debug length(data)
    return_value = if isnothing(type)
      nothing
    elseif from_string
      parse(type, String(data))
    else
      type(data)
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
  parse_response(s, StatusCode; from_string=true)
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
  parse_response(s, Int; from_string=true)
end

function set_exposure_time(s::Spectrometer, time_μs)
  send_cmd(s, "T=$time_μs")
  parse_response(s, nothing)
end

end
