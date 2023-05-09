# MCNet-Software v1.1
OpenComputers software for setting up a network of computers.

Currently, only local servers are added, so typical communication network should look like this:
Client <-modem-> Server

__[Server]__
To start a server, you'll need to configure a LSmain.lua file a bit.
First, you need to enter server's name and second, you need to select a port for your server.
Default ports for local servers are: 301-319. Extra, you may use the 319-399 range, but clients should configure their file first(see below)
After entering name and port to your LSmain.lua file, just run it - the server should start.

__[Writing a server]__
To write a server you can use 2 functions: csend(linetype,msg) and cinput(msg). See LSmain.lua, there's an example of all functions.

_csend_ sends a messgae to your client. First argument is type of message and second one is your message. All arguments are strings. 
Here's a list of all types of messages:

`"exit" - disconnects from client`

`"clear" - clears client's screen`

`"sleep","<amount of time>" - client sleeps for some time. (!!server must sleep for a little longer than client!!) `

`"text","<your text>" - just writest text to client`

_cinput_ inputs a message. if you want to send some symbols before input field (like ">"), write them as 1 argument.       
Usage: `local input=csend() if not clientAddress then return 1 end`

__[Client]__ 
For default use of Client software, jsut run the Client.lua file. Note, that your wait of searching for servers may vary.
You can configure your timeout time in the code with `timeout` value. If you want to connect above the 301-319 range, edit your `maxLocalPorts` value in Client.lua code.

Make sure to report all errors! Other types of connections coming soon, don't worry!
