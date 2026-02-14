/**
* DefaultAndTerminationUtilityTest
*
* Test class for DefaultAndTerminationUtility
*/
@isTest
private class DefaultAndTerminationUtilityTest{
    
    @testSetup static void setupData() {
        //offer
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        insert orgAcc;
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id); 
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        unitrecord.Status__c = Constants.UNIT_STATUS_SOLD;
        insert unitrecord;
        
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(opp.ID,acc.Id);
        salesOrderRecord.Unit__c = unitrecord.Id;
        salesOrderRecord.SalesManager__c = UserInfo.getUserId();
        salesOrderRecord.NumberOfDefaults__c = 0;
        insert salesOrderRecord;
        
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;
        list<PaymentInstallments__c> installmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert installmentLines;
        paymentPlanRecord.IsActive__c =Constants.YES;
        update paymentPlanRecord;
        BuildingSectionMapping__c buldingPaymentMapping = TestObjectsFactory.getBuildingSectionMapping(paymentPlanRecord.Id,buildingRecord.Id);
        insert buldingPaymentMapping;    
        
        //SR Status 
        insert new list<HexaBPM__SR_Status__c>{ TestObjectsFactory.getSRStatus(Constants.STEP_STATUS_TRANSFER_LEGAL),
            TestObjectsFactory.getSRStatus(Constants.SR_STATUS_CLOSED),
            TestObjectsFactory.getSRStatus(Constants.SUBMITTED),
            TestObjectsFactory.getSRStatus(Constants.STATUS_DRAFT) , 
            TestObjectsFactory.getSRStatus(Constants.STEP_STATUS_CUSTOMER_SETTELED),
            TestObjectsFactory.getSRStatus(Constants.STEP_STATUS_COMPLETED)};
                //SR TEMPLATE
                HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = Constants.DEFAULT_AND_TERMINATION;
        SR_Template.HexaBPM__SR_RecordType_API_Name__c=Constants.DEFAULT_AND_TERMINATION;
        insert SR_Template;
        
        //Step Status 
        list<HexaBPM__Status__c> stepStatus = new list<HexaBPM__Status__c>{ new HexaBPM__Status__c(Name=Constants.STEP_STATUS_PENDING, HexaBPM__Code__c=Constants.STEP_STATUS_PENDING , HexaBPM__Type__c = 'Start'),
            new HexaBPM__Status__c(Name=Constants.STEP_STATUS_CUSTOMER_SETTELED, HexaBPM__Code__c=Constants.STEP_STATUS_CUSTOMER_SETTELED , HexaBPM__Type__c = 'End'),
            new HexaBPM__Status__c(Name=Constants.STEP_STATUS_COMPLETED, HexaBPM__Code__c=Constants.STEP_STATUS_COMPLETED , HexaBPM__Type__c = 'End'),
            new HexaBPM__Status__c(Name=Constants.STEP_STATUS_TRANSFER_LEGAL, HexaBPM__Code__c=Constants.STEP_STATUS_TRANSFER_LEGAL , HexaBPM__Type__c = 'End')};
                insert stepStatus;
        
        // STEP AND STEP TEMPLATE
        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = Constants.STEP_NAME_CUSTOMER_NEGOTIATION;
        ST.HexaBPM__Code__c = Constants.STEP_NAME_CUSTOMER_NEGOTIATION;
        ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST;
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = Constants.STEP_NAME_CUSTOMER_NEGOTIATION;
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
        SRStep.HexaBPM__Start_Status__c = stepStatus[0].Id;
        insert SRStep;
        
        
    }
    //Test Installment records, It should create Commission placeholder
    @isTest static void testInstallmentRecords() {
        Account accRecord = [select id from Account limit 1];
        Contact conRecord = [select id from Contact limit 1];
        Opportunity optyRecord = [select id from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        SalesOrder__c salesOrderRecord = [SELECT Id,SalesManager__c from SalesOrder__c Limit 1];
        
        JointOwner__c jointOwner = new JointOwner__c();
        jointOwner.Account__c = accRecord.Id;
        jointOwner.SharePercentage__c = 10;
        jointOwner.SalesOrder__c = salesOrderRecord.Id;
        insert jointOwner;
          Test.startTest();
        list<InstallmentLines__c> installmentLines = new list<InstallmentLines__c>();
        Decimal totalNetSellingPrice = 1000000;
        Decimal totalCommission = 10000;
        for(PaymentInstallments__c tempInstallmentLine : [select id,BrokerPayoutPercentage__c,Description__c,InstallmentNumber__c,InstallmentPercentage__c,InstallmentDate__c,PaymentPlan__c from PaymentInstallments__c]){
            installmentLines.add(new InstallmentLines__c( 
                BrokerPayoutPercentage__c= tempInstallmentLine.BrokerPayoutPercentage__c,
                Description__c= tempInstallmentLine.Description__c,
                InstallmentNumber__c = tempInstallmentLine.InstallmentNumber__c,
                InstallmentPercentage__c= tempInstallmentLine.InstallmentPercentage__c,
                InstallmentDate__c= tempInstallmentLine.InstallmentDate__c, 
                InstallmentAmount__c= totalNetSellingPrice * (tempInstallmentLine.InstallmentPercentage__c/100),
                PaymentInstallments__c= tempInstallmentLine.Id,
                SalesOrder__c = salesOrderRecord.Id,
                PaymentPlan__c= tempInstallmentLine.PaymentPlan__c
            )); 
        }
        if(!installmentLines.isEmpty()){
            insert installmentLines;
           
            ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrderRecord.Id, accRecord.Id, optyRecord.Id, 'Cheque');
            insert receiptAcknowledgement;
            
            ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrderRecord.Id, accRecord.Id, installmentLines[0].Id);
            insert receiptAllocation;
            
            ID customerDocumentType = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('CustomerDocument').getRecordTypeId();
            Document__c docIn = new Document__c(DocumentType__c = Constants.DOC_TYPE_PAYMENTREMINDER,
                                                InstallmentLine__c = installmentLines[0].Id,
                                                SalesOrder__c = salesOrderRecord.id,
                                                RecordtypeId= customerDocumentType);
            insert docIn;
            DefaultAndTerminationUtility.generateSOA(new set<ID>{docIn.Id});
        }
        
        DefaultAndTerminationUtility.createDandTSR(new set<ID>{installmentLines[0].Id});
        HexaBPM__Service_Request__c srRecord = [select id,InstallmentLine__c,SalesOrder__c from HexaBPM__Service_Request__c limit 1] ;
        srRecord.LegalFees__c = 1000;
        srRecord.InstallmentLine__c = installmentLines[0].Id;
        srRecord.SalesOrder__c = salesOrderRecord.Id;
        update srRecord;
        
        ReceiptAcknowledgement__c recAck = [select id from ReceiptAcknowledgement__c];
        System.debug('## srRecord.Id > '+[select id,InstallmentLine__c,SalesOrder__c from HexaBPM__Service_Request__c limit 1]);
        
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'LPC Waiver';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='LPCWaiver';
        insert SR_Template;
        
        //Approval by AVP-Default Step Setup
        HexaBPM__Step_Template__c avpDefault_ST = new HexaBPM__Step_Template__c();
        avpDefault_ST.Id = [SELECT Id FROM HexaBPM__Step_Template__c LIMIT 1].Id;
        avpDefault_ST.Name = Constants.STEP_NAME_CUSTOMER_NEGOTIATION;
        avpDefault_ST.HexaBPM__Code__c = Constants.STEP_NAME_CUSTOMER_NEGOTIATION;
        avpDefault_ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        update avpDefault_ST;

        HexaBPM__SR_Steps__c SRavpDefaultStep = new HexaBPM__SR_Steps__c();
        SRavpDefaultStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRavpDefaultStep.HexaBPM__Step_No__c = 1;
        SRavpDefaultStep.HexaBPM__Step_Template__c = avpDefault_ST.Id;
        SRavpDefaultStep.HexaBPM__Summary__c = 'Approval by AVP-Default';
        SRavpDefaultStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRavpDefaultStep;
        
        
        HexaBPM__Step__c avpDefaultstep = new HexaBPM__Step__c();
        avpDefaultstep.HexaBPM__Summary__c = 'Approval by AVP-Default';
        avpDefaultstep.HexaBPM__SR__c = srRecord.Id;
        avpDefaultstep.HexaBPM__SR_Step__c = SRavpDefaultStep.Id;
        avpDefaultstep.HexaBPM__Start_Date__c = System.today();
       // avpDefaultstep.Step_Template_Code__c=Constants.STEP_NAME_CUSTOMER_NEGOTIATION;
        //avpDefaultstep.InstallmentLine__c = installmentLines[0].Id;
        insert avpDefaultstep;
     
        DefaultAndTerminationUtility.autoTransferToLeagal(new set<ID>{srRecord.Id});
        DefaultAndTerminationUtility.closeDandTSRAfterLegal(new set<ID>{srRecord.Id});
       
        DefaultAndTerminationUtility.verifyReversalandCreateDandTSR(new set<ID>{recAck.Id});
        
        DefaultAndTerminationUtility.verifyandCloseSR(new set<ID>{recAck.Id});
        
        test.stopTest();
    }
    
    //Test Installment records, It should create Commission placeholder
    @isTest static void testForDnTSR() {
        test.startTest();
        SalesOrder__c salesOrderRecord = [SELECT Id,Opportunity__c,Account__c from SalesOrder__c Limit 1];
        list<InstallmentLines__c> installmentLines = new list<InstallmentLines__c>();
        Decimal totalNetSellingPrice = 1000000;
        Decimal totalCommission = 10000;
        for(PaymentInstallments__c tempInstallmentLine : [select id,BrokerPayoutPercentage__c,Description__c,InstallmentNumber__c,InstallmentPercentage__c,InstallmentDate__c,PaymentPlan__c from PaymentInstallments__c]){
            installmentLines.add(new InstallmentLines__c( 
                BrokerPayoutPercentage__c= tempInstallmentLine.BrokerPayoutPercentage__c,
                Description__c= tempInstallmentLine.Description__c,
                InstallmentNumber__c = tempInstallmentLine.InstallmentNumber__c,
                InstallmentPercentage__c= tempInstallmentLine.InstallmentPercentage__c,
                InstallmentDate__c= tempInstallmentLine.InstallmentDate__c, 
                InstallmentAmount__c= totalNetSellingPrice * (tempInstallmentLine.InstallmentPercentage__c/100),
                PaymentInstallments__c= tempInstallmentLine.Id,
                SalesOrder__c = salesOrderRecord.Id,
                PaymentPlan__c= tempInstallmentLine.PaymentPlan__c
            )); 
        }
        if(!installmentLines.isEmpty()){
            insert installmentLines;
            ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrderRecord.Id, salesOrderRecord.Account__c, salesOrderRecord.Opportunity__c, 'Cheque');
            insert receiptAcknowledgement;
            
            ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrderRecord.Id, salesOrderRecord.Account__c, installmentLines[0].Id);
            insert receiptAllocation;
        }
        DefaultAndTerminationUtility.createDandTSR(new set<ID>{installmentLines[0].Id});
        
        HexaBPM__Service_Request__c srRecord = [Select Id,SRType__c,LegalFees__c,Exceptional_Reason__c,LegalStatus__c,Special_Exceptional_Case__c from HexaBPM__Service_Request__c limit 1] ;
        DefaultAndTerminationUtility.checkAndAutoUnflag(new set<ID>{srRecord.Id}, 'Default');
        
                DefaultAndTerminationUtility.getOwnerEmailList(new set<ID>{salesOrderRecord.Id});

         try{
            DefaultAndTerminationUtility.closeDandTSR(new set<ID>{installmentLines[0].Id});
        }catch(exception e){}
        test.stopTest();
    }
    
    @isTest static void testForDnTSR2() {
        test.startTest();
        SalesOrder__c salesOrderRecord = [SELECT Id,Opportunity__c,Account__c from SalesOrder__c Limit 1];
        list<InstallmentLines__c> installmentLines = new list<InstallmentLines__c>();
        Decimal totalNetSellingPrice = 1000000;
        Decimal totalCommission = 10000;
        for(PaymentInstallments__c tempInstallmentLine : [select id,BrokerPayoutPercentage__c,Description__c,InstallmentNumber__c,InstallmentPercentage__c,InstallmentDate__c,PaymentPlan__c from PaymentInstallments__c]){
            installmentLines.add(new InstallmentLines__c( 
                BrokerPayoutPercentage__c= tempInstallmentLine.BrokerPayoutPercentage__c,
                Description__c= tempInstallmentLine.Description__c,
                InstallmentNumber__c = tempInstallmentLine.InstallmentNumber__c,
                InstallmentPercentage__c= tempInstallmentLine.InstallmentPercentage__c,
                InstallmentDate__c= tempInstallmentLine.InstallmentDate__c, 
                InstallmentAmount__c= totalNetSellingPrice * (tempInstallmentLine.InstallmentPercentage__c/100),
                PaymentInstallments__c= tempInstallmentLine.Id,
                SalesOrder__c = salesOrderRecord.Id,
                PaymentPlan__c= tempInstallmentLine.PaymentPlan__c
            )); 
        }
        if(!installmentLines.isEmpty()){
            insert installmentLines;
            ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrderRecord.Id, salesOrderRecord.Account__c, salesOrderRecord.Opportunity__c, 'Cheque');
            insert receiptAcknowledgement;
            
            ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrderRecord.Id, salesOrderRecord.Account__c, installmentLines[0].Id);
            insert receiptAllocation;
        }
        DefaultAndTerminationUtility.createDandTSR(new set<ID>{installmentLines[0].Id});
        System.debug('DnT Updating the SR');
        HexaBPM__Service_Request__c srRecord = ServiceRequestService.getServiceRequestWithWhereClause(null)[0];
        
        HexaBPM__Service_Request__c srRecord_old =ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{srRecord.Id})[0];
        System.debug('DnT Id > '+srRecord.Id);
        System.debug('## srRecord.SRType__c '+srRecord.SRType__c);
        srRecord.Special_Exceptional_Case__c=true;
        srRecord.Exceptional_Reason__c = 'TEST';
        srRecord.LegalFees__c = 2000;
        update srRecord;
        
        ServiceRequestTriggerHandlerNew serviceRequest = new ServiceRequestTriggerHandlerNew();
        serviceRequest.afterUpdateMethod(new List<HexaBPM__Service_Request__c>{srRecord}, new Map<Id, HexaBPM__Service_Request__c>{srRecord.Id=>srRecord},new List<HexaBPM__Service_Request__c>{srRecord_old}, new Map<Id, HexaBPM__Service_Request__c>{srRecord.Id=>srRecord_old});
        test.stopTest();
    }
    @isTest static void sendFormalDemandLetterTest(){
          Test.startTest();
        
         HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c = 'Formal Demand Letter';
          objDocMaster.Name = 'Formal Demand Letter';
        objDocMaster.HexaBPM__Available_to_client__c = true;
        insert objDocMaster;
        
         HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id ;
        docTemp.ESignGroup__c = 'Authorised Signatory' ;
        insert docTemp;
        
          HexaBPM__Service_Request__c SR11 = new HexaBPM__Service_Request__c();
        SR11.HexaBPM__Customer__c  = [SELECT Id FROM Account LIMIT 1].Id;
        SR11.HexaBPM__Ultimate_SR_Menu_Text__c = 'Company Services';
      //SR.Sys_License_Application__c = l1.Id;
        SR11.HexaBPM__Email__c = 'test@fsraconnect.com';
        SR11.HexaBPM__Send_SMS_to_Mobile__c= '00971666666666';

        insert SR11;
      
        Id srId = [select id,InstallmentLine__c,SalesOrder__c from HexaBPM__Service_Request__c limit 1].Id;
        DefaultAndTerminationUtility.sendFormalDemandLetter(srId);
        Test.stopTest();
    }
}