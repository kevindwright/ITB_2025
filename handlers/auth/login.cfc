component extends="coldbox.system.EventHandler" {

	this.prehandler_only      = "";
	this.prehandler_except    = "";
	this.posthandler_only     = "";
	this.posthandler_except   = "";
	this.aroundHandler_only   = "";
	this.aroundHandler_except = "";
	this.allowedMethods       = {};

	function index( event, rc, prc ){
		prc.pageTitle = "Login";

		event.setView( "auth/login" );
	}

}

