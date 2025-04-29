component extends="coldbox.system.EventHandler" {

	property name="cbCookieStorage" inject="cookieStorage@cbstorages";

	property name="authService" inject="auth:authService@api";
	property name="utilService" inject="utilService@api";
	property name="userService" inject="userService@api";

	// OPTIONAL HANDLER PROPERTIES
	this.prehandler_only      = "";
	this.prehandler_except    = "";
	this.posthandler_only     = "";
	this.posthandler_except   = "";
	this.aroundHandler_only   = "";
	this.aroundHandler_except = "";

	this.allowedMethods = { index : "GET" };

	function preIndex(){
		event.noLayout();
	}

	any function index( event, rc, prc ) cache="false"{
		try {
			local.user = authService.authenticateUser();

			return utilService.responseMessage( true, "user profile", local.user );
		} catch ( any e ) {
			if ( e.type == "jwtcfml.ExpiredSignature" ) {
				event.setHTTPHeader( statusCode = 401, statusText = "401-EXPIRED-TOKEN" );
			} else {
				event.setHTTPHeader( statusCode = 401, statusText = "Unauthorized" );
			}
			return utilService.responseMessage( false, e.message );
		}
	}

}
