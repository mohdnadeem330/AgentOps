@IsTest(SeeAllData=false)
public class CC_PropertyTransferOffplanValidationTest {

    @IsTest
    static void setupData() {
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;

        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'test@propertytransfer.com';
        update con;

        Project__c projectRecord = TestObjectsFactory.getProjectRecord('Mayan');
        projectRecord.AccountNumberCorporate__c   = '12345678';
        projectRecord.BankNameCorporate__c        = 'Test Bank';
        projectRecord.BeneficiaryNameCorporate__c = 'Test Beneficiary';
        projectRecord.BranchCorporate__c          = 'Test Branch';
        projectRecord.IBANNoCorporate__c          = 'AE240354031005788876001';
        projectRecord.SwiftCodeCorporate__c       = 'NBADAEAA';
        projectRecord.City__c					  = 'Abu Dhabi';
        insert projectRecord;
        
        // Unit
        Unit__c unit = TestObjectsFactory.unitDataSetup('123456');
        unit.Name = 'AliTest';
        unit.Status__c = 'Sold';
        unit.Project__c = projectRecord.Id;
        insert unit;
        

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(null, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.AmountPayable__c = 100;
        insert salesOrder;
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);
        
        DirectDebitRequest__c ddr = TestObjectsFactory.createDirectDebitRecords(salesOrder.id);
        ddr.PayerAccount__c = acc.Id;
        ddr.CustomerIdType__c = 'Trade License Number';
        ddr.Replicate_same_on_other_Sales_Order__c = true;
        insert ddr;
        
        HexaBPM__SR_Status__c stClosed = new HexaBPM__SR_Status__c(
            Name = 'Closed',
            HexaBPM__Code__c = 'Closed'
        );
        insert stClosed;
        
        HexaBPM__SR_Template__c spaTemp = TestObjectsFactory.getSRTemplate(Constants.SPA_REGISTRATION_TYPE);        
        insert spaTemp;
        
        Id spaRT = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.SPA_REGISTRATION_RT);
        HexaBPM__Service_Request__c spaSR = TestObjectsFactory.getServiceRequest(
            stClosed.Id,
            unit.Id,
            Constants.SPA_REGISTRATION_TYPE,
            spaRT,
            spaTemp.Id
        );
        spaSR.SalesOrder__c = salesOrder.Id;
        spaSR.SPACounterSignedDate__c = Date.today();
        insert spaSR;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.PROPERTY_TRANSFER_DEV_RT, 'PropertyTransferOffPlan');
        insert objStepTemplate;

        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate('PropertyTransferOffPlan');
        SRTemplateDetailRecord.Name = Constants.PROPERTY_TRANSFER_RT;
        insert SRTemplateDetailRecord;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');
        insert draft;

        Id propertyTransferRT = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_OffPlan);
        HexaBPM__Service_Request__c srRecord = TestObjectsFactory.getServiceRequest(
            draft.Id,
            unit.Id,
            Constants.PROPERTY_TRANSFER_OffPlan,
            propertyTransferRT,
            SRTemplateDetailRecord.Id
        );
        srRecord.SalesOrder__c = salesOrder.Id;
        srRecord.HexaBPM__Customer__c = acc.Id;
        srRecord.HexaBPM__Email__c = 'test@propertytransfer.com';
        insert srRecord;
        

        HexaBPM__Step__c step = TestObjectsFactory.getServiceRequestStep(srRecord.Id, objSRSteps.Id, objStepTemplate.Id);
        step.HexaBPM__Summary__c = 'Charge Fees';
        insert step;

        Test.startTest();

        CC_PropertyTransferOffplanValidation validator = new CC_PropertyTransferOffplanValidation();
        String result1 = validator.EvaluateCustomCode(srRecord, step);

        ReceiptAcknowledgement__c receipt = TestObjectsFactory.getReceiptAcknowledgementRecord(
            salesOrder.Id, acc.Id, null, 'Cash'
        );
        receipt.ServiceRequest__c = srRecord.Id;
        insert receipt;

        String result2 = validator.EvaluateCustomCode(srRecord, step);

        step.HexaBPM__Summary__c = 'Book Customer Appointment';
        update step;
        srRecord.AppointmentDate__c = null;
        update srRecord;

        String result3 = validator.EvaluateCustomCode(srRecord, step);

        srRecord.AppointmentDate__c = Date.today();
        update srRecord;

        String result4 = validator.EvaluateCustomCode(srRecord, step);

        String result5 = validator.EvaluateCustomCode(srRecord, null);
        
        step.HexaBPM__Summary__c = 'Verification of Buyer Profile';
        update step;
        srRecord.BuyerName__c = null;
        update srRecord;
        String result7 = validator.EvaluateCustomCode(srRecord, step);
        
        step.HexaBPM__Summary__c = 'Verification of Seller Profile';
        update step;
        srRecord.BuyerName__c = null;
        update srRecord;
        String result77 = validator.EvaluateCustomCode(srRecord, step);
        
        step.HexaBPM__Summary__c = 'Compliance Check for Buyers';
        update step;
        srRecord.Compliance_Status__c = null;
        update srRecord;
        String result8 = validator.EvaluateCustomCode(srRecord, step);
        
        step.HexaBPM__Summary__c = 'Finance Verification';
        update step;
        String result9 = validator.EvaluateCustomCode(srRecord, step);
        
        step.HexaBPM__Summary__c = 'Post Sales Final Approval';
        update step;
		String result10 = validator.EvaluateCustomCode(srRecord, step);
        
        step.HexaBPM__Summary__c = 'Prepare DD Cancellation and PDC documents';
        update step;
		String result11 = validator.EvaluateCustomCode(srRecord, step);
        
        HexaBPM__Step__c invalidStep = new HexaBPM__Step__c(HexaBPM__Summary__c = 'Charge Fees');
        insert invalidStep;
        String result6 = validator.EvaluateCustomCode(srRecord, invalidStep);

    }
    
    @IsTest
    static void ManualSrStepOpenFromApexTest(){
        Test.startTest();
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;

        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'test@propertytransfer.com';
        update con;

        Project__c projectRecord = TestObjectsFactory.getProjectRecord('Mayan');
        projectRecord.AccountNumberCorporate__c   = '12345678';
        projectRecord.BankNameCorporate__c        = 'Test Bank';
        projectRecord.BeneficiaryNameCorporate__c = 'Test Beneficiary';
        projectRecord.BranchCorporate__c          = 'Test Branch';
        projectRecord.IBANNoCorporate__c          = 'AE240354031005788876001';
        projectRecord.SwiftCodeCorporate__c       = 'NBADAEAA';
        projectRecord.City__c					  = 'Abu Dhabi';
        insert projectRecord;
        
        // Unit
        Unit__c unit = TestObjectsFactory.unitDataSetup('123456');
        unit.Name = 'AliTest';
        unit.Status__c = 'Sold';
        unit.Project__c = projectRecord.Id;
        insert unit;
        

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(null, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.AmountPayable__c = 100;
        insert salesOrder;
        
        HexaBPM__SR_Status__c stClosed = new HexaBPM__SR_Status__c(
            Name = 'Closed',
            HexaBPM__Code__c = 'Closed'
        );
        insert stClosed;
        
         HexaBPM__SR_Template__c spaTemp = TestObjectsFactory.getSRTemplate(Constants.SPA_REGISTRATION_TYPE);        
        insert spaTemp;
        
        Id spaRT = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.SPA_REGISTRATION_RT);
        HexaBPM__Service_Request__c spaSR = TestObjectsFactory.getServiceRequest(
            stClosed.Id,
            unit.Id,
            Constants.SPA_REGISTRATION_TYPE,
            spaRT,
            spaTemp.Id
        );
        spaSR.SalesOrder__c = salesOrder.Id;
        spaSR.SPACounterSignedDate__c = Date.today();
        insert spaSR;
        
        HexaBPM__Step_Template__c objStepTemplate1 = TestObjectsFactory.getStepTemplate('Upcoming Installment Cleared', 'PropertyTransferOffPlan');
        insert objStepTemplate1;
		
		HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate('PropertyTransferOffPlan');
        SRTemplateDetailRecord.Name = Constants.PROPERTY_TRANSFER_OffPlan;
        insert SRTemplateDetailRecord;
	
		
		HexaBPM__SR_Steps__c objSRSteps1 = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate1.Id);
        insert objSRSteps1;
		
		HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');
        insert draft;

        Id propertyTransferRT = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_OffPlan);
        HexaBPM__Service_Request__c srRecord = TestObjectsFactory.getServiceRequest( 
            draft.Id,
            unit.Id,
            Constants.PROPERTY_TRANSFER_OffPlan,
            propertyTransferRT,
            SRTemplateDetailRecord.Id
        );
        srRecord.SalesOrder__c = salesOrder.Id;
        srRecord.HexaBPM__Customer__c = acc.Id;
        srRecord.HexaBPM__Email__c = 'test@propertytransfer.com';
        insert srRecord;
		
		HexaBPM__Step__c step1 = TestObjectsFactory.getServiceRequestStep(srRecord.Id, objSRSteps1.Id, objStepTemplate1.Id);
        step1.HexaBPM__Summary__c = 'Upcoming Installment Cleared';
        insert step1;
        CC_PropertyTransferOffplanValidation.ManualSrStepOpenFromApex('Property Transfer (Off Plan)',sRRecord.Id,'Upcoming Installment Cleared');
        CC_PropertyTransferOffplanValidation.poaVerifiedStepStatusCheck(new Set<Id>{ srRecord.Id });
        Test.stopTest();
    }
}