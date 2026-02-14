@isTest
public class DocusignSPAAPITest {
    @testSetUp
    public static void testData(){
        
		Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
		
		Contact newContact = new Contact();
        newContact.AccountId = acc.id  ;
        newContact.FirstName = 'FirstName';
        newContact.LastName = 'LastName';
        newContact.Email = 'testemail@test.com';
		newContact.PrimaryContact__c = true;
        newContact.RecordTypeId = ALD_Constants.BROKER_AGENT_RT;
        newContact.AgentStatus__c = 'Active';
        insert newContact;
        String recipientName = acc.isPersonAccount 
            ? (acc.FirstName + ' ' + acc.LastName) 
            : (acc.Contacts.size() > 0 
               ? acc.Contacts[0].FirstName + ' ' + acc.Contacts[0].LastName 
               : 'No Contact Found');
                   System.debug('Recipient Name: ' + recipientName);
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        OpportunityEOI__c oppEOI = TestObjectsFactory.getOpportunityEOIRecord(opp.Id,'POS');
        oppEOI.Account__c= acc.Id;
        oppEOI.ComplianceStatus__c = 'Cleared';
        insert oppEOI;
        
        Project__c project=TestObjectsFactory.getProjectRecord('recordId');
        project.DigitalSignatureApplied__c = true;
        insert project;
        
        list<Unit__c> units = new list<unit__c>();
        unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        unit.Name = 'MAYAN-B1-1004'; 
        unit.Project__c= project.Id;
        insert unit;
        
        User usr=TestObjectsFactory.getUserRecord('System Administrator','akuttiyil');
        insert usr;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.MortgageApplicable__c = 'Yes';
        salesOrder.Account__c=acc.Id;
        salesOrder.Opportunity__c=opp.Id;
        salesOrder.OwnerManger__c=usr.Id;
        insert salesOrder;
        
        Document__c document = TestObjectsFactory.getSalesOrderDocument(opp.Id,salesOrder.Id);
        document.SalesOrder__c= salesOrder.Id;
        document.ExpressionofInterest__c= oppEOI.Id;
		document.Other_Document_Name__c='test';
		document.DocumentType__c='Aldar Signed SPA';
        insert document;
	
        ContentDocumentLink contentDocLink= new ContentDocumentLink();
		contentDocLink= TestObjectsFactory.createContentDocumentLink(document.Id);

		JointOwner__c jointOwner= new JointOwner__c();
		jointOwner= TestObjectsFactory.getJointOwnerRecord(salesOrder.Id,acc.Id,'Friend Of');
		//insert jointOwner;
		system.debug('SalesorderidofJointonwer::'+jointOwner.SalesOrder__c);
        
        Communication_Preference__c cp = new Communication_Preference__c();
        cp.Document__c= document.Id;
        insert cp;
    }
    
    @isTest
    public static void testSendforDigitalSignature(){
        list<Document__c> documentRecord=[SELECT Id, SalesOrder__c FROM Document__c WHERE Other_Document_Name__c='test'];
        system.debug('SalesorderOfDocument:::'+documentRecord[0].SalesOrder__c);
        Test.startTest();
        DocusignSPAAPI.SendforDigitalSignature(documentRecord[0].Id,'');
        Test.setMock(HttpCalloutMock.class, new DocusignSPAAPIMock());
        Test.stopTest();
    }
    
    @isTest
	 public static void DocusignSPATestCallouts(){
		Test.starttest();
         Test.setMock(HttpCalloutMock.class, new DocusignSPAAPIMock());
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/DocusignSPA';
        req.httpMethod = 'Post';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
		DocusignSPAAPI.DocusignSPA();
        Test.stopTest();
    }

	@isTest
    static void getDocusignURLTest(){
		 list<Document__c> docuRecord=[SELECT Id, SalesOrder__c FROM Document__c WHERE Other_Document_Name__c='test'];
        list<Account> accRecord=[SELECT Id FROM Account WHERE RegistrationNumber__c='G123456'];
		Test.startTest();
         DocusignUpdateEvent__e pgEvent = new DocusignUpdateEvent__e(SalesOrderId__c = docuRecord[0].SalesOrder__c);
        EventBus.publish(pgEvent);
        Test.setMock(HttpCalloutMock.class, new DocusignSPAAPIMock());
        DocusignSPAAPI.getDocusignURL(docuRecord[0].Id,accRecord[0].Id,'docusginreturnurl.com');
		Test.stopTest();
    }
	
	@isTest
    static void getDocusignURLMockCallout(){
        list<Document__c> docRecord=[SELECT Id, SalesOrder__c FROM Document__c WHERE Other_Document_Name__c='test'];
         list<Account> acctRecord=[SELECT Id FROM Account WHERE RegistrationNumber__c='G123456'];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DocusignSPAAPIMock());
        DocusignSPAAPI.getDocusignURL(docRecord[0].Id,acctRecord[0].Id,'docusginreturnurl.com');
        DocuSignAPIWrapper.AuthenticationRequestModel sp = new DocuSignAPIWrapper.AuthenticationRequestModel('test','test');
        DocuSignAPIWrapper.RecipientModel rs = new DocuSignAPIWrapper.RecipientModel(null,'String','String', 'String', 'String' ,'String' , 'NamePlaceholder',  'DatePlaceholder', 'Stamp');
        Test.stopTest();
    }
    
    
    
}