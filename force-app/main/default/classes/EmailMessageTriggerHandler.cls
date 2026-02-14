/**********************************************************************************************************************
* Name               : EmailMessageTriggerHandler                                                        
* Description        : This class contains all the helper methods for the EmailMessage Trigger
* Usage              : EmailMessageTrigger
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     21 May 2022      Initial Draft       
******************************************************************************************************************/
public with sharing class EmailMessageTriggerHandler extends TriggerHandler {
    public static Boolean forceException = false;
    
    
    /*
*********************************************************
@Method Name    : afterInsertMethod
@author         : 
@description    : Method to handle After Insert logic for case
@param          : newList, newMap
@return         : void
********************************************************
*/
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        processEmailMessages((List<EmailMessage>)newList);
    }
    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        if (Test.isRunningTest() && forceException) {
            throw new CustomException('Forced exception for testing catch block');
        }
        for(EmailMessage email : (List<EmailMessage>)newList){
            if(email.ToAddress == 'mdcm@asteco.com' && email.TextBody!=null ){
                if(email.TextBody.contains('Classification : Internal General Purpose')){
                    String delimiter = 'Classification : Internal General Purpose';
                    
                    // Find the position of the delimiter
                    Integer pos = email.TextBody.indexOf(delimiter);
                    
                    // Extract the part before the delimiter
                    String result;
                    
                    if(pos != -1) {
                        result = email.TextBody.substring(0, pos).trim();
                    } 
                    email.TextBody = result;
                }
                
            }
        }
    }
    /*
*********************************************************
@Method Name    : processEmailMessages
@author         : 
@description    : Method to filter email messages to update case source email
@param          : newList, newMap, oldList, oldMap
@return         : void
********************************************************
*/
    public void processEmailMessages(List<EmailMessage> emailMsgs) {        
        Set<Id> csIds = new Set<Id>();
        List<EmailMessage> validEmailMsgs = new List<EmailMessage>();
        User userDetail = Utilities.getLoggedInUserDetail();
        if (userDetail.ProfileName__c == Constants.CONTACT_CENTER_AGENT) {return;}       
        for (EmailMessage emailMsg : emailMsgs) {
            if (emailMsg.Incoming && emailMsg.ParentId != null) {
                validEmailMsgs.add(emailMsg);
                csIds.add(emailMsg.ParentId);
            }
        }
        if (!validEmailMsgs.isEmpty()) {
            updateCaseSourceEmail(validEmailMsgs, csIds);
        }
    }
    /*
*********************************************************
@Method Name    : updateCaseSourceEmail
@author         : 
@description    : Method to update case source email
@param          : newEmailMsgList, csIds
@return         : void
********************************************************
*/
    public static void updateCaseSourceEmail(List<EmailMessage> newEmailMsgList, Set<Id> csIds) {
        List<Case> caseListToUpdate = new List<Case>();
        Map<Id, Case> csMap = new Map<Id, Case>();
        if(!csIds.isEmpty()) {
            csMap = new Map<Id, Case>([SELECT Id, Source_Email__c FROM Case WHERE Id IN: csIds]);       
        } 
        for(EmailMessage emailMsg : newEmailMsgList) {
            Case cs = csMap.get(emailMsg.ParentId);
            if(cs != null && cs.Source_Email__c == null && emailMsg.ToAddress != null) {                
                String toAddressWithoutSpace = emailMsg.ToAddress.deleteWhitespace();
                String truncatedToAddress = toAddressWithoutSpace.length() > 100 ? toAddressWithoutSpace.substring(0, 100) : toAddressWithoutSpace;
                cs.Source_Email__c = truncatedToAddress;
                caseListToUpdate.add(cs);
            }
        }
        if(!caseListToUpdate.isEmpty()) {
            CaseTriggerHandlerNew.isSkipCaseTrigger = true;
            update caseListToUpdate;
            CaseTriggerHandlerNew.isSkipCaseTrigger = false;
        }
    }
    
    public override void beforeDeleteMethod(List<SObject> oldList, Map<Id, SObject> oldMap){
        //prevent deletion
        User tempLoggedInUser = Utilities.getLoggedInUserDetail();
        if(tempLoggedInUser.Profile.Name != Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR){
            for(EmailMessage tempTask : (list<EmailMessage>) oldList ){
                tempTask.addError(Utilities.getSystemMessages(Constants.INSUFFICIENT_ACCESS).Message__c);
            }
        }
    }
}