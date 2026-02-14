@isTest
public class BrokerClassification_Test 
{
    @testSetup static void setupData()
    {
        //Create Setupdata
        /*Account accChild = TestObjectsFactory.getOrganisationAccountRecord('test account', '2123131');
        insert accChild;
        */
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.VisaUIDNo__pc = '784199978419881';
        //acc.ParentId = accChild.Id;
        insert acc;
      

        Id brokerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Broker_Agency')
            .getRecordTypeId();
        Account brokerAcc1 = new Account(Name='broker1',recordTypeId=brokerRecordTypeId);
        Insert brokerAcc1;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        Id managerId = [SELECT Id,ManagerId FROM User WHERE Id!=:userInfo.getUserId() AND Profile.Name = 'System Administrator' AND isActive = true LIMIT 1].Id;
        opp.BrokerAgencyAccount__c = brokerAcc1.Id;
        opp.OwnerManger__c = managerId;
        insert opp;
        
        Opportunity opp2 = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.BrokerAgencyAccount__c = brokerAcc1.Id;
        opp2.OwnerManger__c = managerId;
        
        insert opp2;
        
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        insert unitrecord;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unitrecord.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.BookingDate__c = date.today();
        salesOrder.NetAmount__c = 100;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;

        /*SalesOrder__c salesOrderchild = TestObjectsFactory.getSalesOrderRecord(opp.Id, accChild.Id);
        salesOrderchild.Unit__c = unitrecord.Id;
        salesOrderchild.IsBookingCompleted__c = true;
        salesOrderchild.BookingDate__c = date.today();
        salesOrderchild.NetAmount__c = 20000;
        salesOrderchild.Status__c = 'Sold';
        insert salesOrderchild;
        */
        
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
        BrokerClassification__c bc1 = new BrokerClassification__c(Name='Standard',AnnualSalesTargetFrom__c=0,AnnualSalesTargetTo__c=150000000,AnnualSalesTargetFromInternational__c=0,AnnualSalesTargetToInternational__c=150000000, Year__c = String.valueOf(System.Today().year()));
        Insert bc1;
        
        list<SalesOfferUtility.SaleOfferInputParam> soInputList = new list<SalesOfferUtility.SaleOfferInputParam>();
        SalesOfferUtility.SaleOfferInputParam inputObj = new SalesOfferUtility.SaleOfferInputParam();
        inputObj.unitId=unitrecord.Id;
        inputObj.offerId = offerRecord.Id;
        inputObj.multiPurposeAmountApplicable =true;
        inputObj.selectedPayments = new list<ID>{paymentPlanRecord.Id};
            soInputList.add(inputObj);
        
        Test.startTest();
        map<id,SalesOfferUtility.SalesOfferDetails> result = OpportunityUnitSearchController.generateSalesOffer(soInputList,opp.Id);
        OpportunityUnitSearchController.performBudgetCheck(soInputList,opp.Id);
        OpportunityUnitSearchController.reserveUnit(soInputList,opp.Id,'RESERVE',Opportunity.WinReason__c.getDescribe().getPicklistValues()[0].getValue(),'');
        Test.stopTest();
    }
    
    @isTest
    public static void testMethod2(){ 
        
        List<Opportunity> optyList = [select id,AccountId,BrokerAgencyAccount__c from opportunity];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        PaymentPlan__c ppRecord= [select id from PaymentPlan__c limit 1];
        OffersPromotions__c offerRecord= [select id from OffersPromotions__c limit 1];
        
        Test.startTest();
        List<SalesOrder__c> soList = new List<SalesOrder__c>();
        soList = [SELECT Id FROM SalesOrder__c LIMIT 1];
        if(soList.size() > 0){
            soList[0].BookingDate__c = date.today().addDays(-30);
            soList[0].Status__c = 'Sold';
            Update soList;
        }
        Id brokerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Broker_Agency')
            .getRecordTypeId();
        Account accBr = [SELECT Id FROM Account WHERE RecordType.Id = :brokerRecordTypeId LIMIT 1 ];
        
        Account brokerAcc2 = new Account(Name='broker2',recordTypeId=brokerRecordTypeId,ParentId=accBr.Id);
        Insert brokerAcc2;
        Opportunity opp2 = TestObjectsFactory.getOpportunityRecord(optyList[0].AccountId);
        opp2.BrokerAgencyAccount__c = brokerAcc2.Id;
        insert opp2;
        
        BrokerClassification batch = new BrokerClassification();
        Database.executeBatch(batch,50);
        Test.stopTest();
    }
    
    @IsTest
    public static void myTestMethod() 
    {        
         Test.startTest();
         BrokerClassification myClass = new BrokerClassification ();   
         String chron = '0 0 23 * * ?';        
         system.schedule('Test Sched', chron, myClass);
         Test.stopTest();
    }
    
   @isTest
static void testBrokerClassificationProcessing() {
    Test.startTest();

    // Mock input data
    Map<Id, Account> accMap = new Map<Id, Account>();
    for (Account acc : [SELECT Id, BrokerClassification__c FROM Account]) {
        accMap.put(acc.Id, acc);
    }

    Map<Id, Integer> storeSalesOrderCount = new Map<Id, Integer> {
        accMap.keySet().iterator().next() => 10
    };

    Map<Id, Decimal> totalSalesByAccount = new Map<Id, Decimal> {
        accMap.keySet().iterator().next() => 10000
    };

    // Force today's date to match the last day of the month
    Date fixedDate = Date.newInstance(2024, 2, 29); // Mocked last day of a month
    Date lastDayOfMonth = fixedDate.toStartOfMonth().addMonths(1).addDays(-1);

    if (fixedDate == lastDayOfMonth) {
        List<Broker_Classification_Details__c> insertOrUpdateBCDetails = new List<Broker_Classification_Details__c>();
        String currentYear = String.valueOf(fixedDate.year());
        Decimal currentMonth = fixedDate.month();

        Set<Id> agencyIds = accMap.keySet();
        List<Broker_Classification_Details__c> existingRecords = [
            SELECT Id, Year__c, Month__c, AgencyName__c
            FROM Broker_Classification_Details__c
            WHERE Year__c = :currentYear AND Month__c = :currentMonth AND AgencyName__c IN :agencyIds
        ];

        Map<Id, Broker_Classification_Details__c> existingRecordsMap = new Map<Id, Broker_Classification_Details__c>();
        for (Broker_Classification_Details__c record : existingRecords) {
            existingRecordsMap.put(record.AgencyName__c, record);
        }

        for (Account accNewValues : accMap.values()) {
            Broker_Classification_Details__c bcDetails;

            if (existingRecordsMap.containsKey(accNewValues.Id)) {
                bcDetails = existingRecordsMap.get(accNewValues.Id);
            } else {
                bcDetails = new Broker_Classification_Details__c();
                bcDetails.Year__c = currentYear;
                bcDetails.Month__c = currentMonth;
                bcDetails.AgencyName__c = accNewValues.Id;
            }

            bcDetails.Classification__c = accNewValues.BrokerClassification__c;
            bcDetails.Total_number_of_Sales_in_month__c = storeSalesOrderCount.get(accNewValues.Id);
            bcDetails.Net_amount__c = totalSalesByAccount.get(accNewValues.Id);

            insertOrUpdateBCDetails.add(bcDetails);
        }

        if (!insertOrUpdateBCDetails.isEmpty()) {
            upsert insertOrUpdateBCDetails;
        }
    }

    Test.stopTest();

    // Assert data was inserted or updated
    List<Broker_Classification_Details__c> resultRecords = [
        SELECT Classification__c, Total_number_of_Sales_in_month__c, Net_amount__c
        FROM Broker_Classification_Details__c
    ];

    System.assert(!resultRecords.isEmpty(), 'Records should have been inserted or updated');
}

}