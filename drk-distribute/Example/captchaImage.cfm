<!---
	This file merely  uses cfcontent to send the Captcha
	image to the user and then delete the file.
	
	You will want to add additional protections on this 
	file to prevent malicious  users from passing in paths
	to other files.
--->

<cfcontent file="#expandPath(url.image)#.jpg"
	deletefile="yes" />