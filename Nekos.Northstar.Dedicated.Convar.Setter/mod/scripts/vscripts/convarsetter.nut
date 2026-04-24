untyped

global function ConvarSetter_Init

void function ConvarSetter_Init()
{
	if ( GetConVarBool( "changed_convars" ) )
		return

	foreach ( string convar, string value in northstar_dedicated_convars )
	{
		try
		{
			SetConVarString( convar, value )
		}
		catch ( error ) {}
	}

	SetConVarBool( "changed_convars", true )
}