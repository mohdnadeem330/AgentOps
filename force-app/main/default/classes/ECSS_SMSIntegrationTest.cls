@isTest
public class ECSS_SMSIntegrationTest {
    
    @testSetup
    static void createData(){
        TestObjectsFactory.createUser();
        User testUser = [select id from user where email='testuser@example.com'];
        System.runAs(testUser) {
            Account newAccount = TestObjectsFactory.getPersonAccountRecord(181, 'United Arab Emirates', 'V1', 'P1');
            insert newAccount;
            
            Case caseObj = TestObjectsFactory.getProvisComplaintCase(newAccount);
            insert caseObj;
        }
    }
    @isTest
    public static void testSMS(){
        ECSS_SMS_Configuration__mdt smsMtd = [SELECT MasterLabel, EndPoint__c, Username__c, Password__c, SID__c, MType__c, DR__c, Method__c 
                                               FROM ECSS_SMS_Configuration__mdt 
                                               WHERE MasterLabel = 'IFM/ Khidmah Home' LIMIT 1];
        
        List<String> mobilePhones = new List<String>{'1234567890', '0987654321'};
        String message = 'Test Message';

        ECSS_SMSIntegration.RequestData requestData = new ECSS_SMSIntegration.RequestData();
        requestData.smsMtd = smsMtd;
        requestData.mobilePhones = mobilePhones;
        requestData.message = message;
        requestData.isArabic = false;

        List<ECSS_SMSIntegration.RequestData> requestList = new List<ECSS_SMSIntegration.RequestData>{requestData};

        Test.startTest();
        
        // Step 2: Mock the callout
        String responseBody = JSON.Serialize(requestData);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        
        // Step 3: Invoke the sendMsg method
        ECSS_SMSIntegration.sendMsg(requestList);
        
        Test.stopTest();

        
    }
    
    
}