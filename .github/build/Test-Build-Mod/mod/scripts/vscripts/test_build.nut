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
		printt( "Failed to set ns_convar_test: " + GetConVarString( "ns_convar_test" ) )
		ServerCommand( "quit" )
	}

	if ( GetConVarString( "ns_convar_test_url" ) != "https://northstar.tf" )
	{
		printt( "Failed to set ns_convar_test_url: " + GetConVarString( "ns_convar_test_url" ) )
		ServerCommand( "quit" )
	}

	void functionref( HttpRequestResponse ) onSuccess = void function ( HttpRequestResponse response )
	{
		if ( NSIsSuccessHttpCode( response.statusCode ) )
		{
			NSHttpGet( "127.0.0.1:7274" )
		}
		else
		{
			printt( "Failed https request: " + response.statusCode )
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