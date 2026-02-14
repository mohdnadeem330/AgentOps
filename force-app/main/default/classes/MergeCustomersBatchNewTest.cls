@isTest
public class MergeCustomersBatchNewTest {
    
    @isTest
    static void testMethod1(){
        Test.startTest();
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.MobileNumber__c = '123456789';
        acc.NationalIdNumber__pc = '784199341496818';
        acc.EmploymentStatus__pc = null;
        acc.SourceofFunds__pc= null;
        acc.Other_Source_of_Funds__pc = null;
        acc.Position__pc = null;
        acc.Company__pc = null;
        acc.AnnualIncome__pc = null;
        acc.Passport_type__pc = null;
        acc.PlaceofIssue__pc = null;
        acc.PassportIssueDate__pc = null;
        acc.PassportExpiryDate__pc = null;
        acc.PassportNumber__pc = null;
        acc.MaritalStatus__pc = null;
        acc.LanguagePreference__pc = null;
        acc.CustomerVertical__c = 'Aldar Properties';
  
        insert acc;
        
        Document__c Doc = new Document__c();
        doc.Account__c = acc.Id;
        doc.DocumentType__c = 'Signed KYC Form';
        doc.Status__c  = 'Uploaded';
        insert doc;
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Sample PDF content'),
            IsMajorVersion = true
        );
        insert contentVersion;
        
        ContentVersion insertedContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            LinkedEntityId = doc.Id,
            ContentDocumentId = insertedContentVersion.ContentDocumentId,
            ShareType = 'I'
        );
        insert contentDocumentLink;
        
        Account acc2 = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc2.MobileNumber__c = '1234567829';
        //acc2.ExistingAccount__c = acc.id;
        acc2.NationalIdNumber__pc = '784199341496818';
        acc2.MasterAccount__c = acc.Id;
        acc2.EligibleForMerge__c = true;
        acc2.ResidentStatus__pc = 'Resident';
        acc2.Nationality__pc = 'India';
        acc2.Gender__pc = 'Male';
        acc2.PersonBirthdate =  date.today().addDays(-5);
        acc2.PotentialValueRating__c = 'High';
        acc2.CurrentValueRating__c = 'High';
        acc2.CountryOfResidence__pc = 'India';
        acc2.LanguagePreference__pc = 'English';
        acc2.NameInArabic__c = 'as';
        acc2.PersonTitle = 'AA';
        acc2.MotherNameArabic__pc = 'aa';
        acc2.MaritalStatus__pc = 'Single';
        acc2.BillingCity = 'Dubai';
        acc2.BillingCountry = 'United Arab Emirates';
        acc2.BillingCountryCode = 'AE';
        acc2.BillingPostalCode = '1212';
        acc2.BillingState = 'Dubai';
        acc2.BillingStreet = 'asdas';
        acc2.UaeFamilyNumber__pc = '212';
        acc2.Homatcardnumber__pc = '2123';
        acc2.UaeFamilyBookNumber__pc = '123';
        acc2.SmartPass__pc = '212';
        acc2.UaeFamilyBookPlaceofIssue__pc = 'Dubai';
        acc2.DarnaId__c = '2123';
        acc2.UaeFamilyBookDateofIssue__pc = date.today().addDays(-4);
        acc2.FacebookId__c = '213';
        acc2.InstagramId__c = '123';
        acc2.FazaaId__c = '323';
        acc2.EssadId__c = '323';
        acc2.LinkedinId__c = '343';
        acc2.PurposeofBuying__c = '434';
        acc2.TwitterId__c = '434';
        acc2.EmploymentStatus__pc = 'Employed';
        acc2.SourceofFunds__pc= 'Employment Income';
        acc2.Other_Source_of_Funds__pc = 'Shares';
        acc2.Position__pc = '232';
        acc2.Company__pc = '3434';
        acc2.AnnualIncome__pc = 323232;
        acc2.Passport_type__pc = 'Ordinary';
        acc2.PlaceofIssue__pc = 'DUbai';
        acc2.PassportIssueDate__pc = date.today().addDays(-5);
        acc2.PassportExpiryDate__pc = date.today().addDays(5);
        acc2.PassportNumber__pc = '2323';
        acc2.NationalIdExpiryDate__pc = date.today().addDays(5); 
        acc2.ShippingCity = 'Dubai';
        acc2.ShippingCountry = 'United Arab Emirates';
        acc2.ShippingCountryCode = 'AE';
        acc2.ShippingPostalCode = '1212';
        acc2.ShippingState = 'Dubai';
        acc2.ShippingStreet = 'asdas';
        acc2.VisaExpiryDate__pc = date.today().addDays(5);
        acc2.DuplicateConfirmedBy__c = Userinfo.getUserId();
        acc2.CustomerVertical__c = 'Aldar Properties';
        acc2.PersonEmail = 'test11@pwc.com';
        acc2.MobilePhone__pc = '0545127086';
        acc2.PersonMobilePhone = '0545127086';
        acc2.MobileNumber__c = '0545127086';
        acc2.MobileNumber1__c = '0545127086';
        insert acc2;
        
        Document__c Doc2 = new Document__c();
        doc2.Account__c = acc2.Id;
        doc2.DocumentType__c = 'Signed KYC Form';
        doc2.Status__c  = 'Uploaded';
        insert doc2;
        ContentVersion contentVersion2 = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Sample PDF content'),
            IsMajorVersion = true
        );
        insert contentVersion2;
        
        ContentVersion insertedContentVersion2 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion2.Id];
        ContentDocumentLink contentDocumentLink2 = new ContentDocumentLink(
            LinkedEntityId = doc2.Id,
            ContentDocumentId = insertedContentVersion2.ContentDocumentId,
            ShareType = 'I'
        );
        insert contentDocumentLink2;
        /*,ShippingCity,ShippingCountry,ShippingCountryCode,ShippingPostalCode,ShippingState,ShippingStateCode,
            ShippingStreet,  Passport_type__pc,PlaceofIssue__pc,PassportIssueDate__pc,PassportExpiryDate__pc,PassportNumber__pc,
            EmploymentStatus__pc,SourceofFunds__pc,OtherSourceofFunds__pc,Position__pc,Company__pc,
            AnnualIncome__pc,CompanyAddress__pc,Industry,NoofYearswithCompany__pc,
            MasterAccount__c,NationalIdExpiryDate__pc,CustomerType__c,CustomerSubType__c,CorporateWealthName__c,
            VisaUIDNo__pc,VisaExpiryDate__pc,CustomerClass__c,VIPClass__c,Interested_in_Golden_Visa__c,GVprocessStatus__c,Agencytoprocessthevisa__c,
            UaeFamilyNumber__pc,Homatcardnumber__pc,UaeFamilyBookNumber__pc,SmartPass__pc,UaeFamilyBookPlaceofIssue__pc,
            DarnaId__c,UaeFamilyBookDateofIssue__pc,FacebookId__c,InstagramId__c,FazaaId__c,EssadId__c,
            Loyalty__c,LinkedinId__c,PurposeofBuying__c,TwitterId__c*/
        
        
        database.executebatch(new MergeCustomersBatchNew(new set<Id>{acc2.Id}),1);
        MergeCustomersBatchNew batchJob = new MergeCustomersBatchNew(new set<Id>{acc2.Id});
        System.schedule('Test Merge Job', '0 0 1 * * ?', batchJob);
        Test.stopTest();
        
    }

}