/***
Class       : DMCustomCommentFeederController
Author      : Smaartt
Description : This class is accessed from LWC component to post comments in feed and to notify the assigned users.
TestClass   : DMCustomCommentFeederControllerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.        V1.0              20/02/2024           Initial Version 
****************************************************************************************************************/
public without sharing class DMCustomCommentFeederController {
    @AuraEnabled(cacheable=true)
    public static List<FeedItem> getFeedItemList(String parentId) {
        return [
            SELECT
            Id,
            Title,
            ParentId,
            Type,
            Body,
            TYPEOF CreatedBy WHEN User THEN Id END,
            TYPEOF CreatedBy WHEN User THEN Name END,
            TYPEOF CreatedBy WHEN User THEN SmallPhotoUrl END,
            CreatedDate
            FROM FeedItem
            WHERE  ParentId = :parentId 
            AND (Type = 'TextPost' OR Type = 'CreateRecordEvent')
            ORDER BY CreatedDate DESC
        ];
    }
    @AuraEnabled
    public static void createFeedForAldar(FeedItem feedItemRec, string userId){
        List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();        
        
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();          
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
        
        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        if(userId != null) {
            ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();  
            mentionSegmentInput.id = userId;
            messageBodyInput.messageSegments.add(mentionSegmentInput);       
        } 
        textSegmentInput.text = '\n'+feedItemRec.Body;
        messageBodyInput.messageSegments.add(textSegmentInput);
        
        feedItemInput.body = messageBodyInput;
        feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
        feedItemInput.subjectId =feedItemRec.ParentId;
        
        ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(feedItemInput);
        batchInputs.add(batchInput);        
        
        ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchinputs);
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        List<String>toAddress = new List<String>();
        List<String>ccAddress = new List<String>();
        Id currentUserId = UserInfo.getUserId();
        Set<id>userids = new Set<id>{userId,currentUserId};       
        Map<id,User>userMap = new Map<id,User>([SELECT Id,Name,Email FROM User WHERE Id =:userids]);
        String AssignedUser;
        String CurrentUser;
        
        if(userMap.Containskey(userId)){
            toAddress.add(userMap.get(userId).Email);
            AssignedUser = userMap.get(userId).Name;
        }
        if(userMap.Containskey(currentUserId)){
            ccAddress.add(userMap.get(currentUserId).Email);
            CurrentUser =userMap.get(currentUserId).Name;
        }
        
        String fromAddress = System.label.DM_OrgWideEmailAddress;
        Id orgWideAddressId = [SELECT Id FROM OrgWideEmailAddress WHERE Address=:fromAddress LIMIT 1].Id;
        EmailTemplate emailTemplate = [SELECT id,htmlValue from EmailTemplate WHERE DeveloperName =: Label.DM_chatterFeedNotificationTemp LIMIT 1];
        String htmlBody = emailTemplate.HtmlValue;
        
        //below replaces the UserName with current User Name
        htmlBody = htmlBody.replace('AssignedUser', AssignedUser);
        //below replaces the FirstName with current User First Name
        htmlBody = htmlBody.replace('CurrentUser',CurrentUser);
        htmlBody = htmlBody.replace('SFUrl',URL.getOrgDomainURL().toExternalForm()+'/'+feedItemRec.ParentId);
        
        String body = feedItemRec.Body;
        htmlBody = htmlBody.replace('feedMessage',body);
        
        List<Case>caseInfo = [select id,CaseNumber,RecordType.DeveloperName From Case where id=:feedItemRec.ParentId];
        
        Messaging.SingleEmailMessage mail =  Messaging.renderStoredEmailTemplate(emailTemplate.Id,null,caseInfo[0].id);        
        mail.setToAddresses(toAddress);
        mail.setCcAddresses(ccAddress);
        mail.setReplyTo(fromAddress);
        String subject = 'District Management - '+CurrentUser +''+' mentioned ' +''+ AssignedUser +' For Case '+''+caseInfo[0].CaseNumber;
        mail.setSubject(subject);
        mail.setSaveAsActivity(false);
        //  mail.setTemplateId(emailTemplate.Id);
        
        mail.setHtmlBody(htmlBody);
        mail.setOrgWideEmailAddressId(orgWideAddressId);
        emailList.add(mail);
        System.debug('emailList'+emailList);
        
        if(emailList.size()>0){
            Messaging.sendEmail(emailList);
        }
        
        
    }
    
    @AuraEnabled
    public static void createFeedItemRec(FeedItem feedItemRec, string userId, string requestorId){
        system.debug('feedItemRec '+feedItemRec);
        system.debug('userId '+ userId);
        system.debug('requestorId ' + requestorId);
        if (feedItemRec.ParentId != null && userId != userInfo.getUserId() && userId != null) {
            UserRecordAccess userRecordAccess = [SELECT RecordId, HasEditAccess, HasReadAccess FROM UserRecordAccess 
                                                 WHERE UserId = :userId AND RecordId = :feedItemRec.ParentId];
            
            if (!userRecordAccess.HasReadAccess) {
                try {
                    Case caseObj = new Case();
                    caseObj.Id = feedItemRec.ParentId;
                    caseObj.Sub_Owner__c = userId;
                    update caseObj;
                    
                    CaseShare caseShare = new CaseShare();
                    caseShare.CaseId = feedItemRec.ParentId;
                    caseShare.UserOrGroupId = userId;
                    caseShare.CaseAccessLevel = 'Edit'; // Adjust access level as needed
                    caseShare.RowCause = Schema.CaseShare.RowCause.Manual;
                    insert caseShare;
                    
                } catch (DmlException e) {
                    throw new AuraHandledException(+ e.getMessage());
                }
            }
        } 
        
        List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();        
        
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();          
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
        
        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        //Mention user here      
        if(userId != null) {
            ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();  
            mentionSegmentInput.id = userId;
            messageBodyInput.messageSegments.add(mentionSegmentInput);       
        } else if(requestorId != null) {
            ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();  
            mentionSegmentInput.id = requestorId;
            messageBodyInput.messageSegments.add(mentionSegmentInput);       
        } 
        
        textSegmentInput.text = '\n'+feedItemRec.Body;
        messageBodyInput.messageSegments.add(textSegmentInput);
        
        feedItemInput.body = messageBodyInput;
        feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
        feedItemInput.subjectId =feedItemRec.ParentId;
        
        ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(feedItemInput);
        batchInputs.add(batchInput);        
        
        ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchinputs);
        if(userId!=null && feedItemRec!=null ){
            sendEmail(userId,feedItemRec);
        } else if(requestorId!=null && feedItemRec!=null ){
            sendEmail(requestorId,feedItemRec);
        }
    }
    public static void sendEmail(String userId,FeedItem feedItemRec) {
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        List<String>toAddress = new List<String>();
        List<String>ccAddress = new List<String>();
        Id currentUserId = UserInfo.getUserId();
        Set<id>userids = new Set<id>();
        userids.add(userId);
        userids.add(currentUserId);
        Map<id,User>userMap = new Map<id,User>([SELECT Id,Name,Email FROM User WHERE Id =:userids]);
        String AssignedUser;
        String CurrentUser;
        
        if(userMap.Containskey(userId)){
            toAddress.add(userMap.get(userId).Email);
            AssignedUser = userMap.get(userId).Name;
        }
        if(userMap.Containskey(currentUserId)){
            ccAddress.add(userMap.get(currentUserId).Email);
            CurrentUser =userMap.get(currentUserId).Name;
        }
        
        String fromAddress = System.label.DM_OrgWideEmailAddress;
        Id orgWideAddressId = [SELECT Id FROM OrgWideEmailAddress WHERE Address=:fromAddress LIMIT 1].Id;
        EmailTemplate emailTemplate = [SELECT id,htmlValue from EmailTemplate WHERE DeveloperName =: Label.DM_PMCchat_EmailTemplate LIMIT 1];
        String htmlBody = emailTemplate.HtmlValue;
        
        //below replaces the UserName with current User Name
        htmlBody = htmlBody.replace('AssignedUser', AssignedUser);
        //below replaces the FirstName with current User First Name
        htmlBody = htmlBody.replace('CurrentUser',CurrentUser);
        htmlBody = htmlBody.replace('DM_PortalURL',Label.DM_PortalURL);
        String body = feedItemRec.Body;
        htmlBody = htmlBody.replace('feedMessage',body);
        
        List<Case>caseInfo = [select id,CaseNumber,RecordType.DeveloperName From Case where id=:feedItemRec.ParentId];
        
        Messaging.SingleEmailMessage mail =  Messaging.renderStoredEmailTemplate(emailTemplate.Id,null,caseInfo[0].id);
        
        mail.setToAddresses(toAddress);
        mail.setCcAddresses(ccAddress);
        mail.setReplyTo(fromAddress);
        String subject = CurrentUser +''+' mentioned ' +''+ AssignedUser +' For Case '+''+caseInfo[0].CaseNumber;
        mail.setSubject(subject);
        mail.setSaveAsActivity(false);
        //  mail.setTemplateId(emailTemplate.Id);
        
        mail.setHtmlBody(htmlBody);
        mail.setOrgWideEmailAddressId(orgWideAddressId);
        emailList.add(mail);
        System.debug('emailList'+emailList);
        
        if(emailList.size()>0){
            Messaging.sendEmail(emailList);
        }
    } 
    @AuraEnabled
    public static List<User> getAldarUsers(){
        String profileNames = Label.DM_InternalUser_Profiles;
        return [Select Id, Name from User where Profile.Name IN :profileNames.split(',') AND IsActive = TRUE];
    }
}