component singleton {

	property name="cbApplicationStorage" inject="applicationStorage@cbStorages";

	function init(){
		return this;
	}

	boolean function isValidCredentials( required username, required password ){
		local.DB = cbApplicationStorage.get( "DB" );

		variables.username = arguments.username;
		variables.password = arguments.password;

		// Validate user login details
		local.validUser = local.DB.users.filter( function( user ){
			return user.getUsername() == variables.username && user.getPassword() == variables.password;
		} );
		if ( local.validUser.len() <= 0 ) {
			return false;
		}

		return true;
	}

	User function retrieveUserByUsername( required username ){
		local.DB = cbApplicationStorage.get( "DB" );

		variables.username = arguments.username;

		local.validUser = local.DB.users.filter( function( user ){
			return user.getUsername() == variables.username;
		} );
		return local.validUser[ 1 ];
	}

	User function retrieveUserById( required id ){
		local.DB = cbApplicationStorage.get( "DB" );

		variables.userId = arguments.id;

		local.validUser = local.DB.users.filter( function( user ){
			return user.getId() == variables.userId;
		} )[ 1 ];
		return local.validUser;
	}

	boolean function isValidFingerprint( required numeric id, required string fingerprint ){
		local.DB = cbApplicationStorage.get( "DB" );

		variables.userId              = arguments.id;
		variables.fingerprint         = arguments.fingerprint;
		variables.revokedFingerprints = local.DB[ "revoked_fingerprints" ];

		local.validUserFingerprint = local.DB.users.filter( function( user ){
			return user.getId() == variables.userId && user.getFingerprints().contains( variables.fingerprint ) && !variables.revokedFingerprints.contains(
				variables.fingerprint
			);
		} );

		return local.validUserFingerprint.len() > 0 ? true : false;
	}

	User function revokeFingerprint( required numeric id, required string fingerprint ){
		local.DB = cbApplicationStorage.get( "DB" );

		// Update DB with revoked fingerprint
		local.revokedFingerprints = local.DB[ "revoked_fingerprints" ];
		local.revokedFingerprints.append( arguments.fingerprint );
		local.DB[ "revoked_fingerprints" ] = local.revokedFingerprints
		cbApplicationStorage.set( "DB", local.DB );

		// Remove fingerprint from user
		return updateUser(
			arguments.id,
			"fingerprints",
			arguments.fingerprint,
			"remove"
		);
	}

	User function updateUser(
		required id,
		required string field,
		required string value,
		arrayUpdateType = "add"
	){
		local.DB = cbApplicationStorage.get( "DB" );

		variables.userId          = arguments.id;
		variables.field           = arguments.field;
		variables.value           = arguments.value;
		variables.arrayUpdateType = arguments.arrayUpdateType;

		local.updateDBUsers = local.DB.users.map( function( user ){
			if ( user.getId() == variables.userId ) {
				local.valueToUpdate       = variables.value
				local.getFieldValue       = invoke( user, "get" & ( variables.field ) );
				local.setFieldValueMethod = user[ "set" & ( variables.field ) ];
				if ( isArray( local.getFieldValue ) ) {
					local.valueToUpdate = local.getFieldValue;
					if ( variables.arrayUpdateType == "add" ) {
						local.valueToUpdate.append( variables.value );
					} else {
						arrayDeleteNoCase( local.valueToUpdate, variables.value );
					}
				}
				invoke(
					user,
					"set" & ( variables.field ),
					[ local.valueToUpdate ]
				)
			}
			return user;
		} )

		local.DB.users = local.updateDBUsers;
		cbApplicationStorage.set( "DB", local.DB );

		return local.DB.users.filter( function( user ){
			return user.getId() == variables.userId;
		} )[ 1 ];
	}

}
