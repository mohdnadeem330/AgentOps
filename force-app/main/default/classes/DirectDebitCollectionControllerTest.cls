@isTest
public class DirectDebitCollectionControllerTest { 
    
    @testSetup static void setupData() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        insert orgAcc;
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id); 
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        
        projectRecord.DirectDebitOIC__c = '123456789';
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        unitrecord.PropertyStatus__c = 'Sale';
        unitrecord.Status__c = 'Available';
        insert unitrecord;
        
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(opp.ID,acc.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        salesOrderRecord.Directdebitauthorityreferencenumber__c = '1234578987654';
        salesOrderRecord.Status__c = 'Sold';
        insert salesOrderRecord;
        
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;
        
        list<PaymentInstallments__c> PaymentinstallmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert PaymentinstallmentLines;
        
        list<PaymentInstallments__c> PaymentinstallmentLines1 = [Select Id,ApprovalStatus__c FROM PaymentInstallments__c where Id in:PaymentinstallmentLines];
        list<PaymentInstallments__c> PaymentinstallmentLinesUpdate = New list<PaymentInstallments__c>();
        for(PaymentInstallments__c Paymentinstall: PaymentinstallmentLines1 ){
            Paymentinstall.ApprovalStatus__c ='Approved';
            PaymentinstallmentLinesUpdate.add(Paymentinstall);
        }
        update PaymentinstallmentLinesUpdate;
        paymentPlanRecord.IsActive__c = Constants.YES;
        update paymentPlanRecord;
        
        BuildingSectionMapping__c buldingPaymentMapping = TestObjectsFactory.getBuildingSectionMapping(paymentPlanRecord.Id,buildingRecord.Id);
        insert buldingPaymentMapping;    
        
        DirectDebitRequest__c ddr = TestObjectsFactory.createDirectDebitRecords(salesOrderRecord.id);
        ddr.Status__c = 'Approved by Bank';
        ddr.PayerAccount__c=acc.Id;
        ddr.DDAreferencenumber__c='1234578987654';
        insert ddr;
        
        list<InstallmentLines__c> installmentLines = new list<InstallmentLines__c>();
        Decimal totalNetSellingPrice = 1000000;
        Decimal totalCommission = 10000;
        for(PaymentInstallments__c tempInstallmentLine : [SELECT
                                                          Id,
                                                          BrokerPayoutPercentage__c,
                                                          Description__c,
                                                          InstallmentNumber__c,
                                                          InstallmentPercentage__c,
                                                          InstallmentDate__c,
                                                          PaymentPlan__c
                                                          FROM PaymentInstallments__c]){
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
        }
    }
    
    @isTest static void getInstallmentLinesQueryTest() {
        List<InstallmentLines__c> installments = [Select Id, AmountReceived__c from InstallmentLines__c];
        List<InstallmentLines__c> installmentsToUpdate = new List<InstallmentLines__c>();
        for(InstallmentLines__c inst: installments){
            inst.AmountReceived__c= 20;
            installmentsToUpdate.add(inst);
        }
        update installmentsToUpdate;
        map<string, object> mapToSerialize = new map<string, object>();
        
        for(InstallmentLines__c installment: installments){
            mapToSerialize.put(installment.Id, 10);
        }
        Object jsonString = JSON.serialize(mapToSerialize);
        
        system.debug('query:::'+ ([Select Id, SalesOrder__r.Directdebitauthorityreferencenumber__c,SalesOrder__r.Unit__r.BuildingSectionName__c,
                                   SalesOrder__r.Unit__r.BuildingSectionName__r.Name,AmountReceived__c,SalesOrder__r.Unit__c,SalesOrder__r.Unit__r.Name,SalesOrder__r.Account__r.Name,
                                   ERPID__c,InstallmentAmount__c,InstallmentDateinArabic__c,InstallmentDate__c,InstallmentNumber__c,InstallmentPercentage__c,InvoicedAmount__c,
                                   InvoiceId__c,InvoiceNumber__c,Name,RevisedDate__c,SalesOrder__r.name,
                                   StatusIndicator__c,OutstandingAmount__c from 
                                   InstallmentLines__c   WHERE SalesOrder__r.Directdebitauthorityreferencenumber__c != null
                                   AND PaymentInstallments__r.ApprovalStatus__c='Approved'
                                   AND SalesOrder__r.Status__c='Sold' AND InstallmentNumber__c !=1  AND SalesOrder__r.ProjectName__c = 'Mayan']) );
        String salesOrderStatus = 'Sold';
        String receiptPaymentType = 'Direct Debit';
        String receiptStatus = 'Reversed';
        Integer installmentNumber = 1;
        String installPaymentStatus = 'Approved';
        String ProjectName = 'Mayan';         
        string query = 'SELECT SalesOrder__r.Directdebitauthorityreferencenumber__c,SalesOrder__r.Unit__r.BuildingSectionName__c,SalesOrder__r.Unit__r.BuildingSectionName__r.Name,AmountReceived__c,SalesOrder__r.Unit__c,SalesOrder__r.Unit__r.Name,SalesOrder__r.Account__r.Name,ERPID__c,InstallmentAmount__c,InstallmentDateinArabic__c,InstallmentDate__c,InstallmentNumber__c,InstallmentPercentage__c,InvoicedAmount__c,InvoiceId__c,InvoiceNumber__c,Name,RevisedDate__c,SalesOrder__r.name,StatusIndicator__c,OutstandingAmount__c,(Select Id FROM Receipt_Allocations__r Where ReceiptAcknowledgement__r.PaymentType__c =\'' + receiptPaymentType +'\' AND ReceiptAcknowledgement__r.Status__c != \'' + receiptStatus +'\') FROM InstallmentLines__c WHERE SalesOrder__r.Directdebitauthorityreferencenumber__c != null ' +
            'AND SalesOrder__r.Status__c=\'' + salesOrderStatus +'\''+ ' AND PaymentInstallments__r.IsHandoverPayment__c = false AND InstallmentNumber__c != ' + installmentNumber + 
            ' AND PaymentInstallments__r.ApprovalStatus__c=\'' + installPaymentStatus +'\' AND SalesOrder__r.ProjectName__c =\'' +ProjectName+'\'';
        system.debug('query:::'+query);
        system.debug('query:::'+Database.query(query));
        List<InstallmentLines__c> installmentList = Database.query(query);
        
        Test.startTest(); 
        DirectDebitCollectionController.getInstallmentLinesQuery(query, 100, 0);
        DirectDebitCollectionController.prepareDropdownData('Mayan');
        DirectDebitCollectionController.prepareDropdownData('');
        DirectDebitCollectionController.createDirectDebitTransaction((jsonString));
        Test.stopTest();
    }
}