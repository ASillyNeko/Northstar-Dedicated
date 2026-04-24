global function TestBuild_Init

void function TestBuild_Init()
{
	AddCallback_EntitiesDidLoad( TestBuild_SendRequest )
}

void function TestBuild_SendRequest()
{
	if ( !IsNewThread() )
	{
		thread TestBuild_SendRequest()
		return
	}
	else
		WaitEndFrame()

	if ( !GetConVarBool( "ns_convar_test" ) )
	{
		printt( "Failed to set ns_convar_test: ns_convar_test=" + GetConVarString( "ns_convar_test" ) )
		ServerCommand( "quit" )
	}

	if ( GetConVarString( "ns_convar_test_url" ) != "https://northstar.tf" )
	{
		printt( "Failed to set ns_convar_test_url: ns_convar_test_url=" + GetConVarString( "ns_convar_test_url" ) )
		ServerCommand( "quit" )
	}

	TestBuild_NavMesh()

	void functionref( HttpRequestResponse ) onSuccess = void function ( HttpRequestResponse response )
	{
		if ( NSIsSuccessHttpCode( response.statusCode ) )
		{
			// For testing locally
			#if DEV
				printt( "Success." )
				ServerCommand( "quit" )
			#else
				NSHttpGet( "127.0.0.1:7274" )
			#endif
		}
		else
		{
			printt( "Failed https request: response.statusCode=" + response.statusCode )
			ServerCommand( "quit" )
		}
	}

	void functionref( HttpRequestFailure ) onFailure = void function ( HttpRequestFailure response )
	{
		printt( "Failed https request." )
		ServerCommand( "quit" )
	}

	NSHttpGet( "https://www.githubstatus.com", {}, onSuccess, onFailure )
}

void function TestBuild_NavMesh()
{
	if ( !NavMesh_IsUpToDate() || GetAINScriptVersion() != AIN_REV || !GetNodeCount() )
	{
		printt( "Bad NavMesh/AIN: NavMesh_IsUpToDate=" + NavMesh_IsUpToDate() + " GetAINScriptVersion=" + GetAINScriptVersion() + " AIN_REV=" + AIN_REV + " GetNodeCount=" + GetNodeCount() )
		ServerCommand( "quit" )
	}

	entity titan = CreateNPCTitanFromSettings( GetAllowedPlayerTitanSettings()[0], TEAM_UNASSIGNED, Vector( 0, 0, 0 ), Vector( 0, 0, 0 ) )

	titan.SetOrigin( Vector( -752, 0, 96 ) )
	titan.SetInvulnerable()

	if ( !NavMesh_IsPosReachableForAI( titan, Vector( 752, 0, 96 ) ) )
	{
		printt( "Bad NavMesh: NavMesh_IsPosReachableForAI=" + NavMesh_IsPosReachableForAI( titan, Vector( 752, 0, 96 ) ) )
		ServerCommand( "quit" )
	}

	titan.Destroy()
}