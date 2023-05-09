--local server main
--locals
local component=require("component")
local computer=require("computer")
local event=require("event")
local modem=component.modem
local term=require("term")
local mainName="" --ENTER YOUR MAIN SERVER NAME HERE
local port=301 --ENTER YOUR PORT HERE(301-319 by default, 301-399 for extended
local mainAddress=component.getPrimary("modem")["address"]
local session=false --if client is connected
local clientAddress=nil --client connection 
--functions
local function connection_wait()
	local _,_,from,_,_,msg1,msg2=event.pull("modem")
	if msg1=="localsearch" and msg2=="hello!" then 
		print("Client asked for name: "..from)
		modem.send(from,port,"localsearch",mainName,mainAddress)
	elseif msg1=="localconnect" then
		--connect to client
		print("Connection to client: "..from)
		clientAddress=from
		modem.send(from,port,"localconnect","connected")
		session=true
	else
		print("Invalid request received: "..msg1)
		modem.send(from,port,"unvalid") --!!!!!
	end
end
local function csend(ltype, msg)
	if msg then modem.send(clientAddress,port,ltype,msg)
	else modem.send(clientAddress,port,ltype,msg) end
end
local function disconnect()
	session=false
	print("Disconnected from "..clientAddress)
	clientAddress=nil
end
local function connection() 
	if not clientAddress then error("Attempt to connect to nothing") end
	--YOUR SERVER IS HERE
	--use the "csend" function to send messages to client, see readme.txt for info
	local exitc=false
	--main loop
	while not exitc do
		csend("text","Hello world!")
		csend("sleep","5")
		os.sleep(5.1) --make sure to wait a little bit longer than that!
		
		csend("exit")
		exitc=true
		disconnect() --always remember to close seccion!!
	end
end
--main
print("Checking for modem...")
if not component.isAvailable("modem") then error("No modem found.") end
if not modem.isWireless() then error("Wireless modem required") end
if mainAddress=="" then error("Main server address is not given") end
if mainName=="" then error("Main server name is not given") end
os.sleep(0.5)
term.clear()
computer.beep()
print("MCNet Local Server Software v1.0")
print("This server name is: "..mainName)
print("This server address is: "..mainAddress)
print("This server signal strength is: "..modem.getStrength())
print("--------------------------")
os.sleep(1)
print("Activating session")
modem.open(port)
local exit1= false
while exit1==false do
	if not session then
		connection_wait()
	else
		connection()
	end
end