@isTest
public class SOAFromSRControllerTest {
    
    @isTest
    static void callMethods() {

        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus('Submitted');       
        insert Submitted;

        HexaBPM__Service_Request__c propertyTransfer = new HexaBPM__Service_Request__c();
        propertyTransfer.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_RT);
        propertyTransfer.SRType__c =Constants.PROPERTY_TRANSFER_TYPE;
        insert propertyTransfer;
        
        Test.startTest();
        
        SOAFromSRController.getServiceRequest(propertyTransfer.Id);
        Test.stopTest();
        
    }
}