@isTest
private class ContactServiceTest {
    
    @isTest(SeeAllData=false)  
    static  void callMethods() {

        ContactService.getAgentsByName(new Set<String>{'Ali Athamneh'});

        Account acc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220212');
        insert acc;
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);

        ContactService.getContactsByAccountId(new Set<Id>{acc.Id});
        ContactService.getAccountId(con.Id);

        try{
            ContactService.getAccountId(null);
        } catch(Exception e){

        }

        User user = TestObjectsFactory.getUserRecord('Agency Admin', 'test.user');
        user.ContactId = con.Id;
        insert user;

        ContactService.resetPassword(new List<Id>{con.Id});
        ContactService.resetPassword(null);

        Map<Id, Account> accountsMap = new Map<Id, Account>();
        accountsMap.put(acc.Id, acc);

        ContactService.getAgencyAdminContactsFromRelatedToAccount(accountsMap);
        ContactService.getAllContactsByAccountId(new Set<Id>{acc.Id});

        HexaBPM__SR_Status__c srStatus = new HexaBPM__SR_Status__c();
        srStatus.HexaBPM__Code__c = 'Submitted';
        srStatus.Name = 'Submitted';
        insert srStatus;
        
         HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Agency Registration';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='AgencyRegistration';
        insert SR_Template;
        
        HexaBPM__Service_Request__c serviceRequestRecord = new HexaBPM__Service_Request__c();
        serviceRequestRecord.HexaBPM__SR_Template__c = SR_Template.Id;
        serviceRequestRecord.AccountName__c = 'this.agencyName';
        serviceRequestRecord.TradeCommercialLicenseNumber__c = 'this.licenseNumber';
        serviceRequestRecord.Address1__c = 'this.addressLine1';
        serviceRequestRecord.Address2__c = 'this.addressLine2';
        serviceRequestRecord.City__c = 'this.city';
        serviceRequestRecord.State__c = '';
        serviceRequestRecord.POBox__c = 'this.poBox';
        serviceRequestRecord.Country__c = 'Jordan';
        serviceRequestRecord.EstablishmentDate__c =  date.today();
        serviceRequestRecord.ExpiryDate__c = date.today().addYears(5);
        serviceRequestRecord.PhoneNumber__c = 'this.phoneNumber';
        serviceRequestRecord.CompanyEmail__c = 'this.companyEmail@test.com';
        serviceRequestRecord.Website__c = 'this.website';
        serviceRequestRecord.TaxRegistrationNumber__c = 'this.taxRegistrationCertificate';

        serviceRequestRecord.POATitle__c = 'Mr';
        serviceRequestRecord.NameOfPOA__c = 'this.nameOfPOA';

        serviceRequestRecord.BankName__c = 'this.bankName';
        serviceRequestRecord.SwiftCode__c = 'ssssss11aaa';
        serviceRequestRecord.IBANNumber__c = 'DE89370400440532013000';
        serviceRequestRecord.BankAddress__c = 'this.branchAddress';

        serviceRequestRecord.ReferredBy__c = 'this.referredBy' ;
        serviceRequestRecord.ReferredByTitle__c = 'Mr';
        serviceRequestRecord.Title__c = 'Mr';
        serviceRequestRecord.Designation__c = 'this.designation';
        serviceRequestRecord.SignatoryName__c = 'this.authorizedSignatoryName';
        serviceRequestRecord.SignatoryEmail__c = 'this.authorizedSignatoryEmail@test.com';
        serviceRequestRecord.SRType__c = 'Agency Registration';
        HexaBPM__Service_Request__c sr = BrokerAgencyRegistrationController.createServiceRequestRecord(serviceRequestRecord);
               
        List<Map<String, Object>> partnersOwners = new List<Map<String, Object>>();

        Map<String,Object> partnerOwnerMap = new Map<String,Object>();
        partnerOwnerMap.put('ownerName', 'test');
        partnerOwnerMap.put('ownerCountry', 'Jordan');
        partnerOwnerMap.put('partnerOwnerDetails', 'test');
        partnerOwnerMap.put('shareHoldingPercentage', '100');
        partnersOwners.add(partnerOwnerMap);

        AgencyTeam__c agencyAdmin = new AgencyTeam__c();
            
        agencyAdmin.Title__c = 'Mr';
        agencyAdmin.EmailAddress__c = 'this.contactPersonEmailID@test.com';
        agencyAdmin.DateOfBirth__c = date.today().addYears(-20);
        agencyAdmin.Name = 'this.contactPersonName' + ' ' + 'this.contactMiddleName' + 'this.contactLastName';
        agencyAdmin.MobileNumber__c = 'this.contactPersonCountry';
        agencyAdmin.ServiceRequest__c = sr.Id;
        
        list<AgencyTeam__c> agencyTeam = BrokerAgencyRegistrationController.createAgencyTeamRecord(agencyAdmin, partnersOwners);

        List<Contact> newContact = ContactService.createAgencyContact(agencyTeam, acc.Id, Constants.AGENCY_ADMIN);

    }
}