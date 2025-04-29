component extends="coldbox.system.EventHandler" {

	property name="cbCookieStorage" inject="cookieStorage@cbstorages";
	property name="cbJwtService"    inject="jwtService@cbsecurity";

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
			// Check that refresh token exists in http only cookie
			local.refreshToken = cbCookieStorage.get( "REFRESH_TOKEN" );
			if ( isNull( local.refreshToken ) || !len( trim( local.refreshToken ) ) ) {
				throw(
					type    = "MissingRefreshToken",
					message = "No refresh token was provided.",
					detail  = "The request did not include a valid refresh token in the cookie."
				);
			}

			// Get the decoded token
			local.refreshTokenPayload = authService.decodeJWT( local.refreshToken );

			// Check that refresh token exists in storage
			if ( !cbJwtService.getTokenStorage().exists( local.refreshTokenPayload.jti ) ) {
				throw(
					message = "Token has expired, not found in storage",
					detail  = "Storage lookup failed",
					type    = "TokenRejectionException"
				);
			}

			// Validate token type
			authService.validateTokenType( local.refreshTokenPayload, "refresh_token" );

			// Validate the fingerprint inside the refresh token payload
			local.isValidFingerprint = userService.isValidFingerprint(
				val(local.refreshTokenPayload.sub),
				local.refreshTokenPayload.fingerprint
			)
			if ( !local.isValidFingerprint ) {
				throw(
					type    = "InvalidFingerprint",
					message = "Invalid fingerprint",
					detail  = "The request token includes an invalid fingerprint"
				);
			}

			// Use same fingerprint
			local.fingerprint = local.refreshTokenPayload.fingerprint;

			// Get user from DB
			local.user = userService.retrieveUserById( local.refreshTokenPayload.sub );

			// Generate Refresh token
			local.accessTokenClaims = {
				"token_type"  : "access_token",
				"fingerprint" : local.fingerprint
			};
			structAppend( local.accessTokenClaims, local.user.getJWTCustomClaims() );
			local.refreshTokenClaims = {
				"token_type"  : "refresh_token",
				"fingerprint" : local.fingerprint
			}
			structAppend( local.refreshTokenClaims, local.user.getJWTCustomClaims() );
			local.jwsToken = jwtAuth().fromUser(
				local.user,
				local.accessTokenClaims,
				local.refreshTokenClaims
			);

			// Create (Encrypted) JWE token
			local.jweToken = authService.createJWE(
				local.jwsToken.access_token,
				{ fingerprint : local.fingerprint }
			);

			// Prep response
			local.response = {
				"access_token"             : local.jweToken,
				"expires_in"               : jwtAuth().getSettings().jwt.expiration * 60,
				"refresh_token"            : local.jwsToken.refresh_token,
				"refresh_token_expires_in" : jwtAuth().getSettings().jwt.refreshExpiration * 60,
				"token_type"               : "Bearer"
			};

			// Invalidate token for rotation
			jwtAuth().getTokenStorage().clear( local.refreshTokenPayload.jti );

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
				"token was successfully refreshed",
				local.response
			);
		} catch ( any e ) {
			event.setHTTPHeader( statusCode = 400, statusText = "Bad Request" );
			return utilService.responseMessage( false, e.message );
		}
	}

}
