@isTest
public class ContentDocumentTriggerHandlerTest 
{
    @isTest
    public static void testContentDocumentLinkForContact() 
    {
        Test.startTest();
        Id brokerConRecTypeId = Schema.SobjectType.Contact.getRecordTypeInfosByDeveloperName()
                                        .get('BrokerAgent')
                                        .getRecordTypeID();
        
        Account acc = TestObjectsFactory.getAgencyAccountRecord('TestAgencyAccount', 'TestRegistrationNo');
        acc.AgencyStatus__c = 'Active';
        insert acc;
        
        Contact con = new Contact();
        con.LastName = 'TestingName';
        con.RecordTypeId = brokerConRecTypeId;
        con.AccountId = acc.Id;
        insert con;
        
        ContentVersion contentVersionInsert = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.pdf',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert contentVersionInsert;
		List<ContentDocument> documents = [SELECT Id, Title,
                                           LatestPublishedVersionId FROM ContentDocument];
        //create ContentDocumentLink  record
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = con.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;
        
        delete documents;
        
    	Test.stopTest();
    }

}