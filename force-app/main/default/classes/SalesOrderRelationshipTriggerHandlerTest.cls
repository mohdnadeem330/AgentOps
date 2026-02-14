@isTest
public class SalesOrderRelationshipTriggerHandlerTest {   

    @isTest
    static void testValidateDuplicatesForThridParty() {
        Id thirdPartyRecordTypeId = Schema.SObjectType.Sales_Order_Relationship__c
            .getRecordTypeInfosByName().get('Third Party').getRecordTypeId();

        // SO Account
        Account acc1 = TestObjectsFactory.getAccountRecord('Organization Account', false, '123223376');
        insert acc1;

        // Third party Account (different from SO account)
        Account acc2 = TestObjectsFactory.getAccountRecord('Organization Account', false, '123223377');
        insert acc2;

        List<Document__c> lstDoc = new List<Document__c>{
            new Document__c(Account__c = acc2.Id, DocumentType__c = 'Passport Copy',       Status__c = 'Uploaded'),
            new Document__c(Account__c = acc2.Id, DocumentType__c = 'Signed KYC Form',     Status__c = 'Uploaded'),
            new Document__c(Account__c = acc2.Id, DocumentType__c = 'National ID Back Copy',  Status__c = 'Uploaded'),
            new Document__c(Account__c = acc2.Id, DocumentType__c = 'National ID Front Copy', Status__c = 'Uploaded')
        };
        insert lstDoc;

        ContentVersion cv = TestObjectsFactory.getContentVersion();
        cv.VersionData = Blob.valueOf('test');
        insert cv;

        TestObjectsFactory.insertContentDocumentLink(lstDoc[0].Id, cv.Id);
        TestObjectsFactory.insertContentDocumentLink(lstDoc[1].Id, cv.Id);
        TestObjectsFactory.insertContentDocumentLink(lstDoc[2].Id, cv.Id);

        Contact con = TestObjectsFactory.contactDataSetup(acc1.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
        update con;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc1.Id);
        insert opp;

        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c so1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc1.Id);
        so1.Unit__c = unit.Id;
        so1.Contact__c = con.Id;
        so1.MortgageApplicationNumber__c = '1234';
        so1.MortgageApplicable__c = 'No';
        so1.ADMFeeAmount__c = 20000;
        insert so1;

        // Third-party relationship (account != SalesOrder account)
        Sales_Order_Relationship__c sor1 = new Sales_Order_Relationship__c(
            SalesOrder__c = so1.Id,
            Compliance_status__c = 'Under Review',
            Relationship_Sub_Type__c = 'child',
            Expected_amount__c = 500,
            Account__c = acc2.Id,
            RecordTypeId = thirdPartyRecordTypeId
        );

        List<Sales_Order_Relationship__c> sorList = new List<Sales_Order_Relationship__c>{ sor1 };

        Test.startTest();
        insert sor1; // fires trigger + validation logic
        SalesOrderRelationshipTriggerHelper.validateDuplicatesForThridParty(sorList);
        Test.stopTest();
    }

    @isTest
    static void testInserAARealtionShipRecords() {
        Id thirdPartyRecordTypeId = Schema.SObjectType.Sales_Order_Relationship__c
            .getRecordTypeInfosByName().get('Third Party').getRecordTypeId();

        Account acc1 = TestObjectsFactory.getAccountRecord('Organization Account', false, '123223378');
        insert acc1;

        // different third-party account
        Account acc2 = TestObjectsFactory.getAccountRecord('Organization Account', false, '123223379');
        insert acc2;

        Contact con = TestObjectsFactory.contactDataSetup(acc1.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
        update con;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc1.Id);
        insert opp;

        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c so1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc1.Id);
        so1.Unit__c = unit.Id;
        so1.Contact__c = con.Id;
        so1.MortgageApplicationNumber__c = '1234';
        so1.MortgageApplicable__c = 'No';
        so1.ADMFeeAmount__c = 20000;
        insert so1;

        Sales_Order_Relationship__c sor1 = new Sales_Order_Relationship__c(
            SalesOrder__c = so1.Id,
            Compliance_status__c = 'Under Review',
            Relationship_Sub_Type__c = 'child',
            Expected_amount__c = 500,
            Account__c = acc2.Id,
            RecordTypeId = thirdPartyRecordTypeId
        );

        List<Sales_Order_Relationship__c> sorList = new List<Sales_Order_Relationship__c>{ sor1 };

        Test.startTest();
        SalesOrderRelationshipTriggerHelper.inserAARealtionShipRecords(sorList);
        Test.stopTest();
    }

    @isTest
    static void testOnBeforeInsert() {
        Id thirdPartyRecordTypeId = Schema.SObjectType.Sales_Order_Relationship__c
            .getRecordTypeInfosByName().get('Third Party').getRecordTypeId();

        Account acc1 = TestObjectsFactory.getAccountRecord('Organization Account', false, '123223380');
        insert acc1;

        // third-party account (must be different)
        Account acc2 = TestObjectsFactory.getAccountRecord('Organization Account', false, '123223381');
        insert acc2;

        Contact con = TestObjectsFactory.contactDataSetup(acc1.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
        update con;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc1.Id);
        insert opp;

        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c so1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc1.Id);
        so1.Unit__c = unit.Id;
        so1.Contact__c = con.Id;
        so1.MortgageApplicationNumber__c = '1234';
        so1.MortgageApplicable__c = 'No';
        so1.ADMFeeAmount__c = 20000;
        insert so1;

        List<Sales_Order_Relationship__c> testRecords = new List<Sales_Order_Relationship__c>{
            new Sales_Order_Relationship__c(
                SalesOrder__c = so1.Id,
                Account__c = acc2.Id, // different from acc1
                RecordTypeId = thirdPartyRecordTypeId
            )
        };

        Test.startTest();
        insert testRecords; // fires before insert trigger path
        Test.stopTest();
    }

    @isTest
    static void testOnAfterInsert() {
        Id thirdPartyRecordTypeId = Schema.SObjectType.Sales_Order_Relationship__c
            .getRecordTypeInfosByName().get('Third Party').getRecordTypeId();

        Account acc1 = TestObjectsFactory.getAccountRecord('Organization Account', false, '123223382');
        insert acc1;

        // third-party account (different)
        Account acc2 = TestObjectsFactory.getAccountRecord('Organization Account', false, '123223383');
        insert acc2;

        Contact con = TestObjectsFactory.contactDataSetup(acc1.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
        update con;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc1.Id);
        insert opp;

        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c so1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc1.Id);
        so1.Unit__c = unit.Id;
        so1.Contact__c = con.Id;
        so1.MortgageApplicationNumber__c = '1234';
        so1.MortgageApplicable__c = 'No';
        so1.ADMFeeAmount__c = 20000;
        insert so1;

        List<Sales_Order_Relationship__c> testRecords = new List<Sales_Order_Relationship__c>{
            new Sales_Order_Relationship__c(
                SalesOrder__c = so1.Id,
                Compliance_status__c = 'Under Review',
                Relationship_Sub_Type__c = 'child',
                Expected_amount__c = 500,
                Account__c = acc2.Id, // different from acc1
                RecordTypeId = thirdPartyRecordTypeId
            )
        };

        Test.startTest();
        insert testRecords; // fires after insert handler logic
        Test.stopTest();
    }

    @isTest
    static void testforAccountValidation() {

        List<Account> accList = new List<Account>();
        
        // Person Account 1 (Non-Resident)
        Account personAcc = TestObjectsFactory.getAccountRecord('Person Account', true, '123223384');
        personAcc.PersonEmail = 'test2@gmail.com';
        personAcc.ResidentStatus__pc = 'Non-Resident';
        personAcc.BillingCountry = 'India';
        personAcc.CustomerBankCountry__c = 'United Kingdom';
        personAcc.CustomerBankName__c = 'Surya Bank';
        personAcc.CustomerType__c = 'Existing Customer';
        personAcc.EmploymentStatus__pc = 'Employed';
        personAcc.FirstName = 'test';
        personAcc.Gender__pc = 'Male';
        personAcc.LastName = 'sourab test Passport Merge';
        personAcc.MaritalStatus__pc = 'Single';
        personAcc.MobileCountryCode__pc = '971';
        personAcc.Nationality__pc = 'United Arab Emirates';
        personAcc.PassportExpiryDate__pc = Date.newInstance(2025, 7, 12);
        personAcc.PassportIssueDate__pc = Date.newInstance(2025, 6, 16);
        personAcc.PlaceofIssue__pc = 'LUCKNOW';
        personAcc.PassportNumber__pc = 'A123456789';
        personAcc.Passport_Type__pc = 'Ordinary';
        personAcc.BillingCity = 'Potlan';
        personAcc.BillingStreet = 'dddd';
        personAcc.PersonBirthdate = Date.newInstance(1989, 6, 23);
        personAcc.MobilePhone__pc = '0502482540';
        personAcc.Placeofbirth__c = 'India';
        personAcc.UAEPassExists__pc = false;
        personAcc.VisaType__c = 'Visa not applicable';
        accList.add(personAcc);
        
        // Person Account 2 (Resident)
        Account personAcc2 = TestObjectsFactory.getAccountRecord('Person Account', true, '123223385');
        personAcc2.PersonEmail = 'test23@gmail.com';
        personAcc2.ResidentStatus__pc = 'Resident';
        personAcc2.BillingCountry = 'India';
        personAcc2.CustomerBankCountry__c = 'United Kingdom';
        personAcc2.CustomerBankName__c = 'Surya Bank';
        personAcc2.CustomerType__c = 'Existing Customer';
        personAcc2.EmploymentStatus__pc = 'Employed';
        personAcc2.FirstName = 'test';
        personAcc2.Gender__pc = 'Male';
        personAcc2.LastName = 'sourab test Passport Merge';
        personAcc2.MaritalStatus__pc = 'Single';
        personAcc2.MobileCountryCode__pc = '971';
        personAcc2.Nationality__pc = 'United Arab Emirates';
        personAcc2.PassportExpiryDate__pc = Date.newInstance(2025, 7, 12);
        personAcc2.PassportIssueDate__pc = Date.newInstance(2025, 6, 16);
        personAcc2.PlaceofIssue__pc = 'LUCKNOW';
        personAcc2.PassportNumber__pc = 'A123456789';
        personAcc2.Passport_Type__pc = 'Ordinary';
        personAcc2.BillingCity = 'Potlan';
        personAcc2.BillingStreet = 'dddd';
        personAcc2.PersonBirthdate = Date.newInstance(1989, 6, 23);
        personAcc2.MobilePhone__pc = '0502482540';
        personAcc2.Placeofbirth__c = 'India';
        personAcc2.UAEPassExists__pc = false;
        personAcc2.VisaType__c = 'UAE National';
        accList.add(personAcc2);

        // Org account for SalesOrder
        Account acc1 = TestObjectsFactory.getAccountRecord('Organization Account', false, '123223386');
        accList.add(acc1);

        insert accList;

        // Required docs for personAcc - with Status__c and ContentDocumentLink
        List<Document__c> lstDoc = new List<Document__c>{
            new Document__c(Account__c = personAcc.Id, DocumentType__c = 'Passport Copy',        Status__c = 'Uploaded'),
            new Document__c(Account__c = personAcc.Id, DocumentType__c = 'Signed KYC Form',      Status__c = 'Uploaded'),
            new Document__c(Account__c = personAcc.Id, DocumentType__c = 'National ID Back Copy', Status__c = 'Uploaded'),
            new Document__c(Account__c = personAcc.Id, DocumentType__c = 'National ID Front Copy',Status__c = 'Uploaded')
        };
        insert lstDoc;

        ContentVersion cv = TestObjectsFactory.getContentVersion();
        cv.VersionData = Blob.valueOf('test');
        insert cv;

        TestObjectsFactory.insertContentDocumentLink(lstDoc[0].Id, cv.Id);
        TestObjectsFactory.insertContentDocumentLink(lstDoc[1].Id, cv.Id);
        TestObjectsFactory.insertContentDocumentLink(lstDoc[2].Id, cv.Id);

        // Contact & SO setup
        Contact con = TestObjectsFactory.contactDataSetup(acc1.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
        update con;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc1.Id);
        insert opp;

        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c so1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc1.Id);
        so1.Unit__c = unit.Id;
        so1.Contact__c = con.Id;
        insert so1;

        Sales_Order_Relationship__c rel1 = new Sales_Order_Relationship__c(
            SalesOrder__c = so1.Id,
            Compliance_status__c = 'Under Review',
            Relationship_Sub_Type__c = 'child',
            Expected_amount__c = 500,
            Account__c = personAcc.Id // different from SO account acc1
        );

        Test.startTest();
        insert rel1;
        Test.stopTest();
    }

    @isTest
    static void testUpdateSOR() {

        Id thirdPartyRecordTypeId = Schema.SObjectType.Sales_Order_Relationship__c
            .getRecordTypeInfosByName().get('Third Party').getRecordTypeId();

        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;

        Account acc2 = TestObjectsFactory.getAccountRecord('Organization Account', false, '123223387');
        insert acc2;

        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'anayak@aldar.com';
        update con;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;

        Unit__c unit = TestObjectsFactory.unitDataSetup(opp.Id);
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.status__c = 'Reservation In Progress';
        insert salesOrder;

        // SOR with different third-party account
        Sales_Order_Relationship__c sor1 = new Sales_Order_Relationship__c(
            SalesOrder__c = salesOrder.Id,
            Account__c = acc2.Id, // different from SO account acc
            RecordTypeId = thirdPartyRecordTypeId,
            Compliance_status__c = 'Under Review',
            Relationship_Sub_Type__c = 'child',
            Expected_amount__c = 500
        );
        insert sor1;

        Id nocRT = Schema.SObjectType.Case.getRecordTypeInfosByName()
            .get(System.Label.Third_Party_Payment_NOC_Record_Type).getRecordTypeId();

        Case cs = new Case(
            RecordTypeId = nocRT,
            Unit__c = unit.Id,
            OwnerId = UserInfo.getUserId(),
            Assigned_To__c = UserInfo.getUserId(),
            Status = System.Label.Compliance_Check_Status,
            Sales_Order_Relationship__c = sor1.Id
        );
        insert cs;

        Test.startTest();
        sor1.Compliance_status__c = 'Returned';
        update sor1;

        sor1.Compliance_status__c = 'Cleared';
        update sor1;

        sor1.Compliance_status__c = 'Rejected';
        update sor1;
        Test.stopTest();
    }

}