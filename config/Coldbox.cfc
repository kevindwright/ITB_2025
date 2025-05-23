component {

	/**
	 * Configure the ColdBox App For Production
	 * https://coldbox.ortusbooks.com/getting-started/configuration
	 */
	function configure(){
		/**
		 * --------------------------------------------------------------------------
		 * ColdBox Directives
		 * --------------------------------------------------------------------------
		 * Here you can configure ColdBox for operation. Remember tha these directives below
		 * are for PRODUCTION. If you want different settings for other environments make sure
		 * you create the appropriate functions and define the environment in your .env or
		 * in the `environments` struct.
		 */
		coldbox = {
			// Application Setup
			appName                  : getSystemSetting( "APPNAME", "JWT API Demo" ),
			eventName                : "event",
			// Development Settings
			reinitPassword           : "",
			reinitKey                : "fwreinit",
			handlersIndexAutoReload  : true,
			// Implicit Events
			defaultEvent             : "",
			requestStartHandler      : "Main.onRequestStart",
			requestEndHandler        : "",
			applicationStartHandler  : "Main.onAppInit",
			applicationEndHandler    : "",
			sessionStartHandler      : "",
			sessionEndHandler        : "",
			missingTemplateHandler   : "",
			// Extension Points
			applicationHelper        : "includes/helpers/ApplicationHelper.cfm",
			viewsHelper              : "",
			modulesExternalLocation  : [],
			viewsExternalLocation    : "",
			layoutsExternalLocation  : "",
			handlersExternalLocation : "",
			requestContextDecorator  : "",
			controllerDecorator      : "",
			// Error/Exception Handling
			invalidHTTPMethodHandler : "",
			exceptionHandler         : "main.onException",
			invalidEventHandler      : "",
			customErrorTemplate      : "",
			// Application Aspects
			handlerCaching           : false,
			eventCaching             : false,
			viewCaching              : false,
			// Will automatically do a mapDirectory() on your `models` for you.
			autoMapModels            : true,
			// Auto converts a json body payload into the RC
			jsonPayloadToRC          : true
		};

		/**
		 * --------------------------------------------------------------------------
		 * Custom Settings
		 * --------------------------------------------------------------------------
		 */
		settings = {};

		/**
		 * --------------------------------------------------------------------------
		 * Environment Detection
		 * --------------------------------------------------------------------------
		 * By default we look in your `.env` file for an `environment` key, if not,
		 * then we look into this structure or if you have a function called `detectEnvironment()`
		 * If you use this setting, then each key is the name of the environment and the value is
		 * the regex patterns to match against cgi.http_host.
		 *
		 * Uncomment to use, but make sure your .env ENVIRONMENT key is also removed.
		 */
		// environments = { development : "localhost,^127\.0\.0\.1" };

		/**
		 * --------------------------------------------------------------------------
		 * Module Loading Directives
		 * --------------------------------------------------------------------------
		 */
		modules = {
			// An array of modules names to load, empty means all of them
			include : [],
			// An array of modules names to NOT load, empty means none
			exclude : []
		};

		/**
		 * --------------------------------------------------------------------------
		 * Application Logging (https://logbox.ortusbooks.com)
		 * --------------------------------------------------------------------------
		 * By Default we log to the console, but you can add many appenders or destinations to log to.
		 * You can also choose the logging level of the root logger, or even the actual appender.
		 */
		logBox = {
			// Define Appenders
			appenders : { coldboxTracer : { class : "coldbox.system.logging.appenders.ConsoleAppender" } },
			// Root Logger
			root      : { levelmax : "INFO", appenders : "*" },
			// Implicit Level Categories
			info      : [ "coldbox.system" ]
		};

		/**
		 * --------------------------------------------------------------------------
		 * Layout Settings
		 * --------------------------------------------------------------------------
		 */
		layoutSettings = { defaultLayout : "", defaultView : "" };

		/**
		 * --------------------------------------------------------------------------
		 * Custom Interception Points
		 * --------------------------------------------------------------------------
		 */
		interceptorSettings = { customInterceptionPoints : [] };

		/**
		 * --------------------------------------------------------------------------
		 * Application Interceptors
		 * --------------------------------------------------------------------------
		 * Remember that the order of declaration is the order they will be registered and fired
		 */
		interceptors = [];

		/**
		 * --------------------------------------------------------------------------
		 * Module Settings
		 * --------------------------------------------------------------------------
		 * Each module has it's own configuration structures, so make sure you follow
		 * the module's instructions on settings.
		 *
		 * Each key is the name of the module:
		 *
		 * myModule = {
		 *
		 * }
		 */
		moduleSettings = {
			cbauth : {
				// This is the path to your user object that contains the credential validation methods
				userServiceClass : "auth:userService@api"
			},
			cbsecurity : {
				validator             : "JwtAuthValidator@cbsecurity",
				// The WireBox ID of the authentication service to use in cbSecurity which must adhere to the cbsecurity.interfaces.IAuthService interface.
				authenticationService : "authenticationService@cbauth",
				// WireBox ID of the user service to use
				userService           : "",
				// The name of the variable to use to store an authenticated user in prc scope if using a validator that supports it.
				prcUserVariable       : "oCurrentUser",
				// JWT Settings
				jwt                   : {
					// The issuer authority for the tokens, placed in the `iss` claim
					issuer                     : "simple-coldbox-api",
					// The jwt secret encoding key, defaults to getSystemEnv( "JWT_SECRET", "" )
					// This key is only effective within the `config/Coldbox.cfc`. Specifying within a module does nothing.
					secretKey                  : fileRead( expandPath( getSystemSetting( "JWT_PRIVATE_KEY_PATH", "" ) ) ),
					// by default it uses the authorization bearer header, but you can also pass a custom one as well.
					customAuthHeader           : "x-auth-token",
					// The expiration in minutes for the jwt tokens
					expiration                 : 1,
					// If true, enables refresh tokens, token creation methods will return a struct instead
					// of just the access token. e.g. { access_token: "", refresh_token : "" }
					enableRefreshTokens        : true,
					// The default expiration (in minutes) for refresh tokens, defaults to 7 days (10080)
					refreshExpiration          : 15,
					// The Custom header to inspect for refresh tokens
					customRefreshHeader        : "x-refresh-token",
					// If enabled, the JWT validator will inspect the request for refresh tokens and expired access tokens
					// It will then automatically refresh them for you and return them back as
					// response headers in the same request according to the customRefreshHeader and customAuthHeader
					enableAutoRefreshValidator : false,
					// Enable the POST > /cbsecurity/refreshtoken API endpoint
					enableRefreshEndpoint      : true,
					// encryption algorithm to use, valid algorithms are: HS256, HS384, and HS512
					algorithm                  : "RS256",
					// Which claims neds to be present on the jwt token or `TokenInvalidException` upon verification and decoding
					requiredClaims             : [ "fingerprint" ],
					// The token storage settings
					tokenStorage               : {
						// enable or not, default is true
						"enabled"    : true,
						// A cache key prefix to use when storing the tokens
						"keyPrefix"  : "cbjwt_",
						// The driver to use: db, cachebox or a WireBox ID
						"driver"     : "cachebox",
						// Driver specific properties
						"properties" : { cacheName : "default" }
					}
				}
			}
		};

		/**
		 * --------------------------------------------------------------------------
		 * Flash Scope Settings
		 * --------------------------------------------------------------------------
		 * The available scopes are : session, client, cluster, ColdBoxCache, or a full instantiation CFC path
		 */
		flash = {
			scope        : "session",
			properties   : {}, // constructor properties for the flash scope implementation
			inflateToRC  : true, // automatically inflate flash data into the RC scope
			inflateToPRC : false, // automatically inflate flash data into the PRC scope
			autoPurge    : true, // automatically purge flash data for you
			autoSave     : true // automatically save flash scopes at end of a request and on relocations.
		};

		/**
		 * --------------------------------------------------------------------------
		 * App Conventions
		 * --------------------------------------------------------------------------
		 */
		conventions = {
			handlersLocation : "handlers",
			viewsLocation    : "views",
			layoutsLocation  : "layouts",
			modelsLocation   : "models",
			eventAction      : "index"
		};
	}

	/**
	 * Development environment
	 */
	function development(){
		// coldbox.customErrorTemplate = "/coldbox/system/exceptions/BugReport.cfm"; // static bug reports
		coldbox.customErrorTemplate = "/coldbox/system/exceptions/Whoops.cfm"; // interactive bug report
	}

}
