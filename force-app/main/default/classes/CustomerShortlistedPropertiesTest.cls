@isTest
public class CustomerShortlistedPropertiesTest {
    
    
    private static void setupRestRequest(String requestBody,String accountId,Boolean digitalSales){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/shortlistedProperty';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        CustomerShortlistedPropertiesWebservice.doPost(accountId,digitalSales);
        Test.stopTest();
    }
    
    @testSetup
    public static void testSetupData(){
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.ResidentStatus__pc = 'Non-Resident';
        acc.CountryOfResidence__pc = 'India';
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.isDigitalSales__c = true;
        insert opp;
        
        Project__c proj = TestObjectsFactory.getProjectRecord('25083');
        proj.Name = 'Gate';
        proj.LeadProjectName__c = 'Gate';
        proj.Damascus_Community_Name__c = 'Gate';
        insert proj;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Available';
        unit.Project__c = proj.Id;
        unit.DigitalSales__c = true;
        insert unit;
        
        Communication_Preference__c cpRecord1 = new Communication_Preference__c(
            Category__c = 'Booking',
            Source_Type__c = 'Sales Manager',
            Status__c = 'Fasttrack Completed',
            Active__c = true,
            Unit__c	= Unit.Id,
            Project__c = proj.Name,
            Account__c = acc.Id,
            Opportunity__c = opp.Id,
            Sent_Email_Date_Time__c = DateTime.now(),
            ownerId = userInfo.getUserId());
        insert cpRecord1; 
        
        Communication_Preference__c cpRecord = new Communication_Preference__c(
            Category__c = 'Booking',
            Source_Type__c = 'Live Aldar',
            Status__c = 'Fasttrack Completed',
            Active__c = true,
            Unit__c	= Unit.Id,
            Project__c = proj.Name,
            Account__c = acc.Id,
            Opportunity__c = opp.Id,
            Sent_Email_Date_Time__c = DateTime.now());
        insert cpRecord;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Status__c = 'Reservation In Progress';
        salesOrder.Opportunity__c = opp.Id;
        salesOrder.Is_Digital_Sales__c = true;
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        
        ReceiptAcknowledgement__c receipt = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id,acc.Id,Opp.Id,'Online');
        receipt.Status__c = 'Received';
        receipt.Amount__c = 50000;
        receipt.SalesOrder__c = salesOrder.Id;
        insert receipt;
        
        ReceiptAcknowledgement__c receipt1 = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id,acc.Id,Opp.Id,'Online');
        receipt1.Status__c = 'Received';
        receipt1.Amount__c = 50000;
        receipt1.SalesOrder__c = salesOrder.Id;
        insert receipt1;
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id,1); 
    }
    
    @isTest
    public static void negativeTesting_Account_notFound(){
        
        Account acc = [Select Id From Account Where Name = 'Test Account' Limit 1];
        Project__c proj = [Select Id,Name From Project__c Where Name = 'Gate' Limit 1];
        Unit__c unit = [Select Id,Name,Status__c,Project__c From Unit__c Where Project__c =: proj.Id Limit 1];
        
        String requestBody = JSON.serialize(new Map<String, Object>{ 
            'accountId' => acc.Id,
                'digitalSales' => true
                });
        
        setupRestRequest(requestBody,'001FW000008ozABCDE',true);
    }
    
    
    @isTest
    public static void positiveTesting(){ 
        
        Account acc = [Select Id, PersonContactId From Account Where Name = 'Test Account' Limit 1];   
        Project__c proj = [Select Id,Name,LeadProjectName__c From Project__c Where LeadProjectName__c = 'Gate' Limit 1];
        Unit__c unit = [Select Id,Name,Status__c,Project__c From Unit__c Where Project__c =: proj.Id Limit 1];
        
        String requestBody = JSON.serialize(new Map<String, Object>{ 
            'accountId' => acc.Id,
                'digitalSales' => true
                });
        
        setupRestRequest(requestBody,acc.Id,true);
    }
    
    @isTest
    public static void lockedBySameCustomer(){ 
        
        Account acc = [Select Id, PersonContactId From Account Where Name = 'Test Account' Limit 1];   
        Project__c proj = [Select Id,Name,LeadProjectName__c From Project__c Where LeadProjectName__c = 'Gate' Limit 1];
        Unit__c unit = [Select Id,Name,Status__c,Project__c From Unit__c Where Project__c =: proj.Id Limit 1];
        
        unit.Status__c = 'Reserved';
        unit.LockedByCustomer__c = acc.Id;
        unit.LockedBy__c = userInfo.getUserId(); 
        update unit;
        
        String requestBody = JSON.serialize(new Map<String, Object>{ 
            'accountId' => acc.Id,
                'digitalSales' => true
                });
        
        setupRestRequest(requestBody,acc.Id,true);
    }
    
    @isTest
    public static void lockedByOtherUser(){ 
        
        Account acc = [Select Id, PersonContactId From Account Where Name = 'Test Account' Limit 1];   
        Project__c proj = [Select Id,Name,LeadProjectName__c From Project__c Where LeadProjectName__c = 'Gate' Limit 1];
        Unit__c unit = [Select Id,Name,Status__c,Project__c From Unit__c Where Project__c =: proj.Id Limit 1];
        
        Account acc1 = TestObjectsFactory.getPersonAccountRecord();
        acc1.ResidentStatus__pc = 'Non-Resident';
        acc1.CountryOfResidence__pc = 'India';
        acc1.PassportNumber__pc = 'RARETE636';
        insert acc1;
        
        unit.Status__c = 'Reserved';
        unit.LockedByCustomer__c = acc1.Id;
        unit.LockedBy__c = userInfo.getUserId(); 
        update unit;
        
        String requestBody = JSON.serialize(new Map<String, Object>{ 
            'accountId' => acc1.Id,
                'digitalSales' => true
                });
        
        setupRestRequest(requestBody,acc1.Id,true);
    }
    
    @isTest
    public static void positiveTesting_withReceiptsAndInstallments() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Project__c proj = [SELECT Id FROM Project__c WHERE Name = 'Gate' LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c WHERE Project__c = :proj.Id LIMIT 1];
        
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c WHERE Unit__c = :unit.Id LIMIT 1];
        
        ReceiptAcknowledgement__c rec = new ReceiptAcknowledgement__c(
            Status__c = 'Received',
            Amount__c = 10000,
            SalesOrder__c = so.Id,
            PaymentType__c = 'Online'
        );
        insert rec;
        
        PaymentPlan__c paymentPlan = TestObjectsFactory.getPaymentPlan();
        insert paymentPlan;
        
        List<PaymentInstallments__c> paymentInstallmentList = TestObjectsFactory.getPaymentInstallments(paymentPlan.Id, 2);
        insert paymentInstallmentList;
        
        InstallmentLines__c inst = new InstallmentLines__c(
            SalesOrder__c = so.Id,
            InstallmentNumber__c = 1,
            AmountReceived__c = 2000,
            PaymentInstallments__c = paymentInstallmentList[0].Id,
            InstallmentPercentage__c = paymentInstallmentList[0].InstallmentPercentage__c,
            InstallmentAmount__c = 10000,
            Description__c = 'Test'
        );
        insert inst;
        
        String requestBody = JSON.serialize(new Map<String, Object>{ 
            'accountId' => acc.Id,
                'digitalSales' => true
                });
        
        setupRestRequest(requestBody, acc.Id, true);
    }
    
}