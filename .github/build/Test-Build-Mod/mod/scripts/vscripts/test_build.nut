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

	NSHttpGet( "127.0.0.1:7274" )
}