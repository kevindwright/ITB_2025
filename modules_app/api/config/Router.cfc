/**
 * Module Router
 * https://coldbox.ortusbooks.com/the-basics/routing/routing-dsl
 */
component {

	function configure(){
		route( "/", "main.index" );

		post( "/auth/login", "auth.login" )
		post( "/auth/refresh-token", "auth.refreshToken" )
		post( "/auth/logout", "auth.logout" )

		get( "/user/profile", "user.profile" )
	}

}
