/**
* @description       : This class is used for update the Step record status.
* @coverage          : StepStatusUpdateCtrlTest.cls | @CC100%
* @author            : rizwan
* @group             : 
* @last modified on  : 07-24-2023
* @last modified by  : rizwan
* Modifications Log  
* Ver   Date         Author             Modification
* 1.0   07-24-2023   rizwan             Initial Version | @CC100%
**/
public class StepStatusUpdateCtrl {
    public Boolean isUpdated{get;set;}
    public String responseString{get;set;}
    public String stepId{get;set;}
    public String statusId{get;set;}
    public String statusName{get;set;}
    public String userId{get;set;}
    public String statusType{get;set;}
    
    public StepStatusUpdateCtrl(){
        this.stepId = Apexpages.currentPage().getParameters().get('stepId');
        this.statusId = Apexpages.currentPage().getParameters().get('statusId');
        this.statusName = Apexpages.currentPage().getParameters().get('statusName');
        this.userId = Apexpages.currentPage().getParameters().get('userId');
        
        this.stepId = EncodingUtil.base64Decode(this.stepId).toString();
        this.statusId = EncodingUtil.base64Decode(this.statusId).toString();
        this.statusName = EncodingUtil.base64Decode(this.statusName).toString();
        this.userId = EncodingUtil.base64Decode(this.userId).toString();
        
        statusType = '';
        isUpdated = false;
        responseString = '';
    }
    
    
    public void statusUpdate(){
        List<User> userList = [SELECT Id, FirstName, Is_Approver__c, IsActive FROM User WHERE Id =:this.userId];
        
        this.statusType = 'slds-alert_error';
        HexaBPM__Step__c step = [SELECT Id, HexaBPM__Status__c, HexaBPM__Closed_Date__c FROM HexaBPM__Step__c WHERE Id =:stepId];
        
        if(userList.isEmpty()) {
            responseString = 'Active user is not found!!';
            this.isUpdated = true;
        } else if(!userList[0].Is_Approver__c) {
            responseString = 'This user is not approver!!'+userList[0].FirstName;
            this.isUpdated = true;
        } else if(step.HexaBPM__Closed_Date__c != null) {
            responseString = 'The step is already completed!!';
            this.isUpdated = true;
        } else {
            
            //step.HexaBPM__Status__c = this.statusId;
            step.Status_from_Email__c = this.statusId;
            update step;
            
            this.statusType = 'slds-alert_warning';
            this.isUpdated = true;
            this.responseString = 'Record updated with folllowing status : ' + this.statusName;
        }
    }
}