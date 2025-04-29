/**
 * The main module handler
 */
component {

	property name="cbApplicationStorage" inject="applicationStorage@cbstorages";


	/**
	 * Module EntryPoint
	 */
	function index( event, rc, prc ){
		event.noLayout()
		writeDump( cbApplicationStorage.get( "DB" ) );
		abort;
	}

}
