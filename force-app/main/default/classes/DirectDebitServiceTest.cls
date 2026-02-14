@isTest
private class DirectDebitServiceTest {

    @testSetup
    static void setupDataTest() {

        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        acc.MobileNumber__c = '9999999999';
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
        //insert documentMCD;
        
        Document__c documentScheduleA = TestObjectsFactory.getProjectDocument(project.Id);
        documentScheduleA.DocumentType__c = Constants.DOCUMENT_TYPE_SCHEDULE_A;
        // insert documentScheduleA;
        
        Document__c documentTradeLic = TestObjectsFactory.getProjectDocument(project.Id);
        documentTradeLic.DocumentType__c = Constants.DOCUMENT_TYPE_Commercial_Trade_License;
        // insert documentTradeLic;
        
        Document__c documentBankLetter = TestObjectsFactory.getProjectDocument(project.Id);
        documentBankLetter.DocumentType__c = Constants.DOCUMENT_TYPE_Bank_Letter;
        // insert documentBankLetter;
        
        //added by Dharnesh 
        
        List<Document__c> documentsToInsert = new List<Document__c>{
            documentMCD,
                documentScheduleA, 
                documentTradeLic,
                documentBankLetter
                };
                    
                    insert documentsToInsert;
        
        //added by Dharnesh
        
        ContentDocumentLink documentLink = TestObjectsFactory.createContentDocumentLink(documentMCD.Id);

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesorder.MortgageApplicable__c = 'Yes';
        insert salesOrder;        
        //added by Dharnesh
        List<InstallmentLines__c> installmentLinesList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 5);
        //added by Dharnesh
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.INTERNAL_MORTGAGE_DISCHARGE_TYPE);        
        insert SRTemplateDetailRecord;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.INTERNAL_MORTGAGE_DISCHARGE_TYPE, 'InternalMortgageDischarge');
        insert objStepTemplate;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
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
        objSRDoc.Name = Constants.DOCUMENT_TYPE_SDDRF;
        insert objSRDoc;

        Test.startTest();
        DirectDebitRequest__c ddr = TestObjectsFactory.createDirectDebitRecords(salesOrder.id);
        ddr.PayerAccount__c = acc.Id;
        ddr.CustomerIdType__c = 'Trade License Number';
        ddr.Replicate_same_on_other_Sales_Order__c = true;
        insert ddr;
        Test.stopTest(); 
    }

    @isTest
    static void getSalesOrderAccountDetails_withServiceRequestIdTest() {
       
        HexaBPM__Service_Request__c sr = [SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1];
        Test.startTest();
        DirectDebitService.DDInitWrapper result = DirectDebitService.getSalesOrderAccountDetails(sr.Id);
        Test.stopTest();

        //System.assertNotEquals(null, result);
        //System.assertEquals('HexaBPM__Service_Request__c', result.submitFromObject);
    }

    /*@isTest
    static void updateServiceRequest_successTest() {
        HexaBPM__Service_Request__c sr = [SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1];
        String result = '';
        Test.startTest();
        //result = DirectDebitService.updateServiceRequest(NULL, sr.Id);
        Test.stopTest();
        //System.assertEquals('success', result);
    }*/
    
    @isTest
    static void checkForExistingActiveDDRTest() {
        
		List<DirectDebitRequest__c> ddList = [SELECT Id, SalesOrder__c,Skip_off_plan_ddr_validation__c FROM DirectDebitRequest__c];
        Test.startTest();
        DirectDebitService.checkForExistingActiveDDR(ddList);
        Test.stopTest();
    }

    @isTest
    static void updateSODDRNTest() {
        
        List<DirectDebitRequest__c> ddList = [SELECT Id, SalesOrder__c FROM DirectDebitRequest__c];
        for (DirectDebitRequest__c ddr : ddList) {
            ddr.Status__c = System.Label.Cancelled;
        }
        Test.startTest();
        update ddList;
        
        
        DirectDebitService.updateSODDRN(ddList);
        Test.stopTest();
    }

    @isTest
    static void updateDirectDebitStatusTest() {
        
        List<DirectDebitRequest__c> ddList = [
            SELECT Id,
                isReceived__c, isVerified__c, Status__c, ReceivedBy__c, Received_Date_time__c, VerifiedBy__c, Verified_Date_time__c
            FROM DirectDebitRequest__c
        ];
        for (DirectDebitRequest__c ddr : ddList) {
            ddr.Cancelled__c = true;
        }
        Test.startTest();
        update ddList;
        
        
        DirectDebitService.updateDirectDebitStatus(ddList);
        Test.stopTest();
    }

    @isTest
    static void updateDDRStatusVerifierReceiverTest() {
        
        List<DirectDebitRequest__c> ddList = [
            SELECT Id,
                isReceived__c, isVerified__c, Status__c, ReceivedBy__c, Received_Date_time__c, VerifiedBy__c, Verified_Date_time__c
            FROM DirectDebitRequest__c
        ];
        for (DirectDebitRequest__c ddr : ddList) {
            ddr.isReceived__c = true;
            ddr.isVerified__c = true;
        }
        Test.startTest();
        DirectDebitService.updateDDRStatusVerifierReceiver(ddList);
        Test.stopTest();
    }
    
    @isTest
    static void updateDDRStatusVerifierReceiverTest1() {
       
        List<DirectDebitRequest__c> ddList = [
            SELECT Id,
            isReceived__c, isVerified__c, Status__c, ReceivedBy__c, Received_Date_time__c, VerifiedBy__c, Verified_Date_time__c
            FROM DirectDebitRequest__c
        ];
        for (DirectDebitRequest__c ddr : ddList) {
            ddr.isReceived__c = true;
            ddr.isVerified__c = false;
        }
        Test.startTest();
        DirectDebitService.updateDDRStatusVerifierReceiver(ddList);
        Test.stopTest();
    }

    @isTest
    static void updateDDRWhenStatusIsCancellationRejectedTest() {
        
        List<DirectDebitRequest__c> ddList = [
            SELECT Id,
                isReceived__c, isVerified__c, Status__c, ReceivedBy__c, Received_Date_time__c, VerifiedBy__c, Verified_Date_time__c
            FROM DirectDebitRequest__c
        ];
        for (DirectDebitRequest__c ddr : ddList) {
            ddr.Status__c = 'Cancellation Rejected';
        }
        Test.startTest();
        update ddList;
        
        DirectDebitService.updateDDRWhenStatusIsCancellationRejected(ddList);
        Test.stopTest();
    }

    @isTest
    static void updateDDRWhenStatusIsRejectedTest() {
        
        List<DirectDebitRequest__c> ddList = [
            SELECT Id,
                isReceived__c, isVerified__c, Status__c, ReceivedBy__c, Received_Date_time__c, VerifiedBy__c, Verified_Date_time__c
            FROM DirectDebitRequest__c
        ];
        for (DirectDebitRequest__c ddr : ddList) {
            ddr.Status__c = System.Label.RejectedbyBank;
        }
        Test.startTest();
        update ddList;
        DirectDebitService.updateDDRWhenStatusIsRejected(ddList);
        Test.stopTest();
    }

    @isTest
    static void updateCancelltionDDRStatusVerifierReceiverTest() {
        
        
        List<DirectDebitRequest__c> ddList = [
            SELECT Id,
                isReceived__c, isVerified__c, Status__c, ReceivedBy__c, Received_Date_time__c,
                VerifiedBy__c, Verified_Date_time__c, ReceiveCancellationForm__c, CancelDirectDebitRequest__c,
                CancellationReceivedBy__c, CancellationReceivedDateTime__c, CancellationVerifiedBy__c, CancellationVerifiedDateTime__c
            FROM DirectDebitRequest__c
        ];
        for (DirectDebitRequest__c ddr : ddList) {
            ddr.ReceiveCancellationForm__c = true;
            ddr.CancelDirectDebitRequest__c = true;
        }
        Test.startTest();
        DirectDebitService.updateCancelltionDDRStatusVerifierReceiver(ddList);
        Test.stopTest();
    }

    @isTest
    static void checkForSignedDirectDebitFormCancellationTest() {
        Test.startTest();
        List<DirectDebitRequest__c> ddList = [
            SELECT Id,
                isReceived__c, isVerified__c, Status__c, ReceivedBy__c, Received_Date_time__c, VerifiedBy__c, Verified_Date_time__c
            FROM DirectDebitRequest__c
        ];
        try {
            DirectDebitService.checkForSignedDirectDebitFormCancellation(ddList);
        } catch (Exception ex) {
            //System.debug('Expected error: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    public static void getMaximumAmount() {
        Test.startTest();
        DirectDebitService.getMaximumAmount(new InstallmentLines__c[]{new InstallmentLines__c()});
        Test.stopTest();
    }

    @isTest
    public static void replicateDDRonOtherSalesOrders() {

        List<DirectDebitRequest__c> ddList = [
            SELECT Id,
                Replicate_same_on_other_Sales_Order__c,
                isReceived__c, isVerified__c, Status__c, ReceivedBy__c, Received_Date_time__c,
                VerifiedBy__c, Verified_Date_time__c, ReceiveCancellationForm__c, CancelDirectDebitRequest__c,
                CancellationReceivedBy__c, CancellationReceivedDateTime__c, CancellationVerifiedBy__c, CancellationVerifiedDateTime__c
            FROM DirectDebitRequest__c
        ];
        Test.startTest();
        DirectDebitService.replicateDDRonOtherSalesOrders(ddList);
        Test.StopTest();
    }

    @isTest
    public static void createApexInfoLog(){
        Test.StartTest();
        DirectDebitService.createApexInfoLog('DirectDebitServiceTest','createApexInfoLog','LoggingLevel.INFO','Test','Test');
        Test.StopTest();
    }
    
    /*@isTest
    static void newMessageExceptionTest() {
        String invalidRecordId = '000000000';
        String testDdrId = '00000';
        
        Test.startTest();
        
        try {
            //DirectDebitService.updateServiceRequest(testDdrId, invalidRecordId);
        } catch (Exception e) {
            
        }
        
        Test.stopTest();
    }*/
    
}