public class BreachedStepsController {
    public String userId { get;  set;}
    static Id SR_AGENCY_REGISTRATION_RecordTypeId = Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByDeveloperName().get('AgencyRegistration').getRecordTypeId();

    public List<HexaBPM__Step__c> getbreachedSteps(){
        List<HexaBPM__Step__c> listSteps = new List<HexaBPM__Step__c>();
        try{
            listSteps = 
             [SELECT Id, Name,HexaBPM__Start_Date__c,HexaBPM__Due_Date__c,SLAExtensionInHours__c, HexaBPM__Summary__c, 
                    HexaBPM__SR__c, Account__c, HexaBPM__Step_No__c,HexaBPM__Step_Status__c, HexaBPM__Step_Template__c,CreatedDate,
                    OwnerId,Owner.Name,Owner.Email,HexaBPM__SR__r.Name,HexaBPM__SR__r.CompanyEmail__c,HexaBPM__SR__r.HexaBPM__Customer__c,Sent_Reminders__c
                    FROM HexaBPM__Step__c WHERE HexaBPM__SR__r.RecordTypeId = :SR_AGENCY_REGISTRATION_RecordTypeId AND OwnerId =: userId AND 
                    HexaBPM__SR__r.HexaBPM__SR_Template__r.Name = 'Agency Registration' AND 
                    HexaBPM__SR__r.HexaBPM__External_Status_Name__c NOT IN ('Closed', 'Completed', 'Rejected') AND
                    HexaBPM__Step_Status__c IN ('Pending', 'Pending Review')
                    AND HexaBPM__Summary__c in ('Assignment of Broker Manager','Validation by Sales Admin') ];
        }catch(Exception e){ StepTriggerHandler.createLogs(e, 'BreachedStepsController', 'getbreachedSteps', new List<String>(), listSteps);}
        return listSteps; 
    }
}