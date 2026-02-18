<%--

				Problem No		Correction Date		Changed By
				----------		---------------		----------
				EG10-0004       20/07/2021          SAHIL BHURIA

--%>
<%@page import="java.util.*,java.math.*,com.newgen.eworkstyle.supportbeans.*,com.newgen.eworkstyle.mapdb.*,java.net.URLEncoder,org.apache.commons.lang3.StringEscapeUtils,java.security.*,com.newgen.omni.wf.util.app.NGEjbClient,java.net.*,java.text.SimpleDateFormat,com.newgen.dmsapi.*,com.newgen.omni.wf.util.excp.NGException,org.apache.commons.io.FileUtils,org.apache.commons.lang.*,java.io.*,com.newgen.omni.egov.common.*,com.google.common.html.HtmlEscapers,Component.ComponentInit,JSON.JSONObject" pageEncoding="UTF-8" errorPage="errorpage.jsp"%>
<%@ page import="static com.newgen.egov.common.CommonFunctions.*"%>
<jsp:useBean id="sessionBean" class="com.newgen.eworkstyle.supportbeans.EWSessionBean" scope="session"/>
<jsp:useBean id="egovSessionBean" class="com.newgen.egov.EgovSession" scope="session"/>
<%@ page import="com.newgen.logger.EgovLogger"%>
<%
String  egovUID = egovSessionBean.getegovUID();
if(egovUID == null || egovUID.equals("") || egovUID.equalsIgnoreCase("null")){	
	egovUID = sessionBean.MakeUniqueNumber();	
	egovSessionBean.setegovUID(egovUID);
}
else{
	
}

%>

<%!
	NGEjbClient mobjNGEjbClient;
	String serverIp="";
	String serverport="";
	String serverType="";
	String userIndexOut = "";
	
	String dashboardReport1Data = "";
	String dashboardReport2Data = "";
	String dashboardReport3Data = "";
	String ipXml 			= "";
	String retXml 			= "";
	
	//method added by Priyanka to encrypt session ID to be used with OmniDocs external URL on OD 11 SP2: EG2024-060
	//Commented by Priyanshu Sharma for Go to omnidocs issue
	/*public String getEncryptedUserDbId(EWSessionBean sessionBean,String tokenValue, String cabinetName)
	{
		String outputXml = null;
		
		String encInXml = "<?xml version=\"1.0\"?><NGOManageToken_Input><Option>NGOManageToken</Option><CabinetName>"+cabinetName+"</CabinetName><TokenValue>"+tokenValue+"</TokenValue><ActionFlag>G</ActionFlag></NGOManageToken_Input>"; //ActionFlag G is used to encrypt the TokenValue, ActionFlag D is used to decrypt the TokenValue

		String encUserdbid = "";
		
		try
		{
			String encOutXml = sessionBean.execute(encInXml);
			DMSXmlResponse encOutResp = new DMSXmlResponse(encOutXml);
			String statusCode = encOutResp.getVal("Status");
	
			if("0".equalsIgnoreCase(statusCode)){
				encUserdbid = encOutResp.getVal("TokenValue");
			}
		}
		catch(Exception e){
			System.out.println("Exception caught while encrypting userdbid " + e.getMessage());
			e.printStackTrace();
		}
		return encUserdbid;
	}*/
	
	
	//Added by Nikita.Patidar for checking Rights for DAK folders(EG4-0012)
	public String getRightsOnObject(EWSessionBean sessionBean,String ObjectType, String ObjectIndex,String UserGroupName )throws Exception
	{
		
		String rightsOutputXml= "";
		String finalRightsString="";
		DMSInputXml rightsInputXml =new DMSInputXml();
		
		rightsOutputXml = sessionBean.execute(rightsInputXml.getGetRightsXml(sessionBean.getCabinetName(),sessionBean.getUserDbId(),ObjectType, ObjectIndex));
		
		DMSXmlResponse rightsResponse = new DMSXmlResponse(rightsOutputXml);
		
		if(Integer.parseInt(rightsResponse.getVal("Status"))==0){
			DMSXmlList rightsList = rightsResponse.createList("UserGroupACLs", "UserGroupACL");
			for (rightsList.reInitialize(true); rightsList.hasMoreElements(true); rightsList.skip(true)){
					
					if(rightsList.getVal("UserGroupName").equalsIgnoreCase(UserGroupName))
					{
						finalRightsString=rightsList.getVal("Rights");
						break;
					}else if(rightsList.getVal("UserGroupName").equalsIgnoreCase("Everyone"))
					{
						finalRightsString=rightsList.getVal("Rights");
					}else{
						finalRightsString="";
					}
					
			}
		}	
	
		return finalRightsString;
	}	
	
	//Changes done by Nikita.Patidar for Notifications count Configuration(CQRN-136930)
	public void updateCounterForNotification(EWSessionBean sessionBean,Properties dbQueryCC)
	{
		try{
		String sQueryString = dbQueryCC.getProperty("QRCN21");
		sQueryString=EGovAPI.getPreparedQuery(sQueryString,new Integer(sessionBean.getLoggedInUser().getUserIndex()).toString()+"\u0004int");
		
		
		if(sQueryString.equalsIgnoreCase("Arguments mismatch"))
		{    
			EgovLogger.writeLog(sessionBean.getCabinetName(),'i', "In office.jsp -- QRCN21=" + sQueryString);
			sQueryString="";
		}
		DMSXmlResponse counterUpdate = executeCommonQuery(sessionBean.getCabinetName(), sessionBean.getUserDbId(), sQueryString, "IGSetPreparedData","preparedStmt")    ; 
		
		}
		catch(Exception ex)
		{
			ex.printStackTrace();
		}
	}
	//Changes end by Nikita.Patidar for Notifications count Configuration(CQRN-136930)
%>

<%
	String strEncoding = ((java.util.ResourceBundle)session.getAttribute("genRSB")).getString("Encoding");
	request.setCharacterEncoding(strEncoding);
	response.setContentType("text/html;charset="+strEncoding);		
	serverIp=sessionBean.getIniValue("webserverhost","127.0.0.1");
	serverport=sessionBean.getIniValue("jndiport","1099");
	serverType=sessionBean.getIniValue("servertype","JBOSS");
	
	executeXml(serverIp,serverport,serverType);
	
	response.setHeader("Cache-Control", "no-store, no-store, must-revalidate"); //HTTP 1.1
	response.setHeader("Pragma", "no-cache"); //HTTP 1.0
	response.setDateHeader("Expires", 0); //prevents caching at the proxy server
		
	ResourceBundle rsb = (java.util.ResourceBundle)session.getAttribute("genRSB");
	int cl=Integer.parseInt(((java.util.ResourceBundle)session.getAttribute("genRSB")).getString("Check_Length"));
	sessionBean.setProtocol(sessionBean.getIniValue("Protocol"));
	
	//added on 14-02-2025 by Ashish Anurag to open WI directly after login
	String openFromMail = "N";
	session.setAttribute("openFromMail",openFromMail);
	//14-02-2025 changes end here
	
	//Added for setting the provision string. 7/21/2009
	String strSupervisor= EWAppUtil.getProvisionVal("Supervisor");
	String strProvision = EWAppUtil.getProvisionVal("Provision");
	String strReadMean = EWAppUtil.getProvisionVal("Read");
	BigInteger ibProvision = null;
	if (strProvision == null || strProvision == "")
		ibProvision = EWProvision.ALL;
	else
		ibProvision = new BigInteger(strProvision, 2);
	
	strSupervisor = (strSupervisor == null || strSupervisor.trim().equalsIgnoreCase("") || strSupervisor.trim().equalsIgnoreCase("null"))?"0":strSupervisor;
	strReadMean  = (strReadMean == null || strReadMean.trim().equalsIgnoreCase("") || strReadMean.trim().equalsIgnoreCase("null"))?"111":strReadMean;
	if (strSupervisor.equalsIgnoreCase("1") && sessionBean.getIsAdmin())
		ibProvision = ibProvision.or(EWProvision.ALL);
	sessionBean.setProvision(ibProvision);
	sessionBean.setReadMean(strReadMean);
	//Additions end. 7/21/2009

	EWUser eUser = sessionBean.getLoggedInUser(); //Added for integrating KM.

	session.setAttribute("ewsessionbean",sessionBean);
	//changes by kanchan for newgenoneBase on 07-10-2024
	//Changes made by Lakshay on 23-07-2025 to remove hardcoding
	//session.setAttribute("isNewgenone", isNewgenone);
	//Changes by Lakshay ends here
	session.setAttribute("userDBId",sessionBean.getUserDbId());
	//Added by Adeeba on 9/5/2023 to set the session for Reminder Notification
	session.setAttribute("alreadyStoredReminders","");
	
	//Added by Vaibhav on 03/04/2015 for Committee Doc Upload issue
	session.setAttribute("cabinetName",sessionBean.getCabinetName());
	session.setAttribute("loginUserIndex",sessionBean.getLoggedInUser().getUserIndex());
	//session.setAttribute("imageVolumeIndex",imageVolumeIndex); Updating in LoginOmniDocs.java
	session.setAttribute("loginUserName",sessionBean.getLoggedInUser().getUserName());
	
	//Changes ended
	
	//changes done by vaibhav.khandelwal for dak register.
	String dakDDTTable="";
	String fileDDTTable="";
	String dakDDTTableIndex="";
	String fileDDTTableIndex="";
	String field_ReferenceNo="";
	String field_Subject="";
	String field_Department="";
	String field_Category="";
	String field_FileNumber="";
	String fieldToFetch="";
	//Ended done by vaibhav.khandelwal for dak register.
			
	// Added by Mrunal 18jun09 to read moduleConfig.ini

	Properties properties = getPropertiesLoad(EWContext.getContextPath()+"ini","moduleConfig.ini");

	String strMyDeskProvision = properties.getProperty("mydeskprovision");
			
	int flagWI=0;
	int flagDak=0;
	int flagOffNote=0;
	int flagSubF=0;
	int flagSpeF=0;
	int flagHelp=0;
	int flagWhitehallView=0;
	//added by kanchan for committee integrate on 07-01-2025
	int flagComm=0;
			
	if(!(strMyDeskProvision == null) && !(strMyDeskProvision.equals("")) && !(strMyDeskProvision.equals("null")))
	{
		flagWI= Character.getNumericValue(strMyDeskProvision.charAt(0) );
		flagDak= Character.getNumericValue(strMyDeskProvision.charAt(1));
		flagOffNote= Character.getNumericValue(strMyDeskProvision.charAt(2));
		flagSubF= Character.getNumericValue(strMyDeskProvision.charAt(3));
		flagSpeF= Character.getNumericValue(strMyDeskProvision.charAt(4));
		flagHelp= Character.getNumericValue(strMyDeskProvision.charAt(5));
		flagWhitehallView= Character.getNumericValue(strMyDeskProvision.charAt(6));
		//added by kanchan for committee integrate on 07-01-2025
		flagComm= Character.getNumericValue(strMyDeskProvision.charAt(7));
	}
	
	session.setAttribute("EnableHelp",""+flagHelp);		
	session.setAttribute("WhitehallView",""+flagWhitehallView);		

	//Ayush Gupta: changes for preventing multiple logins on same browser	
	session.setAttribute("LoginFlag","Yes");
	
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
"http://www.w3.org/TR/html4/loose.dtd">
<html dir=<%=((java.util.ResourceBundle)session.getAttribute("genRSB")).getString("HTML_DIR")%> lang=<%=session.getAttribute("language").toString()%>> <!--Changed as per SonarQube-->
 <head>
  <link href="css/<%=((java.util.ResourceBundle)session.getAttribute("genRSBngOne")).getString("Path")%>style1.css" type="text/css" rel="stylesheet">
  <link rel="stylesheet" type="text/css" href="css/<%=((java.util.ResourceBundle)session.getAttribute("genRSBngOne")).getString("Path")%>ewgeneral.css"/>
  <link href="css/<%=((java.util.ResourceBundle)session.getAttribute("genRSBngOne")).getString("Path")%>chat.css" type="text/css" rel="stylesheet">
  <meta name="viewport" content="width=device-width, initial-scale=1">
		<meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta http-equiv="Content-Type" content="text/html;charset=<%=strEncoding%>">
		<!-- Starts Changes here for Calendar Issue -- EGOV-543 -- Gourav Singla -->
		<link rel="stylesheet" type="text/css" href="/<%=sessionBean.getIniValue("ContextName")%>/fullcalendar-3.8.0/fullcalendar.css" />
		<link rel="stylesheet" type="text/css" href="/<%=sessionBean.getIniValue("ContextName")%>/fullcalendar-3.8.0/fullcalendar.print.css" media="print" />
        <!-- Ends Changes here for Calendar Issue -- EGOV-543 -- Gourav Singla -->
		<link rel="stylesheet" type="text/css" href="/<%=sessionBean.getIniValue("ContextName")%>/bootstrap/css/bootstrap.css" />
		<!-- Custom styles for this template -->
	<!-- added by rishav for bootstrap version update: EG2024-050 -->
		<link rel="stylesheet" type="text/css" href="/<%=sessionBean.getIniValue("ContextName")%>/bootstrap/css/customization.css" rel="stylesheet"> 
		
		<!--For Notification -->
		<link rel="stylesheet" type="text/css" href="/<%=sessionBean.getIniValue("ContextName")%>/notificationcenter-master/css/notifcenter.css" />
		<link rel="stylesheet" type="text/css" href="/<%=sessionBean.getIniValue("ContextName")%>/bootstrap/css/bootstrap-egov_eGov_1.css" title="main" />
		<link rel="stylesheet" type="text/css" href="/<%=sessionBean.getIniValue("ContextName")%>/bootstrap/css/offcanvas.css" />
		<link rel="stylesheet" type="text/css" href="/<%=sessionBean.getIniValue("ContextName")%>/font-awesome-4.2.0/css/font-awesome.css" />
		<!-- added by rishav for bootstrap version update: EG2024-050 -->
		<link rel="stylesheet" type="text/css" href="/<%=sessionBean.getIniValue("ContextName")%>/fontawesome-free-6.6.0-web/css/all.css" />
		<!-- Custom css for DatePicker -->
		<link rel="stylesheet" type="text/css" href="/<%=sessionBean.getIniValue("ContextName")%>/bootstrap/css/bootstrap-datetimepicker.css" />
		
		<!-- CSS for AmCharts -->
		<link rel="stylesheet" href="amcharts/style11.css" type="text/css">
	 <!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->
		<link rel="stylesheet" href="css/style.css" type="text/css">
		
		<script>let contextNameGlobal = '<%=sessionBean.getIniValue("ContextName")%>';
		let loginUserName = '<%=sessionBean.getLoggedInUser().getUserName()%>';	
		let pollTimeInMilliSec='<%=(sessionBean.getIniValue("PollNotification"))%>'*60*1000;
		</script>
		<script language="JavaScript" src="scripts/chat.js"></script>
		 <!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->
		<script language="JavaScript" src="scripts/script.js"></script>
		<script language="JavaScript" src="scripts/purify.min.js"></script>
		
		<!-- JS for AmCharts -->
		 <!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->
		<script src="amcharts/core.js"></script>
		<script src="amcharts/charts.js"></script>
		<script src="amcharts/animated.js"></script>
		<script src="amcharts/amcharts.js" type="text/javascript"></script>
		<script src="amcharts/pie.js" type="text/javascript"></script>
		<script src="amcharts/serial.js" type="text/javascript"></script>
		<script src="amcharts/themes/light.js" type="text/javascript"></script>
		<script src="amcharts/themes/dark.js" type="text/javascript"></script>
		<script src="amcharts/themes/black.js" type="text/javascript"></script>
		<script src="amcharts/themes/chalk.js" type="text/javascript"></script>
		<script src="amcharts/d3.min.js" type="text/javascript"></script>
		<script src="amcharts/d3pie.min.js" type="text/javascript"></script>
		<script language="JavaScript" src="amcharts/d3.tip.v0.6.3.js"></script>
		<script src="amcharts/themes/patterns.js" type="text/javascript"></script>
		<script language="JavaScript" src="scripts/customreport.js"></script>
		<!-- added by rishav for bootstrap version update: EG2024-050 -->
		<script language="JavaScript" src="/<%=sessionBean.getIniValue("ContextName")%>/bootstrap/js/jquery-3.7.1.min.js"></script>
		<script language="JavaScript" src="/<%=sessionBean.getIniValue("ContextName")%>/bootstrap/js/jquery-ui.min.js"></script>
		
		<!--js added by rishav to include flatpickr css -->
		<link rel="stylesheet" type="text/css" href="/<%=sessionBean.getIniValue("ContextName")%>/flatpickr/dist/flatpickr.css" />  
		<link rel="stylesheet" type="text/css" href="/<%=sessionBean.getIniValue("ContextName")%>/flatpickr/dist/flatpickr.min.css" />
  
		<!--script added by rishav to include flatpickr JS-->
		<script language="JavaScript" type="text/javascript" src="/<%=sessionBean.getIniValue("ContextName")%>/flatpickr/dist/flatpickr.min.js"></script>
		<script language="JavaScript" type="text/javascript" src="/<%=sessionBean.getIniValue("ContextName")%>/flatpickr/dist/flatpickr.js"></script>

		<!--changes started for Dispatch Module by Rohit Verma -->
		<script language="JavaScript" src="datatables/js/dataTables.js"></script>
		<link rel="stylesheet" type="text/css" href="datatables/css/dataTables.css">
		<!--<script type="text/javascript" src="datatables/js/jquery.dataTables.js"></script>-->
		<!-- changes ended -->
		<script language="JavaScript" src="/<%=sessionBean.getIniValue("ContextName")%>/bootstrap/js/bootstrap.min.js"></script>
		<script language="JavaScript" src="/<%=sessionBean.getIniValue("ContextName")%>/bootstrap/js/offcanvas.js"></script>
		<!-- Starts Changes here for Calendar Issue -- EGOV-543 -- Gourav Singla -->
		<script language="JavaScript" src="/<%=sessionBean.getIniValue("ContextName")%>/fullcalendar-3.8.0/lib/moment.min.js"></script>
		<script language="JavaScript" src="/<%=sessionBean.getIniValue("ContextName")%>/fullcalendar-3.8.0/fullcalendar.js"></script>
		<!-- Ends Changes here for Calendar Issue -- EGOV-543 -- Gourav Singla -->
		<!--For DatePicker -->
		<script language="JavaScript" src="/<%=sessionBean.getIniValue("ContextName")%>/bootstrap/js/bootstrap-datetimepicker.js"></script>
		<!--For Notification -->
		<script src="/<%=sessionBean.getIniValue("ContextName")%>/notificationcenter-master/js/jquery.notificationcenter.js"></script>
		<script src="/<%=sessionBean.getIniValue("ContextName")%>/notificationcenter-master/js/jquery.livestamp.js"></script>
		
		<!-- IE10 viewport hack for Surface/desktop Windows 8 bug -->
		<script src="/<%=sessionBean.getIniValue("ContextName")%>/bootstrap/js/ie10-viewport-bug-workaround.js"></script>
	
		<!-- HTML5 shim and Respond.js IE8 support of HTML5 elements and media queries -->
		<!--[if lt IE 9]>
			<script src="/<%=sessionBean.getIniValue("ContextName")%>/bootstrap/ie8/html5shiv.min.js"></script>
			<script src="/<%=sessionBean.getIniValue("ContextName")%>/bootstrap/ie8/respond.min.js"></script>
		<![endif]-->

		<!--Added on 11Feb by Priyanka-->
		<link href="/<%=sessionBean.getIniValue("ContextName")%>/bootstrap/css/bootstrap.min.css" rel="stylesheet">
		<!--changes started for iBPS queues by Rohit Verma-->
		<link rel="stylesheet" type="text/css" href="/<%=sessionBean.getIniValue("ContextName")%>/bootstrap/css/submenu.css" />
		<!--changes ended-->
		<link href="/<%=sessionBean.getIniValue("ContextName")%>/bootstrap/css/sb-admin.css" rel="stylesheet">   
		<link href="/<%=sessionBean.getIniValue("ContextName")%>/bootstrap/css/plugins/morris.css" rel="stylesheet">  
		<link href="/<%=sessionBean.getIniValue("ContextName")%>/bootstrap/font-awesome/css/font-awesome.min.css" rel="stylesheet" type="text/css">
		<!-- added by rishav for bootstrap version update: EG2024-050 -->
		<link href="/<%=sessionBean.getIniValue("ContextName")%>/bootstrap/font-awesome/css/fontawesome.min.css" rel="stylesheet" type="text/css">
		<script src="/<%=sessionBean.getIniValue("ContextName")%>/bootstrap/js/plugins/morris/raphael.min.js"></script>
		<script src="/<%=sessionBean.getIniValue("ContextName")%>/bootstrap/js/plugins/morris/morris.min.js"></script>
		<!--ended-->
		<!-- Changes for DateFormat - Gourav Singla  EG10_0001-->
		<script language="JavaScript" src="/<%=sessionBean.getIniValue("ContextName")%>/scripts/moment.js"></script>

		<!--EG-0008: UserCredentials traverses in Cleartext ...start-->
		<script LANGUAGE="JavaScript" SRC="/<%=sessionBean.getIniValue("ContextName")%>/estyle/scripts/doccab/blowfish.js"></script>
		<!--EG-0008: User Credentials traverses in Cleartext ...end-->
        <title><%=((java.util.ResourceBundle)session.getAttribute("genRSB")).getString("Egov")%> <%=((java.util.ResourceBundle)session.getAttribute("genRSB")).getString("Office")%></title>
		<!-- added by kanchan for Security on 09-05-2024 Security01 -->
		<script>
		
function escapeHtml(str) {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

		let cookievalue = DOMPurify.sanitize(document.cookie);
		document.cookie = cookievalue+"; SameSite=None; Secure;";
		</script>
		
		<%			
	// EG-0008: User Credentials traverses in Cleartext...start
			String strTokenName = null; 
			String strTokenValue = null;

			strTokenName="EWSPW"+sessionBean.MakeUniqueNumber();
			strTokenValue=sessionBean.MakeUniqueNumber();
			int index = strTokenValue.indexOf('-');
			if(index != -1)
			{
				strTokenValue = strTokenValue.substring(1);
			}
			session.setAttribute("PWDToken",strTokenName);
			session.setAttribute(strTokenName,strTokenValue);
			
	//EG-0008: User Credentials traverses in Cleartext......end
	
	Properties properties1 = getPropertiesLoad(EWContext.getContextPath()+"ini","dataclass.ini");
	// changes by Saurabh Rajput for code optmization for optimize01
	session.setAttribute("dataclassPropertiesFile", properties1);
	String DAKDepartmentFieldName 		= properties1.getProperty("DAKDepartmentFieldName");
	String DAKSubjectField 				= properties1.getProperty("DAKSubjectField");
	String DakCategoryFieldName			= properties1.getProperty("DakCategoryFieldName");
	String FileCategoryFieldName		= properties1.getProperty("File");
	String DakDateFieldName				= properties1.getProperty("DakDateFieldName");
	String DAKRegistrationFieldName 	= properties1.getProperty("DAKRegistrationFieldName");
	String DAKRegistrationFieldPrefix 	= properties1.getProperty("DAKRegistrationFieldPrefix");
	String ToWhomFieldName 				= properties1.getProperty("ToWhomFieldName");
	String dakCategories 				= "";//properties1.getProperty("DakCategories");
	String fileCategories               = "";
	String DAKDepartment 		        = properties1.getProperty("DAKDepartment");
	String DAKReferenceNoLetter 		= properties1.getProperty("DAKReferenceNoLetter");
	String outwarddakCategories 		= "";
	String OutwardDAKRegistration 		= properties1.getProperty("OutwardDAKRegistration");
	String DAKDispatchDate 		        = properties1.getProperty("DAKDispatchDate");
	String OutwardDakDispatchFieldName	= properties1.getProperty("OutwardDakDispatchFieldName");
	String outwardDocDataClass			= properties1.getProperty("Admin_outwardDoc");
	String FileNoFieldname 				= properties1.getProperty("FileNoFieldName");
	String FileNoFieldLen 				= properties1.getProperty("FileNoFieldLen");
	String FileValues					= properties1.getProperty("File");
	String FileDataClass				= properties1.getProperty("Admin_Files");
	String RangeOnDateField				= properties1.getProperty("RangeOnDateField");
	//Added by vaibhav.khandelwal for DAK REGISTER Procedure
	String dakDataclass					= properties1.getProperty("Admin_Documents");
	String fileDataclass				= properties1.getProperty("Admin_Files");
	session.setAttribute("dakDataClassName",dakDataclass);
	session.setAttribute("fileDataClassName",fileDataclass);
	
	String DAKDataClassFieldName				= properties1.getProperty("DAKDataClassFieldName");
	String FileDataClassFieldName				= properties1.getProperty("FileDataClassFieldName");
	String allDataClassFieldsList = DAKDataClassFieldName + "," +FileDataClassFieldName;
	//Added by vaibhav.khandelwal for DAK REGISTER Procedure
	
	//Added by priyanka on 29jul2015------------------------
	String DAKSectionFieldName 		    = properties1.getProperty("DAKSectionFieldName");
	//Ended----------------------------------------
	
	
	//added by vaibhav.khandelwal for Note Reference Number
	String sNoteRefNo 		    = properties1.getProperty("sNoteRefNo");
	String NoteRefField				= properties1.getProperty("NoteRefField");
	String NoteRegistrationFieldPrefix				= properties1.getProperty("NoteRegistrationFieldPrefix");
	session.setAttribute("NoteRegistrationFieldPrefix",NoteRegistrationFieldPrefix);
	session.setAttribute("NoteRefField",NoteRefField);
	//ended by vaibhav.khandelwal for Note Reference Number
	
	session.setAttribute("outwardDAKDT",outwardDocDataClass);
	session.setAttribute("DakCategoryFieldName",DakCategoryFieldName);
	session.setAttribute("DakDateFieldName",DakDateFieldName);  // changes done by sahil Bhuria on 7 JULY 2021 for common Date format (EG10-0001)
	session.setAttribute("ToWhomFieldName",ToWhomFieldName);	// changes done by sahil Bhuria on 7 JULY 2021 for common Date format (EG10-0001)
	
	
	//Added by atish for arabic//
	String FileNumberarabic=properties1.getProperty("FileNumber");
	String FileNamearabic=properties1.getProperty("FileName");
	String Departmentarabic=properties1.getProperty("Department");
	String Sectionarabic=properties1.getProperty("Section");
	String CourtCase=properties1.getProperty("CourtCase");
	String treeAlignment="left";
	
	treeAlignment=((java.util.ResourceBundle)session.getAttribute("genRSB")).getString("TreeAlignment");
	
	//added by Ashish on 14-06-2024 to load uploadmime.conf and store it as a session variable
	Properties uploadMimeConf = getPropertiesLoad(EWContext.getContextPath()+"ini","uploadmime.conf");
	session.setAttribute("uploadMimeConf", uploadMimeConf);
	//14-06-2024 changes end here
	
	Properties properties2 = getPropertiesLoad(EWContext.getContextPath()+"ini","custom.ini");
	// changes by Kanchan for code optmization for optimize01
	session.setAttribute("customPropertiesFile", properties2);
	String egovProcessName = properties2.getProperty("EGOV_Route_Name");
	String serverIpAddress = properties2.getProperty("ServerIp");
	String serverHttpPort = properties2.getProperty("HttpPort");
	String refreshVal = properties2.getProperty("RefreshValue");
	String OutwardDAKEnable = properties2.getProperty("OutwardDAKEnable");	
	//Added by Adeeba for changing Reminder notification color
	String ReminderColor = properties2.getProperty("ReminderColor");
	String createSpecialFilesEnable = properties2.getProperty("CreateSpecialFilesEnable"); //Added by Nikita.Patidar for creating special files(EG7-0008)
	
	//Added By Shirish for handeling CheckMarx vulnerabilities
	String MAX_LOOP_COUNT = properties2.getProperty("MAX_LOOP_COUNT");
	session.setAttribute("MAX_LOOP_COUNT", MAX_LOOP_COUNT);
	
	//Added by Vikas on 12-06-2024 for cache clear: EG2024-053
	String cacheCount = properties2.getProperty("CacheCount");
	session.setAttribute("cacheCount", cacheCount);
	//End by Vikas for cache clear: EG2024-053

	//Chat and Special Files Config//
	String chatEnable=properties2.getProperty("ChatEnable");
	String specialFilesEnable=properties2.getProperty("SpecialFilesEnable");
	//for CNM//
	String commEnable=properties2.getProperty("CNMEnable");
	//for RTI//
	String rtiEnable=properties2.getProperty("RTIEnable");
	//for PQ//
	String pqEnable=properties2.getProperty("PQEnable");
	//for Court Cases//
	String ccEnable=properties2.getProperty("CCEnable");
	//for AUDIT Process//
	String auditEnable=properties2.getProperty("AUDITEnable");
	//for BAM Dash//
	String BAMDashEnable=properties2.getProperty("BAMDashEnable");
	//for OD Link//
	String OmniDocsEnable=properties2.getProperty("OmniDocsEnable");
	//changes by Somya : KM with Egov
	String KMEnable=properties2.getProperty("KMEnable");
	//changes end 
	//for DAK Visibility//
	String DAKEnable=properties2.getProperty("DAKEnable");
	//for Office Note Visibility//
	String OfficeNoteEnable=properties2.getProperty("OfficeNoteEnable");
	
	//CC Config//
	String CC_Config=properties2.getProperty("CC_Config");
	session.setAttribute("CCEnable",CC_Config);
	//changes started for Dispatch Module by Rohit Verma
	//Dispatch Config//
	String Dispatch_Config=properties2.getProperty("Dispatch_Config");
	session.setAttribute("DispatchEnable",Dispatch_Config);
	
	//changes started for dispatch groups by Rohit Verma
	//String dispatchGroupName=properties2.getProperty("Dispatch_Group_Name");
	//session.setAttribute("DispatchGroupName",dispatchGroupName);	
	String deptDispatchGroupNames=properties2.getProperty("Department_Dispatch_Group_Names");
	//changes ended for dispatch groups by Rohit Verma

	String dispatchGroupPrefix=properties2.getProperty("Dispatch_Group_Prefix");
	session.setAttribute("DispatchGroupPrefix",dispatchGroupPrefix);
	//changes ended
	
	//changes started for DAK dispatch functionality by Rohit Verma
	String outwardDakFolderName=properties2.getProperty("OutwardDakFolderName");
	session.setAttribute("OutwardDakFolderName",outwardDakFolderName);
	//changes ended
	
	// Added By Neha Kathuria on October 3,2016 
	//Order Enclosures for enclosures in File
	String OrderEnclosuresInFile=properties2.getProperty("OrderEnclosuresInFile");
	session.setAttribute("OrderEnclosuresInFile",OrderEnclosuresInFile);
	
	//FTS for enclosures in File
	String FTSEnclosuresInFile=properties2.getProperty("FTSEnclosuresInFile");
	session.setAttribute("FTSEnclosuresInFile",FTSEnclosuresInFile);
	
	// Changes by Indra to enable FTS 
	// Added by Neha Kathuria on May 11,2018 for FTSEnclosuresInDAK
	String FTSEnclosuresInDAK=properties2.getProperty("FTSEnclosuresInDAK");
	session.setAttribute("FTSEnclosuresInDAK",FTSEnclosuresInDAK);
	// Add ends here
	//Changes by Indra to configure type of notifications
	
	String TypeOfNotification=properties2.getProperty("TypeOfNotification");
	session.setAttribute("TypeOfNotification",TypeOfNotification);
	
	//Changes made by Lakshay on 16-06-2025 for next/prev on the basis of entryDateTime in NewgenOne for search inbox and Inbox 
	String isIBPS = properties2.getProperty("isIBPS");
	//Changes by Lakshay ends here

	//Changes made by Lakshay on 23-07-2025 to remove hardcoding
	Boolean isNewgenone = Boolean.parseBoolean(properties2.getProperty("IsNewgenone"));
	session.setAttribute("isNewgenone", isNewgenone);
	//Changes by Lakshay ends here.
	
	
	//Changes by Indra end
	//Changes by Indra For distinguishing between iBPS and Omniflow

	String IsiBPS=properties2.getProperty("IsiBPS");
	session.setAttribute("IsiBPS",IsiBPS);
	
	//added by kanchan for jboss versioning on 11-04-2025
	String IsJbossV=properties2.getProperty("IsJbossV");
	session.setAttribute("IsJbossV",IsJbossV);
	//ended here
	
	//changes started for iBPS queues by Rohit Verma
	String ibpsProcessEnable=properties2.getProperty("ibpsProcess");
	//changes ended
	//Download from Enclosures in File config
	String downloadEnclosures=properties2.getProperty("DownloadFromEnclosures");
	session.setAttribute("DownloadEnclosureEnable",downloadEnclosures);
	//Download from Enclosures in File config
	// Added by Indra to download enclosures in whitehall
	
	//Download Enclosures as zip in file Config
	String downloadEnclZip=properties2.getProperty("Zip_Enclosures");
	session.setAttribute("isEnclZip",downloadEnclZip);
	//Download Enclosures as zip in file Config

	//Multiple DAK Forward and Initiate by Kanika Goel on 9-6-2014//
	String MultipleDakForward_Enable=properties2.getProperty("MultipleDAKForwardEnable");	
	String  MultipleDakInitiate_Enable=properties2.getProperty("MultipleDAKInitiateEnable");
	
	//Reminder Config by Kanika Goel//
	String Reminder_Config=properties2.getProperty("Reminder_Config");
	
	//Secure Green Notes Config
	String secureGNotes=properties2.getProperty("Secure_GNotes");
	session.setAttribute("SGNEnable",secureGNotes);
	
	//Changes by Indra to handle dak view rights from ini
	String ufdaksViewRights=properties2.getProperty("ufdaksViewRights");
	session.setAttribute("ufdaksViewRights",ufdaksViewRights);
	//Changes end
	//changes started for reminder by Rohit Verma
	String isDueDateSet=properties2.getProperty("isDueDateSet");
	session.setAttribute("setDueDate",isDueDateSet);
	String reminderTime=properties2.getProperty("reminderDays");
	session.setAttribute("reminderTime",reminderTime);
	String reminderMin=properties2.getProperty("reminderMins");
	session.setAttribute("reminderMin",reminderMin);
	//changes ended for reminder by Rohit Verma
	//Changes by Ayush to read autosave time for drafts from ini
	String AutosaveTime=properties2.getProperty("AutosaveTime");
	session.setAttribute("AutosaveTime",AutosaveTime);	
	String GreenNoteDraftsFolder=properties2.getProperty("GreenNoteDraftsFolder");
	session.setAttribute("GreenNoteDraftsFolder",GreenNoteDraftsFolder);
	
	
	//Changes end 
	//Changes by Indra to sent item search from ini
	String sentItemSearchEnable=properties2.getProperty("SentItemSearchEnable");
	session.setAttribute("sentItemSearchEnable",sentItemSearchEnable);
	//Changes end
	//Added by Neha Kathuria on June 14,2017 to disable F12 for security constraint

	String DisableF12=properties2.getProperty("DisableF12");
	//Added by Neha Kathuria on June 14,2017 to disable Right Click for security constraint	

	String DisableRightClick=properties2.getProperty("DisableRightClick");
	
	//Added by Nikita Patidar for Global index from ini. 
	String UniqueNoPP=properties2.getProperty("Unique_No_PP");
	session.setAttribute("UniqueNoPP",UniqueNoPP);
	   
    String IsDocAvailable=properties2.getProperty("Is_Doc_Available");
	session.setAttribute("IsDocAvailable",IsDocAvailable);
	
	String NotificationEnable=properties2.getProperty("NotificationEnable");
	session.setAttribute("NotificationEnable",NotificationEnable);

	//Changes done by Nikita.Patidar for Notifications count Configuration(CQRN-136930)
	String NotificationsCountToFetch=properties2.getProperty("NotificationsCountToFetch");
	session.setAttribute("NotificationsCountToFetch",NotificationsCountToFetch);

	//session.setAttribute("sessionBean",sessionBean);
	
	String checkInCheckOutGroup=properties2.getProperty("checkInCheckOutGroup");
	if(checkInCheckOutGroup == null || checkInCheckOutGroup.equalsIgnoreCase("null") || checkInCheckOutGroup.equalsIgnoreCase("undefined") || checkInCheckOutGroup.equalsIgnoreCase(""))
		checkInCheckOutGroup = "Everyone";
	
	//BAM Report generalization
	ArrayList<String> BAMReportArrList=new ArrayList<String>();
	try
	{
		int bamCount=1;
		//changes by Rohit Verma for Report right in egov for CEICED
		if(properties2.getProperty("BAM_Report_config").equalsIgnoreCase("yes")){
			while(properties2.getProperty("Report"+bamCount)!=null)
			{				
				BAMReportArrList.add(properties2.getProperty("Report"+bamCount));
				bamCount++;
			}
		}
		else{
			BAMReportArrList.add("");
		}		
		//changes by Rohit Verma for Report right in egov for CEICED
	}
	catch(Exception nfe)
	{
		nfe.printStackTrace();
		throw new Exception("Problem while fetching BAM Reports list!");
	}
	
	//Code to make egov database independent start//
	String databaseType = properties2.getProperty("DatabaseType");
	Properties queryProperties=new Properties();
	Properties queryPropertiesCC=new Properties();
	//changes by Somya : database type is changed post Go-Omnidocs Actions
	sessionBean.setDataBaseType(databaseType);
	
	String queryFile="";
	
	if(databaseType.equalsIgnoreCase("MSSQL"))
	{
		queryFile="mssql.properties";
		String formatForDate=properties2.getProperty("MSSQL_SDF");
		session.setAttribute("dateFormat",formatForDate);
	}
	else if(databaseType.equalsIgnoreCase("ORACLE"))
	{
		queryFile="oracle.properties";
		String formatForDate=properties2.getProperty("ORACLE_SDF");
		session.setAttribute("dateFormat",formatForDate);
	}
	else if(databaseType.equalsIgnoreCase("POSTGRE"))
	{
		queryFile="postgresql.properties";
		String formatForDate=properties2.getProperty("POSTGRES_SDF");
		session.setAttribute("dateFormat",formatForDate);
	}
	//Starts - Changes for DateFormat - Gourav Singla //EG10-0001
	String jsMomentDisplayDateFormat = properties2.getProperty("Js_Moment_Display_Date_Format");
	String javaDisplayDateFormat = properties2.getProperty("Java_Display_Date_Format");
	jsMomentDisplayDateFormat=(jsMomentDisplayDateFormat==null || jsMomentDisplayDateFormat.trim().isEmpty())?"DD-MM-YYYY HH:mm:ss":jsMomentDisplayDateFormat.trim();
	javaDisplayDateFormat=(javaDisplayDateFormat==null || javaDisplayDateFormat.trim().isEmpty())?"DD-MM-YYYY HH:mm:ss":javaDisplayDateFormat.trim();
	session.setAttribute("displayDateFormat",javaDisplayDateFormat);
	session.setAttribute("jsDisplayDateFormat",jsMomentDisplayDateFormat);
	//Ends - Changes for DateFormat - Gourav Singla
	
	//Added by Vaibhav on 20/01/2015 for calendar
	///Added By Varun For Calendar 21/10/2014
	String format="";
	String ccPropertyFile="";
	if(databaseType.equalsIgnoreCase("ORACLE"))
	{
		
		format="dd-mm-yy";
		ccPropertyFile="oracle";
	}
	else if(databaseType.equalsIgnoreCase("POSTGRE"))
	{ // Added for Bug 601 -- Gourav Singla
		
		format="yyyy-mm-dd";
		ccPropertyFile="postgresql";
	}
	else
	{
		
		format="yyyy-mm-dd";
		ccPropertyFile="mssql";
	}
//Changes ended by Vaibhav

	java.io.File dbQuery = new java.io.File(EWContext.getContextPath()+"ini"+File.separator+"queries"+File.separator+queryFile);
	try
	{
		if (!(dbQuery.isFile() && dbQuery.exists()))
		{
			throw new Exception("Properties file not present for Database type "+databaseType);
		}
		 java.io.FileInputStream queryIO = new java.io.FileInputStream(dbQuery);
		 queryProperties.load(queryIO);
		 session.setAttribute("dbQueryPropertiesFile", queryProperties);
		 queryIO.close();
		 dbQuery=null;
		 queryIO=null;
	}
	catch(Exception ex)
	{
		  if (ex.getMessage().indexOf("file not present") != -1)
					  throw new Exception("Database Queries Properties File not found.");
		  ex.printStackTrace();
	}
	//Code to make egov database independent ends//	
	
//Changes added by priyanka on 16mar15-------------
	java.io.File dbQueryCC = new java.io.File(EWContext.getContextPath()+"WEB-INF"+File.separator+"resource"+File.separator+""+ccPropertyFile+".properties");
	try
	{
		if (!(dbQueryCC.isFile() && dbQueryCC.exists()))
		{
			throw new Exception("Properties file not present for Database type "+databaseType);
		}
		 java.io.FileInputStream queryIO2 = new java.io.FileInputStream(dbQueryCC);
		 queryPropertiesCC.load(queryIO2);
		 session.setAttribute("dbQueryCC", queryPropertiesCC);
		 queryIO2.close();
		 dbQueryCC=null;
		 queryIO2=null;
	}
	catch(Exception ex)
	{
		  if (ex.getMessage().indexOf("file not present") != -1)
					  throw new Exception("Database Queries Properties File not found.");
		  ex.printStackTrace();
	}
	//ended---//
		
	String loggedInUser_Department = "";
	String loggedInUser_FirstLevelHierarchy = "";
	String loggedInUser_SecondLevelHierarchy = "";
	String loggedInUser_ThirdLevelHierarchy = "";	
    String LoggedInUser_UserDesignation = "";	
    String LoggedInUser_UserInitials = "";
    String LoggedInUser_UserSection = ""; //Added by Indra for User section handling in egov
	
	
	connectToServer();
	
	
	Properties dbQueryProperties=null;
	dbQueryProperties=(Properties) session.getAttribute("dbQueryPropertiesFile");
	
	String queryString = dbQueryProperties.getProperty("Q93");
	int tempUserIndex=sessionBean.getLoggedInUser().getUserIndex();
	queryString=EGovAPI.getPreparedQuery(queryString,new Integer(tempUserIndex).toString()+"\u0004int");
	if(queryString.equalsIgnoreCase("Arguments mismatch"))
	{	
		EgovLogger.writeLog(sessionBean.getCabinetName(),'i', "In office.jsp -- Q93=" + queryString);
		queryString="";
	}
	
				
	String inputXML ="";			
	String outputXML ="";			
	/*String inputXML = "<?xml version=\"1.0\"?><WFCustomBean_Input><Option>IGGetData</Option><EngineName>"+sessionBean.getCabinetName()+"</EngineName><QueryString  CS=\""+calculateCheckSum(queryString,Integer.parseInt(sessionBean.getUserDbId()))+"\">"+queryString+"</QueryString><SessionId>"+sessionBean.getUserDbId()+"</SessionId></WFCustomBean_Input>";
			
	String outputXML = execute(inputXML);
			
	DMSXmlResponse UserInfoResponse;	
	UserInfoResponse = new DMSXmlResponse(outputXML);*/
	
	DMSXmlResponse 	UserInfoResponse;
	UserInfoResponse = executeCommonQuery(sessionBean.getCabinetName(), sessionBean.getUserDbId(), queryString, "IGGetPreparedData","preparedStmt");
	
	if(UserInfoResponse == null){
				//changes by Ayush Gupta for handling session logout 
			
				session.setAttribute("LoginFlag","false");
				%>
				<script>
				window.document.location="login.jsp";
				</script>
				<%
			}
				 
	loggedInUser_Department = UserInfoResponse.getVal("Value1");
	
	if(loggedInUser_Department == null || loggedInUser_Department.equalsIgnoreCase("null") || loggedInUser_Department.equalsIgnoreCase("undefined") || loggedInUser_Department.equalsIgnoreCase(""))
		loggedInUser_Department = "No Department Set";
	session.setAttribute("LoggedInUser_UserDepartment", loggedInUser_Department);	

	loggedInUser_FirstLevelHierarchy = UserInfoResponse.getVal("Value2");

	if(loggedInUser_FirstLevelHierarchy == null || loggedInUser_FirstLevelHierarchy.equalsIgnoreCase("null") || loggedInUser_FirstLevelHierarchy.equalsIgnoreCase("undefined") || loggedInUser_FirstLevelHierarchy.equalsIgnoreCase(""))
		loggedInUser_FirstLevelHierarchy = "No FirstLevel Set";
	session.setAttribute("LoggedInUser_FirstLevelHierarchy", loggedInUser_FirstLevelHierarchy);	
		
	loggedInUser_SecondLevelHierarchy = UserInfoResponse.getVal("Value3");

	if(loggedInUser_SecondLevelHierarchy == null || loggedInUser_SecondLevelHierarchy.equalsIgnoreCase("null") || loggedInUser_SecondLevelHierarchy.equalsIgnoreCase("undefined") || loggedInUser_SecondLevelHierarchy.equalsIgnoreCase(""))
		loggedInUser_SecondLevelHierarchy = "No SecondLevel Set";
	session.setAttribute("LoggedInUser_SecondLevelHierarchy", loggedInUser_SecondLevelHierarchy);
		
	loggedInUser_ThirdLevelHierarchy = UserInfoResponse.getVal("Value4");
	
	if(loggedInUser_ThirdLevelHierarchy == null || loggedInUser_ThirdLevelHierarchy.equalsIgnoreCase("null") || loggedInUser_ThirdLevelHierarchy.equalsIgnoreCase("undefined") || loggedInUser_ThirdLevelHierarchy.equalsIgnoreCase(""))
		loggedInUser_ThirdLevelHierarchy = "No ThirdLevel Set";	
	session.setAttribute("LoggedInUser_ThirdLevelHierarchy", loggedInUser_ThirdLevelHierarchy);	


	LoggedInUser_UserDesignation = UserInfoResponse.getVal("Value5");
	
	if(LoggedInUser_UserDesignation == null || LoggedInUser_UserDesignation.equalsIgnoreCase("null") || LoggedInUser_UserDesignation.equalsIgnoreCase("undefined") || LoggedInUser_UserDesignation.equalsIgnoreCase(""))
		LoggedInUser_UserDesignation = "No Designation Set";
	session.setAttribute("LoggedInUser_UserDesignation", LoggedInUser_UserDesignation);	
				   
	LoggedInUser_UserInitials = UserInfoResponse.getVal("Value6");
	
	if(LoggedInUser_UserInitials == null || LoggedInUser_UserInitials.equalsIgnoreCase("null") || LoggedInUser_UserInitials.equalsIgnoreCase("undefined") || LoggedInUser_UserInitials.equalsIgnoreCase(""))
		LoggedInUser_UserInitials = "No Initials Set";
	session.setAttribute("LoggedInUser_UserInitials", LoggedInUser_UserInitials);
	
	//Added By Indra to handle user section in egov
	LoggedInUser_UserSection = UserInfoResponse.getVal("Value7");
	
	if(LoggedInUser_UserSection == null || LoggedInUser_UserSection.equalsIgnoreCase("null") || LoggedInUser_UserSection.equalsIgnoreCase("undefined") || LoggedInUser_UserSection.equalsIgnoreCase(""))
		LoggedInUser_UserSection = "No Section Set";
	session.setAttribute("LoggedInUser_UserSection", LoggedInUser_UserSection);
	
	//Changes done by Nikita.Patidar for Notifications count Configuration(CQRN-136930)
	updateCounterForNotification(sessionBean,dbQueryProperties);
	
	queryString = dbQueryProperties.getProperty("Q94");
	//BAM Report generalization//
	StringBuffer queryClause=new StringBuffer();
	//changes by Rohit Verma for Report right in egov for CEICED
	// Changes by Indra to launch BAM from egov in case of iBPS
	/*if(IsiBPS.equalsIgnoreCase("yes"))
	{
		queryString = dbQueryProperties.getProperty("Q211");
		//StringBuffer queryClause=new StringBuffer();
		for(int i=0;i<BAMReportArrList.size();i++)
		{	
			queryClause.append("Reportname='"+BAMReportArrList.get(i)+"' OR ");
		}
	}
	else
	{
		//////
		queryString = dbQueryProperties.getProperty("Q94");
		//BAM Report generalization//
		//StringBuffer queryClause=new StringBuffer();
		for(int i=0;i<BAMReportArrList.size();i++)
		{	
			queryClause.append("name='"+BAMReportArrList.get(i)+"' OR ");
		}
	}*/	

	//queryClause.delete(queryClause.lastIndexOf(" OR "),queryClause.length());
	// Changes by Indra end
	//BAM Report generalization//
	//queryString=EGovAPI.getQuery(queryString,queryClause.toString());
	//queryClause=null;
	/*if(queryString.equalsIgnoreCase("Arguments mismatch"))
	{	
		EgovLogger.writeLog(sessionBean.getCabinetName(),'i', "In office.jsp -- Q94=" + queryString);
		queryString="";
	}
	*/
	
	//dbQueryProperties=null;	
	
	DMSXmlResponse BAMReportResponse=null;
	//BAMReportResponse=executeCommonQuery(sessionBean.getCabinetName(), sessionBean.getUserDbId(), queryString, "IGGetData")    ;

				   
	//DMSXmlList BAMReportList = BAMReportResponse.createList("DataList", "Data");	

	HashMap<String,String> BAMReportsMap=new HashMap<String,String>();
	inputXML="<WFReturnRightsForObjectType_Input><Option>WFReturnRightsForObjectType</Option><EngineName>"+sessionBean.getCabinetName()+"</EngineName><SessionID>"+sessionBean.getUserDbId()+"</SessionID><ObjectType>BAMTRR</ObjectType></WFReturnRightsForObjectType_Input>";	
	
	try{
		outputXML = execute(inputXML);		
		BAMReportResponse = new DMSXmlResponse(outputXML);
		if(Integer.parseInt(BAMReportResponse.getVal("MainCode"))==0){
			DMSXmlList reportList = BAMReportResponse.createList("Objects", "Object");
			for (reportList.reInitialize(true); reportList.hasMoreElements(true); reportList.skip(true)){
				for(int i=0;i<BAMReportArrList.size();i++){						
					if(BAMReportArrList.get(i).equalsIgnoreCase(reportList.getVal("ObjectName"))){
						BAMReportsMap.put(reportList.getVal("ObjectName"), reportList.getVal("ObjectId"));	
					}
				}				
			}
		}		
	}catch(Exception CRException){
		CRException.printStackTrace();
	}
	String dashboardReportIndex = "";	
	/*if (BAMReportList != null) 
	{				
		for (BAMReportList.reInitialize(true); BAMReportList.hasMoreElements(true); BAMReportList.skip(true)) 
		{
			if(BAMReportList.getVal("Value2").equalsIgnoreCase("EGOV_Usr_Pending_Ims"))
				dashboardReportIndex = BAMReportList.getVal("Value1");
			BAMReportsMap.put(BAMReportList.getVal("Value2"),BAMReportList.getVal("Value1"));
		}
	}*/
	//changes by Rohit Verma for Report right in egov for CEICED
	String[] reportNames=new String[BAMReportsMap.size()];
	((Set)BAMReportsMap.keySet()).toArray(reportNames);
	String [] htmlReportNames=new String[BAMReportsMap.size()];
	for(int temp=0;temp<reportNames.length;temp++)
	{
		StringBuffer tempBuffer=new StringBuffer(reportNames[temp]);
		/* while(tempBuffer.indexOf("_")!=-1)
			tempBuffer.replace(tempBuffer.indexOf("_"),tempBuffer.indexOf("_")+1," ");
                
		tempBuffer.replace(tempBuffer.indexOf("EGOV "), tempBuffer.indexOf("EGOV ")+5, ""); */
		// Commented by Indra to fetch BAM reports not having EGOV as prefix
		
		htmlReportNames[temp]=tempBuffer.toString();
	}
	
	//commented by kanchan for fetching data by query
	/*String deparmentXMLContent = "";
	java.io.File file = new java.io.File(EWContext.getContextPath()+"ini"+File.separator+"Departments.xml");
	try 
	{
		deparmentXMLContent = FileUtils.readFileToString(file,"utf-8");
	} 
	catch (IOException e)
	{
		e.printStackTrace();
	}*/
	//added by kanchan for fetching department by query
	queryString = dbQueryProperties.getProperty("Q338");
	//queryString=EGovAPI.getQuery(queryString);
	queryString=EGovAPI.getPreparedQuery(queryString);
	if(queryString.equalsIgnoreCase("Arguments mismatch"))
	{	
		queryString="";
	}
	
	DMSXmlResponse 	xmlResponse=	executeCommonQuery(sessionBean.getCabinetName(), sessionBean.getUserDbId(), queryString, "IGGetPreparedData","preparedStmt");
	//DMSXmlResponse 	xmlResponse=	executeCommonQuery(sessionBean.getCabinetName(), sessionBean.getUserDbId(), queryString, "IGGetData");
	System.out.println("xmlResponse ==== "+xmlResponse);
	DMSXmlList departmentTypeList = xmlResponse.createList("DataList", "Data");
	//ended here by kanchan
%>
<!-- Added by Neha Kathuria for CSRF-->
<script>
<% //Added by Neha Kathuria on June 14,2017 to disable F12 for security constraint
if(DisableF12.equalsIgnoreCase("yes"))
{
%>
document.onkeypress = function (event) {
	event = (event || window.event);
	if (event.keyCode == 123) {
		return false;
	}
}
document.onmousedown = function (event) {
	event = (event || window.event);
	if (event.keyCode == 123) {
		return false;
	}
}
document.onkeydown = function (event) {
	event = (event || window.event);
	if (event.keyCode == 123) {
		return false;
	}
}
<%
}
%>
// Add ends here	
////Added by Adeeba for changing Reminder notification color	
let ReminderColor = "<%=ReminderColor%>";

let egovUID = "<%=egovUID%>";
// Added by Saurabh Rajput for special file enable in egov-12.1
let specialFilesEnable = '<%= specialFilesEnable %>';
let createSpecialFilesEnable = '<%= createSpecialFilesEnable %>';
/*window.open overriding function starts*/

//Added by Priyanshu Sharma for NAFBID Timeout Redirecting Issue 
if (!window.open_) {
  window.open_ = window.open;
}
//ends

let methodType='post'; // Added By Neha Kathuria for RTI/PQ/CC module
window.open=function(m_url,m_name,m_properties)
{   	
	if(m_url.indexOf(".sp")>0){
		methodType='get';
	}
	if(m_url.indexOf("?")>0)	{
		m_url=m_url + "&egovID="+ egovUID;			
	}
	else{
		m_url=m_url + "?egovID="+ egovUID;			
	}  	
    let actionURL=m_url;
	if(m_url.indexOf("Calendar.html") != -1)
	actionURL=getActionUrlFromURL(m_url);	
	// Added by Neha Kathuria for JBoss 7 support (EGOV-1356,EGOV-1475)
	//changes by Kanchan for CSRF Error Encountered when creating Office Note on 18-06-2024
		//Added by Priyanshu Sharma for changing the reports URL to get method type.
	if(m_url.indexOf("calendar.html") != -1 || m_url.indexOf("timeout.htm") != -1 || m_url.indexOf("bam/login") != -1){
		methodType='get';
	}
	//ended here	
    let listParam=getInputParamListFromURL(m_url);
    let win = openNewWindow(actionURL, m_name, m_properties, true,"Ext1","Ext2","Ext3","Ext4",listParam);	
    return win;
}

function openNewWindow(sURL, sName, sFeatures, bReplace,Ext1,Ext2,Ext3,Ext4,listParameters)
{
	let popup = window.open_('',sName,sFeatures,bReplace);
    popup.document.write("<HTML><HEAD><TITLE></TITLE></HEAD><BODY>");
    popup.document.write("<form id='postSubmit' method='"+methodType+"' action='"+sURL+"' enctype='application/x-www-form-urlencoded'>");
    for(let iCountg=0;iCountg<listParameters.length;iCountg++)
    {
        let param=listParameters[iCountg];  	
        popup.document.write("<input type='hidden' id='"+param[0]+"' name='"+param[0]+"'/>");
        popup.document.getElementById(param[0]).value=param[1];//handle single quotes etc
    }
    popup.document.write("</FORM></BODY></HTML>");
    popup.document.close();
    popup.document.forms[0].submit();	
    return popup;
}

function getActionUrlFromURL(sURL)
{
    let ibeginingIndex=sURL.indexOf("?");
    if (ibeginingIndex == -1)
        return sURL;
    else
        return sURL.substring(0,ibeginingIndex);
 }

 function getInputParamListFromURL(sURL)
{    
    let ibeginingIndex=sURL.indexOf("?");
    let listParam=new Array();
    if (ibeginingIndex == -1)
        return listParam;
    let tempList=sURL.substring(ibeginingIndex+1,sURL.length);

    if(tempList.length>0)
     {
        let arrValue =tempList.split("&");
        for(let iCountg=0;iCountg<arrValue.length;iCountg++)
        {
            let arrTempParam=arrValue[iCountg].split("=");
            try
            {
                listParam.push(new Array(decode_ParamValue(arrTempParam[0]),decode_ParamValue(arrTempParam[1])));
            }catch(ex)
            {

            }
        }
    }
    return listParam;
}

function decode_ParamValue(param)
{
    let tempParam =param.replace(/\+/g,' ');
    tempParam = decodeURIComponent(tempParam);

    return tempParam;
}


/*window.open overriding function ends*/
</script>
<!-- Add end by Neha for CSRF-->  
	
			<script>
				//dakDataclassJS added by Lakshay for dak space in header on 04-07-2025
				let dakDataclassJS = "<%= dakDataclass%>";
				
				let formatForDate="<%=(String)session.getAttribute("dateFormat")%>";// Added by Neha Kathuria on May 28,2017 for date format issue in oracle
				let commUrlParamsGlobal = "?CabinetName=<%=sessionBean.getCabinetName()%>&UserDbId=<%=sessionBean.getUserDbId()%>&UserIndex=<%=sessionBean.getLoggedInUser().getUserIndex()%>&UserName=<%=eUser.getUserName()%>&JtsIpAdd=<%=sessionBean.getJtsIpAddress()%>&JtsPort=<%=sessionBean.getJtsPort()%>&redirectURLComm=";
				//Changes for Bug EGOV-1299 -- Handling of Committee data in Inbox -- Gourav Singla
				let databaseType="<%=databaseType%>";
				let languageLocale="<%=session.getAttribute("language")%>";
				//added genRSB variable to open committee from inbox
				let genRSB="<%=session.getAttribute("genRSB")%>";
				let serverip='<%=serverIp%>';  //Changes done by Karan Singh for PrivateIpAddress issue(EG-0009)
				let serverport=<%=serverport%>;	
				let serverType = "<%=serverType%>";
				let departmentTypeArray = new Array();
				let sectionArray =  new Array();
				let fValues='<%=FileValues%>';
				let dataclassfieldNames=new Array();
				//changes started for Dispatch Module by Rohit Verma
				let contextNameDispatch = "<%=sessionBean.getIniValue("ContextName")%>";
				//changes ended
				//changes for opening cutom process workitems by Rohit Verma
				let sProtocol='<%=sessionBean.getProtocol()%>';
				let sServerPort='<%=request.getServerPort()%>';
				let serverIpGlobal="<%=request.getServerName()%>";
				//changes ended
				let typeforKum="";
				let typeforSentitem=""; // Added for sent item filter
				//Changed by Arpan for Kum	
					let prevButtonFlag="";
				//added by kanika
				//changes started for reminder by Rohit Verma
				let isDueDateSet='<%=isDueDateSet%>';				
				//changes ended for reminder by Rohit Verma
				let sReminder_Config='<%=Reminder_Config%>';				
				let sMultipleDakForward_Enable='<%=MultipleDakForward_Enable%>';
				let sMultipleDakInitiate_Enable='<%=MultipleDakInitiate_Enable%>';
				let sPageNo="1";
				let sCabinetName='<%=sessionBean.getCabinetName()%>';//added by vaibhav.khandelwal for cc in office note
				let sFTSEnclosuresInDAK='<%=FTSEnclosuresInDAK%>';// Added by Neha Kathuria on MAy 11,2018 for FTS enable in Ufdaks
				//Changes for DateFormat - Gourav Singla  //EG10_0001
				let displayDateFormat="<%=(String)session.getAttribute("jsDisplayDateFormat")%>";
				function itemSelected_Kum(spvalue,type)
				{  

				
				//type = "ALL";
				sOrderBy="2";						
                sSortOrder="A";
                sRefSortOrder="A";		
                sRefOrderBy="2";
                sBatchCount=1;
                sNoOfRecordsToFetch = "10";
				sPrevIndex = "1";
				//commented on 17-05-2025 for loading inbox
                //document.getElementById(spvalue).style.color="orange";
				
                document.getElementById("itemlinks").innerHTML="";  
				//document.getElementById("leftline").style.visibility="hidden";
				//document.getElementById("leftline").style.display="none";
				//document.getElementById("specialfileslist").style.display="none";
				//document.getElementById("specialfileslist").style.visibility="hidden";
				
				//Commented by Anant Nigam for 	EGOV-1043 started
                //document.getElementById("listItems").style.height="335px";
				//Commented by Anant Nigam for 	EGOV-1043 ended
				
                if(lastItemSelected!="" && lastItemSelected!=spvalue)
                    document.getElementById(lastItemSelected).style.color="blue";
                lastItemSelected=spvalue;
				
				typeforKum=type;
					sLastSortField="";
					sFirstWorkItem="";
					sLastValue1="";			
					sFirstProcessInstance="";
					sLastWorkItem="";
					sLastValue2="";
					sLastProcessInstance="";
					sLastValue="";
					//Changes made by Lakshay on 16-06-2025 for next/prev on the basis of entryDateTime in NewgenOne for search inbox and Inbox 
					if(<%=isIBPS.equalsIgnoreCase("N")%>)
						sOrderBy="29";
					else
						sOrderBy="10";
					
					//changes by Lakshay ends here
					sSortOrder="D";
					sRefSortOrder="D";		
					sRefOrderBy="5";
					sFirstWorkItem="";
					bBatching="";
					if(type=="ALL")
					{
					sLastSortField="";
					sFirstWorkItem="";
					sLastValue1="";			
					sFirstProcessInstance="";
					sLastWorkItem="";
					sLastValue2="";
					sLastProcessInstance="";
					sLastValue="";
					//Changes made by Lakshay on 16-06-2025 for next/prev on the basis of entryDateTime in NewgenOne for search inbox and Inbox 
					if(<%=isIBPS.equalsIgnoreCase("N")%>)
						sOrderBy="29";
					else
						sOrderBy="10";
					
					//changes by Lakshay ends here
					sSortOrder="D";
					sRefSortOrder="D";		
					sRefOrderBy="5";
					renderInboxComponent();
					}
					else
					{
					
                    renderInboxComponent();
					}
				
				

}
			//Added by Sushil for sent item filter 
		function itemSelected_Sentitem(spvalue,type)
		{  
			sPageNo="1";
			typeforSentitem=type;
			
			renderSentItemsComponent(spvalue);
		}


			
	function createRule() { 
	
	     //let searchUrl = "actionitem/touserlist1/toUserSearch.jsp?SelectedUserList=";
		 let searchUrl = "actionitem/touserlist1/newsearch.jsp?ruleCreatedVia="+sLoggedInUser;
		
	     win = window.open(searchUrl,'Search1',"scrollbars=yes,resizable=no,toolbar=no,menubar=no,status=yes,location=no,top="+window1X+",left="+window1Y+",width="+window1W+",height=515");
		 //Changes for window close on logout by rishav started
		 window.top.addWindows(win);
		//Changes for window close on logout by rishav ended
	    }
				
	function modifyRule() { 
	     //let searchUrl = "actionitem/touserlist1/toUserSearch.jsp?SelectedUserList=";
		
		 let searchUrl = "actionitem/touserlist1/ruleList.jsp?ruleCreatedVia="+sLoggedInUser;
		
	     win = window.open(searchUrl,'Search1',"scrollbars=auto,resizable=no,toolbar=no,menubar=no,status=yes,location=no,top="+window1X+",left="+window1Y+",width="+window1W+",height=400");
		 //Changes for window close on logout by rishav started
		 window.top.addWindows(win);
		//Changes for window close on logout by rishav ended
	    }
		//Added by Pushkar (19/1/2017, Transfer Module JS function to load js module)
		function transferModule() { 
		  
	     //let searchUrl = "actionitem/touserlist1/toUserSearch.jsp?SelectedUserList=";
		
		 let strUrl="custom/transferModule.jsp?egovID=<%=egovUID%>";
		
	     win =window.open(strUrl,'Search1',"scrollbars=auto,resizable=no,toolbar=no,menubar=no,status=yes,location=no,top="+window1X+",left="+window1Y+",width="+screen.width+",height="+screen.height);
		 //Changes for window close on logout by rishav started
		 window.top.addWindows(win);
		//Changes for window close on logout by rishav ended
	    }
		// Added by Pushkar for Digital Signature
		function dongleODUserMap() { 
		let strUrl="custom/dongleODUserMap.jsp?egovID=<%=egovUID%>";
	     win =window.open(strUrl,'Search1',"scrollbars=auto,resizable=no,toolbar=no,menubar=no,status=yes,location=no,top="+window1X/2+",left="+window1Y/2+",width="+screen.width*.36+",height="+screen.height*.3);
		 //Changes for window close on logout by rishav started
		 window.top.addWindows(win);
		//Changes for window close on logout by rishav ended
	    }


	//Added by Vaibhav for RSS feeds
	let ajaxres = getXmlHttpRequestObject();
	let ajaxres2 = getXmlHttpRequestObject();
	
	function getXmlHttpRequestObject() {                            
		if (window.XMLHttpRequest) {                                    
			return new XMLHttpRequest();
		} else if(window.ActiveXObject) {                                       
			return new ActiveXObject("Microsoft.XMLHTTP");
		}
	}
	function getFacts() {
		if (ajaxres.readyState == 4 || ajaxres.readyState == 0) {
			
			ajaxres.open("POST", 'http://randomfactgenerator.net/factscript.php', true);
			//ajaxres.setRequestHeader('Content-Type','application/x-www-form-urlencoded');
			ajaxres.onreadystatechange = handleFactsOut;
			let param = "";
			ajaxres.send(param);
		}                       
	}
	
	function handleFactsOut() {
		if (ajaxres.readyState == 4) {
			
			let resText = ajaxres.responseText;
			let indexOfStart = resText.indexOf("$('#randomfactbox').html(");
			
			let indexOfEnd = resText.indexOf("<a href='http://randomfactgener");
			
			let extractText = resText.substring(indexOfStart+26, indexOfEnd);
			
			//document.getElementById('factLabel').innerHTML = extractText;		
			//mTimer = setTimeout('getOnlineUsers();',10000);				
		}
	}
	function getNews() {
		if (ajaxres2.readyState == 4 || ajaxres2.readyState == 0) {
			
			ajaxres2.open("GET", 'http://ajax.googleapis.com/ajax/services/feed/load?v=1.0&num=8&q=http%3A%2F%2Fnews.google.co.in%2Fnews%3Foutput%3Drss', true);
			//ajaxres2.setRequestHeader('Content-Type','application/x-www-form-urlencoded');
			ajaxres2.onreadystatechange = handleNewsOut;
			let param = "";
			ajaxres2.send(param);
		}                       
	}
	
	function handleNewsOut() {
	}
	//Changed ended by Vaibhav
		
	
	</script>	
<%
	int totalDepartmentTypes	=	0;
	for (departmentTypeList.reInitialize(true); departmentTypeList.hasMoreElements(true); departmentTypeList.skip(true)) 
    {
%>		
<script>
<!-- changes by kanchan for fetching department -->
		departmentTypeArray[<%=totalDepartmentTypes%>] = '<%=departmentTypeList.getVal("Value2")%>';
</script>
<%
queryString = dbQueryProperties.getProperty("Q339");
	queryString=EGovAPI.getPreparedQuery(queryString,departmentTypeList.getVal("Value1")+"\u0004int");
	if(queryString.equalsIgnoreCase("Arguments mismatch"))
	{	
		queryString="";
	}
	xmlResponse = executeCommonQuery(sessionBean.getCabinetName(), sessionBean.getUserDbId(), queryString, "IGGetPreparedData","preparedStmt")    ;
	DMSXmlList sectionTypeList = xmlResponse.createList("DataList", "Data");
	//Changes made by Kanchan on 04/09/2024 for reference no. formation
	//int totalSectionTypes	=	10;
%>
<script>		
		sectionArray[<%=totalDepartmentTypes%>] = new Array();
		<!--changes by Kanchan for reference no. formation ends here-->
</script>	
<%		
		int j	=	0;
		for (sectionTypeList.reInitialize(true); sectionTypeList.hasMoreElements(true); sectionTypeList.skip(true)) 
		{
%>		
<script>
			sectionArray[<%=totalDepartmentTypes%>][<%=j%>] = {"SectionName":'<%=sectionTypeList.getVal("Value2")%>',"SectionValue":'<%=sectionTypeList.getVal("Value1")%>'};
			<!-- changes ended here by kanchan -->
</script>
<%			
			j++;
		}
		totalDepartmentTypes ++;
	}
%>

<script>
let rtiEnableGlobal='<%=rtiEnable%>';
let pqEnableGlobal='<%=pqEnable%>';
let ccEnableGlobal='<%=ccEnable%>';
let cnmGlobal='<%=commEnable%>';
// changes by Shirish for handeling CheckMarx vulnerabilities
<%
				String safeChatEnable = "No"; 

				if(chatEnable!= null) {
				String val = chatEnable.trim();
            
				if("Yes".equalsIgnoreCase(val)) {
                safeChatEnable = "Yes";
				}
			}
    %>
let chatEnableGlobal='<%=safeChatEnable%>';

let DAKEnableGlobal='<%=DAKEnable%>';
let OfficeNoteEnableGlobal='<%=OfficeNoteEnable%>';
let sessionvar='<%=sessionBean.getIniValue("ContextName")%>';
let pageContext="<%=sessionBean.getIniValue("ContextName")%>";  // Changes by Indra to download enclosures
let auditEnable='<%=auditEnable%>';
// Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)
let dispatchEnableGlobal='<%=Dispatch_Config%>';
</script>

<%@ include file="custom/getDataclassList.process" %>

<!--  Changes by Vaibhav on 29/01/2015 for inclusion of AMCharts  -->
<%

//changes by Lakshay for the Dak Alias Name check 20-05-2025
String[] dakAliasFieldListArray = dakAliasFieldList.split(",");
String[] dakFieldListArray = dakFieldList.split(",");

Map<String,String> dakAliasFieldMap = new HashMap<>();

for(int i=0;i<dakFieldListArray.length;i++){
	dakAliasFieldMap.put(dakFieldListArray[i],dakAliasFieldListArray[i]);
}


String dakAliasFieldsJson = "{}";
JSONObject dakAliasFieldJsonObject = new JSONObject(dakAliasFieldMap);
dakAliasFieldsJson = dakAliasFieldJsonObject.toString();
session.setAttribute("dakAliasFieldMap",dakAliasFieldMap);

String[] fileAliasFieldListArray = fileAliasFieldList.split(",");
String[] fileFieldListArray = fileFieldList.split(",");

Map<String,String> fileAliasFieldMap = new HashMap<>();

for(int i=0;i<fileFieldListArray.length;i++){
	fileAliasFieldMap.put(fileFieldListArray[i],fileAliasFieldListArray[i]);
}

String fileAliasFieldsJson = "{}";
JSONObject fileAliasFieldJsonObject = new JSONObject(fileAliasFieldMap);
fileAliasFieldsJson = fileAliasFieldJsonObject.toString();
session.setAttribute("fileAliasFieldMap",fileAliasFieldMap);

//20-05-2025 changes by Lakshay ends here


//changes by Indra to allow supervisor rights to all supervisor group user
String hasSupervisorRights="false";
 String grpInpXml = "<?xml version=\"1.0\"?><NGOGetIDFromName_Input><Option>NGOGetIDFromName</Option><UserDBId>"+ sessionBean.getUserDbId() +"</UserDBId><CabinetName>"+ sessionBean.getCabinetName() +"</CabinetName><ObjectType>G</ObjectType><ObjectName>Supervisors</ObjectName></NGOGetIDFromName_Input>";
 String grpOutXml = sessionBean.execute(grpInpXml);

 DMSXmlResponse grpResponse = new DMSXmlResponse(grpOutXml);
 String grpIndex = grpResponse.getVal("ObjectIndex");

 String userInpXml = "<?xml version=\"1.0\"?><NGOGetUserListExt_Input><Option>NGOGetUserListExt</Option><CabinetName>"+ sessionBean.getCabinetName() +"</CabinetName><UserDBId>"+ sessionBean.getUserDbId() +"</UserDBId><GroupIndex>"+grpIndex+"</GroupIndex> <ExcludeGroupList></ExcludeGroupList><OrderBy>2</OrderBy><SortOrder>A</SortOrder><PreviousIndex>1</PreviousIndex><LastSortField></LastSortField><NoOfRecordsToFetch>250</NoOfRecordsToFetch></NGOGetUserListExt_Input>";
grpOutXml = sessionBean.execute(userInpXml);

 DMSXmlList grpList = (new DMSXmlResponse(grpOutXml)).createList("Users", "User");	
				
				
for (grpList.reInitialize(); grpList.hasMoreElements(); grpList.skip()) 
{
	
	if(sessionBean.getLoggedInUser().getUserName().equalsIgnoreCase(grpList.getVal("Name")))
		hasSupervisorRights="true";
}
session.setAttribute("hasSupervisorRights",hasSupervisorRights);	

//changes end


//changes by Lakshay Bansal for optimizing checkInCheckOutGroupNames check 14-05-2025

String hascheckInCheckOutRights="false";

String checkInCheckOutGroupNames[]=checkInCheckOutGroup.toLowerCase().split(",");

String grpInpXmlForCheckin="<?xml version=\"1.0\"?><NGOGetGroupListExt_Input><Option>NGOGetGroupListExt</Option><CabinetName>"+sessionBean.getCabinetName()+"</CabinetName><UserDBId>"+sessionBean.getUserDbId()+"</UserDBId><UserIndex>"+sessionBean.getLoggedInUser().getUserIndex()+"</UserIndex><OrderBy>2</OrderBy><SortOrder>A</SortOrder><PreviousIndex>0</PreviousIndex><LastSortField></LastSortField><NoOfRecordsToFetch>250</NoOfRecordsToFetch><MainGroupIndex>0</MainGroupIndex></NGOGetGroupListExt_Input>";

String grpOutXmlForCheckin = sessionBean.execute(grpInpXmlForCheckin);

DMSXmlResponse xmlResponseGroupForCheckin = new DMSXmlResponse(grpOutXmlForCheckin);
DMSXmlList groupListForCheckin = xmlResponseGroupForCheckin.createList("Groups", "Group");

for(int i=0;i<checkInCheckOutGroupNames.length;i++)
{
	for(groupListForCheckin.reInitialize(true);groupListForCheckin.hasMoreElements(true);groupListForCheckin.skip(true)){
	
		if(groupListForCheckin.getVal("GroupName").equalsIgnoreCase(checkInCheckOutGroupNames[i])){
			hascheckInCheckOutRights = "true";
			break;
		}
	}
	
	if(hascheckInCheckOutRights.equalsIgnoreCase("true"))
			break;
}
session.setAttribute("hascheckInCheckOutRights",hascheckInCheckOutRights);

//14-05-2025 changes BY Lakshay ends here		

int returnValue ;
	String sQueryString = "";
   
	

connectToServer();
	//Added by vaibhav.khandelwal for DAK REGISTER Procedure
			dbQueryProperties=(Properties) session.getAttribute("dbQueryPropertiesFile");		
			sQueryString = dbQueryProperties.getProperty("Q252");
			sQueryString=EGovAPI.getPreparedQuery(sQueryString,dakDataclass,fileDataclass);
			if(sQueryString.equalsIgnoreCase("Arguments mismatch"))
			{	
				EgovLogger.writeLog(sessionBean.getCabinetName(),'i', "In office.jsp -- Q252=" + sQueryString);
				sQueryString="";
			}
			
			
			DMSXmlResponse xmlResponse2 = executeCommonQuery(sessionBean.getCabinetName(), sessionBean.getUserDbId(), sQueryString, "IGGetPreparedData", "preparedStmt")    ;


			DMSXmlList dataClassDataList = xmlResponse2.createList("DataList", "Data");
			for (dataClassDataList.reInitialize(true); dataClassDataList.hasMoreElements(true); dataClassDataList.skip(true)){
					if(dataClassDataList.getVal("Value2").equalsIgnoreCase(dakDataclass)){
						//changes by kanchan for storing ddt name, index in session on 16-05-2024
						dakDDTTable="DDT_"+dataClassDataList.getVal("Value1");
						dakDDTTableIndex = dataClassDataList.getVal("Value1");
						session.setAttribute("dakDDTTable",dakDDTTable);
						session.setAttribute("dakDDTTableIndex",dakDDTTableIndex);
						
						}
					if(dataClassDataList.getVal("Value2").equalsIgnoreCase(fileDataclass)){
						
						fileDDTTable="DDT_"+dataClassDataList.getVal("Value1");
						fileDDTTableIndex=dataClassDataList.getVal("Value1");
						session.setAttribute("fileDDTTable",fileDDTTable);
						session.setAttribute("fileDDTTableIndex",fileDDTTableIndex);
						}
						//changes ended by kanchan
					} 
					String[] dakDataClassFieldNames = DAKDataClassFieldName.split(",");
					String[] fileDataClassFieldNames = FileDataClassFieldName.split(",");
									
					
			sQueryString = dbQueryProperties.getProperty("Q253");
			
			sQueryString=EGovAPI.getPreparedQuery(sQueryString,dakDDTTableIndex+"\u0004int");
			if(sQueryString.equalsIgnoreCase("Arguments mismatch"))
			{	
				EgovLogger.writeLog(sessionBean.getCabinetName(),'i', "In office.jsp -- Q253=" + sQueryString);
				sQueryString="";
			}
			
			xmlResponse2 = executeCommonQuery(sessionBean.getCabinetName(), sessionBean.getUserDbId(), sQueryString, "IGGetPreparedData", "preparedStmt")    ;

			
			dataClassDataList = xmlResponse2.createList("DataList", "Data");
			for (dataClassDataList.reInitialize(true); dataClassDataList.hasMoreElements(true); dataClassDataList.skip(true)){
			
					if(dataClassDataList.getVal("Value1").equalsIgnoreCase(DAKRegistrationFieldName))
						field_ReferenceNo="Field_"+dataClassDataList.getVal("Value2");
					if(dataClassDataList.getVal("Value1").equalsIgnoreCase(DAKSubjectField))
						field_Subject="Field_"+dataClassDataList.getVal("Value2");
					if(dataClassDataList.getVal("Value1").equalsIgnoreCase(DAKDepartmentFieldName))
						field_Department="Field_"+dataClassDataList.getVal("Value2");
					if(dataClassDataList.getVal("Value1").equalsIgnoreCase(DakCategoryFieldName))
						field_Category="Field_"+dataClassDataList.getVal("Value2");
						
						
					for(int i=0;i<dakDataClassFieldNames.length;i++){
						if(dataClassDataList.getVal("Value1").equalsIgnoreCase(dakDataClassFieldNames[i])){
							fieldToFetch = fieldToFetch +dakDDTTable+".Field_"+dataClassDataList.getVal("Value2")+",";
						}
					
					}
					
						
					
					}
					
					
					
			sQueryString = dbQueryProperties.getProperty("Q253");
			sQueryString=EGovAPI.getPreparedQuery(sQueryString,fileDDTTableIndex+"\u0004int");
			if(sQueryString.equalsIgnoreCase("Arguments mismatch"))
			{	
				EgovLogger.writeLog(sessionBean.getCabinetName(),'i', "In office.jsp -- Q253=" + sQueryString);
				sQueryString="";
			}
			
			xmlResponse2 = executeCommonQuery(sessionBean.getCabinetName(), sessionBean.getUserDbId(), sQueryString, "IGGetPreparedData", "preparedStmt")    ;

			
			dataClassDataList = xmlResponse2.createList("DataList", "Data");
			for (dataClassDataList.reInitialize(true); dataClassDataList.hasMoreElements(true); dataClassDataList.skip(true)){
			
					if(dataClassDataList.getVal("Value1").equalsIgnoreCase(FileNoFieldname))
						field_FileNumber="Field_"+dataClassDataList.getVal("Value2");
						
						for(int i=0;i<fileDataClassFieldNames.length;i++){
						if(dataClassDataList.getVal("Value1").equalsIgnoreCase(fileDataClassFieldNames[i])){
							fieldToFetch = fieldToFetch +fileDDTTable+".Field_"+dataClassDataList.getVal("Value2")+",";
						}
					
					}
						
					
					}
					if(fieldToFetch.endsWith(",")){
						try{
									fieldToFetch = fieldToFetch.substring(0,fieldToFetch.length() - 1);
						} catch (Exception e){
							
						}
						}
								
					
				//Ended by vaibhav.khandelwal for DAK REGISTER Procedure
%>

<%!

	String replace(String str, String pattern, String replace) {
        int s = 0;
        int e = 0;
        StringBuffer result = new StringBuffer();

        while ((e = str.indexOf(pattern, s)) >= 0) {
            result.append(str.substring(s, e));
            result.append(replace);
            s = e+pattern.length();
        }
        result.append(str.substring(s));
        return result.toString();
    }
%>	
<!--  Changes by Vaibhav ended  -->

<%
/////////////////////////////////////////Getting Dataclass Fields Info/////////////////////////////////////////////

	DMSInputXml dsinputXml = new DMSInputXml();
	
	String sinXm = dsinputXml.getGetIDFromNameXml(sessionBean.getCabinetName(), sessionBean.getUserDbId(),"X",FileDataClass,"","","");
	String sretXm = sessionBean.execute(sinXm);
	DMSXmlResponse xmlRes = new DMSXmlResponse(sretXm);
	String DataDefIndex = xmlRes.getVal("ObjectIndex");
	
	DMSInputXml inpXml = new DMSInputXml();
	String stXml = null;
	stXml = inpXml.getGetDataDefPropertyXml(sessionBean.getCabinetName(),
														sessionBean.getUserDbId(),
														DataDefIndex);
	String returnXml = sessionBean.execute(stXml);
	
	DMSXmlResponse dataDefResponse = new DMSXmlResponse(returnXml);
	DMSXmlList dfieldsList = dataDefResponse.createList("Fields", "Field");	
	
	int totalDataClassValues=0;
	%>
	<script>
	let dataclassobject=new Array();
	let sDataDefIndex='<%=DataDefIndex%>';
		//Added by vaibhav.khandelwal for DAK REGISTER Procedure
	let dakDDTTable='<%=dakDDTTable%>';
	let fileDDTTable='<%=fileDDTTable%>';
	let field_ReferenceNo='<%=field_ReferenceNo%>';
	let field_Subject='<%=field_Subject%>';
	let field_Department='<%=field_Department%>';
	let field_Category='<%=field_Category%>';
	let field_FileNumber='<%=field_FileNumber%>';
	let fieldToFetch='<%=fieldToFetch%>';
	let allDataClassFieldsList='<%=allDataClassFieldsList%>';
	let fieldToFetchList = allDataClassFieldsList.split( "," );
	//Changes by Lakshay for Alias name 20-05-2025
	let dakFieldToFetchString = '<%=dakFieldList%>';
	let dakFieldToFetchList = dakFieldToFetchString.split(",");
	let fileFieldToFetchString = '<%=fileFieldList%>';
	let fileFieldToFetchList = fileFieldToFetchString.split(",");
	let dakAliasName = <%= dakAliasFieldsJson%>;
	let fileAliasName = <%= fileAliasFieldsJson%>
	
	//20-05-2025 changes by Lakshay ends here
		//Ended by vaibhav.khandelwal for DAK REGISTER Procedure
	
	</script>
	
	<%
	for (dfieldsList.reInitialize(); dfieldsList.hasMoreElements(); dfieldsList.skip()) 
	{
	%>
	<script>
	dataclassobject[<%=totalDataClassValues%>]=new Object();
	dataclassobject[<%=totalDataClassValues%>].IndexName = '<%=dfieldsList.getVal("IndexName")%>';
	dataclassobject[<%=totalDataClassValues%>].IndexId = '<%=dfieldsList.getVal("IndexId")%>';
	dataclassobject[<%=totalDataClassValues%>].IndexType = '<%=dfieldsList.getVal("IndexType")%>';
	dataclassobject[<%=totalDataClassValues%>].IndexLength = '<%=dfieldsList.getVal("IndexLength")%>';
	dataclassobject[<%=totalDataClassValues%>].Pickable = '<%=dfieldsList.getVal("Pickable")%>';
	dataclassobject[<%=totalDataClassValues%>].IndexValue = '<%=dfieldsList.getVal("IndexValue")%>';
	</script>
	<%
		totalDataClassValues++;
	}
	
/////////////////////////////////////////////////////END///////////////////////////////////////////////////////////

//////////////////////////////////////////Getting Dataclass Fields Info/////////////////////////////////////////////

	DMSInputXml sinputXml = new DMSInputXml();
	String dataDefIndex = "";
	// Changes by kanchan for getIDForName call from session
	dataDefIndex=(String)session.getAttribute("DocDataDefIndex");
	if(dataDefIndex==null || dataDefIndex.equalsIgnoreCase("null") || dataDefIndex.equalsIgnoreCase("undefined") || dataDefIndex.equalsIgnoreCase("")){
	String sinXml = sinputXml.getGetIDFromNameXml(sessionBean.getCabinetName(), sessionBean.getUserDbId(),"X",document_Dataclass,"","","");
	String sretXml = sessionBean.execute(sinXml);
	DMSXmlResponse xmlRespons = new DMSXmlResponse(sretXml);
	dataDefIndex = xmlRespons.getVal("ObjectIndex");
	session.setAttribute("DocDataDefIndex",dataDefIndex);
	}
	DMSInputXml inputXmlll = new DMSInputXml();
	String strXml = null;
	strXml = inputXmlll.getGetDataDefPropertyXml(sessionBean.getCabinetName(),
														sessionBean.getUserDbId(),
														dataDefIndex);
	String retXmlll = sessionBean.execute(strXml);
	
	DMSXmlResponse dataDefRespons = new DMSXmlResponse(retXmlll);
	DMSXmlList fieldsListtt = dataDefRespons.createList("Fields", "Field");	
	String dataDefFieldIndexes="";
	Map<String,String> fieldIndexMap = new HashMap<String,String>();
	for (fieldsListtt.reInitialize(); fieldsListtt.hasMoreElements(); fieldsListtt.skip()) 
	{
		// changes done by Sajal Goel for Baehal starts here
		if(dakFieldList.indexOf(fieldsListtt.getVal("IndexName"))>-1) {
			fieldIndexMap.put(fieldsListtt.getVal("IndexName"),fieldsListtt.getVal("IndexId"));
		}
		
		if(fieldsListtt.getVal("Pickable").equalsIgnoreCase("Y") && fieldsListtt.getVal("IndexName").equalsIgnoreCase(DakCategoryFieldName))
			{
					
				String pickListInpXml = "<?xml version=\"1.0\"?><NGOGetPickList_Input><Option>NGOGetPickList</Option><CabinetName>"+ sessionBean.getCabinetName() +"</CabinetName><UserDBId>"+ sessionBean.getUserDbId() +"</UserDBId><DataDefIndex>"+dataDefIndex+"</DataDefIndex><ObjectType>D</ObjectType><FieldIndex>"+fieldsListtt.getVal("IndexId")+"</FieldIndex><PrefixString>*</PrefixString><StartFrom>1</StartFrom><NoOfRecordsToFetch>50</NoOfRecordsToFetch></NGOGetPickList_Input>";
				
				//inputXmlll.getPickListXml( sessionBean.getCabinetName(),  sessionBean.getUserDbId(), dataDefIndex,  "D", fieldsListtt.getVal("IndexId"), "*" , "1",  "50");
					String pickListOutXml = sessionBean.execute(pickListInpXml);
				
				DMSXmlList fieldsListttt = (new DMSXmlResponse(pickListOutXml)).createList("Fields", "FieldValue");	
				for (fieldsListttt.reInitialize(); fieldsListttt.hasMoreElements(); fieldsListttt.skip()) 
				{
						dakCategories = dakCategories+","+fieldsListttt.getVal("FieldValue");	
						
				}
				try{
				dakCategories = dakCategories.substring(1);
				}catch (Exception e){
				}
				session.setAttribute("sDAKCategories",dakCategories);
				} 
			
	}
	for(String str:dakFieldList.split(",")) {
		if(!dataDefFieldIndexes.isEmpty())
			dataDefFieldIndexes += ";";
		dataDefFieldIndexes += str+"#"+fieldIndexMap.get(str);
	}
	// changes done by Sajal Goel ends here
	
	//Changes by Anant
	
	DMSInputXml sinputXmlNew = new DMSInputXml();
	
	String sinXmlNew = sinputXmlNew.getGetIDFromNameXml(sessionBean.getCabinetName(), sessionBean.getUserDbId(),"X",FileDataClass,"","","");
	String sretXmlNew = sessionBean.execute(sinXmlNew);
	DMSXmlResponse xmlResponsNew = new DMSXmlResponse(sretXmlNew);
	String dataDefIndexFile = xmlResponsNew.getVal("ObjectIndex");
	
	DMSInputXml inputXmlllNew = new DMSInputXml();
	String strXmlNew = null;
	strXmlNew = inputXmlllNew.getGetDataDefPropertyXml(sessionBean.getCabinetName(),
														sessionBean.getUserDbId(),
														dataDefIndexFile);
	String retXmlllNew = sessionBean.execute(strXmlNew);
	
	DMSXmlResponse dataDefResponsNew = new DMSXmlResponse(retXmlllNew);
	DMSXmlList fieldsListttNew = dataDefResponsNew.createList("Fields", "Field");	
	String dataDefFieldIndexesNew="";
	Map<String,String> fieldIndexMapNew = new HashMap<String,String>();
	for (fieldsListttNew.reInitialize(); fieldsListttNew.hasMoreElements(); fieldsListttNew.skip()) 
	{
		
		
		if(fieldsListttNew.getVal("Pickable").equalsIgnoreCase("Y") && fieldsListttNew.getVal("IndexName").equalsIgnoreCase(FileCategoryFieldName))
			{
					
				String pickListInpXml = "<?xml version=\"1.0\"?><NGOGetPickList_Input><Option>NGOGetPickList</Option><CabinetName>"+ sessionBean.getCabinetName() +"</CabinetName><UserDBId>"+ sessionBean.getUserDbId() +"</UserDBId><DataDefIndex>"+dataDefIndexFile+"</DataDefIndex><ObjectType>D</ObjectType><FieldIndex>"+fieldsListttNew.getVal("IndexId")+"</FieldIndex><PrefixString>*</PrefixString><StartFrom>1</StartFrom><NoOfRecordsToFetch>50</NoOfRecordsToFetch></NGOGetPickList_Input>";
				
				
					String pickListOutXml = sessionBean.execute(pickListInpXml);
				fieldsListttNew = (new DMSXmlResponse(pickListOutXml)).createList("Fields", "FieldValue");	
				for (fieldsListttNew.reInitialize(); fieldsListttNew.hasMoreElements(); fieldsListttNew.skip()) 
				{
						fileCategories = fileCategories+","+fieldsListttNew.getVal("FieldValue");	
						
				}
				try{
				fileCategories = fileCategories.substring(1);
				}catch (Exception e){
				}
			}
	}
	                     
							session.setAttribute("sFileCategories",fileCategories);

	
	//Changes ended by Anant
	
	//Added by Ashish Anurag on 01-09-2023 to set DAKInProcess and NoteInProcess folder IDS as session attributes
	String DAKInProcessFolderID = "";
	String NoteInProcessFolderID = "";
	
	strXmlNew = sinputXmlNew.getGetIDFromNameXml(sessionBean.getCabinetName(), sessionBean.getUserDbId(),"F",properties2.getProperty("NoteInProcessFolderName"),"0","","");
	retXmlllNew = sessionBean.execute(strXmlNew);
	xmlResponsNew = new DMSXmlResponse(retXmlllNew);
	NoteInProcessFolderID = xmlResponsNew.getVal("ObjectIndex");
	session.setAttribute("NoteInProcessFolderID",NoteInProcessFolderID);
	
	strXmlNew = sinputXmlNew.getGetIDFromNameXml(sessionBean.getCabinetName(), sessionBean.getUserDbId(),"F",properties2.getProperty("DAKInProcessFolderName"),"0","","");
	retXmlllNew = sessionBean.execute(strXmlNew);
	xmlResponsNew = new DMSXmlResponse(retXmlllNew);
	DAKInProcessFolderID = xmlResponsNew.getVal("ObjectIndex");
	session.setAttribute("DAKInProcessFolderID",DAKInProcessFolderID);
	
	//01-09-2023 changes by Ashish end here
	
	
	
//////////////////////////////////////////Getting outwarddak Dataclass Fields Info/////////////////////////////////////////////
	
	if(OutwardDAKEnable.equalsIgnoreCase("yes")){
	
	DMSInputXml sinputXml1 = new DMSInputXml();
	String sinXml1 = sinputXml1.getGetIDFromNameXml(sessionBean.getCabinetName(), sessionBean.getUserDbId(),"X",outwardDak_Dataclass,"","","");
	String sretXml1 = sessionBean.execute(sinXml1);
	DMSXmlResponse xmlRespons1 = new DMSXmlResponse(sretXml1);
	String dataDefIndex1 = xmlRespons1.getVal("ObjectIndex");
	
	DMSInputXml inputXmlll2 = new DMSInputXml();
	String strXml1 = null;
	strXml1 = inputXmlll2.getGetDataDefPropertyXml(sessionBean.getCabinetName(),
														sessionBean.getUserDbId(),
														dataDefIndex1);
	
	String retXmlll2 = sessionBean.execute(strXml1);
	DMSXmlResponse dataDefRespons1 = new DMSXmlResponse(retXmlll2);
	DMSXmlList fieldsListtt1 = dataDefRespons1.createList("Fields", "Field");	
	for (fieldsListtt1.reInitialize(); fieldsListtt1.hasMoreElements(); fieldsListtt1.skip()) 
	{
		if(fieldsListtt1.getVal("Pickable").equalsIgnoreCase("Y") && fieldsListtt1.getVal("IndexName").equalsIgnoreCase(OutwardDakDispatchFieldName.trim()))
			{   
				String pickListInpXml1 = "<?xml version=\"1.0\"?><NGOGetPickList_Input><Option>NGOGetPickList</Option><CabinetName>"+ sessionBean.getCabinetName() +"</CabinetName><UserDBId>"+ sessionBean.getUserDbId() +"</UserDBId><DataDefIndex>"+dataDefIndex1+"</DataDefIndex><ObjectType>D</ObjectType><FieldIndex>"+fieldsListtt1.getVal("IndexId")+"</FieldIndex><PrefixString>*</PrefixString><StartFrom>1</StartFrom><NoOfRecordsToFetch>50</NoOfRecordsToFetch></NGOGetPickList_Input>";
				
				String pickListOutXml1 = sessionBean.execute(pickListInpXml1);
				DMSXmlList fieldsListttt2 = (new DMSXmlResponse(pickListOutXml1)).createList("Fields", "FieldValue");	
				for (fieldsListttt2.reInitialize(); fieldsListttt2.hasMoreElements(); fieldsListttt2.skip()) 
				{
					outwarddakCategories = outwarddakCategories+","+fieldsListttt2.getVal("FieldValue");	
				}
				try{
				outwarddakCategories = outwarddakCategories.substring(1);
				}catch (Exception e){
				}
			 }
			    
			
	}
	}
//Changes done by Nikita.Patidar for checking Rights for DAK & Note folders(EG4-0012)
	String grpInpXml1 = "<?xml version=\"1.0\"?><NGOGetIDFromName_Input><Option>NGOGetIDFromName</Option><UserDBId>"+ sessionBean.getUserDbId() +"</UserDBId><CabinetName>"+ sessionBean.getCabinetName() +"</CabinetName><ObjectType>G</ObjectType><ObjectName>Business Admin</ObjectName></NGOGetIDFromName_Input>";
	String grpOutXml1 = sessionBean.execute(grpInpXml1);
	DMSXmlResponse groupResponse=new DMSXmlResponse(grpOutXml1);
	String groupIndex = groupResponse.getVal("ObjectIndex");

	String userInpXml1 = "<?xml version=\"1.0\"?><NGOGetUserListExt_Input><Option>NGOGetUserListExt</Option><CabinetName>"+ sessionBean.getCabinetName() +"</CabinetName><UserDBId>"+ sessionBean.getUserDbId() +"</UserDBId><GroupIndex>"+groupIndex+"</GroupIndex> <ExcludeGroupList></ExcludeGroupList><OrderBy>2</OrderBy><SortOrder>A</SortOrder><PreviousIndex>1</PreviousIndex><LastSortField></LastSortField><NoOfRecordsToFetch>250</NoOfRecordsToFetch></NGOGetUserListExt_Input>";
	grpOutXml1 = sessionBean.execute(userInpXml1);

	DMSXmlList fieldsList2 = (new DMSXmlResponse(grpOutXml1)).createList("Users", "User");	
	boolean isAdmin=false;//Changes done by Nikita.Patidar for checking Rights for DAK folders(EG4-0012)
	for (fieldsList2.reInitialize(); fieldsList2.hasMoreElements(); fieldsList2.skip()) 
	{
		
		if(sessionBean.getLoggedInUser().getUserName().equalsIgnoreCase(fieldsList2.getVal("Name")))
		isAdmin=true;
	}
	
	//Changes done by Nikita.Patidar for checking Rights for DAK & Note folders(EG4-0012)

	if(loggedInUser_Department!="No Department Set")
	{		
	
	//if(!hasSupervisorRights.equalsIgnoreCase("true") && !isAdmin)
	//{
	DMSInputXml folderIDInputXML=new DMSInputXml();
	// Changes by kanchan for getIDForName call from session
	DMSXmlResponse folderIDOutputXML=null;
	String FolderIdforDAK="";
	String FolderIdforDAKOutput="";
	FolderIdforDAK=(String)session.getAttribute("DAKFolderIdforDAK");
	if(FolderIdforDAK==null || FolderIdforDAK.equalsIgnoreCase("null") || FolderIdforDAK.equalsIgnoreCase("undefined") || FolderIdforDAK.equalsIgnoreCase("")){
	FolderIdforDAKOutput=sessionBean.execute(folderIDInputXML.getGetFolderIdForNameXml(sessionBean.getCabinetName(),sessionBean.getUserDbId(), "0", "DAKS"));
	
	folderIDOutputXML=new DMSXmlResponse(FolderIdforDAKOutput);
		if(Integer.parseInt(folderIDOutputXML.getVal("Status"))==0){
			
			FolderIdforDAK=folderIDOutputXML.getVal("FolderIndex");
			session.setAttribute("DAKFolderIdforDAK",FolderIdforDAK);
			FolderIdforDAKOutput=sessionBean.execute(folderIDInputXML.getGetFolderIdForNameXml(sessionBean.getCabinetName(),sessionBean.getUserDbId(), FolderIdforDAK, (String)session.getAttribute("LoggedInUser_UserDepartment")));
			
			folderIDOutputXML=new DMSXmlResponse(FolderIdforDAKOutput);
			FolderIdforDAK=folderIDOutputXML.getVal("FolderIndex");		
			String rightsOnDAKfolder=getRightsOnObject(sessionBean,"F", FolderIdforDAK, (String)session.getAttribute("LoggedInUser_UserDepartment") );		
			session.setAttribute("rightsOnDepartmentInDAK",rightsOnDAKfolder);
		}
	}else{	
			FolderIdforDAKOutput=sessionBean.execute(folderIDInputXML.getGetFolderIdForNameXml(sessionBean.getCabinetName(),sessionBean.getUserDbId(), FolderIdforDAK, (String)session.getAttribute("LoggedInUser_UserDepartment")));
			
			folderIDOutputXML=new DMSXmlResponse(FolderIdforDAKOutput);
			FolderIdforDAK=folderIDOutputXML.getVal("FolderIndex");		
			String rightsOnDAKfolder=getRightsOnObject(sessionBean,"F", FolderIdforDAK, (String)session.getAttribute("LoggedInUser_UserDepartment") );		
			session.setAttribute("rightsOnDepartmentInDAK",rightsOnDAKfolder);
	}
	// Changes by Saurabh Rajput for getIDFromName call from session
	FolderIdforDAK=(String)session.getAttribute("FolderIdDAKInProcess");
	if(FolderIdforDAK==null || FolderIdforDAK.equalsIgnoreCase("null") || FolderIdforDAK.equalsIgnoreCase("undefined") || FolderIdforDAK.equalsIgnoreCase("")){
	String FolderIdforDAKInProcess=sessionBean.execute(folderIDInputXML.getGetFolderIdForNameXml(sessionBean.getCabinetName(),sessionBean.getUserDbId(), "0", "DAKInProcess"));
    folderIDOutputXML=new DMSXmlResponse(FolderIdforDAKInProcess);
	
		if(Integer.parseInt(folderIDOutputXML.getVal("Status"))==0){
			
			FolderIdforDAK=folderIDOutputXML.getVal("FolderIndex");		
			String rightsOnDAKfolder=getRightsOnObject(sessionBean,"F", FolderIdforDAK, sessionBean.getLoggedInUser().getUserName() );		
			session.setAttribute("rightsOnDAKInProcess",rightsOnDAKfolder);
			session.setAttribute("FolderIdDAKInProcess",FolderIdforDAK);
			
		}
	}
   // Changes by Saurabh Rajput ends for getIDFromName call from session
   String sParentFolderId="0";
   String sFolderName="DRAFTS";
     String sFolderIndex=ComponentInit.getFolderIdFromName(sFolderName,sessionBean,sParentFolderId);
     String status="";
     if(sFolderIndex.equals("-1"))
     {
         sFolderIndex=createFolder(sessionBean,sFolderName, sParentFolderId);
             status=setACLFlag(sessionBean,sFolderIndex,sFolderName);
         
     }
     
     sFolderName=sessionBean.getLoggedInUser().getUserName().toUpperCase();
     sParentFolderId=sFolderIndex;
     sFolderIndex=  ComponentInit.getFolderIdFromName(sFolderName,sessionBean,sParentFolderId);

     
     //create the User Folder in the Drafts and set the ACL
        if(sFolderIndex.equals("-1"))
        {
            
            sFolderIndex=createFolder(sessionBean,sFolderName, sParentFolderId);
             status=setACLFlag(sessionBean,sFolderIndex,sFolderName);
        }
     
   // Changes by kanchan for getIDForName call from session
   String FolderIdforNote="";
   String FolderIdforNoteOutput="";
   String rightsOnNotefolder="";
	FolderIdforNote=(String)session.getAttribute("FolderIdforDraft");
	if(FolderIdforNote==null || FolderIdforNote.equalsIgnoreCase("null") || FolderIdforNote.equalsIgnoreCase("undefined") || FolderIdforNote.equalsIgnoreCase("")){
   FolderIdforNoteOutput=sessionBean.execute(folderIDInputXML.getGetFolderIdForNameXml(sessionBean.getCabinetName(),sessionBean.getUserDbId(), "0", "DRAFTS"));
		folderIDOutputXML=new DMSXmlResponse(FolderIdforNoteOutput);
		FolderIdforNote=folderIDOutputXML.getVal("FolderIndex");
		session.setAttribute("FolderIdforDraft",FolderIdforNote);
	
		if(Integer.parseInt(folderIDOutputXML.getVal("Status"))==0){
					
			FolderIdforNoteOutput=sessionBean.execute(folderIDInputXML.getGetFolderIdForNameXml(sessionBean.getCabinetName(),sessionBean.getUserDbId(), FolderIdforNote,sessionBean.getLoggedInUser().getUserName().toUpperCase()));
			
			folderIDOutputXML=new DMSXmlResponse(FolderIdforNoteOutput);
			FolderIdforNote=folderIDOutputXML.getVal("FolderIndex");	
			
			/*condition modified on 25-04-2025 by Ashish due to OD 11 SP3 'Logged in cannot perform operation on self' restriction
			rightsOnNotefolder=getRightsOnObject(sessionBean,"F", FolderIdforNote, sessionBean.getLoggedInUser().getUserName().toUpperCase());
			*/
			if(FolderIdforNote==null || FolderIdforNote.equalsIgnoreCase("null") || FolderIdforNote.equalsIgnoreCase("undefined") || FolderIdforNote.equalsIgnoreCase("")){
				EgovLogger.writeLog(sessionBean.getCabinetName(),'i', "Folder not found in office.jsp: " + sessionBean.getLoggedInUser().getUserName().toUpperCase());
			}
			else{
				rightsOnNotefolder = "111111";
			}
			//25-04-2025 changes end here

			session.setAttribute("rightsOnUserInDrafts",rightsOnNotefolder);
		}
	}else{
		
		FolderIdforNoteOutput=sessionBean.execute(folderIDInputXML.getGetFolderIdForNameXml(sessionBean.getCabinetName(),sessionBean.getUserDbId(), FolderIdforNote,sessionBean.getLoggedInUser().getUserName().toUpperCase()));
			
			folderIDOutputXML=new DMSXmlResponse(FolderIdforNoteOutput);
			FolderIdforNote=folderIDOutputXML.getVal("FolderIndex");	
			
			/*condition modified on 25-04-2025 by Ashish due to OD 11 SP3 'Logged in cannot perform operation on self' restriction
			rightsOnNotefolder=getRightsOnObject(sessionBean,"F", FolderIdforNote, sessionBean.getLoggedInUser().getUserName().toUpperCase());
			*/
			if(FolderIdforNote==null || FolderIdforNote.equalsIgnoreCase("null") || FolderIdforNote.equalsIgnoreCase("undefined") || FolderIdforNote.equalsIgnoreCase("")){
				EgovLogger.writeLog(sessionBean.getCabinetName(),'i', "Folder not found in office.jsp: " + sessionBean.getLoggedInUser().getUserName().toUpperCase());
			}
			else{
				rightsOnNotefolder = "111111";
			}
			//25-04-2025 changes end here
			
			session.setAttribute("rightsOnUserInDrafts",rightsOnNotefolder);
		
	}
	//ended here
	
	// Changes by kanchan for getIDForName call from session
	FolderIdforNote=(String)session.getAttribute("FolderIdNoteInProcess");
	if(FolderIdforNote==null || FolderIdforNote.equalsIgnoreCase("null") || FolderIdforNote.equalsIgnoreCase("undefined") || FolderIdforNote.equalsIgnoreCase("")){
	String FolderIdforNoteInProcess=sessionBean.execute(folderIDInputXML.getGetFolderIdForNameXml(sessionBean.getCabinetName(),sessionBean.getUserDbId(), "0", "NoteInProcess"));
    folderIDOutputXML=new DMSXmlResponse(FolderIdforNoteInProcess);
	
		if(Integer.parseInt(folderIDOutputXML.getVal("Status"))==0){
			
			FolderIdforNote=folderIDOutputXML.getVal("FolderIndex");		
			String rightsOnNoteInProcess=getRightsOnObject(sessionBean,"F", FolderIdforNote, sessionBean.getLoggedInUser().getUserName() );		
			session.setAttribute("rightsOnNoteInProcess",rightsOnNoteInProcess);
			session.setAttribute("FolderIdNoteInProcess",FolderIdforNote);
		}
	}
	//}	
	}	
   //Changes ended by Nikita.Patidar for checking Rights for DAK & Note folders(EG4-0012)
/////////////////////////////////////////////////////END///////////////////////////////////////////////////////////

	//added by Ashish Anurag on 24-04-2025 to get Process ID of egov process for WFSearchWorkItemList API
	String egovProcessID = "";
	
	try
	{	
		String getProcessListInXml = "<?xml version=\"1.0\"?><WMGetProcessList_Input><Option>WMGetProcessList</Option><EngineName>"+sessionBean.getCabinetName()+"</EngineName><SessionId>"+sessionBean.getUserDbId()+"</SessionId><DataFlag>N</DataFlag><LatestVersionFlag></LatestVersionFlag><Filter><StateFlag>E</StateFlag></Filter><BatchInfo> <SortOrder>A</SortOrder><LastValue></LastValue><LastIndex></LastIndex><NoOfRecordsToFetch>100</NoOfRecordsToFetch><RightFlag></RightFlag></BatchInfo></WMGetProcessList_Input>";
			
		String getProcessListOutXml = execute(getProcessListInXml);
			
		DMSXmlResponse getProcessListOutXmlResp = new DMSXmlResponse(getProcessListOutXml);
			
		DMSXmlList getProcessListOutXmlList;
		
		if (getProcessListOutXmlResp.getVal("MainCode").equalsIgnoreCase("0")) 
		{
			getProcessListOutXmlList = getProcessListOutXmlResp.createList("ProcessList","ProcessInfo");
			for (getProcessListOutXmlList.reInitialize(true);getProcessListOutXmlList.hasMoreElements(true); getProcessListOutXmlList.skip(true))
			{
				if(egovProcessName.equalsIgnoreCase(getProcessListOutXmlList.getVal("Name"))){
					egovProcessID = getProcessListOutXmlList.getVal("ID");
					break;
				}
			}
		}
	}
	catch(Exception ex){
		System.out.println("Some exception occured while getting process def ID in office.jsp: " + ex.getMessage());
		ex.printStackTrace();
	}
	session.setAttribute("egovProcessID",egovProcessID);	
	session.setAttribute("egovProcessName",egovProcessName);	
	
	//24-04-2025 changes by Ashish end here

%>

<!-- Changed position by Neha Kathuria on May 28,2017 for handling date format -->
		 <script language="JavaScript" src="estyle/scripts/doccab/estyle.js"></script>



        <script language="JavaScript" src="scripts/office.js"></script>
        <script language="JavaScript" src="scripts/actionitem.js"></script>
        <script language="JavaScript" src="scripts/ajax.js"></script>
        <script language="JavaScript" src="scripts/logout.js"></script>
        <script language="JavaScript" src="scripts/drafts.js"></script>
        <script language="JavaScript" src="scripts/unfiledDaks.js"></script>
		<script language="JavaScript" src="scripts/outwardDaks.js"></script>
        <script language="JavaScript" src="scripts/inbox.js"></script>
		<!-- changes started for iBPS queues by Rohit Verma -->
		<script language="JavaScript" src="scripts/ofqueue.js"></script>
		<!-- changes-->
        <script language="JavaScript" src="scripts/sentitems.js"></script>
        <script language="JavaScript" src="scripts/dakstatus.js"></script>
        <script language="JavaScript" src="scripts/adminfiles.js"></script>
        <script language="JavaScript" src="scripts/dakSearch.js"></script>

        <script language="JavaScript" src="scripts/ufdaks/calendarFuture.js"></script>
        <script language="JavaScript" src="scripts/createFile.js"></script>
        <script language="JavaScript" src="scripts/fileindex.js"></script>
        <script language="JavaScript" src="scripts/specialfiles.js"></script>
        <script language="JavaScript" src="scripts/caseFiles.js"></script>
		<script language="JavaScript" src="scripts/actionitemsearch.js"></script>
		<!-- changes started for Dispatch Module by Rohit Verma-->
		<script language="JavaScript" src="scripts/dispatchView.js"></script>
		<!--changes ended-->
        <script language="JavaScript" src="estyle/scripts/doccab/ewgeneral.js"></script>
        
		<%
		if(!session.getAttribute("language").toString().equalsIgnoreCase("en"))
		{		
		%>
		<script language="JavaScript" src="estyle/<%=session.getAttribute("language")%>/scripts/doccab/constants.js"></script>
		<%
		}
		else
		{
		%>		
        <script language="JavaScript" src="estyle/scripts/doccab/constants.js"></script>
		<%
		}
		%>
        <script language="JavaScript" src="scripts/folderoperations.js"></script>
        <script language="JavaScript" src="scripts/documentoperations.js"></script>
		<script language="JavaScript" src="scripts/dakregister.js"></script>
		<script language="JavaScript" src="scripts/dashboard.js"></script>
		<script language="JavaScript" src="scripts/notifications.js"></script>
		<!--For DatePicker -->
	    <script language="JavaScript" src="bootstrap/js/bootstrap-datepicker.js"></script>
		<link rel="stylesheet" type="text/css" href="bootstrap/css/datepicker.css" />
		
        <script language="JavaScript">
		////////Added by Amit Pandey on 26/11/2012 fro DAK Search//////////
		let fromUserDakSearch = '';
		let subjectDakSearch = '';
		let fileNoDakSearch = '';
		let deptDakSearch = '';
		let categoryDakSearch = '';
		let statusDakSearch = '';
		let docRefNoDakSearch = '';
		let toUserDakSearch = '';
		let fromDateDakSearch = '';
		let toDateDakSearch = '';
		let sDAKSubjectField = '<%=DAKSubjectField%>';
		let sDakCategoryFieldName = '<%=DakCategoryFieldName%>';
		let sFileCategoryFieldName = '<%=FileCategoryFieldName%>';
		let sOutwardDakDispatchFieldName = '<%=OutwardDakDispatchFieldName%>';
		
		let sDakCategoryValue ='';
		let sDakDateValue =''; //changes done by sahil Bhuria on 7 JULY 2021 for common Date format (EG10-0001)
		let sToWhomValue ='';  //changes done by sahil Bhuria on 7 JULY 2021 for common Date format (EG10-0001)
		let sDakDateFieldName = '<%=DakDateFieldName%>';
		let sRangeOnDateField = '<%=RangeOnDateField%>';
		let searchDAK = '<%=rsb.getString("Search")%>' +' '+ '<%=rsb.getString("DAK")%>';
		let trackDAK  = '<%=rsb.getString("Track")%>' +' '+ '<%=rsb.getString("DAK")%>';
		let sDakCategories = '<%=dakCategories%>';
		let sFileCategories = '<%=fileCategories%>';
		let sOutwarddakCategories = '<%=outwarddakCategories%>';
		let outward_DataClassName = '<%=outwardDak_Dataclass%>';
			
		let outDAKFields = '<%=outDAKFields%>'; 
		let isNewgenone='<%=session.getAttribute("isNewgenone")%>';		
		let outDAKFieldsList = outDAKFields.split( "," );
		let sDAKReferenceNoLetter = '<%=DAKReferenceNoLetter%>';
		let sDAKDepartment = '<%=DAKDepartment%>';
		let sOutwardDAKRegistration = '<%=OutwardDAKRegistration%>';
		let sDAKDispatchDate = '<%=DAKDispatchDate%>';			
		let sUfdaksViewRights = '<%=ufdaksViewRights%>';
		let sSentItemSearchEnable = '<%=sentItemSearchEnable%>';
		let sUniqueNoPP = '<%=UniqueNoPP%>';

		//Changes started for EG-0008: User Credentials traverses in Cleartext
		let bf = new Blowfish('DES');
		
		/*modified to stop password being read in cleartext with KM module
		let userpassword="";
		*/

		//Changes ended for EG-0008: User Credentials traverses in Cleartext
		

		////////Addition by Amit Pandey ends///////////////////////////////
		////////////////Added By Varun For Making General Document Dataclass///////////////////
			let document_DataClassName = '<%=document_Dataclass%>';
			
			let dakFieldList = '<%=dakFieldList%>';
			let dakFieldIndexString = '<%=dataDefFieldIndexes%>';
			let document_DataClassNameIndex = <%=dataDefIndex%>;
			let fileDocSearchFieldList = '<%=fileDocSearchFieldList%>';
			let fileDocDisplayFieldList = '<%=fileDocDisplayFieldList%>';
			let dataclassFieldsList = dakFieldList.split( "," );
			let fileDocSearchFields = fileDocSearchFieldList.split( "," );
			let fileDocDisplayFields = fileDocDisplayFieldList.split( "," );
			let sDAKRegistrationFieldName = '<%=DAKRegistrationFieldName%>';
			let sDAKDepartmentFieldName = '<%=DAKDepartmentFieldName%>';	
			//Added by priyanka on 29jul2015------------------------
			let sDAKSectionFieldName='<%=DAKSectionFieldName%>';
			//Ended--------------
			let sToWhomFieldName = '<%=ToWhomFieldName%>';			
			let sDAKRegistrationFieldPrefix = '<%=DAKRegistrationFieldPrefix%>';			
			let docLastSearch_Dataclass = "";
			let docLastSearch_DcFieldsVal = "";
			let deleteDocId = new Array(); //For Deleting Drafts 
		//////////////////////////////////////End By Varun/////////////////////////////////////
            let lastItemSelected="";				// createTable Function
            let sHeaderString="";
            let sIdString="";
            let sValueString=new Array();
            let sDocumentIndexString=new Array();
			let sFolderId=new Array();
			let sInitiatedBy=new Array();
			let sFromUser=new Array();
			let sAssignedUser=new Array();
			let sMessageBox=new Array();
			let sSubject=new Array();
			let workitemId = new Array();
			let processInstanceId = new Array();
			let workitemPriority = new Array();
			let sWorkitemType=new Array();
			let sOrderByValue=new Array();
			let sReadStatus=new Array();
            let flagDocId=new Array();
            let sDocumentList=new Array();
            let sBatchCount=1;
			
			//adding new variables on use in renderInboxComponent1 method
			let sValueStringA=new Array();
            let sDocumentIndexStringA=new Array();
			let sFolderIdA=new Array();
			let sInitiatedByA=new Array();
			let sFromUserA=new Array();
			let sAssignedUserA=new Array();
			let sMessageBoxA=new Array();
			let sSubjectA=new Array();
			let workitemIdA = new Array();
			let processInstanceIdA = new Array();
			let workitemPriorityA = new Array();
			let sWorkitemTypeA=new Array();
			let sReadStatusA=new Array();
            let flagDocIdA=new Array();
            let sDocumentListA=new Array();
 
            let sOrderBy="";						// sorting and batching
            let sSortOrder="";		
            let sFirstIndex="0";		
            let sLastIndex="0";		
            let sLastField="";			
            let sFirstField="";
            let sRefSortOrder="";		
            let sRefOrderBy="";					
            let bNextBatch="false";
            let bPrevBatch="false";
            let bBatching="";
            let sPrevIndex="0";
            let sLastSortField="";
			let sFirstWorkItem="";
            let sLastValue1="";			
			let sFirstProcessInstance="";
			let sLastWorkItem="";
            let sLastValue2="";
            let sLastProcessInstance="";
            let sLastValue="";
			//let sPageNo="1";
			let sCurrentWorkitem="";
			let sCurrentProcessInstance="";
			let sCurrentValue="";
			//Changes by Nikita (EOFFINT-1440)
			let	sNoOfRecordsForCurBatch="10";
			let lastWorkitemForCurBatch;
			let lastProcessInstanceForCurBatch;
			let lastValueForCurBatch;
			let lastValueForOrderBy;
			let lastValueForSortOrder;
			//Changes end
            let xElemPos;				
            let yElemPos;

            let txtAdminFileNo="";		// AdminFiles Search
            let txtAdminFIleSub="";

            let sLoggedInUserIndex='<%=sessionBean.getLoggedInUser().getUserIndex()%>';
    
			let sLoggedInUser='<%=sessionBean.getLoggedInUser().getUserName()%>';
			
            let sSortedTableIndex="0";	// unknown	
            
            let sStartFrom="1";
            let elemIndex="";

            let itemView="";			// OpenItem function
            let adminFiles="";			// Used in adminfiles.js
            let documentList="";                // Used in adminfiles.js
            let selectedItemIndex=0;
			
			let sUserDepttFolderName=""; 

            let sUfDakFolderId="";              //For Unfiled daks, used in unfiledDaks.js

			//Added by Priti Solanki on 28 Sep 2011 for removing volumeindex hard coding
			let sUfDakFolderVolumeId="";		//For Unfiled daks, used in unfiledDaks.js
			//Additions by Priti Solanki end
			
            let dakSearchInnerHtml=""; //For DAK Search
            
            // unknown	
            let sBatchOption="false";
           
            //let daks="";			   //declared but never used	
            //let alarmsInnerHtml="";
            
            //Used in Action Item Search 
            let sAIStatusCombo="";
            let sAISubject="";
            let sAITrackNo="";
            let sAIInitOrForwardCombo="";
            let sAINumberCombo="";
            let sAIPeriodCombo="";
            let sAIDateFrom="";
            let sAIDateUpto="";
            let sAIStageCombo="";
            let sAIUser="";
            let sAIFromDepartment="";
            let sAIToDepartment="";
            let sAIImportance="";
            let sAIOpenSince="";
            let sAIDateRadio="";
            //Used in Action Item Search

			let allWindows = new Array();   //to close all open windows
			let nextFileNo = "";
			//ended here
			///Added By Varun For Karnataka POC////
			let loggedInUserInitials = '<%=LoggedInUser_UserInitials%>';
			let sFileNoFieldname = 'FileNumber';
			let file_DataClassName = '<%=file_Dataclass%>';
			let loggedInUserDepartment = '<%=loggedInUser_Department%>';
			let loggedInUser_UserSection = '<%=LoggedInUser_UserSection%>';
			//Added by Srikant for fix the length of FileNoFieldLen 
			let file_FileNoFieldLen = '<%=FileNoFieldLen%>';
			let egovProcessName = '<%=egovProcessName%>';
			let menuwidth = screen.width*(20.5/100);
			let screenwidth = screen.width-menuwidth;
			let listItemsHeight = screen.height*(43.6/100);
			
			let FileNumberarabic='<%=FileNumberarabic%>';
			let FileNamearabic='<%=FileNamearabic%>';
			let Departmentarabic='<%=Departmentarabic%>';
			let Sectionarabic='<%=Sectionarabic%>';
			let CourtCase='<%=CourtCase%>';
			//CC Config
			let CCEnable='<%=session.getAttribute("CCEnable")%>';
			let sNoteRefNo='<%=sNoteRefNo%>'; //added by vaibhav.khandelwal for note reference number
			
			//Changes done by Nikita.Patidar for checking Rights for DAK & Note folders(EG4-0012)
			let rightsOnDepartmentInDAK='<%=session.getAttribute("rightsOnDepartmentInDAK")%>';
			let rightsOnDAKInProcess='<%=session.getAttribute("rightsOnDAKInProcess")%>';
			let rightsOnUserInDrafts='<%=session.getAttribute("rightsOnUserInDrafts")%>';
			let rightsOnNoteInProcess='<%=session.getAttribute("rightsOnNoteInProcess")%>';
			
		   //Changes ended by Nikita.Patidar for checking Rights for DAK & Note folders(EG4-0012)
			
			//Added By Varun For Default BAM Report
			let bamReportUrl ='<%=sessionBean.getProtocol()%>'+"://"+'<%=serverIpAddress%>'+":"+'<%=serverHttpPort%>'+"/bam/login/login.jsp?CalledFrom=EXT&UserIndex=<%=sessionBean.getLoggedInUser().getUserIndex()%>&UserId=<%=sessionBean.getLoggedInUser().getUserName()%>&CabinetName=<%=sessionBean.getCabinetName()%>&LaunchClient=RI&ReportIndex=<%=dashboardReportIndex%>&EmbeddedView=01111011&SessionId=<%=sessionBean.getUserDbId()%>";
			
			//Added by Vaibhav on 20/01/2015 for calendar
			//Added By Varun for Calendar
			let dashboardCalDt = new Date();
			//Changes ended by Vaibhav
			////////Added by Amit Pandey on 26/11/2012 for Dak Search 
			let subjectValue="";
			
			function setSearchCriteria()
			{
				
				let fileNoDakSearch1=document.getElementById("fileNoDakSearch1").value;
	let toUserDakSearch1=document.getElementById("toUserDakSearch1").value;
	let statusDakSearch1=document.getElementById("statusDakSearch1").value;
	let dateDakSearch1=document.getElementById("dateDakSearch1").value;
	let dateDakSearch2=document.getElementById("dateDakSearch2").value;
	let categoryDakSearch1=document.getElementById("categoryDakSearch1").value;
	let docRefNoDakSearch1=document.getElementById("docRefNoDakSearch1").value;
	let subjectDakSearch1=document.getElementById("subjectDakSearch1").value;
	let deptDakSearch1=document.getElementById("deptDakSearch1").value;
	
	//Changes by Shweta Trisal (EG10-0011)
	if(fileNoDakSearch1=="" && toUserDakSearch1=="" && statusDakSearch1=="---Select---" && dateDakSearch1=="" && dateDakSearch2=="" && categoryDakSearch1=="---Select---" && docRefNoDakSearch1=="" && subjectDakSearch1=="" && deptDakSearch1=="")
	{
	alert(Enter_Search_Criteria);
	return false;
	}
				
				
				//changes started by Rohit Verma for File number,Dak reference number and subject with special characters - EGOV-538
				toUserDakSearch 	= encode_utf8(document.getElementById('toUserDakSearch1').value);
				//fromUserDakSearch 	= document.getElementById('fromUserDakSearch1').value;
				subjectDakSearch 	= encode_utf8(document.getElementById('subjectDakSearch1').value);
				fileNoDakSearch 	= encode_utf8(document.getElementById('fileNoDakSearch1').value);
				deptDakSearch 		= encode_utf8(document.getElementById('deptDakSearch1').value);
			    categoryDakSearch 	= encode_utf8(document.getElementById("categoryDakSearch1").options[document.getElementById("categoryDakSearch1").selectedIndex].value);//document.getElementById('categoryDakSearch1').value;
				if(categoryDakSearch=='---Select---')
					categoryDakSearch='';	
				

				statusDakSearch 	= encode_utf8(document.getElementById("statusDakSearch1").options[document.getElementById("statusDakSearch1").selectedIndex].value);
				docRefNoDakSearch 	= encode_utf8(document.getElementById('docRefNoDakSearch1').value);
				//changes ended by Rohit Verma for File number,Dak reference number and subject with special characters - EGOV-538
				if(statusDakSearch=='---Select---')
					statusDakSearch='';
				fromDateDakSearch 	= document.getElementById('dateDakSearch1').value;
				fromDateDakSearch 	= fromDateDakSearch.replace(/\//g,"-");
				
				toDateDakSearch 	= document.getElementById('dateDakSearch2').value;
				toDateDakSearch 	= toDateDakSearch.replace(/\//g,"-");
				
				if( ((fromDateDakSearch==null || fromDateDakSearch=="") && !(toDateDakSearch==null || toDateDakSearch=="")) || (!(fromDateDakSearch==null || fromDateDakSearch=="") && (toDateDakSearch==null || toDateDakSearch=="")) ){
					alert(SELECT_START_END_DATES);
					return;
				}else if((fromDateDakSearch.split("-")[2] > toDateDakSearch.split("-")[2]) || (fromDateDakSearch.split("-")[1] > toDateDakSearch.split("-")[1] && fromDateDakSearch.split("-")[2] == toDateDakSearch.split("-")[2]) || (fromDateDakSearch.split("-")[1] == toDateDakSearch.split("-")[1] && fromDateDakSearch.split("-")[0] > toDateDakSearch.split("-")[0] && fromDateDakSearch.split("-")[2] == toDateDakSearch.split("-")[2])){
					alert(START_SMALLER_END_DATE);
					return;
				}
				/*else{
				
					
					let frmDate= new Date(document.getElementById('dateDakSearch1').value);
					let to_Date= new Date(document.getElementById('dateDakSearch2').value);
					
					if(to_Date < frmDate){
						alert("Enter the correct date range.");

						return;
					}
				}	*/ 
				
				//document.getElementById("itemSelected").innerHTML=searchDak;
				document.getElementById('toUserDakSearch1').value="";
				//document.getElementById('fromUserDakSearch1').value="";
				document.getElementById('subjectDakSearch1').value="";
				document.getElementById('fileNoDakSearch1').value="";
				document.getElementById('deptDakSearch1').value="";
				document.getElementById('categoryDakSearch1').selectedIndex = "---Select---";
				document.getElementById("statusDakSearch1").selectedIndex = "---Select---";
				document.getElementById('docRefNoDakSearch1').value="";
				document.getElementById('dateDakSearch1').value="";
				document.getElementById('dateDakSearch2').value="";
				//document.getElementById('fadedBack').style.display='none';
				//document.getElementById('DakSearchCriteria').style.display='none';			
				
				setDefault();
				itemSelected('searchDak');
			}
			////////Changes by Amit Pandey	ends
			//CC Config
			function getCCConfig()
			{
				return CCEnable;
			}
			//changes started for iBPS queues by Rohit Verma
			function ofQueueItemSelected(processId, processName, spvalue,id, queueName)
			{ 				
				sOrderBy="2";						
				sSortOrder="A";
				sRefSortOrder="A";		
				sRefOrderBy="2";
				sBatchCount=1;
				sNoOfRecordsToFetch = "10";
				sPrevIndex = "1";
				document.getElementById("itemlinks").innerHTML="";  
				document.getElementById("listItems").style.height=listItemsHeight;
				lastItemSelected=spvalue;
				if(spvalue=="OFQueues")
				{					
					typeforKum = "ALL";
					//document.getElementById("itemSelected").innerHTML=document.getElementById(spvalue).innerHTML;
					sLastSortField="";					
					sFirstWorkItem="";
					sLastValue1="";			
					sFirstProcessInstance="";
					sLastWorkItem="";
					sLastValue2="";
					sLastProcessInstance="";
					sLastValue="";
					sOrderBy="10";
					sSortOrder="D";
					sRefSortOrder="D";		
					sRefOrderBy="5";					
					sOFQueueId=id;
					sProcessName=processName;
					sProcessId=processId;
					sQueueName=queueName;
					renderOFInboxComponent();		
				}					
				return;
			}
			//changes ended
			
            function itemSelected(spvalue,subSpValue)
            {
			
			 let searchVal ="";
				// Added By Neha Kathuria on july 27,2015 for auto refresh	
			
				renderdashboardComponent2();
                sOrderBy="2";						
                sSortOrder="A";
                sRefSortOrder="A";		
                sRefOrderBy="2";
                sBatchCount=1;
                sNoOfRecordsToFetch = "10";
				sPrevIndex = "1";
				try{
					//document.getElementById(spvalue).style.color="orange";
				}catch(e) {}

                document.getElementById("itemlinks").innerHTML="";  
				
                //Changes for EGOV-1519 started by Anant Nigam
				document.getElementById("noticationcentermain").style.overflow="hidden";
				document.getElementById("listIDocs").style.display='none';
                document.getElementById("listItems").style.height=listItemsHeight;
				//Changes for EGOV-1519 ended by Anant Nigam
				
				//Added by Anant Nigam for EGOV-1297 started
				document.getElementById("noticationcentermain").style.height='100%';
				//document.getElementById("notificationcenterpanel").style.height='100%';
				//Added by Anant Nigam for EGOV-1297 ended
				
                lastItemSelected=spvalue;

				if(spvalue=="dashboard")
				{
					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
					document.getElementById("itemSelected").innerHTML=document.getElementById(spvalue).innerHTML;
				 // Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)
					document.getElementById("itemSelected").style.display = 'none';
					document.getElementById("itemlinks").style.display = 'none';
					document.getElementById("pageList").style.display = 'none';
					
					sLastSortField="";
					sFirstWorkItem="";
					sLastValue1="";			
					sFirstProcessInstance="";
					sLastWorkItem="";
					sLastValue2="";
					sLastProcessInstance="";
					sLastValue="";
					//Changes made by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					//sOrderBy="5";
					//Changes made by Lakshay on 16-06-2025 for next/prev on the basis of entryDateTime in NewgenOne for search inbox and Inbox 
					if(<%=isIBPS.equalsIgnoreCase("N")%>)
						
						sOrderBy="29";
					else
						sOrderBy="10";
					
					//changes by Lakshay ends here
					
					
					sSortOrder="D";
					sRefSortOrder="D";		
					sRefOrderBy="5";
					
                    renderdashboardComponent('<%=dashboardReport1Data%>','<%=dashboardReport2Data%>','<%=dashboardReport3Data%>','<%=rtiEnable%>','<%=pqEnable%>','<%=ccEnable%>','<%=commEnable%>'); // Changed by Neha Kathuria on Aug 26,2016 for all egov modules Counting issue when any module is disable 
					getChartData();
					
					
				}
			//Added by Vaibhav on 20/01/2015 for calendar
				else if(spvalue=="calendar")
				{
					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
					//Added by Anant Nigam for EGOV-1297 started
					document.getElementById("noticationcentermain").style.height='200%';
					document.getElementById("notificationcenterpanel").style.height='200%';
					//Added by Anant Nigam for EGOV-1297 ended
					
					/*commented by rishav for bootstrap version update: EG2024-050 
					document.getElementById("pageList").innerHTML = "";
					*/
					document.getElementById("itemlinks").innerHTML = "";
					document.getElementById("listItems").innerHTML = "";
					document.getElementById("listIDocs").innerHTML = "";
					document.getElementById("itemSelected").innerHTML = My_Calendar;
					let innerHtml = "";
					innerHtml +="<br><div class='row' >";
					// Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)
					//Changes by kanchan for calender scroll bar on 02-12-2024  EGOV-11.6.01
					innerHtml += 	"<div class='col-xs-12 col-sm-12 col-md-12 col-lg-12' style='background-color:white; height: 500px; overflow-y: scroll;' id='dashboardCalendar'></div>";
					innerHtml +="<div>";

					document.getElementById("listItems").innerHTML=innerHtml;
					showCalendar();
					
				}
			//Changes ended by Vaibhav
			    
                else if(spvalue=="inbox")
				{	

					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
				// Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)
                    document.getElementById("itemSelected").style.display = 'block';
					document.getElementById("itemlinks").style.display = 'block';
					document.getElementById("pageList").style.display = 'block';			
					typeforKum = "ALL";
					//document.getElementById("itemSelected").innerHTML=document.getElementById(spvalue).innerHTML;
					document.getElementById("itemSelected").innerHTML=Inbox;
				
					sLastSortField="";
					sFirstWorkItem="";
					sLastValue1="";			
					sFirstProcessInstance="";
					sLastWorkItem="";
					sLastValue2="";
					sLastProcessInstance="";
					sLastValue="";
					//Changes made by Lakshay on 16-06-2025 for next/prev on the basis of entryDateTime in NewgenOne for search inbox and Inbox 
					if(<%=isIBPS.equalsIgnoreCase("N")%>)
						sOrderBy="29";
					else
						sOrderBy="10";
					
					//changes by Lakshay ends here
					sSortOrder="D";
					sRefSortOrder="D";		
					sRefOrderBy="5";
					//Changes done by Nikita Patidar for EOFFINT-1440
					flagForCurBatch=true;
					if (subSpValue=='inbox')
						subjectValue='';
						
					if(subjectValue=="" || typeof(subjectValue)=='undefined')
                        renderInboxComponent();					
					else
					{
						renderInboxComponent1(subjectValue);
						
					}
					
		
				}
				//Added by priyanka on 16feb15------------------
				else if(spvalue=="dakFilter")
				{
					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
					typeforKum = "Dak";
					document.getElementById("itemSelected").innerHTML=document.getElementById(spvalue).innerHTML;
				
					sLastSortField="";
					sFirstWorkItem="";
					sLastValue1="";			
					sFirstProcessInstance="";
					sLastWorkItem="";
					sLastValue2="";
					sLastProcessInstance="";
					sLastValue="";
					sOrderBy="10";
					sSortOrder="D";
					sRefSortOrder="D";		
					sRefOrderBy="5";
					//Changes done by Nikita Patidar for EOFFINT-1440
					flagForCurBatch=true;
                    renderInboxComponent();				
					
				}
				else if(spvalue=="noteFilter")
				{		
					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
					typeforKum = "Note";
					document.getElementById("itemSelected").innerHTML=document.getElementById(spvalue).innerHTML;
				
					sLastSortField="";
					sFirstWorkItem="";
					sLastValue1="";			
					sFirstProcessInstance="";
					sLastWorkItem="";
					sLastValue2="";
					sLastProcessInstance="";
					sLastValue="";
					sOrderBy="10";
					sSortOrder="D";
					sRefSortOrder="D";		
					sRefOrderBy="5";
					//Changes done by Nikita Patidar for EOFFINT-1440
					flagForCurBatch=true;
                    renderInboxComponent();				
					
				}
				else if(spvalue=="fileFilter")
				{
					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
					typeforKum = "File";
					document.getElementById("itemSelected").innerHTML=document.getElementById(spvalue).innerHTML;
				
					sLastSortField="";
					sFirstWorkItem="";
					sLastValue1="";			
					sFirstProcessInstance="";
					sLastWorkItem="";
					sLastValue2="";
					sLastProcessInstance="";
					sLastValue="";
					sOrderBy="10";
					sSortOrder="D";
					sRefSortOrder="D";		
					sRefOrderBy="5";
					//Changes done by Nikita Patidar for EOFFINT-1440
					flagForCurBatch=true;
                    renderInboxComponent();				
					
				}
				else if(spvalue=="rtiFilter")
				{		
				//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
					typeforKum = "RTI";
					document.getElementById("itemSelected").innerHTML=document.getElementById(spvalue).innerHTML;
				
					sLastSortField="";
					sFirstWorkItem="";
					sLastValue1="";			
					sFirstProcessInstance="";
					sLastWorkItem="";
					sLastValue2="";
					sLastProcessInstance="";
					sLastValue="";
					sOrderBy="10";
					sSortOrder="D";
					sRefSortOrder="D";		
					sRefOrderBy="5";
					
                    renderInboxComponent();				
					
				}
				else if(spvalue=="pqFilter")
				{		
			
			//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
					typeforKum = "PQ";
					document.getElementById("itemSelected").innerHTML=document.getElementById(spvalue).innerHTML;
				
					sLastSortField="";
					sFirstWorkItem="";
					sLastValue1="";			
					sFirstProcessInstance="";
					sLastWorkItem="";
					sLastValue2="";
					sLastProcessInstance="";
					sLastValue="";
					sOrderBy="10";
					sSortOrder="D";
					sRefSortOrder="D";		
					sRefOrderBy="5";
					
                    renderInboxComponent();				
					
				}
				else if(spvalue=="ccFilter")
				{		
			//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
					typeforKum = "CC";
					document.getElementById("itemSelected").innerHTML=document.getElementById(spvalue).innerHTML;
				
					sLastSortField="";
					sFirstWorkItem="";
					sLastValue1="";			
					sFirstProcessInstance="";
					sLastWorkItem="";
					sLastValue2="";
					sLastProcessInstance="";
					sLastValue="";
					sOrderBy="10";
					sSortOrder="D";
					sRefSortOrder="D";		
					sRefOrderBy="5";
					
                    renderInboxComponent();				
					
				}
				else if(spvalue=="cnmFilter")
				{	
			//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
					typeforKum = "CNM";
					document.getElementById("itemSelected").innerHTML=document.getElementById(spvalue).innerHTML;
				
					sLastSortField="";
					sFirstWorkItem="";
					sLastValue1="";			
					sFirstProcessInstance="";
					sLastWorkItem="";
					sLastValue2="";
					sLastProcessInstance="";
					sLastValue="";
					sOrderBy="10";
					sSortOrder="D";
					sRefSortOrder="D";		
					sRefOrderBy="5";
					
                    renderInboxComponent();				
					
				}
				//Ended by priyanka----------------
                else if(spvalue=="createfile" || spvalue=="Create_CC")
				{ 
			//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
					//getNextFileNo(); 
					//document.getElementById("itemSelected").innerHTML=document.getElementById(spvalue).innerHTML;
					// Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)
				document.getElementById("itemSelected").style.display = 'block';
				document.getElementById("itemlinks").style.display = 'block';
				document.getElementById("pageList").style.display = 'block';
					document.getElementById("itemSelected").innerHTML=Create_File;
					if(subSpValue=='isCC')
					{		
						renderCreateFileComponent('isCC');
					}
					else
					{ 
						
						//changes started for Part File Option by Rohit Verma
						let partFileOption;
						<%
						if(sessionBean.getIniValue("PartFileOption","0").equalsIgnoreCase("1"))
						{					
						%>
							partFileOption=1;
							renderCreateFileComponent(partFileOption);
						<%
						}
						else
						{
						%>
							partFileOption=0;
							renderCreateFileComponent(partFileOption);
						<%
						}
						%>
					}
					//changes ended
				}
				//Added by Nikita.Patidar for creating special files(EG7-0008)
				else if(spvalue=="createSpecialFiles")
				{
					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
					//Egov-12.1-0001
					//document.getElementById("itemSelected").innerHTML=document.getElementById(spvalue).innerHTML;
					document.getElementById("itemSelected").style.display = 'block';
				document.getElementById("itemlinks").style.display = 'block';
				document.getElementById("pageList").style.display = 'block';
					document.getElementById("itemSelected").innerHTML=Create_Special_File;
					renderCreateSpecialFilesComponent();
				}
                else if(spvalue=="underConstruction1"||spvalue=="underConstruction2"||spvalue=="underConstruction3"||spvalue=="underConstruction4")
                {
					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
                    document.getElementById("itemSelected").innerHTML=document.getElementById(spvalue).innerHTML;
                    document.getElementById("itemlinks").innerHTML="";
                    document.getElementById(spvalue).style.color="orange";           
                    let innerHtml="";
                    innerHtml=innerHtml+"<table border='0' width='99%' cellpadding='3' cellspacing='0'>";
                    innerHtml=innerHtml+"<tr><td align=center class=EWErrorMessage><%=rsb.getString("This_page_is_under_construction")%></td></tr>";
                    innerHtml=innerHtml+"</table>";       
                    document.getElementById("listItems").innerHTML=innerHtml;
                }
                     
                else if(spvalue=="ufDaks") {
					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
                		// Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)
                    document.getElementById("itemSelected").style.display = 'block';
					document.getElementById("itemlinks").style.display = 'block';
					document.getElementById("pageList").style.display = 'block';					
					document.getElementById("itemSelected").innerHTML=document.getElementById(spvalue).innerHTML;
					sOrderBy="5";	
					sPrevIndex="0";
					sSortOrder="D";
                    renderUnfiledDaks(spvalue,subSpValue);					
				}
				else if(spvalue=="OutwardDAK"){
					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
						// Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)
					  document.getElementById("itemSelected").style.display = 'block';
					document.getElementById("itemlinks").style.display = 'block';
					document.getElementById("pageList").style.display = 'block';
					
					document.getElementById("itemSelected").innerHTML=document.getElementById(spvalue).innerHTML;
					
					sOrderBy="5";
					sSortOrder="D";
					sPrevIndex="0";
                    renderOutwardDAKs(spvalue);    
				}
				else if(spvalue=="casefiles")
					renderCaseFiles(spvalue);
                else if(spvalue=="sentitems")
				{
					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
						// Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)
					  document.getElementById("itemSelected").style.display = 'block';
					document.getElementById("itemlinks").style.display = 'block';
					document.getElementById("pageList").style.display = 'block';
					//document.getElementById("itemSelected").innerHTML=document.getElementById(spvalue).innerHTML;
					document.getElementById("itemSelected").innerHTML=Sent_items;
					sOrderBy="5";
					sSortOrder="D";
					sRefSortOrder="D";		
					sRefOrderBy="5";
					
					if(typeof(subSpValue)=='undefined' || subSpValue =='ALL' || subSpValue=='' )
						typeforSentitem='';
					else
						typeforSentitem=subSpValue;
					
					//typeforSentitem='';
					sPageNo=1;
                    renderSentItemsComponent(spvalue);
				}
                else if(spvalue=="status")
                {
                    initializeSearchForm();
                    //renderDakStatusComponent(spvalue);
                }
                else if(spvalue=="adminFiles")
				{
					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
						// Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)
					document.getElementById("itemSelected").style.display = 'block';
					document.getElementById("itemlinks").style.display = 'block';
					document.getElementById("pageList").style.display = 'block';
				
					//document.getElementById("itemSelected").innerHTML=document.getElementById(spvalue).innerHTML;
					document.getElementById("itemSelected").innerHTML=Search_File;
					// Changes by Saurabh Rajput for EG10-0031 on 20/10/2022 (Search court case)
                    renderAdminFilesSearchComponenent("File");          
				}
				// Added by Saurabh Rajput for EG10-0031 on 20/10/2022 (Search court case)
				else if(spvalue=="Search_CC")
				{
					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
				
					document.getElementById("itemSelected").innerHTML=document.getElementById(spvalue).innerHTML;
                    renderAdminFilesSearchComponenent("CourtCase");          
				}
				// ends
                else  if(spvalue=="drafts")
				{
					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
						// Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)
					document.getElementById("itemSelected").style.display = 'block';
					document.getElementById("itemlinks").style.display = 'block';
					document.getElementById("pageList").style.display = 'block';
					document.getElementById("itemSelected").innerHTML=document.getElementById(spvalue).innerHTML;
					sOrderBy="4";
					sSortOrder="D";
					sPrevIndex="0";
					renderDraftsComponent("false");  
				}  
                else  if(spvalue=="createnew"){
					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
					document.getElementById("itemSelected").style.display = 'block';
					document.getElementById("itemlinks").style.display = 'block';
					document.getElementById("pageList").style.display = 'block';
                    renderDraftsComponent("true");
				}
				else  if(spvalue=="cnmhome") 
				{
					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
					let commUrlParams = "?CabinetName=<%=sessionBean.getCabinetName()%>&UserDbId=<%=sessionBean.getUserDbId()%>&UserIndex=<%=sessionBean.getLoggedInUser().getUserIndex()%>&UserName=<%=eUser.getUserName()%>&JtsIpAdd=<%=sessionBean.getJtsIpAddress()%>&JtsPort=<%=sessionBean.getJtsPort()%>&redirectURLComm=";
					let commUrl = "office.jsf";
					window.open("/committee/externalLogin.jsf"+commUrlParams+commUrl,"CommitteeMeetingsHome","scrollbars=yes,resizable=yes,toolbar=no,Addressbar=no,menubar=no,status=yes,width=1500,height=800"); 
					//window.open("/committee/office.jsf","Committee Meetings Home","scrollbars=yes,resizable=yes,toolbar=no,Addressbar=no,menubar=no,status=yes,width=1500,height=800"); 
				}
				else  if(spvalue=="createcomm") 
				{
					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
					//changes by Somya Bagai to open committee meeting module
					
					
					
					//added genRSB parameter to open committee from inbox
			

					/* Added by Suneet Saurabh for Hindi Version of Committee Meeting*/
					<%
						if(session.getAttribute("language").toString().equalsIgnoreCase("en"))
						{
					%>
						let commUrlParams1 = "CabinetName=<%=sessionBean.getCabinetName()%>&UserDbId=<%=sessionBean.getUserDbId()%>&JtsIpAdd=<%=sessionBean.getJtsIpAddress()%>&JtsPort=<%=sessionBean.getJtsPort()%>&dataBaseType=<%=sessionBean.getDataBaseType()%>&strEnc=UTF-8&localeString=en&MenuOption=createcommittee";
<%
						}
%>
<% 
					if(session.getAttribute("language").toString().equalsIgnoreCase("hi"))
						{
%>
						let commUrlParams1 = "CabinetName=<%=sessionBean.getCabinetName()%>&UserDbId=<%=sessionBean.getUserDbId()%>&JtsIpAdd=<%=sessionBean.getJtsIpAddress()%>&JtsPort=<%=sessionBean.getJtsPort()%>&dataBaseType=<%=sessionBean.getDataBaseType()%>&strEnc=UTF-8&localeString=hi&MenuOption=createcommittee";
<%
						}
%>
					
					
					let width=screen.width;
					let height=screen.height;
					//window.open("/<%=sessionBean.getIniValue("committeeWarName")%>/externalLogin.jsp?"+commUrlParams1+"&rid="+MakeUniqueNumber(),"Committee & Meetings",""); 		
//added by vinoth					
					window.open("/<%=sessionBean.getIniValue("committeeWarName")%>/externalLogin.jsp?"+commUrlParams1+"&rid="+MakeUniqueNumber(),"Committee & Meetings","scrollbars=yes,resizable=yes,toolbar=no,Addressbar=no,menubar=no,status=yes,top=" + screen.width + ", left=" + screen.height + ",width="+screen.width+",height="+screen.height);
				}		else  if(spvalue=="CommMeet") 
				{
					//changes by Somya Bagai to open committee meeting module
			

					/* Added by Suneet Saurabh for Hindi Version of Committee Meeting*/
					<%
						if(session.getAttribute("language").toString().equalsIgnoreCase("en"))
						{
					%>
						let commUrlParams1 = "CabinetName=<%=sessionBean.getCabinetName()%>&UserDbId=<%=sessionBean.getUserDbId()%>&JtsIpAdd=<%=sessionBean.getJtsIpAddress()%>&JtsPort=<%=sessionBean.getJtsPort()%>&dataBaseType=<%=sessionBean.getDataBaseType()%>&strEnc=UTF-8&localeString=en";
<%
						}
%>
<% 
					if(session.getAttribute("language").toString().equalsIgnoreCase("hi"))
						{
%>
						let commUrlParams1 = "CabinetName=<%=sessionBean.getCabinetName()%>&UserDbId=<%=sessionBean.getUserDbId()%>&JtsIpAdd=<%=sessionBean.getJtsIpAddress()%>&JtsPort=<%=sessionBean.getJtsPort()%>&dataBaseType=<%=sessionBean.getDataBaseType()%>&strEnc=UTF-8&localeString=hi";
<%
						}
%>
					
					
					let width=screen.width;
					let height=screen.height;
					//window.open("/<%=sessionBean.getIniValue("committeeWarName")%>/externalLogin.jsp?"+commUrlParams1+"&rid="+MakeUniqueNumber(),"Committee & Meetings",""); 		
//added by vinoth					
					window.open("/<%=sessionBean.getIniValue("committeeWarName")%>/externalLogin.jsp?"+commUrlParams1+"&rid="+MakeUniqueNumber(),"Committee & Meetings","scrollbars=yes,resizable=yes,toolbar=no,Addressbar=no,menubar=no,status=yes,top=" + screen.width + ", left=" + screen.height + ",width="+screen.width+",height="+screen.height);
				}
				else  if(spvalue=="createmeet") 
				{
					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
					//changes by Somya Bagai to open committee meeting module
					
					
					
					//added genRSB parameter to open committee from inbox
			

					/* Added by Suneet Saurabh for Hindi Version of Committee Meeting*/
					<%
						if(session.getAttribute("language").toString().equalsIgnoreCase("en"))
						{
					%>
						let commUrlParams1 = "CabinetName=<%=sessionBean.getCabinetName()%>&UserDbId=<%=sessionBean.getUserDbId()%>&JtsIpAdd=<%=sessionBean.getJtsIpAddress()%>&JtsPort=<%=sessionBean.getJtsPort()%>&dataBaseType=<%=sessionBean.getDataBaseType()%>&strEnc=UTF-8&localeString=en&MenuOption=createmeet";
<%
						}
%>
<% 
					if(session.getAttribute("language").toString().equalsIgnoreCase("hi"))
						{
%>
						let commUrlParams1 = "CabinetName=<%=sessionBean.getCabinetName()%>&UserDbId=<%=sessionBean.getUserDbId()%>&JtsIpAdd=<%=sessionBean.getJtsIpAddress()%>&JtsPort=<%=sessionBean.getJtsPort()%>&dataBaseType=<%=sessionBean.getDataBaseType()%>&strEnc=UTF-8&localeString=hi&MenuOption=createmeet";
<%
						}
%>
					
					
					let width=screen.width;
					let height=screen.height;
					//window.open("/<%=sessionBean.getIniValue("committeeWarName")%>/externalLogin.jsp?"+commUrlParams1+"&rid="+MakeUniqueNumber(),"Committee & Meetings",""); 		
//added by vinoth					
					window.open("/<%=sessionBean.getIniValue("committeeWarName")%>/externalLogin.jsp?"+commUrlParams1+"&rid="+MakeUniqueNumber(),"Committee & Meetings","scrollbars=yes,resizable=yes,toolbar=no,Addressbar=no,menubar=no,status=yes,top=" + screen.width + ", left=" + screen.height + ",width="+screen.width+",height="+screen.height);
				}
				else  if(spvalue=="createmom") 
				{
					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
					//changes by Somya Bagai to open committee meeting module
					
					
					
					//added genRSB parameter to open committee from inbox
			

					/* Added by Suneet Saurabh for Hindi Version of Committee Meeting*/
					<%
						if(session.getAttribute("language").toString().equalsIgnoreCase("en"))
						{
					%>
						let commUrlParams1 = "CabinetName=<%=sessionBean.getCabinetName()%>&UserDbId=<%=sessionBean.getUserDbId()%>&JtsIpAdd=<%=sessionBean.getJtsIpAddress()%>&JtsPort=<%=sessionBean.getJtsPort()%>&dataBaseType=<%=sessionBean.getDataBaseType()%>&strEnc=UTF-8&localeString=en&MenuOption=createmom";
<%
						}
%>
<% 
					if(session.getAttribute("language").toString().equalsIgnoreCase("hi"))
						{
%>
						let commUrlParams1 = "CabinetName=<%=sessionBean.getCabinetName()%>&UserDbId=<%=sessionBean.getUserDbId()%>&JtsIpAdd=<%=sessionBean.getJtsIpAddress()%>&JtsPort=<%=sessionBean.getJtsPort()%>&dataBaseType=<%=sessionBean.getDataBaseType()%>&strEnc=UTF-8&localeString=hi&MenuOption=createmom";
<%
						}
%>
					
					
					let width=screen.width;
					let height=screen.height;
					//window.open("/<%=sessionBean.getIniValue("committeeWarName")%>/externalLogin.jsp?"+commUrlParams1+"&rid="+MakeUniqueNumber(),"Committee & Meetings",""); 		
//added by vinoth					
					window.open("/<%=sessionBean.getIniValue("committeeWarName")%>/externalLogin.jsp?"+commUrlParams1+"&rid="+MakeUniqueNumber(),"Committee & Meetings","scrollbars=yes,resizable=yes,toolbar=no,Addressbar=no,menubar=no,status=yes,top=" + screen.width + ", left=" + screen.height + ",width="+screen.width+",height="+screen.height);
				}
				// Added for committee home in egov -- Gourav Singla
				else  if(spvalue=="commhome") 
				{
					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
					<%
					if(session.getAttribute("language").toString().equalsIgnoreCase("en")) {
					%>
						let commUrlParams1 = "CabinetName=<%=sessionBean.getCabinetName()%>&UserDbId=<%=sessionBean.getUserDbId()%>&JtsIpAdd=<%=sessionBean.getJtsIpAddress()%>&JtsPort=<%=sessionBean.getJtsPort()%>&dataBaseType=<%=sessionBean.getDataBaseType()%>&strEnc=UTF-8&localeString=en&MenuOption=commhome";
					<%
					}
					%>
					<% 
					if(session.getAttribute("language").toString().equalsIgnoreCase("hi")) {
					%>
						let commUrlParams1 = "CabinetName=<%=sessionBean.getCabinetName()%>&UserDbId=<%=sessionBean.getUserDbId()%>&JtsIpAdd=<%=sessionBean.getJtsIpAddress()%>&JtsPort=<%=sessionBean.getJtsPort()%>&dataBaseType=<%=sessionBean.getDataBaseType()%>&strEnc=UTF-8&localeString=hi&MenuOption=commhome";
					<%
					}
					%>
					let width=screen.width;
					let height=screen.height;
					window.open("/<%=sessionBean.getIniValue("committeeWarName")%>/externalLogin.jsp?"+commUrlParams1+"&rid="+MakeUniqueNumber(),"Committee & Meetings","scrollbars=yes,resizable=yes,toolbar=no,Addressbar=no,menubar=no,status=yes,top=" + screen.width + ", left=" + screen.height + ",width="+screen.width+",height="+screen.height);
				}
				else  if(spvalue=="rticreate") 
				{
					
				window.open("rtirequest.sp","AddRTI","scrollbars=yes,resizable=yes,toolbar=no,Addressbar=no,menubar=no,status=yes,top=" + screen.width + ", left=" + screen.height + ",width="+screen.width+",height="+screen.height);
				}
				//Added by priyanka on 20Nov
				else  if(spvalue=="firstappeal") 
				{
					
				window.open("rtifirstappealrequest.sp","AddRTI","scrollbars=yes,resizable=yes,toolbar=no,Addressbar=no,menubar=no,status=yes,top=" + screen.width + ", left=" + screen.height + ",width="+screen.width+",height="+screen.height);
				}	
				else  if(spvalue=="secondappeal") 
				{
					
				window.open("rtisecondappealrequest.sp","AddRTI","scrollbars=yes,resizable=yes,toolbar=no,Addressbar=no,menubar=no,status=yes,top=" + screen.width + ", left=" + screen.height + ",width="+screen.width+",height="+screen.height);
				}	
				else  if(spvalue=="pqcreate") 
				{
					
				window.open("pqrequest.sp","AddPQ","scrollbars=yes,resizable=yes,toolbar=no,Addressbar=no,menubar=no,status=yes,top=" + screen.width + ", left=" + screen.height + ",width="+screen.width+",height="+screen.height);
				}	
				else  if(spvalue=="cccreate") 
				{
					
				window.open("ccrequest.sp","AddCC","scrollbars=yes,resizable=yes,toolbar=no,Addressbar=no,menubar=no,status=yes,top=" + screen.width + ", left=" + screen.height + ",width="+screen.width+",height="+screen.height);
				}				
				//Ended by priyanka
                //Added by Siddharth Nawani for AUDIT Process
				else  if(spvalue=="memocreate") 
				{
					
				window.open("auditrequest.sp","AddADT","scrollbars=yes,resizable=yes,toolbar=no,Addressbar=no,menubar=no,status=yes,top=" + screen.width + ", left=" + screen.height + ",width="+screen.width+",height="+screen.height);
				}
				
				//Ended by Siddharth Nawani
				else if(spvalue=="fileIndex"){
					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
						// Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)
				document.getElementById("itemSelected").style.display = 'block';
				document.getElementById("itemlinks").style.display = 'block';
				document.getElementById("pageList").style.display = 'block';
                    renderFileIndex();
                }
				else if(spvalue=="dakRegister"){
					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
					// Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)
				document.getElementById("itemSelected").style.display = 'block';
				document.getElementById("itemlinks").style.display = 'block';
				document.getElementById("pageList").style.display = 'block';
				sPageNo=1;	
				document.getElementById("itemSelected").innerHTML=document.getElementById(spvalue).innerHTML;				
                    renderDakRegister();
				
				}	
				//Added by Amit Pandey on 26/11/2012 for search DAK	
				else if(spvalue=="searchDak")
				{
					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
						// Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)
					document.getElementById("itemSelected").style.display = 'block';
				document.getElementById("itemlinks").style.display = 'block';
				document.getElementById("pageList").style.display = 'block';
						document.getElementById("itemSelected").innerHTML=document.getElementById(spvalue).innerHTML;
						searchDakRegister();	
				}
				//Addition by Amit Pandey ends	
                else if(spvalue=="specialFiles") 
                {
					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
					
					sOrderBy="2";
					// Egov-12.1-0001
					document.getElementById("itemSelected").style.display = 'block';
				document.getElementById("itemlinks").style.display = 'block';
				document.getElementById("pageList").style.display = 'block';
                    document.getElementById("itemSelected").innerHTML=document.getElementById(spvalue).innerHTML;
                    document.getElementById("itemlinks").innerHTML="";
                    /* Jtrac Id – 	EGOV-230
	                Description – Special Files ,onclick changes its colour from white to orange and remains on that.
                    Date of Resolution – 26/09/2017 
                    Resolved by – Nikita Patidar    */
					
                  //  document.getElementById(spvalue).style.color="orange"; 
					 renderSpecialFiles("specialFiles");
                    //renderSpecialFiles();
                }
				else if(spvalue=="searchDoc"){
					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
						// Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)
				  document.getElementById("itemSelected").style.display = 'block';
				document.getElementById("itemlinks").style.display = 'block';
				document.getElementById("pageList").style.display = 'block';
				 // document.getElementById("itemSelected").innerHTML=document.getElementById(spvalue).innerHTML;
				 if(subSpValue=='OfficeNote Dataclass'){
				 document.getElementById("itemSelected").innerHTML=Search_Note;
				 }
			  else if(subSpValue=='DAK Dataclass'){
				   document.getElementById("itemSelected").innerHTML=Search_DAK;
			  }else{
				  document.getElementById("itemSelected").innerHTML=Search_Document;
			  }
			    displayDocumentSearchForm1(0,subSpValue);
				}
				//CC Config
				else if(spvalue=="ccitems")
				{
					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
						// Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)
					document.getElementById("itemSelected").style.display = 'block';
				document.getElementById("itemlinks").style.display = 'block';
				document.getElementById("pageList").style.display = 'block';
					sOrderBy="2";
					sSortOrder="D";
						// Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)
					document.getElementById("itemSelected").innerHTML=CC;
					//document.getElementById("itemSelected").innerHTML=document.getElementById(lastItemSelected).innerHTML;
					renderCCNotificationComponent();
					
				
				}
				else if(spvalue=="ccsentitems")
				{
					//Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next
					document.getElementById("itemlinksnepr").style.display = 'none';
					// Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)
					document.getElementById("itemSelected").style.display = 'block';
				document.getElementById("itemlinks").style.display = 'block';
				document.getElementById("pageList").style.display = 'block';
					sOrderBy="3";
					sSortOrder="D";
					//document.getElementById("itemSelected").innerHTML=document.getElementById(lastItemSelected).innerHTML;
					document.getElementById("itemSelected").innerHTML=Sent_CC_Notifications;
					renderCCSentNotificationComponent();
				}
                /*else  if(spvalue=="dkSearch")
                {
                    if(dakSearchInnerHtml!="")
                    {
                        searchDaks();
                        return;
                    }
                    document.getElementById("itemSelected").innerHTML=document.getElementById(spvalue).innerHTML;
                    document.getElementById(spvalue).style.color="orange";            
                    innerHtml="";
                    innerHtml=innerHtml+"<table border='0' width='100%' cellpadding='3' cellspacing='0'>";
                    innerHtml=innerHtml+"<tr><td><table background='images/white_u.gif' border=0 width='100%'><tr><td align=center class=EWLabel1>Subject:</td><td><input id='txtDakSubject' type='textbox' value='' size=40/></td>";
                    innerHtml=innerHtml+"<td align=center class=EWLabel1>Received From: </td><td><input id='txtDakReceivedFrom' type='textbox' value='' size=40/></td></tr>";
                    innerHtml=innerHtml+"<tr><td align=center class=EWLabel1>Reference No:</td><td><input id='txtDakReferenceNo' type='textbox' value='' size=40/></td>";
                    innerHtml=innerHtml+"<td align=center class=EWLabel1>Date Of Receipt: </td><td><input disabled='disabled' id='txtDateOfReceipt' type='textbox' value='' size=40/><a href='#' onclick='popupcalendar1(\"txtDateOfReceipt\",this);'><img src='images/cal.gif' border='0'></a></td></tr>";
                    innerHtml=innerHtml+"<tr>";
                    innerHtml=innerHtml+"<td align=center class=EWLabel1>Date On Letter: </td><td colspan=3><input id='txtDateOnLetter' type='textbox' value='' disabled='disabled' size=40/><a href='#' onclick='popupcalendar1(\"txtDateOnLetter\",this);'><img src='images/cal.gif' border='0'></a></td></tr>";
                    innerHtml=innerHtml+"<tr><td colspan='4' align='right'><img src='images/search.gif' style='cursor:pointer;' onclick=\'searchDaks();\'>&nbsp;&nbsp;<img src='images/cancel.gif' style='cursor:pointer;'></td></tr>";
                    innerHtml=innerHtml+"</table></td></tr>";
                    innerHtml=innerHtml+"</table>";  
                    document.getElementById("listItems").innerHTML=innerHtml;
                }*/  //Commented Code removed be karan Singh for PrivateIpAddress disclosed(EG-0009)                    
                else 
                {
                    return;
                } 
                // Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)  
				//if (!sidePanel.classList.contains('icon'))
            sidePanel.style.width = '0';	
			//}			

                return;
            }          
                        
            function windowRefresh()
            {
                window.location.reload();
            }
            function hideAlarmsDiv()
            {
                document.getElementById("alarms").style.visibility="hidden";
            }
			
			function getChartData()
			{ 
				let xmlHttp=null;
				xmlHttp = GetXmlHttpObject();
				let egovUIDnew = document.getElementById("egovUID").value;
				
				$.ajax({
					type: "POST",
					url: "getChartData.jsp?egovID="+egovUIDnew,					
					async: false,
					success: function (data, status)
					{	
	
						if(status == "success")
						{
							/*modified on 12-01-2024 to handle XSS vulnerability
							let textToShow = eval('('+data+')');*/
							let textToShow = JSON.parse(data);
							let dashboardReport1Data=textToShow.dashboardReport1Data;
							let dashboardReport2Data=textToShow.dashboardReport2Data;
							let dashboardReport3Data=textToShow.dashboardReport3Data;
							myDashboardReports(dashboardReport1Data,dashboardReport2Data,dashboardReport3Data);
							
						}
						else if(status == "error")	
						{   // Changed by Saurabh Rajput on 10/08/2021 for EG10-0015
							alert(ERROR_PROBLEM);
						}
						else
						{	
							alert("Status="+status);
						}
					}

		
			
			});
			}
            function setTimer()
            {    
                setTimeout("getAllAlarmsAndReminders();setTimer();",pollTimeInMilliSec);  //300000     
                //self.focus();
            }
            setTimer();

			function folderOperations(loginUserRights, FolderIndex, ParentFolderIndex, FolderName, FolderLock, LockedByUser,FolderOwner)
			{
				opsDiv = document.getElementById("operations");
				let sRightsArray = new Array();
				let i=0;
				for(i=0;i<loginUserRights.length;i++)
				{
					sRightsArray[i]=loginUserRights.charAt(i);
				}
				let innerHtml = "";
				// Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)
				innerHtml = '<table border="0" style="border-style:solid;border-width:1px;background-color:white" width="100%" align="left"								bgcolor="white" cellpadding="3" cellspacing="0" class="black--text">';
				<%
					if(sessionBean.getProvision().testBit(EWProvision.FOLD_PROP_VIEW))
					{
				%>
				
						
						innerHtml+=getInnerHtml(Properties,sRightsArray,"folderProperties(\'"+FolderIndex+"\',\'"+FolderName+"\')");
				<%
					}
				%>
				<%
					if(sessionBean.getProvision().testBit(EWProvision.DOC_ADD))
					{
				%>
						//innerHtml+=getInnerHtml("Add Document",sRightsArray,"folderAddDocument()");
				<%
					}
				%>
				<%
					if(sessionBean.getProvision().testBit(EWProvision.FOLD_MOVE))
					{
				%>
						innerHtml+=getInnerHtml(Move_Copy,sRightsArray,"folderMove(\'"+FolderIndex+"\',\'"+ParentFolderIndex+"\',\'"+FolderName+"\')");
				<%
					}
				%>
				////Commented By varun For UIDAI////
				/*
				<%
					if(sessionBean.getProvision().testBit(EWProvision.FOLD_DELETE))
					{
				%>
						innerHtml+=getInnerHtml('<%=rsb.getString("Delete")%>',sRightsArray,"folderDelete(\'"+FolderIndex+"\',\'"+ParentFolderIndex+"\',\'"+FolderName+"\')");
				<%
					}
				%>
				*/
				<%
					if(sessionBean.getProvision().testBit(EWProvision.FOLD_ALARM_VIEW))
					{
				%>
						innerHtml+=getInnerHtml(Alarms,sRightsArray,"folderAlarms('"+FolderIndex+"','"+FolderName+"','"+FolderOwner+"')");
				<%
					}
				%>
				<%
					if(sessionBean.getProvision().testBit(EWProvision.FOLD_LOG))
					{
				%>
						innerHtml+=getInnerHtml(Audit_Log,sRightsArray,"folderLog(\'"+FolderIndex+"\',\'"+FolderName+"\')");
				<%
					}
				%>
				<%
					if(sessionBean.getProvision().testBit(EWProvision.FOLD_SHARE_VIEW))
					{
				%>
						innerHtml+=getInnerHtml(Sharing,sRightsArray,"folderSharing('"+FolderIndex+"','"+FolderName+"','"+FolderOwner+"')");
				<%
					}
				%>
				<%
				if(sessionBean.getProvision().testBit(EWProvision.FOLD_DOC_ORDER))
					{
				%>
						innerHtml+=getInnerHtml(Order,sRightsArray,"folderDocOrder(\'"+FolderIndex+"\',\'"+FolderName+"\')");
				<%
					}
				%>
					innerHtml +=getInnerHtml(Movement_Slip, sRightsArray, "folderMovementSlip('"+FolderIndex+"')");
					
					innerHtml +=getInnerHtml(Documents, sRightsArray, "displayDocumentSearchForm1('"+FolderIndex+"')");
					
				opsDiv.innerHTML = innerHtml;
			} 

			function documentOperations(sLoginUserRightsList, sDocIdList, sParentFolderIdList, sDocNameList, sDocReferenceList, sCreatedByAppName, DocumentVersionNo, CheckoutStatus, CheckoutBy, DocumentType, Owner, ISIndex, NoOfPages, DataDefName, Multiple, isFoldOrDocList,calledFrom)
			{	
				//changes by Indra to display selective doc operation options in case of paper profile
				opsDiv = document.getElementById("operations");
				let innerHtml = "";
				let sRightsArray = new Array();
				let i=0;
				let isPaperProfile=false;
				
					
				for(i=0;i<sLoginUserRightsList.length;i++)
				{
					sRightsArray[i]=sLoginUserRightsList.charAt(i);
				}
				<%
					if(sessionBean.getProvision().testBit(EWProvision.DOC_ADD))
					{
				%>
						if(ISIndex.indexOf("-1#-1")>-1)
						{
							isPaperProfile=true;
						}
				<%
					}
				%>
				// Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)
				innerHtml += '<table border="0" style="border-style:solid;border-width:1px;" width="110%" align="left"								bgcolor="white" cellpadding="3" cellspacing="0" class="black--text">';
				<%
					
					if(sessionBean.getProvision().testBit(EWProvision.DOC_PROP_VIEW))
					{
				%>	
							innerHtml+=getDocInnerHtml(Properties,sRightsArray,"GetDocProp(\'"+sDocIdList+"\',\'"+sParentFolderIdList+"\',\'"+sDocReferenceList+"\')",Multiple, CheckoutStatus,isPaperProfile);
						
				<%
					}
				%>
				

				<%
					if(sessionBean.getProvision().testBit(EWProvision.DOC_MOVE))
					{//documentIdList, SelFolderId, documentNameList, documentOwnerList, documentReferenceList, documentCreatedByAppNameList, isFoldOrDocList
				%>
						if(calledFrom!='searchDocument')
						{
							/*commented on 26-06-2025 to remove Move option from document operations
							innerHtml+=getDocInnerHtml(Move_Copy,sRightsArray,"MoveDoc('"+ sDocIdList + "','" + sParentFolderIdList + "','" + sDocNameList + "','" + Owner+"','" + sDocReferenceList +"','" + sCreatedByAppName + "','" + isFoldOrDocList +"')",Multiple, CheckoutStatus,isPaperProfile);
							*/
						}
				<%
					}
				%>
				
				
				<%
					if(sessionBean.getProvision().testBit(EWProvision.DOC_DELETE))
					{
				%>
						if(calledFrom!='searchDocument')
						{
							innerHtml+=getDocInnerHtml(Delete,sRightsArray,"DeleteDoc('"+sParentFolderIdList+"','"+sDocReferenceList+"','"+sDocIdList+"','"+Owner+"','"+sDocNameList+"','"+"<%=sessionBean.getLoggedInUser().getTrashFolderId()%>"+"','"+isFoldOrDocList+"')",Multiple, CheckoutStatus,isPaperProfile);
						}	
				<%
					}
				%>
				
				////Commented By varun Temorarily as it not working properly////
				//changed by Rohit(28-12-15) for Check Out and Check In and Version
				<%
					if(sessionBean.getProvision().testBit(EWProvision.DOC_CHECKINOUT))
					{
				%>
						if(calledFrom!='searchDocument')
						{
							innerHtml+=getDocInnerHtml(Check_Out,sRightsArray,"DocCheckout('"+sCreatedByAppName+"','"+CheckoutStatus +"','"+sDocIdList+"','"+sDocNameList+"','"+ISIndex+"')",Multiple, CheckoutStatus,isPaperProfile);
						}	
				<%
					}
				%>
				<%
					if(sessionBean.getProvision().testBit(EWProvision.DOC_CHECKINOUT))
					{
				%>
						if(calledFrom!='searchDocument')
						{
							innerHtml+=getDocInnerHtml(Check_In,sRightsArray,"DocCheckin('"+sDocIdList+"','"+sDocNameList +"','"+DocumentVersionNo+"','"+sCreatedByAppName+"','"+ISIndex+"','"+Owner+"','"+CheckoutStatus+"','"+CheckoutBy+"','"+"<%=sessionBean.getLoggedInUser().getUserName()%>"+"','"+"<%=sessionBean.getIsAdmin()%>"+"')",Multiple, CheckoutStatus,isPaperProfile);
						}	
				<%
					}
				%>
				<%
					if(sessionBean.getProvision().testBit(EWProvision.DOC_VERSION_VIEW))
					{
				%>
						innerHtml+=getDocInnerHtml(Version,sRightsArray,"DisplayVersions(\'"+sDocIdList+"\',\'"+sParentFolderIdList+"\',\'"+sDocNameList+"\',\'"+sLoginUserRightsList+"\')",Multiple, CheckoutStatus,isPaperProfile);
				<%
					}
				%>
				//comment ends
				
				
				<%
					if(sessionBean.getProvision().testBit(EWProvision.DOC_SHARE_VIEW))
					{
				%>
						if(calledFrom!='searchDocument')
						{
							/*commented on 26-06-2025 to remove Share option from document operations
							innerHtml+=getDocInnerHtml(Share,sRightsArray,"DocSharing(\'"+sDocIdList+"\',\'"+sDocNameList+"\',\'"+sParentFolderIdList+"\',\'"+Owner+"\')",Multiple, CheckoutStatus,isPaperProfile);
							*/
						}	
				<%
					}
				%>
				
				
				<%
					if(sessionBean.getProvision().testBit(EWProvision.DOC_DOWNLOAD))
					{
				%>		
						if(calledFrom!='searchDocument')
						{
							innerHtml+=getDocInnerHtml(Download,sRightsArray,"DownloadDocument('"+"<%=sessionBean.getCabinetName()%>"+"','"+"<%=sessionBean.getJtsIpAddress()%>"+"','"+"<%=sessionBean.getJtsPort()%>"+"','"+sDocIdList+"','"+sCreatedByAppName+"','"+sDocNameList+"','"+ISIndex+"')",Multiple, CheckoutStatus,isPaperProfile);
						}	
				<%
					}
				%>
				<%
					if(sessionBean.getProvision().testBit(EWProvision.DOC_PRINT))
					{
				%>
					
				//Commented by Neha Kathuria on Sept 16,2016 for hiding print option	
				//innerHtml+=getDocInnerHtml(Print,sRightsArray,"Printdoc('"+sDocIdList+"','"+sCreatedByAppName+"','"+DocumentVersionNo+"','"+NoOfPages+"','"+ISIndex+"','"+sParentFolderIdList+"','"+sDocNameList+"','"+DocumentType+"','"+"<%=sessionBean.getJtsIpAddress()%>"+"','"+"<%=sessionBean.getJtsPort()%>"+"','"+"<%=sessionBean.getCabinetName()%>"+"','"+"<%=sessionBean.getIniValue("ContextName")%>"+"')",Multiple, CheckoutStatus);
				<%
					}
				%>
				
				<%
					if(sessionBean.getProvision().testBit(EWProvision.DOC_LINK_VIEW))
					{
				%>
						if(calledFrom!='searchDocument')
						{
							/*commented on 26-06-2025 to remove Link option from document operations
							innerHtml+=getDocInnerHtml(Links,sRightsArray,"LinkDocuments('"+sDocIdList+"','"+sDocNameList+"','"+sParentFolderIdList+"','"+Owner+"','"+CheckoutStatus+"','"+sLoginUserRightsList+"','"+sCreatedByAppName+"')",Multiple, CheckoutStatus,isPaperProfile);
							*/
						}	
				<%
					}
				%>
				
				<%
					if(sessionBean.getProvision().testBit(EWProvision.DOC_POST))
					{
				%>
						//innerHtml+=getDocInnerHtml("Post",sRightsArray,"PostDocument('"+sCreatedByAppName+"','"+sDocReferenceList+"','"+CheckoutStatus+"','"+sDocIdList+"','"+sDocNameList+"','"+Owner.toLowerCase()+"','"+"<%=sessionBean.getIsAdmin()%>"+"','"+"<%=sessionBean.getLoggedInUser().getUserIndex()%>"+"','"+Multiple+"')",Multiple, CheckoutStatus);
				<%
					}
				%>
				<%
				//Commented by Indra to remove "Duplicate" functionality from doc operations
				/*	if(sessionBean.getProvision().testBit(EWProvision.DOC_DUPLICATE))
					{*/
				%>
						//innerHtml+=getDocInnerHtml(Duplicate,sRightsArray,"duplicateDoc('"+sCreatedByAppName+"','"+sDocNameList+"','"+sDocReferenceList+"','"+sDocIdList+"','"+sParentFolderIdList+"')",Multiple, CheckoutStatus,isPaperProfile);
				<%
					//}
				%>
				<%
					if(sessionBean.getProvision().testBit(EWProvision.DOC_LOG))
					{
				%>
						innerHtml+=getDocInnerHtml(Audit_Log,sRightsArray,"DocAuditLog('"+ sDocIdList + "','" + sDocNameList+"')",Multiple, CheckoutStatus,isPaperProfile);
				<%
					}
				%>
				
				
				<%
					if(sessionBean.getProvision().testBit(EWProvision.DOC_ALARM_VIEW))
					{
				%>
						if(calledFrom!='searchDocument')
						{
							/*commented on 26-06-2025 to remove Alarm option from document operations
							innerHtml+=getDocInnerHtml(Alarms,sRightsArray,"DocAlarmReminder('"+sDocIdList+"','"+sDocNameList+"','"+Owner+"','"+sCreatedByAppName+"','"+sParentFolderIdList+"','O')",Multiple, CheckoutStatus,isPaperProfile);
							*/
						}	
				<%
					}
				%>
				
				
				
				<%
					if(sessionBean.getProvision().testBit(EWProvision.DOC_FORWARD))
					{
				%>
						if(calledFrom!='searchDocument')
						{
							/*commented on 26-06-2025 to remove Forward option from document operations
							innerHtml+=getDocInnerHtml(Forward,sRightsArray,"DocForward('"+sDocIdList+"','"+ISIndex+"','"+sDocNameList+"','"+sCreatedByAppName+"')",Multiple, CheckoutStatus,isPaperProfile);
							*/
						}	
				<%
					}
				%>
				
				
				<%
					if(sessionBean.getProvision().testBit(EWProvision.DOC_FORWARD) && MultipleDakInitiate_Enable.equalsIgnoreCase("Yes"))
					{
				%>
						if(calledFrom!='searchDocument')
						{
							innerHtml+=getDocInnerHtml(Initiate,sRightsArray,"multDak()",Multiple, CheckoutStatus,isPaperProfile);
						}	
				<%
					}
				%>
				<%
				//changes started for upload DOC to Paper Profile by Rohit Verma
					if(sessionBean.getProvision().testBit(EWProvision.DOC_ADD))
					{
					
				%>
						if(ISIndex.indexOf("-1#-1")>-1){
							innerHtml+=getDocInnerHtml(Upload,sRightsArray,"uploadDoc('"+sDocIdList+"','"+sDocNameList +"','"+DocumentVersionNo+"','"+sCreatedByAppName+"','"+ISIndex+"','"+Owner+"','"+CheckoutStatus+"','"+CheckoutBy+"','"+"<%=sessionBean.getLoggedInUser().getUserName()%>"+"','"+"<%=sessionBean.getIsAdmin()%>"+"')",Multiple, CheckoutStatus,isPaperProfile);
						}
				<%
					}
					//changes ended
				%>
				//Changes by Indra ends
	//Ayush Gupta: Changes done for Chrome issue with move/copy
				//innerHtml += createMultiDocForm();
				
			opsDiv.innerHTML = "";
			
			opsDiv.innerHTML = "";
				document.getElementById("operations1").innerHTML=createMultiDocForm();
					opsDiv.innerHTML = innerHtml;
				
						}
		
		//BAM Report generalization
		function showBAMReport(reportIndex)
		{
			
				// Changes by Indra for BAM reports om 14/1/2016
			<%
			if(IsiBPS.equalsIgnoreCase("yes"))
			{
			%>
				
				//let strUrl='<%=sessionBean.getProtocol()%>'+"://"+'<%=request.getServerName()%>'+":"+'<%=request.getServerPort()%>'+"/bam/login/login.jsf?CalledFrom=EXT&UserId=<%=URLEncoder.encode(sessionBean.getLoggedInUser().getUserName(),"UTF-8")%>&UserIndex=<%=sessionBean.getLoggedInUser().getUserIndex()%>&SessionId=<%=sessionBean.getUserDbId()%>&CabinetName=<%=sessionBean.getCabinetName()%>&LaunchClient=RI&ReportIndex="+reportIndex+"&AjaxRequest=Y&OAPDomHost="+'<%=request.getServerName()%>'+":"+'<%=request.getServerPort()%>';
				
				//strUrl updated as per iBPS 6 by Priyanshu Sharma for MRPL ID: EGOV-11.6.01
			    let strUrl='<%=sessionBean.getProtocol()%>'+"://"+'<%=request.getServerName()%>'+":"+'<%=request.getServerPort()%>'+"/bam/login/extlogin?for=R&UserId=<%=URLEncoder.encode(sessionBean.getLoggedInUser().getUserName(),"UTF-8")%>&UserIndex=<%=sessionBean.getLoggedInUser().getUserIndex()%>&SessionId=<%=sessionBean.getUserDbId()%>&CabinetName=<%=sessionBean.getCabinetName()%>&LaunchClient=RI&ReportIndex="+reportIndex+"&AjaxRequest=Y&OAPDomHost="+'<%=request.getServerName()%>'+":"+'<%=request.getServerPort()%>'+"&OAPDomPrt=<%=sessionBean.getProtocol()%>";
				//strUrl changes by Priyanshu Sharma for MRPL ID: EGOV-11.6.01 end here
				
				
			<%
			}
			else
			{
			%>	
			
			
				// Changed by Priyanshu Sharma for changing URL according to newgenone.
				let strUrl='<%=sessionBean.getProtocol()%>'+"://"+'<%=request.getServerName()%>'+":"+'<%=request.getServerPort()%>'+"/bam/login/extlogin?for=R&UserIndex=<%=sessionBean.getLoggedInUser().getUserIndex()%>&UserId=<%=URLEncoder.encode(sessionBean.getLoggedInUser().getUserName(),"UTF-8")%>&CabinetName=<%=sessionBean.getCabinetName()%>&LaunchClient=RI&ReportIndex="+reportIndex+"&EmbeddedView=01111011&UID=<%=sessionBean.getUserDbId()%>";
				//Ended by Priyanshu Sharma.
			<%
			}
			%>	
			let strWindowProp="menubar=no,toolbar=no,top="+window5X+",left="+window5Y+",height="+window5H+",width="+window5W;
			
			//document.getElementById("bamDashReport1").src= strUrl;			
			win = window.open(strUrl,"BAMReport",strWindowProp);
			//Changes for window close on logout by rishav started
			window.top.addWindows(win);
		    //Changes for window close on logout by rishav ended
		}
		//BAM Report generalization
		//Changes by Priyanka to encrypt session ID to be used with OmniDocs external URL on OD 11 SP2: EGOV-11.6.01
		//Changes by Priyanshu Sharma for mrpl EGOV-11.6.01
        function openOdWeb() {
   
			let sProtocol = '<%=sessionBean.getProtocol()%>';		
	        let sEngineName = '<%=sessionBean.getCabinetName()%>';
	        let sSessionId = '<%=sessionBean.getUserDbId()%>';
			
			
			let encUserdbid;
			$.ajax({
        type:"POST",
        url: "encUserdbid.jsp?egovID="+egovUID,
        data:{"userDBId":sSessionId,"cabName":sEngineName},
        async:false,
        success:function(data,status) {                  
                        let d =data.trim();
                        let obj = JSON.parse(d);
                         encUserdbid = obj['encdb'];
                      
                    }
           });
			
			
			
		
			
	        let strUrl= '<%=sessionBean.getProtocol()%>'+"://"+'<%=request.getServerName()%>'+":"+'<%=request.getServerPort()%>'+"/omnidocs/UserDbIdLogin?CabinetName=<%=sessionBean.getCabinetName()%>&UserDbId="+encUserdbid+"&HeaderOptions=11111110";
			
	        win = window.open(strUrl,'Omnidocs',"scrollbars=auto,resizable=no,toolbar=no,menubar=no,status=yes,location=no,top="+window1X+",left="+window1Y+",width="+screen.width+",height="+screen.height);
}
// changes end by Priyanshu Sharma for mrpl EGOV-11.6.01
		//Changes by Priyanshu Sharma for opening BAM through newgenone workspace (Workspace needs to be configured in newgenone separately.)
		function showBAMDash()
		{	
			/*if(IsiBPS.equalsIgnoreCase("Yes")){
			let strUrl= '<%=sessionBean.getProtocol()%>'+"://"+'<%=request.getServerName()%>'+":"+'<%=request.getServerPort()%>'+"/omniapp/pages/login/extendsession.app?UserIndex=<%=sessionBean.getLoggedInUser().getUserIndex()%>&CabinetName=<%=sessionBean.getCabinetName()%>&SessionId=<%=sessionBean.getUserDbId()%>";
			let strWindowProp="menubar=no,toolbar=no,top="+window5X+",left="+window5Y+",height="+window.screen.availHeight+",width="+window.screen.availWidth;	
				console.log("strurl::"+strUrl);
			window.open(strUrl,"BAMDash",strWindowProp);
			}else{ */
				
				// Changed By Neha Kathuria on Dec 14,2016
			//let strUrl='<%=sessionBean.getProtocol()%>'+"://"+'<%=sessionBean.getJtsIpAddress()%>'+":"+'<%=serverHttpPort%>'+"/bam/login/login.jsp";
			
			//let strUrl='<%=sessionBean.getProtocol()%>'+"://"+'<%=request.getServerName()%>'+":"+'<%=request.getServerPort()%>'+"/bam";
			 let sSessionId = '<%=sessionBean.getUserDbId()%>';
			 let sEngineName = '<%=sessionBean.getCabinetName()%>';
			 let workspaceName = "eGovBAM";
			 let encUserdbid;
			$.ajax({
        type:"POST",
        url: "encUserdbid.jsp?egovID="+egovUID,
        data:{"userDBId":sSessionId,"cabName":sEngineName},
        async:false,
        success:function(data,status) {                  
                        let d =data.trim();
                        let obj = JSON.parse(d);
                         encUserdbid = obj['encdb'];
                       
                    }
           });

		   
		   
		   
			
			let strUrl= '<%=sessionBean.getProtocol()%>'+"://"+'<%=request.getServerName()%>'+":"+'<%=request.getServerPort()%>'+"/oap-rest/app/openws?UserIndex=<%=sessionBean.getLoggedInUser().getUserIndex()%>&udbid="+encUserdbid+"&cabinetname=<%=sessionBean.getCabinetName()%>&wsname="+workspaceName;
			
			
			
			let strWindowProp="menubar=no,toolbar=no,top="+window5X+",left="+window5Y+",height="+window.screen.availHeight+",width="+window.screen.availWidt;
			
			
			//document.getElementById("bamDashReport1").src= strUrl;			
			window.open(strUrl,"BAMDash",strWindowProp);
			//}
		}
		//Changes end by Priyanshu Sharma for opening BAM through newgenone workspace (Workspace needs to be configured in newgenone separately.)


		
		function getNextFileNo(FieldName)
		{
			let adminFilesDataclssName = file_DataClassName;
			
			let fileDepartmentType = document.getElementById('departmentType').options[document.getElementById('departmentType').selectedIndex].value;
           <!--Changes made by Kanchan on 04/09/2024 for reference no. formation-->			
			//let fileSectionCode = document.getElementById('sectionType').options[document.getElementById('sectionType').selectedIndex].value;	
			let fileSectionCode = document.getElementById('sectionType').options[document.getElementById('sectionType').selectedIndex].text;
			
			let fileSubject = document.getElementById('fileSubject').value;
			fileSubject = fileSubject.replace(/[^a-zA-Z0-9 _@!]/g, "");
			//1168643 Added encoding by Adeeba on 21/4/2023 to handle & in file reference no.
			
			document.getElementById("getFileNo").src = "custom/getFileNoForFile.jsp?egovID=<%=egovUID%>&CreateOrComplete=Create&AdminFilesDataclssName=" + adminFilesDataclssName + "&FileUniqueIdFieldname=" + FieldName + "&FileDepartmentType=" + encode_utf8(fileDepartmentType) + "&FileSectionCode=" + encode_utf8(fileSectionCode)+"&FileSubject="+(fileSubject)+"&rid="+MakeUniqueNumber();

		}

		function updateUser()
		{
			// Changed by Neha Kathuria for EGOV-1232
			let strUrl="custom/add_user.jsp?egovID=<%=egovUID%>&commEnable=<%=commEnable%>";
			let strWindowProp="menubar=no,toolbar=no,top="+(window5X-100)+",left="+window5Y+",height="+(window5H+180)+",width="+window5W;
			win = window.open(strUrl,"CompleteReport",strWindowProp);
			//Changes for window close on logout by rishav started
			window.top.addWindows(win);
		//Changes for window close on logout by rishav ended
		}
		//added by kanchan on 18-04-2024 for department
		function addDepartment()
		{
			let strUrl="custom/add_department.jsp?egovID=<%=egovUID%>&commEnable=<%=commEnable%>";
			let strWindowProp="menubar=no,toolbar=no,top="+(window5X-100)+",left="+window5Y+",height="+(window5H+180)+",width="+window5W;
			win = window.open(strUrl,"CompleteReport",strWindowProp);
			window.top.addWindows(win);
		}
		//ended here by kanchan on 18-04-2024 for department
		//added by kanchan on 18-04-2024 for designation
		function addDesignation()
		{
			let strUrl="custom/add_designation.jsp?egovID=<%=egovUID%>&commEnable=<%=commEnable%>";
			let strWindowProp="menubar=no,toolbar=no,top="+(window5X-100)+",left="+window5Y+",height="+(window5H+180)+",width="+window5W;
			win = window.open(strUrl,"CompleteReport",strWindowProp);
			window.top.addWindows(win);
		}
		//ended here by kanchan on 18-04-2024 for designation
		//changes  started for change password option by Rohit Verma 
		function changePassword()
		{
			//Changes done  by Nikita for Session Hijacking(EG-0001)
			/*let strUrl="doccab/changepass.jsp";
			alert(strUrl);
			let strWindowProp="menubar=no,toolbar=no,resizable=no,top="+(window2X-100)+",left="+(window2Y-150)+",height="+(window2H+200)+",width="+(window2W+300);
			//Changes for window close on logout by vaibhav.khandelwal started
			let win = window.open(strUrl,"CompleteReport",strWindowProp);*/
			strWindowProp="menubar=no,toolbar=no,resizable=no,top="+(window2X-100)+",left="+(window2Y-150)+",height="+(window2H+200)+",width="+(window2W+300);
			let changePasswordForm=window.document.forms['changePasswordForm'];
			changePasswordForm.action="doccab/changepass.jsp";
			let windowname = 'CompleteReport';
			//Changes for window close on logout by vaibhav.khandelwal started
			let NewWin = window.open('',windowname , strWindowProp); 
			addWindows(NewWin);	 
			changePasswordForm.target=windowname;
			changePasswordForm.submit();
			//Changes ended  by Nikita for Session Hijacking(EG-0001)
			//Changes for window close on logout by vaibhav.khandelwal ended
		}
		//whitehall and transfer module password added by kanchan EG10-0032
		function changePasswordWh()
		{
			strWindowProp="menubar=no,toolbar=no,resizable=no,top="+(window2X-100)+",left="+(window2Y-150)+",height="+(window2H+200)+",width="+(window2W+300);
			let changePasswordForm=window.document.forms['changePasswordForm'];
			changePasswordForm.action="doccab/changepassWh.jsp";
			let windowname = 'CompleteReport';
			let NewWin = window.open('',windowname , strWindowProp); 
			addWindows(NewWin);	 
			changePasswordForm.target=windowname;
			changePasswordForm.submit();
		}
		function changePasswordTM()
		{
			strWindowProp="menubar=no,toolbar=no,resizable=no,top="+(window2X-100)+",left="+(window2Y-150)+",height="+(window2H+200)+",width="+(window2W+300);
			let changePasswordForm=window.document.forms['changePasswordForm'];
			changePasswordForm.action="doccab/changepassTM.jsp";
			let windowname = 'CompleteReport';
			let NewWin = window.open('',windowname , strWindowProp); 
			addWindows(NewWin);	 
			changePasswordForm.target=windowname;
			changePasswordForm.submit();
		}
		//ended here

		function openChatold()
		{
			let strUrl="custom/chatUsersAuto.jsp";
			let strWindowProp="menubar=no,scrollbars=yes,toolbar=no,top="+window2X+",left="+window2Y+",height="+window2H+",width="+window2W;
			window.open(strUrl,"Chatting",strWindowProp);
		}
		
		function noBack()
		{
			window.history.forward();
		}
		
		window.onbeforeunload=function()
		{
			window.location.reload();
		};
		
		function changeUnload()
		{
			window.onbeforeunload=function(){}
		}
		function preloadDashboardImage()
		{
			let dv=document.getElementById('fadedDashboard');
			dv.innerHTML='<table height="100%" border="2"><tr><td>&nbsp;</td></tr><tr width="100%"><td width="100%" valign="center" align="center"><img src="images/initial_loading.gif" width="70" height="70" style="top:40%;left:40%"/></td></tr><tr><td>&nbsp;</td></tr></table>';
		}
		
		//Added By Varun for theme Change//
		jQuery(function($) {
			$('body').on('click', '.change-style-menu-item', function() {
			  let theme_name = $(this).attr('data-color');
			  let theme = "/<%=sessionBean.getIniValue("ContextName")%>/bootstrap/css/bootstrap-egov_" + theme_name + ".css";
			  set_theme(theme);
			});
			
			
		});
		
	
		function set_theme(theme) {
		  $('link[title="main"]').attr('href', theme);
		}
		/*
		$(function(){$('#fromdate').datepicker({
		pickTime:false
		});
		});
		*/
		
		 /*  $(document).ready(function () {
                
                $('#fromdate').datepicker({
                 Boolean. Default: false
                });  
           */ /*
			$("#fromdate").datepicker({
					startDate: '-3d'
				});
				*/


/*
$('.datepicker').datepicker()
    .on(click, function(e){
       format: 'mm/dd/yyyy',
    startDate: '-3d'
    });
		
	*/	
//Added by Priyanka on 6Feb15 	
$(function() {$('.dakdatepicker').datepicker({
 format : "yyyy-mm-dd",
 autoclose : true
});
});
function clearDates(){
	
	$('#dateDakSearch1').data('datepicker').setDate(null);
	$('#dateDakSearch2').data('datepicker').setDate(null);
}
function clearSentItemDates(){

	$('#initiatedOn1').data('datepicker').setDate(null);
	$('#initiatedOn2').data('datepicker').setDate(null);
	$('#sentOn1').data('datepicker').setDate(null);
	$('#sentOn2').data('datepicker').setDate(null);
}
//ended
//changes started for iBPS queues by Rohit Verma

	function newWorkItem(sProcessId, sOFQueueId)
	{		
		let egovUIDnew = document.getElementById("egovUID").value;
		let pId='';
		let url= "/<%=sessionBean.getIniValue("ContextName")%>/custom/openNewWorkItem.jsp?rid="+ MakeUniqueNumber()+"&sProcessId="+sProcessId+"&webdesktopServerIP="+'<%=request.getServerName()%>'+"&sOFQueueId"+sOFQueueId+"&webdesktopServerPort="+'<%=request.getServerPort()%>'+"&egovID="+egovUIDnew;
		let xmlHttp=null;
		xmlHttp=GetXmlHttpObject();	
		if (xmlHttp==null)
		{
			alert (BROWSER_NOT_SUPPORT_HTTP);
			return;
		}	
		xmlHttp.onreadystatechange=function(){	
			if (xmlHttp.readyState==4) {			
				let xmlDoc = xmlHttp.responseXML;
				pId=xmlHttp.responseText;
				pId=pId.trim();
				openIt(pId);								
			}	
		}
		xmlHttp.open("GET",url,true);
		xmlHttp.send(null);			
	}

	function openIt(pId){
		let top=0;
		let left=0;
		let sProtocol='<%=sessionBean.getProtocol()%>';		
		let sEngineName='<%=sessionBean.getCabinetName()%>';
		let sUserName='<%=sessionBean.getLoggedInUser().getUserName()%>';
		let sSessionId='<%=sessionBean.getUserDbId()%>';		
		let sUserIndex='<%=sessionBean.getLoggedInUser().getUserIndex()%>';             

		let url= sProtocol+"://"+'<%=request.getServerName()%>'+":"+'<%=request.getServerPort()%>'+"/webdesktop/login/loginapp.jsf" + "?WDDomHost="+ '<%=request.getServerName()%>' + ":"+'<%=request.getServerPort()%>'+"&CalledFrom=OPENWI&CabinetName="+sEngineName + "&SessionId="+ sSessionId +"&UserName=" + sUserName+ "&UserIndex=" + sUserIndex + "&pid=" + pId+ "&wid=" + "1&OAPDomHost="+'<%=request.getServerName()%>'+":"+'<%=request.getServerPort()%>';

		//changes started for window size issue by Rohit Verma
		let w = window.innerWidth;
		let h = window.innerHeight;		

		window.open(url, "_blank", "toolbar=yes, scrollbars=yes, resizable=yes, top=0, left=0, width="+w+",height="+(h+20));		

		//changes ended for window size issue by Rohit Verma

		renderOFInboxComponent();
	}
	
	function openOFWorkItem(sProcessInstanceId,wId)
	{	//changes ended to open referred workitem by Rohit Verma

		let top=0;
		let left=0;
		let sProtocol='<%=sessionBean.getProtocol()%>';
		let sEngineName='<%=sessionBean.getCabinetName()%>';
		let sUserName='<%=sessionBean.getLoggedInUser().getUserName()%>';
		let sSessionId='<%=sessionBean.getUserDbId()%>';		
		let sUserIndex='<%=sessionBean.getLoggedInUser().getUserIndex()%>';             
		//changes started to open referred workitem by Rohit Verma

		//let url= sProtocol+"://"+'<%=request.getServerName()%>'+":"+'<%=request.getServerPort()%>'+"/webdesktop/login/loginapp.jsf" + "?WDDomHost="+ '<%=request.getServerName()%>' + ":"+'<%=request.getServerPort()%>'+"&CalledFrom=OPENWI&CabinetName="+sEngineName + "&SessionId="+ sSessionId +"&UserName=" + sUserName+ "&UserIndex=" + sUserIndex + "&pid=" + sProcessInstanceId+ "&wid=" +wId+ "&OAPDomHost="+'<%=request.getServerName()%>'+":"+'<%=request.getServerPort()%>';
		let url= sProtocol+"://"+'<%=request.getServerName()%>'+":"+'<%=request.getServerPort()%>'+"/webdesktop/login/loginapp.app" + "?WDDomHost="+ '<%=request.getServerName()%>' + ":"+'<%=request.getServerPort()%>'+"&CalledFrom=OPENWI&CabinetName="+sEngineName + "&SessionId="+ sSessionId +"&UserName=" + sUserName+ "&UserIndex=" + sUserIndex + "&pid=" + sProcessInstanceId+ "&wid=" +wId+ "&OAPDomHost="+'<%=request.getServerName()%>'+":"+'<%=request.getServerPort()%>';
		
		//changes ended to open referred workitem by Rohit Verma
		//changes started for window size issue by Rohit Verma	 

		
		let w = window.innerWidth;
		let h = window.innerHeight;		
		window.open(url, "_blank", "toolbar=yes, scrollbars=yes, resizable=yes, top=0, left=0, width="+w+",height="+(h+20));
		//changes ended for window size issue by Rohit Verma
		renderOFInboxComponent();
	}
//changes ended

function setDiversion() 
{ 
//Changes by Anant Nigam for calendar height issue
	let strUrl="custom/diversionUser.jsp?egovID=<%=egovUID%>&fromUser=<%=sessionBean.getLoggedInUser().getUserName()%>";
     win =window.open(strUrl,'Search1',"scrollbars=auto,resizable=no,toolbar=no,menubar=no,status=yes,location=no,top="+window1X/2+",left="+window1Y/2+",width="+screen.width*.5+",height="+screen.height*.62);
	 //Changes for window close on logout by rishav started
	 window.parent.addWindows(win);
	//Changes for window close on logout by rishav ended
}
		
//Added by Indra to check user's information on login
function checkUserInfo()
{ 
	if(('<%=loggedInUser_Department%>'=="No Department Set" ||  '<%=LoggedInUser_UserDesignation%>' == "No Designation Set") && !(('<%=hasSupervisorRights%>'=="true") || ('<%=sessionBean.getLoggedInUser().getUserName()%>'=="badmin")))
	{
		alert(set_user_dept_designation);
		LogoutUser();		
	}
	else
		return false;
}
//changes end
//changes started for reminder by Rohit Verma
function updateReminderCounter()
{
$.ajax({
		url: "/"+contextNameGlobal+"/notifications/updateReminderCounter.sp",
		type: "post",
		dataType:'json',
		//data: {id: nid},
		success: function(data) 
		{
			
		},
		error: function(jqXHR, textStatus) 
		{
			
		}
	});
}
//changes ended for reminder by Rohit Verma
// Added by Indra for notifications in case of page refresh and login
function updateCounter()
{

$.ajax({
				url: "/"+contextNameGlobal+"/notifications/updateCounter.sp",
				type: "post",
				dataType:'json',
				//data: {id: nid},
				success: function(data) 
				{
					
				},
				error: function(jqXHR, textStatus) 
				{
					
				}
			});
}
// changes by Indra end
<!-- changes by Somya : KM with Egov -->
function openKM(){
//alert("called");
let commUrlParams1 = "CabinetName=<%=sessionBean.getCabinetName()%>&UserDbId=<%=sessionBean.getUserDbId()%>&JtsIpAdd=<%=sessionBean.getJtsIpAddress()%>&JtsPort=<%=sessionBean.getJtsPort()%>&dataBaseType=<%=sessionBean.getDataBaseType()%>&strEnc=UTF-8&localeString=en";
//alert(commUrlParams1);

window.open("/km/externalLogin.jsp?"+commUrlParams1+"&rid="+MakeUniqueNumber(),"Knowledge & Management","scrollbars=yes,resizable=yes,toolbar=no,Addressbar=no,menubar=no,status=yes,top=" + screen.width + ", left=" + screen.height + ",width="+screen.width+",height="+screen.height);
}
<!-- changes END -->
        </script> 
	
   
<!--Added by Vaibhav on 20/01/2015 for calendar -->	
<!--	<div id="noticationcentermain" style="background: #fff;">-->
<div id="noticationcentermain" style="background: #fff;overflow-x:scroll;overflow-y:hidden; "> <!--Changes by Indra to remove extra scroll bar from home screen in chrome-->
		<div id="addEventForm" class="modal fade" >
			<div class="modal-dialog">
				<div class="modal-content">
					<div class="modal-header">
						<button type="button" class="close" data-bs-dismiss="modal"><span aria-hidden="true">&times;</span><span class="sr-only">Close</span></button>
						<h4 class="modal-title" id="myModalLabel"><%=rsb.getString("Add_new_event")%></h4>
					</div>
					<form id="EventForm" class="well">
					<div class="modal-body" id="formPreview">
						
							<input type="hidden" id="eventId">
							<label><%=rsb.getString("Event_title")%><br />
							<input type="text" name="title" id="title" placeholder="<%=rsb.getString("Title_here")%>"></label><br /><!--Changes as per SonarQube -->
							<div class="checkbox">
								<label>
									<input type="checkbox" name="allDay" id="allDayEvent" value="false">
									<%=rsb.getString("All_Day")%>
								</label>
							</div>
							<label><%=rsb.getString("Scheduled")%> <%=rsb.getString("Start")%> <%=rsb.getString("Date")%><br />
						<!--	<div id="dtpick" class="datepicker">
							<input type="text" name="fromdate" id="fromdate"  data-date-format="YYYY-MM-DD HH:mm"><br />
							</div>
							-->
						<!--	<input type="text" name="fromdate" id="fromdate" class="datepicker" data-date-format="YYYY-MM-DD HH:mm">  -->
							<input type="text" name="fromdate" id="fromdate" class="" data-date-format="YYYY-MM-DD HH:mm">
						    <!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->
							<input type="button" class="btn btn-danger btn-xs cancel--new" value="&times;"></label></br><!-- Changes as per SonarQube -->
							<label><%=rsb.getString("Scheduled")%> <%=rsb.getString("End")%> <%=rsb.getString("Date")%><br />
							
						<!--	<input type="text" name="todate" id="todate" class="datepicker" data-date-format="YYYY-MM-DD HH:mm">  -->
							<input type="text" name="todate" id="todate" class="" data-date-format="YYYY-MM-DD HH:mm">
							<!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->
							<input type="button" class="btn btn-danger btn-xs cancel--new" value="&times;"></label><br /><!-- Changes as per SonarQube -->
							<input type="hidden" name="url" id="url" value="">
							<label><%=rsb.getString("Description")%><br />
							<textarea name="description" id="description" placeholder="<%=rsb.getString("Add_Description")%>" rows="5" cols="30" style="margin: 0px; width: 201px; height: 104px;resize: none;"></textarea></label><br/><!-- Changes as per SonarQube -->
							<!--<input type="text" name="description" id="description" placeholder="<%=rsb.getString("Add_Description")%>"><br />-->
							<input type="hidden" name="editable" value="true">
							<input type="hidden" name="startEditable" value="true">
							<input type="hidden" name="durationEditable" value="true">
							<label><%=rsb.getString("Event")%> <%=rsb.getString("Category")%><br />
							<select id="eventCategory" class="form-control">
								<option value="Meeting"><%=rsb.getString("Meeting_Reminder")%></option>
								<option value="Call"><%=rsb.getString("Call_Reminder")%></option>
								<option value="Task"><%=rsb.getString("Task_Reminder")%></option>
							</select></label><!-- Changes as per SonarQube -->
							<input type="hidden" name="className" id="className" value="">
							<input type="hidden" name="source" value="">						
							<input type="hidden" name="color" value="">
							<input type="hidden" name="backgroundColor" value="">
							<input type="hidden" name="borderColor" value="">
							<input type="hidden" name="textColor" value="">		
							<input type="hidden" name="userid" value="<%=sessionBean.getLoggedInUser().getUserIndex()%>">
							<input type="hidden" name="eventtype" value="user">
						
					</div>
					<div class="modal-footer">
					<!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->
						<button type="button" id="btnPopupCancel" data-bs-dismiss="modal" class="btn btn-danger cancel--new"><%=rsb.getString("Cancel")%></button>
						<button type="submit" name="submit" id="btnPopupSave" class="btn btn-success save--new" ><%=rsb.getString("Save")%> <%=rsb.getString("Event")%></button>
					</div>
					<input id="egovUID" type="hidden" name="egovID" value="<%=egovUID%>"></form>
				</div>
			</div>
		</div>
	<div id="updateEventForm" class="modal fade">
			<div class="modal-dialog">
				<div class="modal-content">
					<div class="modal-body">
						<button type="button" class="close" data-bs-dismiss="modal" style="margin-top:-10px;">&times;</button>
						<form id="updateForm" class="no-margin">
							<input type="hidden" name="eventIdUpdate" id="eventIdUpdate" value="">
							<label><%=rsb.getString("Change")%> <%=rsb.getString("Event")%> <%=rsb.getString("Name")%> &nbsp;
							<input class="middle" name="titleUpdate" id="titleUpdate" autocomplete="off" type="text" value="" /></label><!-- Changes as per SonarQube -->
							<button type="submit" class="btn btn-sm btn-success"><i class="ace-icon fa fa-check"></i> <%=rsb.getString("Save")%></button>
							<div class="checkbox">
								<label>
									<input type="checkbox" name="allDayUpdate" id="allDayUpdate" value="false">
									<%=rsb.getString("All_Day")%>
								</label>
							</div>
							<label><%=rsb.getString("Scheduled")%> <%=rsb.getString("Start")%> <%=rsb.getString("Date")%> &nbsp;<br />
							<!-- <input type="text" name="fromdateUpdate" id="fromdateUpdate" class="datepicker" data-date-format="YYYY-MM-DD HH:mm"><br />  -->
							<input type="text" name="fromdateUpdate" id="fromdateUpdate" class="" data-date-format="YYYY-MM-DD HH:mm"></label><br /><!-- Changes as per SonarQube -->
							<label><%=rsb.getString("Scheduled")%> <%=rsb.getString("End")%> <%=rsb.getString("Date")%> &nbsp;<br />
							<!-- <input type="text" name="todateUpdate" id="todateUpdate" class="datepicker" data-date-format="YYYY-MM-DD HH:mm"><br />  -->
							<input type="text" name="todateUpdate" id="todateUpdate" class="" data-date-format="YYYY-MM-DD HH:mm"></label><br /><!-- Changes as per SonarQube -->
							<label><%=rsb.getString("Description")%> &nbsp;<br />
							<!-- Changes done by Nikita Patidar to change textbox to textarea for description(EGOV-461)-->
							<!--<input type="text" name="descriptionUpdate" id="descriptionUpdate" placeholder="Add Description"><br />-->
							<textarea name="descriptionUpdate" id="descriptionUpdate" placeholder="Add Description" style="margin: 0px; width: 177px; height: 65px;resize: none;"></textarea></label><br /><!-- Changes as per SonarQube -->
							<label><%=rsb.getString("Event")%> <%=rsb.getString("Category")%> &nbsp;<br />
							<select id="eventCategoryUpdate" class="form-control">
								<option value="Meeting"><%=rsb.getString("Meeting_Reminder")%></option>
								<option value="Call"><%=rsb.getString("Call_Reminder")%></option>
								<option value="Task"><%=rsb.getString("Task_Reminder")%></option>
							</select></label><!-- Changes as per SonarQube -->
							<input type="hidden" name="editableUpdate" value="true">
							<input type="hidden" name="startEditableUpdate" value="true">
							<input type="hidden" name="durationEditableUpdate" value="true">
							<input type="hidden" name="classNameUpdate" id="classNameUpdate" value="">
						<input id="egovUID" type="hidden" name="egovID" value="<%=egovUID%>"></form>
					</div>
					<div class="modal-footer">
						<button type="button" class="btn btn-sm btn-danger" id="deleteEvent"><i class="ace-icon fa fa-trash-o"></i><%=rsb.getString("Delete")%> <%=rsb.getString("Event")%></button>
						<button type="button" class="btn btn-sm" data-bs-dismiss="modal"><i class="ace-icon fa fa-times"></i><%=rsb.getString("Cancel")%></button>
					</div>
				</div>
			</div>
		</div>
<!-- Changes ended by Vaibhav -->

	    <iframe id="saveReport" name="saveReport" height="0" title ="saveReport" width="0" hidden></iframe>
		<iframe id="getFileNo" name="getFileNo" src="" title ="getFileNo"  height="0" width="0" hidden ></iframe>
	    <span id="dashboard" class="EWHomeSubHeadings" style="color:green"></span>	
 </head>
 <% //Changed by Neha Kathuria on June 14,2017 to disable Right Click for security constraint
if(DisableRightClick.equalsIgnoreCase("yes"))
{
%>
	<!--changes started for reminder by Rohit Verma-->
	<!--Changes done by Nikita.Patidar for Notifications count Configuration(CQRN-136930)-->
<!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->

	<body role="button" tabindex="0" oncontextmenu="return false" onLoad="fetchReminder();checkUserInfo();itemSelected('dashboard');getAllUsers();getOffileMessages();getNews();" onUnload="closeWindows();" onclick="hideDiv('operations');dakFlagOptionsHtml(2);" onKeyDown="hideDiv('operations');dakFlagOptionsHtml(2);">
<%
}
else
{
%>

	<!--Changes done by Nikita.Patidar for Notifications count Configuration(CQRN-136930)-->
   <!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->
   <body role="button" tabindex="0" onLoad="fetchReminder();checkUserInfo();itemSelected('dashboard');getAllUsers();getOffileMessages();getNews();" onUnload="closeWindows();" onclick="hideDiv('operations');dakFlagOptionsHtml(2);" onKeyDown="hideDiv('operations');dakFlagOptionsHtml(2);">
   <!--changes ended for reminder by Rohit Verma-->
<%
}
// Changes end here
%>
  <!-- Added by Saurabh Rajput on 05/08/2021 for EG10-0019 -->
  <!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->
  <div id="loader" class="center center--loader"></div>
  <!-- ENDs -->
  <input id="egovUID" type="hidden" name="egovID" value="<%=egovUID%>">
  <!--  CHANGES FOR MODAL WINDOW FOR SENT ITEMS  ADDED BY SIDDHARTH NAWANI -->
		
		<div id="modalsent" >
		
			<!-- Modal for RTI sent item-->
			<div class="modal fade" id="myModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
			  <div class="modal-dialog modal-lg">
				<div class="modal-content">
				  <div class="modal-header">
					<button type="button" class="close" data-bs-dismiss="modal"><span aria-hidden="true">&times;</span><span class="sr-only"><%=rsb.getString("Close")%></span></button>
					<!-- Changed by Neha Kathuria for Jtrac id- EGOV- 843-->
					<span class="panel-title" style="cursor: default" id="myModalLabel"><%=rsb.getString("RTI_Sent_Item_Tracking")%> </span>
				  </div>
				  <div class="modal-body" id="modalbody">
			
					<!--Table for queries -->
					
					<div class="panel panel-default">
					      <div   id="rtirequestno">
							</div>
							<div class="panel-heading">
							  <h4 class="panel-title">	
									<%=rsb.getString("RTI_Information")%>		
								<!-- Changes for Bug EGOV-1054 - Gourav Singla -->
								<!-- <span class="pull-right clickable"><i class="glyphicon glyphicon-chevron-up"></i></span> -->
							  </h4>
							  </div>
							<br>
							<div>
							<label for="queryid" class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label"><%=rsb.getString("RTI_RequestNo")%></label><!-- Changes as per SonarQube -->
							<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" >
							<input type="text" class="egov-form-control" id="queryid" name="queryid" value="" readOnly="true"/>
							</div>
							<label for="rtistatus" class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label"><%=rsb.getString("RTI_Status")%></label><!-- Changes as per SonarQube -->
							<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" >
							<input type="text" class="egov-form-control" id="rtistatus" value="" readOnly="true"/>
							</div>
							</div>
							<br><br>
							<div class="panel-heading">
							  <h4 class="panel-title">	
									<%=rsb.getString("RTI_Queries")%>		
								<!-- Changes for Bug EGOV-1054 - Gourav Singla -->
								<!-- <span class="pull-right clickable"><i class="glyphicon glyphicon-chevron-up"></i></span> -->
							  </h4>
							</div>
							<div id="collapseQuery" class="panel-collapse collapse in">
								<div class="panel-body">
									<div class="col-xs-12 col-sm-12 col-md-12 col-lg-12" id="secondPart">
					
										<div class="row">
											<div class="container-fluid">
												<div class="row clearfix">
													<div class="col-xs-12 col-sm-12 col-md-12 col-lg-12 column">
													
														<table class="table table-bordered table-hover" id="tab_logic">
															<thead>
																<tr >
																	<th class="text-center">
																		#
																	</th>
																	<!--Commented for rti common issues - Gourav Singla -->
																	<!--<th class="text-center">
																		<%=rsb.getString("Query_ID")%>
																	</th>-->
																	<th class="text-center">
																		<%=rsb.getString("Query_Info")%>
																	</th>
																	<th class="text-center">
																		<%=rsb.getString("Query_Description")%>
																	</th>
																	<th class="text-center">
																		<%=rsb.getString("Egov_Reply")%>
																	</th>
																	<th class="text-center">
																		<%=rsb.getString("Department")%>
																	</th>
																	<th class="text-center">
																		<%=rsb.getString("Query_Status")%>
																	</th>
																</tr>
															</thead>
															<tbody>
															<div id="loader" class="center"></div>	
																<tr align="center" id='query1'></tr>
																
																
															</tbody>
														</table>
													</div>
												</div>
											
											</div>
										</div>
									</div>
								</div>
							</div>
						</div>
					
					
					
					
					
					<!-- Table for queries end here-->
					
					
					
				  </div>
				  <div class="modal-footer">
					<button type="button" class="btn btn-danger" data-bs-dismiss="modal"><%=rsb.getString("Close")%></button>
					<!-- Changes for Bug EGOV-679 - Gourav Singla -->
					<button type="button" class="btn btn-success" style="display: none;"><%=rsb.getString("Print")%></button>
				  </div>
				</div>
			  </div>
			</div>
			
			<!-- Modal starts for PQ sent items-->
			<div class="modal fade" id="myPQModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
			  <div class="modal-dialog modal-lg">
				<div class="modal-content">
				  <div class="modal-header">
					<button type="button" class="close" data-bs-dismiss="modal"><span aria-hidden="true">&times;</span><span class="sr-only"><%=rsb.getString("Close")%></span></button>
					<!-- Changed by Neha Kathuria for Jtrac id- EGOV- 843-->
					<span class="panel-title" style="cursor: default" id="myModalLabel"><%=rsb.getString("PQ_Sent_Item_Tracking")%> </span>
				  </div>
				  <div class="modal-body" id="modalbody">
			
					<!--Table for queries -->
					
					<div class="panel panel-default">
					     
							<div class="panel-heading">
							  <h4 class="panel-title">	
									<%=rsb.getString("PQ_Information")%>	
								<!-- Changes for Bug EGOV-1054 - Gourav Singla -->
								<!-- <span class="pull-right clickable"><i class="glyphicon glyphicon-chevron-up"></i></span> -->
							  </h4>
							  </div>
							<br>
							<div>
							<label for="pqqueryid" class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label"><%=rsb.getString("PQ_RequestNo")%></label><!-- Changes as per SonarQube -->
							<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" >
							<input type="text" class="egov-form-control" id="pqqueryid" name="pqqueryid" value="" readOnly="true"/>
							</div>
							<label for="status" class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label"><%=rsb.getString("PQ_Status")%></label><!-- Changes as per SonarQube -->
							<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" >
							<input type="text" class="egov-form-control" id="status" value="" readOnly="true"/>
							</div>
							</div>
							<br><br>
							<div class="panel-heading">
							  <h4 class="panel-title">	
									<%=rsb.getString("PQ_Queries")%>		
								<!-- Changes for Bug EGOV-1054 - Gourav Singla -->
								<!-- <span class="pull-right clickable"><i class="glyphicon glyphicon-chevron-up"></i></span> -->
							  </h4>
							</div>
							<div id="collapseQuery" class="panel-collapse collapse in">
								<div class="panel-body">
									<div class="col-xs-12 col-sm-12 col-md-12 col-lg-12" id="secondPart">
					
										<div class="row">
											<div class="container-fluid">
												<div class="row clearfix">
													<div class="col-xs-12 col-sm-12 col-md-12 col-lg-12 column">
													
														<table class="table table-bordered table-hover" id="tab_logicpq">
															<thead>
																<tr >
																	<th class="text-center">
																		#
																	</th>
																	<!-- Commented for pq common issues - Gourav Singla -->
																	<!--<th class="text-center">
																		<%=rsb.getString("Query_ID")%>
																	</th>-->
																	<th class="text-center">
																		<%=rsb.getString("Query_Info")%>
																	</th>
																	<th class="text-center">
																		<!-- Changed by Neha Kathuria for JTRAC id-- EGOV 893																		
																		<%=rsb.getString("Query_Description")%>-->
																		<%=rsb.getString("Remarks")%>
																	</th>
																	<th class="text-center">
																		<%=rsb.getString("Egov_Reply")%>
																	</th>
																	<th class="text-center">
																		<%=rsb.getString("Department")%>
																	</th>
																	<th class="text-center">
																		<%=rsb.getString("Query_Status")%>
																	</th>
																</tr>
															</thead>
															<tbody>
																
																<tr align="center" id='pqquery1'></tr>
																
																
															</tbody>
														</table>
													</div>
												</div>
											
											</div>
										</div>
									</div>
								</div>
							</div>
						</div>
									
					<!-- Table for queries end here-->
							
				  </div>
				  <div class="modal-footer">
					<button type="button" class="btn btn-danger" data-bs-dismiss="modal"><%=rsb.getString("Close")%></button>
					<!-- Commented by Neha Kathuria on Nov 17,2016 for hiding print option
					<button type="button" class="btn btn-success"><%=rsb.getString("Print")%></button>-->
				  </div>
				</div>
			  </div>
			</div>
			<!--modal ends-->
		<!--changes started for Dispatch Module by Rohit Verma	-->		
		<div class="modal fade" id="dispatchHistoryModal" role="dialog">
			<div class="modal-dialog">
				<div class="modal-content">
					<div class="modal-header">
					<!--modified by rishav for bootstrap version update: EG2024-050
						<button type="button" class="close" data-dismiss="modal">&times;</button> -->
						<button type="button" class="close" data-bs-dismiss="modal">&times;</button>
						<h4 class="modal-title"><%=rsb.getString("Dispatch_Details")%></h4>
					</div>
					<div class="modal-body">
						<div id="dispatchmodalbody"></div>
					</div>
					<div class="modal-footer">
					<!-- Commented by Neha Kathuria on Dec 22,2016 for hiding GOTO File Button
						<button type="button" class="btn btn-success" onclick="goToFile();"><%=rsb.getString("Dispatch_Go_To_File")%></button>
						-->
						<button type="button" class="btn btn-danger cancel--new" data-bs-dismiss="modal"><%=rsb.getString("Dispatch_Close")%></button>
					</div>
				</div>
			</div>
		</div>
		<!--changes ended-->
			
			
	<!-- Modal starts for CC sent items-->
			<div class="modal fade" id="sentItemCCModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
			  <!--<div class="modal-dialog modal-lg">-->
			<!--Changes by Anant for Adjusting Search DAK Modal started-->
			  <div style='margin:auto;width:1000px;padding:30px;height:40px'">
			  <!--Changes by Anant for Adjusting Search DAK Modal ended-->
				<div class="modal-content">
				  <div class="modal-header">
					<button type="button" class="close" data-bs-dismiss="modal"><span aria-hidden="true">&times;</span><span class="sr-only"><%=rsb.getString("Close")%></span></button>
					<!-- Changed by Neha Kathuria for Jtrac id- EGOV- 843-->
					<label class="panel-title" style="cursor: default" id="myModalLabel"><%=rsb.getString("CC_Sent_Item_Tracking")%> </label>
				  </div>
				  <div class="modal-body" id="modalbody">
			
					<div class="panel panel-default">
					     
							<div class="panel-heading">
							  <h4 class="panel-title">	
									<%=rsb.getString("CC_Information")%>
								<!-- Changes for issue EGOV-1313 - Gourav Singla -->	
								<!-- <span class="pull-right clickable"><i class="glyphicon glyphicon-chevron-up"></i></span> -->
							  </h4>
							 </div>
							<div id="collapseQuery" class="panel-collapse collapse in">
								<div class="panel-body">
								
								<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label" style="margin-top:5px;" ><%=rsb.getString("CCRequestNo")%></label>
								<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" style="margin-top:5px;" >
									<input type="text" class="egov-form-control" id="ccrequestid"  readOnly="true"/>
								</div>
								
								<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label" style="margin-top:5px;" ><%=rsb.getString("Applicant_Name")%></label>
								<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" style="margin-top:5px;" >
									<input type="text" class="egov-form-control" id="ccapplname" readOnly="true"/>
								</div>	
								<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label" style="margin-top:5px;" ><%=rsb.getString("Current_Status")%></label>
								<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" style="margin-top:5px;" >
									<input type="text" class="egov-form-control" id="ccstatus" name="pqqueryid"  readOnly="true"/>
								</div>						
								<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label" style="margin-top:5px;" ><%=rsb.getString("Filing_Date")%></label>
								<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" style="margin-top:5px;" >
									<input type="text" class="egov-form-control" id="ccfilingdate"  readOnly="true"/>
								</div>	
								<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label" style="margin-top:5px;" ><%=rsb.getString("Case_Detail")%></label>
								<div class="col-xs-10 col-sm-10 col-md-10 col-lg-10" style="margin-top:5px;" >
									<input type="text" class="egov-form-control" id="cccasedetail" name="pqqueryid" readOnly="true"/>
								</div>	
							</div>
							</div>
					</div>
					
				  </div>
				
				
				  <div class="modal-footer">
					<button type="button" class="btn btn-danger" data-bs-dismiss="modal"><%=rsb.getString("Close")%></button>
					<!-- For Bug EGOV-959 - Gourav Singla -->
					<button type="button" class="btn btn-success" style="display:none;"><%=rsb.getString("Print")%></button>
				  </div>
				</div>
			  </div>
			 </div>
		
			<!--modal ends-->
<!--changes started for Inbox Search by Rohit Verma -->
<!--Inbox Search modal starts -->
<div class="modal fade" id="searchInboxModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
	  <div class="modal-dialog modal-lg">
		<div class="modal-content">
		  <div class="modal-body" id="modalbody">			
			<div class="panel panel-default">					     
					<div class="panel-heading">
					  <h4 class="panel-title">	
						<%=rsb.getString("Inbox_Search1")%>	
						<!--modified by rishav for bootstrap version update: EG2024-050
						<span class="pull-right clickable"><button type="button" class="close" data-dismiss="modal">&times; -->
						<span class="pull-right clickable"><button type="button" class="close" data-bs-dismiss="modal">&times;</button></span></button></span>
					  </h4>
					  </div>
				
					<br>
				
					<div id="collapseQuery" class="panel-collapse collapse in">
						<div class="panel-body">
						<!-- for Type -->
						<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label" style="margin-top:5px;" ><%=rsb.getString("Inbox_Type")%>: </label>
						<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" style="margin-top:5px;"> 
						<!--changes started by Rohit Verma for search inbox on :-Priority-->
						<select id="inboxType" class="egov-form-control" >
							<option value="--Select--">--<%=rsb.getString("Select")%>--</option>							
							<!--option value="All"><%=rsb.getString("All")%></option-->
							<!--changes ended by Rohit Verma for search inbox on :-Priority-->
							<option value="File"><%=rsb.getString("File")%></option>
							<!-- changes by kanchan for enable condtion on 25-02-2025 MRPL-0025 -->
							<%
							if( DAKEnable.equalsIgnoreCase("yes")){
							%>
							<option value="Dak"><%=rsb.getString("DAK")%></option>
							<%
							}
							if( OfficeNoteEnable.equalsIgnoreCase("yes")){
							%>
							<option value="Note"><%=rsb.getString("Note")%></option>
							<%
							}
							if( commEnable.equalsIgnoreCase("yes")){
							%>
							<option value="CNM"><%=rsb.getString("C&M")%></option>
							<%
							}
							if( rtiEnable.equalsIgnoreCase("yes")){
							%>
							<option value="RTI"><%=rsb.getString("RTI")%></option>
							<%
							}
							if( pqEnable.equalsIgnoreCase("yes")){
							%>
							<option value="PQ"><%=rsb.getString("PQ")%></option>
							<%
							}
							if( ccEnable.equalsIgnoreCase("yes")){
							%>
							<option value="CC"><%=rsb.getString("CC")%></option>
							<%
							}
							%>
							<!-- Add by Neha ends here -->
						</select>
						</div>												
						<!-- for Subject -->
						<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label" style="margin-top:5px;" ><%=rsb.getString("Inbox_Subject")%>: </label>
						<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" style="margin-top:5px;"> 
						<input type="text" id="inboxSubject" class="egov-form-control"/>
						</div>
						<!-- for Viewed on -->
						<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label" style="margin-top:5px;"><%=rsb.getString("Inbox_Viewed_On")%>: </label>
						<div class="col-xs-5 col-sm-2 col-md-2 col-lg-2" style="margin-top:5px; z-index:9999 !important;">
						<input type="text" id="inboxViewedOn1" name="inboxViewedOn1"  class="egov-form-control dakdatepicker"/>							
						</div>
						<div class="col-xs-5 col-sm-2 col-md-2 col-lg-2" style="margin-top:5px; z-index:9999 !important;">
						<input type="text" id="inboxViewedOn2" name="inboxViewedOn2"   class="egov-form-control dakdatepicker"/>							
						</div>								
						<!-- for from user -->
						<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label" style="margin-top:5px;" ><%=rsb.getString("Inbox_From_User")%>: </label>
						<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" style="margin-top:5px;"> 
						<input type="text" id="inboxFromUser" class="egov-form-control"/>
						</div>
						<!-- for from department -->
						<!-- Changes for Bug EGOV-1299 - Handling Committee Issue - Gourav Singla -->
						<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label from-dept" style="margin-top:5px;"><%=rsb.getString("Inbox_From_Department")%>: </label>
						<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4 from-dept" style="margin-top:5px;">
							<select name="inboxFromDepartment" id="inboxFromDepartment" class="egov-form-control">
								<option  value="">---<%=rsb.getString("Select")%>---</option>
							<%
							for (departmentTypeList.reInitialize(true); departmentTypeList.hasMoreElements(true); departmentTypeList.skip(true)) 
							{
							%>
							<option value='<%=departmentTypeList.getVal("Value2")%>'><%=departmentTypeList.getVal("Value2")%></option>
							<%
							}
							%>
							</select>
						</div>
						<!--Added by Neha Kathuria on May 3,2017 for filter on Introduction Date Time-->
						<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label" style="margin-top:5px;"><%=rsb.getString("Inbox_Intro_On")%>: </label>
						<div class="col-xs-5 col-sm-2 col-md-2 col-lg-2" style="margin-top:5px; z-index:9999 !important;">
						<input type="text" id="inboxIntroOn1" name="inboxIntroOn1"  class="egov-form-control dakdatepicker"/>							
						</div>
						<div class="col-xs-5 col-sm-2 col-md-2 col-lg-2" style="margin-top:5px; z-index:9999 !important;">
						<input type="text" id="inboxIntroOn2" name="inboxIntroOn2"   class="egov-form-control dakdatepicker"/>							
						</div>
						<!-- Add by Neha ends here-->
						<!--changes started by Rohit Verma for search inbox on :-Priority-->
						<!-- for Priority -->
						<!-- Changes for Bug EGOV-1299 - Handling Committee Issue - Gourav Singla -->
						<div id="extraBlk">
							<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label" style="margin-top:5px;" ></label>
							<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" style="margin-top:5px;">
							</div>
						</div>
						<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label" style="margin-top:5px;" ><%=rsb.getString("Inbox_Priority")%>: </label>
						<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" style="margin-top:5px;"> 
							<select id="inboxPriority" class="egov-form-control">
								<option value="">--<%=rsb.getString("Select")%>--</option>
								<option value="4"><%=rsb.getString("Inbox_Priority1")%></option>
								<option value="3"><%=rsb.getString("Inbox_Priority2")%></option>
								<option value="2"><%=rsb.getString("Inbox_Priority3")%></option>
								<option value="1"><%=rsb.getString("Inbox_Priority4")%></option>
							</select>
						</div>						
						<!--changes ended by Rohit Verma for search inbox on :-Priority-->
					</div>
				</div>							
		  </div>
		  
		  <div class="modal-footer">						
			<input type="hidden" id="searchDak"/>
			<!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->				
			<button type="button" class="btn btn-danger cancel--new" data-bs-dismiss="modal"><%=rsb.getString("Inbox_Close")%></button>
			<button type="button" class="btn btn-success save--new"  onClick='setInboxSearchCriteria();'><%=((java.util.ResourceBundle) session.getAttribute("genRSB")).getString("Inbox_Search")%></button>
		  </div>
		</div>
	  </div>
	</div>
</div>
<!-- Inbox Search modal ends -->

<!--Changes by Indra for search sent items-->

<div class="modal fade" id="searchSentItemsModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
	<div class="modal-dialog modal-lg">
		<div class="modal-content">
			<div class="modal-body" id="modalbody">
				<div class="panel panel-default">
					<div class="panel-heading">
						<h4 class="panel-title">	
							<%=rsb.getString("Sent_item_search")%>	
							<!--modified by rishav for bootstrap version update: EG2024-050
							<span class="pull-right clickable"><button type="button" class="close" data-dismiss="modal">
							&times;</button></span> -->
							<span class="pull-right clickable"><button type="button" class="close" data-bs-dismiss="modal">&times;</button></span>
						</h4>
					</div>
					
					<br>
					
					<div id="collapseQuery" class="panel-collapse collapse in">
						<div class="panel-body">
							<!--For item type-->
							<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label" style="margin-top:5px;" ><%=rsb.getString("Type")%>: </label>
							<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" style="margin-top:5px;">
								<select id="sentItemType" class="egov-form-control">
									<option value="All"><%=rsb.getString("All")%></option>
									<option value="File"><%=rsb.getString("File")%></option>
									<!-- changes by kanchan for enable condtion on 25-02-2025 MRPL-0025 -->
									<%
									if( DAKEnable.equalsIgnoreCase("yes")){
									%>
									<option value="DAK"><%=rsb.getString("DAK")%></option>
									<%
									}
									if( OfficeNoteEnable.equalsIgnoreCase("yes")){
									%>
									<option value="Note"><%=rsb.getString("Note")%></option>
									<%
									}
									if( commEnable.equalsIgnoreCase("yes")){
									%>
									<option value="CNM"><%=rsb.getString("C&M")%></option>
									<%
									}
									if( rtiEnable.equalsIgnoreCase("yes")){
									%>
									<option value="RTI"><%=rsb.getString("RTI")%></option>
									<%
									}
									if( pqEnable.equalsIgnoreCase("yes")){
									%>
									<option value="PQ"><%=rsb.getString("PQ")%></option>
									<%
									}
									if( ccEnable.equalsIgnoreCase("yes")){
									%>
									<option value="CC"><%=rsb.getString("CC")%></option>
									<%
									}
									%>	
								</select>
							</div>
							<!--changes started for sent item priority by Rohit Verma-->
							<!-- for priority -->
							<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2" style="margin-top:5px;" ><%=rsb.getString("Inbox_Priority")%>: </label>
							<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" style="margin-top:5px;"> 
							<!-- changes by Tarun Mishra started for CQRN-0000139093 started-->
							<!-- EG9-0019(CQRN-0000139093)-->
								<select id="sentPriority" class="egov-form-control">    
									<option value="">--<%=rsb.getString("Select")%>--</option>
									<!-- changes by Tarun Mishra started for CQRN-0000139093  ended-->
									<option value="4"><%=rsb.getString("Inbox_Priority1")%></option>
									<option value="3"><%=rsb.getString("Inbox_Priority2")%></option>
									<option value="2"><%=rsb.getString("Inbox_Priority3")%></option>
									<option value="1"><%=rsb.getString("Inbox_Priority4")%></option>
								</select>
							</div>
							<!--changes ended for sent item priority by Rohit Verma-->
							<!--For Subject-->
							<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label" style="margin-top:5px;" ><%=rsb.getString("Subject")%>: </label>
							<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" style="margin-top:5px;"> 
							<input type="text" id="sentSubject" class="egov-form-control"/>
							</div>
							
							<!--For initiated on date-->
							<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label" style="margin-top:5px;"><%=rsb.getString("Initiated_On")%>: </label>
							<div class="col-xs-5 col-sm-2 col-md-2 col-lg-2" style="margin-top:5px; z-index:9999 !important;">
							<input type="text" id="initiatedOn1" name="initiatedOn1"  class="egov-form-control dakdatepicker"/>	</div>
							<div class="col-xs-5 col-sm-2 col-md-2 col-lg-2" style="margin-top:5px; z-index:9999 !important;">
							<input type="text" id="initiatedOn2" name="initiatedOn2"   class="egov-form-control dakdatepicker"/>	</div>
							
							<!--For sent on date-->
							<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label" style="margin-top:5px;"><%=rsb.getString("Sent_On")%>: </label>
							<div class="col-xs-5 col-sm-2 col-md-2 col-lg-2" style="margin-top:5px; z-index:9999 !important;">
							<input type="text" id="sentOn1" name="sentOn1"  class="egov-form-control dakdatepicker"/>	</div>
							<div class="col-xs-5 col-sm-2 col-md-2 col-lg-2" style="margin-top:5px; z-index:9999 !important;">
							<input type="text" id="sentOn2" name="sentOn2"   class="egov-form-control dakdatepicker"/>	</div>	
							
							<!--For with user-->
							<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label" style="margin-top:5px;" ><%=rsb.getString("With_User")%>: </label>
							<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" style="margin-top:5px;"> 
							<input type="text" id="withUser" class="egov-form-control"/>
							</div>
							
							<!--For initiated by user-->
							<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label" style="margin-top:5px;" ><%=rsb.getString("Initiated_By")%>: </label>
							<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" style="margin-top:5px;"> 
							<input type="text" id="initiatedByUser" class="egov-form-control"/>
							</div>
							
							<!--For with department-->
							<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label" style="margin-top:5px;"><%=rsb.getString("Inbox_From_Department")%>: </label>
							<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" style="margin-top:5px;">
								<select name="FromDepartment" id="FromDepartment" class="egov-form-control">
									<option  value="">---<%=rsb.getString("Select")%>---</option>
								<%
								for (departmentTypeList.reInitialize(true); departmentTypeList.hasMoreElements(true); departmentTypeList.skip(true)) 
								{
								%>
								<option value='<%=departmentTypeList.getVal("Value2")%>'><%=departmentTypeList.getVal("Value2")%></option>
								<%
								}
								%>
								</select>
							</div>
							<!--For from department-->
							<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label" style="margin-top:5px;"></label>
							<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" style="margin-top:5px;">							
							</div>
							<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label" style="margin-top:5px;"><%=rsb.getString("With_department")%>: </label>
							<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" style="margin-top:5px;">
								<select name="withDepartment" id="withDepartment" class="egov-form-control">
									<option  value="">---<%=rsb.getString("Select")%>---</option>
								<%
								for (departmentTypeList.reInitialize(true); departmentTypeList.hasMoreElements(true); departmentTypeList.skip(true)) 
								{
								%>
								<option value='<%=departmentTypeList.getVal("Value2")%>'><%=departmentTypeList.getVal("Value2")%></option>
								<%
								}
								%>
								</select>
							</div>
						</div>
					</div>
					
					<div class="modal-footer">						
						<input type="hidden" id="searchDak"/>		
						<!--modified by rishav for bootstrap version update: EG2024-050
						<button type="button" class="btn btn-danger" data-dismiss="modal"><%=rsb.getString("Close")%></button> -->
						<button type="button" class="btn btn-danger cancel--new" data-bs-dismiss="modal" style="font-size:14px;"><%=rsb.getString("Close")%></button>
						<button type="button" class="btn btn-success save--new"  style="font-size:14px" onClick='setSentItemSearchCriteria();clearSentItemDates();' ><%=((java.util.ResourceBundle) session.getAttribute("genRSB")).getString("Search")%></button>
					</div>
				</div>
			</div>
		</div>
	</div>
</div>
<!--Search sent items ends-->
<!-- changes ended -->
	<!--Dak search modal starts-->			
	<div class="modal fade" id="searchDakModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
			  <div class="modal-dialog modal-lg">
				<div class="modal-content">
				  <div class="modal-body" id="modalbody">
			
					<!--Table for queries -->
					
					<div class="panel panel-default">
					     
							<div class="panel-heading">
							  <h4 class="panel-title">	
									<%=rsb.getString("DAK_Search")%>
								<!-- Changes started for closing search modal by Rohit Verma-->			
								<!--<span class="pull-right clickable"><i class="glyphicon glyphicon-chevron-up"></i></span>-->
								<!--modified by rishav for bootstrap version update: EG2024-050
								<span class="pull-right clickable"><button type="button" class="close" data-dismiss="modal">&times;</button></span>  -->
								<span class="pull-right clickable"><button type="button" class="close" data-bs-dismiss="modal">&times;</button></span>
								<!-- Changes ended-->	
							  </h4>
							  </div>
						
							<br>
						
							<div id="collapseQuery" class="panel-collapse collapse in">
								<div class="panel-body">
																				
								<!--<tr><td >From User: </td> <td> <input type="text" id="fromUserDakSearch1"/> </td></tr>-->
								<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label" style="margin-top:5px;" ><%=rsb.getString("File_Number")%>: </label>
								<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" style="margin-top:5px;"> 
								<input type="text" id="fileNoDakSearch1" class="egov-form-control"/>
								</div>
								<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label" style="margin-top:5px;"><%=rsb.getString("To_User")%>: </label>
								<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" style="margin-top:5px;">
								<input type="text" id="toUserDakSearch1" class="egov-form-control"/>  
								</div>
														
								<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label"  style="margin-top:5px;"><%=rsb.getString("Status")%>: </label>
														
								<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" style="margin-top:5px;">
									<select name="statusDakSearch1" id="statusDakSearch1" class="egov-form-control">
											<option value="---Select---">---<%=rsb.getString("Select")%>---</option>
											<option value="InProgress"><%=rsb.getString("InProgress")%></option>
											<option value="Complete"><%=rsb.getString("Complete")%></option>
									</select> 
								</div>
								<!-- Changes started for getting Date pop up by Rohit Verma-->						
								<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label"  style="margin-top:5px;"><%=rsb.getString("Date_Range")%>: </label>
								<div class="col-xs-5 col-sm-2 col-md-2 col-lg-2" style="margin-top:5px; z-index:9999 !important;">
								<input type="text" id="dateDakSearch1" name="dateDakSearch1"  class="egov-form-control dakdatepicker"/>							
								</div>
								
								<div class="col-xs-5 col-sm-2 col-md-2 col-lg-2" style="margin-top:5px; z-index:9999 !important;">								
								<input type="text" id="dateDakSearch2" name="dateDakSearch2"   class="egov-form-control dakdatepicker"/>							
								</div>
								<!-- Changes ended-->							
								<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label" style="margin-top:5px;"><%=rsb.getString("Department")%>: </label>



								<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" style="margin-top:5px;">
									<select name="deptDakSearch1" id="deptDakSearch1" class="egov-form-control">
										<option  value="">---<%=rsb.getString("Select")%>---</option>
									<%
									for (departmentTypeList.reInitialize(true); departmentTypeList.hasMoreElements(true); departmentTypeList.skip(true)) 
									{
									%>
									<option value='<%=departmentTypeList.getVal("Value2")%>'><%=departmentTypeList.getVal("Value2")%></option>
									<%
									}
									%>
									</select>
								</div>						
								<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label" style="margin-top:5px;"><%=rsb.getString("DAK")%> <%=rsb.getString("Category")%>: </label>
							
							<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" style="margin-top:5px;">
							   <select name="categoryDakSearch1" id="categoryDakSearch1" class="egov-form-control">
									<option  value="---Select---">---<%=rsb.getString("Select")%>---</option>
										<%
										String[] dakCategoriesArray = dakCategories.split(",");
										for(int ii=0;ii<dakCategoriesArray.length;ii++)
											{
										%>
											<option value="<%=dakCategoriesArray[ii]%>"><%=dakCategoriesArray[ii]%>
											</option>
									    <%
											}
									    %>
								</select>
							</div>	
							<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label"  style="margin-top:5px;"><%=rsb.getString("Dak_Reference_Number")%>: </label>
								<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" style="margin-top:5px;">
								<input type="text" id="docRefNoDakSearch1" class="egov-form-control"/>
								</div>
								<label class="col-xs-6 col-sm-2 col-md-2 col-lg-2 control-label" style="margin-top:5px;"><%=rsb.getString("Subject")%>: </label>
								<div class="col-xs-10 col-sm-4 col-md-4 col-lg-4" style="margin-top:5px;">
								<input type="text" id="subjectDakSearch1" class="egov-form-control"/>
								</div>
										 
							</div>
						</div>
									
					<!-- Table for queries end here-->
							
				  </div>
				  
				  <div class="modal-footer">						
					<input type="hidden" id="searchDak"/>
					<!--modified by rishav for bootstrap version update: EG2024-050
					<button type="button" class="btn btn-danger" data-dismiss="modal"><%=rsb.getString("Close")%></button>  -->
					<button type="button" class="btn btn-danger cancel--new" data-bs-dismiss="modal"><%=rsb.getString("Close")%></button>
					<button type="button" class="btn btn-success save--new"  onClick='setSearchCriteria();clearDates();' data-bs-dismiss="modal"><%=((java.util.ResourceBundle) session.getAttribute("genRSB")).getString("Search")%></button>
				  </div>
				</div>
			  </div>
			</div>
		</div>
	<!--Dak modal ends-->	
	
		</div>
		<!-- CHANGES END HERE --> 
		<!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->
 <div id="wrapper">
 <table width="100%" border="0" cellspacing="0" cellpadding="0" align="center">
  <tr width="100%">
  <td>
  <table width="100%" border="0" cellspacing="0" cellpadding="0" align="center">
 <tr width="100%">
 <td>
 	<!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->
 <nav class="navbar navbar-inverse navbar-fixed-top navbar--new" role="navigation" style="background-color:#448b65;">
            <!-- Brand and toggle get grouped for better mobile display -->
            <div class="navbar-header">
						<!--modified by rishav for bootstrap version update: EG2024-050
						<button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-ex1-collapse">-->
                <button type="button" class="navbar-toggle" data-bs-toggle="collapse" data-target=".navbar-ex1-collapse">
                
                    <span class="sr-only"><%=rsb.getString("Toggle_navigation")%></span>
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                </button>
                	<!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->
                <a class="navbar-brand" href="#" onClick="fetchReminder();setDefault();itemSelected('dashboard');" title="<%=rsb.getString("Home")%>" style="margin-top:-10px;"><img class="new--logo" src="images/Newgen--new.png" style="width:166px; height:40px !important;" ></a>
               
            </div>
            <!-- Top Menu Items -->
            	<!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->
            <ul class="nav navbar-right top-nav black--text">
			<% if(sessionBean.getLoggedInUser().getUserName().equalsIgnoreCase("vaibhav1")){  %>
			<li id="tickerli" class="alert-info" onClick="document.getElementById('tickerli').style.display ='none';" style="margin-top:11px;height:24px;width:700px"> <marquee><span id="tickerBar" > </span></marquee></li>
			<%  }  %>
			<%if(OmniDocsEnable.equalsIgnoreCase("yes") || BAMDashEnable.equalsIgnoreCase("yes")) { %>
			<li class="dropdown">
					<!-- added by rishav for bootstrap version update: EG2024-050
					 <a href="#" class="dropdown-toggle" data-toggle="dropdown" id="gotoMenu" title="<%=rsb.getString("Go_To")%>"><%=rsb.getString("Go_To")%><b class="caret"></b></a> -->
                    <a href="#" class="nav-link dropdown-toggle" data-bs-toggle="dropdown" id="gotoMenu" title="<%=rsb.getString("Go_To")%>"><%=rsb.getString("Go_To")%><b class="caret"></b></a>
                   <!-- Changes by Indra on 3-12-15 for Arabic version-->
                    <ul class="dropdown-menu message-dropdown">
					<%if(OmniDocsEnable.equalsIgnoreCase("yes")) { %>
					<li style="margin-left:5px;margin-bottom:5px;margin-top:5px;"> 
					<!-- onclick function changed by Ashish Anurag on 04-05-2022 to access OmniDocs Web directly from eGov
						<a href="#" onclick='openOdWebDesktop();' ><i class="fa fa-folder-open"></i> <%=rsb.getString("OmniDocs")%></a> -->
						<a href="#" onclick='openOdWeb();' ><i class="fa fa-folder-open"></i> <%=rsb.getString("OmniDocs")%></a>
					</li>
					<%  }  %>
					
					<!-- changes by Somya : KM with Egov -->
					
					<% if(KMEnable.equalsIgnoreCase("yes")) {  %>
					<li style="margin-left:5px;margin-bottom:5px;margin-top:5px;"> 
						<a href="#" onclick='openKM();' ><i class="fa fa-folder-open"></i> Knowledge Management</a>
					</li>
					<%}%>
					
					<!-- changes End -->
					<%if(BAMDashEnable.equalsIgnoreCase("yes")) { %>
					<li style="margin-left:5px;margin-bottom:5px;margin-top:5px;"> 
						<a href="#" onClick="showBAMDash();"><i class="fa fa-bar-chart"></i><%=rsb.getString("BAM")%></a>
					</li>
					<%  }  %>
                    </ul>
             </li>
			<%  }  %>
			 <li class="dropdown">
			 		<!-- added by rishav for bootstrap version update: EG2024-050
                    <a href="#" class="dropdown-toggle" data-toggle="dropdown" id="reportsDD" title="<%=rsb.getString("Reports")%>"><%=rsb.getString("Reports")%><b class="caret"></b></a>
					-->
                    <a href="#" class="nav-link dropdown-toggle" data-bs-toggle="dropdown" id="reportsDD" title="<%=rsb.getString("Reports")%>"><%=rsb.getString("Reports")%><b class="caret"></b></a>
					<!-- Changes by Indra on 3-12-15 for Arabic version-->
                    
                    <ul class="dropdown-menu message-dropdown">
                    
					        
							
<%
							for(int j=0;j<reportNames.length;j++)
							{ 
					
%>
								<li style="margin-left:1px;margin-bottom:1px;margin-top:1px;"> 
									<a href="#" onClick="showBAMReport(<%=BAMReportsMap.get(reportNames[j])%>);"><i class="fa fa-bar-chart"></i> <%=htmlReportNames[j]%></a>
								</li>
								
<%
							}
%>	


							<!-- Starts Changes for BAM Message in case Reports Not Exported -- Gourav Singla -->
<%
							if(reportNames.length == 0){
%>
							<li style="margin-left:5px;margin-bottom:5px;margin-top:5px;">
								<%=((java.util.ResourceBundle) session.getAttribute("genRSB")).getString("REPORT_NOT_CONFIGURED")%>
							</li>
<%
							}
%>
							<!-- Ends Changes for BAM Message in case Reports Not Exported -- Gourav Singla -->
                    </ul>
                </li>
				<!--Added by vishal 6/7/15 for audit-->
<%				
					if(auditEnable.equalsIgnoreCase("Yes"))
					{
%>	
				<li class="dropdown">
					<!--modified by rishav for bootstrap version update: EG2024-050 
                    <a href="#" class="dropdown-toggle" data-toggle="dropdown" id="audit" title="Audit"><%=rsb.getString("AUDIT")%><b class="caret"></b></a>
					-->
                    <a href="#" class="nav-link dropdown-toggle" data-bs-toggle="dropdown" id="audit" title="Audit"><%=rsb.getString("AUDIT")%><b class="caret"></b></a>
                    <ul class="dropdown-menu message-dropdown">
                    
							
<%
							for(int j=0;j<1;j++)
							{ 
					
%>
								<li style="margin-left:1px;margin-bottom:1px;margin-top:1px;"> 
									<a href="#" onClick="setDefault();itemSelected('memocreate');"><i class="fa fa-check-square-o"></i> <%=rsb.getString("Create_Memo")%></a>
								</li>
								
<%
							}
%>						
					   
                    </ul>
                </li>
<%
					}
%>				
<!-- changes started by Rohit Verma for change password option -->	
				<li>
				<!--modified by rishav for bootstrap version update: EG2024-050
				<a href="#" class="dropdown-toggle" title="<%=rsb.getString("Admin_Items")%>" data-toggle="dropdown" id="adminDD"><i class="glyphicon glyphicon-cog"></i> <b class="caret"></b></a>  -->
				<a href="#" class="nav-link dropdown-toggle" title="<%=rsb.getString("Admin_Items")%>" data-bs-toggle="dropdown" id="adminDD"><i class=" fa fa-sharp fa-solid fa-gear"></i> <b class="caret"></b></a>
					<ul class="dropdown-menu message-dropdown">
						<li style="margin-left:2px;margin-bottom:5px;margin-top:5px;">
							<a href="#"  tabindex="-1" onClick="changePassword();"><%=rsb.getString("Change_Password")%></a>
						</li>				
						 <li style="margin-left:2px;margin-bottom:5px;margin-top:5px;">
							<a href="#"  tabindex="-1" onClick="setDiversion();"><%=rsb.getString("Set_Diversion")%></a>
						</li>
<%				//Ayush Gupta: Adding badmin for transfer module

					if(hasSupervisorRights.equalsIgnoreCase("true") || isAdmin)

					{
						if(isAdmin || hasSupervisorRights.equalsIgnoreCase("true"))
						{
				%>			
						
						<!--Added by Pushkar (19/1/2017, Transfer Module JS function to load js module)-->
							<li style="margin-left:5px;margin-bottom:5px;margin-top:5px;">
								<a href="#"  tabindex="-1" onClick="transferModule();"><%=rsb.getString("Transfer_Module")%></a>
							</li>
				<%
						}	
						
						if(hasSupervisorRights.equalsIgnoreCase("true"))
						{
				%>
			           	<!-- added by kanchan for password EG10-0032-->
                        <li style="margin-left:2px;margin-bottom:5px;margin-top:5px;">
							<a href="#"  tabindex="-1" onClick="changePasswordWh();"><%=rsb.getString("Change_WhUser_Password")%></a>
							
						</li>
                        <li style="margin-left:2px;margin-bottom:5px;margin-top:5px;">
							<a href="#"  tabindex="-1" onClick="changePasswordTM();"><%=rsb.getString("Change_TMUser_Password")%></a>
							
						</li>						
                          <!--ended here-->						
						<li style="margin-left:5px;margin-bottom:5px;margin-top:5px;">
							<a href="#"  tabindex="-1" onClick="updateUser();"><%=rsb.getString("Update_User")%></a>
						</li>
						<!-- added by kanchan on 18-04-2024 for department -->
						<li style="margin-left:5px;margin-bottom:5px;margin-top:5px;">
							<a href="#"  tabindex="-1" onClick="addDepartment();"><%=rsb.getString("Add_Department")%></a>
						</li>
						<!-- added by kanchan on 18-04-2024 for designation -->
						<li style="margin-left:5px;margin-bottom:5px;margin-top:5px;">
							<a href="#"  tabindex="-1" onClick="addDesignation();"><%=rsb.getString("Add_Designation")%></a>
						</li>
						 <!--<li class="divider"></li>-->
						<li style="margin-left:5px;margin-bottom:5px;margin-top:5px;">
							<a href="#"  tabindex="-1" onClick="createRule();"><%=rsb.getString("Create_Rule")%></a>
						</li>
						<!-- <li class="divider"></li>-->
						<li style="margin-left:5px;margin-bottom:5px;margin-top:5px;">
							<a href="#"  tabindex="-1" onClick="modifyRule();"><%=rsb.getString("Modify_Rule")%></a>
						</li>	

						<!--Added by Pushkar (03 Nov,2017, User OD-Dongle Mapping JS function to load js module)-->
							<li style="margin-left:5px;margin-bottom:5px;margin-top:5px;">
								<a href="#"  tabindex="-1" onClick="dongleODUserMap();"><%=rsb.getString("DigitalSignature_User_Dongle_Mapping")%></a>
							</li>
			<%
						}
					}

%>					
					</ul>
				</li>

				<!-- changes ended-->		
				<li class="">
								<!-- modified by rishav for bootstrap version update: EG2024-050
                    <a href="#"  onClick="setDefault();itemSelected('calendar');" title="<%=rsb.getString("Calendar")%>" id="calendar" style="margin-top:3px;"><i class="glyphicon glyphicon-calendar" ></i> </a>
					-->
                    <a href="#"  onClick="setDefault();itemSelected('calendar');" title="<%=rsb.getString("Calendar")%>" id="calendar" style="margin-top:0px;display:none;"><i class="fa fa-calendar-days"></i></a>
					<!-- Changes by Indra on 3-12-15 for Arabic version-->
				
                </li>
				      
                <li class="">
                	<!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->
                    <a href="#"  title="<%=rsb.getString("Notification")%>" id="notificationcentericon" style="margin-top:3px;display:none"><i class="fa fa-bell" ></i> </a>
<!-- Changes by Indra on 3-12-15 for Arabic version-->
				
                </li>
                <li class="dropdown">
				
					<!-- Description –  Overlap of chat box and logout button
						set z-index order on logout
						Date of Resolution – 14/09/2017  
						Resolved by – Somya Bagai -->
				
					<!-- added by rishav for bootstrap version update: EG2024-050 
                    <a href="#" class="dropdown-toggle" data-toggle="dropdown">&nbsp;<%=rsb.getString("Welcome")%> <%=LoggedInUser_UserDesignation%>, <%=sessionBean.getLoggedInUser().getFirstName()%>&nbsp;<%=sessionBean.getLoggedInUser().getLastName()%>&nbsp;<b class="caret"></b></a> -->
					<a href="#" class="nav-link dropdown-toggle" data-bs-toggle="dropdown">&nbsp;<%=rsb.getString("Welcome")%> <%=LoggedInUser_UserDesignation%>, <%=sessionBean.getLoggedInUser().getFirstName()%>&nbsp;<%=sessionBean.getLoggedInUser().getLastName()%>&nbsp;<b class="caret"></b></a>
					<!--Changes by Anant for handling log-out issue-->
                    <!--<ul class="dropdown-menu" style="z-index: 5;">  -->         
                        <ul class="dropdown-menu">	
                    <!--Changes by Anant ended-->						
                        <li><!--changes for opening cutom process workitems by Rohit Verma-->					
                            <a href="#" title="Logout" id="btnLogout" onClick="changeUnload();updateLogoutTimeStamp();logoutOmniApp();LogoutUser();return false;"><i class="fa fa-fw fa-power-off"></i><%=rsb.getString("Log_Out")%></a>
							<!--changes ended-->
                        </li>
                    </ul>
                </li>
            </ul>
            
        </nav>

</td>
</tr>
	<!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->
</table>
</td>
</tr>
</table>
</div>
	<div class="container1">
  <div class="left-panel" id="leftpanel">
		 <div class="icon" id="icon1" onclick="sideBar('icon1');"><img src="image/dashboard1.png" width="20" height="20"><br><b><%=rsb.getString("Workdesk")%></b></div>
<%
			int loggedInUserIndex=sessionBean.getLoggedInUser().getUserIndex();
			String inputXmlGroup="<?xml version=\"1.0\"?><NGOGetGroupListExt_Input><Option>NGOGetGroupListExt</Option><CabinetName>"+sessionBean.getCabinetName()+"</CabinetName><UserDBId>"+sessionBean.getUserDbId()+"</UserDBId><UserIndex>"+loggedInUserIndex+"</UserIndex><OrderBy>2</OrderBy><SortOrder>A</SortOrder><PreviousIndex>0</PreviousIndex><LastSortField></LastSortField><NoOfRecordsToFetch>250</NoOfRecordsToFetch><MainGroupIndex>0</MainGroupIndex></NGOGetGroupListExt_Input>";
			String outputXmlGroup=sessionBean.execute(inputXmlGroup);
			DMSXmlResponse xmlResponseGroup = new DMSXmlResponse(outputXmlGroup);
			DMSXmlList groupList = xmlResponseGroup.createList("Groups", "Group");
			//changes started for dispatch groups by Rohit Verma
			String groupNames[]=deptDispatchGroupNames.toLowerCase().split(",");
			String userDispatchGroups="";
			int dispatchFlag=0;
			for(int i=0;i<groupNames.length;i++){
				if (groupList != null){				
					for(groupList.reInitialize(true);groupList.hasMoreElements(true);groupList.skip(true)){					
						if(groupList.getVal("GroupName").equalsIgnoreCase(groupNames[i])){
							dispatchFlag=1;
							userDispatchGroups+=groupList.getVal("GroupName")+",";
						}
					}
				}
			}
			session.setAttribute("DispatchGroupNames",deptDispatchGroupNames);
			session.setAttribute("userDispatchGroupNames",userDispatchGroups);			
%>
	<script>
	
	document.querySelector('.fa-calendar-days').style.display = 'none'; // added by shirish to hide calendar icon
	// Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)
	let dispatchFlag='<%=dispatchFlag%>';
	let dispatchGroupNames='<%=userDispatchGroups%>';
	let allDispatchGroupNames='<%=deptDispatchGroupNames%>';					
	</script>
       
<%
		if( flagDak==1)
		{
			if(DAKEnable.equalsIgnoreCase("yes")) 
			{
%>
	<!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->
 <div class="icon" id="icon2"  onclick="sideBar('icon2');"><img src="image/dak.png" width="23" height="21"><br><b><%=rsb.getString("DAK")%></b></div>
<%
		}
	}
%>
	<!-- Changes by Saurabh Rajput ends for MRPL new UI(MRPL-0001)-->		
       
<%
		if( flagOffNote==1)
		{
			if(OfficeNoteEnable.equalsIgnoreCase("yes")) 
			{
%>
	<!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->
 <div class="icon" id="icon3"  onclick="sideBar('icon3');"><img src="image/note.png" width="21" height="22"><br><b><%=rsb.getString("Note")%></b></div>
<%
		}
	}
%>
		
       
<%
		if( flagSubF==1)
		{
%>	
	<!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->
		 <div class="icon" id="icon4"  onclick="sideBar('icon4');"><img src="image/files.png" width="22" height="20"><br><b><%=rsb.getString("Files")%></b></div>
<%
		}
%>
<!--added by kanchan for committe integrate on 07-01-2025 -->
<%
		if( flagComm==1)
		{
			if(commEnable.equalsIgnoreCase("yes")) 
			{
%>	
<div class="icon" id="icon5"  onclick="sideBar('icon5');"><img src="image/dak.png" width="23" height="21"><br><b><%=rsb.getString("C&M")%></b></div>
<%
			}
		}
%>
</div>
	<!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->
<div class="main-content" id="mainContent">
		<div class="col-xs-12 col-sm-12 col-md-12 col-lg-12" style = "padding:0px!important;height:100%" id="mainBody" ><!-- Changed by Neha Kathuria for UI issue-->
			<!-- Changed by Neha Kathuria for UI issue-->	
			<%
		//	if(!refresh.equalsIgnoreCase("Y")){
				%>
				<div id="itemSelected" class="col-xs-3 col-sm-3 col-md-3 col-lg-3 EWMsg1" align="left" class='EWEnabledLinkfont' style='font-weight: bold;font-size:14px;margin-top:8px;'> </div>							


				<!--Added by Vaibhav on 20/01/2015 for calendar -->
				<div id="pageList" class="col-xs-5 col-sm-5 col-md-5 col-lg-5 EWMsg1" ></div>
				<!--Changes ended by Vaibhav -->							

	<!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->
				<div id="itemlinks" class="col-xs-9 col-sm-9 col-md-9 col-lg-9 EWMsg1" align="right"></div>
				<!-- Added by Adeeba on 10/06/2025 for opening list of workitems on the click of bar graph for Prev/Next -->
				 <div id="itemlinksnepr" class="col-xs-12 col-sm-12 col-md-12 col-lg-12" align="right"></div>
				<!-- Changed by Neha Kathuria on May 11, 2017 for displaying next/prev button (changes revert back)-->

			<%//}%>
				<!--added by Dheeraj mishra  on Dec 4, 2017 for jtrac issue EGOV-358 the File Number column the table is stretched.-->
               	<!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->
                <div id="listItems" class="col-xs-12 col-sm-12 col-md-12 col-lg-12" style="width:100%;height:100%;padding:0px!important;overflow:auto"></div> 				

				<!--<div id="listItems" class="col-xs-12 col-sm-12 col-md-12 col-lg-12"  class="panel-body"></div>--><!-- commented by Dheeraj for jtrac issue EGOV-358 -->
				<!--<div id="listItems" class="col-xs-12 col-sm-12 col-md-12 col-lg-12"  class="panel-body" style="overflow:auto;width:1350px;height:auto;overflow-y: hidden;"></div> <!--added by Indra to add scroll bar in case of increased number of fields in inbox/sent items/ufdaks-->
					<!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->
				<!--Added By Dheeraj Mishra on Dec 19'17 for Jtrack EGOV-385 Scroll bar issue in search document-->
                <div id="listIDocs" class="col-xs-12 col-sm-12 col-md-12 col-lg-12 " style="overflow:auto;width:100%;height:100%;overflow-y: hidden;display:none;" ></div>
		
		</div>
	<!-- Changes by Saurabh Rajput ends for MRPL new UI(MRPL-0001)-->

<!-- Ayush Gupta: Changes for UI issues in Chat window -->
	<% if(chatEnable.equalsIgnoreCase("yes")){ %>
		<!-- Description –  Overlap of chat box and logout button
set z-index order on class chat-box
Date of Resolution – 14/09/2017  
Resolved by – Somya Bagai -->
		<div class="chat-box" style="z-index: 4;">
		<!--<input type="checkbox" />-->
		<label id="lb1" style="width:200px !important;z-index:9998 !important;" >Chat 
				<a id = "upbutton" type="button" onclick="showChatDiv();" style="align:right !important;" class="btn btn-default btn-xs">
                            <span class="glyphicon glyphicon-chevron-up"></span>
                        </a>
						<a id = "downbutton" type="button" onclick="hideChatDiv();" style="align:right !important;display:none;" class="btn btn-default btn-xs">
                            <span class="glyphicon glyphicon-chevron-down"></span>
                        </a>
						</label>
		<div id="chatusersdiv" class="chat-box-content">
			<span class="label label-default">
			<%=rsb.getString("Online_Users")%>
			</span>
			<label id="status"></label>
			<label id="userlabel"></label>
			<div id="userdiv">
			</div>
			<br>
			<span class="label label-default">
			<%=rsb.getString("Offline_Users")%>
			</span>
			<div id="offlineuserdiv">
			</div>	
		</div>
		</div>
		<div id="chatholder"></div>
	<% } %>
	
	<script>
	
	function showChatDiv() {
		
	   document.getElementById('chatusersdiv').style.display = "block";
	   document.getElementById('lb1').style.position = "fixed";
	  // document.getElementById('lb1').innerHTML  = "Close Chat";
	   //document.getElementById('upbutton').style.visibility = "hidden";
	   //document.getElementById('downbutton').style.visibility = "visible";
	   $('#downbutton').show();
	   $('#upbutton').hide();
	}
	function hideChatDiv() {
		
	   document.getElementById('chatusersdiv').style.display = "none";
	   document.getElementById('lb1').style.position = "relative";
	  // document.getElementById('lb1').innerHTML  = "Open Chat";
	    $('#upbutton').show()
	    $('#downbutton').hide()
	}
	</script>
<div id="fadedBack" class="opacityObj" style="height:100%;width:100%;top:0%;left:0px;position:absolute;overflow-y:auto;overflow-x:auto;border-style:ridge;
         border-width:2px;border-color:purple;border-top-width:2px;background-color:gray;display:none;z-index:5">
        <table width="100%">
            <tr width="100%">
                <td width="100%">
                    
                </td>
            </tr>

        </table>
</div>	

<div id="fadedDashboard" class="opacityObj" style="height:100%;width:100%;top:0%;left:0px;position:absolute;overflow-y:auto;overflow-x:auto;border-style:ridge;
         border-width:2px;border-color:purple;border-top-width:2px;background-color:white;display:block;z-index:5">
       <table width="100%">
            <tr width="100%">
                <td width="100%" valign="center" align="center">
                    
				</td>
            </tr>

        </table>
</div>

	
		<!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->
		<div id="operations" style="display:none; background-color: white; height:auto; width:110px;position:absolute;Z-index:4;margin-left: -110px;margin-top: 23px;">
        </div>
		
<!-- Ayush Gupta: Adding div for move/copy issue  -->		
		<div id="operations1" >
        </div>
		<!----------Added By Varun---------------->
			<!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->
		<div id="flagOptions" style="display:none; height:auto; width:110px;position:absolute;z-index:4;margin-left:-110px;margin-top: 23px;" onMouseOver="showDiv('flagOptions');" onMouseOut="hideDiv('flagOptions');">
				<table border="0" style="border-style:solid;border-width:1px;" height="120px"width="135px" align="left"	bgcolor="white" cellpadding="2" cellspacing="0">
				
					<tr>
						<td background="images/white_u.gif">
						<!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->
						<a href='#' onClick="flagMessage('4');" style="align=right" class= EWEnabledLink ><%=rsb.getString("Very_High")%></a>
						</td>
						<td background="images/white_u.gif">
						<img src='images/priority_veryhigh.gif' width=15 height=15 align='right'>
						</td>
					</tr>
					<tr>
						<td background="images/white_u.gif">
						<a href='#' onClick="flagMessage('3');" class= EWEnabledLink ><%=rsb.getString("High")%></a>
						</td>
						<td background="images/white_u.gif">
						<img src='images/priority_high.gif' width=15 height=15 align='right'>
						</td>
					</tr>
					<tr>
						<td background="images/white_u.gif">
						<a href='#' onClick="flagMessage('2');" class= EWEnabledLink ><%=rsb.getString("Medium")%></a>
						</td>
						<td background="images/white_u.gif">
						<img src='images/priority_medium.gif' width=15 height=15 align='right'>
						</td>
					</tr>
					<tr>
						<td background="images/white_u.gif">
						<a href='#' onClick="flagMessage('1');" class= EWEnabledLink ><%=rsb.getString("Low")%></a>
						</td>
						<td background="images/white_u.gif">
						<img src='images/priority_low.gif' width=15 height=15 align='right'>
						</td>
					</tr>							
				</table>
		</div>	
	<!--changes started for inbox search by Rohit Verma-->
		<div id="holdMessageDiv1" style="display:none; height:auto; width:110px;position:absolute;z-index:4" >
			<table border="0" style="border-style:solid;border-width:1px;" width="10%" align="left"	bgcolor="white" cellpadding="2" cellspacing="0">
				<tr>
					<td background="images/white_u.gif">
						<textarea rows="4" cols="15" id="holdMessageValue1" value="" >
						</textarea><!--Changed by Neha Kathuria on Aug 17,2016 for hold message. -->
					</td>
				</tr>
				<tr align="center">
					<td background="images/white_u.gif">
						<input type="button" value="Submit" onClick="holdFile1();" class="btn btn-success btn-xs"/>
						<input type="button" value="Close" onClick="hideDiv('holdMessageDiv1');" class="btn btn-danger btn-xs"/>
					</td>
				</tr>						
			</table>
		</div>
	

<input type="hidden" name="myField" id="myField" value="" />
<script>
function myFieldValue()
{
	let myFieldVal=document.getElementById('myField').value;	
	return myFieldVal;
}
	
</script>
	<!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->
		<div id="flagOptions1" style="display:none; height:auto; width:110px;position:absolute;z-index:4;margin-left:-110px;margin-top: 23px;" onMouseOver="showDiv1('flagOptions1',myFieldValue());" onMouseOut="hideDiv('flagOptions1');">	
				<table border="0" style="border-style:solid;border-width:1px;" width="80%" align="left"	bgcolor="white" cellpadding="2" cellspacing="0">				
					<tr>
						<td background="images/white_u.gif">
						<a href='#' onClick="flagMessage1('4',myFieldValue());" class= EWEnabledLink ><%=rsb.getString("Very_High")%></a>
						</td>
						<td background="images/white_u.gif">
						<img src='images/priority_veryhigh.gif' width=15 height=15 align='right'>
						</td>
					</tr>
					<tr>
						<td background="images/white_u.gif">
						<a href='#' onClick="flagMessage1('3',myFieldValue());" class= EWEnabledLink ><%=rsb.getString("High")%></a>
						</td>
						<td background="images/white_u.gif">
						<img src='images/priority_high.gif' width=15 height=15 align='right'>
						</td>
					</tr>
					<tr>
						<td background="images/white_u.gif">
						<a href='#' onClick="flagMessage1('2',myFieldValue());" class= EWEnabledLink ><%=rsb.getString("Medium")%></a>
						</td>
						<td background="images/white_u.gif">
						<img src='images/priority_medium.gif' width=15 height=15 align='right'>
						</td>
					</tr>
					<tr>
						<td background="images/white_u.gif">
						<a href='#' onClick="flagMessage1('1',myFieldValue());" class= EWEnabledLink ><%=rsb.getString("Low")%></a>
						</td>
						<td background="images/white_u.gif">
						<img src='images/priority_low.gif' width=15 height=15 align='right'>
						</td>
					</tr>							
				</table>
		</div>
<!-- changes ended -->

		<div id="holdMessageDiv" style="display:none; height:auto; width:110px;position:absolute;z-index:4" >
			<table border="0" style="border-style:solid;border-width:1px;" width="10%" align="left"	bgcolor="white" cellpadding="2" cellspacing="0">
				<tr>
					<td background="images/white_u.gif">
						<textarea rows="4" cols="15" id="holdMessageValue" value="" >
						</textarea>
					</td>
				</tr>
				<tr align="center">
					<td background="images/white_u.gif">
						<input type="button" value="Submit" onClick="holdFile();" class="btn btn-success btn-xs save--new"/>
						<input type="button" value="Close" onClick="hideDiv('holdMessageDiv');" class="btn btn-danger btn-xs cancel--new"/>
					</td>
				</tr>						
			</table>
		</div>		
		<!----------------------------------------->
		
        <div id="loadingMessage" style="position:absolute;height:8px;
        width:10px;top:300px;left:500px;display:none">
            <table ><tr><td style="color:red;"><%=((java.util.ResourceBundle)session.getAttribute("genRSB")).getString("Loading")%>....</td></tr></table>
        </div>
	
        <!--<div id="alarms" style="position:absolute;height:auto;right:2px;bottom:2px;
        width:250px;display:block;z-index:1;">
            <table border="0" cellspacing="0" cellpadding="2" width="100%" style="border-style:solid;border-width:1px;" cellpadding="4" cellspacing="0">
                <tr>
                    <td background="images/white_u.gif" style="background-repeat:repeat" class="EWLabelBold">
                        <table width="100%" border="0" cellpadding="0" cellspacing="0" >
							<tr><%if(Reminder_Config=="Yes"){
							%>
                                <td background="images/white_u.gif" style="background-repeat:repeat" width="100%" align="left" class="EWErrorMessage"><%=rsb.getString("Alarms")%>/<%=rsb.getString("Reminders")%></td>
                                <td align="right"><img src="images/close.gif" onClick="hideAlarmsDiv();"></td>
								<%}
								else{
								%>

								<td background="images/white_u.gif" style="background-repeat:repeat" width="100%" align="left" class="EWErrorMessage"><%=rsb.getString("Alarms")%></td>
                                <td align="right"><img src="images/close.gif" onClick="hideAlarmsDiv();"></td>
								<% }
								%>
                            </tr>
                        </table>
                    </td>
                </tr>
                <tr>
                    <td>
                        <div id="alarmslist" >   
                        </div>
                    </td>
                </tr>
            </table>
        </div> -->

	
   <!--<tr>
    <td>&nbsp;</td>
  </tr>
  
  <tr>
    <td>&nbsp;</td>
  </tr> 
 <tr>
    <td>&nbsp;</td>
  </tr>
  
  <tr>
    <td>&nbsp;</td>
  </tr>-->
  <!--<tr>
  
    <td align="center">
	    
	<img src="images/bg.png" width="965" height="1">
	</td>
  </tr>-->
  <!--<tr>
    <td>&nbsp;</td>
  </tr>-->


<!-- Changed by Neha Kathuria on Jan 22,2016  to directly open Custom desktop from "GOTO Omnidocs" option-->
   <form name="odwebdesktop" method="get" action="../omnidocs/ExtendSession.jsp">
            <input type="hidden" name="CabinetName" value="<%=sessionBean.getCabinetName()%>"/>
            <input type="hidden" name="UserDbId" value="<%=sessionBean.getUserDbId()%>"/>
<!--
 Changed By						: Rohit Mittal
 Reason / Cause (Bug No if Any)	: UTBUG013
 Change Description				: Added parameters to be sent to webextendsession.jsp.
-->
<!--
			Commented by Neha Kathuria on Jan 22,2016 to directly open Custom desktop from "GOTO Omnidocs" option
            <input type="hidden" name="UserIndex" value="<%=sessionBean.getLoggedInUser().getUserIndex()%>"/>
            <input type="hidden" name="JtsIpAdd" value="<%=sessionBean.getJtsIpAddress()%>"/>
            <input type="hidden" name="JtsPort" value="<%=sessionBean.getJtsPort()%>"/>
            <input type="hidden" name="DataBaseType" value="<%=sessionBean.getDataBaseType()%>"/>
			<input type="hidden" name="Encoding" value="UTF-8"/>
			<input type="hidden" name="LaunchSearch" value="N"/>
			<input type="hidden" name="ShowLogOut" value="No"/>
			<input type="hidden" name="Webaccess" value="true"/>
			<input type="hidden" name="Locale" value="en_US"/>
        <input id="egovUID" type="hidden" name="egovID" value="<%=egovUID%>"></form>-->
		<form name="committeeHome" method="get" action="../committee/externalLogin.jsf">
            <input type="hidden" name="CabinetName" value="<%=sessionBean.getCabinetName()%>"/>
            <input type="hidden" name="UserDbId" value="<%=sessionBean.getUserDbId()%>"/>
            <input type="hidden" name="UserIndex" value="<%=sessionBean.getLoggedInUser().getUserIndex()%>"/>
            <input type="hidden" name="UserName" value="<%=eUser.getUserName()%>"/>
            <input type="hidden" name="JtsIpAdd" value="<%=sessionBean.getJtsIpAddress()%>"/>
            <input type="hidden" name="JtsPort" value="<%=sessionBean.getJtsPort()%>"/>
			<input type="hidden" name="redirectURLComm" value="compostion/compose.jsf"/>
			
        <input id="egovUID" type="hidden" name="egovID" value="<%=egovUID%>"></form>
		<form name="specialfilesintegration" method="post" action="../omnidocs/webaccess/configurations/launchsearch.jsp">
			<input type="hidden" name="CriterionName" value=""/>
            <input type="hidden" name="CabinetName" value="<%=sessionBean.getCabinetName()%>"/>
            <input type="hidden" name="Userdbid" value="<%=sessionBean.getUserDbId()%>"/>
            <input type="hidden" name="UserIndex" value="<%=sessionBean.getLoggedInUser().getUserIndex()%>"/>
            <!--<input type="hidden" name="UserName" value="<%=sessionBean.getLoggedInUser().getUserName()%>"/>-->
            <input type="hidden" name="JtsIpAdd" value="<%=sessionBean.getJtsIpAddress()%>"/>
            <input type="hidden" name="JtsPort" value="<%=sessionBean.getJtsPort()%>"/>
            <input type="hidden" name="DataBaseType" value="<%=sessionBean.getDataBaseType()%>"/>
			<input type="hidden" name="HeaderFooter" value="N"/>
			<input type="hidden" name="sessionIndexSet" value="false"/>
        <input id="egovUID" type="hidden" name="egovID" value="<%=egovUID%>"></form>
		<form name="knowledgemanager" method="POST" action="../nkms1/kms/mainodkm.jsp">
			<input type="hidden" name="CabName" value="<%=sessionBean.getCabinetName()%>" >
			<input type="hidden" name="UsrDbId" value="<%=sessionBean.getUserDbId()%>" >
			<input type="hidden" name="jtsipadd" value="<%=sessionBean.getJtsIpAddress()%>" >
			<input type="hidden" name="jtsport" value="<%=sessionBean.getJtsPort()%>" >
			<input type="hidden" name="CabID" value="<%=sessionBean.getCabinetId()%>" >
			<input type="hidden" name="DataBaseType" value="<%=sessionBean.getDataBaseType()%>" >
			<input type="hidden" name="GroupName" value="<%=sessionBean.getGroupName()%>" >
			<input type="hidden" name="UserName" value="<%=eUser.getUserName()%>" >
			<input type="hidden" name="LoggedInUserIndex" value="<%=eUser.getUserIndex()%>" >
			<input type="hidden" name="UserPassword" value="" ><!--EG-0008: User Credentials traverses in Cleartext-->
						
		<input id="egovUID" type="hidden" name="egovID" value="<%=egovUID%>"></form>
		<form name="specialFilesSearch" method="post" action="">
			<input type="hidden" name="DataDefIndex" value="" >
			<input type="hidden" name="FieldCriteria" value="" >
		<input id="egovUID" type="hidden" name="egovID" value="<%=egovUID%>"></form>
		<form name="stayAtPage" method="post" action="../office.jsp#no-back">
		<input id="egovUID" type="hidden" name="egovID" value="<%=egovUID%>"></form>
		
		<!--Changes done  by Nikita for Session Hijacking(EG-0001)-->
		<form name="Folderview" method="post" action="">
		<input type="hidden" name="FromInbox" value="" >
		<input type="hidden" name="DocId" value="" >
		<input type="hidden" name="DocVersion" value="" >
		<input type="hidden" name="NoteNo" value="" >
		<input type="hidden" name="FromAttach" value="" >
		<input type="hidden" name="FolderName" value="" >
		<input type="hidden" name="FolderId" value="" >
		<input type="hidden" name="FolderRights" value="" >
		<input type="hidden" name="ProcessInstanceId" value="" >
		<input type="hidden" name="WorkitemId" value="" >
		<input type="hidden" name="OrderBy" value="" >
		<input type="hidden" name="SortOrder" value="" >
		<input type="hidden" name="LastValue" value="" >
		<input type="hidden" name="tempVar" value="" >
		<input type="hidden" name="typeforaicte" value="" >
		<input type="hidden" name="FromSentItems" value="" >
		<input type="hidden" name="VolumeIndex" value="" >
		<input type="hidden" name="NotesView" value="" >
		<input type="hidden" name="FullView" value="" >
		<input type="hidden" name="SHOWFULLVIEW" value="" >
		<input type="hidden" name="OpenAI" value="" >
		<input type="hidden" name="RTICompleted" value="" >
		<input type="hidden" name="CurrFolderIndex" value="" >
		<!--Added by Saurabh Rajput on 19/05/2022 for EG10-0028(Prev/Next after filter)-->
		<input type="hidden" name="FilterCheck" value="" >
		<!-- changes by Saurabh ends here -->
		<!--Added by Adeeba on 13-7-2023 to remove inititate functionality from special file case -->
		<input type="hidden" name="FromSpecialFiles" value="" >
		<input id="egovUID" type="hidden" name="egovID" value="<%=egovUID%>"></form>
		<!--Changes ended by Nikita for Session Hijacking (EG-0001)-->

 <!--Changes done  by Ojasvi for Session Hijacking(EG-0001)-->

		<form name="Notesview" method="post" action="">
		<input type="hidden" name="Modify" value="" >
		<input type="hidden" name="FolderIndex" value="" >
		<input type="hidden" name="DocumentIndex" value="" >
		<input type="hidden" name="DocName" value="" >
		<input type="hidden" name="rid" value="" >
		<input type="hidden" name="DocId" value="" >
		<input type="hidden" name="FolderId" value="" >
		<input type="hidden" name="ProcessInstanceId" value="" >
		<input type="hidden" name="WorkitemId" value="" >
		<input type="hidden" name="OrderBy" value="" >
		<input type="hidden" name="SortOrder" value="" >
		<input type="hidden" name="LastValue" value="" >
		<input type="hidden" name="FromInbox" value="" >
		<input type="hidden" name="addedAsAttachment" value="" >
		<input type="hidden" name="FromSentItems" value="" >
		<input type="hidden" name="AIDocIndex" value="" >
		<!--Added by Saurabh Rajput on 19/05/2022 for EG10-0028(Prev/Next after filter)-->
		<input type="hidden" name="FilterCheck" value="" >
		<input type="hidden" name="typeforaicte" value="" >
		<!-- changes by Saurabh ends here -->

		<input id="egovUID" type="hidden" name="egovID" value="<%=egovUID%>"></form>
 <!--Changes ended by Ojasvi for Session Hijacking (EG-0001)-->
 
 <!--Changes done  by ritu for Session Hijacking(EG-0001)-->
		<form name="DAKActivityview" method="post" action="">
		<input type="hidden" name="DocId" value="" >
		<input type="hidden" name="DepartmentFieldName" value="" >
		<input type="hidden" name="DepartmentName" value="" >
		<input type="hidden" name="DataclassName" value="" >
		<input type="hidden" name="GroupFolderId" value="" >
		<input type="hidden" name="GroupFolderVolumeIndex" value="" >
		<input type="hidden" name="OrderBy" value="" >
		<input type="hidden" name="SortOrder" value="" >
		<input type="hidden" name="LastSortField" value="" >
		<input type="hidden" name="PrevIndex" value="" >
		<input type="hidden" name="param1" value="" >
		<input type="hidden" name="countChk" value="" >
		<input type="hidden" name="workitem" value="" >
		<input type="hidden" name="CalledFrom" value="" >
		<input type="hidden" name="FromInbox" value="" >
		<input type="hidden" name="WorkitemId" value="" >
		<input type="hidden" name="ProcessInstanceId" value="" >
		<input type="hidden" name="InboxOrderBy" value="" >
		<input type="hidden" name="InboxSortOrder" value="" >
		<input type="hidden" name="InboxLastValue" value="" >
		<input type="hidden" name="FromSentItems" value="" >
		<!--Added by Saurabh Rajput on 19/05/2022 for EG10-0028(Prev/Next after filter)-->
		<input type="hidden" name="FilterCheck" value="" >
		<input type="hidden" name="typeforaicte" value="" >
		<!-- changes by Saurabh ends here -->
		<input type="hidden" name="param2" value="" >
		<input type="hidden" name="rid" value="" >
		<input id="egovUID" type="hidden" name="egovID" value="<%=egovUID%>"></form>
		
		<form name="RegisterNewDAK" method="post" action="">
		<input type="hidden" name="DocListFolderId" value="" >
		<input type="hidden" name="DocListFolderVolumeId" value="" >
		<input type="hidden" name="DAKDataclssName" value="" >
		<input type="hidden" name="DAKRegistrationFieldName" value="" >
		<input type="hidden" name="DAKRegistrationFieldPrefix" value="" >
		<input type="hidden" name="DAKDepartmentFieldName" value="" >
		<input type="hidden" name="ToWhomFieldName" value="" >
		<input type="hidden" name="DAKSectionFieldName" value="" >
		<input type="hidden" name="DataAlsoFlag" value="" >
		<input type="hidden" name="ReqFrom" value="" >
		<input id="egovUID" type="hidden" name="egovID" value="<%=egovUID%>"></form>
		<!--Changes ended by ritu for Session Hijacking (EG-0001)-->
 		
		<!--Changes done  by Nikita for Session Hijacking(EG-0001)-->
		<form name="changePasswordForm" method="post" action="">
		<input id="egovUID" type="hidden" name="egovID" value="<%=egovUID%>"></form>
		<!--Changes ended  by Nikita for Session Hijacking(EG-0001)-->
		<!--Added by Vaibhav on 20/01/2015 for calendar -->
		<!-- Custom Bootstrap Plugins js for eGov -->
		<script language="JavaScript" src="/<%=sessionBean.getIniValue("ContextName")%>/bootstrap/js/calnotif.js"></script>	
		<!--Changes ended by Vaibhav -->
			<!-- Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)-->
		</div>
		</div>
		  <div class="side-panel" id="sidePanel">
        <div class="side-panel-content" id="sidePanelContent"><ul style="width:149;">
</div>
    </div>
	<script>
//changes to add flatpickr starts here by rishav
	$( document ).ready(function() {
		
	setTimeout(function(){
	flatpickr("#fromdate,#todate,#todateUpdate,#fromdateUpdate", {
            enableTime: true,
			time_24hr: true,
			
            dateFormat: "Y/m/d H:i",
            defaultDate: new Date(),
			minDate:"today",
        });

}, 500);
  
    });
	//changes to add flatpickr end here
</script>
</body>

<script>

	function refreshTag()
	{ 
	  setInterval("renderRefresh()",<%=refreshVal%>);
	}
	function renderRefresh()
	{
		
		
	   if(document.getElementById("itemSelected").innerHTML==My_Desk)
	   {
			sLastSortField="";
			sFirstWorkItem="";
			sLastValue1="";			
			sFirstProcessInstance="";
			sLastWorkItem="";
			sLastValue2="";
			sLastProcessInstance="";
			sLastValue="";
			sOrderBy="5";
			sSortOrder="D";
			sRefSortOrder="D";		
			sRefOrderBy="5";
			renderdashboardComponent('<%=dashboardReport1Data%>','<%=dashboardReport2Data%>','<%=dashboardReport3Data%>','<%=rtiEnable%>','<%=pqEnable%>','<%=ccEnable%>','<%=commEnable%>');// Changed by Neha Kathuria on Aug 26,2016 for all egov modules Counting issue when any module is disable 
			getChartData();
	   }
	    
	}
// Changes by Saurabh Rajput for MRPL new UI(MRPL-0001)

function fetchReminder(){
				
				let timestamp = new Date().getTime();
	            $.ajax({
                url: '/'+contextNameGlobal+'/EGovServlet/notifications/getUserNotifications?timestamp='+ timestamp,
                method: 'POST',
                dataType: 'json',
                success: function(notifications) {
					// Added by Saurabh Rajput for notifications count display (11.6.01) on 16-01-2025
					document.getElementById("Notifcount").innerHTML="( " + notifications.length+ " )";
					if (notifications.length === 0) {
						const container = $('#reminder-list');
						container.empty();
					    const $div = $('<div></div>');
						let noData = "<div style='text-align:center;padding:30px'><img src='images/data.png' height='50px' width='50px'/><br><br><b>No new notifications !</b></div>";
						$div.html(noData);
						container.append($div);
						
					} else {
						const container = $('#reminder-list');
						container.empty();

                    notifications.forEach(notification => {
						displayNotif(notification.text);
                      
                    });
					}
                },
                error: function(jqXHR, textStatus, errorThrown) {
                    console.error('Error fetching notifications:', textStatus, errorThrown);
                }
            });
}
  //Added by Priyanshu Sharma for dismiss notification for mrpl EGOV-11.6.01
		function removeNotifTypeFromDB() {
			$.ajax({
				url: "/"+contextNameGlobal+"/EGovServlet/notifications/deleteNotificationType",
				type: "post",
				dataType:'json',
				data: {notifyType: "Inbox"},
				success: function(data) 
				{
					fetchReminder();
				},
				error: function(jqXHR, textStatus) 
				{
						fetchReminder();
				}
			});
			
			}
	

function removeNotificationFromDB(nid) {
			$.ajax({
				url: "/"+contextNameGlobal+"/EGovServlet/notifications/deleteUserNotifications",
				type: "post",
				dataType:'json',
				data: {id: nid},
				success: function(data) 
				{
						fetchReminder();
				},
				error: function(jqXHR, textStatus) 
				{
						fetchReminder();
				}
			});
			}

//End by Priyanshu Sharma for dismiss notification for mrpl EGOV-11.6.01
function displayNotif(text){
	const container = $('#reminder-list');
	let title = '';
	let textstr = '';
	let notificationId='';
	
	let itemType='';
	let assignedUser='';
	let actionDateTime='';
	let subject='';
	let actionPerformed='';
	let notifytype='';
	let actionPerformedStr='';
	//changes started for reminder by Rohit Verma
	let remarksStr='';
	//changes ended for reminder by Rohit Verma
	if (typeof text === 'object') {
	
		subject=decode_utf8(decode_utf8(text.text));
			
		if (text.title=='Calendar Notification')
		{
			text.title=cal_notif;
		}
		
		if (text.title=='Initiate')
		{
			text.title=Initiate;
			actionPerformedStr=actionPerformed1;
		}
		if (text.title=='Forward')
		{
			text.title=Forward;
			actionPerformedStr=actionPerformed2;
		}
		if (text.title=='Refer')
		{
			text.title=Refer;
			actionPerformedStr=actionPerformed3;
		}
		if (text.title=='Return')
		{
			text.title=Return;
			actionPerformedStr=actionPerformed4;
		}	
		if (text.title=='Closed')
		{
			actionPerformedStr=actionPerformed5;
		}
		if (text.title=='Receive')
		{
			text.title=DISPATCH;
			actionPerformedStr=actionPerformed6;
		}
		if (text.title=='Acknowledge')
		{
			text.title=DISPATCH;
			actionPerformedStr=actionPerformed7;
		}
		if (text.title=='update')
		{
			text.title=DISPATCH;
			actionPerformedStr=actionPerformed8;
		}
		if (text.title=='delete')
		{
			text.title=DISPATCH;
			actionPerformedStr=actionPerformed9;
		}
		if(text.title=='momCreated' || text.title=='MomCreated')
		{	
			text.title=MOM;
			actionPerformedStr=actionPerformed10;
		}
		if(text.title=='Accepted' || text.title=='accepted')
		{	
			text.title=meetingAccepted;
			actionPerformedStr=actionPerformed11;
		}
		if(text.title=='Rejected' || text.title=='rejected')
		{	
			text.title=meetingRejected;
			actionPerformedStr=actionPerformed12;
		}
		if (text.title=='Send for Clarification')
		{
			text.title=Clarification;
			actionPerformedStr=actionPerformed16;
		}
		if (text.title=='Sent for Revert')
		{
			text.title=Revert;
			actionPerformedStr=actionPerformed17;
		}
		if (text.title=='Reminder')
		{
			text.title=Reminder;
		}					
		if (text.notifytype=='Inbox')
			text.notifytype=Inbox;
		if (text.notifytype=='Pending')
			text.notifytype=Pending;
		if (text.notifytype=='Closed')
			text.notifytype=Closed;	
		
		title = '<b style="color:#1281dd;font-weight: bold;">' + text.title + '</b>';
		itemType=text.itemType;
		assignedUser=decode_utf8(text.assignedUser);
		actionDateTime=decode_utf8(text.actionDateTime);
		actionPerformed=text.title;
		remarksStr=decode_utf8(text.remarks);
		
		if(itemType=='DAK')
			itemType=Dak;
		if(itemType=='Note')
			itemType=Note;
		if(itemType=='File')
			itemType=FILE;
		if(itemType=='Dispatch')
			itemType=DISPATCH;
			
		if(assignedUser=='you')
			assignedUser==assignedUser1;
		if(itemType=='Dispatch'){
		textstr=itemType+" "+subject+actionPerformedStr;
		}
		else
		{		
			if (text.title=='Calendar Notification')
			{
				textstr=subject;
			}
			else if (text.title=='Reminder')
			{	
				title = '<b style="color:Red;font-weight: bold">' + text.title + '</b>';
				if(assignedUser=='you')
					assignedUser=msg3;
				let remarks1=" : \""+remarksStr +"\"";
				if(remarksStr!=""||remarksStr!=null||remarksStr!="undefined"){
					textstr=itemType+" "+subject+msg1+actionDateTime+msg2+assignedUser+msg4+remarks1;	
				}
				else{
					textstr=itemType+" "+subject+msg1+actionDateTime+msg2+assignedUser+msg4;
				}							
			}
			else
			{
				textstr=itemType+" "+subject+ notifStr1 +actionPerformedStr+" "+assignedUser+notifStr2+ actionDateTime;	
			}
		}					
		
	} else {
		textstr = decode_utf8(text);
	}
	
	let str = '';
	//Added by Priyanshu Sharma for dismiss notification for mrpl EGOV-11.6.01
		if (text.title=='Reminder'){
		str = '<div style="color:grey;font-weight: normal">' + title +" - " +textstr+'</div>';
		}
		else{
			str = '<div style="color:grey;font-weight: normal" >' + title +" - " +textstr +'-   <span style="font-size:14px;font-weight:bold;cursor:pointer;color:#1281dd"  onclick="removeNotificationFromDB('+text.notificationId+')">Dismiss</span></div>';
		}
		//End by Priyanshu Sharma for dismiss notification for mrpl EGOV-11.6.01
	 const $div = $('<div></div>');
	 $div.html(DOMPurify.sanitize(str));
	container.append($div);
	
}
	//refreshTag();
// Changes by Saurabh Rajput ends for MRPL new UI(MRPL-0001)
</script>
</html>