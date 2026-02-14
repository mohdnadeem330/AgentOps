@isTest
public class ProgressIndicatorControllerTest {
    
    @isTest
    static void callMethods() {
        Test.startTest();
        
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'AgencyRegistration']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }
        
        HexaBPM__SR_Status__c srStatus = new HexaBPM__SR_Status__c();
        srStatus.HexaBPM__Code__c = 'Submitted';
        srStatus.Name = 'Submitted';
        insert srStatus;
        
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Agency Registration';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='AgencyRegistration';
        insert SR_Template;
        
        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'Assignment of Broker Manager';
        ST.HexaBPM__Code__c = 'Assignment of Broker Manager';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST;
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = 'Assignment of Broker Manager';
        SRStep.HexaBPM__Group_Name__c = 'Assignment of Broker Manager';
        insert SRStep;
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        //SR.RecordTypeId = recordTypeSR.get('AgencyRegistration');
        SR.HexaBPM__External_SR_Status__c = srStatus.Id;
		SR.HexaBPM__Internal_SR_Status__c = srStatus.Id;
        SR.HexaBPM__Submitted_DateTime__c = Datetime.now();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.SRType__c = 'Agency Registration';
        insert SR;

        /*HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'Step 1';
        ST.HexaBPM__Code__c = 'Require More Information';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'Require More Information';
        insert ST;*/
        
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'Assignment of Broker Manager';
        step.HexaBPM__SR__c = SR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        step.HexaBPM__Step_Template__c = ST.Id;
        step.HexaBPM__Step_Notes__c = 'notes';
        insert step;

        /*HexaBPM__Service_Request__c sr = [Select Id From HexaBPM__Service_Request__c WHERE HexaBPM__External_SR_Status__r.Name != 'Draft' ORDER BY CreatedDate DESC LIMIT 1];
        sr.HexaBPM__Submitted_DateTime__c = Datetime.now();
        update sr;*/
        
        ProgressIndicatorController.getStepGroupWrapper(SR.Id);

        Test.stopTest();
    }
}