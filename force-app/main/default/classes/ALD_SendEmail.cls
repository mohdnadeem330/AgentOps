/**********************************************************************************************************************
* Name              : ALD_SendEmail                                                        
* Description       : Custom Invocable action to call from flow to send emails
* Method			: sendMailLikeEmailAlert()
* Test Class		: SendEmailFromFlowTest.testMethodAldSendEmail()
* Created By        : tdontha@aldar.com - Tharun    
* Last Modified By	: tdontha@aldar.com - Tharun
******************************************************************************************************************/
public class ALD_SendEmail
{
    @InvocableMethod(label='Send Email Custom Action' iconName='slds:standard:email')
    public static void sendMailLikeEmailAlert (List<FlowInputParamsWrapper> inputParameters) 
    {
        System.debug('inputParameters-----' + inputParameters);
        FlowInputParamsWrapper input 							= inputParameters[0];
        sendEmailApexMethod(input);
    }
    
    public static void sendEmailApexMethod(FlowInputParamsWrapper input)
    {
        List<String> toAddressesAll 							= new List<String>();
        List<Messaging.EmailFileAttachment> email_attachments 	= new List<Messaging.EmailFileAttachment>();
        EmailTemplate template 									= [SELECT Id
                                                                   FROM EmailTemplate 
                                                                   WHERE DeveloperName =: input.emailTemplateName];
        List<Attachment> attachments 							= [SELECT Id,
                                                                   Name,
                                                                   Body,
                                                                   ContentType
                                                                   FROM Attachment
                                                                   WHERE ParentId = :template.Id];
        for(Attachment att : attachments){
            Messaging.EmailFileAttachment email_att = new Messaging.EmailFileAttachment();
            email_att.setBody(att.Body);
            email_att.setContentType(att.ContentType);
            email_att.setFileName(att.Name);
            //email_att.setinline(false);
            email_attachments.add(email_att);
        }
        
        Messaging.AttachmentRetrievalOption attachRet 			= Messaging.AttachmentRetrievalOption.NONE;
        Messaging.SingleEmailMessage tempEmailInstance 			= Messaging.renderStoredEmailTemplate(template.Id, null, input.recordID, attachRet);
        tempEmailInstance.setFileAttachments(email_attachments);
            
        for(OrgWideEmailAddress orgwideaddress : [SELECT Id, Address 
                                                  FROM OrgWideEmailAddress 
                                                  WHERE Address =: input.fromEmailAddress])
        {
            tempEmailInstance.setOrgWideEmailAddressId(orgwideaddress.Id);
        }
        
        //recRelatedToEmailAddress = all the related to Contact/Lead/Contact Owner email addresses
        if(input.recRelatedToEmailAddress != null && String.isNotBlank(input.recRelatedToEmailAddress)){
            System.debug('recRelatedToEmailAddress---'+input.recRelatedToEmailAddress);
            List<String> toAddresses = input.recRelatedToEmailAddress.split(',');
            toAddressesAll.addAll(toAddresses);
        }
        
        // toAddressesAll = all static email addressess
        if(input.recToEmailAddress != null && String.isNotBlank(input.recToEmailAddress)){
            System.debug('recToEmailAddress---'+input.recToEmailAddress);
            List<String> toAddresses = input.recToEmailAddress.split(',');
            toAddressesAll.addAll(toAddresses);
        }
        
        // toAddressesAll = created by user email address
        if(input.recRecCreatorId != null){
            System.debug('recRecCreatorId----'+input.recRecCreatorId);
            for (User userRec: [SELECT Id, Email, isActive
                                FROM User 
                                WHERE isActive = true AND Email != null AND Id =: input.recRecCreatorId])
            {
                toAddressesAll.add(userRec.Email);
            }
        }
        
        // toAddressesAll = query the sobjects passed email fields
        if(input.recEmailFields != null && input.objectName != null)
        {
            System.debug('objectName+++++++'+input.objectName);
            System.debug('objectFieldName+++++++'+input.recEmailFields);
            
            String queryStr					= '';
            String sObjApiName 				= input.objectName;
            String sObjcommaSepratedFields 	= input.recEmailFields;
            String sObjrecordId				= input.recordID;
            queryStr						= 'SELECT Id, '+sObjcommaSepratedFields+' FROM '+sObjApiName+' WHERE Id = :sObjrecordId Limit 1';
            System.debug('queryStr===='+queryStr);
            
            sObject sobjRecord 							= Database.query(queryStr);
            List<String> sObjcommaSepratedFieldsList 	= sObjcommaSepratedFields.replace(' ','').split(',');
            Map<String, Schema.SObjectType> schemaMap 	= Schema.getGlobalDescribe();
            Map<String, Schema.SObjectField> fieldMap 	= schemaMap.get(sObjApiName).getDescribe().fields.getMap();
            
            for(Schema.SObjectField fieldAPIName : fieldMap.values()){
                List<String> emailAddresses = new List<String>();
                if(sObjcommaSepratedFieldsList.contains(String.valueOf(fieldAPIName))){
                    if(sobjRecord.get(fieldAPIName) != null){
                        emailAddresses.add(String.valueOf(sobjRecord.get(fieldAPIName)));
                    }
                }
                toAddressesAll.addAll(emailAddresses);
            }
        }
        
        // toAddressesAll = gets Records Owner Id
        if(input.recOwnerId != null){
            System.debug('Record OwnerId+++++++'+input.recOwnerId);
            User userRecord = [SELECT Id, Email, isActive
                               FROM User 
                               WHERE isActive = true
                               AND Email != null 
                               AND Id =: input.recOwnerId LIMIT 1];
            if(userRecord != null){
                toAddressesAll.add(userRecord.Email);
            }
        }
        
        // toAddressesAll = gets Records Account Owner Id
        if(input.recAccountOwnerId != null){
            System.debug('Record Accounts OwnerId------'+input.recAccountOwnerId);
            User accUserRecord = [SELECT Id, Email, isActive
                                  FROM User 
                                  WHERE isActive = true
                                  AND Email != null 
                                  AND Id =: input.recAccountOwnerId LIMIT 1];
            if(accUserRecord != null){
                toAddressesAll.add(accUserRecord.Email);
            }
        }
        
        // toAddressesAll = get all user ids sent from flow
        if(input.recUserId != null){
            System.debug('Users Ids$$$$$$$$$'+input.recUserId);
            List<String> emailAddresses 	= new List<String>();
            List<String> userIdsList 		= input.recUserId.replace(' ','').split(',');
            List<User> userRecords 			= [SELECT Id, Email, isActive
                                               FROM User 
                                               WHERE isActive = true 
                                               AND Email != null 
                                               AND Id IN :userIdsList];
            for(User userSingle : userRecords){
                emailAddresses.add(userSingle.Email);
            }
            toAddressesAll.addAll(emailAddresses);
        }
        
        
        if(input.ccEmailAddress != null)
        {
            List<String> ccAddresses = input.ccEmailAddress.split(',');
            tempEmailInstance.setCcAddresses(ccAddresses);
        }
        
        if(input.bccEmailAddress != null)
        {
            List<String> bccAddresses = input.bccEmailAddress.split(',');
            tempEmailInstance.setBccAddresses(bccAddresses);
        }
        
        System.debug('toAddressesAll****'+toAddressesAll);
        System.debug('&&&getEntityAttachments---'+tempEmailInstance.getEntityAttachments());
        System.debug('&&&getFileAttachments---'+tempEmailInstance.getFileAttachments());
        
        tempEmailInstance.setToAddresses(toAddressesAll);
        tempEmailInstance.setSaveAsActivity(input.saveAsActivity);
        
        try{
            if(toAddressesAll.size() > 0){
                List<Messaging.SendEmailResult> results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{tempEmailInstance});
                System.debug('results for successful email sent--->>>' + results);
            }
        } catch(Exception ex) {
            System.debug('exception in ALD_SendEmail-------->>>' + ex);
            LoggerService.save(LoggerService.createApexLog(ex,'Email Exception','ALD_SendEmail-'+input.recordID,'sendEmailApexMethod'));
        }
    }
    
    
    public class FlowInputParamsWrapper
    {
        @InvocableVariable(label='Email Template API Name'	required=true	description='Enter Developer Name of EmailTemplate')
        public String emailTemplateName;
        
        @InvocableVariable(label='Object API Name' 			required=true	description='Merge Fields Object Name')
        public String objectName;
        
        @InvocableVariable(label='Record ID' 				required=true	description='Record Id of triggering record')
        public String recordID;
        
        @InvocableVariable(label='From Email Address' 		required=true	description='Enter orgwide email address')
        public String fromEmailAddress;
        
        @InvocableVariable(label='Recipients To Additional Email Addresses' description='Email addressess in comma separated')
        public String recToEmailAddress = null;
        
        @InvocableVariable(label='Recipients Record Related To Email Addresses' description='Related Contact/Lead/Contact Owner Email addresses')
        public String recRelatedToEmailAddress = null;
        
        @InvocableVariable(label='Recipients Record Creator ID'				description='Enter {!$Record.CreatedById}')
        public String recRecCreatorId;
        
        @InvocableVariable(label='Recipients Record Email Fields')
        public String recEmailFields;
        
        @InvocableVariable(label='Recipients Record Owner ID')
        public String recOwnerId;
        
        @InvocableVariable(label='Recipients Record Account Owner ID'	description='Enter records customer owner Id')
        public String recAccountOwnerId;
        
        @InvocableVariable(label='Recipients User IDs'				description='Enter specific user Ids comma separated')
        public String recUserId;
        
        @InvocableVariable(label='CC Email Address'					description='Enter Email addresses to add in cc')
        public String ccEmailAddress  = null;
        
        @Invocablevariable(label='BCC Email Address'				description='Enter Email addresses to add in bcc')
        public String bccEmailAddress = null;
        
        @Invocablevariable(label='Set ReplyTo Email Address')
        public String replyToEmailAddress = null;
        
        @InvocableVariable(label='Save As Activity'					description='Global constants true for saving as activity')
        public Boolean saveAsActivity = false;
    }
    
}