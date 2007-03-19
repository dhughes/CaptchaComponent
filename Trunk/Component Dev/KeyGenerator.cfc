<cfcomponent displayname="KeyGenerator" hint="I create a software keys based on a string and can validate them too." output="no">

	<cfset variables.charString = "0123456789ABCDEFGHJKLMNPQRTUVWXY" />
	
	<cffunction name="getKey" access="private" output="false" returntype="string">
		<cfargument name="initialChars" required="true" type="string" />
		<cfargument name="appText" required="true" type="string" />
		<cfset var md5String = "" />
		<cfset var key = "" />
		
		<!--- get a hash of the string --->
		<cfset md5String = hash(initialChars & arguments.appText) />
		<cfset key = arguments.initialChars />
		
		<!--- 
			Loop over the has, grabing 2 chars on each look, convert them to base 10 and mod 32 the results.
			This value is the character in the list of valid chars we will be using for this char in the resulting key.
		--->
		<cfloop from="1" to="32" index="i" step="2">
			<cfset key = key & Mid(variables.charString, (InputBaseN(Mid(md5String, i, 2),16) Mod 32) + 1, 1) />
		</cfloop>
	
		<!--- add dashes --->
		<cfset key = Insert("-", key, 20) />
		<cfset key = Insert("-", key, 15) />
		<cfset key = Insert("-", key, 10) />
		<cfset key = Insert("-", key, 5) />
		
		<cfreturn key />
	</cffunction>
	
	<cffunction name="generateKey" access="public" output="false" returntype="string">
		<cfargument name="appText" required="true" type="string" />
		<cfset var i = 0 />
		<cfset var initialChars = "" />
		
		<!--- seed the random number generator --->
		<cfset Randomize(GetTickCount()/10000)>
		
		<!--- generate nine random caracters that are all members of charString --->
		<cfloop from="1" to="9" index="i">
			<cfset initialChars = initialChars & Mid(variables.charString, RandRange(1, 32), 1) />
		</cfloop>
		
		<!--- get a hash of the string --->
		<cfreturn getKey(initialChars, arguments.appText) />
	</cffunction>
	
	<cffunction name="validateKey" access="public" output="false" returntype="boolean">
		<cfargument name="key" required="true" type="string" />
		<cfargument name="appText" required="true" type="string" />
		<cfset var initialChars = "" />
		
		<!--- fix the key (remove all hyphens) --->
		<cfset arguments.key = Replace(arguments.key, "-", "", "all") />
	
		<!--- grab the first 9 chars --->
		<cfset initialChars = Left(arguments.key, 9) />
			
		<!--- get a key and compare to our current key  --->
		<cfreturn Replace(getKey(initialChars, arguments.appText), "-", "", "all") IS arguments.key />
	</cffunction>
</cfcomponent>