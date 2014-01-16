// Written in the D programming language.
/**						   
Copyright: Copyright Felix 'Zoadian' Hufnagel 2014-.

License:   $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).

Authors:   $(WEB zoadian.de, Felix 'Zoadian' Hufnagel)
*/
module netstack.net;


import std.socket;
import std.range;
import std.exception;
import std.typecons;
public import std.socket : Address, InternetAddress;


struct ConnectionInOutRange {
private:
	Connection _connection;

public:
	ubyte front() nothrow @property {	  
		try {
			return _connection._data[0];
		}
		catch(Exception e) {
			assert(0);
		}
	}

	void popFront() nothrow {	 
		try {
			_connection._data.popFront(); 
		}
		catch(Exception e) {		  
			assert(0);
		}
	}

	bool empty() nothrow @property {
		return this.length > 0;
	}

	ubyte opIndex(size_t idx) nothrow {	 
		try {
			return _connection._data[idx]; 
		}
		catch(Exception e) {  
			assert(0);
		}
	}			

	size_t length() nothrow @property {	
		try {
			_connection._receive();
			return _connection._data.length; 
		}
		catch(Exception e) {	
			assert(0);
		}
	}

public:
	void put(ubyte data) nothrow {
		this.put([data]);
	}

	void put(const(ubyte[]) data) nothrow {
		try {
			_connection._socket.send(data);
		}
		catch(Exception e) {
		}
	}
}

/**
Connection
*/				 
class Connection {	   
private:
	Socket _socket;	
	ubyte[] _data;

private:	 
	this(Socket socket) @safe nothrow {
		this._socket = socket;
	}

public:		   
	this(Address adress) nothrow {
		try {
			this._socket = new TcpSocket();
			if(this._socket is null) return;
			this._socket.connect(adress);
			this._socket.blocking = false;
		}
		catch(Exception e) {
			this._socket = null;
		}		
	}

	///Warning! make sure this is called before main exits!
	~this() nothrow {
		if(this._socket is null) return;
		try {
			this._socket.shutdown(SocketShutdown.BOTH);
			this._socket.close();
			this._socket.destroy();
		}
		catch(Exception e) {
		}
	}

public:
	bool isAlive() const @property {
		if(this._socket is null) return false;
		return this._socket.isAlive;
	}

	ConnectionInOutRange io() @safe nothrow {
		return ConnectionInOutRange(this);
	}

private:
	void _receive() nothrow {	
		try {	  
			ubyte[1024] buf;
			ptrdiff_t read = this._socket.receive(buf);	
			this._data ~= buf[0..read];
		}
		catch(Exception e) {
		}
	}
}


/**
NewConnectionsResult
*/	
struct NewConnectionsResult {
private:
	Server _server;
public:
	Connection front() @safe nothrow @property {
		return _server._newConnections[0];
	}

	void popFront() @safe nothrow {
		_server._newConnections.popFront();
	}

	bool empty() nothrow @property {
		return this.length > 0;
	}

	size_t length() nothrow @property {
		_server._accept();
		return _server._newConnections.length;
	}
}


/**
Server
*/	
class Server {
private:			
	Socket _socket;			  
	Connection[] _connections;
	Connection[] _newConnections;

public:				
	this(Address address, uint maxConnections) nothrow {	
		try {
			this._socket = new TcpSocket();
			if(this._socket is null) return;
			this._socket.blocking = false;
			this._socket.bind(address);
			this._socket.listen(maxConnections);
		}
		catch(Exception e) {
			this._socket = null;
		}
	}

	///Warning! make sure this is called before main exits!
	~this() nothrow {
		if(this._socket is null) return;
		try {
			this._socket.shutdown(SocketShutdown.BOTH);
			this._socket.close();
			this._socket.destroy();
		}
		catch(Exception e) {
		}
	}

public:		   
	Connection[] connections() @safe nothrow @property { 
		return this._connections;
	}			   

	auto newConnections() @safe nothrow @property {
		return NewConnectionsResult(this);
	}

	bool isAlive() const nothrow @property {
		if(this._socket is null) return false;
		try {
			return this._socket.isAlive;			
		} 
		catch(Exception e) {
			return false;
		}
	}

private:
	void _accept() nothrow {	  	
		try {
			Socket clientSocket = this._socket.accept();
			if(clientSocket !is null && clientSocket.isAlive()) {
				auto connection = new Connection(clientSocket);
				this._connections ~= connection;
			} else if(clientSocket !is null) {	
				clientSocket.shutdown(SocketShutdown.BOTH);
				clientSocket.close();
				clientSocket.destroy();
			}		
		} 
		catch(SocketAcceptException sae) {
		}  
		catch(Exception e) {
		}
	}
}
