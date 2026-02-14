/**
* CommissionLineItemServiceTest
*
* Test class for CommissionLineItemService
*/
@isTest
private class CommissionLineItemTriggerHandlerTest{
    //Setup test Data
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
     //Test Commission record creation
    @isTest static void commissionRecords() {
        Account accRecord = [select id from Account limit 1];
        Contact conRecord = [select id from Contact limit 1];
        Opportunity optyRecord = [select id from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        Test.startTest();
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,accRecord.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        salesOrderRecord.ERPID__c = '098765';
        insert salesOrderRecord;
        
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
                commissionLineExtenalRecord.ERPID__c = '123456';
                externalCommission.add(commissionLineExtenalRecord);
            }
        }
        if(!installmentLines.isEmpty()){
            insert installmentLines;
        }
        if(!externalCommission.isEmpty()){
            insert externalCommission;
            system.debug('externalCommission::'+externalCommission);
            
            externalCommission[0].Status__c=Constants.COMMISSION_LINE_STATUS_FIXED;
            externalCommission[0].ApprovalStatus__c = 'Approved';
            //externalCommission[0].GenerateClaimForm__c = true;
            externalCommission[0].InvoiceNumber__c='0';
            list<CommissionLineItem__c> oldRec =new list<CommissionLineItem__c>();
            oldRec.add(new CommissionLineItem__c(id=externalCommission[0].Id,Status__c=null/*,GenerateClaimForm__c=false*/,InvoiceNumber__c='0'));
            oldRec.add(new CommissionLineItem__c(id=externalCommission[1].Id,Status__c=null,InvoiceNumber__c='0'));
            CommissionLineItemTriggerHandler obj=new CommissionLineItemTriggerHandler();
            obj.beforeUpdateMethod(externalCommission,new map<id,sObject>(externalCommission),oldRec,new map<id,sObject>(oldRec));
            obj.afterUpdateMethod(externalCommission, new map<id,sObject>(externalCommission), oldRec, new map<id,sObject>(oldRec));
        }
        list<CommissionLineItem__c> commissionRecords = [SELECT
                                                         Id,
                                                         SalesOrder__r.ErpId__c,
                                                         ErpId__c,
                                                         SalesOrder__r.IsSalesConsultantsChange__c,
                                                         ApprovalStatus__c,
                                                         BrokerAgency__c,
                                                         Comments__c
                                                         FROM CommissionLineItem__c];
        system.debug('commissionRecords::'+commissionRecords);
        list<CommissionLineItem__c> cliList = new list<CommissionLineItem__c>();
        InvoiceBundle__c invoiceBundle = new InvoiceBundle__c(); 
        invoiceBundle.BrokerAgency__c = commissionRecords[0].BrokerAgency__c;
        invoiceBundle.BundleName__c = 'brokerAgencyId';
        invoiceBundle.Status__c = 'Ready for Submission';
        invoiceBundle.BundleNumber__c = 1;
        insert invoiceBundle;
        
        for(CommissionLineItem__c cli: commissionRecords){
            CommissionLineItem__c clitem = new CommissionLineItem__c();
            clitem.id = cli.Id;
            clitem.InvoiceBundle__c = invoiceBundle.Id;
            cliList.add(clitem);
        }
        update cliList;
        
        cliList[0].ApprovalStatus__c='In Progress';
        cliList[0].Comments__c='Update';
        cliList[0].SubmitforReview__c = true;
        update cliList[0];
        system.debug('commissionRecords::'+cliList[0]);
        CommissionLineItemTriggerHandler.checkandCreatePublicLink(new set<ID>{ cliList[0].Id});
        System.assertEquals(cliList.isEmpty(), false);
        
        CommissionLineItemTriggerHandler.updateInvoiceBundle(new List<Id>{invoiceBundle.id});
        CommissionLineItemTriggerHandler.getCountOnInvoiceBunlde(new List<Id>{invoiceBundle.id});
        /*list<CommissionLineItem__c> oldRec =new list<CommissionLineItem__c>();
            oldRec.add(new CommissionLineItem__c(id=externalCommission[0].Id,Status__c='Pending Finance Verification',ApprovalStatus__c='Approved',GenerateClaimForm__c=true,InvoiceNumber__c='0'));
            oldRec.add(new CommissionLineItem__c(id=externalCommission[1].Id,Status__c='Pending Finance Verification',ApprovalStatus__c='Approved',GenerateClaimForm__c=false,InvoiceNumber__c='0'));
            CommissionLineItemTriggerHandler obj=new CommissionLineItemTriggerHandler();
            obj.beforeUpdateMethod(externalCommission,new map<id,sObject>(externalCommission),oldRec,new map<id,sObject>(oldRec));
            List<Document__c> docrecords = [Select id from Document__c where documenttype__c='Commission Claim Form' ];
            System.assertEquals(commissionRecords.isEmpty(), false);*/
        Test.stopTest();
    }
    
    //Test Commission record creation
    @isTest static void commissionRecordsTestDelete() {
        Account accRecord = [select id from Account limit 1];
        Contact conRecord = [select id from Contact limit 1];
        Opportunity optyRecord = [select id from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        Test.startTest();
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,accRecord.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        salesOrderRecord.ERPID__c = '098765';
        insert salesOrderRecord;
        
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
                commissionLineExtenalRecord.ERPID__c = '123456';
                externalCommission.add(commissionLineExtenalRecord);
            }
        }
        if(!installmentLines.isEmpty()){
            insert installmentLines;
        }
        if(!externalCommission.isEmpty()){
            insert externalCommission;
        }
        
		List<CommissionLineItem__c> listToDelete = [SELECT Id From CommissionLineItem__c Limit 1];        
        Delete listToDelete;
        Test.stopTest();
    }
}