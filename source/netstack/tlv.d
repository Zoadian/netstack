// Written in the D programming language.
/**						   
Copyright: Copyright Felix 'Zoadian' Hufnagel 2014-.

License:   $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).

Authors:   $(WEB zoadian.de, Felix 'Zoadian' Hufnagel)
*/
module netstack.tlv;

import std.traits;
import std.typetuple;

import std.stdio;

import cerealed;


private struct TlvHeader {
	size_t tag;
	size_t length;
};


ubyte[] tlvEncode(size_t tag, const(ubyte[]) value) pure nothrow {
	TlvHeader header = TlvHeader(tag, value.length); 
	return (cast(ubyte*)&header)[0 .. header.sizeof] ~ value;
}


bool tlvDecode(ubyte[] tlv, out size_t tag, out ubyte[] value)  { 
	if(tlv.length < TlvHeader.sizeof) return false;
	auto header = cast(TlvHeader*)tlv.ptr;
	tag = header.tag;
	value = tlv[TlvHeader.sizeof .. TlvHeader.sizeof + header.length];	 
	return true;
}


ubyte[] protoEncode(T, PROTO...)(T data) {
	alias IDX = staticIndexOf!(T, PROTO);
	static assert(IDX != -1, "type not in protocol");

	Cerealiser enc = new Cerealiser();
	enc ~= data;		 
	return tlvEncode(IDX, enc.bytes);
}
				  

bool protoDecode(T, PROTO...)(ubyte[] data, out T t) {	
	alias IDX = staticIndexOf!(T, PROTO);
	static assert(IDX != -1, "type not in protocol");

	size_t tag;
	ubyte[] value;
	if(tlvDecode(data, tag, value) == false) return false;

	auto dec = new Decerealiser(value);	  					  
	if(tag == IDX) {
		t = dec.value!T;
		return true;
	}
	return false;
}
