/**********************************************************************************************************************
* Name               : ConfirmACDController                                                        
* Description        : Class used as controller for ConfirmACD LWC
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     06/09/2022      Initial Draft       
******************************************************************************************************************/
public class ConfirmACDController{
   @auraEnabled
   public static void updateMilestoneDetails(string recordID, Date proposedDate){
       BuildingSection__c tempRec = [select id, AnticipatedCompletionDate__c, OriginalAnticipatedCompletionDate__c from BuildingSection__c where id = :recordID limit 1];
       tempRec.ProposedAnticipatedCompletionDate__c = (proposedDate == null ? tempRec.AnticipatedCompletionDate__c : proposedDate);
       tempRec.ApprovalStatus__c= constants.APPROVE_STATUS ;
       update tempRec;
       
       //submit for Approval
       Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
       req1.setComments('ACD Approval process');
       req1.setObjectId(tempRec.Id);
       req1.setSubmitterId(UserInfo.getUserId());
       req1.setProcessDefinitionNameOrId('ACDApprovalProcess');
       req1.setSkipEntryCriteria(true);
       Approval.ProcessResult result = Approval.process(req1);
   }
}