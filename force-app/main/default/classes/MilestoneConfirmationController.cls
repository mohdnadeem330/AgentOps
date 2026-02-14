/**********************************************************************************************************************
* Name               : MilestoneConfirmationController                                                        
* Description        : Class used as controller for MilestoneConfirmation LWC
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     06/09/2022      Initial Draft       
******************************************************************************************************************/
public class MilestoneConfirmationController{
   @auraEnabled
   public static void updateMilestoneDetails(string recordID, Date proposedDate, boolean triggerNotification, string comments){
       PaymentInstallments__c tempRec = [select id, InstallmentDate__c, OriginalInstallmentDate__c from PaymentInstallments__c where id = :recordID limit 1];
       tempRec.ProposedInstallmentDate__c = (proposedDate == null ? tempRec.InstallmentDate__c : proposedDate);
       tempRec.TriggerCustomerNotification__c = triggerNotification;
       tempRec.MilestoneChangeComment__c = comments;
       //tempRec.OriginalInstallmentDate__c = (tempRec.OriginalInstallmentDate__c == null ? tempRec.InstallmentDate__c : tempRec.OriginalInstallmentDate__c);
       tempRec.ApprovalStatus__c = Constants.APPROVE_STATUS;
       update tempRec;
       
       //submit for Approval
       Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
       req1.setComments('Milestone approval process');
       req1.setObjectId(tempRec.Id);
       req1.setSubmitterId(UserInfo.getUserId());
       req1.setProcessDefinitionNameOrId('PaymentInstallmentsApproval');
       req1.setSkipEntryCriteria(true);
       Approval.ProcessResult result = Approval.process(req1);
   }
}