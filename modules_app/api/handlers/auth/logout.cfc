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

	// REST Allowed HTTP Methods Ex: this.allowedMethods = {delete='POST,DELETE',index='GET'}
	this.allowedMethods = { index : "POST" };

	function preIndex(){
		event.noLayout();
	}

	any function index( event, rc, prc ){
		try {
			local.user       = authService.authenticateUser();
			local.jwtPayload = authService.decodeJWT();

			jwtAuth().getTokenStorage().clear( local.jwtPayload.jti );

			userService.revokeFingerprint( val(local.jwtPayload.sub), local.jwtPayload.fingerprint );

			return utilService.responseMessage( true, "user successfully logged out" );
		} catch ( any e ) {
			event.setHTTPHeader( statusCode = 400, statusText = "Bad Request" );
			return utilService.responseMessage( false, e.message );
		}
	}

}
