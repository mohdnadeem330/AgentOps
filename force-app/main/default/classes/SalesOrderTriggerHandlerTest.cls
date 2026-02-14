@isTest(SeeAllData=false)
public class SalesOrderTriggerHandlerTest {
    @testSetup static void setupData() {
        Account account = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
        System.debug('@@@test'+account);
        System.debug('@@@Nationaty'+account.Nationality__pc);
        account.Sync_with_SFMC__c = false;
        account.CustomerVertical__c = 'LSQ';
        insert account;

        Account relatedAccount = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
        relatedAccount.Sync_with_SFMC__c = false;
        relatedAccount.CustomerVertical__c = 'LSQ';
        insert relatedAccount;
        
        Account relatedAccount1 = TestObjectsFactory.getOrganisationAccountRecord('companyName1', 'registrationNo1');
        relatedAccount1.Sync_with_SFMC__c = false;
        relatedAccount1.CustomerVertical__c = 'LSQ';
        insert relatedAccount1;

        Contact con = TestObjectsFactory.contactDataSetup(account.Id);

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(account.Id );
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

        HexaBPM__SR_Status__c objCloseStat4 = new HexaBPM__SR_Status__c();
        objCloseStat4.Name = 'SUBMITTED';
        objCloseStat4.HexaBPM__Code__c = 'SUBMITTED';
        insert objCloseStat4;
        
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
        
        Unit__c unit1 = TestObjectsFactory.unitDataSetup('Mayan');
        unit1.Project__c = project.Id;
        unit1.BuildingSectionName__c =BuildingSection.Id;
        unit1.Name = 'MAYAN-B1-101096';
        unit1.AffectionPlan__c = 'www.google.com';
        insert unit1;
        
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

        TestObjectsFactory.createContentDocumentLink(doc.Id);
        
        Test.startTest();
		
        SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, account.Id);
        salesOrder1.Unit__c = unit.Id;
        salesOrder1.PaymentPlan__c=paymentPlanRecord.Id;
        salesOrder1.Status__c = Constants.OPPO_UNIT_STATUS_PENDING;
        salesOrder1.SubStatus__c = Constants.OPPO_UNIT_SUBSTATUS_PENDING_SM;
        //salesOrder1.Account__c=account.Id;
        salesOrder1.CustomerType__c = Constants.ACCOUNT_CUSTOMER_TYPE_ALDAR_STAFF;
        salesOrder1.OffPlanSalesOrder__c = true;
        salesOrder1.JointOwnerComplianceStatus__c ='Cleared';
        salesOrder1.ThirdPartyComplianceStatus__c ='Cleared';
        salesOrder1.SignatureType__c='Physical Signature';
        salesOrder1.DoorNumber__c = '2';
        salesOrder1.SubStatus__c = Constants.SUB_STATUS;
        salesOrder1.SyncStatus__c = Constants.STATUS_SYNCED;
        salesOrder1.IsSalesOrderChange__c = false;
        salesOrder1.CustomerAddress__c = '{"Street":"Street","City":"City","State":"State","PostalCode":"PostalCode","Country":"Country"}';
        salesOrder1.DeliveryConfirmationEmailTime__c = Datetime.now();
        salesOrder1.QualtricsIntegrationStatus__c = Constants.QUALTRICS_IN_PROGRESS;
        //salesOrder1.ProjectBudget__c = projectBudget.Id;
        insert salesOrder1;
        
        CaseUtilities queueJob = new CaseUtilities(salesOrder1);
		System.enqueueJob(queueJob);

        TriggerHandler.processedIds = new Set<Id>();
        JointOwner__c jointOwner = TestObjectsFactory.getJointOwner(relatedAccount.Id,20,'Friend Of');
        jointOwner.SalesOrder__c = salesOrder1.Id;
        insert jointOwner;
        
        Document__c doc3 = TestObjectsFactory.getProjectDocument(project.Id);
        doc3.SalesOrder__c = salesOrder1.Id;
        doc3.DocumentType__c = Constants.DOCUMENT_TYPE_ALDAR_SIGNED_SPA;
        doc3.Status__c = Constants.DOCUMENT_STATUS_UPLOADED;
        insert doc3;
        
        Test.stopTest();
    }
    
    @isTest static void testUpdateSOReserved(){
         Test.startTest();
        SalesOrder__c salesOrder1 = [SELECT Id,Account__c,Status__c FROM SalesOrder__c WHERE CustomerType__c =: Constants.ACCOUNT_CUSTOMER_TYPE_ALDAR_STAFF LIMIT 1];
        salesOrder1.Status__c = Constants.UNIT_STATUS_SOLD;
        update salesOrder1;
        SalesOrderTriggerHandler.updateSOReserved(new Set<Id>{salesOrder1.Id});
        Test.stopTest();
    }
    
    @isTest static void testCreateShipmentRecords(){
         Test.startTest();
         SalesOrder__c salesOrder1 = [SELECT Id,Account__c,Status__c FROM SalesOrder__c WHERE CustomerType__c =: Constants.ACCOUNT_CUSTOMER_TYPE_ALDAR_STAFF LIMIT 1];
        salesOrder1.Status__c = Constants.UNIT_STATUS_SOLD;
        update salesOrder1;
        SalesOrderTriggerHandler.createShipmentRecords(new List<SalesOrder__c>{salesOrder1});
        Test.stopTest();
    }
    
    @isTest static void testUpdateOpportunityCancelSaleOrder(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];   
        SalesOrderTriggerHandler.updateOpportunityCancelSaleOrder(new Set<Id>{opp.Id});
    }
    
    @isTest
    public static void testSOCancellation() {
        Test.startTest();
     	Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        SalesOrder__c salesOrder1 = [SELECT Id,Account__c,Status__c FROM SalesOrder__c WHERE CustomerType__c =: Constants.ACCOUNT_CUSTOMER_TYPE_ALDAR_STAFF LIMIT 1];
        SalesOrderCancellation__c soCancel = TestObjectsFactory.getSalesOrderCancellationRecord(salesorder1.Id, unit.Id);
        soCancel.ReasonforCancellation__c = 'Changing customer name or switching between the joint owners.';
        soCancel.Cancellation_Status__c = 'Approved';
        soCancel.New_Buyer_Opportunity__c = opp.Id;
        insert soCancel;
        BuildingSection__c BuildingSection = [SELECT Id FROM BuildingSection__c LIMIT 1];
		Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        OffersPromotions__c offers =  TestObjectsFactory.getOfferPromotion(BuildingSection.Id, project.Id);
        insert offers;
        OfferLines__c offerLines = TestObjectsFactory.getOfferLine(offers.Id);
        insert offerLines;
        salesOrder1.Offer__c = offers.Id;
        salesOrder1.NetAmount__c = 100000;
        salesOrder1.InternalCommissionAmount__c = 1000;
        salesorder1.ExternalCommissionAmount__c = 1000;
        salesOrder1.Status__c = Constants.SO_STATUS_CANCELLED;
        update salesOrder1;
        TriggerHandler.processedIds = new Set<Id>();
        SalesOrderTriggerHandler.updateSOReserved(new Set<Id>{salesOrder1.Id});
        SalesOrderTriggerHandler.createShipmentRecords(new List<SalesOrder__c>{salesOrder1});
        SalesOrderTriggerHandler.updateOpportunityCancelSaleOrder(new Set<Id>{opp.Id});
        Test.stopTest();
    }

}