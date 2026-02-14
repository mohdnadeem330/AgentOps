@isTest
private class DefaultAndTerminationCalloutHelperTest {
   //Create setupData
    @testSetup static void setupData() {
        Id DandTRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.DEFAULT_AND_TERMINATION);

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
        
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;
        list<PaymentInstallments__c> installmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert installmentLines;
        paymentPlanRecord.IsActive__c =Constants.YES;
        update paymentPlanRecord;
        BuildingSectionMapping__c buldingPaymentMapping = TestObjectsFactory.getBuildingSectionMapping(paymentPlanRecord.Id,buildingRecord.Id);
        insert buldingPaymentMapping;   
        
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(opp.ID,acc.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        insert salesOrderRecord;
        
        list<InstallmentLines__c> installmentLinesToInsert = new list<InstallmentLines__c>();
        Decimal totalNetSellingPrice = 1000000;
        Decimal totalCommission = 10000;
        for(PaymentInstallments__c tempInstallmentLine : [select id,BrokerPayoutPercentage__c,Description__c,InstallmentNumber__c,InstallmentPercentage__c,InstallmentDate__c,PaymentPlan__c from PaymentInstallments__c]){
            installmentLinesToInsert.add(new InstallmentLines__c( 
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
        if(!installmentLinesToInsert.isEmpty()){
            installmentLinesToInsert[0]. SyncStatus__c =Constants.STATUS_FAILED;
            insert installmentLinesToInsert;
        }
        
          //SR TEMPLATE
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = Constants.DEFAULT_AND_TERMINATION;
        SR_Template.HexaBPM__SR_RecordType_API_Name__c=Constants.DEFAULT_AND_TERMINATION;
        insert SR_Template;
        
        
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
        insert SRStep;
        
        //SR Status 
        insert new list<HexaBPM__SR_Status__c>{TestObjectsFactory.getSRStatus(Constants.SUBMITTED),TestObjectsFactory.getSRStatus(Constants.STATUS_DRAFT)};
        
        //SR AND STEP
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = DandTRecordTypeId;
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        //SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unitrecord.Id;
        SR.SalesOrder__c = salesOrderRecord.Id;
        SR.InstallmentLine__c = installmentLinesToInsert[0].Id;
        insert SR;
        
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = Constants.STEP_NAME_CUSTOMER_NEGOTIATION;
        step.HexaBPM__SR__c = SR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        insert step; 
        
        
    }
    
    @isTest
    public static void testDefaultCalloutSR (){
        HexaBPM__Service_Request__c srRecord = [select id from HexaBPM__Service_Request__c limit 1] ;
        Test.startTest();
            String responseBody = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "80741660-85c0-11ed-9cc4-066e2175c02a","results": [{"sfRequestId": "80741660-85c0-11ed-9cc4-066e2175c02a","sfServiceReqId": "'+srRecord.Id+'","status": "Success","errorMsg": "","erpId": "185506"}]}';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            DefaultAndTerminationCalloutHelper.syncDefaultServiceRequest(new set<ID>{srRecord.Id});
        Test.stopTest();
    }
    @isTest
    public static void testDefaultErrorCalloutSR (){
        HexaBPM__Service_Request__c srRecord = [select id from HexaBPM__Service_Request__c limit 1] ;
        Test.startTest();
            String responseBody = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "80741660-85c0-11ed-9cc4-066e2175c02a","results": [{"sfRequestId": "80741660-85c0-11ed-9cc4-066e2175c02a","sfServiceReqId": "'+srRecord.Id+'","status": "Failed","errorMsg": "Failed","erpId": "185506"}]}';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            DefaultAndTerminationCalloutHelper.syncDefaultServiceRequest(new set<ID>{srRecord.Id});
        Test.stopTest();
    }
    
    @isTest
    public static void testMilestoneCalloutSR (){
        PaymentInstallments__c paymentIns = [select id from PaymentInstallments__c limit 1] ;
        InstallmentLines__c ins = [select id,InstallmentDate__c from InstallmentLines__c limit 1];
        ins.InstallmentDate__c = ins.InstallmentDate__c.AddDays(1);
        Test.startTest();
            String responseBody = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "80741660-85c0-11ed-9cc4-066e2175c02a","results": [{"sfRequestId": "80741660-85c0-11ed-9cc4-066e2175c02a","sfInstallmentId": "'+paymentIns.Id+'","status": "Success","errorMsg": "","erpId": "185506"}]}';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            DefaultAndTerminationCalloutHelper.syncInstallments(new set<ID>{paymentIns.Id});
        Test.stopTest();
    }
    @isTest
    public static void testMilestoneErrCalloutSR (){
        PaymentInstallments__c paymentIns = [select id from PaymentInstallments__c limit 1] ;
        InstallmentLines__c ins = [select id,InstallmentDate__c from InstallmentLines__c limit 1];
        ins.InstallmentDate__c = ins.InstallmentDate__c.AddDays(1);
        Test.startTest();
            String responseBody = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "80741660-85c0-11ed-9cc4-066e2175c02a","results": [{"sfRequestId": "80741660-85c0-11ed-9cc4-066e2175c02a","sfInstallmentId": "'+paymentIns.Id+'","status": "Failed","errorMsg": "Failed","erpId": "185506"}]}';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            DefaultAndTerminationCalloutHelper.syncInstallments(new set<ID>{paymentIns.Id});
        Test.stopTest();
    }
    @isTest
    public static void testPHPPErrCalloutSR (){
        PaymentInstallments__c paymentIns = [select id from PaymentInstallments__c limit 1] ;
        InstallmentLines__c ins = [select id,InstallmentDate__c from InstallmentLines__c limit 1];
        ins.InstallmentDate__c = ins.InstallmentDate__c.AddDays(1);
        Test.startTest();
            String responseBody = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "80741660-85c0-11ed-9cc4-066e2175c02a","results": [{"sfRequestId": "80741660-85c0-11ed-9cc4-066e2175c02a","sfInstallmentId": "'+paymentIns.Id+'","status": "Failed","errorMsg": "Failed","erpId": "185506"}]}';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            DefaultAndTerminationCalloutHelper.syncPHPPInstallments(new set<ID>{paymentIns.Id});
        Test.stopTest();
    }
    @isTest
    public static void testMilestoneErrCalloutSRwithBatch (){
        //PaymentInstallments__c paymentIns = [select id from PaymentInstallments__c limit 1] ;
        InstallmentLines__c ins = [select id,SalesOrder__c,InstallmentNumber__c,OriginalInstallmentDate__c,InstallmentDate__c from InstallmentLines__c where  SyncStatus__c != :Constants.STATUS_SYNCED limit 1];
        
        ins.InstallmentDate__c = ins.InstallmentDate__c.AddDays(1);
        Test.startTest();
            String responseBody = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "80741660-85c0-11ed-9cc4-066e2175c02a","results": [{"sfRequestId": "80741660-85c0-11ed-9cc4-066e2175c02a","sfInstallmentId": "'+ins.Id+'","status": "Failed","errorMsg": "Failed","erpId": "185506"}]}';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
            DefaultAndTerminationCalloutHelper.syncInstallmentswithBatch(new set<ID>{ins.Id});
        Test.stopTest();
    }
}