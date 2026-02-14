/**
* RTOCustomerPaymentNotificationBatchTest
*
* Test class for RTOCustomerPaymentNotificationBatch
*/
@isTest
private class RTOCustomerPaymentNotificationBatchTest{
    //Create setupData
    @testSetup static void setupData() {
            //offer
            Account acc = TestObjectsFactory.getPersonAccountRecord();
            insert acc;

            Account agencyAcc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
            agencyAcc.PreviousAgencyStatus__c = 'In Active';
            agencyAcc.AgencyStatus__c = 'Active';
            insert agencyAcc;

            Contact con = TestObjectsFactory.contactDataSetup(agencyAcc.Id);
    
            Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
            opp.EnquiryTrigger__c=null;
            insert opp;
            ProjectBudget__c projectBudget = TestObjectsFactory.getProjectBudget();
            insert projectBudget;
            
            Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
            projectRecord.ProjectBudget__c = projectBudget.Id;
            insert projectRecord;
            BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
            buildingRecord.ProjectBudget__c = projectBudget.Id;
            insert buildingRecord;
            Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
            unitrecord.RTOAllowed__c=true;
            unitrecord.SellingPrice__c = 500000;
            unitrecord.MeasuredArea__c =1000;
            unitrecord.AnticipatedServiceCharges__c=10;
            unitrecord.EscalationServiceCharge__c=10;
            insert unitrecord;

            List<Unit__c> unitRecords = UnitService.getAllUnitsById(new Set<Id>{unitrecord.Id});
    
            PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
            paymentPlanRecord.name='RTO Plan';
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

            Map<Id,OffersPromotions__c> unitToOfferMap = new Map<Id,OffersPromotions__c>();
            unitToOfferMap.put(unitrecord.Id,offerRecord);

            InternalCommission__c internalCommission = TestObjectsFactory.getInternalCommission();
            insert internalCommission;

            BrokerCommission__c brokerCommission = TestObjectsFactory.getBrokerCommission(unitrecord.Project__c);
            brokerCommission.BuildingSection__c = unitrecord.BuildingSectionName__c ;
            insert brokerCommission;

            InternalCommission__c internalCommissionProject = TestObjectsFactory.getInternalCommission();
            internalCommissionProject.Project__c = unitrecord.Project__c;
            insert internalCommissionProject;
    }

    @isTest static void testRTODefault() {
        
        Opportunity opp = [select id from Opportunity limit 1];
        Account agencyAcc = [select id from Account Where Name = 'Test Agency Account' limit 1];
        Contact agencyCon = [select id from Contact limit 1];
        
        Unit__c unitrecord =[select id,ProjectBudget__c,Name,BuildingSectionName__c,Project__c from Unit__c limit 1];
        
        
        list<RTOConfiguration__c> RTOCOnfigs = new list<RTOConfiguration__c>{new RTOConfiguration__c(Name = unitrecord.Name+'-1',
                                                                                                     BuildingSectionName__c =unitrecord.BuildingSectionName__c,
                                                                                                     Project__c = unitrecord.Project__c,
                                                                                                     Unit__c = unitrecord.Id,
                                                                                                     Years__c = '1 Year')};
        list<RTOLines__c> rtoConfigLine = new list<RTOLines__c>{new RTOLines__c(Name = '1-'+unitrecord.Name+'-1',
                                                                                YearNumber__c=1,
                                                                                RebatePercentage__c =1,
                                                                                RebateAmount__c =10000,
                                                                                Rent__c = 50000,
                                                                                RentEscalation__c =5,
                                                                                RentCreditRate__c = 100,
                                                                                RentCredit__c = 50000,
                                                                                CummulativeEquity__c = 50000,
                                                                                TotalEquity__c = 50000,
                                                                                TotalEquityPercentage__c = 10,
                                                                                RemainingPayment__c = 50000,
                                                                                Unit__c =unitrecord.Id,
                                                                                Years__c ='1 Year' )};
        OpportunityRTOUnitSearchController.saveConfigurations(new list<ID>{unitrecord.Id},new list<String>{'1'},RTOCOnfigs,rtoConfigLine,1000,5,true,true);
        
        RTOConfiguration__c configDetail = [select id from RTOConfiguration__c limit 1];
        list<map<String,string>> winValues = OpportunityRTOUnitSearchController.getWinReasonPickList();
        OpportunityRTOUnitSearchController.bookRTO(opp.id,configDetail.id,System.today(),'1','Cheque',winValues[0].get('value') ,10000);
        
        list<SalesOrder__c> soRecord = [select id from SalesOrder__c limit 1];
        system.assertEquals(soRecord.isEmpty(), false);
        list<ReceiptAcknowledgement__c> RA = [select id from ReceiptAcknowledgement__c ];
        for(ReceiptAcknowledgement__c ack : RA){
            ack.MaturityDate__c = system.today().addDays(-14);
        }
        update RA;
        
        test.startTest();
            System.schedule('RTOCustomerPaymentNotificationBatch-Test', '0 0 * * * ?', new RTOCustomerPaymentNotificationBatch() );
        test.stopTest();
    
    }
        @isTest static void testRTONotification() {
        
        Opportunity opp = [select id from Opportunity limit 1];
        Account agencyAcc = [select id from Account Where Name = 'Test Agency Account' limit 1];
        Contact agencyCon = [select id from Contact limit 1];
        
        Unit__c unitrecord =[select id,ProjectBudget__c,Name,BuildingSectionName__c,Project__c from Unit__c limit 1];
        
        
        list<RTOConfiguration__c> RTOCOnfigs = new list<RTOConfiguration__c>{new RTOConfiguration__c(Name = unitrecord.Name+'-1',
                                                                                                     BuildingSectionName__c =unitrecord.BuildingSectionName__c,
                                                                                                     Project__c = unitrecord.Project__c,
                                                                                                     Unit__c = unitrecord.Id,
                                                                                                     Years__c = '1 Year')};
        list<RTOLines__c> rtoConfigLine = new list<RTOLines__c>{new RTOLines__c(Name = '1-'+unitrecord.Name+'-1',
                                                                                YearNumber__c=1,
                                                                                RebatePercentage__c =1,
                                                                                RebateAmount__c =10000,
                                                                                Rent__c = 50000,
                                                                                RentEscalation__c =5,
                                                                                RentCreditRate__c = 100,
                                                                                RentCredit__c = 50000,
                                                                                CummulativeEquity__c = 50000,
                                                                                TotalEquity__c = 50000,
                                                                                TotalEquityPercentage__c = 10,
                                                                                RemainingPayment__c = 50000,
                                                                                Unit__c =unitrecord.Id,
                                                                                Years__c ='1 Year' )};
        OpportunityRTOUnitSearchController.saveConfigurations(new list<ID>{unitrecord.Id},new list<String>{'1'},RTOCOnfigs,rtoConfigLine,1000,5,true,true);
        
        RTOConfiguration__c configDetail = [select id from RTOConfiguration__c limit 1];
        list<map<String,string>> winValues = OpportunityRTOUnitSearchController.getWinReasonPickList();
        OpportunityRTOUnitSearchController.bookRTO(opp.id,configDetail.id,System.today(),'1','Cheque',winValues[0].get('value') ,10000);
        
        list<SalesOrder__c> soRecord = [select id from SalesOrder__c limit 1];
        soRecord[0].Status__c = Constants.SO_STATUS_RTO_SOLD;
        update soRecord;
        system.assertEquals(soRecord.isEmpty(), false);
        list<ReceiptAcknowledgement__c> RA = [select id from ReceiptAcknowledgement__c ];
        for(ReceiptAcknowledgement__c ack : RA){
            ack.MaturityDate__c = system.today().addDays(30);
        }
        update RA;
        
        test.startTest();
            System.schedule('RTOCustomerPaymentNotificationBatch-Test', '0 0 * * * ?', new RTOCustomerPaymentNotificationBatch() );
        test.stopTest();
    
    }
}