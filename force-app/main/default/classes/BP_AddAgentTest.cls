@IsTest
private class BP_AddAgentTest {
    
    static void setupTestData() {
       
        Account testAgency = new Account(
            Name = 'Test Agency',
            BillingCountry = 'United Arab Emirates',
            BillingState = 'Dubai'
        );
        insert testAgency;

        // Create test data for required fields
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Agent',
            Email = 'testagent@example.com',
            BrokerType__c = 'Agent',
            AccountId = testAgency.Id,
            NationalIdNumber__c = '784123456789012'
        );
        insert testContact;
        
        Account testAgency_AD = new Account(
            Name = 'Test Agency AD',
            BillingCountry = 'United Arab Emirates',
            BillingState = 'Abu Dhabi'
        );
        insert testAgency_AD;

        // Create test data for required fields
        Contact testContact_AD = new Contact(
            FirstName = 'Test',
            LastName = 'Agent',
            Email = 'testagent_AD@example.com',
            BrokerType__c = 'Agent',
            AccountId = testAgency_AD.Id,
            NationalIdNumber__c = '784123456789012'
        );
        insert testContact_AD;
        
        Id recordTypeID = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('BrokerDocuments').getRecordTypeId();

        Document__c documentRecord = DocumentService.createDocumentRecord('','','','Emirates ID Copy','','',recordTypeID);
        documentRecord.Contact__c   = testContact_AD.Id;
        documentRecord.SendForESign__c          = false;
        documentRecord.DocumentPlaceHolderId__c = 'test';
        documentRecord.EligibleForeSign__c      = true;
        insert documentRecord;
        
        Document__c documentRecord2 = DocumentService.createDocumentRecord('','','','ADM Card','','',recordTypeID);
        documentRecord2.Contact__c   = testContact.Id;
        documentRecord2.SendForESign__c          = false;
        documentRecord2.DocumentPlaceHolderId__c = 'test';
        documentRecord2.EligibleForeSign__c      = true;
        insert documentRecord2;
    }

    @IsTest
    static void testCreateContactSuccess() {
        setupTestData();
        Account agency = [SELECT Id FROM Account WHERE Name = 'Test Agency' LIMIT 1];

        // Mock request data
        String requestBody = JSON.serialize(new Map<String, Object>{
            'agencyName' => agency.Id,
            'title' => 'Mr',
            'firstName' => 'Moh',
            'lastName' => 'Sarfaraj',
            'emailId' => 'msarfaraj123@aldar.com',
            'role' => 'Agency Admin',
            'country' => 'United Arab Emirates',
            'residentStatus' => 'Abu Dhabi',
            'phoneNumber' => '552191627',
            'countryCode' => '971',
            'contactId' => '',
            'userId' => '',
            'birthdate' => '1992-01-12',
            'emiratesID' => '784123456789012',
            'expiryDate' => '2029-01-01',
            'primaryOwner' => false,
            'primaryAgencyAdmin' => false,
            'nationality' => 'India',
            'passportNumber' => '6718575',
            'passportExpiryDate' => '2032-01-01',
            'emiratesOrVisaCopy' =>'heruwff', // required for UAE
            'passportCopy' => 'contetsnt', // required for all
            'reraCopy' =>'yutuyijhf',// required for Dubai,UAE (Agent) only
            'admCopy' =>'rieuhu' // required for Abu Dhabi,UAE (Agent) only
        
        });

        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = res;

        BP_AddAgent.createContact();
        Test.stopTest();

    }
    
      @IsTest
    static void testCreateContactSuccess2() {
        setupTestData();
        Contact con = [SELECT Id From Contact limit 1];
        Account agency = [SELECT Id FROM Account WHERE Name = 'Test Agency AD' LIMIT 1];

        // Mock request data
        String requestBody = JSON.serialize(new Map<String, Object>{
            'agencyName' => agency.Id,
            'title' => 'Mr',
            'firstName' => 'Moh',
            'lastName' => 'Sarfaraj',
            'emailId' => 'msarfaraj123@aldar.com',
            'role' => 'Agency Admin',
            'country' => 'United Arab Emirates',
            'residentStatus' => 'Abu Dhabi',
            'phoneNumber' => '552191627',
            'countryCode' => '971',
            'contactId' => con.Id,
            'userId' => '',
            'birthdate' => '1992-01-12',
            'emiratesID' => '784123456789012',
            'expiryDate' => '2029-01-01',
            'primaryOwner' => false,
            'primaryAgencyAdmin' => false,
            'nationality' => 'India',
            'passportNumber' => '6718575',
            'passportExpiryDate' => '2032-01-01',
            'emiratesOrVisaCopy' =>'heruwff', // required for UAE
            'passportCopy' => 'contetsnt', // required for all
            'reraCopy' =>'yutuyijhf',// required for Dubai,UAE (Agent) only
            'admCopy' =>'rieuhu' // required for Abu Dhabi,UAE (Agent) only
        
        });

        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = res;
        BP_AddAgent.createContact();
        Test.stopTest();

    }

    @IsTest
    static void testCreateContactValidationFailure() {
        setupTestData();
        Account agency = [SELECT Id FROM Account WHERE Name = 'Test Agency' LIMIT 1];

        // Mock invalid request data (missing required fields)
        String requestBody = JSON.serialize(new Map<String, Object>{
            'agencyName' => agency.Id,
            'title' => 'Mr',
            'firstName' => 'Moh',
            'lastName' => 'Sarfaraj',
            'emailId' => 'msarfaraj123@aldar.com',
            'role' => 'Agency Admin',
            'country' => 'United Arab Emirates',
            'residentStatus' => 'Abu Dhabi',
            'phoneNumber' => '552191627',
            'countryCode' => '971',
            'contactId' => '',
            'userId' => '',
            'birthdate' => '1992-01-12',
            'emiratesID' => '784123456789012',
            'expiryDate' => '2029-01-01',
            'primaryOwner' => false,
            'primaryAgencyAdmin' => false,
            'nationality' => 'India',
            'passportNumber' => '6718575',
            'passportExpiryDate' => '2032-01-01',
            'emiratesOrVisaCopy' => 'heruwff', // required for UAE
                'passportCopy' => new List<String>{ 'contetsnt'}, // required for all
            'reraCopy' => 'yutuyijhf',// required for Dubai,UAE (Agent) only
            'admCopy' => 'rieuhu' // required for Abu Dhabi,UAE (Agent) only
        });

        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = res;

        BP_AddAgent.createContact();
        Test.stopTest();
  }

    
    @IsTest
    static void testCreateContactExceptionHandling() {
        setupTestData();
        String invalidRequestBody = '';

        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(invalidRequestBody);
        RestContext.request = req;
        RestContext.response = res;

        BP_AddAgent.createContact();
        Test.stopTest();

            }

	@isTest
    static void uploadUserPictureTest(){
        setupTestData();
         String base64Data = 'iVBORw0KGgoAAAANSUhEUgAAAoAAAAHgCAIAAADd'+
                            'mDkNBQAAAHElEQVR4nOzdf3gUVRjG8S/GsZm++vLfFYc8PmvMNTZBgINIfli'+
                            'D3uXf5bmDQfA+Y1iFWbsqrchQeNBRd7l74YRL8ZRTtQQgAldzyJEwZGm7qFiT2kg==' ;
        test.startTest();
        BP_AddAgent.uploadUserPicture(base64Data);
		test.stopTest();
    }
    
    @isTest(SeeAllData=true)
    static void uploadUserPictureTest2(){
        setupTestData();
         String base64Data = 'iVBORw0KGgoAAAANSUhEUgAAAoAAAAHgCAIAAADd'+
                            'mDkNBQAAAHElEQVR4nOzdf3gUVRjG8S/GsZm++vLfFYc8PmvMNTZBgINIfli'+
                            'D3uXf5bmDQfA+Y1iFWbsqrchQeNBRd7l74YRL8ZRTtQQgAldzyJEwZGm7qFiT2kg==' ;
        test.startTest();
        BP_AddAgent.uploadUserPicture(base64Data);
		test.stopTest();
    }
	
  
}