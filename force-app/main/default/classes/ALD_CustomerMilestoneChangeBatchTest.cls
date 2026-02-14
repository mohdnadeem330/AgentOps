/**
* ALD_CustomerMilestoneChangeBatch
*
* Test class for ALD_CustomerMilestoneChangeBatch
*/
@isTest
private class ALD_CustomerMilestoneChangeBatchTest{
    @testSetup static void setupData() {
        //offer
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.BankName__c = 'Bank Name';
        acc.CustomerBankName__c = 'Bank Name';
        acc.BankCountry__c = 'United Arab Emirates';
        acc.CustomerBankCountry__c = 'United Arab Emirates';
        acc.CompanyAddress__pc = 'UAE';
        acc.Company__pc = 'ALDAR';
        acc.Position__pc = 'SSE';
        acc.AnnualIncome__pc = 10000;
        acc.Industry = 'Real Estate';
        acc.NoofYearswithCompany__pc = 13;
        acc.SourceofFunds__pc = '';
        insert acc;
        
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
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Folder fd = [SELECT Id, Name, DeveloperName, AccessType FROM Folder where DeveloperName='One_time_Use' Limit 1];
            EmailTemplate eTemp = new EmailTemplate (developerName = 'NewMilestoneChange2023Template', FolderId = fd.Id, TemplateType= 'Text', Name = 'NewMilestoneChange2023Template'); // plus any other fields that you want to set
            eTemp.IsActive = true;
            insert eTemp;
            
        }
    }
    //Test Installment records,
    @isTest static void testInstallmentEmailNotification() {
        Account accRecord = [select id from Account limit 1];
        Contact conRecord = [select id from Contact limit 1];
        
        Opportunity optyRecord = [select id from opportunity limit 1];
        Unit__c unitrecord = [select id, Project__c from Unit__c limit 1];
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,accRecord.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        salesOrderRecord.Contact__c = conRecord.Id; 
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
            
            
        }
        if(!installmentLines.isEmpty()){
            installmentLines[0].InstallmentDate__c=System.Today().addDays(30);
            insert installmentLines;
        }
        
        List<String> installmentIds=new List<String>();
        for(InstallmentLines__c ins:installmentLines){
            installmentIds.add(ins.ID);
        }
        
        Test.StartTest();
        List<String> projectIds = new List<String>();
        projectIds.add(unitrecord.Project__c);
        EmailTemplate eTemp = [Select id from EmailTemplate Where developerName = 'NewMilestoneChange2023Template' Limit 1];
        Database.executebatch(new ALD_CustomerMilestoneChangeBatch('',projectIds ,eTemp.Id),200);
        Database.executebatch(new ALD_CustomerMilestoneChangeBatch('',projectIds ,eTemp.Id,installmentIds),200);
        Test.StopTest();
    }
}