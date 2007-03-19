
<!---
	Create an application for the example.
	This is done so that we can store the instantiated captcha
	component in the application scope.
	
	You should not that this example does not demonstrate best
	practices with regards to locking shared variables!
--->
<cfapplication name="captchaExample" sessionmanagement="yes" />

<!---
	Create an instance of the captcha component and store it in
	the application scope.
--->
<cfif NOT IsDefined("application.myCaptcha")>
	<cfset application.myCaptcha = CreateObject("Component", "Captcha").configure(expandPath("."), "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX") />
</cfif>