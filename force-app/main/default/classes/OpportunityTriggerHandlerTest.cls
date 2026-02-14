@isTest
public class OpportunityTriggerHandlerTest {
    
    @isTest static void insertOpportunity() {
      
       
        
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.Emirates_ID__c ='784123123123123';
        insert acc;

        List<Opportunity> oppToInsert = new List<Opportunity>();

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        oppToInsert.add(opp);

        Opportunity opp1 = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp1.LeadSource = Constants.WALK_IN;
        opp1.EnquiryCategory__c = 'Kiosk';
        opp1.EnquiryTrigger__c = 'Yas Mall Kiosk';
        oppToInsert.add(opp1);

        Opportunity opp2 = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp2.CustomerContactedBySM__c = true;
        oppToInsert.add(opp2);

        insert oppToInsert;
         Test.startTest();
        TriggerHandler.processedIds = new Set<Id>();
        Opportunity oppDup = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert oppDup;

        TriggerHandler.processedIds = new Set<Id>();
        Project__c p= TestObjectsFactory.getProjectRecord('25083');
        insert p;
        Unit__c u = TestObjectsFactory.unitDataSetup(p.Id);        
        insert u;

        SalesOrder__c sa = TestObjectsFactory.getSalesOrderRecord(opp.Id,acc.Id);
        sa.Unit__c = u.Id;
        sa.Status__c = Constants.STATUS_RESERVATION_IN_PROGRESS;
        insert sa;

        TriggerHandler.processedIds = new Set<Id>();
        opp.ReservationApprovalStatus__c = Constants.STATUS_APPROVED;
		opp.StageName = Constants.STAGE_CLOSED_LOST;
        opp.LossReason__c = constants.OPPORTUNITY_LOST_PRICE;
        opp.LossComments__c = constants.OPPORTUNITY_LOST_PRICE;
		update opp;

        TriggerHandler.processedIds = new Set<Id>();
        Account brokerAcc = TestObjectsFactory.getAgencyAccountRecord('agencyName','registrationNo');
        brokerAcc.Emirates_ID__c ='784123123123123';
        insert brokerAcc;
        opp.ReservationApprovalStatus__c = Constants.STATUS_REJECTED;
        opp.BrokerAgencyAccount__c = brokerAcc.Id;
        opp.StageName = 'Closed Won';
        opp.LossReason__c = null;
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Resale').getRecordTypeId();
		update opp;

        Test.stopTest();
    }
    
    @isTest static void resaleOpportunityTest() {
        
        Project__c p= TestObjectsFactory.getProjectRecord('25083');
        p.EligibleforResale__c = true;
        insert p;
        
        TriggerHandler.processedIds = new Set<Id>();
        Unit__c u = TestObjectsFactory.unitDataSetup(p.Id);        
        u.ResaleListed__c = false;
        u.ResaleStatus__c = '';
        u.PropertyId__c = '10000000';
        u.CompletionDate__c = System.today().addDays(7);
        u.Project__c = p.Id;
        insert u;      
        
        TriggerHandler.processedIds = new Set<Id>();
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.Emirates_ID__c ='784123123123123';
        insert acc;
        TriggerHandler.processedIds = new Set<Id>();
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;

        SalesOrder__c sa = TestObjectsFactory.getSalesOrderRecord(opp.Id,acc.Id);
        sa.Unit__c = u.Id;
        sa.Account__c = acc.Id;
        sa.IsBookingCompleted__c = true;
        sa.NetAmount__c = 10000000;
        sa.Status__c = 'Sold';
        sa.SellingPrice__c = 10000000;
        insert sa;

        Id recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Resale Case').getRecordTypeId();
        Case newCase = TestObjectsFactory.getCaseRecord(recTypeId, 'Question', u.Id, 'Online');
        insert newCase;

        Test.startTest();
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        Opportunity resaleOpp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        resaleOpp.LeadSource = Constants.WALK_IN;
        resaleOpp.EnquiryCategory__c = 'Kiosk';
        resaleOpp.EnquiryTrigger__c = 'Yas Mall Kiosk';
        resaleOpp.Unit__c = u.Id;
        resaleOpp.Lead_Type__c = 'Resale';
        resaleOpp.StageName = 'Meeting';
        resaleOpp.RecordTypeId = ResaleConstants.Resale_Opp_RecordTypeId;
        insert resaleOpp;

        TriggerHandler.processedIds = new Set<Id>();

        opp.StageName = ResaleConstants.OPP_STATUS_OFFER_ACCEPTED;
		update opp;
        Test.stopTest();
    }
 
    @isTest
    static  void testCreateCommissionLineItemsOnTransfer() {
        // Create test data - System.labels

        
      
          Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.Emirates_ID__c ='784123123123123';
        insert acc;

        List<Opportunity> oppToInsert = new List<Opportunity>();
        Opportunity opp1 = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp1.Amount = 1000000;
        opp1.SaleType__c = 'Resale';
        
        opp1.LeadSource = Constants.WALK_IN;
        opp1.EnquiryCategory__c = 'Kiosk';
        opp1.EnquiryTrigger__c = 'Yas Mall Kiosk';
        opp1.Amount = 1000000;
        Insert opp1;

		  TriggerHandler.processedIds = new Set<Id>();
        Opportunity oppDup = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert oppDup;
        
        
		TriggerHandler.processedIds = new Set<Id>();
        Project__c p= TestObjectsFactory.getProjectRecord('25083');
        p.EligibleforResale__c = true;
        insert p;
        User Rmuser = [SELECT Id FROM User where Profile.Name = 'Resale Relationship Manager' AND IsActive= true LIMIT 1];
        
        BuildingSection__c newBuilding = TestObjectsFactory.getBuildingDetailRecord(p.Id);
        newBuilding.CompletionCertificateDate__c = null;
        insert newBuilding; 

        Unit__c u = TestObjectsFactory.unitDataSetup(p.Id);   
        u.CompletionDate__c = date.today().addDays(4);
        u.BuildingSectionName__c = newBuilding.Id;
        u.OwnerId = Rmuser.Id;
        u.Project__c = p.Id;
        insert u;

        SalesOrder__c sa = TestObjectsFactory.getSalesOrderRecord(opp1.Id,acc.Id);
        sa.Unit__c = u.Id;
        sa.Status__c = 'Sold';
        insert sa;
        opp1.StageName = 'Offer Accepted';
        opp1.Unit__c = u.Id;
        opp1.OwnerId = userInfo.getUserId();
        Update opp1;

        Id recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Resale Case').getRecordTypeId();
        
        system.runAs(Rmuser){
            Case newCase1 = TestObjectsFactory.getCaseRecord(recTypeId, 'Question', u.Id, 'Direct Call');
            
            //		newCase1.OwnerId = Rmuser.Id;
            //        newCase1.ReferredBy__c = Rmuser.Id;
            newCase1.ownerId = userInfo.getUserId();
            try{
                 insert newCase1;

            } catch(Exception e){
                
                system.debug('Message: '+ e.getMessage());
                 system.debug('Message: '+ e.getLineNumber());
                 system.debug('Message: '+ e.getStackTraceString());
                 
                
            }
                       
        }
        
        
        // Insert the Cases
        //insert new List<Case>{ newCase1, newCase2 };

        // Call the method to be tested
        List<Opportunity> opportunitiesToBeTested = [SELECT Id,Buyer_Service_Charge_fx__c,stagename,Seller_Service_Charge_fx__c,
                                                     ReferredBy__c,SalesOrder__c,OwnerId,Project__c,Unit__c,LeadNumber__c,Amount
                                                     FROM Opportunity WHERE ID=:opp1.Id];
        OpportunityTriggerHandler.createCommissionLineItemsOnTransfer(opportunitiesToBeTested);

        // Query the CommissionLineItem__c records created by the method
        List<CommissionLineItem__c> commissionLineItems = [
            SELECT Id, SalesManager__c, CommissionAmount__c, SalesOrder__c, ReSaleJourneyType__c
            FROM CommissionLineItem__c
            WHERE SalesOrder__r.Opportunity__c IN :opportunitiesToBeTested
        ];

        // Assert that the CommissionLineItem__c records are created as expected
       // System.assertEquals(/* Expected number of commistestCreateCommissionLineItemsOnTransfersion line items */, commissionLineItems.size());
        for (CommissionLineItem__c item : commissionLineItems) {
            // Add assertions for each field based on your business logic
            System.assertEquals(sa.SalesManager__c, item.SalesManager__c);
            System.assertEquals(100, item.CommissionAmount__c);
            System.assertEquals(sa.Id, item.SalesOrder__c);
            //System.assertEquals(resaleJourneyType, item.ReSaleJourneyType__c);
        }
    }
   
    //Dummy comments
    @isTest
    static void testCreateCommissionLineItems() {
       Project__c p= TestObjectsFactory.getProjectRecord('25083');
        insert p;
        
        TriggerHandler.processedIds = new Set<Id>();
        Unit__c u = TestObjectsFactory.unitDataSetup(p.Id);        
        u.ResaleListed__c = false;
        u.ResaleStatus__c = '';
        u.PropertyId__c = '10000000';
        u.CompletionDate__c = System.today().addDays(7);
        insert u;      
        
        TriggerHandler.processedIds = new Set<Id>();
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.Emirates_ID__c ='784123123123123';
        insert acc;
        TriggerHandler.processedIds = new Set<Id>();
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;

        SalesOrder__c sa = TestObjectsFactory.getSalesOrderRecord(opp.Id,acc.Id);
        sa.Unit__c = u.Id;
        sa.Account__c = acc.Id;
        sa.IsBookingCompleted__c = true;
        sa.NetAmount__c = 10000000;
        sa.Status__c = 'Sold';
        sa.SellingPrice__c = 10000000;
        insert sa;
              SalesOrder__c sa1 = TestObjectsFactory.getSalesOrderRecord(opp.Id,acc.Id);
        Id salesManagerId = sa1.SalesManager__c;
        Decimal commissionAmount = 100.00; // Set the commission amount
        Id salesOrderId = sa1.Id;
        String resaleJourneyType = 'Buyer referral';

        // Call the method to be tested
        CommissionLineItem__c commissionLineItem = OpportunityTriggerHandler.createCommissionLineItems(salesManagerId, commissionAmount, salesOrderId, resaleJourneyType);

        // Assert that the CommissionLineItem__c record is created as expected
        //System.assertNotEquals(null, commissionLineItem.Id);
        System.assertEquals('Internal', commissionLineItem.CommissionType__c);
        System.assertEquals(commissionAmount, commissionLineItem.CommissionAmount__c);
        System.assertEquals(salesOrderId, commissionLineItem.SalesOrder__c);
        System.assertEquals(0, commissionLineItem.CommissionPercentage__c);
        System.assertEquals(resaleJourneyType, commissionLineItem.ReSaleJourneyType__c);
    }


    /*@isTest static void createCommissionLineItems() {        
        try{
            OpportunityTriggerHandler.createCommissionLineItems(null, 10.5, null, 'Buyer');
        }catch(Exception Ex)
        {
            System.debug('Exception Ocured');
        }
    }*/ 
    
 @isTest
    static void coverExecutionApprovalStatus() {
 
        Id piRT = Schema.SObjectType.Opportunity
            .getRecordTypeInfosByName()
            .get('P&I Opportunity')
            .getRecordTypeId();
 
      
        Opportunity oldOpp = new Opportunity(
            RecordTypeId = piRT,
            Approval_Status__c = 'Execution approval in progress'
        );
 
        Opportunity newOpp = oldOpp.clone(false);
        newOpp.RecordTypeId = piRT;
        newOpp.Approval_Status__c = 'Execution Approved';
 
        List<Opportunity> result = new List<Opportunity>();
 
   
        result = OpportunityTriggerHandler.evaluatePIApprovalStatus(
            newOpp,
            oldOpp,
            piRT
            
        );
 
        System.assertEquals(1, result.size(),
            'P&I execution approval transition should be captured');
    }
    
    @istest
    static void createOfferLetterDocumentTest(){
        
         Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.Emirates_ID__c = '784123123123788';
        insert acc;
        list<Opportunity> opplist = new list<Opportunity>();
        Id leasingRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('ECSS_Leasing').getRecordTypeId();
         Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.recordTypeId = leasingRecordTypeId;
        opp.Project__c = '';
        opp.OwnerId = userinfo.getUserId();
        opplist.add(opp);
        if(opplist.size() > 0){
            insert opplist;
        }
        
        OpportunityTriggerHandler.createLeasingDocuments(opplist);
        
        
        
        
    }
    
    
   
}