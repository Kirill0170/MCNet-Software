--client module
--locals
local component=require("component")
local computer=require("computer")
local event=require("event")
local modem=component.modem
local term=require("term")
local contype="none"
local maxLocalPorts=319
local timeout=5
local localSearched=false
local serverMap={}
local localConnected=nil --server name
--functions
local function printServerTable(keyword)
	if not keyword then keyword="all" end
	print("Contype|Port|Name")
	print("-------+----+----------")
	for key,values in pairs(serverMap) do
		if keyword=="all" then
			local ctype
			if values[3]=="local" then ctype="local "
			else ctype=values[3] end
			print(ctype.." |"..values[2].." |"..key)
		else
			if values[3]==keyword then
				local ctype
				if values[3]=="local" then ctype="local "
				else ctype=values[3] end
				print(ctype.." |"..values[2].." |"..key)
			end
		end
	end
end
local function linput(input) --input
    local address,port,_=table.unpack(serverMap[localConnected])
	--check if disconnected
	modem.send(address,port,"disconnected?")
	local _,_,from,port2,_,msg=event.pull(timeout,"modem")
	if msg=="n" then
		--ok
	elseif msg=="busy" or msg=="y" or from~=address then
		--disconnected
		print("Disconnected")
		localConnected=nil
		return false
	else
		print("Unknown error occured. Disconnected")
		localConnected=nil
		return false
	end
	--now, send the input. if not received, send again
	local chks=false
	local try=0 --counter, if try==5, disconnect
	while not chks do
		--check current try
		if try==5 then --disconnect
			print("Server timeouted.")
			localConnected=nil
			return false
		end
		--send
		modem.send(address, port,"input",input)
		--wait for confirm
		local _,_,from,_,_,msg=event.pull(timeout,"modem")
		if not from then 
			--timeout
			try=try+1
		elseif from~=address then
			--interrupted
			try=try+1
		elseif msg~="received" then
			--uhh, error?
			try=try+1
		else
			--all good
			chks=false
			return true
		end
	end
end
local function connection()
	local exitc=false
	local timeoutchk=0
	local address,port,_=table.unpack(serverMap[localConnected])
	if not modem.isOpen(port) then modem.open(port) end
	while not exitc do
		local _,_,from,port2,_,ltype,msg=event.pull(timeout,"modem")
		if ltype==nil then
				print("Request timeouted")
				timeoutchk=timeoutchk+1
				if timeoutchk==5 then
					print("Connection timeouted")
					exitc=true
					localConnected=nil
				end
		elseif from==address then
			timeoutchk=0
			if ltype=="exit" then
				print("Disconnected.")
				localConnected=nil
				exitc=true
			elseif ltype=="clear" then
				term.clear()
			elseif ltype=="sleep" then
				if tonumber(msg)~=nil then os.sleep(tonumber(msg)) 
				else print("Invalid sleep request received") end
			elseif ltype=="text" then
				if not msg then msg="" end
				print(msg)
			elseif ltype=="input" then
				if msg then term.write(msg) end
				local inputc=io.read()
				local chkli=linput(inputc)
				if not chkli then 
					--if input failed
					exitc=true
				end
			else
				print("Invalid request received")
			end
		else
			print("Interrupted")
		end
	end
end
local function local_search()
	for i=301,maxLocalPorts do
		modem.open(i)
		modem.broadcast(i,"localsearch","hello!")
		local _,_,from,port,_,msg1,msg2,msg3=event.pull(timeout,"modem")
		--msg3=address
		--check
		if msg1=="localsearch" then
			if msg2 and msg3 then
				--add server to map
				serverMap[msg2]={msg3,i,"local"}
			end
		end
		modem.close(i)
	end
	localSearched=true
	return true
end
local function checkForServer(name)
	if not serverMap[name] then return false else return true end
end
local function local_connect(name)
	if not checkForServer(name) then print("No such server") return false end
	local address,port,_=table.unpack(serverMap[name])
	print("Attempting to connect to "..address.." on port "..port)
	modem.open(port)
	modem.send(address,port,"localconnect")
	local _,_,from,_,_,msg1,msg2=event.pull(timeout*2,"modem")
	if not msg1 then 
		modem.close(port)
		print("Server response timeouted")
		return false
	elseif from~=address then
		modem.close(port)
		print("Interrupted")
		return false
	else
		if msg1=="localconnect" then
			if msg2=="connected" then 
				localConnected=name 
				print("Connected to "..name) 
				return true
			elseif msg2=="busy" then
				modem.close(port)
				print(name.."is busy")
				return false
			else
				modem.close(port)
				print("Unvalid request received from "..name)
				return false
			end
		else
			print("Unvalid response from "..name)
			modem.close(port) 
			return false 
		end
	end
end
--main
print("Checking for modem...")
if not component.isAvailable("modem") then error("No modem found.") end
if not modem.isWireless() then error("Wireless modem required") end
os.sleep(0.5)
term.clear()
computer.beep()
print("MCNet Client Software v1.1")
print("Your computer address is: "..component.getPrimary("modem")["address"])
print("Your signal strength is: "..modem.getStrength())
print("--------------------------")
local exit1=false
while not exit1 do
print("Choose connection type. (type help for info)")
	local input1=io.read()
	if input1=="help" then
		print("test = test connection(dev only)")
		print("local = connect to local server")
		print("server = connect to local node")
		print("direct = connect directly to server using linked cards")
		print("exit - to exit program")
	elseif input1=="test" then
		--test section
	elseif input1=="local" then
		exit1=true
		contype=input1
		if not localSearched then
			print("Searching for local servers")
			local _=local_search()
			print("Search completed.")
			os.sleep(1)
		else
			print("Search for local servers? [y/n]")
			local chk1=term.read()
			if chk1=="y" or chk1=="Y" then
				local _=local_search()
				print("Search completed.")
				os.sleep(1)
			end
		end
	elseif input1=="server" then
		exit1=true
		contype=input1
	elseif input1=="direct" then
		exit1=true
		contype=input1
	elseif input1=="exit" then
		exit1=true
		contype="exit"
	else
		print("Unknown value. Type help for info.")
	end
end
--contype is given, enter connection menu
if contype=="none" then
	computer.beep()
	print("Internal error occured: contype=none")
	print("Please restart")
	error("Internal error")
elseif contype=="exit" then
elseif contype=="test" then
	error("Test here.")
elseif contype=="local" then
	local mainloop=true
	while mainloop do
		while not localConnected do
			term.clear()
			print("Local connection menu")
			print("Enter a name of server to connect")
			printServerTable("local")
			print(" ")
			local input2=io.read()
			if input2=="exit" then
				localConnected="exit"
				print("Exiting...")
				mainloop=false
				os.sleep(1)
				break
			else
				local chk2=local_connect(input2)
				if chk2==false then print("Connection failed") os.sleep(2) end 
			end
		end
		--connect or exit
		print("----------------")
		connection()
		os.sleep(1)
	end
end
print("Exited")
