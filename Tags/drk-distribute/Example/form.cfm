
<!---
	Use the instantiated Captcha component to generate a captcha image.
	
	Calling this method writes a captcha image to disk and returns
	information on the captcha image in the form of a struct.

	The returned structure contains the following nodes:
		directory	- this is the directory where images are written
		fileName	- this is the name of the generated file
		fontsUsed	- this is an array of the fonts used to create the image
		hash		- this is a hash of a lowercase version of the string displayed
		string		- this is the string displayed
--->
<cfset captcha = application.myCaptcha.createCaptcha() />

<!---
	We will be storing the hashed value in the user's session.
	You can also place this in a hidden form field.  However, that
	would make your form less secure.
--->
<cfset session.captchaHash = captcha.hash />

<html>
<head></head>
<body>
<!---
	This form is an example form which displays a captcha image to confirm
	that a humam is filling it out.  We will confirm the captcha text in 
	the validateForm.cfm file.
--->
<form name="form1" method="post" action="validateForm.cfm">
  <table border="0" cellspacing="0" cellpadding="4">
    <tr align="left" valign="top">
      <td>First Name:</td>
      <td><input name="firstName" type="text" size="30" maxlength="100"></td>
    </tr>
    <tr align="left" valign="top">
      <td>Last Name:</td>
      <td><input name="lastName" type="text" size="30" maxlength="100"></td>
    </tr>
    <tr align="left" valign="top">
      <td>Password:</td>
      <td><input name="password" type="password" size="30" maxlength="100"></td>
    </tr>
    <tr align="left" valign="top">
      <td>Enter the code shown:</td>
      <td>
	  	<!---
			In this section we provide a text field where the user will type the 
			string displayed in the captcha image.
		--->
	    <p>
          <input name="captchaText" type="text" size="30" maxlength="100">
          <br>
		  <!--- show some helpful text so the user knows what this is --->
          <span style="font-size: x-small;">This helps prevent automated submissions. </span></p>
        <p>
			<!--- 
				Although you can display the image files directly it is not suggested
				as it will make it harder to clean up old files.
				
				Alagad suggests using a .cfm file to send the image to the user.  In 
				this example a file named captchaImage.cfm is created.  It accepts a 
				URL variable "image" which is name of the created file without the JPG
				extension. 
				
				The extension  is removed as a security measure.  It is added back on in 
				the captchaImage.cfm file to prevent users from passing in arbitrary paths
				to files.
			--->
			<cfoutput>
				<img src="captchaImage.cfm?image=#ListFirst(captcha.filename, ".")#" />
			</cfoutput>
		</p></td>
    </tr>
    <tr align="left" valign="top">
      <td>&nbsp;</td>
      <td><input type="submit" name="Submit" value="Submit"></td>
    </tr>
  </table>
</form>
</body>
</html>
