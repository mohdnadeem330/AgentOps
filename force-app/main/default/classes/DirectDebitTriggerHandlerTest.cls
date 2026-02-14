@isTest
public class DirectDebitTriggerHandlerTest { 
    
    @isTest
    public static void replicateDDRonOtherSalesOrdersTest() {
        //FIN-138 Dummy Commit
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.Company__pc = 'ALdar';
        acc.Position__pc = 'CEO';
        acc.AnnualIncome__pc = 123456;
        acc.Industry = 'Agriculture';
        acc.BankName__c = 'ADCB';
        acc.NoofYearswithCompany__pc = 20;
        acc.BankCountry__c = 'United Arab Emirates';
        acc.CompanyAddress__pc = 'Test address';
        acc.isValidationBypass__c  = true;
        acc.EmploymentStatus__pc = 'Unemployed';
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        Opportunity opp2 = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp2;
        
        Unit__c unit2 = TestObjectsFactory.unitDataSetup('25084');
        insert unit2;
        
        SalesOrder__c salesOrder1= TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit.Id;
        insert salesOrder1;
        
        
        List<InstallmentLines__c> installmentLinesList = TestObjectsFactory.createInstallmentLines(salesOrder1.Id, 5);
        
        SalesOrder__c salesOrder2= TestObjectsFactory.getSalesOrderRecord(opp2.Id, acc.Id);
        salesOrder2.Unit__c = unit2.Id;
        insert salesOrder2;
        
        DirectDebitRequest__c ddr = TestObjectsFactory.createDirectDebitRecords(salesOrder1.id);
        ddr.PayerAccount__c=acc.Id;
        insert ddr;
        
        Test.startTest();
        
       // DirectDebitService.getSalesOrderAccountDetails(salesOrder1.id);
        
        TriggerHandler.processedIds = new Set<Id>();
        ddr.Replicate_same_on_other_Sales_Order__c = true;
        try{
            ddr.Status__c = System.Label.SenttoBank;
            update ddr;
        } catch(Exception exp){
            
        }
        
        DirectDebitRequest__c ddr1 = new DirectDebitRequest__c();
        ddr1.CustomerIdType__c = 'Passport';
        ddr1.CustomerIDNumber__c = '1234567890';
        ddr1.CustomerBankAccountType__c = 'Savings';
        ddr1.CustomerAccountName__c = 'Test';
        ddr1.CustomerBankName__c = 'Abu Dhabi Commercial Bank';
        ddr1.CustomerIBANNumber__c = 'AE123456789012345678901';
        ddr1.Status__c = 'DDS Generated';
        ddr1.SalesOrder__c = salesOrder2.id;
        ddr1.Replicate_same_on_other_Sales_Order__c = true;
        ddr1.PayerAccount__c=acc.Id;
        DirectDebitService.getSalesOrderDetailsForDDS(salesOrder1.id);
        DirectDebitService.getMaximumAmount(installmentLinesList);
        try{
            insert ddr1;
        }catch(Exception ex){
            
        }
        test.stopTest();
    }
    @isTest
    public static void replicateDDRonOtherSalesOrdersTest2() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.Company__pc = 'ALdar';
        acc.Position__pc = 'CEO';
        acc.AnnualIncome__pc = 123456;
        acc.Industry = 'Agriculture';
        acc.BankName__c = 'ADCB';
        acc.NoofYearswithCompany__pc = 20;
        acc.BankCountry__c = 'United Arab Emirates';
        acc.CompanyAddress__pc = 'Test address';
        acc.isValidationBypass__c  = true;
        acc.EmploymentStatus__pc = 'Unemployed';
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder1= TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit.Id;
        insert salesOrder1;
        
        
        List<InstallmentLines__c> installmentLinesList = TestObjectsFactory.createInstallmentLines(salesOrder1.Id, 5);
        
        
        DirectDebitRequest__c ddr = TestObjectsFactory.createDirectDebitRecords(salesOrder1.id);
        ddr.Replicate_same_on_other_Sales_Order__c = true;
        ddr.PayerAccount__c   =acc.Id;   
        insert ddr; 
        
        test.startTest();
        TriggerHandler.processedIds = new Set<Id>();
        test.stopTest();
    }
    @isTest
    public static void DDRstatusUpdateTest() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.Company__pc = 'ALdar';
        acc.Position__pc = 'CEO';
        acc.AnnualIncome__pc = 123456;
        acc.Industry = 'Agriculture';
        acc.BankName__c = 'ADCB';
        acc.NoofYearswithCompany__pc = 20;
        acc.BankCountry__c = 'United Arab Emirates';
        acc.CompanyAddress__pc = 'Test address';
        acc.isValidationBypass__c  = true;
        acc.EmploymentStatus__pc = 'Unemployed';
        insert acc;
        system.debug('acc:::'+acc);
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder1= TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit.Id;
        insert salesOrder1;
        
        DirectDebitRequest__c ddr1 = new DirectDebitRequest__c();
        ddr1.CustomerIdType__c = 'Passport';
        ddr1.CustomerIDNumber__c = '1234567890';
        ddr1.CustomerBankAccountType__c = 'Savings';
        ddr1.CustomerAccountName__c = 'Test';
        ddr1.CustomerBankName__c = 'Abu Dhabi Commercial Bank';
        ddr1.CustomerIBANNumber__c = 'AE123456789012345678901';
        ddr1.Status__c = 'DDS Generated';
        ddr1.SalesOrder__c = salesOrder1.id;
        ddr1.PayerAccount__c   =  acc.Id;   
        insert ddr1;
        
        test.startTest();
        try{
            ddr1.Status__c = 'Rejected by Bank';
        	update ddr1;
        }
        catch(Exception exp){
            
        }
        
        List<DirectDebitRequest__c> ddList = [Select 
                                              Id,
                                              Status__c,
                                              ReceivedBy__c,
                                              isReceived__c,
                                              VerifiedBy__c,
                                              Is_EDDS__c,
                                              isVerified__c from DirectDebitRequest__c where Id =: ddr1.Id];
        DirectDebitService.updateDDRWhenStatusIsRejected(ddList);
        try{
        	ddr1.Cancelled__c = true;
        	update ddr1;
        }
        catch(Exception exp){
            
        }
        List<DirectDebitRequest__c> ddList1 = new List<DirectDebitRequest__c>{ddr1};
        DirectDebitService.updateDirectDebitStatus(ddList1);
        
        ddr1.Status__c = 'Cancelled';
        update ddr1;
        List<DirectDebitRequest__c> ddList2 = new List<DirectDebitRequest__c>{ddr1};
        DirectDebitService.updateSODDRN(ddList2);    
        
        ddr1.isReceived__c = true;
        update ddr1;
        List<DirectDebitRequest__c> ddList3 = new List<DirectDebitRequest__c>{ddr1};
        DirectDebitService.updateDDRStatusVerifierReceiver(ddList3);
        
        ddr1.Status__c = 'Cancellation Rejected';
        update ddr1;
        List<DirectDebitRequest__c> ddList4 = new List<DirectDebitRequest__c>{ddr1};
        DirectDebitService.updateDDRWhenStatusIsCancellationRejected(ddList4);
        DirectDebitService.checkForSignedDirectDebitFormCancellation(ddList4);
        
        ddr1.ReceiveCancellationForm__c = true;
        ddr1.CancellationReason__c = 'Unit Transferred';
        ddr1.CancellationReasonPicklist__c = 'Unit Transferred';
        update ddr1;
        List<DirectDebitRequest__c> ddList5 = new List<DirectDebitRequest__c>{ddr1};
        DirectDebitService.updateCancelltionDDRStatusVerifierReceiver(ddList5);
            
        ddr1.CancelDirectDebitRequest__c = true;
        update ddr1;
        List<DirectDebitRequest__c> ddList6 = new List<DirectDebitRequest__c>{ddr1};
        DirectDebitService.updateCancelltionDDRStatusVerifierReceiver(ddList6);
        test.stopTest();
    }
     @isTest
    public static void DDRstatusUpdateTest2() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.Company__pc = 'ALdar';
        acc.Position__pc = 'CEO';
        acc.AnnualIncome__pc = 123456;
        acc.Industry = 'Agriculture';
        acc.BankName__c = 'ADCB';
        acc.NoofYearswithCompany__pc = 20;
        acc.BankCountry__c = 'United Arab Emirates';
        acc.CompanyAddress__pc = 'Test address';
        acc.isValidationBypass__c  = true;
        acc.EmploymentStatus__pc = 'Unemployed';
        insert acc;
        system.debug('acc:::'+acc);
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder1= TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit.Id;
        insert salesOrder1;
        
        DirectDebitRequest__c ddr1 = new DirectDebitRequest__c();
        ddr1.CustomerIdType__c = 'Passport';
        ddr1.CustomerIDNumber__c = '1234567890';
        ddr1.CustomerBankAccountType__c = 'Savings';
        ddr1.CustomerAccountName__c = 'Test';
        ddr1.CustomerBankName__c = 'Abu Dhabi Commercial Bank';
        ddr1.CustomerIBANNumber__c = 'AE123456789012345678901';
        ddr1.Status__c = 'DDS Generated';
        ddr1.SalesOrder__c = salesOrder1.id;
        ddr1.PayerAccount__c   =  acc.Id;   
        insert ddr1;
        
        test.startTest();
        DirectDebitRequest__c ddr2 = [Select Id, Status__c from DirectDebitRequest__c where Id =: ddr1.Id];
        system.debug('ddr2::'+ddr2);
        ddr2.Status__c = System.Label.SenttoBank;
        update ddr2;
        
        ddr2.Status__c = System.Label.ApprovedbyBank;
        update ddr2;
        
        test.StopTest();
    }
    @isTest
    public static void DDRstatusUpdateTest3() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.Company__pc = 'ALdar';
        acc.Position__pc = 'CEO';
        acc.AnnualIncome__pc = 123456;
        acc.Industry = 'Agriculture';
        acc.BankName__c = 'ADCB';
        acc.NoofYearswithCompany__pc = 20;
        acc.BankCountry__c = 'United Arab Emirates';
        acc.CompanyAddress__pc = 'Test address';
        acc.isValidationBypass__c  = true;
        acc.EmploymentStatus__pc = 'Unemployed';
        insert acc;
        system.debug('acc:::'+acc);
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder1= TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit.Id;
        insert salesOrder1;
        
        DirectDebitRequest__c ddr1 = new DirectDebitRequest__c();
        ddr1.CustomerIdType__c = 'Passport';
        ddr1.CustomerIDNumber__c = '1234567890';
        ddr1.CustomerBankAccountType__c = 'Savings';
        ddr1.CustomerAccountName__c = 'Test';
        ddr1.CustomerBankName__c = 'Abu Dhabi Commercial Bank';
        ddr1.CustomerIBANNumber__c = 'AE123456789012345678901';
        ddr1.Status__c = 'Received by Finance';
        ddr1.SalesOrder__c = salesOrder1.id;
        ddr1.PayerAccount__c   =  acc.Id;   
        insert ddr1;
        Test.startTest();
        DirectDebitRequest__c ddr2 = new DirectDebitRequest__c();
        ddr2.Id = ddr1.Id;
        ddr2.Status__c = System.Label.ApprovedbyBank;
        update ddr2;
        test.stopTest();
    }
    
    @isTest
    public static void DDRstatusUpdateTest4() {
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
       
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        Project__c project = new Project__c();
        project.Id = unit.Project__c;
        project.Name = 'Mayan';
        update project;
        
        Document__c documentMCD = TestObjectsFactory.getProjectDocument(project.Id);
        documentMCD.DocumentType__c = Constants.DOCUMENT_TYPE_MCD;
        insert documentMCD;
        
        Document__c documentScheduleA = TestObjectsFactory.getProjectDocument(project.Id);
        documentScheduleA.DocumentType__c = Constants.DOCUMENT_TYPE_SCHEDULE_A;
        insert documentScheduleA;
        
        Document__c documentTradeLic = TestObjectsFactory.getProjectDocument(project.Id);
        documentTradeLic.DocumentType__c = Constants.DOCUMENT_TYPE_Commercial_Trade_License;
        insert documentTradeLic;
        
        Document__c documentBankLetter = TestObjectsFactory.getProjectDocument(project.Id);
        documentBankLetter.DocumentType__c = Constants.DOCUMENT_TYPE_Bank_Letter;
        insert documentBankLetter;
        
        ContentDocumentLink documentLink = TestObjectsFactory.createContentDocumentLink(documentMCD.Id);

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesorder.MortgageApplicable__c = 'Yes';
        insert salesOrder;        
                
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.INTERNAL_MORTGAGE_DISCHARGE_TYPE);        
        insert SRTemplateDetailRecord;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.INTERNAL_MORTGAGE_DISCHARGE_TYPE, 'InternalMortgageDischarge');
        insert objStepTemplate;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        Test.startTest();
        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;
       
        Id mortgageDischargeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.INTERNAL_MORTGAGE_DISCHARGE_TYPE);
        Id spaId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.SPA_REGISTRATION_RT);

        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.INTERNAL_MORTGAGE_DISCHARGE_TYPE, mortgageDischargeId, SRTemplateDetailRecord.Id);
        newSR.SalesOrder__c = salesOrder.Id;
        newSR.BuyerName__c = acc.Id;
        insert newSR;
		
        HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c = 'Agency_Agreement_Document';
        objDocMaster.HexaBPM__Available_to_client__c = true;
        insert objDocMaster;
        
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id ;
        //docTemp.Stage__c = 'Licensed';
        insert docTemp;

        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SRTemplateDetailRecord.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = objStepTemplate.Id;
        SRStep.HexaBPM__Summary__c = 'Test';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'AgencyRegistration';
        SRStep.DocusignExpiryinDays__c = 2;
        insert SRStep;

        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'AgencyRegistration';
        step.HexaBPM__SR__c = newSR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        insert step; 
        
        HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
        objSRDoc.HexaBPM__Document_Master__c = objDocMaster.id  ;
        objSRDoc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c = newSR.id  ;
        objSRDoc.HexaBPM__Step__c = step.Id;
        objSRDoc.Name = Constants.DOCUMENT_TYPE_SDDCF; 
        insert objSRDoc;
        
        /*DirectDebitRequest__c ddr = TestObjectsFactory.createDirectDebitRecords(salesOrder.id);
        ddr.PayerAccount__c = newSR.HexaBPM__Customer__c;
        ddr.CustomerIdType__c = 'Trade Licence Number';
        insert ddr;*/
        
        
      DirectDebitService.getSalesOrderAccountDetails(salesOrder.id);
      DirectDebitService.getSalesOrderAccountDetails(newSR.id);
        DirectDebitService.createApexInfoLog('test', 'test', 'test', 'test', 'test');
      //  DirectDebitService.updateServiceRequest(null, newSR.id);
        Test.stopTest();
    }
}