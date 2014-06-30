<%@page import="com.marcus.function.SNSManager"%>
<%@page import="com.marcus.function.RDSManager"%>
<%@page import="com.amazonaws.services.dynamodbv2.model.AttributeValue"%>
<%@page import="com.marcus.function.DynamoDBManager"%>
<%@page import="com.amazonaws.services.s3.model.GetObjectRequest"%>
<%@page import="java.util.*"%>
<%@page import="java.io.File"%>
<%@page import="com.marcus.function.S3Controller"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@page import="com.jspsmart.upload.*"%>
<%
	long maxSize = 1024 * 1024 * 1024;
	int uploadCount = 0;
	String videoName = "";

	boolean debugMode = true;

	if (!(debugMode)) {
		SmartUpload smartUpload = new SmartUpload();
		smartUpload.initialize(pageContext);
		smartUpload.setMaxFileSize(maxSize);
		smartUpload.upload();

		videoName = smartUpload.getRequest()
				.getParameter("video_title");
		String bucketName = "fromhomepage";
		if (!videoName.equals("")) {
			uploadCount = smartUpload.getFiles().getCount();

			System.out.println("Upload Count : " + uploadCount + "\n"
					+ "Video Name : " + videoName);

			String savedFilePath;

			savedFilePath = getClass().getResource("/").getPath()
					+ videoName;
			System.out.println("Saved file path : " + savedFilePath);

			com.jspsmart.upload.File uploadedFile = smartUpload
					.getFiles().getFile(0);
			// save physically in (secondary)File system, which can be accessed by java.io.File 
			uploadedFile.saveAs(savedFilePath,
					smartUpload.SAVE_PHYSICAL);
			// Access the file by the provided path 
			java.io.File savedFile = new File(savedFilePath);
			savedFile.deleteOnExit();

			// storing video to S3:
			S3Controller s3Controller = new S3Controller();
			s3Controller.uploadToS3(videoName, bucketName, savedFile);

			ArrayList<String> bucketList = new ArrayList<String>();
			bucketList = s3Controller.listBucketName();

			com.amazonaws.services.s3.model.S3Object object = s3Controller.s3Client
					.getObject(new GetObjectRequest(bucketName,
							videoName + "_key"));
			S3Controller.displayOnConsole(object.getObjectContent());

			// **delete a bucket including all obejcts inside
			//s3Controller.deleteAllObejctInBucket(bucketName);

			// **delete all bucket in S3
			//s3Controller.deleteAllBucketInS3();

		}

		// Storing info to DynamoDB:
		DynamoDBManager dynamoDBManager = new DynamoDBManager();
		String tableName = "videoInfo";

		dynamoDBManager.createTable(tableName);

		dynamoDBManager.saveAItemToDynamoDB(tableName, "bucketName",
				bucketName, "videoKey", videoName);

		// **delete all table in DynamoDB
		//dynamoDBManager.deleteAllTable();

	}

	// Implementing SNS:
	SNSManager snsManager = new SNSManager();
	String topic = "videoForum";
	String subscriberEmail = "kiddkevin01@gmail.com";
	String message = "Welcome to Awesome Video Forum!!";
	snsManager.deleteATopic("MyNewTopic");
	// only needed for first time creating topic
	//snsManager.createATopic(topic);
	// only needed for first time suscription
	//snsManager.subscribeToATopic(topic, subscriberEmail);
	snsManager.publishToATopic(topic, message);

	response.sendRedirect("videoHome.jsp?status=complete");
%>


<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=US-ASCII">
<title>Insert title here</title>
</head>
<body>

</body>
</html>