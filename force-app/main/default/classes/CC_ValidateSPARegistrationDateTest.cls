@isTest
public with sharing class CC_ValidateSPARegistrationDateTest {
    
    static testMethod void  validateSPARegistrationDateTest() {
		Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.NationalIdNumber__pc = '';
        insert acc;
        
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'InvestorCertificate']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }

        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('InvestorCertificate');       
        insert SR;
        
        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert objSRStatus;

        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Investor Certificate';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='InvestorCertificate';
        insert SR_Template;

        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'Step 1';
        ST.HexaBPM__Code__c = 'Prepare & Verify the Investor Certificate';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'Prepare & Verify the Investor Certificate';
        insert ST;
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = 'Test';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'InvestorCertificate';
        insert SRStep;
        
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'Prepare & Verify the Investor Certificate';
        step.HexaBPM__SR__c = SR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        insert step; 

        CC_ValidateSPARegistrationDate obj = new CC_ValidateSPARegistrationDate();
        obj.EvaluateCustomCode(SR, step);
        obj.EvaluateCustomCode(null, null);
        
        //User userData = [select id from User where profile.Name='Broker Manager' and UserRole.Name= 'Broker Relations Manager' limit 1];
        
        //SR.BrokerManager__c=userData.Id;//userInfo.getUserId();
        //update SR;
        //obj.EvaluateCustomCode(SR, step);

    }


}