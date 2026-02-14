/**
* InstallmentLinesTriggerHandlerTest
*
* Test class for InstallmentLinesTriggerHandler
*/
@isTest
private class InstallmentLinesTriggerHandlerTest{
    @testSetup static void setupData() {
        
          String responseBody = '{"applicationName":"x-ald-sferp-api","success":true,"statusCode":"201","correlationId":"9d5db2a0","results":[{"sfRequestId":"df06b0f0","sfId":"","status":"Success","errorMessage":"","locationCode":"ALG-SW1_C451_A-2-06"}]}';
        
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorRes(responseBody));
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
        insert unitrecord;
        
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;
        list<PaymentInstallments__c> installmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert installmentLines;
        paymentPlanRecord.IsActive__c =Constants.YES;
        update paymentPlanRecord;
        BuildingSectionMapping__c buldingPaymentMapping = TestObjectsFactory.getBuildingSectionMapping(paymentPlanRecord.Id,buildingRecord.Id);
        insert buldingPaymentMapping;    
        
        OffersPromotions__c offerRecord= TestObjectsFactory.getOfferPromotion(buildingRecord.Id,projectRecord.Id);
        insert offerRecord;
        OfferLines__c offerLine = TestObjectsFactory.getOfferLine(offerRecord.Id);
        insert offerLine;
    }
    //Test Installment records, It should create Commission placeholder
    @isTest static void testInstallmentRecords() {
         String responseBody = '{"applicationName":"x-ald-sferp-api","success":true,"statusCode":"201","correlationId":"9d5db2a0","results":[{"sfRequestId":"df06b0f0","sfId":"","status":"Success","errorMessage":"","locationCode":"ALG-SW1_C451_A-2-06"}]}';
        
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorRes(responseBody));
        
        Account accRecord = [select id from Account limit 1];
        Contact conRecord = [select id from Contact limit 1];
        Opportunity optyRecord = [select id from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,accRecord.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        insert salesOrderRecord;
        
        Test.startTest();
        list<InstallmentLines__c> installmentLines = new list<InstallmentLines__c>();
        list<CommissionLineItem__c> externalCommission= new list<CommissionLineItem__c>();
        Decimal totalNetSellingPrice = 1000000;
        Decimal totalCommission = 10000;
        for(PaymentInstallments__c tempInstallmentLine : [select id,BrokerPayoutPercentage__c,Description__c,InstallmentNumber__c,InstallmentPercentage__c,InstallmentDate__c,PaymentPlan__c from PaymentInstallments__c]){
            installmentLines.add(new InstallmentLines__c( 
                BrokerPayoutPercentage__c= tempInstallmentLine.BrokerPayoutPercentage__c,
                Description__c= tempInstallmentLine.Description__c,
                InvoiceNumber__c = '23456',
                InstallmentNumber__c = tempInstallmentLine.InstallmentNumber__c,
                InstallmentPercentage__c= tempInstallmentLine.InstallmentPercentage__c,
                InstallmentDate__c= tempInstallmentLine.InstallmentDate__c, 
                InstallmentAmount__c= totalNetSellingPrice * (tempInstallmentLine.InstallmentPercentage__c/100),
                PaymentInstallments__c= tempInstallmentLine.Id,
                SalesOrder__c = salesOrderRecord.Id,
                PaymentPlan__c= tempInstallmentLine.PaymentPlan__c
            )); 
            
            //Create Commission
            //split based on the payout 
            if (tempInstallmentLine.BrokerPayoutPercentage__c!=null && tempInstallmentLine.BrokerPayoutPercentage__c!=0) {
                CommissionLineItem__c commissionLineExtenalRecord = new CommissionLineItem__c();
                commissionLineExtenalRecord.BrokerAgent__c = conRecord.id;
                commissionLineExtenalRecord.BrokerAgency__c = accRecord.Id;
                commissionLineExtenalRecord.CommissionAmount__c = (totalCommission * (tempInstallmentLine.BrokerPayoutPercentage__c/100)).setScale(2);
                commissionLineExtenalRecord.CommissionPercentage__c = tempInstallmentLine.BrokerPayoutPercentage__c;
                commissionLineExtenalRecord.CommissionType__c = Constants.COMMISSION_LINE_EXTERNAL_COMMISSION;
                commissionLineExtenalRecord.SalesManager__c = UserInfo.getUserId();
                commissionLineExtenalRecord.SalesOrder__c = salesOrderRecord.Id;
                externalCommission.add(commissionLineExtenalRecord);
            }
        }
        if(!installmentLines.isEmpty()){
            installmentLines[0].InvoicedAmount__c=installmentLines[0].InstallmentAmount__c;
             System.debug('installmentLines:'+installmentLines[0].Id);
            insert installmentLines;
            System.debug('installmentLines:'+installmentLines[0].Id);
            installmentLines[1].InvoicedAmount__c=installmentLines[1].InstallmentAmount__c;
            installmentLines[2].InvoicedAmount__c=(installmentLines[2].InstallmentAmount__c -100);
              
            //update installmentLines;
            InstallmentLines__c instUpd = new InstallmentLines__c();
            instUpd.Id = [SELECT Id FROM InstallmentLines__c WHERE Id =: installmentLines[0].Id LIMIT 1].Id;
            instUpd.InvoicedAmount__c = 20000;
            System.debug('installmentLines upddd:'+installmentLines[0].InvoicedAmount__c);
            TriggerHandler.processedIds = new Set<Id>();
            update instUpd;
            System.debug('installmentLines upd:'+installmentLines[0].InvoicedAmount__c);
            
            
        }
        if(!externalCommission.isEmpty()){
            externalCommission[0].InstallmentLine__c=installmentLines[0].Id;
            externalCommission[1].InstallmentLine__c=installmentLines[1].Id;
            insert externalCommission;
            InstallmentLinesTriggerHandler.createCommissionLineDocuments(new map<id,InstallmentLines__c>(installmentLines));
            list<CommissionLineItem__c> cml = [select id from CommissionLineItem__c];
            for(CommissionLineItem__c cli : cml){
                cli.Status__c = Constants.COMMISSION_LINE_STATUS_NOT_READY;
            }
            update cml;
            
            list<SalesOrder__c> soList = [select id from SalesOrder__c];
            for(SalesOrder__c so : soList){
                so.Status__c = Constants.SO_STATUS_SOLD;
            }
            update soList;
          InstallmentLinesTriggerHandler.createCommissionLineDocuments(new map<id,InstallmentLines__c>(installmentLines));
        }
        list<CommissionLineItem__c> commissionRecords = [select id from CommissionLineItem__c];
        System.assertEquals(commissionRecords.isEmpty(), false);
      Test.stopTest();
    }
    
    /**
    * @description Test Installment records, update handover payment settlement date when outstanding amount less then 100
    * @author rmohmmed@aldar.com | 08-25-2023 | Story Number
    **/
    @isTest 
    static void testUpdateHandOverDate() {
         String responseBody = '{"applicationName":"x-ald-sferp-api","success":true,"statusCode":"201","correlationId":"9d5db2a0","results":[{"sfRequestId":"df06b0f0","sfId":"","status":"Success","errorMessage":"","locationCode":"ALG-SW1_C451_A-2-06"}]}';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorRes(responseBody));
        Account accRecord = [select id from Account limit 1];
        Contact conRecord = [select id from Contact limit 1];
        Opportunity optyRecord = [select id from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,accRecord.Id);
        salesOrderRecord.Unit__c = unitrecord.Id;
        insert salesOrderRecord;
        
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'LPCWaiver']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'LPC Waiver';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c = 'LPCWaiver';
        insert SR_Template;
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.HexaBPM__Customer__c = accRecord.Id;
        //SR.HexaBPM__Contact__c = conRecord.Id;
        SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrderRecord.Id;
        SR.RecordTypeId = recordTypeSR.get('LPCWaiver');
        
        insert SR;
        
        Test.startTest();
        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrderRecord.Id, accRecord.Id, optyRecord.Id, 'Credit Card');
        receiptAcknowledgement.ServiceRequest__c = SR.Id;
        receiptAcknowledgement.ClearedDate__c = system.today();
        insert receiptAcknowledgement;
        
        list<InstallmentLines__c> installmentLines = new list<InstallmentLines__c>();
        list<CommissionLineItem__c> externalCommission= new list<CommissionLineItem__c>();
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
            
            //Create Commission
            //split based on the payout 
            if (tempInstallmentLine.BrokerPayoutPercentage__c!=null && tempInstallmentLine.BrokerPayoutPercentage__c!=0) {
                CommissionLineItem__c commissionLineExtenalRecord = new CommissionLineItem__c();
                commissionLineExtenalRecord.BrokerAgent__c = conRecord.id;
                commissionLineExtenalRecord.BrokerAgency__c = accRecord.Id;
                commissionLineExtenalRecord.CommissionAmount__c = (totalCommission * (tempInstallmentLine.BrokerPayoutPercentage__c/100)).setScale(2);
                commissionLineExtenalRecord.CommissionPercentage__c = tempInstallmentLine.BrokerPayoutPercentage__c;
                commissionLineExtenalRecord.CommissionType__c = Constants.COMMISSION_LINE_EXTERNAL_COMMISSION;
                commissionLineExtenalRecord.SalesManager__c = UserInfo.getUserId();
                commissionLineExtenalRecord.SalesOrder__c = salesOrderRecord.Id;
                externalCommission.add(commissionLineExtenalRecord);
            }
        }
        if(!installmentLines.isEmpty()){
            installmentLines[0].InvoicedAmount__c=installmentLines[0].InstallmentAmount__c;
            insert installmentLines;
            
            ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrderRecord.Id, accRecord.Id, installmentLines[0].Id);
            receiptAllocation.InstallmentLine__c = installmentLines[0].Id;
            insert receiptAllocation;
            
            HandoverDetails__c handoverDetail = new HandoverDetails__c();
            handoverDetail.LastInstallment__c = installmentLines[0].Id;
            insert handoverDetail;
            
            installmentLines[1].InvoicedAmount__c=installmentLines[1].InstallmentAmount__c;
            installmentLines[2].InvoicedAmount__c=(installmentLines[2].InstallmentAmount__c -100);
            update installmentLines;
            
            
        }
        if(!externalCommission.isEmpty()){
            externalCommission[0].InstallmentLine__c=installmentLines[0].Id;
            externalCommission[1].InstallmentLine__c=installmentLines[1].Id;
            insert externalCommission;
            InstallmentLinesTriggerHandler.createCommissionLineDocuments(new map<id,InstallmentLines__c>(installmentLines));
            list<CommissionLineItem__c> cml = [select id from CommissionLineItem__c];
            for(CommissionLineItem__c cli : cml){
                cli.Status__c = Constants.COMMISSION_LINE_STATUS_NOT_READY;
            }
            update cml;
            
            list<SalesOrder__c> soList = [select id from SalesOrder__c];
            for(SalesOrder__c so : soList){
                so.Status__c = Constants.SO_STATUS_SOLD;
            }
            update soList;
            
            
            InstallmentLinesTriggerHandler.createCommissionLineDocuments(new map<id,InstallmentLines__c>(installmentLines));
            InstallmentLinesTriggerHandler.updateHandOverDate(new map<id,InstallmentLines__c>(installmentLines).keySet());
        }
        list<CommissionLineItem__c> commissionRecords = [select id from CommissionLineItem__c];
        Test.stopTest();
    }
}