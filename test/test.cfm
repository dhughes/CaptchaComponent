<cfset captcha = CreateObject("component", "Captcha.Captcha").configure(expandPath("."))  />

<cfset captcha.setAllowedFontList("Gloucester MT Extra Condensed, Footlight MT Light, Century Schoolbook,Bodoni MT") />
<cfset captcha.setSpotsEnabled(false) />

<cfset captcha.setContrast(50) />

<cfset captchaResults = captcha.createCaptcha("blarg.foo") />

<p><b>Captcha Image:<br></b>
<cfoutput>
<img src="#captchaResults.fileName#" />
</cfoutput>
</p>

<p><b>Captcha Structure:<br></b>
<cfdump var="#captchaResults#" />
</p>

