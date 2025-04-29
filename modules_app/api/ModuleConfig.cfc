/**
 * Module Directives as public properties
 *
 * this.title 				= "Title of the module";
 * this.author 			= "Author of the module";
 * this.webURL 			= "Web URL for docs purposes";
 * this.description 		= "Module description";
 * this.version 			= "Module Version";
 * this.viewParentLookup   = (true) [boolean] (Optional) // If true, checks for views in the parent first, then it the module.If false, then modules first, then parent.
 * this.layoutParentLookup = (true) [boolean] (Optional) // If true, checks for layouts in the parent first, then it the module.If false, then modules first, then parent.
 * this.entryPoint  		= "" (Optional) // If set, this is the default event (ex:forgebox:manager.index) or default route (/forgebox) the framework will use to create an entry link to the module. Similar to a default event.
 * this.cfmapping			= "The CF mapping to create";
 * this.modelNamespace		= "The namespace to use for registered models, if blank it uses the name of the module."
 * this.dependencies 		= "The array of dependencies for this module"
 *
 * structures to create for configuration
 * - parentSettings : struct (will append and override parent)
 * - settings : struct
 * - interceptorSettings : struct of the following keys ATM
 * 	- customInterceptionPoints : string list of custom interception points
 * - interceptors : array
 * - layoutSettings : struct (will allow to define a defaultLayout for the module)
 * - wirebox : The wirebox DSL to load and use
 *
 * Available objects in variable scope
 * - controller
 * - appMapping (application mapping)
 * - moduleMapping (include,cf path)
 * - modulePath (absolute path)
 * - log (A pre-configured logBox logger object for this object)
 * - binder (The wirebox configuration binder)
 * - wirebox (The wirebox injector)
 *
 * Required Methods
 * - configure() : The method ColdBox calls to configure the module.
 *
 * Optional Methods
 * - onLoad() 		: If found, it is fired once the module is fully loaded
 * - onUnload() 	: If found, it is fired once the module is unloaded
 **/
component {

	// Module Properties
	this.title              = "api";
	this.author             = "";
	this.webURL             = "";
	this.description        = "";
	this.version            = "1.0.0";
	// If true, looks for views in the parent first, if not found, then in the module. Else vice-versa
	this.viewParentLookup   = true;
	// If true, looks for layouts in the parent first, if not found, then in module. Else vice-versa
	this.layoutParentLookup = true;
	// Module Entry Point
	this.entryPoint         = "api";
	// Inherit Entry Point
	this.inheritEntryPoint  = false;
	// Model Namespace
	this.modelNamespace     = "api";
	// CF Mapping
	this.cfmapping          = "";
	// Auto-map models
	this.autoMapModels      = true;
	// Module Dependencies
	this.dependencies       = [ "cbstorages" ];

	/**
	 * Configure the module
	 */
	function configure(){
		// parent settings
		parentSettings = {};

		// module settings - stored in modules.name.settings
		settings = {}

		// Layout Settings
		layoutSettings = { defaultLayout : "" };

		// Custom Declared Points
		interceptorSettings = { customInterceptionPoints : [] };

		// Custom Declared Interceptors
		interceptors = [];

		// Binder Mappings
		// Seems models in modules need to be called like this userService@api even if the model is selfcontained. Using the below code would map the name directly.
		// Advisable not to map and use the deault userService@api
		// binder.map("userService").to("#moduleMapping#.models.userService");

		// binder.map("Alias").to("#moduleMapping#.models.MyService");
	}

	/**
	 * Fired when the module is registered and activated.
	 */
	function onLoad(){
		local.cbApplicationStorage = wirebox.getInstance( "applicationStorage@cbstorages" );

		local.mockUsers = [
			{
				id           : 1,
				firstName    : "Admin",
				lastName     : "Admin",
				username     : "admin",
				password     : "123",
				roles        : [ "admin" ],
				fingerprints : []
			},
			{
				id           : 2,
				firstName    : "Kevin",
				lastName     : "Wright",
				username     : "kevin",
				password     : "CB123",
				roles        : [ "user" ],
				fingerprints : []
			}
		];
		users = [];
		for ( mockUser in local.mockUsers ) {
			local.oUser = wirebox.getInstance( "user:User@api" );
			local.user  = local.oUser
				.setId( mockUser.id )
				.setFirstName( mockUser.firstName )
				.setLastName( mockUser.lastName )
				.setUsername( mockUser.username )
				.setPassword( mockUser.password )
				.setRoles( mockUser.roles );
			arrayAppend( users, user );
		}

		local.DB = { users : users, revoked_fingerprints : [] };
		local.cbApplicationStorage.set( "DB", local.DB );
	}

	/**
	 * Fired when the module is unregistered and unloaded
	 */
	function onUnload(){
		local.cbApplicationStorage = wirebox.getInstance( "applicationStorage@cbstorages" );
		local.cbApplicationStorage.delete( "DB" );
	}

}
