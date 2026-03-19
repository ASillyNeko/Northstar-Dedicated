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

	void functionref( HttpRequestResponse ) onSuccess = void function ( HttpRequestResponse response )
	{
		if ( NSIsSuccessHttpCode( response.statusCode ) )
		{
			NSHttpGet( "127.0.0.1:7274" )
		}
		else
		{
			printt( "Github ping request failed." )
			ServerCommand( "quit" )
		}
	}

	void functionref( HttpRequestResponse ) onFailure = void function ( HttpRequestResponse response )
	{
		printt( "Github ping request failed." )
		ServerCommand( "quit" )
	}

	NSHttpGet( "https://www.githubstatus.com/", {}, onSuccess, onFailure )
}