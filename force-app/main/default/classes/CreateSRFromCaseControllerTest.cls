@isTest(SeeAllData=false)
public class CreateSRFromCaseControllerTest {

    @testSetup static void setupData() {
        Account account = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
        insert account;

        Contact con = TestObjectsFactory.contactDataSetup(account.Id);
        con.Email = 'ajay.thakur.tpr@gmail.com';
        update con;
        
 		Opportunity opp = TestObjectsFactory.getOpportunityRecord(account.Id);
        insert opp;
        
        
        
        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        project.AsiteProjectName__c = 'Test Project Name';
        insert project;
        
        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        insert buildingSection;
        
        Unit__c unit = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
        unit.Name += '1';
        unit.Status__c = 'Sold';
        insert unit;
        
        
        
        /*Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;*/

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, account.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.NetAmount__c = 100;
        insert salesOrder;

        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 1);
        installmentLines[0].InvoicedAmount__c = 30;
        update installmentLines;

        Case cs = TestObjectsFactory.getStandardCase(account.Id, con.Id, 'Compliance');    
        cs.Unit__c = unit.Id;
        cs.SalesOrder__c = salesOrder.Id;
        insert cs;
        
        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;

        HexaBPM__SR_Template__c srTemplate = TestObjectsFactory.getSRTemplate(Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);
        srTemplate.Name = Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE;
        insert srTemplate;

        HexaBPM__SR_Template__c mortgageDischargeTemplate = TestObjectsFactory.getSRTemplate(Constants.INTERNAL_MORTGAGE_DISCHARGE_RT);
        mortgageDischargeTemplate.Name = Constants.INTERNAL_MORTGAGE_DISCHARGE_TYPE;
        insert mortgageDischargeTemplate;
        
        HexaBPM__SR_Template__c paymentExtentionTemplate = TestObjectsFactory.getSRTemplate(Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);
        paymentExtentionTemplate.Name = Constants.PAYMENT_EXTENSION_SR_TYPE;
        insert paymentExtentionTemplate;
        
        HexaBPM__SR_Template__c template = new HexaBPM__SR_Template__c();
        template.HexaBPM__SR_RecordType_API_Name__c = 'PropertyTransfer';
        insert template;
        
        Account ac = TestObjectsFactory.getPersonAccountRecord();
        ac.BankEmail__c = 'ajay.thakur.tpr@pwc.com';
        ac.BankName__c = 'Abu Dhabi Commercial Bank';
        ac.CustomerBankName__c = 'Abu Dhabi Commercial Bank';
        ac.CustomerBankCountry__c = 'United Arab Emirates';
        insert ac;
        
        Test.startTest();
        User admin = TestObjectsFactory.getUserRecord('System Administrator', 'admin');
        admin.FirstName = 'Admin';
        insert admin;
        
        Opportunity op = TestObjectsFactory.getOpportunityRecord(ac.Id);
        op.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(ResaleConstants.RESALE_OPPORTUNITY_RecordTypeDeveloperName).getRecordTypeId();
        op.OwnerManger__c = UserInfo.getUserId();
        op.Seller__c = ac.Id;
        op.unit__c = unit.Id;
        op.Amount = 500000;
        op.OwnerId = admin.Id;
        insert op;
        
        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, ac.Id, 'Friend Of');
        insert jointOwner;
        
        Case ca = TestObjectsFactory.getStandardCase(account.Id, con.Id, 'Compliance');    
        ca.Unit__c = unit.Id;
        ca.SalesOrder__c = salesOrder.Id;
        ca.Opportunity__c = op.Id;
        ca.Subject = 'Test Subject';
        ca.Description = 'Test Description';
        ca.Status = 'New';
        ca.Origin = 'Online';
        ca.CaseCategory__c = 'Property Transfer';
        ca.Initial_Condition__c = 'Re Sale';
        insert ca;
        Test.stopTest();
    }
    
    /*@isTest static void mortageRegistration(){
        
        Case cs = [select id, SubVertical__c, Type, CaseCategory__c, AccountId, ContactId, Category__c, PaidEquity__c FROM Case LIMIt 1]; 
        
        cs.SubVertical__c = 'ADM Services';
        cs.Type = Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE;
        cs.CaseCategory__c = Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE;        
        update cs;  
        
        Test.startTest();
        CreateSRFromCaseController.createSR(cs.Id);
        CreateSRFromCaseController.getSRTemplate(Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE);
        Test.stopTest();
    }*/

    @isTest static void mortageDischarge(){
        Test.startTest();
        Case cs = [select id, SubVertical__c, Type, CaseCategory__c, AccountId, ContactId, Category__c, PaidEquity__c FROM Case LIMIt 1];

        SalesOrder__c salesOrder = [select id, MortgageApplicable__c, NetAmount__c, TotalBilled__c FROM SalesOrder__c LIMIt 1];        
        salesOrder.MortgageApplicable__c = 'Yes';
        update salesOrder;
        
        cs.SubVertical__c = 'ADM Services';
        cs.Type = Constants.INTERNAL_MORTGAGE_DISCHARGE_TYPE;
        cs.CaseCategory__c = Constants.INTERNAL_MORTGAGE_DISCHARGE_TYPE;
        update cs;
        
        
        CreateSRFromCaseController.createSR(cs.Id);
        Test.stopTest();
    }

   /* @isTest static void investorCertificate(){
		
        Case cs = [select id, SubVertical__c, Type, CaseCategory__c, AccountId, ContactId, Category__c, PaidEquity__c FROM Case LIMIt 1];
        
        cs.SubVertical__c = 'ADM Services';
        cs.Type = Constants.INVESTOR_CERTIFICATE;
        cs.CaseCategory__c = Constants.INVESTOR_CERTIFICATE;
        update cs;
        
        Test.startTest();
        CreateSRFromCaseController.createSR(cs.Id);
		Test.stopTest();
    }*/

    @isTest static void chequeReplacement(){

        Case cs = [select id,  AccountId, Opportunity__c, Initial_Condition__c, ContactId, Category__c FROM Case where Opportunity__c != null AND Initial_Condition__c = 'Re Sale' AND Subject = 'Test Subject' LIMIT 1];

        Test.startTest();
        CreateSRFromCaseController.createSR(cs.Id);
		Test.stopTest();

    }

    /*@isTest static void lpcWaiver(){

        Case cs = [select id, SubVertical__c, Type, CaseCategory__c, AccountId, ContactId, Category__c, PaidEquity__c FROM Case LIMIt 1];
        
        Id recordTypeId = Utilities.getRecordTypeId('Case', 'Feedback Case');
        cs.SubVertical__c = 'Post Sales';
        cs.Type = Constants.LPC_WAIVER_TYPE;
        cs.CaseCategory__c = Constants.LPC_WAIVER_TYPE;
        cs.SubCategory__c = 'Milestone';
        cs.TotalLPCAmount__c = 10000;
        cs.RecordTypeId = recordTypeId;
        update cs;

        //CreateSRFromCaseController.createSR(cs.Id);

    }*/

   // @isTest static void propertyTransfer(){

   //     Case cs = [select id, SubVertical__c, Type, CaseCategory__c, AccountId, ContactId, Category__c, PaidEquity__c FROM Case LIMIt 1];

   //     SalesOrder__c salesOrder = [select id, MortgageApplicable__c, NetAmount__c, TotalBilled__c, TitleDeedRegistrationNumber__c FROM SalesOrder__c LIMIt 1];
              
  //      cs.SubVertical__c = 'RTO';
  //      cs.CaseCategory__c = Constants.PROPERTY_TRANSFER_TYPE;
  ////      cs.SubCategory__c = 'Transfer Normal';
  //      update cs;
        
   //     Test.startTest();
   //     CreateSRFromCaseController.createSR(cs.Id);
	//	Test.stopTest();
   // }

   /* @isTest static void paymentExtention(){
  		
        Case cs = [select id, SubVertical__c, Type, CaseCategory__c, AccountId, ContactId, Category__c, PaidEquity__c FROM Case LIMIt 1];

        cs.SubVertical__c = 'ADM Services';
        cs.Type = Constants.PAYMENT_EXTENSION_TYPE;
        cs.CaseCategory__c = Constants.PAYMENT_EXTENSION_TYPE;
        update cs;
		
        Test.startTest();
        CreateSRFromCaseController.createSR(cs.Id);
        Test.stopTest();
    }*/

   /* @isTest static void developmentUndertakingAgreement(){

        Case cs = [select id, SubVertical__c, Type, CaseCategory__c, AccountId, ContactId, Category__c, PaidEquity__c FROM Case LIMIt 1];
        
        CreateSRFromCaseController.createSR(cs.Id);
        
        Test.startTest();
        
        cs.SubVertical__c = 'Post Sales';
        cs.Type = Constants.DEVELOPMENT_UNDERTAKING_AGREEMENT;
        cs.CaseCategory__c = 'Plot DUA';
        update cs;

        CreateSRFromCaseController.createSR(cs.Id);
        
        Test.stopTest();
    }

    @isTest static void paymentPlanChange(){

        Case cs = [select id, SubVertical__c, Type, CaseCategory__c, AccountId, ContactId, Category__c, PaidEquity__c FROM Case LIMIt 1];
        
        cs.SubVertical__c = 'Defaults & Collection';
        cs.CaseCategory__c = Constants.PAYMENT_PLAN_CHANGE_TYPE;
        update cs;

        CreateSRFromCaseController.createSR(cs.Id);
    }

    @isTest static void mutualCancellation(){

        Case cs = [select id, SubVertical__c, Type, CaseCategory__c, AccountId, ContactId, Category__c, PaidEquity__c FROM Case LIMIt 1];
        
        cs.SubVertical__c = 'Defaults & Collection';
        cs.Type = Constants.CANCELLATION_TYPE;
        cs.CaseCategory__c = Constants.CANCELLATION_TYPE;
        update cs;

        CreateSRFromCaseController.createSR(cs.Id);
    }
    
    @isTest static void consolidation(){

        Case cs = [select id, SubVertical__c, Type, CaseCategory__c, AccountId, ContactId, Category__c, PaidEquity__c FROM Case LIMIt 1];
        
        cs.SubVertical__c = 'Defaults & Collection';
        cs.Type = Constants.CANCELLATION_TYPE;
        cs.CaseCategory__c = 'Cancelation-Refund';
        update cs;

        CreateSRFromCaseController.createSR(cs.Id);
    }*/
}