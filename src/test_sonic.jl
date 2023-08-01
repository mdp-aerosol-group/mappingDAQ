using YoungModel81000
using LibSerialPort
list_ports()
portSONIC = YoungModel81000.config("/dev/ttyUSB0") 



nbytes_read, bytes = LibSerialPort.sp_nonblocking_read(portSONIC, 512)
str = String(bytes[1:nbytes_read])
tmp = split(str, "\r") 
tmp = filter(x -> x .!= "\0", tmp)
msg = map(x -> parse.(Float64, split(x)), tmp)
msg = filter(x -> (length(x) == 6), msg)
println(msg)

LibSerialPort.get_port_list()
