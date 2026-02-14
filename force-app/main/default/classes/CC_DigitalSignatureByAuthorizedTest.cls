@isTest
public class CC_DigitalSignatureByAuthorizedTest {
    //Create setupData
    @testSetup static void setupData() {
        
        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        
        User newUser = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'newuseradmin');
        newUser.UserRoleId = portalRole.Id;
        newUser.Email = 'test@aldar.com.invalid';
        insert newUser;
        
        User agencyAdmin = new User();
        System.runAs(newUser) {
            Account oAcc = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
            insert oAcc;
            
            Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
            orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
            orgAcc.ResidentialAddressSameAsPermanent__c = 'Yes';
            orgAcc.BillingStreet = 'SARA';
            orgAcc.BillingCity = 'SARA';
            orgAcc.BillingCountry = 'India';
            insert orgAcc;
            System.debug('orgAcc -> '+orgAcc.Id);
            
            Contact aCon = new Contact();
            aCon.LastName = 'Alice';
            aCon.FirstName = 'Alice';
            aCon.AccountId = orgAcc.Id;
            aCon.BrokerType__c = Constants.AGENCY_ADMIN;
            insert aCon;
            
            //Case cs = TestObjectsFactory.getCase(oAcc.Id, aCon.Id, 'Compliance');
            //insert cs;
            
            //TestObjectsFactory.createContentDocumentLink(cs.Id);
            
            agencyAdmin = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN_PROFILE, 'agencyAdmin');
            agencyAdmin.ContactId = aCon.Id;
            agencyAdmin.Email = 'test.portal@aldar.com.saran';
            insert agencyAdmin;
            
            orgAcc.BrokerAgent__c = aCon.Id;
            update orgAcc;
            
            Map<String,Id> recordTypeSR = new Map<String,Id>();
            for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'AgencyRegistration']){
                recordTypeSR.put(rtype.DeveloperName,rtype.Id);
            }
            
            Account orgAcc2 = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220212');
            orgAcc2.BillingStreet = 'SARA';
            orgAcc2.BillingCity = 'SARA';
            orgAcc2.BillingCountry = 'India';
            orgAcc2.ResidentialAddressSameAsPermanent__c = 'Yes';
            insert orgAcc2;
            System.debug('orgAcc2 -> '+orgAcc2.Id);
            
            Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
            
       
            HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
            SR.RecordTypeId = recordTypeSR.get('AgencyRegistration');
            SR.HexaBPM__Customer__c=orgAcc.id;
            SR.Address2__c = 'SARA';
            SR.Address2__c = 'SARA';
            SR.Country__c = 'India';
            SR.State__c = 'SARA';
            SR.City__c = 'SARA';
            SR.POBox__c = '2123';
            SR.TaxRegistrationNumber__c = '12345670';
            SR.VATRegistrationEndDate__c = System.today()+10;
            SR.VATRegistrationStartDate__c = System.today()-10;
            SR.AccountName__c = 'SARANS';
            SR.BankName__c = 'NBD';
            SR.IBANNumber__c = 'AED9872e2926348';
            SR.SwiftCode__c ='SWEDIT89798';
            SR.BankAddress__c = 'Abu Dhabi';
            SR.BankAccountNumber__c = '1221322143';
            SR.BankCountry__c = 'United Arab Emirates';
            SR.VATRegistrationtype__c = 'VAT Registration Certificate';
            insert SR;
            
            HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
            SR_Template.Name = 'Agency Registration';
            SR_Template.HexaBPM__SR_RecordType_API_Name__c='AgencyRegistration';
            insert SR_Template;
            
            HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
            ST.Name = 'Step 1';
            ST.HexaBPM__Code__c = 'Require More Information';
            ST.HexaBPM__Step_RecordType_API_Name__c = 'Require More Information';
            insert ST;
            
            HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
            SRStep.HexaBPM__SR_Template__c = SR_Template.id;
            SRStep.HexaBPM__Step_No__c = 1;
            SRStep.HexaBPM__Step_Template__c = ST.Id;
            SRStep.HexaBPM__Summary__c = 'Test';
            SRStep.HexaBPM__Step_RecordType_API_Name__c = 'AgencyRegistration';
            insert SRStep;
            
            HexaBPM__Step__c step = new HexaBPM__Step__c();
            step.HexaBPM__Summary__c = 'Digital Signature by CCO';
            step.HexaBPM__SR__c = SR.Id;
            step.HexaBPM__SR_Step__c = SRStep.Id;
            step.HexaBPM__Start_Date__c = System.today();
            insert step;
        }
        
         
    }
    @isTest
    static void callMethods() {
        Id userId = [select Id  from User where RoleName__c like '%Broker Relations Manager%' AND IsActive=true Limit 1].Id;

        Test.startTest();

        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c,HexaBPM__SR__r.HexaBPM__Customer__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Digital Signature by CCO' AND HexaBPM__SR__c != null limit 1];

        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.Id = stp.HexaBPM__SR__c;
        SR.PhoneNumber__c = '971 56789123';
        SR.Country__c = 'United Arab Emirates';
        SR.State__c = 'Sharjah';
        SR.ExpiryDate__c = Date.today().addYears(10);
        SR.BrokerManager__c = userId;
        SR.TaxRegistrationNumber__c = '12345670121';
        SR.VATRegistrationEndDate__c = System.today()+15;
        SR.VATRegistrationStartDate__c = System.today()-15;
        SR.VATRegistrationtype__c = 'VAT Registration Certificate';
        update SR;
        System.debug('stp.HexaBPM__SR__r.HexaBPM__Customer__c -> '+stp.HexaBPM__SR__r.HexaBPM__Customer__c);
        //HexaBPM__Service_Request__c SRQ = [SELECT Id FROM HexaBPM__Service_Request__c WHERE Id=:stp.HexaBPM__SR__c];
        HexaBPM__SR_Doc__c srDoc = new HexaBPM__SR_Doc__c();
        srDoc.Name = 'Agency Agreement Signed by CCO';
        srDoc.HexaBPM__Customer__c = stp.HexaBPM__SR__r.HexaBPM__Customer__c;
        srDoc.HexaBPM__Service_Request__c = SR.Id;
        insert srDoc;
        
        CC_DigitalSignatureByAuthorizedSignatory cc = new CC_DigitalSignatureByAuthorizedSignatory();

        cc.EvaluateCustomCode(SR, stp);

        SR.HexaBPM__Required_Docs_not_Uploaded__c = true;
        update SR;

        cc.EvaluateCustomCode(SR, stp);

        HexaBPM__Step__c stp1 = new HexaBPM__Step__c();
        cc.EvaluateCustomCode(SR, stp1);

        Test.stopTest();

    }
}