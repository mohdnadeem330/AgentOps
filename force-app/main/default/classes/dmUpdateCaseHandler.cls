/***
Class       : dmUpdateCaseHandler
Author      : Smaartt
Description : This class is accessed from LWC to update the case status in salesforce.
TestClass   : dmUpdateCaseHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.        V1.0               23/02/2024          Initial Version
****************************************************************************************************************/
 
public without sharing class dmUpdateCaseHandler {
    @AuraEnabled
    public static void updateCase(Case caseObj,string feedMsg,string userId,string approverAction,string nextApproverId,string caseNumber){
        Savepoint sp = Database.setSavepoint();
        system.debug('caseObj.CaseNumber = '+ caseObj.CaseNumber);
        system.debug('Next Approved Id='+nextApproverId);
        system.debug('Next Approver Action='+approverAction);
       string Notificationbody = caseNumber +' is assigned for Approval';
        try{
            Update caseObj;
            if(approverAction != null){

               
                List<ProcessInstanceWorkitem> workItems = [
                    SELECT Id, ProcessInstanceId
                    FROM ProcessInstanceWorkitem
                    WHERE ProcessInstance.TargetObjectId =:caseObj.Id
                ];
                 system.debug('workItems'+ workItems);
                List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
                 system.debug('requests'+ requests);
                for(ProcessInstanceWorkitem workItem : workItems){
                    Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                    req.setWorkitemId(workItem.Id);                  
                    req.setAction(approverAction);
                    req.setComments(caseObj.Rejected_Reason__c);
                    //req.setNextApproverIds(new List<Id>{nextApproverId});

                    if (nextApproverId != null && approverAction == 'Approve') {
                        req.setNextApproverIds(new List<Id>{nextApproverId});
                    }
                    requests.add(req);
                     system.debug('requests--- last '+ requests);
                   
                }
                Approval.ProcessResult[] processResults = Approval.process(requests);
                if(nextApproverId!=null){
                DM_UtilityController.sendBellNotification(new set<string>{caseObj.Assigned_To__c}, caseObj.Id , label.Dm_BellNotification_CaseTitle,Notificationbody);
                }
                else{
                  List<User> users = [SELECT Id FROM User WHERE Profile.Name = :Label.Dm_PaymentCtrlProfile ];
                    if(users.size()>0)
                    DM_UtilityController.sendBellNotification(new set<string>{users[0].id}, caseObj.Id , label.Dm_BellNotification_CaseTitle,Notificationbody);
                }
            }
           
            if(feedMsg != null && userId != null){
                List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();        
               
                ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();          
                ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
                ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
               
                messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
                //Mention user here    
                ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();  
                mentionSegmentInput.id = userId;
                messageBodyInput.messageSegments.add(mentionSegmentInput);  
               
                textSegmentInput.text = '\n'+feedMsg;
                messageBodyInput.messageSegments.add(textSegmentInput);
               
                feedItemInput.body = messageBodyInput;
                feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
                feedItemInput.subjectId =caseObj.Id;
               
                ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(feedItemInput);
                batchInputs.add(batchInput);        
                if (!Test.isRunningTest()) {
                    ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchinputs);
                }
            }
        }catch (DmlException e) {
            Database.rollback(sp);
            system.debug('Exception e'+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
       
    }
   
    @AuraEnabled(cacheable=true)
    public static List<Generic_Sub_Status_Config__mdt> getSubStatusDetails(String recId, String sObjectName) {
       
        case ca = [Select Id,Sub_Status__c from Case where Id=:recId];
        List<Map<String, String>> subStatusDetails = new List<Map<String, String>>();
        String currentUserId = UserInfo.getUserId();
        User currentUser = [SELECT Profile.Name FROM User WHERE Id = :currentUserId];
        String profileName = currentUser.Profile.Name;
       
        List<Generic_Sub_Status_Config__mdt> nextStatusValues = [SELECT NextApplicableStatus__c, Reject_Reasons__c FROM Generic_Sub_Status_Config__mdt WHERE MasterLabel = :ca.Sub_Status__c AND Sobject__c = :sObjectName AND User_Identifier__c LIKE :('%' + profileName + '%')];
        return nextStatusValues;
    }
    @AuraEnabled
    public static List<User> getDMApproverUsers(){
        return [Select Id, Name from User where Username IN :Label.DM_2ndLevelApproverProfile.split(',') and Id !=: UserInfo.getUserId() AND IsActive = TRUE];
    }
    @AuraEnabled
    public static List<User> getDMFinalApproverUserInfo(){
        return [Select Id, Name from User where Username IN :Label.Dm_PaymentCtrlProfile.split(',') AND IsActive = TRUE ORDER BY Name DESC];
    }
    @AuraEnabled
    public static Case getCaseInfo(String recordId){
        return [Select Id,CaseNumber,Skip_Next_Approver__c,Sub_Status__c,Status from Case Where Id=:recordId];
    }

    @AuraEnabled
    public static void postToChatter(String caseId, String userId, String feedMsg) {
        System.debug('--- postToChatter called ---');
        System.debug('caseId: ' + caseId);
        System.debug('userId: ' + userId);
        System.debug('feedMsg: ' + feedMsg);

        

        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();          
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();

        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

        ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();  
        mentionSegmentInput.id = userId;
        messageBodyInput.messageSegments.add(mentionSegmentInput);  

        ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
        textSegmentInput.text = '\n' + feedMsg;
        messageBodyInput.messageSegments.add(textSegmentInput);

        feedItemInput.body = messageBodyInput;
        feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
        feedItemInput.subjectId = caseId;
        if (!Test.isRunningTest()) {
            ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
        	System.debug('Chatter post created');
        }
    }
}