@isTest
public class CommunicationTryBatchTest 
{
    @isTest static void setupDataMethod()
    {
        Account orgAcc = TestObjectsFactory.getAccountRecord('Broker Agency',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
        insert orgAcc;
        
        Account orgAcc2 = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220212');
        insert orgAcc2;

        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        
        
        User agencyAdminUser = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN, 'pdbaa');
        agencyAdminUser.contactId=conRecord.Id;
        insert agencyAdminUser;
        
        CommunicationTemplate__c template = new CommunicationTemplate__c();
        template.HTMLBody__c='Test';
        template.Offense__c=CommunicationTemplate__c.Offense__c.getDescribe().getPicklistValues()[0].getValue();
        template.SuspensionStartDate__c = System.today().addDays(5);
        template.SuspensionEndDate__c = System.today().addDays(5);
        template.PlainTextBody__c='Test';
        template.Status__c='Published';
        template.Title__c='Test';
        template.Type__c=CommunicationTemplate__c.Type__c.getDescribe().getPicklistValues()[0].getValue();
        insert template;
        
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
        
        //select id,Agency__c,Agent__c,Recipient__c,Status__c from Communication__c
        List<Communication__c>    communicationList = new List<Communication__c>(); 
        
        Communication__c communication 	= new Communication__c();
        communication.Agency__c			= orgAcc.Id;
        communication.Agent__c			= conRecord.Id;
        communication.CommunicationTemplate__c = template.Id;
        communicationList.add(communication);
        
        insert communicationList;
        
        Id bannerId =  [SELECT id, Name, Keywords FROM 
                        Document where Folder.Name = 'AlDar' AND Keywords = 'Broker' AND IsPublic = true 
                        ORDER BY CreatedDate DESC limit 1].Id;
            
        test.startTest();
        Database.executeBatch(new CommunicationTryBatch(communicationList, template.Id,bannerId ));
        test.stopTest();
        
    }
    
}