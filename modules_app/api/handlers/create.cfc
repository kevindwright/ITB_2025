component {

	property name="cbJwtService" inject="jwtService@cbsecurity";

    jwtStruct = {
            "iat": 1569340662,
            "scope": "",
            "iss": "http://127.0.0.1:56596/",
            "sub": 123,
            "exp": 1569344262,
            "jti": "12954F907C0535ABE97F761829C6BD11",
            "fname": "Kevin",
            "lname": "Wright",
            "user": "kwright",
        }

	function index( event, rc, prc ){
		event.noLayout()
		writeDump( cbJwtService.encode(jwtStruct));
		abort;
	}

}