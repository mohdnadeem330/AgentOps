/*
*********************************************************
Apex Class Name    : CaseTriggerService
Created Date       : 
@description       : Class to handle case Trigger Case-specific business logic
@author            : 
Modification Log:
Ver   Date         Author                Modification
1.0   27-06-2025                         Initial Version
*********************************************************
*/
public without sharing class CaseTriggerService {
    //Global variable declaration Start
    public static CaseTriggerMetadata.CaseRecordTypeWrapper rtWrapper = CaseTriggerMetadata.getRTypeInstance(CaseTriggerHelper.recordTypeByNames);
    public static CaseTriggerMetadata.QueueWrapper queueWrapper = CaseTriggerMetadata.getqueueWrInstance(CaseTriggerHelper.getQueueMap());
    //Global variable declaration End    
    /*
    *********************************************************
    @Method Name    : beforeInsertCaseFieldMapping
    @author         : 
    @description    : Method to populate fields irrespective of Record Type 
    @param          : newCaseList,oldMap
    @return         : void
    ********************************************************
    */
    public static void beforeInsertCaseFieldMapping(List<Case> newCaseList) {
        for(Case caseRecord : newCaseList){ 
            if(caseRecord.Priority =='P3'  && caseRecord.Origin =='Email' && caseRecord.Recordtype_Name__c =='ECSS_Email_to_Case' && caseRecord.Description!=null){
                if(caseRecord.Description.contains('Classification : Internal General Purpose')){
                    String delimiter = 'Classification : Internal General Purpose';
                    // Find the position of the delimiter
                    Integer pos = caseRecord.Description.indexOf(delimiter);
                    // Extract the part before the delimiter
                    String result;
                    if(pos != -1) {
                        result = caseRecord.Description.substring(0, pos).trim();
                    } else {
                        // If delimiter not found, store whole string or handle accordingly
                        result = caseRecord.Description;
                    }
                    caseRecord.Description = result;
                }                                   
            }
        }
    }            
    /*
    *********************************************************
    @Method Name    : beforeUpdateEntitlementAndOwnerIdMapping
    @author         : 
    @description    : Method to populate Entitlement and OwnerId
    @param          : newCaseList,oldMap
    @return         : void
    ********************************************************
    */
    public static void beforeUpdateEntitlementAndOwnerIdMapping(List<Case> newCaseList,Map<Id,Case> oldMap) {
        User loggedInUser = CaseTriggerHelper.getCurrentUserDetails(); 
        for(Case caseRecord : newCaseList) {
            Case oldCase = oldMap.get(caseRecord.Id);
            String recordTypeName = caseRecord.recordTypeId != null ? Utilities.getRecordTypeName('Case', caseRecord.recordTypeId) : '';
            if ((recordTypeName == Constants.FEEDBACK_CASE_RT || recordTypeName == Constants.DLP_CASE_RT || recordTypeName ==System.Label.AMCRecTypeLabel || recordTypeName == Constants.STANDARD_CASE_RT || recordTypeName == Constants.HOME_FINANCE_CASE_RT) && caseRecord.CaseCategory__c != oldCase.CaseCategory__c){
                if((caseRecord.SubVertical__c != Constants.DLP_SUB_VERTICAL || caseRecord.SubVertical__c != Constants.DLP_CONTRACTOR_SUB_VERTICAL) && recordTypeName !=System.Label.AMCRecTypeLabel){
                    caseRecord.EntitlementId = System.Label.DefaultEntitlementId;
                } else if(recordTypeName ==System.Label.AMCRecTypeLabel && (caseRecord.SubCategory__c == 'PPM Visit' || caseRecord.SubCategory__c == 'PMA Visit')) {
                    caseRecord.EntitlementId = System.Label.AMCEntitlementId ;  
                } else if(recordTypeName ==System.Label.AMCRecTypeLabel && caseRecord.CaseCategory__c  == System.Label.ODCaseCategoty){ 
                    caseRecord.EntitlementId = System.Label.AMC_OD_Entitlement_Id ; 
                } else if(caseRecord.SubVertical__c == Constants.DLP_SUB_VERTICAL){ 
                    caseRecord.EntitlementId = System.Label.DLPEntitlementId;
                }                
                if(caseRecord.CaseCategory__c == Constants.QUALTRICS_SURVEY_CATEGORY && caseRecord.Origin == Constants.SURVEY_CASE_ORIGIN){
                    caseRecord.OwnerId = queueWrapper.surveyQueue.Id;
                } else if((caseRecord.SubVertical__c == Constants.DLP_SUB_VERTICAL || caseRecord.SubVertical__c == Constants.DLP_CONTRACTOR_SUB_VERTICAL ) && (recordTypeName == Constants.STANDARD_CASE_RT || (recordTypeName == Constants.DLP_CASE_RT && caseRecord.Status == Constants.CASE_NEW) ) && caseRecord.Origin != Constants.CASE_ORIGIN_CUSTOMER_PORTAL && caseRecord.Origin != Constants.CASE_ORIGIN_CUSTOMER_APP){
                    caseRecord.OwnerId = queueWrapper.dlpQueue.Id;
                }
            }            
        }
    }    
    /*
    *********************************************************
    @Method Name    : callCAFMCase
    @author         : 
    @description    : Method to populate AMDEmail
    @param          : newCaseList
    @return         : void
    ********************************************************
    */
    public static void callCAFMCase(List<Case> newCaseList) {  
        List<Id> cafmCaseIdList = new List<Id>();     
        for(Case caseRecord : newCaseList) {
            if (caseRecord.RecordtypeId == rtWrapper.cafmRecordTypeId) {
                cafmCaseIdList.add(caseRecord.Id);
            }     
        } 
        if(!cafmCaseIdList.isEmpty()) {
            CAFMCalloutToMuleSoft.callCAFMCaseCreationQueue(cafmCaseIdList); 
        }                 
    }    
    /*
    *********************************************************
    @Method Name    : validateQualtricsCaseEligibility
    @author         : 
    @description    : Method to check if case is eligible to be sent to qualtrics
    @param          : newCaseList, oldMap
    @return         : void
    ********************************************************
    */
    public static Set<ID> validateQualtricsCaseEligibility(List<SObject> newCaseList, Map<Id,SObject> oldMap) {        
        //Skip Invalid Record Types Skip Legal Case Skip Survey Case
        Set<ID> qualtircsIDsToProcess = new Set<ID>();
        Set<ID> recordTypeToPorcess = new Set<ID>{
            rtWrapper.feedbackRTypeID,
            rtWrapper.standardRTypeID,
            rtWrapper.dlpRTypeID,
            rtWrapper.homeFinanceRTId,
            rtWrapper.amcRTypeID,
            rtWrapper.queriesRTypeID,
            rtWrapper.complaintsRTypeID,
            rtWrapper.requestsRTypeID
        };
        Map<Id,Id> caseToAccountId = new Map<Id,Id>();
        for(Case tempCaseRecord : (List<Case>)newCaseList){
            //Ticket ASF-516
            Case oldCase=(Case)oldMap.get(tempCaseRecord.Id);
            if(tempCaseRecord.status=='Closed' 
                && !tempCaseRecord.Survey_Required__c  
                && tempCaseRecord.status != oldCase.status
                && tempCaseRecord.Qualtrics_Survey_Required__c
                && tempCaseRecord.Origin != Constants.ORIGIN_SURVEY
                && tempCaseRecord.Vertical__c != Constants.LEGAL_VERTICAL
                && recordTypeToPorcess.Contains(tempCaseRecord.RecordTypeID)
                && tempCaseRecord.DLP_Closure_Reason__c !=Constants.DLP_CLOSURE_REASON_NOT_UNDER_DLP
                && tempCaseRecord.DLP_Closure_Reason__c !=Constants.DLP_CLOSURE_REASON_COMMON_AREA_DLP
                && tempCaseRecord.DLP_Closure_Reason__c !=Constants.DLP_CLOSURE_REASON_CUSTOMER_NOT_AVAILABLE
                && tempCaseRecord.AMC_Closure_Reason__c !=Constants.DLP_CLOSURE_REASON_CUSTOMER_NOT_AVAILABLE
                && tempCaseRecord.AMC_Closure_Reason__c != 'Customer Cancellation Request'
              ){              
                caseToAccountId.put(tempCaseRecord.Id,tempCaseRecord.AccountId);               
            }
        }
        //Exclude the property tansfer SR Case //Try to get Property Transfer SR        
        Set<ID> caseIdsPropTrans = new Set<ID>();
        if(!caseToAccountId.isEmpty()) {
            for(HexaBPM__Service_Request__c tempS : [select id,Case__c from HexaBPM__Service_Request__c where Case__c in :caseToAccountId.keySet() and HexaBPM__Record_Type_Name__c in (:Constants.PROPERTY_TRANSFER_DEV_RT, :Constants.PLOT_PROPERTY_TRANSFER_DEV_RT ,  :Constants.PROPERTY_TRANSFER_NOC_DEV_RT) ]){
                caseToAccountId.remove(tempS.Case__c);
            }
        }
        //Validate the DLP Case close Date
        Set<Id> accountIdsToSkip = new Set<Id>();
        if(!caseToAccountId.isEmpty()) {
            for(Case tempClosedDLP : [select id,AccountID from Case where AccountID in :caseToAccountId.values() and isCLosed=true and ClosedDate = LAST_N_DAYS:5 and (Vertical__c = :Constants.DLP_SUB_VERTICAL OR  Vertical__c = :Constants.DLP_VERTICAL)  and  id not in :caseToAccountId.keySet() and Survey_Point__c = 'DLP Closed']) {
                accountIdsToSkip.add(tempClosedDLP.AccountID);
            }
            for(ID tempRecID : caseToAccountId.keySet() ){
                if( !accountIdsToSkip.contains(caseToAccountId.get(tempRecID))){
                    qualtircsIDsToProcess.add(tempRecID);
                }
            }
        }        
        return qualtircsIDsToProcess;
    }
    /*
    *********************************************************
    @Method Name    : updateSurveyPoint
    @author         : 
    @description    : Method to update the Survey_Point__c on Case
    @param          : newCaseList, oldMap
    @return         : void
    ********************************************************
    */
    public static void updateSurveyPoint(List<Case> newCaseList,Map<Id,Case> oldMap){ 
        Set<Id> qualtricsEligibleIds=validateQualtricsCaseEligibility(newCaseList, oldMap);
        for(Case caseRecord : newCaseList) {
            if(!qualtricsEligibleIds.isEmpty() && qualtricsEligibleIds.contains(caseRecord.Id)){
                caseRecord.Survey_Required__c=true;
                if(caseRecord.Vertical__c == Constants.DLP_SUB_VERTICAL && caseRecord.SubVertical__c == 'AMC' && caseRecord.AMC_Closure_Reason__c ==System.Label.AMCClosureForComleted) {//V2.1 change Start
                    caseRecord.Survey_Point__c=System.Label.Case_AMC;//V2.1 Ends here
                }else if(caseRecord.Vertical__c == Constants.DLP_VERTICAL && (caseRecord.SubVertical__c == Constants.DLP_SUB_VERTICAL || caseRecord.SubVertical__c =='New Sale'|| caseRecord.SubVertical__c == Constants.DLP_CONTRACTOR_SUB_VERTICAL )){
                    caseRecord.Survey_Point__c=System.Label.Case_DLP_Closed;   
                }else if(caseRecord.SubVertical__c ==System.Label.Case_Home_finance &&  caseRecord.Sub_Status__c==System.Label.Case_Sub_status_loan){
                    caseRecord.Survey_Point__c=System.Label.Case_Home_finance_closed;
                }else if(caseRecord.SubVertical__c ==System.Label.Case_Subvertical_Onboarding) {
                    caseRecord.Survey_Point__c='Customer Onboarding Closed';
                }
                else if(caseRecord.SubVertical__c !=System.Label.Case_Home_finance && caseRecord.SubVertical__c !='Customer Onboarding'&& caseRecord.SubVertical__c !='New Sale') {
                    caseRecord.Survey_Point__c=Constants.CLOSED_CASE;
                }
            }
        }        
    }        
    /*
    *********************************************************
    @Method Name    : afterUpdateTaskCreationForCase
    @author         : 
    @description    : Method to create the task for case
    @param          : newList,oldCaseMap
    @return         : void
    ********************************************************
    */
    public static void afterUpdateTaskCreationForCase(List<Case> newList,Map<Id,Case> oldCaseMap){
        List<task> tasksToInsert = new List<task>();
        for(case newCase : newList){
            Case oldCase = oldCaseMap.get(newCase.Id);
            if( newCase.SubVertical__c == system.label.Case_Subvertical_Onboarding && ((String.valueOf(oldCase.OwnerId).startsWith('00G') && String.valueOf(newCase.OwnerId).startsWith('005')) || (String.valueOf(newCase.OwnerId).startsWith('005') && newCase.Status == Constants.CASE_WORK_IN_PROGRESS )) ){
               Task newTask = new Task(); 
               newTask.Subject = 'Call'; 
               newTask.OwnerId = newCase.OwnerId; 
               newTask.WhatId = newCase.Id;
               newTask.Task_Name__c = 'Call Attempt 1';
               tasksToInsert.add(newTask);
            }
        }
        if(!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }    
    /*
    *********************************************************
    @Method Name    : afterUpdateSendServiceReport
    @author         : 
    @description    : MFinal Email to customer with SERVICE report 
    @param          : newCaseList,oldCaseMap
    @return         : void
    ********************************************************
    */
    public static void afterUpdateSendServiceReport(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        List<Case> dlpClosedCases = new List<Case>();
        for(Case newCase : newCaseList) {
            Case oldCase = oldCaseMap.get(newCase.Id);
            String recordTypeName = Utilities.getRecordTypeName('Case', newCase.recordTypeId);
            if(((recordTypeName == Constants.DLP_CASE_RT || recordTypeName == System.Label.AMCRecTypeLabel) && newCase.status == Constants.CLOSED_CASE ) || ( recordTypeName == System.Label.AMCRecTypeLabel && newCase.Customer_Response__c != null && newCase.Customer_Response__c != oldCase.Customer_Response__c)) {
                dlpClosedCases.add(newCase);               
            }
        }
        if(!dlpClosedCases.isEmpty()) {
            sendServiceReport(dlpClosedCases);
        }
    }
    /*
    *********************************************************
    @Method Name    : sendServiceReport
    @author         : 
    @description    : MFinal Email to customer with SERVICE report 
    @param          : newCaseList
    @return         : void
    ********************************************************
    */
    public static void sendServiceReport(List<Case> newCaseList) {        
        try{   
            //v2.1 START  here
            Map<String, String> amcTemplates = new Map<String, String>{
                System.Label.AMCClosureForComleted => 'PPM_Service_Complete_Confirmation',
                System.Label.AMCClosureCustNA => 'PPM_schedule_with_no_access',
                System.Label.First_Call =>'No_response_to_the_call',
                System.Label.Last_Call =>'No_response_to_the_call_Last_Trial'
            };//v2.1 END  here 
            //Start V2.2       
            Map<String, String> amcODTemplates = new Map<String, String>{
                System.Label.AMCClosureForComleted => 'AMC_OD_Service_Complete_Confirmation',
                System.Label.AMCClosureCustNA => 'AMC_OD_schedule_with_no_access'
            };
            Map<Id,Case> newCaseMap = new Map<Id,Case>(newCaseList);
            string emailtemplateId;
            List<String> lstDLPMembers = new List<String>();             
            Set<String> templateDevNames = new Set<String>(); 
            Map<String, Id> templateMap = new Map<String, Id>();
            Map<id,ServiceAppointment> mapSAandCase = new Map<id,ServiceAppointment>();

            //V2.2 End        
            for(ServiceAppointment saRecord : [select Id,Case__c, (Select Id, ContentVersionDocumentId From ServiceReports ORDER BY LastModifiedDate desc Limit 1 ) from ServiceAppointment where Case__c in:newCaseMap.keySet()  and Status ='Closed' and (Record_Type_Name__c='Assessment' OR Record_Type_Name__c='AMC')  ORDER BY LastModifiedDate desc] ){ //2.1 change here
                if(!mapSAandCase.containskey(saRecord.Case__c)){ 
                    mapSAandCase.put(saRecord.Case__c,saRecord); 
                }
            }   
            for(case caseId :newCaseList) {
                if(caseId.Recordtype_Name__c==System.Label.AMCRecTypeLabel || test.isRunningTest()){//v2.1 START                     
                    String templateDevName ='';
                    if(caseId.Status == 'Closed'  || test.isRunningTest()){  
                        templateDevNames.add((caseId.CaseCategory__c == System.Label.ODCaseCategoty ? amcODTemplates.get(caseId.AMC_Closure_Reason__c) : amcTemplates.get(caseId.AMC_Closure_Reason__c)));    
                        lstDLPMembers = getEmailsFromPublicGroup(System.Label.DLPManagerGroupName);                                             
                    } else if (caseId.Customer_Response__c != null){                         
                        templateDevNames.add(amcTemplates.get(caseId.Customer_Response__c));  
                    }                    
                }
            }
            for (EmailTemplate et : [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName IN :templateDevNames]) {
                templateMap.put(et.DeveloperName, et.Id);
            }     
            List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();    
            for(case caseId :newCaseList){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                ServiceAppointment saRec = mapSAandCase.get(caseId.Id);
                if(saRec != null && saRec.ServiceReports.size() > 0 ){
                    List<ID> docid=new List<ID>(); 
                    docid.add(saRec.ServiceReports[0].ContentVersionDocumentId);
                    mail.setEntityAttachments(docid);
                }
                if(caseId.ContactId != null){ 
                    mail.setTargetObjectId(caseId.ContactId);
                } else { 
                    mail.setTargetObjectId(caseId.AccountId);   
                } 
                if(lstDLPMembers.size() > 0) {
                    mail.setCCAddresses(lstDLPMembers);
                }                                                     
                if(caseId.Recordtype_Name__c==Constants.DLP_CASE_RT){  //v2.1
                    if(caseId.DLP_Closure_Reason__c == System.Label.DLPFinalReportStatus) {
                        emailtemplateId = System.Label.DLPCompletedEmailtemplate;
                    } else if(caseId.DLP_Closure_Reason__c == System.Label.DLP_customernotavailable) {
                        emailtemplateId = System.Label.DLP_CustNotAvailEmailTemplate;
                    } else {
                        emailtemplateId = System.Label.DLPOutofscopeEmailtemplate;
                    }
                }
                //v2.1 change start here
                if(caseId.Recordtype_Name__c==System.Label.AMCRecTypeLabel || test.isRunningTest()){//v2.1 START                    
                    String templateDevName ='';
                    if(caseId.Status == 'Closed'  || test.isRunningTest()){  
                        templateDevName = (caseId.CaseCategory__c == System.Label.ODCaseCategoty ? amcODTemplates.get(caseId.AMC_Closure_Reason__c) : amcTemplates.get(caseId.AMC_Closure_Reason__c));                                                   
                    } else if(caseId.Customer_Response__c != null){ 
                        templateDevName = amcTemplates.get(caseId.Customer_Response__c);  
                    }
                    if (templateDevName != null) {  
                        emailtemplateId = templateMap.get(templateDevName); 
                    }
                 }
                 //v2.1 END
                mail.setTemplateId(emailtemplateId); 
                string toEmail = '';            
                if(caseId.CustomerType__c == 'Owner'){ 
                    toEmail = caseId.ContactEmail ; 
                } else {  
                    toEmail = caseId.Contact.Email;   
                }                
                if(toEmail != '' && toEmail != null){
                    String[] toaddresses = new String[] {toEmail};  
                    mail.setToAddresses(toAddresses);                   
                    if(saRec != null){mail.setWhatId(saRec.Id);} 
                    mail.setOrgWideEmailAddressId(System.Label.DLPOrgWideCustomerCareId);
                    mail.setBccSender(false); 
                    mail.setUseSignature(false); 
                    mail.setSaveAsActivity(true); 
                    emailsToSend.add(mail);
                }
            }
            if (!emailsToSend.isEmpty()) {
                Messaging.sendEmail(emailsToSend);
            }
        }catch(exception e){ LoggerService.save(LoggerService.addApexLog(e,'BookingSystemIntegration','BookingSystemIntegration',''));}
    }
    /*
    *********************************************************
    @Method Name    : getEmailsFromPublicGroup
    @author         : 
    @description    : Method to get emails from public group
    @param          : groupName
    @return         : void
    ********************************************************
    */
    public static List<String> getEmailsFromPublicGroup(String groupName) {
        List<String> emails = new List<String>();
        // One SOQL: pull active users whose Ids appear as members of the named group
        if(groupName != '' && groupName != null) {
            for (User u : [SELECT Email 
                            FROM User 
                            WHERE IsActive = true 
                            AND Email != null 
                            AND Id IN (SELECT UserOrGroupId FROM GroupMember WHERE Group.Name = :groupName)]) {
                emails.add(u.Email);
            }
        }
        if(test.isRunningTest()) {
            emails.add('test@gmail.com');
        }
        return emails;
    }    
}