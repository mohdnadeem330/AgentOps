@isTest
public class CC_ALDRA_CreditNoteCreationProcessTest {
    @testSetup static void setupData() {
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'Credit_Note_Creation']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }
        User us = [SELECT Id FROM User WHERE IsActive=true and UserName!=:Userinfo.getUserName() and ProfileId=:UserInfo.getProfileId() Limit 1];
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Credit Note Creation';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='CreditNoteCreation';
        insert SR_Template;
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('Credit_Note_Creation');
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        SR.Credit_Note_Sub_Type__c = 'Installment Reversal';
        SR.Amount__c = 123.00;
        SR.SRType__c = 'Credit Note';
        SR.ChargeType__c = 'Credit Note';
        SR.InvoiceReversal__c=false;
        insert SR;
        
        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'Manage Receipt';
        ST.HexaBPM__Code__c = 'Manage Receipt';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST;
        
        HexaBPM__Status__c objStatus = new HexaBPM__Status__c();
        objStatus.Name = 'Approved';
        objStatus.HexaBPM__Type__c = 'End';
        objStatus.HexaBPM__Code__c = 'Approved';
        insert objStatus;
        
        HexaBPM__Status__c objStatus2 = new HexaBPM__Status__c();
        objStatus2.Name = 'Completed';
       // objStatus2.HexaBPM__Type__c = 'End';
        objStatus2.HexaBPM__Code__c = 'Completed';
        insert objStatus2;
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = 'Manage Receipt';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep;
        
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'Manage Receipt';
        step.HexaBPM__SR__c = SR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        step.OwnerId = us.Id;
        step.HexaBPM__Status__c = objStatus2.Id;
        insert step; 
        
        HexaBPM__Step__c step2 = new HexaBPM__Step__c();
        step2.HexaBPM__Summary__c = 'Verify the Request';
        step2.HexaBPM__SR__c = SR.Id;
        step2.HexaBPM__SR_Step__c = SRStep.Id;
        step2.HexaBPM__Start_Date__c = System.today();
        step2.HexaBPM__Status__c = objStatus.Id;
        insert step2; 
        
        
        //FOR REVERSAL
        HexaBPM__Service_Request__c SR2 = new HexaBPM__Service_Request__c();
        SR2.RecordTypeId = recordTypeSR.get('Credit_Note_Creation');
        SR2.HexaBPM__Customer__c = acc.Id;
        SR2.HexaBPM__Contact__c = acc.PersonContactId;
        SR2.OwnerId = UserInfo.getUserId();
        SR2.HexaBPM__SR_Template__c = SR_Template.Id;
        SR2.Unit__c = unit.Id;
        SR2.SalesOrder__c = salesOrder.Id;
        SR2.Credit_Note_Sub_Type__c = 'Installment Reversal';
        SR2.Amount__c = 123.00;
        SR2.SRType__c = 'Credit Note';
        SR2.ChargeType__c = 'Credit Note';
        SR2.InvoiceReversal__c=true;
        insert SR2;
        
        HexaBPM__Step__c step11 = new HexaBPM__Step__c();
        step11.HexaBPM__Summary__c = 'Manage Receipt';
        step11.HexaBPM__SR__c = SR2.Id;
        step11.HexaBPM__SR_Step__c = SRStep.Id;
        step11.HexaBPM__Start_Date__c = System.today();
        step11.OwnerId = us.Id;
        insert step11; 
        
        
        HexaBPM__Step__c step22 = new HexaBPM__Step__c();
        step22.HexaBPM__Summary__c = 'Verify the Request';
        step22.HexaBPM__SR__c = SR2.Id;
        step22.HexaBPM__SR_Step__c = SRStep.Id;
        step22.HexaBPM__Start_Date__c = System.today();
        insert step22;
        
    }
    @isTest
    public static void callMethod (){
        Test.startTest();
        
        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c From HexaBPM__Service_Request__c WHERE InvoiceReversal__c=false Limit 1];
        List<HexaBPM__Step__c> stps = [Select Id, Name, HexaBPM__SR__c, Step_Template_Code__c,HexaBPM__Summary__c,HexaBPM__Status__c,HexaBPM__Status__r.Name,SRTemplateName__c From HexaBPM__Step__c WHERE (HexaBPM__Summary__c = 'Manage Receipt' OR HexaBPM__Summary__c = 'Verify the Request') AND HexaBPM__SR__c=:SR.Id ORDER BY CreatedDate DESC limit 2];
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);
        InstallmentLines__c il = new InstallmentLines__c();
        il.Id = installmentLineList[0].Id;
        il.InvoiceId__c = '1234';
        il.InvoiceNumber__c = '1234';
        il.InvoicedAmount__c = 100.00;
        update il;
        
        SR.InstallmentLine__c = il.Id;
        update SR;
        
        HexaBPM__Status__c status = [SELECT Id from HexaBPM__Status__c WHERE Name='Approved' Limit 1];
        List<HexaBPM__Step__c> stpList = new List<HexaBPM__Step__c>();
        for(HexaBPM__Step__c stp:stps) {
            if(stp.HexaBPM__Summary__c == 'Verify the Request') {
                stp.HexaBPM__Status__c = status.Id;
                stpList.add(stp);
            }
        }
        
        update stpList;
        
        CC_ALDRA_CreditNoteCreationProcess cc = new CC_ALDRA_CreditNoteCreationProcess();
        
        String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "396fbd20-fa08-11ed-acd1-06dbb03cb360", "results": { "othChgRes": [ { "sfRequestId": "396fbd20-fa08-11ed-acd1-06dbb03cb360", "srSFId": "a0Q250000059slaEAA", "sfId": "a2425000002qNaJAAU", "erpId": "", "recAcct": "", "expAcct": "", "taxAcct": "", "status": "Failure", "errorMsg": "Err in API Call : Error : no CM trx type id defined.Msg1: Error : no CM trx type id defined.", "invoiceNo": "" } ] } }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        
        cc.EvaluateCustomCode(SR, stpList[0]);
        
        Test.stopTest();
    }
    
    
    @isTest
    public static void callMethodPositive (){
        Test.startTest();
        
        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c From HexaBPM__Service_Request__c WHERE InvoiceReversal__c=false Limit 1];
        HexaBPM__Step__c stp = [Select Id, Name, HexaBPM__SR__c, Step_Template_Code__c,HexaBPM__Summary__c,HexaBPM__Status__c,HexaBPM__Status__r.Name,SRTemplateName__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Verify the Request' AND HexaBPM__SR__c=:SR.Id ORDER BY CreatedDate DESC limit 1];
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);
        InstallmentLines__c il = new InstallmentLines__c();
        il.Id = installmentLineList[0].Id;
        il.InvoiceId__c = '1234';
        il.InvoiceNumber__c = '1234';
        update il;
        
        SR.InstallmentLine__c = il.Id;
        update SR;
        
        CC_ALDRA_CreditNoteCreationProcess cc = new CC_ALDRA_CreditNoteCreationProcess();
        
        String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "396fbd20-fa08-11ed-acd1-06dbb03cb360", "results": { "othChgRes": [ { "sfRequestId": "396fbd20-fa08-11ed-acd1-06dbb03cb360", "srSFId": "a0Q250000059slaEAA", "sfId": "a2425000002qNaJAAU", "erpId": "123243", "recAcct": "123243", "expAcct": "123243", "taxAcct": "123243", "status": "Success", "errorMsg": "", "invoiceNo": "12343" } ] } }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        System.debug('stp -> '+stp.HexaBPM__Summary__c);
        System.debug('stp HexaBPM__Status__c -> '+stp.HexaBPM__Status__r.Name);
        cc.EvaluateCustomCode(SR, stp);
        
        Test.stopTest();
    }
    
    @isTest
    public static void callMethodNegative (){
        Test.startTest();
        
        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, Name, HexaBPM__SR__c, Step_Template_Code__c,HexaBPM__Summary__c,HexaBPM__Status__c,HexaBPM__Status__r.Name,SRTemplateName__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Verify the Request' AND HexaBPM__SR__c=:SR.Id ORDER BY CreatedDate DESC limit 1];
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);
        InstallmentLines__c il = new InstallmentLines__c();
        il.Id = installmentLineList[0].Id;
        il.InvoiceId__c = '1234';
        il.InvoiceNumber__c = '1234';
        update il;
        
        SR.InstallmentLine__c = il.Id;
        update SR;
        
        CC_ALDRA_CreditNoteCreationProcess cc = new CC_ALDRA_CreditNoteCreationProcess();
        
        String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "204", "correlationId": "396fbd20-fa08-11ed-acd1-06dbb03cb360", "results": { "othChgRes": [ { "sfRequestId": "396fbd20-fa08-11ed-acd1-06dbb03cb360", "srSFId": "a0Q250000059slaEAA", "sfId": "a2425000002qNaJAAU", "erpId": "123243", "recAcct": "123243", "expAcct": "123243", "taxAcct": "123243", "status": "Success", "errorMsg": "", "invoiceNo": "12343" } ] } }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        System.debug('stp -> '+stp.HexaBPM__Summary__c);
        System.debug('stp HexaBPM__Status__c -> '+stp.HexaBPM__Status__r.Name);
        cc.EvaluateCustomCode(SR, stp);
        
        Test.stopTest();
    }
    
    @isTest
    public static void callMethodPositiveInvoiceReversalMReceipt (){
        Test.startTest();
        
        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c From HexaBPM__Service_Request__c WHERE InvoiceReversal__c=true Limit 1];
        List<HexaBPM__Step__c> stps = [Select Id, Name, HexaBPM__SR__c, Step_Template_Code__c,HexaBPM__Summary__c,HexaBPM__Status__c,HexaBPM__Status__r.Name,SRTemplateName__c From HexaBPM__Step__c WHERE (HexaBPM__Summary__c = 'Manage Receipt' OR HexaBPM__Summary__c = 'Verify the Request') AND HexaBPM__SR__c=:SR.Id ORDER BY CreatedDate DESC limit 2];
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);
        
        InstallmentLines__c il = new InstallmentLines__c();
        il.Id = installmentLineList[0].Id;
        il.InvoiceId__c = '1234';
        il.InvoiceNumber__c = '1234';
        il.InvoicedAmount__c = 100.00;
        update il;
        
        SR.InstallmentLine__c = il.Id;
        update SR;
        
        HexaBPM__Status__c status = [SELECT Id from HexaBPM__Status__c WHERE Name='Completed' Limit 1];
        List<HexaBPM__Step__c> stpList = new List<HexaBPM__Step__c>();
        for(HexaBPM__Step__c stp:stps) {
            if(stp.HexaBPM__Summary__c == 'Manage Receipt') {
                stp.HexaBPM__Status__c = status.Id;
                stpList.add(stp);
            }
        }
        
        update stpList;
        
        CC_ALDRA_CreditNoteCreationProcess cc = new CC_ALDRA_CreditNoteCreationProcess();
        
        String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "396fbd20-fa08-11ed-acd1-06dbb03cb360", "results": { "othChgRes": [ { "sfRequestId": "396fbd20-fa08-11ed-acd1-06dbb03cb360", "srSFId": "a0Q250000059slaEAA", "sfId": "a2425000002qNaJAAU", "erpId": "123243", "recAcct": "123243", "expAcct": "123243", "taxAcct": "123243", "status": "Success", "errorMsg": "", "invoiceNo": "12343" } ] } }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        
        cc.EvaluateCustomCode(SR, stpList[0]);
        
        
        Test.stopTest();
    }
    
    @isTest
    public static void callMethodPositiveInvoiceReversalVerifyReqNeg(){
        Test.startTest();
        
        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c From HexaBPM__Service_Request__c WHERE InvoiceReversal__c=true Limit 1];
        List<HexaBPM__Step__c> stps = [Select Id, Name, HexaBPM__SR__c, Step_Template_Code__c,HexaBPM__Summary__c,HexaBPM__Status__c,HexaBPM__Status__r.Name,SRTemplateName__c From HexaBPM__Step__c WHERE (HexaBPM__Summary__c = 'Manage Receipt' OR HexaBPM__Summary__c = 'Verify the Request') AND HexaBPM__SR__c=:SR.Id ORDER BY CreatedDate DESC limit 2];
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);
        
        InstallmentLines__c il = new InstallmentLines__c();
        il.Id = installmentLineList[0].Id;
        il.InvoiceId__c = '1234';
        il.InvoiceNumber__c = '1234';
        il.InvoicedAmount__c = 100.00;
        update il;
        
        SR.InstallmentLine__c = il.Id;
        update SR;
        
        HexaBPM__Status__c status = [SELECT Id from HexaBPM__Status__c WHERE Name='Approved' Limit 1];
        List<HexaBPM__Step__c> stpList = new List<HexaBPM__Step__c>();
        for(HexaBPM__Step__c stp:stps) {
            if(stp.HexaBPM__Summary__c == 'Verify the Request') {
                stp.HexaBPM__Status__c = status.Id;
                stpList.add(stp);
            }
        }
        
        update stpList;
        CC_ALDRA_CreditNoteCreationProcess cc = new CC_ALDRA_CreditNoteCreationProcess();
        String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "396fbd20-fa08-11ed-acd1-06dbb03cb360", "results": { "othChgRes": [ { "sfRequestId": "396fbd20-fa08-11ed-acd1-06dbb03cb360", "srSFId": "a0Q250000059slaEAA", "sfId": "a2425000002qNaJAAU", "erpId": "123243", "recAcct": "123243", "expAcct": "123243", "taxAcct": "123243", "status": "Success", "errorMsg": "", "invoiceNo": "12343" } ] } }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        cc.EvaluateCustomCode(SR, stpList[0]);
        Test.stopTest();
    }
    
    @isTest
    public static void callMethodPositiveInvoiceReversalVerifyReqPos(){
        Test.startTest();
        
        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c From HexaBPM__Service_Request__c WHERE InvoiceReversal__c=true Limit 1];
        List<HexaBPM__Step__c> stps = [Select Id, Name, HexaBPM__SR__c, Step_Template_Code__c,HexaBPM__Summary__c,HexaBPM__Status__c,HexaBPM__Status__r.Name,SRTemplateName__c From HexaBPM__Step__c WHERE (HexaBPM__Summary__c = 'Manage Receipt' OR HexaBPM__Summary__c = 'Verify the Request') AND HexaBPM__SR__c=:SR.Id ORDER BY CreatedDate DESC limit 2];
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);
        
        InstallmentLines__c il = new InstallmentLines__c();
        il.Id = installmentLineList[0].Id;
        il.InvoiceId__c = '1234';
        il.InvoiceNumber__c = '1234';
        il.InvoicedAmount__c = 0;
        update il;
        
        SR.InstallmentLine__c = il.Id;
        update SR;
        
        HexaBPM__Status__c status = [SELECT Id from HexaBPM__Status__c WHERE Name='Approved' Limit 1];
        List<HexaBPM__Step__c> stpList = new List<HexaBPM__Step__c>();
        for(HexaBPM__Step__c stp:stps) {
            if(stp.HexaBPM__Summary__c == 'Verify the Request') {
                stp.HexaBPM__Status__c = status.Id;
                stpList.add(stp);
            }
        }
        update stpList;
        CC_ALDRA_CreditNoteCreationProcess cc = new CC_ALDRA_CreditNoteCreationProcess();
        String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "396fbd20-fa08-11ed-acd1-06dbb03cb360", "results": { "othChgRes": [ { "sfRequestId": "396fbd20-fa08-11ed-acd1-06dbb03cb360", "srSFId": "a0Q250000059slaEAA", "sfId": "a2425000002qNaJAAU", "erpId": "123243", "recAcct": "123243", "expAcct": "123243", "taxAcct": "123243", "status": "Success", "errorMsg": "","IsInvoiceReversal": "Y", "invoiceNo": "12343" } ] } }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        cc.EvaluateCustomCode(SR, stpList[0]);
        Test.stopTest();
    }
    @isTest
    public static void testException() {
        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c From HexaBPM__Service_Request__c WHERE InvoiceReversal__c=true Limit 1];

        CC_ALDRA_CreditNoteCreationProcess cc = new CC_ALDRA_CreditNoteCreationProcess();
        cc.EvaluateCustomCode(SR, new HexaBPM__Step__c());
    }
    
    @isTest
    public static void OtherChangeReversalWithVat_Test(){
        Test.startTest();
        
        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c,HexaBPM__Customer__c From HexaBPM__Service_Request__c WHERE InvoiceReversal__c=false Limit 1];
        
        SalesOrderOtherCharges__c salesOrderOtherCharges = new SalesOrderOtherCharges__c();
        salesOrderOtherCharges.SalesOrder__c = SR.SalesOrder__c;
        salesOrderOtherCharges.Account__c = SR.HexaBPM__Customer__c;
        salesOrderOtherCharges.Amount__c = 10000;
        salesOrderOtherCharges.InvoicedAmount__c = 10000;
        salesOrderOtherCharges.TypeOfCharge__c = Constants.BUDGET_LINE_ADMFEE;
        salesOrderOtherCharges.VATAmount__c=500;
        salesOrderOtherCharges.AmountWithoutVAT__c=9500;
        
        insert salesOrderOtherCharges;
        
        SR.Sales_Order_Other_Charges__c=salesOrderOtherCharges.Id;
        SR.Credit_Note_Sub_Type__c='Other Charges Reversal';
        SR.Amount__c=2000;
        //VATAmount__c
         //AmountWithoutVAT__c
        update SR;
        
        
        List<HexaBPM__Step__c> stps = [Select Id, Name, HexaBPM__SR__c, Step_Template_Code__c,HexaBPM__Summary__c,HexaBPM__Status__c,HexaBPM__Status__r.Name,SRTemplateName__c From HexaBPM__Step__c WHERE (HexaBPM__Summary__c = 'Manage Receipt' OR HexaBPM__Summary__c = 'Verify the Request') AND HexaBPM__SR__c=:SR.Id ORDER BY CreatedDate DESC limit 2];
       // update SR;
        
        HexaBPM__Status__c status = [SELECT Id from HexaBPM__Status__c WHERE Name='Approved' Limit 1];
        List<HexaBPM__Step__c> stpList = new List<HexaBPM__Step__c>();
        for(HexaBPM__Step__c stp:stps) {
            if(stp.HexaBPM__Summary__c == 'Verify the Request') {
                stp.HexaBPM__Status__c = status.Id;
                stp.HexaBPM__SR__c=SR.ID;
                stpList.add(stp);
            }
        }
        
        update stpList;
        CC_ALDRA_CreditNoteCreationProcess cc = new CC_ALDRA_CreditNoteCreationProcess();
        String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "396fbd20-fa08-11ed-acd1-06dbb03cb360", "results": { "othChgRes": [ { "sfRequestId": "396fbd20-fa08-11ed-acd1-06dbb03cb360", "srSFId": "a0Q250000059slaEAA", "sfId": "a2425000002qNaJAAU", "erpId": "123243", "recAcct": "123243", "expAcct": "123243", "taxAcct": "123243", "status": "Success", "errorMsg": "", "invoiceNo": "12343" } ] } }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        cc.EvaluateCustomCode(SR, stpList[0]);
        Test.stopTest();
    }
    
    
     @isTest
    public static void OtherChangeReversalWithVat_Test1(){
        Test.startTest();
        
        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c,HexaBPM__Customer__c From HexaBPM__Service_Request__c WHERE InvoiceReversal__c=false Limit 1];
        
        SalesOrderOtherCharges__c salesOrderOtherCharges = new SalesOrderOtherCharges__c();
        salesOrderOtherCharges.SalesOrder__c = SR.SalesOrder__c;
        salesOrderOtherCharges.Account__c = SR.HexaBPM__Customer__c;
        salesOrderOtherCharges.Amount__c = 10000;
        salesOrderOtherCharges.InvoicedAmount__c = 10000;
        salesOrderOtherCharges.TypeOfCharge__c = Constants.BUDGET_LINE_ADMFEE;
        salesOrderOtherCharges.VATAmount__c=500;
        salesOrderOtherCharges.AmountWithoutVAT__c=9500;
        
        insert salesOrderOtherCharges;
        
        SR.Sales_Order_Other_Charges__c=salesOrderOtherCharges.Id;
        SR.Credit_Note_Sub_Type__c='Other Charges Reversal';
        SR.Amount__c=2000;
        //VATAmount__c
         //AmountWithoutVAT__c
        update SR;
        
        
        List<HexaBPM__Step__c> stps = [Select Id, Name, HexaBPM__SR__c, Step_Template_Code__c,HexaBPM__Summary__c,HexaBPM__Status__c,HexaBPM__Status__r.Name,SRTemplateName__c From HexaBPM__Step__c WHERE (HexaBPM__Summary__c = 'Manage Receipt' OR HexaBPM__Summary__c = 'Verify the Request') AND HexaBPM__SR__c=:SR.Id ORDER BY CreatedDate DESC limit 2];
       // update SR;
        
        HexaBPM__Status__c status = [SELECT Id from HexaBPM__Status__c WHERE Name='Completed' Limit 1];
        List<HexaBPM__Step__c> stpList = new List<HexaBPM__Step__c>();
        for(HexaBPM__Step__c stp:stps) {
            if(stp.HexaBPM__Summary__c == 'Manage Receipt') {
                stp.HexaBPM__Status__c = status.Id;
                stp.HexaBPM__SR__c=SR.ID;
                stpList.add(stp);
            }
        }
        
        update stpList;
        CC_ALDRA_CreditNoteCreationProcess cc = new CC_ALDRA_CreditNoteCreationProcess();
        String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "396fbd20-fa08-11ed-acd1-06dbb03cb360", "results": { "othChgRes": [ { "sfRequestId": "396fbd20-fa08-11ed-acd1-06dbb03cb360", "srSFId": "a0Q250000059slaEAA", "sfId": "a2425000002qNaJAAU", "erpId": "123243", "recAcct": "123243", "expAcct": "123243", "taxAcct": "123243", "status": "Success", "errorMsg": "", "invoiceNo": "12343" } ] } }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        cc.EvaluateCustomCode(SR, stpList[0]);
        Test.stopTest();
    }
   
    
    
    
    
}