
<!--- 
	This file validates the information provided by the user in form.cfm.
	
	It pulls the Captcha object from the application scope and calls its
	validate() method.  The value of the Captcha Hash stored in the user's
	session as well as well as the provided Captcha Text from form.com.
	If the text is correct then the method returns true and we see a
	confirmation message. If text does not match we see an error message.
--->

<cfif application.myCaptcha.validate(session.captchaHash, form.captchaText)>
	<h3>Captcha Is Correct!</h3>
<cfelse>
	<h3>Captcha Is Not Correct!</h3>
</cfif>