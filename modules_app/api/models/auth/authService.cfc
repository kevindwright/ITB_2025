component singleton {

	property name="cbJwtService" inject="jwtService@cbsecurity";
	property name="utilService"  inject="utilService@api";

	authService function init(){
		return this;
	}

	function validateTokenType( struct decodedPayload, string tokenShouldBe = "access_token" ){
		var isRefresh       = decodedPayload.keyExists( "cbsecurity_refresh" ) && decodedPayload.cbsecurity_refresh;
		var shouldBeRefresh = ( tokenShouldBe == "refresh_token" );

		if ( isRefresh != shouldBeRefresh ) {
			throw(
				type    = "InvalidTokenType",
				message = "Invalid Token type",
				detail  = "The provided token is not a valid #tokenShouldBe#."
			);
		}
	}

	string function createJWE( required string accessToken, struct customJWEClaims = {} ){
		local.jwePayload = {
			"jwsToken" : arguments.accessToken,
			"exp"      : utilService.convertDateToUnixTimestamp(
				dateAdd(
					"s",
					cbJwtService.getSettings().jwt.expiration * 60,
					now()
				)
			)
		};

		// Overwrite jwePaylod with custom claims
		structAppend(
			local.jwePayload,
			arguments.customJWEClaims,
			true
		);

		local.payloadJSON  = serializeJSON( local.jwePayload );
		local.payloadBytes = charsetDecode( payloadJSON, "utf-8" );

		// Create Protected header
		local.header          = { "alg" : "RSA-OAEP", "enc" : "A256GCM" };
		local.headerJSON      = serializeJSON( local.header );
		local.headerBytes     = charsetDecode( local.headerJSON, "utf-8" );
		local.protectedHeader = utilService.base64UrlEncode( local.headerBytes );

		// Generate AES key + IV
		local.keyGen = createObject( "java", "javax.crypto.KeyGenerator" ).getInstance( "AES" );
		local.keyGen.init( 256 );
		local.aesKey = local.keyGen.generateKey();

		local.iv = createObject( "java", "java.security.SecureRandom" ).generateSeed( 12 );

		// Handle AES-GCM encryption with Java cipher directly
		local.cipher  = createObject( "java", "javax.crypto.Cipher" ).getInstance( "AES/GCM/NoPadding" );
		local.gcmSpec = createObject( "java", "javax.crypto.spec.GCMParameterSpec" ).init( 128, local.iv );
		local.cipher.init(
			cipher.ENCRYPT_MODE,
			local.aesKey,
			local.gcmSpec
		);
		local.cipher.updateAAD( local.headerBytes );
		local.encryptedBytes = cipher.doFinal( local.payloadBytes );

		// Split ciphertext + tag
		local.totalLen = arrayLen( local.encryptedBytes );
		local.tagLen   = 16;

		local.ciphertextBytes = arraySlice(
			local.encryptedBytes,
			1,
			local.totalLen - local.tagLen
		);
		local.tagBytes = arraySlice(
			local.encryptedBytes,
			local.totalLen - local.tagLen + 1,
			local.tagLen
		);

		// Encrypt AES key with RSA public key
		local.pemKey     = utilService.getPublicKey();
		local.cleanedKey = local.pemKey
			.replace( "-----BEGIN PUBLIC KEY-----", "" )
			.replace( "-----END PUBLIC KEY-----", "" )
			.replace( chr( 10 ), "" )
			.replace( chr( 13 ), "" );
		local.decodedKey = binaryDecode( local.cleanedKey, "base64" );

		local.keySpec    = createObject( "java", "java.security.spec.X509EncodedKeySpec" ).init( decodedKey );
		local.keyFactory = createObject( "java", "java.security.KeyFactory" ).getInstance( "RSA" );
		local.publicKey  = keyFactory.generatePublic( local.keySpec );

		local.rsaCipher = createObject( "java", "javax.crypto.Cipher" ).getInstance( "RSA/ECB/OAEPWithSHA-256AndMGF1Padding" );
		local.rsaCipher.init( local.rsaCipher.ENCRYPT_MODE, local.publicKey );
		local.encryptedAESKey = local.rsaCipher.doFinal( aesKey.getEncoded() );

		// Base64URL encode all components
		local.jweToken = local.protectedHeader & "." &
		utilService.base64UrlEncode( utilService.javaBytesToCFBinary( local.encryptedAESKey ) ) & "." &
		utilService.base64UrlEncode( utilService.javaBytesToCFBinary( local.iv ) ) & "." &
		utilService.base64UrlEncode( utilService.javaBytesToCFBinary( local.ciphertextBytes ) ) & "." &
		utilService.base64UrlEncode( utilService.javaBytesToCFBinary( local.tagBytes ) );

		return local.jweToken;
	}

	struct function decryptJWE( required string jweToken ){
		try {
			// Split the token into 5 parts
			local.parts = listToArray( arguments.jweToken, "." );
			if ( arrayLen( local.parts ) NEQ 5 ) {
				throw( type = "InvalidTokenFormat", message = "JWE token must have 5 parts." );
			}

			local.protectedB64    = parts[ 1 ];
			local.encryptedKeyB64 = parts[ 2 ];
			local.ivB64           = parts[ 3 ];
			local.ciphertextB64   = parts[ 4 ];
			local.tagB64          = parts[ 5 ];

			// Decode all base64url parts
			local.protectedHeaderBytes = utilService.base64UrlDecode( local.protectedB64 );
			local.encryptedAESKeyBytes = utilService.base64UrlDecode( local.encryptedKeyB64 );
			local.ivBytes              = utilService.base64UrlDecode( local.ivB64 );
			local.ciphertextBytes      = utilService.base64UrlDecode( local.ciphertextB64 );
			local.tagBytes             = utilService.base64UrlDecode( local.tagB64 );

			// 4. Load and decode RSA private key
			local.pemPrivateKey = utilService.getPrivateKey();
			local.cleanedKey    = local.pemPrivateKey
				.replace( "-----BEGIN PRIVATE KEY-----", "" )
				.replace( "-----END PRIVATE KEY-----", "" )
				.replace( chr( 10 ), "" )
				.replace( chr( 13 ), "" );

			local.decodedKey = binaryDecode( local.cleanedKey, "base64" );

			// Reconstruct Private Key
			local.keySpec = createObject( "java", "java.security.spec.PKCS8EncodedKeySpec" ).init(
				local.decodedKey
			);
			local.keyFactory = createObject( "java", "java.security.KeyFactory" ).getInstance( "RSA" );
			local.privateKey = local.keyFactory.generatePrivate( local.keySpec );

			// Decrypt the AES key using RSA private key
			local.rsaCipher = createObject( "java", "javax.crypto.Cipher" ).getInstance( "RSA/ECB/OAEPWithSHA-256AndMGF1Padding" );
			local.rsaCipher.init( local.rsaCipher.DECRYPT_MODE, local.privateKey );
			local.aesKeyBytes   = local.rsaCipher.doFinal( local.encryptedAESKeyBytes );
			local.secretKeySpec = createObject( "java", "javax.crypto.spec.SecretKeySpec" ).init(
				local.aesKeyBytes,
				"AES"
			);

			// Combine ciphertext + tag
			local.baos = createObject( "java", "java.io.ByteArrayOutputStream" );
			local.baos.write( local.ciphertextBytes );
			local.baos.write( local.tagBytes );
			local.combinedEncryptedBytes = local.baos.toByteArray();

			// Decrypt with AES/GCM
			local.cipher  = createObject( "java", "javax.crypto.Cipher" ).getInstance( "AES/GCM/NoPadding" );
			local.gcmSpec = createObject( "java", "javax.crypto.spec.GCMParameterSpec" ).init( 128, local.ivBytes );
			local.cipher.init(
				local.cipher.DECRYPT_MODE,
				local.secretKeySpec,
				local.gcmSpec
			);
			local.cipher.updateAAD( local.protectedHeaderBytes );

			local.decryptedPayloadBytes = cipher.doFinal( local.combinedEncryptedBytes );
			local.payloadJSON           = charsetEncode( local.decryptedPayloadBytes, "utf-8" );

			local.originalPayload = deserializeJSON( local.payloadJSON );
			return local.originalPayload;
		} catch ( any e ) {
			throw( "Unable to decrypt JWE" )
		}
	}

	function decodeJWT( token = cbJwtService.discoverToken() ){
		local.jwtPublicKey = utilService.getPublicKey();
		try {
			// try to decode the token. Will fail if not a JWS token
			local.jwtPayload = cbJwtService.getJwt().decode( arguments.token, local.jwtPublicKey, "RS256" );
		} catch ( any e ) {
			// If fails, first decrypt the token (most likely JWE), then decode
			local.jwePayload = decryptJWE( arguments.token );
			local.jwtPayload = cbJwtService
				.getJwt()
				.decode(
					local.jwePayload.jwsToken,
					local.jwtPublicKey,
					"RS256"
				);
		}

		return local.jwtPayload
	}

	function authenticateUser(){
		local.jwtPayload = decodeJWT();
		
		if ( !cbJwtService.getTokenStorage().exists( local.jwtPayload.jti ) ) {
			throw(
				message = "Token has expired, not found in storage",
				detail  = "Storage lookup failed",
				type    = "TokenRejectionException"
			);
		}

		// Token should be a access token
		validateTokenType( local.jwtPayload, "access_token" );

		local.authUser = cbJwtService.authenticate( local.jwtPayload );

		return local.authUser.getUserDetails();
	}

}
