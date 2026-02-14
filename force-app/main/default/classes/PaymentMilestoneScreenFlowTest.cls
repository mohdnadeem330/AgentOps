@isTest
public class PaymentMilestoneScreenFlowTest {

    // Helper method to create PaymentInstallments__c records
    private static List<PaymentInstallments__c> createPaymentInstallments(Integer numRecords) {
         PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        
            insert paymentPlanRecord;
        List<PaymentInstallments__c> installments = new List<PaymentInstallments__c>();
        for (Integer i = 0; i < numRecords; i++) {
            PaymentInstallments__c installment = new PaymentInstallments__c(
               
                InstallmentDate__c = Date.today().adddays(i),
                PaymentPlan__c = paymentPlanRecord.Id,
                Associated_Projects__c = 'The Source',
                ApprovalStatus__c = 'Draft',
                Description__c ='Test Description',
                InstallmentNumber__c = i,
                InstallmentPercentage__c=10
            );
            installments.add(installment);
        }
        insert installments;
        return installments;
    }
    
     private static List<PaymentInstallments__c> createPaymentInstallments2(Integer numRecords) {
         PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        
            insert paymentPlanRecord;
        List<PaymentInstallments__c> installments = new List<PaymentInstallments__c>();
        for (Integer i = 0; i < numRecords; i++) {
            PaymentInstallments__c installment = new PaymentInstallments__c(
               
                
                PaymentPlan__c = paymentPlanRecord.Id,
                Associated_Projects__c = 'The Source',
                ApprovalStatus__c = 'Draft',
                Description__c ='Test Description',
                InstallmentNumber__c = i,
                InstallmentPercentage__c=10
            );
            installments.add(installment);
        }
        insert installments;
        return installments;
    }

    // Helper method to create InstallmentLines__c records
    private static List<InstallmentLines__c> createInstallmentLines(List<PaymentInstallments__c> paymentInstallments) {
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@gmail.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.MortgageApplicable__c = 'Yes';
        salesOrder.Contact__c = con.Id;
        insert salesOrder;
        
        List<InstallmentLines__c> lines = new List<InstallmentLines__c>();
        for (PaymentInstallments__c installment : paymentInstallments) {
            InstallmentLines__c line = new InstallmentLines__c(
                PaymentInstallments__c = installment.Id,
                PaymentInstallments__r = installment, // Assuming the relationship is correct
                InstallmentAmount__c =1000,
                SalesOrder__c=salesOrder.Id,
                InstallmentPercentage__c=10,
                InstallmentNumber__c= 1,
                Description__c='Desc'
                
            );
            lines.add(line);
        }
        insert lines;
        return lines;
    }
    
     @isTest
    public static void testProcessAccountIds_Success2() {
         List<PaymentInstallments__c> paymentInstallments = createPaymentInstallments2(3);
        
        // Create corresponding InstallmentLines__c records
        //createInstallmentLines(paymentInstallments);
        
        // Create InputPaymentInstallment object
        PaymentMilestoneScreenFlow.InputPaymentInstallment input = new PaymentMilestoneScreenFlow.InputPaymentInstallment();
        input.paymentInstallmentIds = new List<Id>{paymentInstallments[0].Id, paymentInstallments[1].Id, paymentInstallments[2].Id};
        
        Test.startTest();
        // Call the method with the input data
        List<PaymentMilestoneScreenFlow.OutputMessage> outputMessages = PaymentMilestoneScreenFlow.processAccountIds(new List<PaymentMilestoneScreenFlow.InputPaymentInstallment>{input});
        Test.stopTest();
        
    }

    @isTest
    public static void testProcessAccountIds_Success() {
        // Create sample PaymentInstallments__c records
        List<PaymentInstallments__c> paymentInstallments = createPaymentInstallments(3);
        
        // Create corresponding InstallmentLines__c records
        createInstallmentLines(paymentInstallments);
        
        // Create InputPaymentInstallment object
        PaymentMilestoneScreenFlow.InputPaymentInstallment input = new PaymentMilestoneScreenFlow.InputPaymentInstallment();
        input.paymentInstallmentIds = new List<Id>{paymentInstallments[0].Id, paymentInstallments[1].Id, paymentInstallments[2].Id};
        
        Test.startTest();
        // Call the method with the input data
        List<PaymentMilestoneScreenFlow.OutputMessage> outputMessages = PaymentMilestoneScreenFlow.processAccountIds(new List<PaymentMilestoneScreenFlow.InputPaymentInstallment>{input});
        Test.stopTest();

    }

    @isTest
    public static void testProcessAccountIds_InstallmentLinesNotAvailable() {
        // Create sample PaymentInstallments__c records
         Test.startTest();
        List<PaymentInstallments__c> paymentInstallments = createPaymentInstallments(3);

        PaymentMilestoneScreenFlow.InputPaymentInstallment input = new PaymentMilestoneScreenFlow.InputPaymentInstallment();
        input.paymentInstallmentIds = new List<Id>{paymentInstallments[0].Id, paymentInstallments[1].Id, paymentInstallments[2].Id};
        
        
        // Call the method with the input data
        List<PaymentMilestoneScreenFlow.OutputMessage> outputMessages = PaymentMilestoneScreenFlow.processAccountIds(new List<PaymentMilestoneScreenFlow.InputPaymentInstallment>{input});
        Test.stopTest();

    }

    @isTest
    public static void testProcessAccountIds_ApprovalPending() {
        // Create sample PaymentInstallments__c records with approval pending status
        Test.startTest();
        List<PaymentInstallments__c> paymentInstallments = createPaymentInstallments(1);
        paymentInstallments[0].ApprovalStatus__c = 'Approval Pending';
        update paymentInstallments;
        
        // Create InputPaymentInstallment object
        PaymentMilestoneScreenFlow.InputPaymentInstallment input = new PaymentMilestoneScreenFlow.InputPaymentInstallment();
        input.paymentInstallmentIds = new List<Id>{paymentInstallments[0].Id};
        
        
        // Call the method with the input data
        List<PaymentMilestoneScreenFlow.OutputMessage> outputMessages = PaymentMilestoneScreenFlow.processAccountIds(new List<PaymentMilestoneScreenFlow.InputPaymentInstallment>{input});
        Test.stopTest();

    }

    @isTest
    public static void testProcessAccountIds_InstallmentDateDifference() {
        Test.startTest();
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;
        
        PaymentPlan__c paymentPlanRecord2 = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord2;

       PaymentInstallments__c installment = new PaymentInstallments__c();
                installment.InstallmentDate__c = Date.today();
                installment.PaymentPlan__c = paymentPlanRecord.Id;
                installment.Associated_Projects__c = 'The Source';
                installment.ApprovalStatus__c = 'Draft';
                installment.Description__c ='Test Description';
                installment.InstallmentNumber__c = 1;
                installment.InstallmentPercentage__c=10;
           insert installment;

         PaymentInstallments__c installment2 = new PaymentInstallments__c();
                installment2.InstallmentDate__c = Date.today().addDays(10);
                installment2.PaymentPlan__c = paymentPlanRecord2.Id;
                installment2.Associated_Projects__c = 'Nareel';
                installment2.ApprovalStatus__c = 'Draft';
                installment2.Description__c ='Test Description';
                installment2.InstallmentNumber__c = 1;
                installment2.InstallmentPercentage__c=10;
           insert installment2;

        PaymentMilestoneScreenFlow.InputPaymentInstallment input = new PaymentMilestoneScreenFlow.InputPaymentInstallment();
        input.paymentInstallmentIds = new List<Id>{installment.Id, installment2.Id};
        system.debug('@@@input'+input);

        List<PaymentMilestoneScreenFlow.OutputMessage> outputMessages = PaymentMilestoneScreenFlow.processAccountIds(new List<PaymentMilestoneScreenFlow.InputPaymentInstallment>{input});
        Test.stopTest();

    }
    
    
     /* @isTest
    public static void testProcessAccountIds_PaymentPlanDifference() {
        Test.startTest();
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;
        system.debug('paymentPlanRecord@@@'+paymentPlanRecord);
       PaymentInstallments__c installment = new PaymentInstallments__c();
                installment.InstallmentDate__c = Date.today();
                installment.PaymentPlan__c = paymentPlanRecord.Id;
                installment.Associated_Projects__c = 'The Source';
                installment.ApprovalStatus__c = 'Draft';
                installment.Description__c ='Test Description';
                installment.InstallmentNumber__c = 1;
                installment.InstallmentPercentage__c=10;
           insert installment;
        system.debug('installment@@@'+installment);
        
        PaymentPlan__c paymentPlanRecord2 = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord2; 
        system.debug('paymentPlanRecord2@@@'+paymentPlanRecord2);
         PaymentInstallments__c installment2 = new PaymentInstallments__c();
                installment2.InstallmentDate__c = Date.today();
                installment2.PaymentPlan__c = paymentPlanRecord2.Id;
                installment2.Associated_Projects__c = 'Nareel';
                installment2.ApprovalStatus__c = 'Draft';
                installment2.Description__c ='Test Description';
                installment2.InstallmentNumber__c = 1;
                installment2.InstallmentPercentage__c=10;
           insert installment2;
       

        PaymentMilestoneScreenFlow.InputPaymentInstallment input = new PaymentMilestoneScreenFlow.InputPaymentInstallment();
        input.paymentInstallmentIds = new List<Id>{installment.Id, installment2.Id};
  
        List<PaymentMilestoneScreenFlow.OutputMessage> outputMessages = PaymentMilestoneScreenFlow.processAccountIds(new List<PaymentMilestoneScreenFlow.InputPaymentInstallment>{input});
        Test.stopTest();

    }*/
    
    /*@isTest
    public static void testProcessAccountIds_ProjectDifference() {
        Test.startTest();
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;
        system.debug('paymentPlanRecord@@@'+paymentPlanRecord);
       PaymentInstallments__c installment = new PaymentInstallments__c();
                installment.InstallmentDate__c = Date.today();
                installment.PaymentPlan__c = paymentPlanRecord.Id;
                installment.Associated_Projects__c = 'The Source';
                installment.ApprovalStatus__c = 'Draft';
                installment.Description__c ='Test Description';
                installment.InstallmentNumber__c = 1;
                installment.InstallmentPercentage__c=10;
           insert installment;
        system.debug('installment@@@'+installment);
        
        

         PaymentInstallments__c installment2 = new PaymentInstallments__c();
                installment2.InstallmentDate__c = Date.today();
                installment2.PaymentPlan__c = paymentPlanRecord.Id;
                installment2.Associated_Projects__c = 'Nareel';
                installment2.ApprovalStatus__c = 'Draft';
                installment2.Description__c ='Test Description';
                installment2.InstallmentNumber__c = 1;
                installment2.InstallmentPercentage__c=10;
           insert installment2;
        
        
     
        PaymentMilestoneScreenFlow.InputPaymentInstallment input = new PaymentMilestoneScreenFlow.InputPaymentInstallment();
        input.paymentInstallmentIds = new List<Id>{installment.Id, installment2.Id};
        
        List<PaymentMilestoneScreenFlow.OutputMessage> outputMessages = PaymentMilestoneScreenFlow.processAccountIds(new List<PaymentMilestoneScreenFlow.InputPaymentInstallment>{input});
        Test.stopTest();
        
        
    }*/

   
}