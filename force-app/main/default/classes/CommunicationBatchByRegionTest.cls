@isTest
private class CommunicationBatchByRegionTest {

    @TestSetup
    static void makeData(){
        // Create necessary record types
        Id brokerRecordTypeId = Constants.BROKER_AGENCY_RECORD_TYPE_ID;

        // Create a Communication Template
        CommunicationTemplate__c template = new CommunicationTemplate__c();
        template.HTMLBody__c = 'Test';
        template.Offense__c = CommunicationTemplate__c.Offense__c.getDescribe().getPicklistValues()[0].getValue();
        template.SuspensionStartDate__c = System.today().addDays(5);
        template.SuspensionEndDate__c = System.today().addDays(5);
        template.PlainTextBody__c = 'Test';
        template.Status__c = 'Published';
        template.Title__c = 'Test';
        template.Type__c = CommunicationTemplate__c.Type__c.getDescribe().getPicklistValues()[0].getValue();
        insert template;

        // Create an Account (Agency)
        Account acc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        acc.RecordTypeId = Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
        acc.AgencyStatus__c = 'Active' ;
        insert acc;

        // Create a Contact
        Contact con = new Contact(AccountId = acc.Id, FirstName = 'John', LastName = 'Doe', Email = 'john@example.com');
        insert con;

        // Create an Active User linked to the agency and contact
        User usr = new User(
            Username = 'testuser51626476341265785325362@test.com',
            Email = 'testuser@test.com',
            Alias = 'tuser',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Agency Admin']?.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            FirstName = 'John',
            LastName = 'Doe',
            ContactId = con.Id,
           // AccountId = acc.Id,
            IsActive = true
        );
        //insert usr;

        Folder myfolder = [Select Id From Folder Where Name = 'AlDar' LIMIT 1 ];
        if(myfolder != null){
            Document document = new Document();
            document.Body = Blob.valueOf('Some_Text');
            document.ContentType = 'jpg';
            document.DeveloperName = 'my_document';
            document.IsPublic = true;
            document.Name = 'MyDocument';
            document.FolderId = myfolder.Id;
            document.Keywords = 'Broker';
            insert document;
        }
    }

    @isTest
    static void testCommunicationBatchExecution() {
        
        Test.startTest();
        Document document = [SELECT Id FROM Document LIMIT 1];
        CommunicationTemplate__c template = [SELECT Id FROM CommunicationTemplate__c LIMIT 1];
        CommunicationBatchByRegion batch = new CommunicationBatchByRegion(
            'Domestic',             // regionName
            'Abu Dhabi',             // emirateName
            template.Id,         // templateId
            'qa-team@test.com',  // testEmail
            document.Id   // bannerId
        );

        Database.executeBatch(batch, 1); // scope size 1 for simplicity

        List<Sobject> listSobject = [SELECT Id FROM Account] ;
        Database.QueryLocator ql = batch.start(null);
        batch.execute(null, listSobject);
        batch.Finish(null);

        Test.stopTest();
    }

    @isTest
    static void testEmptyAgencyScenario() {
        CommunicationTemplate__c template = new CommunicationTemplate__c();
        template.HTMLBody__c = 'Test';
        template.Offense__c = CommunicationTemplate__c.Offense__c.getDescribe().getPicklistValues()[0].getValue();
        template.SuspensionStartDate__c = System.today().addDays(5);
        template.SuspensionEndDate__c = System.today().addDays(5);
        template.PlainTextBody__c = 'Test';
        template.Status__c = 'Published';
        template.Title__c = 'Test';
        template.Type__c = CommunicationTemplate__c.Type__c.getDescribe().getPicklistValues()[0].getValue();
        insert template;

        Test.startTest();
        CommunicationBatchByRegion batch = new CommunicationBatchByRegion(
            'Domestic',
            'Abu Dhabi',
            template.Id,
            '',
            ''
        );

        Database.executeBatch(batch, 1);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Communication__c WHERE CommunicationTemplate__c = :template.Id]);
    }
}