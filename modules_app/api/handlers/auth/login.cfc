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
		param rc.username = "";
		param rc.password = "";

		try {
			// Generate new fingerprint
			local.fingerprint = utilService.generateGUID();

			// Create (Signed) JWS token
			local.jwsToken = jwtAuth().attempt(
				rc.username,
				rc.password,
				{ "fingerprint" : local.fingerprint }
			);

			// Create (Encrypted) JWE token
			local.jweToken = authService.createJWE(
				local.jwsToken.access_token,
				{ fingerprint : local.fingerprint }
			);

			// Prep response
			local.response = {
				/* "access_token"             : local.jweToken, */
				"access_token"             : local.jweToken,
				"expires_in"               : jwtAuth().getSettings().jwt.expiration * 60,
				"refresh_token_expires_in" : jwtAuth().getSettings().jwt.refreshExpiration * 60,
				"refresh_token"            : local.jwsToken.refresh_token,
				"token_type"               : "Bearer"
			};

			// Update user fingerprints;
			local.user = userService.updateUser(
				jwtAuth().getUser().getId(),
				"fingerprints",
				local.fingerprint
			);

			// Set cookie with HttpOnly, Secure, and SameSite attributes
			local.cookie = {
				name     : "REFRESH_TOKEN",
				value    : local.response[ "refresh_token" ],
				domain   : "127.0.0.1",
				expires  : local.response[ "refresh_token_expires_in" ],
				path     : "/",
				httpOnly : true,
				sameSite : "strict"
			};
			cbCookieStorage.set(
				name     = local.cookie.name,
				value    = local.cookie.value,
				expires  = dateAdd( "s", local.cookie.expires, now() ),
				domain   = local.cookie.domain,
				path     = local.cookie.path,
				httpOnly = local.cookie.httpOnly,
				sameSite = local.cookie.sameSite
			);
			return utilService.responseMessage(
				true,
				"you have successfully logged in",
				local.response
			);
		} catch ( any e ) {
			event.setHTTPHeader( statusCode = 401, statusText = "Unauthorized" );
			return utilService.responseMessage( false, e.message );
		}
	}

}
