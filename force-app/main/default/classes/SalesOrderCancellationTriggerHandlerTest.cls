@isTest
public class SalesOrderCancellationTriggerHandlerTest {
    
    @testSetup static void init(){
        Account account = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
        insert account;
        
        Account relatedAccount = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
        insert relatedAccount;
        
        Account relatedAccount1 = TestObjectsFactory.getOrganisationAccountRecord('companyName1', 'registrationNo1');
        insert relatedAccount1;
        
        Contact con = TestObjectsFactory.contactDataSetup(account.Id);
        Account account1 = TestObjectsFactory.getPersonAccountRecord();
        insert account1;
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(account1.Id );
        opp.EnquiryTrigger__c=null;
        opp.EmployeeId__c = '123456789';
        opp.EmployeeEmail__c = 'test@aldar.com';
        opp.SaleType__c = 'New Sale';
        insert opp;
        
        ProjectBudget__c projectBudget = TestObjectsFactory.getProjectBudget();
        insert projectBudget;
        
        Project__c project = TestObjectsFactory.getProjectRecord('ABC');
        project.ProjectBudget__c = projectBudget.Id;
        insert project;
        
        BuildingSection__c BuildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        BuildingSection.LaunchStartDate__c = date.today().adddays(-10);
        BuildingSection.LaunchEndDate__c = date.today().adddays(10);
        Insert BuildingSection;
        
        
        Document__c gtc = TestObjectsFactory.getProjectDocument(project.Id);
        insert gtc;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('Mayan');
        unit.Project__c = project.Id;
        unit.BuildingSectionName__c =BuildingSection.Id;
        unit.Name = 'MAYAN-B1-101095';
        unit.AffectionPlan__c = 'www.google.com';
        insert unit;
        
        Document__c doc = TestObjectsFactory.getProjectDocument(project.Id);
        doc.Unit__c = unit.Id;
        doc.DocumentType__c = 'Affection Plan';
        insert doc;
        
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        paymentPlanRecord.Classification__c ='30-70';
        insert paymentPlanRecord;
        
        Communication_Preference__c cp = new Communication_Preference__c();
        cp.Account__c=account.Id;
        cp.Status__c = 'Fasttrack Completed';
        cp.FastTrack_Completion_Date_Time__c= System.now();
        insert cp;
        Test.startTest();
        TestObjectsFactory.createContentDocumentLink(doc.Id);
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, account.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.PaymentPlan__c=paymentPlanRecord.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.BookingDate__c = date.today();
        salesOrder.NetAmount__c = 100;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;
        
        SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, account1.Id);
        salesOrder1.Unit__c = unit.Id;
        salesOrder1.PaymentPlan__c=paymentPlanRecord.Id;
        salesOrder1.Status__c = 'Sold';
        salesOrder1.SubStatus__c = Constants.OPPO_UNIT_SUBSTATUS_PENDING_SM;
        salesOrder1.CustomerType__c = Constants.ACCOUNT_CUSTOMER_TYPE_ALDAR_STAFF;
        salesOrder1.OffPlanSalesOrder__c = true;
        salesOrder1.JointOwnerComplianceStatus__c ='Cleared';
        salesOrder1.ThirdPartyComplianceStatus__c ='Cleared';
        salesOrder1.SignatureType__c='Physical Signature';
        insert salesOrder1;
        User manager = TestObjectsFactory.getUserRecord('Sales Manager','srana');
        insert manager;
        SalesOrderCancellation__c SOCancellation = TestObjectsFactory.getSalesOrderCancellationRecord(salesOrder.Id,unit.Id);
        SOCancellation.LineManager__c = manager.Id;
        SOCancellation.RefundAmount__c = 0;
        SOCancellation.ForfeitAmount__c = 0;
        SOCancellation.RelocationAmount__c = 0;
        SOCancellation.ProvisionAmount__c = 0;
        insert SOCancellation;
        SalesOrderCancellation__c SOCancellation1 = TestObjectsFactory.getSalesOrderCancellationRecord(salesOrder1.Id,unit.Id);
        SOCancellation1.LineManager__c = manager.Id;
        SOCancellation1.RefundAmount__c = 0;
        SOCancellation1.ForfeitAmount__c = 0;
        SOCancellation1.RelocationAmount__c = 0;
        SOCancellation1.ProvisionAmount__c = 0;
        insert SOCancellation1;
        SalesOrderCancellation__c SOCancellation2 = TestObjectsFactory.getSalesOrderCancellationRecord(salesOrder1.Id,unit.Id);
        insert SOCancellation2;
        List<SOCancellationDocumentsHelper.FlowInputParamsWrapper> ab = new List<SOCancellationDocumentsHelper.FlowInputParamsWrapper>();
        SOCancellationDocumentsHelper.FlowInputParamsWrapper t = new SOCancellationDocumentsHelper.FlowInputParamsWrapper();
        t.recordId = SOCancellation.Id;
        ab.add(t);
        SOCancellationDocumentsHelper.createDocuments(ab);
        
        ab = new List<SOCancellationDocumentsHelper.FlowInputParamsWrapper>();
        SOCancellationDocumentsHelper.FlowInputParamsWrapper t2 = new SOCancellationDocumentsHelper.FlowInputParamsWrapper();
        t2.recordId = SOCancellation1.Id;
        ab.add(t2);
        SOCancellationDocumentsHelper.createDocuments(ab);
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.ContentLocation = 'S'; // S = Stored in Salesforce
        contentVersion.PathOnClient = 'test';
        contentVersion.Title = 'test';
        contentVersion.VersionData = EncodingUtil.base64Decode('test');
        insert contentVersion;
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:contentVersion.Id].ContentDocumentId;
        List<Id> ids = new List<Id>();
        ids.add(SOCancellation1.Id);
        ids.add(SOCancellation.Id);
        List<Document__c> lstDoc = [SELECT Id FROM Document__c WHERE Sales_Order_Cancellation__c IN : ids ];
        List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
        for(Document__c doc1 : lstDoc){
            // 3. Create ContentDocumentLink
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
                ContentDocumentId = contentDocumentId,
                LinkedEntityId = doc1.Id,
                ShareType = 'V', // View Only
                Visibility = 'AllUsers' // Or any other visibility
            );
            contentDocumentLinkList.add(contentDocumentLink);
            
        }
        insert contentDocumentLinkList;
        Test.stopTest();
    }
    
    static testmethod void testSOCancellationTriggerHandler(){
        Test.startTest();
        List<SalesOrderCancellation__c> lstSOCancellation = [SELECT Id, RefundApplicable__c, RefundAmount__c FROM SalesOrderCancellation__c];
        List<String> socId = new List<String>();
        List<SalesOrderCancellation__c> lstSOCancellationToUpdate = new List<SalesOrderCancellation__c>();
        for(SalesOrderCancellation__c soCancellation : lstSOCancellation){
            if(soCancellation.RefundAmount__c != 0) continue;
            soCancellation.Cancellation_Status__c = 'Awaiting Approval';
            soCancellation.CustomerAccountName__c = 'Sumit Singh Rana';
            soCancellation.CustomerAccountNumber__c = 'AE2345678876543';
            soCancellation.CustomerBankName__c = 'ADCB';
            soCancellation.CustomerBranchName__c = 'Abu Dhabi';
            soCancellation.CustomerIBANCode__c = '1234';
            soCancellation.CustomerSwiftCode__c = '1234';
            soCancellation.Refund_To__c = 'Primary';
            soCancellation.RefundApplicable__c = true;
            soCancellation.RefundReason__c = 'test';
            SOCancellation.RefundAmount__c = 0;
            SOCancellation.ForfeitAmount__c = 0;
            SOCancellation.RelocationAmount__c = 0;
            SOCancellation.ProvisionAmount__c = 0;
            lstSOCancellationToUpdate.add(SOCancellation);
        }
        //        try{
        update lstSOCancellationToUpdate;  
        //        }
        //        catch(Exception exp){
        
        //        }
        socId.add(lstSOCancellation.get(0).Id);
        SOCancellationSRCreationValidation.validateDocuments(socId);
        socId = new List<String>();
        socId.add(lstSOCancellation.get(1).Id);
        SOCancellationSRCreationValidation.validateDocuments(socId);
        for(SalesOrderCancellation__c soCancellation : lstSOCancellationToUpdate){
            soCancellation.Refund_To__c = 'Third Party';
            soCancellation.RefundApplicable__c = true;
        }
        
        //         try{
        update lstSOCancellationToUpdate;  
        //        }
        //        catch(Exception exp){
        
        //        }
        lstSOCancellation.get(0).Refund_To__c = 'Third Party';
        lstSOCancellation.get(1).Refund_To__c = 'Third Party';
        lstSOCancellation.get(0).RefundApplicable__c = false;
        lstSOCancellation.get(1).RefundApplicable__c = false;
        update lstSOCancellation;
        socId = new List<String>();
        socId.add(lstSOCancellation.get(0).Id);
        SOCancellationSRCreationValidation.validateDocuments(socId);
        socId = new List<String>();
        socId.add(lstSOCancellation.get(1).Id);
        SOCancellationSRCreationValidation.validateDocuments(socId);
        socId = new List<String>();
        socId.add(lstSOCancellation.get(2).Id);
        SOCancellationSRCreationValidation.validateDocuments(socId);
        Test.stopTest();
        
    }
}