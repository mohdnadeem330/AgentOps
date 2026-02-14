@isTest
public class ReSalesManagerCommissionLineBatchTest {

    public static void getData(){
        Account acc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220212');
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryCategory__c = 'Aldar Employees';
        opp.EnquiryTrigger__c = 'Aldar Hospitality';
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        unit.CompletionDate__c = System.today()+10;
        insert unit;
        
        User usr = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.SalesManager__c = UserInfo.getUserId();
        salesOrder.BrokerManager__c = UserInfo.getUserId();
        salesOrder.InventoryLaunch__c = 'Inventory';
        salesOrder.BookingDate__c = date.today().addDays(-3);
        salesOrder.SalesApprovedDate__c = date.today().addDays(-3);
        salesOrder.NetAmount__c = 50000;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;
        
        SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit.Id;
        salesOrder1.SalesManager__c = UserInfo.getUserId();
        salesOrder1.BrokerManager__c = UserInfo.getUserId();
        salesOrder1.InventoryLaunch__c = 'Inventory';
        salesOrder1.BookingDate__c = date.today().addDays(-3);
        salesOrder1.SalesApprovedDate__c = date.today().addDays(-3);
        salesOrder1.NetAmount__c = 50000;
        salesOrder1.Status__c = 'Sold';
        insert salesOrder1;

        System.debug('Unit::'+ [Select Id,OffPlanProperty__c, CompletionDate__c From Unit__c where Id=:unit.Id ]);
        Opportunity reSalesopp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        reSalesopp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Resale').getRecordTypeId();
        reSalesopp.EnquiryCategory__c = 'Aldar Employees';
        reSalesopp.EnquiryTrigger__c = 'Aldar Hospitality';
        reSalesopp.Unit__c = unit.id;
        reSalesopp.TransferredDate__c= system.Today(); 
        reSalesopp.OwnerId = usr.Id;
        reSalesopp.Amount = 10000000;
        reSalesopp.Transferred__c = true;
        reSalesopp.SalesOrder__c = salesOrder.Id;
        insert reSalesopp;
        
        Opportunity reSalesopp1 = TestObjectsFactory.getOpportunityRecord(acc.Id);
        reSalesopp1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Resale').getRecordTypeId();
        reSalesopp1.EnquiryCategory__c = 'Aldar Employees';
        reSalesopp1.EnquiryTrigger__c = 'Aldar Hospitality';
        reSalesopp1.Unit__c = unit.id;
        reSalesopp1.TransferredDate__c= system.Today(); 
        reSalesopp1.OwnerId = usr.Id;
        reSalesopp1.Amount = 10000000;
        reSalesopp1.Transferred__c = true;
        reSalesopp1.SalesOrder__c = salesOrder1.Id;
        insert reSalesopp1;
        
        PaymentPlan__c paymentPlan = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlan;
        
        list<PaymentInstallments__c> paymentInstallmentList = TestObjectsFactory.getPaymentInstallment(paymentPlan.Id);
        insert paymentInstallmentList;
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.getInstallmentLines(salesOrder.id, paymentPlan.Id, paymentInstallmentList);
        insert  installmentLineList;
        
        List<InstallmentLines__c> installmentLineList1 = TestObjectsFactory.getInstallmentLines(salesOrder1.id, paymentPlan.Id, paymentInstallmentList);
        insert  installmentLineList1;
        
        CommissionLineItem__c objCommissionLineItem = TestObjectsFactory.createCommissionLineItems(salesOrder.Id, installmentLineList[0].Id);
        objCommissionLineItem.TotalPayableCommission__c = 500;
        update objCommissionLineItem;
        CommissionLineItem__c objCommissionLineItem1 = TestObjectsFactory.createCommissionLineItems(salesOrder1.Id, installmentLineList[0].Id);
        objCommissionLineItem1.TotalPayableCommission__c = 500;
        update objCommissionLineItem1;
        //objCommissionLineItem.CommissionType__c = Constants.COMMISSION_LINE_INTERNAL_COMMISSION;  
        //insert objCommissionLineItem;
        
        MonthlySalesTarget__c monthlySalesTarget = TestObjectsFactory.getMonthlySalesTargetRecord(usr.Id, 'ReSales');
        monthlySalesTarget.TargetMonth__c = String.valueOf(date.today().month());
        monthlySalesTarget.TargetYear__c = String.valueOf(date.today().year());
        insert monthlySalesTarget;
       
        MonthlySalesTarget__c monthlySalesTarget2 = TestObjectsFactory.getMonthlySalesTargetRecord(usr.Id, 'ReSales');
        monthlySalesTarget2.AchievedAmount__c = 50000;
        monthlySalesTarget2.TargetMonth__c = String.valueOf(date.today().month());
        monthlySalesTarget2.TargetYear__c = String.valueOf(date.today().year());
        insert monthlySalesTarget2;
    }
    
    @isTest
    public static void testReSaleMangerCommissionLineBatch() {
        
        getData();
        List<CommissionLineItem__c> lstCommisionLineItems = [SELECT SalesOrder__c,CommissionType__c,CommissionPercentage__c,
                                                            CommissionAmount__c,SalesManager__c,InstallmentLine__c,TotalPayableCommission__c FROM CommissionLineItem__c];
        Map<String,CommissionPayoutLine__c> mapExistingCommissionPayOuts = new Map<String,CommissionPayoutLine__c>();
        List<CommissionPayoutLine__c> objCommisionPayoutLineItemList = new List<CommissionPayoutLine__c>();
        
        string strMonth = String.valueOf(date.today().month()-1);
        string strYear = String.valueOf(date.today().year());
        Map<Id, MonthlySalesTarget__c> managerBasedMonSalesTarget = new Map<Id, MonthlySalesTarget__c>();
        List<MonthlySalesTarget__c> lstMonthlySalesTarget = new List<MonthlySalesTarget__c>();
        for(MonthlySalesTarget__c objMSaleTarget : [SELECT AcceleratorCommissionAmount__c,AcceleratorPercentage__c,TargetAmount__c,
                                                    TargetMonth__c,KPI1__c,KPI2__c,TargetYear__c,
                                                    AcceleratorTargetAmount__c,ResourceName__c,
                                                    KPIPayoutPercentage__c FROM MonthlySalesTarget__c 
                                                    WHERE TargetMonth__c =: strMonth AND TargetYear__c =: strYear]){
                                                        managerBasedMonSalesTarget.put(objMSaleTarget.ResourceName__c, objMSaleTarget);
                                                        lstMonthlySalesTarget.add(objMSaleTarget); 
                                                    }
        Map<String, object> results = new Map<String, object>();
        reSalesCommissionPayoutService.getCalculatedCommissionPayouts(mapExistingCommissionPayOuts,
                                                                     lstCommisionLineItems,
                                                                     String.valueOf(date.today().month()),
                                                                     String.valueOf(date.today().year()),
                                                                     objCommisionPayoutLineItemList,
                                                                     managerBasedMonSalesTarget);
        Test.startTest();
        try {
            database.executeBatch(new ReSalesManagerCommissionLineBatch(String.valueOf(date.today().month()), String.valueOf(date.today().year())));
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        try {} catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    @isTest
    public static void testReSaleMangerCommissionLineBatch2() {
        
        getData();
        Test.startTest();
        try {
            database.executeBatch(new ReSalesManagerCommissionLineBatch());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        try {} catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
}