@isTest
public class UpdateReferredByProfileBatchTest 
{
    @isTest
    public static void testAgencyRegistrationSR()
    {
        HexaBPM__Service_Request__c serviceRequestRecord = new HexaBPM__Service_Request__c();
            
        serviceRequestRecord.AccountName__c = 'agencyName';
        serviceRequestRecord.TradeCommercialLicenseNumber__c = 'licenseNumber';
        serviceRequestRecord.Address1__c = 'addressLine1';
        serviceRequestRecord.Address2__c = 'addressLine2';
        serviceRequestRecord.City__c = 'this.city';
        serviceRequestRecord.State__c = 'this.state';
        serviceRequestRecord.POBox__c = 'this.poBox';
        serviceRequestRecord.Country__c = 'Jordan';
        serviceRequestRecord.EstablishmentDate__c =  date.today();
        serviceRequestRecord.ExpiryDate__c = date.today().addYears(5);
        serviceRequestRecord.PhoneNumber__c = 'phoneNumber';
        serviceRequestRecord.CompanyEmail__c = 'this.companyEmail@test.com';
        serviceRequestRecord.Website__c = 'this.website';
        serviceRequestRecord.TaxRegistrationNumber__c = 'this.taxRegistrationCertificate';

        serviceRequestRecord.POATitle__c = 'Mr';
        serviceRequestRecord.NameOfPOA__c = 'Nikil';

        serviceRequestRecord.ReferredBy__c = 'Faiza Kanwal' ;
        serviceRequestRecord.ReferredByTitle__c = 'Mr';
        serviceRequestRecord.Title__c = 'Mr';
        serviceRequestRecord.Designation__c = 'CCO';
        serviceRequestRecord.SignatoryName__c = 'Mahmood';
        serviceRequestRecord.SignatoryEmail__c = 'test@gmail.com';
        serviceRequestRecord.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Agency Registration');
        
       	HexaBPM__Service_Request__c sr = BrokerAgencyRegistrationController.createServiceRequestRecord(serviceRequestRecord);
        sr.ReferredByProfileName__c = '';
        update sr;
        
        Test.startTest();
        UpdateReferredByProfileBatch b = new UpdateReferredByProfileBatch();
		Database.executeBatch(b,5);
        Test.stopTest();
        
    }

}