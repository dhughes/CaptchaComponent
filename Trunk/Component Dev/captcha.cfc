<!------------------------------------------------------------------------------
Source Code Copyright © 2004 Alagad, Inc. www.alagad.com

  Application: Alagad Captcha Component 
  Supported CF Version: CF MX 6.1, BlueDragon 6.1 JX (or better)
  File Name: Captcha.cfc
  CFC Component Name: Captcha
  Created By: Doug Hughes (alagad@alagad.com)
  Created Date: Before 02/11/2005
  Description: I am a CFC which can be used to generate an image of an obfuscated string and a corresponding hash of the string.  Users of the component will be able to compare a user provided string with the hashed string.  If matched, then the developer can be reasonably sure that the user is a real person.

Version History:
  
 Created before 02/11/2005 by	D.Hughes
  
  mm/dd/yyyy	Author		Version		Comments
  02/11/2005	D.Hughes	1.1			Added setAllowedFontList() method as well as some failsafes when determining what font to use.
										Added setSpotsEnabled(), setContrast() and setInvert().
  08/30/2006	D.Hughes	1.2			Added init method and made getDirectory public.  also allowed for relative or absolute paths.
  
Comments:

  mm/dd/yyyy	Author		Comment
  
To Do:

  mm/dd/yyyy	Comment
  02/11/2005	Doucment setInvert().
  
------------------------------------------------------------------------------->

<cfcomponent displayname="Captcha" hint="I am a CFC which can be used to generate an image of an obfuscated string and a corresponding hash of the string.  Users of the component will be able to compare a user provided string with the hashed string.  If matched, then the developer can be reasonably sure that the user is a real person." output="no">

	<cfset variables.directory = "" />
	<cfset variables.licensed = false />
	<cfset variables.appText = "AlagadCaptcha*%Food!IsWhatyouMake(OF)it." />
	<cfset variables.charString = "0123456789ABCDEFGHJKLMNPQRTUVWXY" />
	<cfset variables.ignoredFontList = "" />
	<cfset variables.allowedFontList = "" />
	<cfset variables.spotsEnabled = true />
	<cfset variables.contrast = 0 />
	<cfset variables.invert = false />
	
	<cffunction name="configure" access="public" hint="I configure the Captcha CFC.  The directory argument must be provided. The key is optional.  I return myself correctly configured." output="false" returntype="Captcha">
		<cfargument name="directory" hint="I am the directory where captcha images will be written." required="yes" type="string" />
		<cfargument name="key" hint="I am the key used to unlock the software.  This will prevent the image from drawing Alagad Captcha across the image." required="no" default="" />
		
		<cfif NOT DirectoryExists(arguments.directory)>
			<cfset arguments.directory = ExpandPath(arguments.directory) />
		</cfif>
		
		<cfset setDirectory(arguments.directory) />
		<cfset setKey(arguments.key) />
		
		<cfreturn this />		
	</cffunction>
	
	<cffunction name="init" access="public" hint="I am a convenience method which simply calls configure." output="false" returntype="Captcha">
		<cfargument name="directory" hint="I am the directory where captcha images will be written." required="yes" type="string" />
		<cfargument name="key" hint="I am the key used to unlock the software.  This will prevent the image from drawing Alagad Captcha across the image." required="no" default="" />
		
		<cfreturn configure(arguments.directory, arguments.key) />		
	</cffunction>

	<cffunction name="createCaptcha" access="public" hint="I create a Captcha image.  I return a structure containing the hashed value of the string, the image name, and the string value." output="false" returntype="struct">
		<cfargument name="fileName" hint="If provided, I am the file name to write into the configured directory.  If not provided a unique file name will be generated." required="no" default="" />
		<cfargument name="string" hint="I am the string to use when creating the Captcha image.  You can easily pass in the results from calling createRandomString() or pass in your own string.  If this argument is not provided a 6 character random string will be used." required="no" default="" />
		<cfset var results = structNew() />
		<cfset var captchaString = 0 />

		<cfset var captchaStringMetrics = 0 />
		<cfset var Image = 0 />
		<cfset var fontsUsed = ArrayNew(1) />
		
		<!--- check to see if a file name has not been provided --->
		<cfif NOT Len(fileName)>
			<!--- it has not been provided, create a new name --->
			<cfset arguments.fileName = CreateUUID() & ".jpg" />
		</cfif>
		
		<!--- load the license if it exists in captchakey.txt --->
		<cfset loadLicenseFile() />
		
		<!--- check to see if the string has been provded --->
		<cfif NOT Len(string)>
			<!--- no string, create one --->
			<cfset arguments.string = createRandomString() />
		</cfif>
		
		<!--- if we are unlicensed then use the word "Unlicensed" --->
		<cfif NOT isLicensed()>
			<cfset arguments.string = "UNLICENSED" />
		</cfif>
		
		<!--- set the output filename into the results struct --->
		<cfset results.fileName = arguments.fileName />
		<!--- set the string being encoded into the results struct --->
		<cfset results.string = arguments.string />
		<!--- the hash encoding of the string --->
		<cfset results.hash = Hash(Ucase(results.string)) />
		<!--- the directory where the file was output --->
		<cfset results.directory = getDirectory() />
				
		<!--- create an attributed string --->
		<cfset captchaString = createString(arguments.string) />
		<!--- format the string --->
		<cfloop from="1" to="#Len(arguments.string)#" index="x">
			<cfset ArrayAppend(fontsUsed, randomCharStyle(captchaString, x -1)) />
		</cfloop>
		
		<!--- append the fonts used to the results --->
		<cfset results.fontsUsed = fontsUsed />
		
		<!--- get the randomly formatted string's metrics --->
		<cfset captchaStringMetrics = getStringMetrics(captchaString) />
		
		<!--- create the image with 6 extra pixels arround it. --->
		<cfset Image = createImage(captchaStringMetrics.width+6, captchaStringMetrics.Ascent + captchaStringMetrics.Descent + 6) />
		
		<!--- set a random background color --->
		<cfset clearBackground(Image) />
		
		<!--- draw spots on the background --->
		<cfif getSpotsEnabled()>
			<cfset drawSpots(Image) />
		</cfif>
		
		<!--- draw the string into the new image --->
		<cfset drawString(Image, captchaString, 3, captchaStringMetrics.Ascent + 3) />

		<!--- check to see if we need to invert the image --->
		<cfif getInvert()>
			<cfset Image = adjustLevels(Image, 255, 0) />
		</cfif>

		<!--- write the image to disk --->
		<cfset writeImage(Image, getDirectory() & arguments.fileName) />
		
		<!--- return the results --->
		<cfreturn results />
	</cffunction>
	
	<!--- loadLicenseFile --->
	<cffunction name="loadLicenseFile" access="private" output="false" returntype="void" hint="I check for the existance of (and contents of) captchakey.txt and load it as the license key, if it exists.">
		<cfset var cfcKey = getDirectoryFromPath(getCurrentTemplatePath()) & "captchakey.txt" />
		<cfset var key = "" />
		
		<!--- look for a file named captchakey.txt --->
		<cfif FileExists(cfcKey)>
			<!--- read the key file, if possible --->
			<cffile action="read"
				file="#cfcKey#"
				variable="key" />
			<!--- set the key (if not valid it won't be licensed) --->
			<cfset setKey(trim(key)) />
		</cfif>
	</cffunction>
	
	<!--- createRandomString --->
	<cffunction name="createRandomString" access="public" hint="I return a random string based on the provided attributes." output="false" returntype="string">
		<cfargument name="length" hint="I am the length of the random string to return." required="no" type="numeric" default="6" />
		<cfset var randomStringAllowedChars = "23456789ABCDEFGHJKLMNPQRTUVWXYabcdefghjkmnpqrtuvwxy" />
		<cfset var numRandomChars = Len(randomStringAllowedChars) />
		<cfset var x = 0 />
		<cfset var randomString = "" />
		
		<!--- create the random string --->
		<cfloop from="1" to="#arguments.length#" index="x">
			<cfset randomString = randomString & Mid(randomStringAllowedChars, RandRange(1, numRandomChars), 1) />
		</cfloop>
		
		<!--- return the random string --->
		<cfreturn randomString />
	</cffunction>
	
	
	
	<!--- adjustLevels --->
	<cffunction name="adjustLevels" access="private" output="false" returntype="any" hint="I adjust the contrast levels in the image.">
		<cfargument name="Image" hint="I am the Image to adjust." required="yes" type="any">
		<cfargument name="low" hint="I am the low value.  I must be between 0 and 255" required="yes" type="numeric">
		<cfargument name="high" hint="I am the high value.  I must be between 0 and 255" required="yes" type="numeric">
		<cfset var ArrayObj = CreateObject("Java", "java.lang.reflect.Array") />
		<cfset var Short = CreateObject("Java", "java.lang.Short") />
		<cfset var ArrayType = Short.TYPE />
		<cfset var ShortArray = ArrayObj.newInstance(ArrayType, 256) />
		<cfset var slope = (arguments.high - arguments.low) / 255  />
		<cfset var x1 = 0 />
		<cfset var y1 = arguments.low />
		<cfset var y = 0 />
		<cfset var x = 0 />
		
		<!--- verify arguments --->
		<cfif arguments.low LT 0 OR arguments.low GT 255>
			<cfthrow
				type="Alagad.Image.InvalidArgumentValue"
				message="Invalid low attribute.  The low attribute must be greater than or equal to 0 and less than or equal to 255." />
		</cfif>
		<cfif arguments.high LT 0 OR arguments.high GT 255>
			<cfthrow
				type="Alagad.Image.InvalidArgumentValue"
				message="Invalid high attribute.  The high attribute must be greater than or equal to 0 and less than or equal to 255." />
		</cfif>
		
		<cfloop from="0" to="255" index="x">
			<cfset x = int(x) />
			<cfset y = int(round((slope * (x - x1)) + y1)) />
			
			<cfset ArrayObj.setShort(ShortArray, Short.parseShort(JavaCast("string", x)), Short.parseShort(JavaCast("string", y))) />
		</cfloop>
		
		<cfreturn applyLookupTable(arguments.Image, ShortArray) />
	</cffunction>
		
	<!--- applyLookupTable --->
	<cffunction name="applyLookupTable" access="private" output="false" returntype="any" hint="I apply a lookup table to the image.">
		<cfargument name="Image" hint="I am the Image to adjust." required="yes" type="any">
		<cfargument name="lookupArray" hint="I am the array which populates the lookup table." required="yes" type="array" />
		<cfset var NewImage = createObject("java", "java.awt.image.BufferedImage") />
		<cfset var RenderingHints = CreateObject("Java", "java.awt.RenderingHints") />
		<cfset var LookupTable = CreateObject("Java", "java.awt.image.ShortLookupTable") />
		<cfset var LookupOp = CreateObject("Java", "java.awt.image.LookupOp") />
		
		<!--- we can't convolve indexed images --->
		<cfif arguments.Image.getType() IS arguments.Image.TYPE_BYTE_INDEXED>
			<cfthrow
				type="Alagad.Image.IndexedImageCanNotBeConvolved"
				message="Indexed images can not be convolved (adjustlevels, brighten, darken, etc.)" />
		</cfif>
		
		<cfscript>
			NewImage.init(JavaCast("int", arguments.Image.getWidth()), JavaCast("int", arguments.Image.getHeight()), JavaCast("int", arguments.Image.getType()));
			RenderingHints.init(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_DEFAULT);
			LookupTable.init(JavaCast("int", 0), arguments.lookupArray);
			LookupOp.init(LookupTable, RenderingHints);
			LookupOp.filter(arguments.Image, NewImage);
		</cfscript>

		<cfreturn NewImage />
	</cffunction>
		
	<!--- validate --->
	<cffunction name="validate" access="public" hint="I verify that a provided string is the correct value for the provided hash." output="false" returntype="boolean">
		<cfargument name="hash" hint="I am the hash returned by the createCaptcha() method." required="yes" type="string" />
		<cfargument name="string" hint="I am string provided by the user being tested." required="yes" type="string" />
		
		<cfreturn Hash(Ucase(arguments.string)) IS arguments.hash />		
	</cffunction>
		
	<!--- allowedFontList --->
    <cffunction name="setAllowedFontList" access="public" output="false" returntype="void">
       <cfargument name="allowedFontList" hint="I am a list of fonts which are allowed when creating random strings." required="yes" type="string" />
       <cfset variables.allowedFontList = trim(arguments.allowedFontList) />
    </cffunction>
    <cffunction name="getAllowedFontList" access="public" output="false" returntype="string">
       <cfreturn variables.allowedFontList />
    </cffunction>
	
	<!--- ignoredFontList --->
    <cffunction name="setIgnoredFontList" access="public" output="false" returntype="void">
       <cfargument name="ignoredFontList" hint="I am a list of fonts which are ignored when creating random strings." required="yes" type="string" />
       <cfset variables.ignoredFontList = arguments.ignoredFontList />
    </cffunction>
    <cffunction name="getIgnoredFontList" access="public" output="false" returntype="string">
       <cfreturn variables.ignoredFontList />
    </cffunction>
	
	<!--- spotsEnabled --->
    <cffunction name="setSpotsEnabled" access="public" output="false" returntype="void">
       <cfargument name="spotsEnabled" hint="I indicate if the component will draw random spots in the background to confuse OCR software." required="yes" type="boolean" />
       <cfset variables.spotsEnabled = arguments.spotsEnabled />
    </cffunction>
    <cffunction name="getSpotsEnabled" access="public" output="false" returntype="boolean">
       <cfreturn variables.spotsEnabled />
    </cffunction>
	
	<!--- contrast --->
    <cffunction name="setContrast" access="public" output="false" returntype="void">
       <cfargument name="contrast" hint="I control the amount of contrast in the captcha image.  Options are 0 to 100" required="yes" type="numeric" />
       <cfif arguments.contrast LT 0 OR arguments.contrast GT 100>
	     <cfthrow message="Invalid contrast setting.  Options are 0 to 100."
		 	type="alagad.captcha.invalidContrastSetting" />
	   </cfif>
	   <cfset variables.contrast = arguments.contrast />
    </cffunction>
    <cffunction name="getContrast" access="public" output="false" returntype="numeric">
       <cfreturn variables.contrast />
    </cffunction>
    <cffunction name="getContrastFloat" access="public" output="false" returntype="numeric">
       <cfreturn variables.contrast / 100 />
    </cffunction>
	
	<!----------
	//
	//	private methods
	//
	----------->
	
	<!--- writeImage --->
	<cffunction name="writeImage" access="private" output="false" returntype="void" hint="I write the image to disk.">
		<cfargument name="Image" hint="I am the image to draw into." required="yes" type="any" />
		<cfargument name="path" hint="I am the path of the file to write to." required="yes" type="string"/>
		<cfset var OutputStream = CreateObject("Java", "java.io.FileOutputStream") /> 
		<cfset var ImageIO = CreateObject("Java", "javax.imageio.ImageIO") />
		
		<!--- validate that the directory specified in path exists --->
		<cfif NOT DirectoryExists(getDirectoryFromPath(arguments.path))>
			<cfthrow message="Invalid path attribute.  The directory getDirectoryFromPath(arguments.path) does not exist or is not accessible." />
		</cfif>

		<cftry>
			<!--- output the file --->
			<cfset OutputStream.init(arguments.path) />
			<cfset ImageIO.write(arguments.Image, "JPG", OutputStream) />
		
			<cfcatch>
				<!--- close the output stream --->
				<cfset OutputStream.close() />
				<cfthrow message="There was an error writing the image to the #arguments.path#." />
			</cfcatch>		
		</cftry>
		
		<!--- flush and finalize the image --->
		<cfset Image.flush() />
				
		<!--- close the output stream --->
		<cfset OutputStream.close() />
	</cffunction>
	
	<!--- CreateImage --->
	<cffunction name="createImage" access="private" output="false" returntype="any" hint="I create a new image and return it.">
		<cfargument name="width" hint="I am the width of the image to create" required="yes" type="numeric" />
		<cfargument name="height" hint="I am the height of the image to create" required="yes" type="numeric" />
		<cfset var Image = CreateObject("java", "java.awt.image.BufferedImage") />
		<cfset var Graphics = 0 />
		
		<!--- validate width/height --->
		<cfif arguments.width LTE 0>
			<cfthrow message="Invalid width attribute.  The width attribute must be greater than 0." />
		</cfif>
		<cfif arguments.height LTE 0>
			<cfthrow message="Invalid height attribute.  The height attribute must be greater than 0." />
		</cfif>
		
		<!--- create the new image --->
		<cfset Image.init( JavaCast("int", arguments.width), JavaCast("int", arguments.height), JavaCast("int", Image.TYPE_INT_RGB) ) />
						
		<!--- return the new image --->
		<cfreturn Image />
	</cffunction>
	
	<!--- drawSpots --->
	<cffunction name="drawSpots" access="private" output="false" returntype="void" hint="I draw random circles on the background.">
		<cfargument name="Image" hint="I am the image to draw into." required="yes" type="any" />
		<cfset var Graphics = arguments.Image.getGraphics() />
		<cfset var x = 0 />
		<cfset var randColor = 0 />
		<cfset var RenderingHints = CreateObject("Java", "java.awt.RenderingHints") />
		
		<cfset RenderingHints.init(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON) />
		<!--- set the antialias settings --->
		<cfset Graphics.addRenderingHints(RenderingHints) />
		
		<cfloop from="1" to="#arguments.Image.getWidth()#" index="x">
			<cfif RandRange(1, 7) IS 5>
				<cfset randColor = createColor(RandRange(20, 255), RandRange(20, 255), RandRange(20, 255), RandRange(20, 100)) />
				<cfset Graphics.setPaint(randColor) />
				<cfset Graphics.fillOval(JavaCast("int", x), JavaCast("int", RandRange(1, arguments.Image.getHeight())), JavaCast("int", RandRange(10, 30)), JavaCast("int", RandRange(10, 30))) />
			</cfif>
		</cfloop>
	</cffunction>
	
	<!--- getStringMetrics --->
	<cffunction name="getStringMetrics" access="private" output="false" returntype="struct" hint="I return a structure of font metrics for the advanced string.">
		<cfargument name="AdvancedString" hint="I am the Advanced String to get the metrics of." required="yes" type="any" />
		<cfset var Image = CreateObject("Java", "java.awt.image.BufferedImage") />
		<cfset var Graphics = 0 />
		<cfset var TextLayout = CreateObject("Java", "java.awt.font.TextLayout") />
		<cfset var Iterator = 0 />
		<cfset var Bounds = 0 />
		<cfset var metrics = StructNew() />
		
		<!--- validate the advancedString --->
		<cfif NOT IsObject(arguments.advancedString) OR arguments.advancedString.getClass().getName() IS NOT "java.text.AttributedString" >
			<cfthrow message="The advancedString attribute must be an Advanced String Object." />
		</cfif>
		
		<!---
			init the "holder" image
			-- we don't want to have created an image just to get the size of text
			-- what if we wanted to create an image based on the size of some text?
		--->
		<cfset Image.init(JavaCast("int", 1), JavaCast("int", 1), JavaCast("int", Image.TYPE_INT_ARGB)) />
		<cfset Graphics = Image.getGraphics() />
				
		<!--- apply standard graphic settings
		<cfset applyGrapicsSettings(Graphics) /> --->
		
		<!--- get the itterator --->
		<cfset Iterator = arguments.AdvancedString.getIterator() />
		
		<!--- create a new textlayout to get the metrics of the string --->
		<cfset TextLayout.init(Iterator, Graphics.getFontRenderContext()) />
		
		<!--- get the font metrics --->
		<cfset Bounds = TextLayout.getBounds() />
		<cfset metrics.height = ceiling(Bounds.getHeight()) />
		<cfset metrics.width = ceiling(Bounds.getWidth()) />
		<cfset metrics.ascent = ceiling(TextLayout.getAscent()) />
		<cfset metrics.descent = ceiling(TextLayout.getDescent()) />
		<cfset metrics.leading = ceiling(TextLayout.getLeading()) />
		
		<cfreturn metrics />
	</cffunction>

	<!--- drawString --->
	<cffunction name="drawString" access="private" output="false" returntype="any" hint="I draw the advanced string onto the image.">
		<cfargument name="Image" hint="I am the image to draw into." required="yes" type="any" />
		<cfargument name="AdvancedString" hint="I am the Advanced String to draw." required="yes" type="any" />
		<cfargument name="x" hint="I am the x coordinate of the string baseline." required="yes" type="numeric" />
		<cfargument name="y" hint="I am the y coordinate of the string baseline." required="yes" type="numeric" />
		<cfset var Iterator = 0 />
		<cfset var Graphics = arguments.Image.getGraphics() />
		<cfset var RenderingHints = CreateObject("Java", "java.awt.RenderingHints") />
		
		<!--- validate the advancedString --->
		<cfif NOT IsObject(arguments.advancedString) OR arguments.advancedString.getClass().getName() IS NOT "java.text.AttributedString" >
			<cfthrow message="The advancedString attribute must be an Advanced String Object." />
		</cfif>
		
		<cfset RenderingHints.init(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON) />
		<!--- set the antialias settings --->
		<cfset Graphics.addRenderingHints(RenderingHints) />
		
		<!--- try to get the itterator --->
		<cftry>
			<cfset Iterator = arguments.AdvancedString.getIterator() />
			<cfcatch>
				<cfthrow message="Can not use drawString() before calling createString()." />
			</cfcatch>
		</cftry>
		
		<!--- output the string --->
		<cfset Graphics.drawString(Iterator, javaCast("int", arguments.x), javaCast("int", arguments.y)) />
	</cffunction>
		
	<!--- randomCharStyle --->
	<cffunction name="randomCharStyle" access="private" hint="I apply random string formatting." output="false" returntype="string">
		<cfargument name="captchaString" hint="I the attributed string to format." required="yes" type="Any" />
		<cfargument name="char" hint="I am the char to format" required="yes" type="numeric" />
		<cfset var randomFont = createRandomDisplayableFont(char) />
		
		<!--- create a random font which can display this character --->
		<cfset setStringFont(arguments.captchaString, randomFont, arguments.char, arguments.char + 1) />
		
		<!--- set a random foreground color --->
		<cfset setStringForeground(arguments.captchaString, createLightColor(), arguments.char, arguments.char + 1) />
		
		<cfreturn randomFont.getFamily() />
	</cffunction>
	
	<!--- createRandomDisplayableFont --->
	<cffunction name="createRandomDisplayableFont" access="private" returntype="Any" hint="I create a random font which can display the provided character.">
		<cfargument name="char" hint="I am the char to format" required="yes" type="numeric" />
		<cfargument name="recLevel" hint="I am the number of times this method has recursed." required="yes" type="numeric" default="0" />
		<cfset var Font = loadSystemFont(getRandomFontName(), RandRange(20, 40), getRandomFontStyle()) />
		<cfset var String = CreateObject("Java", "java.lang.String").init(JavaCast("string", char)) />
		<cfset var validFont = true />
		
		<!--- make sure the font is not disallowed --->
		<cfif ListFindNoCase( ListAppend(getIgnoredFontList(), "Mangal,Latha,Tunga,Estrangelo Edessa,Gautami,MV Boli,Raavi,Shruti,Symbol,Tunga,Webdings,Wingdings"), Font.getFamily() )>
			<cfset validFont = false />
		</cfif>
		
		<!--- make sure the font can display this character --->
		<cfif NOT Font.canDisplay(String.charAt(0))>
			<cfset validFont = false />
		</cfif>
		
		<!--- if the font's not valid, try again --->
		<cfif NOT validFont>
			<!--- only allow 10 times, then choose tnr --->
			<cfif recLevel LT 10>
				<cfset Font = createRandomDisplayableFont(arguments.char, recLevel+1) />
			<cfelse>
				<!--- if we're stuck in a recursive loop then break out and just use TNR --->
				<cfset Font = loadSystemFont("Times New Roman", RandRange(20, 40), getRandomFontStyle()) />
			</cfif>
		</cfif>
		
		<cfreturn Font />
	</cffunction>
	
	<!--- loadSystemFont --->
	<cffunction name="loadSystemFont"  access="private" output="false" returntype="any" hint="I load and return the specified system fonts.">
		<cfargument name="systemFontName" hint="I am the name of a system font as returned by getSystemFonts()" required="yes" type="string" />
		<cfargument name="size" hint="I am the size of the font." required="yes" type="numeric" />
		<cfargument name="style" hint="I am the style of the font.  Options: plain, bold, italic, boldItalic." required="no" type="string" default="plain" />
		<cfset var Font = CreateObject("Java","java.awt.Font") />
		
		<cfreturn Font.decode("#arguments.systemFontName#-#ucase(arguments.style)#-#arguments.size#") />
	</cffunction>
	
	<!--- clearBackground --->
	<cffunction name="clearBackground" access="private" output="false" returntype="void" hint="I clear the entire area of the image, setting it to a dark color.">
		<cfargument name="Image" hint="I am the image to draw into." required="yes" type="any" />
		<cfset var Graphics = arguments.Image.getGraphics() />
		
		<!--- check to see if we have a background color --->
		<cfset Graphics.setBackground(createDarkColor()) />
		
		<cfset Graphics.clearRect(JavaCast("int", 0), JavaCast("int", 0), JavaCast("int", arguments.Image.getWidth()), JavaCast("int", arguments.Image.getHeight())) />
	</cffunction>
	
	<!--- createDarkColor --->
	<cffunction name="createDarkColor" access="private" output="false" returntype="any" hint="I create a random dark color.">
		<!--- I need to create three numbers all less than 128 which, when added up, to total less than 255 --->
		<cfset var red = randRange(0, 128) * (1 - getContrastFloat()) />
		<cfset var green = randRange(0, 128) * (1 - getContrastFloat()) />
		<cfset var blue = randRange(0, 128) * (1 - getContrastFloat()) />
		<cfset var Color = 0 />
		
		<cfif red + green + blue LTE 255>
			<cfset Color = createColor(red, green, blue) />
		<cfelse>
			<cfset Color = createDarkColor() />
		</cfif>
		
		<cfreturn Color />		
	</cffunction>
	
	<!--- createLightColor --->
	<cffunction name="createLightColor" access="private" output="false" returntype="any" hint="I create a random light color.">
		<!--- I need to create three numbers all greater than 128 and less than 255 which, when added up, to total greater than 510 --->
		<cfset var red = 255 - (randRange(0, 128) * (1 - getContrastFloat())) />
		<cfset var green = 255 - (randRange(0, 128) * (1 - getContrastFloat())) />
		<cfset var blue = 255 - (randRange(0, 128) * (1 - getContrastFloat())) />
		<cfset var Color = 0 />
		
		<cfif red + green + blue GTE 510>
			<cfset Color = createColor(red, green, blue) />
		<cfelse>
			<cfset Color = createLightColor() />
		</cfif>
		
		<cfreturn Color />		
	</cffunction>
	
	<!--- createRandomColor
	<cffunction name="createRandomColor" access="private" output="false" returntype="any" hint="I create a random color.">
		<cfreturn createColor(RandRange(20, 255), RandRange(20, 255), RandRange(20, 255), RandRange(230, 255)) />
	</cffunction> --->
	
	<!--- createColor --->
	<cffunction name="createColor" access="private" output="false" returntype="any" hint="I create and return a color object.">
		<cfargument name="red" hint="I am the red value of the color.  Valid options are 0 to 255." required="yes" type="numeric" />
		<cfargument name="green" hint="I am the green value of the color.  Valid options are 0 to 255." required="yes" type="numeric" />
		<cfargument name="blue" hint="I am the blue value of the color.  Valid options are 0 to 255." required="yes" type="numeric" />
		<cfargument name="alpha" hint="I am the transparency of the color.  Valid options are 0 to 255.  255 = Opaque, 0 = Transparent." required="no" default="255" type="numeric" />
		<cfset var Color = CreateObject("Java", "java.awt.Color") />
		
		<!--- validate attributes --->
		<cfif NOT (arguments.red GTE 0 AND arguments.red LTE 255)>
			<cfthrow message="Invalid red attribute.  Valid options are 0 - 255" />
		</cfif> 
		<cfif NOT (arguments.green GTE 0 AND arguments.green LTE 255)>
			<cfthrow message="Invalid green attribute.  Valid options are 0 - 255" />
		</cfif> 
		<cfif NOT (arguments.blue GTE 0 AND arguments.blue LTE 255)>
			<cfthrow message="Invalid blue attribute.  Valid options are 0 - 255" />
		</cfif> 
		<cfif NOT (arguments.alpha GTE 0 AND arguments.alpha LTE 255)>
			<cfthrow message="Invalid alpha attribute.  Valid options are 0 - 255" />
		</cfif> 
		
		<cfset Color.init(JavaCast("int", arguments.red), JavaCast("int", arguments.green), JavaCast("int", arguments.blue), JavaCast("int", arguments.alpha)) />
		
		<cfreturn Color />
	</cffunction>
	
	<!--- invert --->
    <cffunction name="setInvert" access="public" output="false" returntype="void">
       <cfargument name="invert" hint="I indicate if the captcha image should be inverted to Dark on Light." required="yes" type="boolean" />
       <cfset variables.invert = arguments.invert />
    </cffunction>
    <cffunction name="getInvert" access="public" output="false" returntype="boolean">
       <cfreturn variables.invert />
    </cffunction>
	
	<!--- setStringBackground --->
	<cffunction name="setStringBackground" access="private" output="false" returntype="void" hint="I set advanced text background color.">
		<cfargument name="AdvancedString" hint="I am the Advanced String to format." required="yes" type="any" />
		<cfargument name="color" hint="I am the background color to use." type="any" required="yes" />
		<cfargument name="start" hint="I am the starting character for this style." type="numeric" required="no" default="-1" />
		<cfargument name="end" hint="I am the ending character for this style." type="numeric" required="no" default="-1" />
		<cfset var TextAttribute = CreateObject("Java", "java.awt.font.TextAttribute") />
		
		<cfif NOT IsObject(arguments.color) OR arguments.color.getClasS().getName() IS NOT "java.awt.Color" >
			<cfthrow message="The color attribute must be a Color object." />
		</cfif>		
		
		<cfset setTextAttribute(arguments.AdvancedString, TextAttribute.BACKGROUND, arguments.color, arguments.start, arguments.end) />
	</cffunction>
	
	<!--- setStringForeground --->
	<cffunction name="setStringForeground" access="private" output="false" returntype="void" hint="I set advanced text foreground color.">
		<cfargument name="AdvancedString" hint="I am the Advanced String to format." required="yes" type="any" />
		<cfargument name="color" hint="I am the foreground color to use." type="any" required="yes" />
		<cfargument name="start" hint="I am the starting character for this style." type="numeric" required="no" default="-1" />
		<cfargument name="end" hint="I am the ending character for this style." type="numeric" required="no" default="-1" />
		<cfset var TextAttribute = CreateObject("Java", "java.awt.font.TextAttribute") />
		
		<cfif NOT IsObject(arguments.color) OR arguments.color.getClasS().getName() IS NOT "java.awt.Color" >
			<cfthrow message="The color attribute must be a Color object." />
		</cfif>
		
		<cfset setTextAttribute(arguments.AdvancedString, TextAttribute.FOREGROUND, arguments.color, arguments.start, arguments.end) />
	</cffunction>
		
	<!--- setStringFont --->
	<cffunction name="setStringFont" access="private" output="false" returntype="void" hint="I set advanced text font based on a provided font.">
		<cfargument name="AdvancedString" hint="I am the Advanced String to format." required="yes" type="any" />
		<cfargument name="Font" hint="I am the Font object to use." type="any" required="yes" />
		<cfargument name="start" hint="I am the starting character for this style." type="numeric" required="no" default="-1" />
		<cfargument name="end" hint="I am the ending character for this style." type="numeric" required="no" default="-1" />
		<cfset var TextAttribute = CreateObject("Java", "java.awt.font.TextAttribute") />
		
		<!--- validate the font --->
		<cftry>
			<cfif (IsObject(arguments.Font) AND arguments.Font.getClass().getName() IS NOT "java.awt.Font") OR (NOT IsObject(arguments.Font) AND Len(arguments.Font))>
				<cfthrow message="Invalid Font attribute.  The Font attibute must be a Font object.  These can be loaded with loadSystemFont() or loadTTFFile()." />
			</cfif>
			<cfcatch>
				<cfthrow message="Invalid Font attribute.  The Font attibute must be a Font object.  These can be loaded with loadSystemFont() or loadTTFFile()." />
			</cfcatch>
		</cftry>
				
		<cfset setTextAttribute(arguments.AdvancedString, TextAttribute.FONT, arguments.Font, arguments.start, arguments.end) />
	</cffunction>
	
	<!--- setTextAttribute --->
	<cffunction name="setTextAttribute" access="private" output="false" returntype="void" hint="I set a given text attribute to the provided value.">
		<cfargument name="AdvancedString" hint="I am the Advanced String to set the attributes of." required="yes" type="any" />
		<cfargument name="attribute" hint="I am the attribute to set." type="any" required="yes" />
		<cfargument name="value" hint="I am the value for the attribute." type="any" required="yes" />
		<cfargument name="start" hint="I am the starting character for this style." type="numeric" required="yes" />
		<cfargument name="end" hint="I am the ending character for this style." type="numeric" required="yes" />
		<cfset var stringLen = arguments.AdvancedString.getIterator().getEndIndex() />
		
		<!--- validate the advancedString --->
		<cfif NOT IsObject(arguments.advancedString) OR arguments.advancedString.getClass().getName() IS NOT "java.text.AttributedString" >
			<cfthrow message="The AdvancedString attribute must be an Advanced String Object." />
		</cfif>
		
		<!--- validate start and end. --->
		<cfif arguments.start GT -1 AND arguments.end GT -1 AND	arguments.start GTE arguments.end>
			<cfthrow message="If the start and end attributes are provided they must both be greater than or equal to 0.  The end attribute must be greater than the start attribute.">
		</cfif>
		
		<!--- make sure start and end are both greater than or equal to 0 --->
		<cfif arguments.start LT 0 OR arguments.end LT 0>
			<cfthrow message="The start and end attributes must be greater than or equal to 0.">
		</cfif>
		
		<!--- make sure both elements are less than the string length --->
		<cfif arguments.start GT stringLen OR arguments.end GT stringLen>
			<cfthrow message="The start and end attributes must be less than or equal to the length of the string.">
		</cfif>
		
		<cfif arguments.start GT -1 AND arguments.end GT -1>
			<cfset arguments.AdvancedString.addAttribute(arguments.attribute, arguments.value, javaCast("int", arguments.start), javaCast("int", arguments.end)) />
		<cfelse>
			<cfset arguments.AdvancedString.addAttribute(arguments.attribute, arguments.value) />
		</cfif>
	</cffunction>
	
	<!--- getRandomFontStyle --->
	<cffunction name="getRandomFontStyle" access="private" hint="I return a random font style name." output="false" returntype="string">
		<cfswitch expression="#RandRange(1, 4)#">
			<cfcase value="1">
				<cfreturn "plain" />
			</cfcase>
			<cfcase value="2">
				<cfreturn "bold" />
			</cfcase>
			<cfcase value="3">
				<cfreturn "italic" />
			</cfcase>
			<cfcase value="4">
				<cfreturn "boldItalic" />
			</cfcase>
		</cfswitch>
	</cffunction>
	
	<!--- getRandomFontName --->
	<cffunction name="getRandomFontName" access="private" hint="I return a name of a random system font." output="false" returntype="string">
		<cfset var allowedFonts = ListToArray(getAllowedFontList()) />
		<cfset var fonts = 0 />
		<cfif ArrayLen(allowedFonts)>
			<cfset fonts = allowedFonts />
		<cfelse>
			<cfset fonts = getSystemFonts() />
		</cfif>

		<cfreturn trim(fonts[RandRange(1, ArrayLen(fonts))]) />
	</cffunction>
	
	<!--- getSystemFonts --->
	<cffunction name="getSystemFonts" access="private" output="false" returntype="array" hint="I return an array of all system fonts.">
		<cfset var GraphicsEnvironment = CreateObject("Java", "java.awt.GraphicsEnvironment") />
		<cfreturn GraphicsEnvironment.getLocalGraphicsEnvironment().getAvailableFontFamilyNames() />
	</cffunction>
	
	<!--- createString --->
	<cffunction name="createString" access="private" output="false" returntype="any" hint="I create and return a new Advanced String for advanced text formatting.">
		<cfargument name="string" hint="I am the string to use for advanced text formatting." required="yes" type="string">
		<cfset var newString = CreateObject("Java", "java.text.AttributedString") />
		<cfreturn newString.init(arguments.string) />
	</cffunction>
	
	<!--- key related --->
	<cffunction name="validateKey" access="private" output="false" returntype="boolean">
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

	<cffunction name="getKey" access="private" output="false" returntype="string">
		<cfargument name="initialChars" required="true" type="string" />
		<cfargument name="appText" required="true" type="string" />
		<cfset var md5String = "" />
		<cfset var key = "" />
		
		<!--- get a hash of the string --->
		<cfset md5String = hash(initialChars & arguments.appText) />
		<cfset key = arguments.initialChars />
		
		<!--- 
			Loop over the hash, grabing 2 chars on each look, convert them to base 10 and mod 32 the results.
			This value is the character in the list of valid chars we will be using for this char in the resulting key.
		--->
		<cfloop from="1" to="32" index="i" step="2">
			<cfset key = key & Mid(getCharString(), (InputBaseN(Mid(md5String, i, 2),16) Mod 32) + 1, 1) />
		</cfloop>
		
		<cfif Len(key) IS 25>
			<!--- add dashes --->
			<cfset key = Insert("-", key, 20) />
			<cfset key = Insert("-", key, 15) />
			<cfset key = Insert("-", key, 10) />
			<cfset key = Insert("-", key, 5) />
		</cfif>
		
		<cfreturn key />
	</cffunction>

	<!--- getFileSepeartor --->
	<cffunction name="getFileSeparator" access="private" output="false" returntype="string">
		<cfset var fileObj = createObject("java", "java.io.File") />
        <cfreturn fileObj.separator />
	</cffunction>

	<!--- directory --->
    <cffunction name="setDirectory" access="private" output="false" returntype="void">
       <cfargument name="directory" hint="I am the directory where captcha images will be written." required="yes" type="string" />
	   <!--- validate that the provided directory exists --->
	   <cfif NOT DirectoryExists(arguments.directory)>
	   	<cfthrow
			type="Alagad.Captcha.DirectoryDoesNotExist"
			message="The directory '#arguments.directory#' does not exist." />
	   </cfif>
	   
	   <!--- make sure directory has a trailing slash --->
	   <cfif Right(arguments.directory, 1) IS NOT getFileSeparator()>
	     <cfset arguments.directory = arguments.directory & getFileSeparator() />
	   </cfif>
	   
	   <cfset variables.directory = arguments.directory />
    </cffunction>
    <cffunction name="getDirectory" access="public" output="false" returntype="string">
       <cfreturn variables.directory />
    </cffunction>
		
	<!--- isLicensed --->
	<cffunction name="isLicensed" access="private" output="false" returntype="boolean">
		<cfreturn variables.licensed />
	</cffunction>

	<!--- key --->
    <cffunction name="setKey" access="private" output="false" returntype="void">
       <cfargument name="key" hint="I am the key used to unlock the software.  This will preven the image from drawing Alagad Captcha across the image." required="yes" type="string" />
	   
	   <!--- validate the key --->
	   <cfif validateKey(arguments.key, getAppText())>
	   	 <cfset variables.licensed = true />
	   <cfelse>
	     <cfset variables.licensed = false />
	   </cfif>
    </cffunction>
	
	<!--- appText --->
    <cffunction name="getAppText" access="private" output="false" returntype="string">
       <cfreturn variables.appText />
    </cffunction>
	
	<!--- charString --->
    <cffunction name="getCharString" access="private" output="false" returntype="string">
       <cfreturn variables.charString />
    </cffunction>
</cfcomponent>