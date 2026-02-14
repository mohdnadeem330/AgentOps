/**
* DocumentTriggerHandlerTest
*
* Test class for DocumentTriggerHandler
*/
@isTest
private class DocumentTriggerHandlerTest{
    public static Boolean BYPASS_TRIGGER = TRUE; //By-pass existing integration for the Other Charges
    public static Boolean IsTesting_FOR_ADMIN = TRUE; //ADMIN TEST TO MOCK
    public static Boolean bypassValidation = true;
    //Creating Setup data for testing 
     @testSetup static void setupData() {
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID;
        orgAcc.Email__c = 'Ali.athamneh@pwc.com';
        insert orgAcc;
       
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        conRecord.Email = 'Ali.athamneh@pwc.com';
        update conRecord;
        
        /*User agencyAdminUser = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN, 'pdbaa');
agencyAdminUser.contactId=conRecord.Id;
agencyAdminUser.UserRoleId = role.Id;
insert agencyAdminUser;
*/
         
        Loop__DDP__c loopdd = New Loop__DDP__c();
        loopdd.Name = 'GTC';
        insert loopdd;
         
        Loop__DDP_Integration_Option__c loopdrec = new Loop__DDP_Integration_Option__c();
        loopdrec.Loop__DDP__c = loopdd.id;
        loopdrec.Name = 'GTC';
        insert loopdrec;
         
         Account acc = TestObjectsFactory.getPersonAccountRecord();
         acc.CustomerBankName__c = 'Test';
         acc.CustomerBankCountry__c = 'United Arab Emirates';
         insert acc;
         
         Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
         opp.BrokerAgencyAccount__c =orgAcc.Id;
         opp.BrokerAgentContact__c=conRecord.Id;
         
         opp.Contact__c=conRecord.Id;
         insert opp; 
         Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
         insert projectRecord;
         
         //Add GTC under project
         Document__c docRecord= new Document__c(Project__c=projectRecord.Id,DocumentType__c=Constants.DOCUMENT_TYPE_GTC);
         insert docRecord;
         OpportunityUnitSearchController.uploadFile(Blob.valueOf('Test').toString(),docRecord.DocumentType__c,docRecord.id);
         
         BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
         insert buildingRecord;
         Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
         insert unitrecord;
         
         PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
         insert paymentPlanRecord;
         list<PaymentInstallments__c> installmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
         insert installmentLines;
         paymentPlanRecord.IsActive__c =Constants.YES;
         update paymentPlanRecord;
         BuildingSectionMapping__c buldingPaymentMapping = TestObjectsFactory.getBuildingSectionMapping(paymentPlanRecord.Id,buildingRecord.Id);
         insert buldingPaymentMapping;    
         
         OffersPromotions__c offerRecord= TestObjectsFactory.getOfferPromotion(buildingRecord.Id,projectRecord.Id);
         insert offerRecord;
         OfferLines__c offerLine = TestObjectsFactory.getOfferLine(offerRecord.Id);
         insert offerLine;
    }
    //Tesing Sales Order Documents
    @isTest static void testSODocument() {
        test.startTest();
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID;
        orgAcc.Email__c = 'Ali.athamneh@pwc.com';
        insert orgAcc;
        Opportunity optyRecord = [select id,AccountId from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        Project__c projectRecord= [select id from Project__c limit 1];
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,orgAcc.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        //salesOrderRecord.Project__c=projectRecord.Id;
        salesOrderRecord.SellingPrice__c=1000000;
        salesOrderRecord.ExternalCommissionAmount__c=10000;
        salesOrderRecord.Status__c = Constants.UNIT_STATUS_SOLD;
        salesOrderRecord.Account__c=optyRecord.AccountId;
        salesOrderRecord.ReceiptAcknowledgementPaymentMethod__c='Online';
        salesOrderRecord.RAcknowledgementReservationAmount__c=10000;
        insert salesOrderRecord;
        //Add GTC under SO
        Document__c docRecord= new Document__c(SalesOrder__c=salesOrderRecord.Id,DocumentType__c=Constants.DOCUMENT_TYPE_GTC);
        insert docRecord;
        
        list<Document__c> docsToCOmplete = [select id,Suspensions_Warning__c,SalesOrder__c,GenerateDocument__c,ExpressionofInterest__c,Status__c, Case__c, Opportunity__c,IsEmailSenttoADHA__c,DocumentType__c,ProjectName__c,Quote__c  from Document__c where SalesOrder__c=:salesOrderRecord.Id];
        list<Document__c> oldList = new list<Document__c>();
        System.assertEquals(docsToCOmplete.isEmpty(),false);
        for(Document__c doc : docsToCOmplete){
            oldList.add(doc.clone(true,true,true,false));
            doc.Status__c=Constants.DOCUMENT_STATUS_COMPLETED;
        }
        update docsToCOmplete;
        DocumentTriggerHandler obj= new DocumentTriggerHandler();
        obj.afterUpdateMethod(docsToCOmplete,new map<id,Document__c>(docsToCOmplete),oldList,new map<id,Document__c>(oldList) );
        test.stoptest();
    }

   /* @isTest static void testspaSrToCreate() {
Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID;
orgAcc.Email__c = 'Ali.athamneh@pwc.com';
insert orgAcc;
Opportunity optyRecord = [select id,AccountId from opportunity limit 1];
Unit__c unitrecord = [select id from Unit__c limit 1];
unitrecord.Status__c = 'Sold';
update unitrecord;
Project__c projectRecord= [select id from Project__c limit 1];
SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,orgAcc.Id);
salesOrderRecord.Unit__c=unitrecord.Id;
HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
insert objSRStatus;
        
HexaBPM__Service_Request__c srRecords = new HexaBPM__Service_Request__c();
srRecords.HexaBPM__External_SR_Status__c = objSRStatus.Id;
srRecords.HexaBPM__Internal_SR_Status__c = objSRStatus.Id;
srRecords.HexaBPM__Submitted_DateTime__c = system.now();
srRecords.HexaBPM__Submitted_Date__c = system.today();
insert srRecords;
        
//salesOrderRecord.Project__c=projectRecord.Id;
salesOrderRecord.SellingPrice__c=1000000;
salesOrderRecord.ExternalCommissionAmount__c=10000;
salesOrderRecord.Status__c = Constants.UNIT_STATUS_SOLD;
salesOrderRecord.Account__c=optyRecord.AccountId;
salesOrderRecord.ReceiptAcknowledgementPaymentMethod__c='Online';
salesOrderRecord.RAcknowledgementReservationAmount__c=10000;
insert salesOrderRecord;
//Add GTC under SO
Document__c docRecord= new Document__c(SalesOrder__c=salesOrderRecord.Id,DocumentType__c=Constants.DOCUMENT_TYPE_GTC);
insert docRecord;
test.startTest();
list<Document__c> docsToCOmplete = [select id,SalesOrder__c,GenerateDocument__c,ExpressionofInterest__c,Status__c, Case__c, Opportunity__c,IsEmailSenttoADHA__c,DocumentType__c,ProjectName__c  from Document__c where SalesOrder__c=:salesOrderRecord.Id];
list<Document__c> oldList = new list<Document__c>();
System.assertEquals(docsToCOmplete.isEmpty(),false);
for(Document__c doc : docsToCOmplete){
oldList.add(doc.clone(true,true,true,false));
doc.Status__c=Constants.DOCUMENT_STATUS_UPLOADED;
doc.DocumentType__c=Constants.DOCUMENT_TYPE_ALDAR_SIGNED_SPA;
}
update docsToCOmplete;
DocumentTriggerHandler obj= new DocumentTriggerHandler();
obj.afterUpdateMethod(docsToCOmplete,new map<id,Document__c>(docsToCOmplete),oldList,new map<id,Document__c>(oldList) );
test.stoptest();
}*/
    
    @isTest static void testupdateAccountFromCase() {
        // Account accRecord = [select id from Account limit 1];
        Account accRecord = TestObjectsFactory.getPersonAccountRecord();
        accRecord.CustomerBankName__c = 'Test';
        accRecord.CustomerBankCountry__c = 'United Arab Emirates';
        accRecord.Company__pc = 'ADNOC';
        accRecord.AnnualIncome__pc = 12000000;
        accRecord.Position__pc = 'Banking';
        accRecord.NoofYearswithCompany__pc = 4;
        accRecord.CompanyAddress__pc = 'Sweden';
        accRecord.Industry = 'Construction';
        accRecord.EmploymentStatus__pc  = 'Unemployed';
        accRecord.SourceofFunds__pc = 'Saving';
        accRecord.PassportNumber__pc = 'p2';
        accRecord.VisaUIDNo__pc = 'v2';
       // accRecord.BankName__c = ' ';
        accRecord.BankCountry__c = 'United Arab Emirates';

        insert accRecord;
        Opportunity optyRecord = [select id,AccountId from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        unitrecord.Status__c = 'Sold';
        update unitrecord;
        Project__c projectRecord= [select id from Project__c limit 1];
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,accRecord.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert objSRStatus;
        Id recordTypeId = Utilities.getRecordTypeId('Case', 'Standard Case');
        Case caseRecord = TestObjectsFactory.getCaseRecord(recordTypeId, Constants.PAYMENT_EXTENSION_TYPE, unitrecord.Id, 'Phone');
        caseRecord.Subject = 'Test Subject';
        caseRecord.AccountId = accRecord.id;
        caseRecord.EmploymentStatus__c = 'Unemployed';
        caseRecord.MobileCountryCode__c = '971';
        caseRecord.MaritalStatus__c = 'Married';
        caseRecord.Position__c = 'Banking';
        caseRecord.MobileNumber__c = '547934361';
        caseRecord.Company__c = 'ADNOC';
        caseRecord.NumberOfYearsWithCompany__c = 6;
        caseRecord.PassportNumber__c = '123';
        caseRecord.ResidentStatus__c = 'Resident';
        caseRecord.CompanyAddress__c = 'Soft wear Specialist';
        caseRecord.AnnualIncome__c = 6600000;
        //insert caseRecord;
        //salesOrderRecord.Project__c=projectRecord.Id;
        salesOrderRecord.SellingPrice__c=1000000;
        salesOrderRecord.ExternalCommissionAmount__c=10000;
        salesOrderRecord.Status__c = Constants.UNIT_STATUS_SOLD;
        salesOrderRecord.Account__c=optyRecord.AccountId;
        salesOrderRecord.ReceiptAcknowledgementPaymentMethod__c='Online';
        salesOrderRecord.RAcknowledgementReservationAmount__c=10000;
        // insert salesOrderRecord;
        //Add GTC under SO
        Document__c docRecord= new Document__c(Case__c=caseRecord.Id,DocumentType__c=Constants.DOCUMENT_TYPE_GTC);
        insert docRecord;
        test.startTest();
        list<Document__c> docsToCOmplete = [select id,Suspensions_Warning__c,SalesOrder__c,GenerateDocument__c,ExpressionofInterest__c,Status__c, Case__c, Opportunity__c,IsEmailSenttoADHA__c,DocumentType__c,ProjectName__c,Quote__c  from Document__c where Case__c=:caseRecord.Id];
        list<Document__c> oldList = new list<Document__c>();
        System.assertEquals(docsToCOmplete.isEmpty(),false);
        for(Document__c doc : docsToCOmplete){
            oldList.add(doc.clone(true,true,true,false));
            doc.Status__c=Constants.DOCUMENT_STATUS_UPLOADED;
            doc.DocumentType__c=Constants.DOCUMENT_TYPE_SIGNED_CIS;
        }
        update docsToCOmplete;
        DocumentTriggerHandler obj= new DocumentTriggerHandler();
        obj.afterUpdateMethod(docsToCOmplete,new map<id,Document__c>(docsToCOmplete),oldList,new map<id,Document__c>(oldList) );
        test.stoptest();
    }
    //Testing EOI documents
    @isTest static void testEOIDocument() {
        Account accRecord = [select id from Account limit 1];
        Opportunity optyRecord = [select id,AccountId from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        Project__c projectRecord= [select id from Project__c limit 1];
        BuildingSection__c buildingRecord= [select id from BuildingSection__c limit 1];
        OpportunityEOI__c eoiRecord= new OpportunityEOI__c ();
        eoiRecord.Account__c = optyRecord.AccountId;
        eoiRecord.BuildingSectionName__c =buildingRecord.Id;
        eoiRecord.Opportunity__c =optyRecord.Id;
        eoiRecord.PaymentMode__c ='Online';
        eoiRecord.InterestFee__c=100;
        eoiRecord.ProjectName__c = projectRecord.Id; 
        eoiRecord.UnitModel__c=OpportunityEOI__c.UnitModel__c.getDescribe().getPicklistValues()[0].getValue();
        eoiRecord.PriceRangeFrom__c=100000;
        eoiRecord.PriceRangeTo__c=10000000;
        eoiRecord.UnitFeatures__c=OpportunityEOI__c.UnitFeatures__c.getDescribe().getPicklistValues()[0].getValue();
        insert eoiRecord;
        
        test.startTest();
        
        list<Document__c> docsToCOmplete = [select id,Suspensions_Warning__c,Status__c,SalesOrder__c,GenerateDocument__c,ExpressionofInterest__c, Case__c, Opportunity__c,IsEmailSenttoADHA__c,DocumentType__c,ProjectName__c,Quote__c from Document__c where ExpressionofInterest__c=:eoiRecord.Id];
        System.assertEquals(docsToCOmplete.isEmpty(),false);
        list<Document__c> oldList = new list<Document__c>();
        for(Document__c doc : docsToCOmplete){
            oldList.add(doc.clone(true,true,true,false));
            doc.Status__c=Constants.DOCUMENT_STATUS_COMPLETED;
            
        }
        update docsToCOmplete;
        DocumentTriggerHandler obj= new DocumentTriggerHandler();
        obj.afterUpdateMethod(docsToCOmplete,new map<id,Document__c>(docsToCOmplete),oldList,new map<id,Document__c>(oldList) );
        test.stoptest();
    }
    /*@isTest
    static void testEsign() {
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator']; // Replace with appropriate profile
        User testUser = new User(
        Alias = 'user12',
        Email = 'testuser1232@example.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Test',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = testProfile.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        UserName = 'testuser2342@example.com'
        );
        insert testUser;
        
        // Assign permission sets to the test user
        PermissionSet psSender = [SELECT Id,Name FROM PermissionSet Where Name = 'DocuSign_Sender' Limit 1];
        PermissionSet psUser = [SELECT Id FROM PermissionSet WHERE Name = 'DocuSign_User' LIMIT 1];
        PermissionSetAssignment psaSender = new PermissionSetAssignment(
        AssigneeId = testUser.Id,
        PermissionSetId = psSender.Id
        );
        PermissionSetAssignment psaUser = new PermissionSetAssignment(
        AssigneeId = testUser.Id,
        PermissionSetId = psUser.Id
        );
        insert psaSender;
        insert psaUser;
        
        // Rest of your test method logic goes here
        // Ensure you run your tests as the test user
        System.runAs(testUser) {
        // Ensure necessary data setup
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID;
        orgAcc.Email__c = 'Ali.athamneh@pwc.com';
        insert orgAcc;
                Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        conRecord.Email = 'Ali.athamneh@pwc.com';
        update conRecord;
        
            //User agencyAdminUser = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN, 'pdbaa');
//agencyAdminUser.contactId=conRecord.Id;
//agencyAdminUser.UserRoleId = role.Id;
//insert agencyAdminUser;
         
         Account acc = TestObjectsFactory.getPersonAccountRecord();
         acc.CustomerBankName__c = 'Test';
         acc.CustomerBankCountry__c = 'United Arab Emirates';
         acc.NationalIdNumber__pc = '111112222255555';
         acc.VisaUIDNo__pc = '222223333366666'; 
         insert acc;
         
         Opportunity optyRecord = TestObjectsFactory.getOpportunityRecord(acc.Id);
         optyRecord .BrokerAgentContact__c=conRecord.Id;
         optyRecord .BrokerAgencyAccount__c =orgAcc.Id;
         optyRecord .Contact__c=conRecord.Id;
         insert optyRecord ;
         
         Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
         insert projectRecord;
         
         test.startTest();
         //Add GTC under project
         
            BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
            insert buildingRecord;
            
            Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
            insert unitrecord;
            
            SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.Id, orgAcc.Id);
            salesOrderRecord.Unit__c = unitrecord.Id;
            salesOrderRecord.SellingPrice__c = 1000000;
            salesOrderRecord.ExternalCommissionAmount__c = 10000;
            salesOrderRecord.Status__c = Constants.UNIT_STATUS_SOLD;
            salesOrderRecord.Account__c = optyRecord.AccountId;
            salesOrderRecord.ReceiptAcknowledgementPaymentMethod__c = 'Online';
            salesOrderRecord.RAcknowledgementReservationAmount__c = 10000;
            salesOrderRecord.SubStatus__c = Constants.STATUS_APPROVED;
            insert salesOrderRecord;
            
            Document__c docRecord= new Document__c(Project__c=projectRecord.Id, SendForESign__c = true,DocumentType__c = Constants.DOCUMENT_TYPE_RA,SalesOrder__c = salesOrderRecord.Id);
            insert docRecord;
            OpportunityUnitSearchController.uploadFile(Blob.valueOf('Test').toString(),docRecord.DocumentType__c,docRecord.id);
            
            
         
        try {
            // Mock the DocuSign API call
            dfsle.TestUtils.setMock(new dfsle.ESignatureAPIMock());
    
            // Retrieve documents related to the Sales Order
            List<Document__c> docsToComplete = [
                SELECT Id, SalesOrder__c, GenerateDocument__c, DocumentType__c, ExpressionofInterest__c, Status__c, Case__c 
                FROM Document__c 
                WHERE SalesOrder__c = :salesOrderRecord.Id AND DocumentType__c = :Constants.DOCUMENT_TYPE_RA
            ];
    
            // Assert that documents are found
            System.assertNotEquals(docsToComplete.size(), 0, 'Expected documents to process');
    
            // Process each document for eSign
            Set<Id> raDocId = new Set<Id>();
            for (Document__c doc : docsToComplete) {
                OpportunityUnitSearchController.uploadFile(Blob.valueOf('Test').toString(), doc.DocumentType__c, doc.Id);
                raDocId.add(doc.Id);
            }
    
            // If documents are present, invoke the processEsign method
            if (!raDocId.isEmpty()) {
               // DocumentTriggerHelper.processEsign(raDocId);
            }
        } catch (dfsle.ValidationException e) {
            // Handle validation exceptions if needed
            System.debug('ValidationException: ' + e.getMessage());
        } catch (dfsle.UnauthorizedException e) {
            // Handle unauthorized exceptions (DocuSign permissions issue)
            System.debug('UnauthorizedException: ' + e.getMessage());
            System.assert(false, 'Unauthorized to send envelopes via DocuSign');
        }
        test.stopTest();
    }
    } */
    
    @isTest
    static void testEsignEOI() {
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User']; // Replace with appropriate profile
        List<PermissionSet> pckgPermissionSet = [SELECT Id FROM PermissionSet WHERE Name IN ('THYNK_API_Read_Write','Thynk_PMS_Connect_User','Thynk_PMS_Connect_Admin')];
        User testUser = new User(
        Alias = 'tuser11',
        Email = 'testuser4556@example.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Test',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = testProfile.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        UserName = 'testuser354232@example.com'
        );
        insert testUser;
        
        // Assign permission sets to the test user
        PermissionSet psSender = [SELECT Id,Name FROM PermissionSet Where Name = 'DocuSign_Sender' Limit 1];
        PermissionSet psUser = [SELECT Id FROM PermissionSet WHERE Name = 'DocuSign_User' LIMIT 1];
        PermissionSetAssignment psaSender = new PermissionSetAssignment(
        AssigneeId = testUser.Id,
        PermissionSetId = psSender.Id
        );
        PermissionSetAssignment psaUser = new PermissionSetAssignment(
        AssigneeId = testUser.Id,
        PermissionSetId = psUser.Id
        );
        insert psaSender;
        insert psaUser;
        List<PermissionSetAssignment> prSetAssignment = new List<PermissionSetAssignment>();
        for(PermissionSet perSet: pckgPermissionSet){
            PermissionSetAssignment permissionSetAssignment1 = new PermissionSetAssignment();
            permissionSetAssignment1.AssigneeId = testUser.Id;
            permissionSetAssignment1.PermissionSetId = perSet.Id;
           	prSetAssignment.add(permissionSetAssignment1);
        }
        if(prSetAssignment.size()>0)
        {
            insert prSetAssignment;
        }
        // Rest of your test method logic goes here
        // Ensure you run your tests as the test user
        System.runAs(testUser) {
        // Ensure necessary data setup
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID;
        orgAcc.Email__c = 'Ali.athamneh@pwc.com';
        insert orgAcc;
        
         Account acc = TestObjectsFactory.getPersonAccountRecord();
         acc.CustomerBankName__c = 'Test';
         acc.CustomerBankCountry__c = 'United Arab Emirates';
         acc.NationalIdNumber__pc = '111112222255555';
         acc.VisaUIDNo__pc = '222223333366666';
         insert acc;
        
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        conRecord.Email = 'Ali.athamneh@pwc.com';
        update conRecord;
        
         Opportunity optyRecord  = TestObjectsFactory.getOpportunityRecord(acc.Id);
         optyRecord .BrokerAgentContact__c=conRecord.Id;
         optyRecord .BrokerAgencyAccount__c =orgAcc.Id;
         optyRecord .Contact__c=conRecord.Id;
         insert optyRecord ;
         
         Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
         insert projectRecord;
         test.startTest();
         //Add GTC under project
         Document__c docRecord= new Document__c(Project__c=projectRecord.Id,DocumentType__c=Constants.DOCUMENT_TYPE_GTC);
         insert docRecord;
         OpportunityUnitSearchController.uploadFile(Blob.valueOf('Test').toString(),docRecord.DocumentType__c,docRecord.id);
         
         BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
         insert buildingRecord;
         Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
         insert unitrecord;
    
        // Create Opportunity EOI record
        OpportunityEOI__c eoiRecord = new OpportunityEOI__c(
            Account__c = optyRecord.AccountId,
            BuildingSectionName__c = buildingRecord.Id,
            Opportunity__c = optyRecord.Id,
            PaymentMode__c = 'Online',
            InterestFee__c = 100,
            ProjectName__c = projectRecord.Id,
            UnitModel__c = OpportunityEOI__c.UnitModel__c.getDescribe().getPicklistValues()[0].getValue(),
            PriceRangeFrom__c = 100000,
            PriceRangeTo__c = 10000000,
            UnitFeatures__c = OpportunityEOI__c.UnitFeatures__c.getDescribe().getPicklistValues()[0].getValue()
        );
        insert eoiRecord;
    
        // Start test execution
        
        try {
            // Mock the DocuSign API call
            dfsle.TestUtils.setMock(new dfsle.ESignatureAPIMock());
    
            // Retrieve documents related to the EOI record
            List<Document__c> docsToComplete = [
                SELECT Id, SalesOrder__c, GenerateDocument__c, DocumentType__c, ExpressionofInterest__c, Status__c, Case__c 
                FROM Document__c 
                WHERE ExpressionofInterest__c = :eoiRecord.Id AND DocumentType__c = 'EOI Agreement'
            ];
    
            // Assert that documents are found
            System.assertNotEquals(docsToComplete.size(), 0, 'Expected documents to process');
    
            // Process each document for eSign
            Set<Id> raDocId = new Set<Id>();
            for (Document__c doc : docsToComplete) {
                OpportunityUnitSearchController.uploadFile(Blob.valueOf('Test').toString(), doc.DocumentType__c, doc.Id);
                raDocId.add(doc.Id);
            }
    
            // If documents are present, invoke the processEsign method
            if (!raDocId.isEmpty()) {
               // DocumentTriggerHelper.processEsign(raDocId);
            }
        } catch (dfsle.ValidationException e) {
            // Handle validation exceptions if needed
            System.debug('ValidationException: ' + e.getMessage());
        } catch (dfsle.UnauthorizedException e) {
            // Handle unauthorized exceptions (DocuSign permissions issue)
            System.debug('UnauthorizedException: ' + e.getMessage());
            System.assert(false, 'Unauthorized to send envelopes via DocuSign');
        }
        test.stopTest();
    }
  }
        //Testing case record
    @isTest static void testCaseRecord() {
        
        Unit__c unitrecord = TestObjectsFactory.unitDataSetup('25083');
        unitrecord.Status__c = 'Sold';
        unitrecord.Name = 'Test';
        insert unitrecord;
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;

        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@gmail.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        test.startTest();
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(opp.ID,acc.Id);
        salesOrderRecord.Unit__c = unitrecord.Id;
        salesOrderRecord.Contact__c = con.Id;
        salesOrderRecord.NetAmount__c = 1000;
        insert salesOrderRecord;

        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert objSRStatus;
        
        Id recordTypeId = Utilities.getRecordTypeId('Case', 'Standard Case');
        Case caseRecord = TestObjectsFactory.getCaseRecord(recordTypeId, Constants.PAYMENT_EXTENSION_TYPE, unitrecord.Id, 'Phone');
        caseRecord.Subject = 'Test Subject';
       // insert caseRecord;
       // DocumentTriggerHelper.updateAccountFromCase(new Set<Id>{caseRecord.Id});
        List<Document__c> lstDocuments = new List<Document__c>();
        Document__c docRecord= new Document__c(SalesOrder__c=salesOrderRecord.Id,DocumentType__c=Constants.DOCUMENT_TYPE_ALDAR_SIGNED_SPA);
        //insert docRecord;
        lstDocuments.add(docRecord);
        
        //Document__c docRecord1= new Document__c(Case__c=caseRecord.Id,DocumentType__c= Constants.DOCUMENT_TYPE_SIGNED_CIS);
        //insert docRecord1;
        //lstDocuments.add(docRecord1);
         
        insert lstDocuments;
        TriggerHandler.processedIds = new Set<Id>();

    

        // docRecord.Status__c = Constants.DOCUMENT_STATUS_UPLOADED;
        // docRecord1.Status__c = Constants.DOCUMENT_STATUS_UPLOADED;
        // update docRecord;
        TriggerHandler.processedIds = new Set<Id>();
        lstDocuments[0].Status__c = Constants.DOCUMENT_STATUS_UPLOADED;
        update lstDocuments[0];

        test.stoptest(); 
    }
    //Testing sales order record
    @isTest static void testSalesOrderRecord() {
            
        Unit__c unitrecord = TestObjectsFactory.unitDataSetup('25083');
        unitrecord.Status__c = 'Sold';
        unitrecord.Name = 'Test';
        insert unitrecord;
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;

        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@gmail.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        test.startTest();
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(opp.ID,acc.Id);
        salesOrderRecord.Unit__c = unitrecord.Id;
        salesOrderRecord.Contact__c = con.Id;
        salesOrderRecord.NetAmount__c = 1000;
        insert salesOrderRecord;

        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert objSRStatus;
        
        Document__c docRecord= new Document__c(SalesOrder__c=salesOrderRecord.Id,DocumentType__c=Constants.DOCUMENT_TYPE_ALDAR_SIGNED_SPA);
        insert docRecord;

        TriggerHandler.processedIds = new Set<Id>();

        try {
            
            docRecord.Status__c = Constants.DOCUMENT_STATUS_UPLOADED;
            update docRecord;   
            
        } catch (Exception ex) {
            System.debug(ex);
        } 
        test.stoptest();
    }

    //Testing resale case record
    @isTest static void testResaleCaseRecord() {
        
        Unit__c unitrecord = TestObjectsFactory.unitDataSetup('25083');
        unitrecord.Status__c = 'Sold';
        unitrecord.Name = 'Test';
        unitrecord.CompletionDate__c = System.today().addDays(7);
        insert unitrecord;
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;

        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@gmail.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        test.startTest();
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(opp.ID,acc.Id);
        salesOrderRecord.Unit__c = unitrecord.Id;
        salesOrderRecord.Contact__c = con.Id;
        salesOrderRecord.NetAmount__c = 1000;
        salesOrderRecord.Status__c = 'Sold';
        insert salesOrderRecord;

        Case caseRecord = TestObjectsFactory.getCaseRecord(ResaleConstants.Resale_Case_RecordTypeId, Constants.PAYMENT_EXTENSION_TYPE, unitrecord.Id, 'Phone');
        caseRecord.Subject = 'Test Subject';
        caseRecord.Unit__c = unitrecord.Id;
        caseRecord.RecordTypeId = ResaleConstants.Resale_Case_RecordTypeId;
        //insert caseRecord;
        
        Document__c docRecord1= new Document__c(Case__c=caseRecord.Id,DocumentType__c= ResaleConstants.CASE_SIGNED_LISTING_AGREEMENT_DOCUMENT_TYPE);
        insert docRecord1;
        
        TriggerHandler.processedIds = new Set<Id>();
        
        
        docRecord1.ProcessResaleCase__c=true;
        update docRecord1;

         test.stoptest();
    }

    //Testing resale case record
    @isTest static void testResaleOppRecord() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetSMSNotificationSuccess');

        Unit__c unitrecord = TestObjectsFactory.unitDataSetup('25083');
        unitrecord.Status__c = 'Sold';
        unitrecord.Name = 'Test';
        unitrecord.CompletionDate__c = System.today().addDays(7);
        insert unitrecord;
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;

        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@gmail.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        test.startTest();
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(opp.ID,acc.Id);
        salesOrderRecord.Unit__c = unitrecord.Id;
        salesOrderRecord.Contact__c = con.Id;
        salesOrderRecord.NetAmount__c = 1000;
        salesOrderRecord.Status__c = 'Sold';
        insert salesOrderRecord;
        
        
        Case caseRecord = TestObjectsFactory.getCaseRecord(ResaleConstants.Resale_Case_RecordTypeId, Constants.PAYMENT_EXTENSION_TYPE, unitrecord.Id, 'Phone');
        caseRecord.Subject = 'Test Subject';
        caseRecord.Unit__c = unitrecord.Id;
        //insert caseRecord;

        
        caseRecord.CustomerContacted__c = true;
        caseRecord.Status = 'Property Listed';
        //update caseRecord;
        
        Opportunity resaleOpp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        resaleOpp.Unit__c = unitrecord.Id;
        resaleOpp.Lead_Type__c = 'Resale';
        resaleOpp.StageName = 'Meeting';
        resaleOpp.RecordTypeId = ResaleConstants.Resale_Opp_RecordTypeId;
        insert resaleOpp;
        
        Document__c docRecord1= new Document__c(Opportunity__c=resaleOpp.Id,DocumentType__c= 'Signed Listing MOU' );
        insert docRecord1;
        
        TriggerHandler.processedIds = new Set<Id>();

        docRecord1.Status__c = Constants.DOCUMENT_STATUS_UPLOADED;
        update docRecord1;
test.stoptest();
         
    }
    
    @isTest private static void kycGenerateDocumentTest(){
        Document__c docu = [SELECT Id,GenerateDocument__c ,Account__c FROM Document__c WHERE (Account__c != null AND DocumentType__c = 'KYC Form'
                            AND GenerateDocument__c = false) OR (DocumentType__c ='Direct Debit registration form' AND DirectDebitRequest__c != null AND  GenerateDocument__c = false) LIMIT 1];
        System.debug('docu docu'+ docu);
        Test.startTest();
        try{
            docu.GenerateDocument__c = true;
            update docu;
        }
        catch(Exception e)
        {
            String message = e.getMessage();            
        }        
        Test.StopTest();
        
    }
    
        @isTest
    public static void testValidateDocumentDebitRequest() {
        Test.startTest();
        List<DirectDebitRequest__c> testDebitRequests = createDirectDebitRequests(2);
        List<KYC_Mandatory_Field__mdt> testKYCFields = createKYCMandatoryFields(2);
        Test.stopTest();
        Set<Id> recordIds = new Set<Id>();
        for (DirectDebitRequest__c dr : testDebitRequests) {
            recordIds.add(dr.Id);
        }
        
        String result = DocumentValidationService.validateDocumentDebitRequest(recordIds);
        
        //System.assertEquals('Expected validation string', result);
    }

    public static List<DirectDebitRequest__c> createDirectDebitRequests(Integer numRecords) {
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V2', 'P2');
        acc.RecordTypeId = recordTypeId;
        //acc.MobilePhone__c = '501234567';
        acc.PersonMobilePhone = '501234567';
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Project__c projectRecord = TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        
        BuildingSection__c buildingRecord = TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        
        Unit__c unit = TestObjectsFactory.getUnitDetail(projectRecord.Id, buildingRecord.Id);
        insert unit;
        
        SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit.Id;
        insert salesOrder1;
        
        List<DirectDebitRequest__c> records = new List<DirectDebitRequest__c>();
        for (Integer i = 0; i < numRecords; i++) {
            DirectDebitRequest__c record = TestObjectsFactory.createDirectDebitRecords(salesOrder1.id);
            record.Account__c = acc.Id;
            record.PayerAccount__c = acc.Id;
            records.add(record);
        }
        insert records;
        return records;
    }

    private static List<KYC_Mandatory_Field__mdt> createKYCMandatoryFields(Integer numRecords) {
        List<KYC_Mandatory_Field__mdt> records = new List<KYC_Mandatory_Field__mdt>();
        for (Integer i = 0; i < numRecords; i++) {
            records.add(new KYC_Mandatory_Field__mdt(
                ObjectName__c = 'DirectDebitRequest__c'
            ));
        }
        return records;
    }
    
    @isTest
    static void testDocumentInvocableMethodForAccount() {
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
            
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V12', 'P12');
        acc.RecordTypeId = recordTypeId;
        //acc.MobilePhone__c = '501234567';
        acc.PersonMobilePhone = '501234567';
        insert acc;
        
        Test.startTest();
        List<String> result = DocumentValidationService.documentInvocableMethod(new List<Id>{acc.Id});
        Test.stopTest();
    }
    
    @isTest
    static void testDocumentInvocableMethodForDirectDebitRequest() {
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V2', 'P2');
        acc.RecordTypeId = recordTypeId;
        //acc.MobilePhone__c = '501234567';
        acc.PersonMobilePhone = '501234567';
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Project__c projectRecord = TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        
        BuildingSection__c buildingRecord = TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        
        Unit__c unit = TestObjectsFactory.getUnitDetail(projectRecord.Id, buildingRecord.Id);
        insert unit;
        Test.startTest();
        SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit.Id;
        insert salesOrder1;
        
            DirectDebitRequest__c record = TestObjectsFactory.createDirectDebitRecords(salesOrder1.id);
            record.Account__c = acc.Id;
            record.PayerAccount__c = acc.Id;
            insert record;
        
        
        List<String> result = DocumentValidationService.documentInvocableMethod(new List<Id>{record.Id});
        Test.stopTest();
    }
    
    @isTest
    static void testDocumentInvocableMethodWithMultipleIds() {
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V2', 'P2');
        acc.RecordTypeId = recordTypeId;
        //acc.MobilePhone__c = '501234567';
        acc.PersonMobilePhone = '501234567';
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Project__c projectRecord = TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        
        BuildingSection__c buildingRecord = TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        
        Unit__c unit = TestObjectsFactory.getUnitDetail(projectRecord.Id, buildingRecord.Id);
        insert unit;
        Test.startTest();
        SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit.Id;
        insert salesOrder1;
        
            DirectDebitRequest__c record = TestObjectsFactory.createDirectDebitRecords(salesOrder1.id);
            record.Account__c = acc.Id;
            record.PayerAccount__c = acc.Id;
            insert record;
        
        
        List<String> result = DocumentValidationService.documentInvocableMethod(new List<Id>{acc.Id, record.Id});
        Test.stopTest();
    }
    
    @isTest
    static void testDocumentInvocableMethodWithInvalidObjectType() {
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V2', 'P2');
        acc.RecordTypeId = recordTypeId;
        //acc.MobilePhone__c = '501234567';
        acc.PersonMobilePhone = '501234567';
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Test.startTest();
        List<String> result = DocumentValidationService.documentInvocableMethod(new List<Id>{opp.Id});
        Test.stopTest();
    }

    @isTest 
    public static void updateDocumentURLToSuspensionWarningTest(){
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO2022021156gdyw');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
        insert orgAcc;

        List<Suspensions_Warning__c> suspensions = new List<Suspensions_Warning__c>();
        suspensions.add(new Suspensions_Warning__c(
            BrokerAgency__c = orgAcc.Id,
            SuspensionApprovalStatus__c = 'Submitted for Suspension Approval',
            SuspensionWarning__c = 'Warning'
        ));
        
        suspensions[0].LeadRegistrationSubCategory__c = 'Broker Register as Customer W/O Consent';
        suspensions[0].CommissionSubCategory__c = 'Failure to Sign the Broker Form';
        suspensions[0].LegalMattersSubCategory__c = 'Broker attempting to disguise illegal funds';
        suspensions[0].DisputesSubCategory__c = 'Soliciting customers to interfere on a final decision given by Aldar on dispute cases.';
        suspensions[0].BusinessEthicsSubCategory__c = 'Brokers using inappropriate, coarse, offensive language';
        suspensions[0].MarketingAndCommunicationsSubCategory__c = 'Failure to follow Aldar’s corporate brand guidelines.';
        suspensions[0].BrokerRegistrationSubCategory__c = 'If broker refuses to register on GoAML register';
        suspensions[0].PropertyViewingsSubCategory__c = 'Brokers not behaving appropriately and not following rules';
        // suspensions[0].ResaleSubCategory__c = 'Brokers advertisement about any of Aldar’s project in the secondary market';
        suspensions[0].ConfidentialityInfoFailureSubCategory__c = 'Mishandling or disclosing confidential information about clients or transactions.';
        suspensions[0].PublishingWoConsentSubCategory__c = 'Unapproved official PR communication on any platform';
        suspensions[0].OtherReasonforSuspension__c = 'Test';

        insert suspensions;

        Document__c docRecord1 = new Document__c(Suspensions_Warning__c=suspensions[0].Id,
                                                DocumentType__c = 'Warning Letter Draft');
        insert docRecord1;
        
        Test.startTest();
        docRecord1.Status__c = Constants.DOCUMENT_STATUS_UPLOADED;
        //update docRecord1;
       // DocumentTriggerHelper.updateDocumentURLToSuspensionWarning(new Map<Id,Id>{docRecord1.Id=>suspensions[0].Id});
        Test.stopTest();
    }
    
    @isTest static void testupdateAccountFromCases() {
        Account accRecord = TestObjectsFactory.getPersonAccountRecord();
        accRecord.CustomerBankName__c = 'Test';
        accRecord.CustomerBankCountry__c = 'United Arab Emirates';
        accRecord.Company__pc = 'ADNOC';
        accRecord.AnnualIncome__pc = 12000000;
        accRecord.Position__pc = 'Banking';
        accRecord.NoofYearswithCompany__pc = 4;
        accRecord.CompanyAddress__pc = 'Sweden';
        accRecord.Industry = 'Construction';
        accRecord.EmploymentStatus__pc  = 'Unemployed';
        accRecord.SourceofFunds__pc = 'Saving';
        accRecord.PassportNumber__pc = 'p2';
        accRecord.VisaUIDNo__pc = 'v2';
        accRecord.BankCountry__c = 'United Arab Emirates';
        insert accRecord;
        
        Opportunity optyRecord = [select id,AccountId from opportunity limit 1];
        
        Project__c projectRecord2 = TestObjectsFactory.getProjectRecord('Mayan');
        projectRecord2.Name = 'Balghaiylam';
        insert projectRecord2;
        test.StartTest();
        Unit__c unitrecord = [select id from Unit__c limit 1];
        unitrecord.Status__c = 'Sold';
        unitrecord.Project__c = projectRecord2.Id;
        update unitrecord;
        
        Project__c projectRecord= [select id from Project__c limit 1];
        
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,accRecord.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        
        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert objSRStatus;
        
        Id recordTypeId = Utilities.getRecordTypeId('Case', 'Standard Case');
        Case caseRecord = TestObjectsFactory.getCaseRecord(recordTypeId, Constants.PAYMENT_EXTENSION_TYPE, unitrecord.Id, 'Phone');
        caseRecord.Subject = 'Test Subject';
        caseRecord.AccountId = accRecord.id;
        caseRecord.EmploymentStatus__c = 'Unemployed';
        caseRecord.MobileCountryCode__c = '971';
        caseRecord.MaritalStatus__c = 'Married';
        caseRecord.Position__c = 'Banking';
        caseRecord.MobileNumber__c = '547934361';
        caseRecord.Company__c = 'ADNOC';
        caseRecord.NumberOfYearsWithCompany__c = 6;
        caseRecord.PassportNumber__c = '123';
        caseRecord.ResidentStatus__c = 'Resident';
        caseRecord.CompanyAddress__c = 'Soft wear Specialist';
        caseRecord.AnnualIncome__c = 6600000;
        //insert caseRecord;
        
       	//salesOrderRecord.Project_Id__c=projectRecord2.Id;
        salesOrderRecord.SellingPrice__c=1000000;
        salesOrderRecord.ExternalCommissionAmount__c=10000;
        salesOrderRecord.Status__c = Constants.UNIT_STATUS_SOLD;
        salesOrderRecord.Account__c=optyRecord.AccountId;
        salesOrderRecord.ReceiptAcknowledgementPaymentMethod__c='Online';
        salesOrderRecord.RAcknowledgementReservationAmount__c=10000;
        insert salesOrderRecord;
        //Add GTC under SO
        
        Document__c docRecord= new Document__c(Case__c=caseRecord.Id,DocumentType__c=Constants.DOCUMENT_TYPE_SIGNED_RA, Project__c = projectRecord2.Id, SalesOrder__c = salesOrderRecord.Id);
        insert docRecord;
        
         // Create a ContentVersion (this also creates the ContentDocument)
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test File', 
            PathOnClient = 'TestFile.pdf', 
            VersionData = Blob.valueOf('Sample file content'),
            IsMajorVersion = true
        );
        insert testContentVersion;
        
        // Retrieve the ContentDocument associated with the ContentVersion
        ContentDocument testContentDocument = [
            SELECT Id
            FROM ContentDocument
            LIMIT 1
        ];
               
        
        
        // Create a ContentDocumentLink to link the ContentDocument to the Account
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = testContentDocument.Id,
            LinkedEntityId = docRecord.Id,
            ShareType = 'V' // V = Viewer access, C = Collaborator access, etc.
        );
        
        // Insert the ContentDocumentLink
        insert testContentDocumentLink;
        
        list<Document__c> docsToCOmplete = [select id,Suspensions_Warning__c,SalesOrder__c,GenerateDocument__c,ExpressionofInterest__c,Status__c, Case__c, Opportunity__c,IsEmailSenttoADHA__c,DocumentType__c,ProjectName__c,Quote__c  from Document__c where Case__c=:caseRecord.Id];
        list<Document__c> oldList = new list<Document__c>();
        
        
        for(Document__c doc : docsToCOmplete){
            oldList.add(doc.clone(true, true, true, false));
            doc.Status__c='Completed';
            doc.DocumentType__c=Constants.DOCUMENT_TYPE_SIGNED_RA;
        }
        update docsToCOmplete;
        
        DocumentTriggerHandler obj= new DocumentTriggerHandler();
        obj.afterUpdateMethod(docsToCOmplete, new map<id,Document__c>(docsToCOmplete), oldList, new map<id,Document__c>(oldList));
        test.Stoptest();
    }
    
    /*@isTest static void testUpdateAccountFromCaseMethod() {
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;

        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@gmail.com';
        update con;
        
        
        test.startTest();
		Case caseRecord = new Case();
        caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Home_Finance').getRecordTypeId();
        caseRecord.CaseCategory__c = 'Home Finance';
        caseRecord.CaseComments__c = 'Home Finance Parent Case';
        caseRecord.Status = 'New';
        caseRecord.SubVertical__c = 'Home Finance';
        caseRecord.AccountId = acc.Id;
        insert caseRecord;
        try{
           // DocumentTriggerHelper.updateAccountFromCase(new Set<Id>{caseRecord.Id});
        } catch(exception ex){}
        
        test.stoptest();
    } */
    
    
    /**
* Test method for updateAccountFromCase - SIMPLE WORKING VERSION
* Tests the updateAccountFromCase method directly
*/
    /**
* Test method for updateAccountFromCase - DIRECT METHOD TEST (RECOMMENDED)
* Tests the updateAccountFromCase method logic without Case triggers
*/
    /*@isTest
static void testUpdateAccountFromCaseComplete_Corrected() {
Test.startTest();

// Create test Account
Account testAcc = new Account(Name = 'Test Account', Email__c = 'oldemail@test.com', MobileNumber__c = '971500000000');
insert testAcc;

// Create and insert a real Case (do NOT assign Case.Id = Account.Id)
Case caseRecord = new Case(
Subject = 'Test Case Subject',
AccountId = testAcc.Id,
Email__c = 'newemail@test.com',
MobileNumber__c = '501234567',
MobileCountryCode__c = '971',
Status = 'New',
Origin = 'Email'
);

try {
insert caseRecord;
} catch (DmlException e) {
// Likely a Flow/process error (Case Trigger Flow). Fail with a helpful message.
// Ask admin to deactivate/modify the flow or make it test-safe, then re-run tests.
System.assert(false,
'Case insert failed during test; likely cause: an org Flow/Process running on Case insert. ' +
'Please disable or update the "Case Trigger Flow" in sandbox (or change its criteria) and re-run tests. ' +
'Original error: ' + e.getMessage()
);
// Execution will stop here because of the assert
Test.stopTest();
return;
}

// Create Document linked to the inserted Case
Document__c docRecord = new Document__c(
Case__c = caseRecord.Id,
DocumentType__c = Constants.DOCUMENT_TYPE_SIGNED_CIS,
Status__c = 'New'
);
insert docRecord;

// Fetch and update to simulate trigger flow
List<Document__c> docsToUpdate = [
SELECT Id, Status__c, Case__c, DocumentType__c
FROM Document__c
WHERE Case__c = :caseRecord.Id
LIMIT 1
];

System.assertEquals(1, docsToUpdate.size(), 'Should have 1 document');

List<Document__c> oldDocList = new List<Document__c>();
oldDocList.add(new Document__c(
Id = docsToUpdate[0].Id,
Status__c = 'New',
Case__c = docsToUpdate[0].Case__c,
DocumentType__c = docsToUpdate[0].DocumentType__c
));

docsToUpdate[0].Status__c = Constants.DOCUMENT_STATUS_UPLOADED;
update docsToUpdate;

// Call handler directly (same as trigger would)
DocumentTriggerHandler handler = new DocumentTriggerHandler();
handler.afterUpdateMethod(
docsToUpdate,
new Map<Id, Document__c>(docsToUpdate),
oldDocList,
new Map<Id, Document__c>(oldDocList)
);

Test.stopTest();

// Verify account got updated by the method
Account updatedAcc = [SELECT Id, Email__c, MobileNumber__c FROM Account WHERE Id = :testAcc.Id];
System.assertEquals('newemail@test.com', updatedAcc.Email__c);
System.assertEquals('971501234567', updatedAcc.MobileNumber__c);

// Verify case closed
Case updatedCase = [SELECT Id, Status FROM Case WHERE Id = :caseRecord.Id];
System.assertEquals(Constants.CLOSED_CASE, updatedCase.Status);
} */
    
    
    
   /* @isTest
    static void testUpdateAccountFromCaseComplete_Corrected() {
        Test.startTest();
        
        // Create test Account
        Account testAcc = new Account(Name = 'Test Account', Email__c = 'oldemail@test.com', MobileNumber__c = '971500000000');
        insert testAcc;
        
        // Create and insert a real Case (do NOT assign Case.Id = Account.Id)
        Case caseRecord = new Case(
            Subject = 'Test Case Subject',
            AccountId = testAcc.Id,
            Email__c = 'newemail@test.com',
            MobileNumber__c = '501234567',
            MobileCountryCode__c = '971',
            Status = 'New',
            Origin = 'Email'
        );
        
        try {
            insert caseRecord;
        } catch (DmlException e) {
            System.assert(false,
                          'Case insert failed during test; likely cause: an org Flow/Process running on Case insert. ' +
                          'Please disable or update the "Case Trigger Flow" in sandbox (or change its criteria) and re-run tests. ' +
                          'Original error: ' + e.getMessage()
                         );
            Test.stopTest();
            return;
        }
        
        // Create Document linked to the inserted Case
        Document__c docRecord = new Document__c(
            Case__c = caseRecord.Id,
            DocumentType__c = Constants.DOCUMENT_TYPE_SIGNED_CIS,
            Status__c = 'New'
        );
        insert docRecord;
        
        // Fetch and update to simulate trigger flow - INCLUDE ALL FIELDS
        List<Document__c> docsToUpdate = [
            SELECT Id, 
            Status__c, 
            Case__c, 
            DocumentType__c,
            ProjectName__c,
            Account__c,
            SalesOrder__c,
            ExpressionofInterest__c,
            DirectDebitRequest__c,
            Quote__c,
            Suspensions_Warning__c,
            Conga_template__c,
            GenerateDocument__c,
            Opportunity__c,
            IsEmailSenttoADHA__c
            FROM Document__c
            WHERE Case__c = :caseRecord.Id
            LIMIT 1
        ];
        
        System.assertEquals(1, docsToUpdate.size(), 'Should have 1 document');
        
        List<Document__c> oldDocList = new List<Document__c>();
        oldDocList.add(new Document__c(
            Id = docsToUpdate[0].Id,
            Status__c = 'New',
            Case__c = docsToUpdate[0].Case__c,
            DocumentType__c = docsToUpdate[0].DocumentType__c,
            //  ProjectName__c = docsToUpdate[0].ProjectName__c,
            Account__c = docsToUpdate[0].Account__c,
            SalesOrder__c = docsToUpdate[0].SalesOrder__c,
            ExpressionofInterest__c = docsToUpdate[0].ExpressionofInterest__c,
            DirectDebitRequest__c = docsToUpdate[0].DirectDebitRequest__c,
            Quote__c = docsToUpdate[0].Quote__c,
            Suspensions_Warning__c = docsToUpdate[0].Suspensions_Warning__c,
            Conga_template__c = docsToUpdate[0].Conga_template__c,
            GenerateDocument__c = docsToUpdate[0].GenerateDocument__c,
            Opportunity__c = docsToUpdate[0].Opportunity__c,
            IsEmailSenttoADHA__c = docsToUpdate[0].IsEmailSenttoADHA__c
        ));
        
        docsToUpdate[0].Status__c = Constants.DOCUMENT_STATUS_UPLOADED;
        update docsToUpdate;
        
        // Call handler directly (same as trigger would)
        DocumentTriggerHandler handler = new DocumentTriggerHandler();
        handler.afterUpdateMethod(
            docsToUpdate,
            new Map<Id, Document__c>(docsToUpdate),
            oldDocList,
            new Map<Id, Document__c>(oldDocList)
        );
        
        Test.stopTest();
        
        // Verify account got updated by the method
        Account updatedAcc = [SELECT Id, Email__c, MobileNumber__c FROM Account WHERE Id = :testAcc.Id];
        System.assertEquals('newemail@test.com', updatedAcc.Email__c);
        System.assertEquals('971501234567', updatedAcc.MobileNumber__c);
        
        // Verify case closed
        Case updatedCase = [SELECT Id, Status FROM Case WHERE Id = :caseRecord.Id];
        System.assertEquals(Constants.CLOSED_CASE, updatedCase.Status);
    }  */
    
    
    
    @isTest
    static void testUpdateAccountFromCase_CoversPersonAccountBranch() {
        Test.startTest();
        
        // Get Person Account RecordTypeId via RecordType object (safe)
        RecordType personRT = [
            SELECT Id 
            FROM RecordType 
            WHERE SobjectType = 'Account' AND IsPersonType = true
            LIMIT 1
        ];
        Id personAccountRTId = personRT.Id;
        
        // Create a Person Account (set RecordTypeId and required person fields)
        Account personAcc = new Account(
            RecordTypeId = personAccountRTId,
            FirstName = 'Test',
            LastName  = 'Person',
            PersonEmail = 'before@test.com'
        );
        insert personAcc;
        Account acc = [SELECT Id,personContactId FROM Account WHERE Id=:personAcc.Id];
        // Create Case linked to the Person Account; fill fields the method copies
        Case c = new Case(
            Subject = 'Person Account Update Case',
            AccountId = personAcc.Id,
            PassportNumber__c = 'P-111222',
            ResidentStatus__c = 'Resident',
            MaritalStatus__c = 'Married',
            EmploymentStatus__c = 'Employed',
            Email__c = 'newperson@example.com',
            MobileCountryCode__c = '971',
            MobileNumber__c = '500123456',
            Company__c = 'AcmeCorp',
            Position__c = 'Engineer',
            CompanyAddress__c = 'Office St',
            AnnualIncome__c = 120000,
            NumberOfYearsWithCompany__c = 3,
            Industry__c = 'Construction',
            Status = 'New',
            Origin = 'Phone',
            ContactId =acc.personContactId
        );
        insert c;
        
        // Create Document__c linked to the Case
        Document__c doc = new Document__c(
            Case__c = c.Id,
            DocumentType__c = Constants.DOCUMENT_TYPE_SIGNED_CIS,
            Status__c = 'New'
        );
        insert doc;
        
        // Re-query doc including fields referenced by handler
        List<Document__c> docsToUpdate = [
            SELECT Id, Status__c, Case__c, DocumentType__c,
            ProjectName__c, Account__c, SalesOrder__c, ExpressionofInterest__c,
            DirectDebitRequest__c, Quote__c, Suspensions_Warning__c,
            Conga_template__c, GenerateDocument__c, Opportunity__c, IsEmailSenttoADHA__c
            FROM Document__c
            WHERE Id = :doc.Id
            LIMIT 1
        ];
        
        // Old snapshot
        List<Document__c> oldList = new List<Document__c>{
            new Document__c(
                Id = docsToUpdate[0].Id,
                Status__c = 'New',
                Case__c = docsToUpdate[0].Case__c,
                DocumentType__c = docsToUpdate[0].DocumentType__c
            )
                };
                    
                    // Update document status to Uploaded -> causes handler logic to run
                    docsToUpdate[0].Status__c = Constants.DOCUMENT_STATUS_UPLOADED;
        update docsToUpdate;
        
        // Call handler directly (same as trigger)
        DocumentTriggerHandler handler = new DocumentTriggerHandler();
        handler.afterUpdateMethod(
            docsToUpdate,
            new Map<Id, Document__c>(docsToUpdate),
            oldList,
            new Map<Id, Document__c>(oldList)
        );
        
        Test.stopTest();
        
        
        
    }
    
    
  /*  @isTest
    static void testUpdateAccountFromCase_CoversElseBranch_DirectCall() {
        Test.startTest();
        Account orgAcc = new Account(Name = 'Org Else Branch Test', Email__c = 'before@org.com');
        insert orgAcc;
        
        Case orgCase = new Case(
            Subject = 'Org Case for Else Branch',
            AccountId = orgAcc.Id,
            Email__c = 'orgnew@example.com',
            MobileNumber__c = '501234567',
            MobileCountryCode__c = '971',
            Status = 'New',
            Origin = 'Phone'
        );
        insert orgCase;
        
        try {
            DocumentTriggerHandler.updateAccountFromCase(new Set<Id>{ orgCase.Id });
        } catch (Exception e) {
            System.assert(false, 'updateAccountFromCase threw exception: ' + e.getMessage());
        }
        
        Test.stopTest();
        
        Account updatedOrg = [
            SELECT Id, Email__c, EmailAddress__c, MobileNumber1__c, MobileNumber__c, MobileNumberEnc__c
            FROM Account
            WHERE Id = :orgAcc.Id
            LIMIT 1
        ];
        
        Case updatedCase = [SELECT Id, Status FROM Case WHERE Id = :orgCase.Id LIMIT 1];
        
        System.assertEquals('orgnew@example.com', updatedOrg.Email__c, 'Email__c should be copied from Case');
        System.assertEquals('orgnew@example.com', updatedOrg.EmailAddress__c, 'EmailAddress__c should be copied from Case');
        System.assertEquals('501234567', updatedOrg.MobileNumber1__c, 'MobileNumber1__c should be copied from Case');
        System.assertEquals('971501234567', updatedOrg.MobileNumber__c, 'MobileNumber__c should be country + number');
        System.assertEquals('501234567', updatedOrg.MobileNumberEnc__c, 'MobileNumberEnc__c should be raw mobile number');
        
        System.assertEquals(Constants.CLOSED_CASE, updatedCase.Status, 'Case should be closed by updateAccountFromCase');
    } */
    
    
    @isTest
static void test_updateDocumentURLToSuspensionWarning() {
    // --------------------------------------------------------
    // 1️⃣ Create a dummy Suspension record
    // --------------------------------------------------------
    Suspensions_Warning__c susp = new Suspensions_Warning__c(
      //  Name = 'Test Suspension' // Auto number field
      SuspensionWarning__c = 'Suspension'
    );
    insert susp;

    // --------------------------------------------------------
    // 2️⃣ Create a dummy ContentDocument + ContentVersion
    // --------------------------------------------------------
    ContentVersion cv = new ContentVersion(
        Title = 'TestFile',
        PathOnClient = 'TestFile.pdf',
        VersionData = Blob.valueOf('Sample'),
        IsMajorVersion = true
    );
    insert cv;

    // Get ContentDocument Id
    Id contentDocId = [SELECT ContentDocumentId 
                       FROM ContentVersion 
                       WHERE Id = :cv.Id].ContentDocumentId;

    // --------------------------------------------------------
    // 3️⃣ Link the ContentDocument to the Suspension record
    // --------------------------------------------------------
    ContentDocumentLink cdl = new ContentDocumentLink(
        ContentDocumentId = contentDocId,
        LinkedEntityId   = susp.Id,
        ShareType        = 'V',
        Visibility       = 'InternalUsers'
    );
    insert cdl;

    // --------------------------------------------------------
    // 4️⃣ Prepare map needed by the method
    //    mapDocumentToSuspension.put(DocumentId → SuspensionId)
    // --------------------------------------------------------
    Map<Id,Id> mapDocToSusp = new Map<Id,Id>{
        susp.Id => susp.Id
    };

    // --------------------------------------------------------
    // 5️⃣ Call method
    // --------------------------------------------------------
    Test.startTest();
    DocumentTriggerHandler.updateDocumentURLToSuspensionWarning(mapDocToSusp);
    Test.stopTest();

    // --------------------------------------------------------
    // 6️⃣ Verify Updated URL
    // --------------------------------------------------------
    Suspensions_Warning__c updated = [
        SELECT DocumentURL__c FROM Suspensions_Warning__c WHERE Id = :susp.Id
    ];

    System.assertNotEquals(null, updated.DocumentURL__c, 'URL should be populated');
    System.assert(
        updated.DocumentURL__c.contains('/lightning/r/ContentDocument/'),
        'Document URL must contain ContentDocument path'
    );
}
/*@isTest
static void test_checkQuery() {

    
    Project__c proj = new Project__c(
        Name = 'Test Project',
        BusinessUnitId__c = 'BU001',
        ProjectCode__c = 'PRJ001'
    );
    insert proj;

 
    Unit__c unitRec = new Unit__c(
        Name = 'Test Unit',
        Project__c = proj.Id,
        BuildingSectionName__c = 'Test Section',
        UnitType__c = 'Apartment'
    );
    insert unitRec;


    SalesOrder__c so = new SalesOrder__c(
        Unit__c = unitRec.Id
    );
    insert so;


    DocumentPlaceHolder__mdt md = new DocumentPlaceHolder__mdt(
        Query_Filter__c = 'SELECT Id FROM SalesOrder__c WHERE Id != null'
    );


    Boolean result = DocumentTriggerHandler.checkQuery(md, so.Id);

    System.assertEquals(true, result);
}*/

}