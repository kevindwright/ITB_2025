component singleton {

	public utilService function init(){
		variables.env         = new coldbox.system.core.delegates.Env();
		variables.utcBaseDate = createObject( "java", "java.util.Date" ).init( javacast( "int", 0 ) );
		return this;
	}

	struct function responseMessage(
		required boolean success,
		string message = "",
		any detail     = {}
	){
		return {
			"status"  : arguments.success ? "success" : "failure",
			"message" : arguments.message,
			"detail"  : arguments.detail
		};
	}

	public string function generateGUID(){
		return insert( "-", createUUID(), 23 );
	}

	function convertDateToUnixTimestamp( required date dateToConvert ){
		return dateDiff(
			"s",
			utcBaseDate,
			parseDateTime( dateToConvert )
		);
	}

	function convertUnixTimestampToDate( required numeric timestamp ){
		return dateAdd( "s", timestamp, utcBaseDate );
	}

	function getPrivateKey(){
		local.jwtPrivateKey = fileRead( expandPath( env.getSystemSetting( "JWT_PRIVATE_KEY_PATH", "" ) ) );
		return local.jwtPrivateKey;
	}

	function getPublicKey(){
		local.jwtPublicKey = fileRead( expandPath( env.getSystemSetting( "JWT_PUBLIC_KEY_PATH", "" ) ) );
		return local.jwtPublicKey;
	}

	function javaBytesToCFBinary( javaBytes ){
		local.baos = createObject( "java", "java.io.ByteArrayOutputStream" );
		for ( b in arguments.javaBytes ) {
			local.baos.write( javacast( "int", ( b lt 0 ? b + 256 : b ) ) );
		}
		return local.baos.toByteArray();
	}

	function base64UrlEncode( binaryData ){
		local.b64 = binaryEncode( arguments.binaryData, "base64" );

		local.b64 = replace( local.b64, "+", "-", "all" );
		local.b64 = replace( local.b64, "/", "_", "all" );
		local.b64 = replace( local.b64, "=", "", "all" );
		return local.b64;
	}

	function base64UrlDecode( str ){
		local.padding = repeatString( "=", ( 4 - ( len( arguments.str ) mod 4 ) ) mod 4 );
		local.str     = replace( arguments.str & local.padding, "-", "+", "all" );
		local.str     = replace( local.str, "_", "/", "all" );
		return binaryDecode( local.str, "base64" );
	}

}
