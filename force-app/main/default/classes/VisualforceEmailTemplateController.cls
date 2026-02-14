/**
* @description       : VF Page Controller 
* @coverage          : VisualforceEmailTemplateControllerTest.cls | @CC100%
* @author            : rizwan
* @group             : 
* @last modified on  : 07-24-2023
* @last modified by  : rizwan
* Modifications Log
* Ver   Date         Author                                    Modification
* 1.0   07-24-2023   rizwan             Initial Version |  | @CC100%
**/
public class VisualforceEmailTemplateController {
    public String emailStepId { get; set; }
    public String userRecordId{get;set;}
    public String currentStatus{get;set;}
    public Decimal waivedAmount{get;set;}
    public HexaBPM__Service_Request__c serviceRequest{get;set;}
    
    public VisualforceEmailTemplateController(){
        //HexaBPM__Step__c step = [SELECT Id, HexaBPM__Step_Status__c FROM HexaBPM__Step__c WHERE Id=:emailStepId LIMIT 1];
        //this.currentStatus = step.HexaBPM__Step_Status__c;
    }
	
    //Return a list of transitions
    public List<Wrapper> getTransitions(){
        List<Wrapper> wrapList = new List<Wrapper>();
		this.userRecordId = EncodingUtil.Base64Encode(Blob.valueOf(userRecordId));        
        List<HexaBPM__Step_Transition__c> stepTransitionList = new List<HexaBPM__Step_Transition__c>();
        HexaBPM__Step__c step = [SELECT Id, HexaBPM__SR_Step__c, HexaBPM__Step_Status__c, HexaBPM__SR__c FROM HexaBPM__Step__c WHERE Id =:emailStepId LIMIT 1];
        serviceRequest = [SELECT Id, WaivedAmount__c, Unit__r.Name, HexaBPM__Customer__r.Name, Name FROM HexaBPM__Service_Request__c WHERE Id =:step.HexaBPM__SR__c LIMIT 1];
        currentStatus = step.HexaBPM__Step_Status__c;
        
        stepTransitionList = [SELECT Id, HexaBPM__To__c, HexaBPM__Transition__c, HexaBPM__Transition__r.HexaBPM__To__c, Name FROM HexaBPM__Step_Transition__c WHERE HexaBPM__SR_Step__c =:step.HexaBPM__SR_Step__c];
        
        for(HexaBPM__Step_Transition__c stepTran : stepTransitionList) {
            wrapList.add(new Wrapper(emailStepId, stepTran.HexaBPM__Transition__r.HexaBPM__To__c, stepTran.HexaBPM__To__c));
        }
        
        return wrapList;
    }
    
    public class Wrapper {
        public String stepId{get; set;}
        public String statusId{get; set;}
        public String statusName{get; set;}
        public String name{get; set;}
        
        public Wrapper(String stepId, String statusId, String statusName) {
            this.stepId = EncodingUtil.Base64Encode(Blob.valueOf(stepId));
            this.statusId = EncodingUtil.Base64Encode(Blob.valueOf(statusId));
            this.statusName = EncodingUtil.Base64Encode(Blob.valueOf(statusName));
            this.name = statusName;
        }
    }
}