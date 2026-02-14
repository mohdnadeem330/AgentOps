@isTest
public class CC_ReviewRegistrationRequestTest {
    //Create setupData
    @testSetup static void setupData() {
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'AgencyRegistration']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }
        
        HexaBPM__Status__c SR_Status = new HexaBPM__Status__c();
        SR_Status.Name = 'Pending';
        SR_Status.HexaBPM__Code__c = 'Pending';
        insert SR_Status;

        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Agency Registration';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='AgencyRegistration';
        insert SR_Template;
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.AccountName__c = 'Test123';
        SR.RecordTypeId = recordTypeSR.get('AgencyRegistration');
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        insert SR;
        
        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'Require More Information';
        ST.HexaBPM__Code__c = 'Require More Information';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST;
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = 'Require More Information';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep;
        
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'Require More Information';
        step.HexaBPM__SR__c = SR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        insert step; 
        
        AgencyTeam__c at = new AgencyTeam__c();
        at.Type__c = 'Agency Admin';
        at.ShareHoldingPercentage__c = 100;
        at.ServiceRequest__c = SR.id;
        insert at;
    }
    
    @isTest
    static void callMethods() {
        Test.startTest();

        HexaBPM__Service_Request__c SR;
        AgencyTeam__c at;
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Require More Information' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        stp.ExecuteCustomCode__c = true;
        update stp;

        HexaBPM__Service_Request__c srToUpdate = new HexaBPM__Service_Request__c();
        srToUpdate.Id = stp.HexaBPM__SR__c;
        srToUpdate.PhoneNumber__c = '971 56789123';
        srToUpdate.Country__c = 'United Arab Emirates';
        srToUpdate.State__c = 'Sharjah';
        srToUpdate.ExpiryDate__c = Date.today().addYears(10);
        update srToUpdate;

        List<HexaBPM__Step__c> oldSteps = [Select Id, ExecuteCustomCode__c From HexaBPM__Step__c Where HexaBPM__SR__c =: stp.HexaBPM__SR__c And  ExecuteCustomCode__c = false];

        List<HexaBPM__Step__c> oldStepsToUpdate = new List<HexaBPM__Step__c>();

        for(HexaBPM__Step__c s : oldSteps){
            s.ExecuteCustomCode__c = true;
            oldStepsToUpdate.add(s);
        }
        update oldStepsToUpdate;

        CC_ReviewRegistrationRequest cc = new CC_ReviewRegistrationRequest();
        cc.EvaluateCustomCode(SR, stp);

        stp.ExecuteCustomCode__c = true;
        update stp;

        srToUpdate.Id = stp.HexaBPM__SR__c;
        srToUpdate.PhoneNumber__c = '';
        srToUpdate.Country__c = '';
        srToUpdate.State__c = '';
        srToUpdate.ExpiryDate__c = Date.today().addYears(10);
        update srToUpdate;

        cc.EvaluateCustomCode(SR, stp);

        HexaBPM__Step__c stp1 = new HexaBPM__Step__c();
        cc.EvaluateCustomCode(SR, stp1);


        Test.stopTest();
    }
}