/***
Class       : DM_PmcPortalCtrl
Author      : Smaartt
Description : This class is accessed from LWC component to retrieve PMC user related information in portal.
TestClass   : DM_PmcPortalCtrlTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.        V1.0              14/02/2024           Initial Version 
****************************************************************************************************************/
public without sharing class DM_PmcPortalCtrl {   
    @AuraEnabled
    public static List<User> getPMCPortalUsers(){
        String profileNames = Label.DM_PortalUsers;
        return [Select Id, Name from User where Profile.Name IN :profileNames.split(',') and Id !=: UserInfo.getUserId() AND IsActive = TRUE];
    }
    @AuraEnabled
    public static List<User> getDMApproverUsers(){
        return [Select Id, Name from User where Username IN :Label.DM_1stLevelApprover.split(',') AND IsActive = TRUE ORDER BY Name DESC];
    }
    @AuraEnabled
    public static void updateCase(Case caseObj, String comment){
        
        string Notificationbody = caseObj.CaseNumber +' '+'is assigned for Approval';
        try{
            if(comment != null){     
                System.debug('Comment provided: ' + comment);         
                List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();        
                
                ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();          
                ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
                ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
                
                messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
                //Mention user here       
                ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();  
                mentionSegmentInput.id = caseObj.CreatedById;
                messageBodyInput.messageSegments.add(mentionSegmentInput);       
                
                textSegmentInput.text = '\n'+comment;
                messageBodyInput.messageSegments.add(textSegmentInput);
                
                feedItemInput.body = messageBodyInput;
                feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
                feedItemInput.subjectId = caseObj.Id;
                
                ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(feedItemInput);
                batchInputs.add(batchInput);        
                
                ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchInputs);
            }
            //additionalInfoReqCustomer SLA Update
            if(caseObj.Sub_Status__c == Label.DM_SubStatus_AddInfoReqCustomer){
                Id BUSINESS_HOURS_ID = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id;
                caseObj.Requestor_SLA_Date__c = AddDays(2, BUSINESS_HOURS_ID);
                caseObj.Requestor_SLA_Completion_Date__c =AddDays(7, BUSINESS_HOURS_ID);
            }
            
            update caseObj;
            System.debug('Case updated: ' + caseObj);
            
            if(caseObj.Sub_Status__c == Label.DM_DocAcceptedByPMC && caseObj.Assigned_To__c!= null){
                Approval.ProcessSubmitRequest req1 =  new Approval.ProcessSubmitRequest();
                req1.setComments('Submitting request for approval.');
                req1.setObjectId(caseObj.Id);
                req1.setSubmitterId(UserInfo.getUserId()); 
                req1.setProcessDefinitionNameOrId(Label.DM_CaseApprovalProcess); 
                req1.setSkipEntryCriteria(true);
                req1.setNextApproverIds(new List<Id>{caseObj.Assigned_To__c});
                
                Approval.ProcessResult result = Approval.process(req1);
                
                DM_UtilityController.sendBellNotification(new set<string>{caseObj.Assigned_To__c}, caseObj.Id , label.Dm_BellNotification_CaseTitle,Notificationbody);
            }  
            
        }
        catch (DmlException e) {	
            throw new AuraHandledException(e.getMessage());
        }           
    } 
    // Helper method to add business hours
    public static DateTime AddDays(Integer iDays, Id BUSINESS_HOURS_ID) {         
        Datetime now = Datetime.now();
        Integer offset = UserInfo.getTimezone().getOffset(now);
        Datetime local = now.addSeconds(offset/1000);
        Datetime businessEndDateTime = BusinessHours.add(BUSINESS_HOURS_ID, local, iDays * 9 * 60 * 60 * 1000L);
        return businessEndDateTime;
    }
    
    @auraEnabled
    public static list<Payment_Request__c> getPaymentRequests(List<String> caseId){
        system.debug('caseId '+caseId);
        return [SELECT Id,name,Amount__c,Case__r.CaseNumber,Payment_Type__c,Transaction_No__c,Transaction_Date__c,Status__c from Payment_Request__c where Case__c != null AND Case__c =: caseId]; 
    }
    
    @AuraEnabled(cacheable=false)
    public static List<CaseMilestone> getCaseMilestones(Id caseId) {
        String pmcMilestone = Label.DM_PMCMilestone; // PMC SLA
        return [SELECT Id, MilestoneType.Name, StartDate, TargetDate, IsCompleted,IsViolated, 
                TargetResponseInMins, TargetResponseInHrs,TimeRemainingInHrs, ElapsedTimeInHrs,BusinessHoursId
                FROM CaseMilestone
                WHERE CaseId = :caseId
                AND MilestoneType.Name =: pmcMilestone];
    }
    
    @auraEnabled
    public static Document__c updateAldarDocument(String caseId,String aldarDocName,String docType){
        try{
            Map<string,string> CaseRecTypeNames = DM_UtilityController.getCaseRecTypeName(new list<string>{caseId});            Document__c document = new Document__c();
            document.DocumentType__c = docType;
            document.Case__c = caseId; 
            document.RecordTypeId = Schema.getGlobalDescribe().get('Document__c').getDescribe().getRecordTypeInfosByDeveloperName().get(Label.DM_CustomerDocumentRecordType).getRecordTypeId();
            document.Other_Document_Name__c = aldarDocName;
            document.Case_Recordtype__c=CaseRecTypeNames.get(caseId);
            insert document;
            System.debug('Document inserted: ' + document);
            
            return document;
        }
        catch (DmlException e) {	
            throw new AuraHandledException(e.getMessage());
        }          
    }
    @auraEnabled
    public static void recallApproval(string recordId){
        ProcessInstanceWorkitem[] Pval = [SELECT Id FROM ProcessInstanceWorkItem WHERE ProcessInstance.TargetObjectId = :recordId AND ProcessInstance.Status = 'Pending']; 
        if(Pval.size() > 0){            
            Approval.ProcessWorkItemRequest Preq= new Approval.ProcessWorkItemRequest();
            Preq.setAction('Removed');
            Preq.setWorkItemId(Pval[0].Id);
            Approval.ProcessResult result = Approval.process(Preq);
            case ca = new case(Id=recordId);
            ca.Sub_Status__c = 'Work In Progress';
            update ca;
        }       
               
    }
    @AuraEnabled
    public static void updateDocument(Document__c doc){       
        update doc;
    }
}