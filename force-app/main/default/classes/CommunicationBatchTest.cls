/**
* CommunicationBatchTest
*
* Test class for CommunicationBatch
*/
@isTest
private class CommunicationBatchTest{
    //Creating setup data
    @testSetup static void setupData() {
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
       
            insert orgAcc;
       
        Account orgAcc2 = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220212');
       
            insert orgAcc2;
        
        
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        
        User agencyAdminUser = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN, 'pdbaa');
        agencyAdminUser.contactId=conRecord.Id;
        insert agencyAdminUser;
        
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
    //Testing Email communication
    @isTest static void testCommunicationEmail() {
        
            Contact conRecord = [select id from Contact limit 1];
            User userRecord = [select id from User where contactId = :conRecord.Id limit 1];
            Id bannerId =  [SELECT id, Name, Keywords FROM 
                            Document where Folder.Name = 'AlDar' AND Keywords = 'Broker' AND IsPublic = true 
                            ORDER BY CreatedDate DESC limit 1].Id;
           
            list<Account> agencies = CommunicationController.getAllAgency('','', '', '');
            System.assertEquals(agencies.isEmpty(),false);
            list<User> userList= CommunicationController.getRelatedUsers(new list<String>{agencies[0].Id});
            System.assertEquals(userList.isEmpty(),false);
            
            list<CommunicationTemplate__c> templateList= CommunicationController.getReletedCommunicationRecords(null);
            System.assertEquals(templateList.isEmpty(),true);
            
            Account nonRegistered = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220212');
            //nonRegistered.recordTypeID=Constants.NON_REGISTERED_TYPE_ID ;
            //nonRegistered.Name=null;
            
            insert nonRegistered;
            
            CommunicationTemplate__c templateEmail = new CommunicationTemplate__c();
            templateEmail.HTMLBody__c='Test';
            templateEmail.Offense__c=CommunicationTemplate__c.Offense__c.getDescribe().getPicklistValues()[0].getValue();
            templateEmail.SuspensionStartDate__c = System.today().addDays(5);
            templateEmail.SuspensionEndDate__c = System.today().addDays(5);
            templateEmail.PlainTextBody__c='Test';
            templateEmail.Status__c='Draft';
            templateEmail.Title__c='Test';
            templateEmail.Type__c='Email';
            insert templateEmail;
            
            Communication__c comm = new Communication__c(
                CommunicationTemplate__c = templateEmail.Id, Agency__c = agencies[0].Id, 
                Agent__c = conRecord.Id, Recipient__c = userRecord.Id, Status__c = 'In Progress'
            );
            insert comm;
            
            //Insert document
            ContentVersion contentVersion = new ContentVersion(
                Title          = 'a picture',
                PathOnClient   = 'Pic.jpg',
                VersionData    = Blob.valueOf('Test Content'),
                IsMajorVersion = true);
            insert contentVersion;
            
            contentVersion cv = [SELECT Id, ContentDocumentID FROM contentVersion where id =:contentVersion.Id limit 1];
            
            ContentDocumentLink contentlink=new ContentDocumentLink();
            contentlink.LinkedEntityId=templateEmail.id;
            contentlink.contentdocumentid=cv.ContentDocumentId;
            contentlink.ShareType = 'I';
            contentlink.Visibility = 'AllUsers'; 
            insert contentlink;    
            
            CommunicationController.updateUserSelection(templateEmail.Id, new list<ID>{userList[0].Id},new list<ID>{nonRegistered.Id},false,'test@test.com',bannerId);
            
            Test.startTest();
            Database.executeBatch(new CommunicationBatch(templateEmail.Id, bannerId),100);
            Test.stopTest();
       
        
    }
    
    //Testing SMS communication
    @isTest static void testCommunicationSMS() {
 
            Contact conRecord = [select id from Contact limit 1];
            conRecord.MobileCountryCode__c='971';
            conRecord.MobilePhone__c='000000000';
            update conRecord;     
            User userRecord = [select id from User where contactId = :conRecord.Id limit 1];
            Id bannerId =  [SELECT id, Name, Keywords FROM 
                            Document where Folder.Name = 'AlDar' AND Keywords = 'Broker' AND IsPublic = true 
                            ORDER BY CreatedDate DESC limit 1].Id;
            
            list<Account> agencies = CommunicationController.getAllAgency('','','', '');
            System.assertEquals(agencies.isEmpty(),false);
            list<User> userList= CommunicationController.getRelatedUsers(new list<String>{agencies[0].Id});
            System.assertEquals(userList.isEmpty(),false);
            
            list<CommunicationTemplate__c> templateList= CommunicationController.getReletedCommunicationRecords(null);
            System.assertEquals(templateList.isEmpty(),true);
            
            Account nonRegistered = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220212');
            //nonRegistered.recordTypeID=Constants.NON_REGISTERED_TYPE_ID ;
            //nonRegistered.Name=null;
            
                insert nonRegistered;
            
            
            CommunicationTemplate__c templateSMS = new CommunicationTemplate__c();
            templateSMS.HTMLBody__c='Test';
            templateSMS.Offense__c=CommunicationTemplate__c.Offense__c.getDescribe().getPicklistValues()[0].getValue();
            templateSMS.SuspensionStartDate__c = System.today().addDays(5);
            templateSMS.SuspensionEndDate__c = System.today().addDays(5);
            templateSMS.PlainTextBody__c='Test';
            templateSMS.Status__c='Draft';
            templateSMS.Title__c='Test';
            templateSMS.Type__c='SMS';
            insert templateSMS;
            
            Communication__c comm = new Communication__c(
                CommunicationTemplate__c = templateSMS.Id, Agency__c = agencies[0].Id, 
                Agent__c = conRecord.Id, Recipient__c = userRecord.Id, Status__c = 'In Progress'
            );
            insert comm;
            
            CommunicationController.updateUserSelection(templateSMS.Id, new list<ID>{userList[0].Id},new list<ID>{nonRegistered.Id},false,'test@test.com',bannerId);
            
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SMSMockResponse());
            Database.executeBatch(new CommunicationBatch(templateSMS.Id,bannerId),100);
            Test.stopTest();
       
    }
}