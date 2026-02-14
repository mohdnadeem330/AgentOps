@isTest
public class SendCommunityManagerEmailTest {
    @testSetUp
    static void dataSetUp() {
        Id personAccountRecordTypeId = utilities.getRecordTypeId('Account', 'Person Account');
        Account acc = new Account(
            FirstName = 'Test',
            LastName = 'Agni',
            PersonEmail = 'agni@gmail.com',
            RecordTypeId = personAccountRecordTypeId,
            CustomerAppWebUser__c = false
        );
        insert acc;
        
        Project__c project = TestObjectsFactory.getProjectRecord('recordId');
        project.OA_Community_Name__c = 'Al Muneera';
        insert project;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        unit.Name = 'MAYAN-B1-1004';
        unit.Project__c = project.Id;
        insert unit;
        
        Unit__c unit2 = TestObjectsFactory.unitDataSetup('25083');
        unit2.Status__c = 'Sold';
        unit2.Name = 'ALG2-B1-1004';
        unit2.Project__c = project.Id;
        insert unit2;
        
        HexaBPM__SR_Status__c submittedStatus = TestObjectsFactory.getSRStatus('Submitted');
        insert submittedStatus;
        
        HexaBPM__Status__c status = new HexaBPM__Status__c();
        status.Name = 'Cancelled';
        status.HexaBPM__Code__c = 'Cancelled';
        status.HexaBPM__Type__c = 'Start';
        insert status;
        
        HexaBPM__SR_Status__c cancelledByuser = new HexaBPM__SR_Status__c();
        cancelledByuser.Name = 'Cancelled By user';
        cancelledByuser.HexaBPM__Code__c = 'Cancelled By user';
        insert cancelledByuser;
        
        Id moveInNOCRTId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'AldarEstatesMoveInOut');
        HexaBPM__SR_Template__c moveInSRTemplate = new HexaBPM__SR_Template__c(
            HexaBPM__Active__c = true,
            HexaBPM__SR_RecordType_API_Name__c = 'Aldar Estates Move In/Out'
        );
        insert moveInSRTemplate;
        
        HexaBPM__Service_Request__c moveInSR = TestObjectsFactory.getServiceRequest(
            submittedStatus.Id, unit.Id, 'Aldar Estates Move-In', moveInNOCRTId, moveInSRTemplate.Id
        );
        moveInSR.HexaBPM__Customer__c = acc.Id;
        moveInSR.RecordTypeId =  Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByDeveloperName().get('AldarEstatesMoveInOut').getRecordTypeId();
        
        insert moveInSR;
        system.debug('INSERTED_SR_DETAILS::'+moveInSR);
    }
    
    
    @isTest
    static void callSendEmailMethod() {
        
        String templateId = Utilities.getEmailtemplateIdByName('Notify_Community_Manager_Before_Move_In');
        List<HexaBPM__Service_Request__c>  moveInSR = [SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1];
         list<String> toAddress = new list<String>(); 
        toAddress.add('test@aldar.com.invalid');
        try {
            Test.startTest();
            SendCommunityManagerEmail.FlowInput flowInput = new SendCommunityManagerEmail.FlowInput();
            flowInput.srId = moveInSR[0].Id;
            flowInput.emailtemplateId = templateId;
            flowInput.toAddress = toAddress;
            
            SendCommunityManagerEmail.sendEmail(new List<SendCommunityManagerEmail.FlowInput>{flowInput});
            
            Test.StopTest();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        
    }
    
    
    
}