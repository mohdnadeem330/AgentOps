@isTest
public class ResaleUnitServiceTest {
    
    @TestSetup
    static void makeData(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        project.AsiteProjectName__c = 'Test Project Name';
        insert project;
        
        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        insert buildingSection;
        
        Account newAccount = TestObjectsFactory.getPersonAccountRecord();
        newAccount.MaritalStatus__pc = 'Single';
        insert newAccount;
        
        Lead objLead1 = TestObjectsFactory.getLeadRecord(1,'Person');
        objLead1.agencyName__c = 'Address Point Properties L.L.C';
        objLead1.agentName__c = 'Brooke Reynolds';
        objLead1.offer1__c = '2020 Free for 3 offer';
        insert objLead1;
        
        
        Unit__c unit = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
        unit.Name += '1';
        unit.Status__c = 'Sold';
        unit.CompletionDate__c = System.today().addDays(7);
        unit.ResaleListed__c = true;
        unit.Listing_Price__c = 5000;
        insert unit;
        
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        opp.OwnerManger__c = UserInfo.getUserId();
        insert opp;    
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        salesOrder.Account__c = newAccount.Id;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;
        
        Opportunity opp2 = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        opp2.Name = 'TestResale';
        opp2.OwnerManger__c = UserInfo.getUserId();
        opp2.SalesOrder__c = salesOrder.id;
        opp2.Unit__c = unit.id;
        opp2.Lead_Type__c = 'Resale';
        insert opp2;
        
        
        User admin = TestObjectsFactory.getUserRecord('System Administrator', 'admin');
        admin.FirstName = 'Admin';
        insert admin;
        
        List<User> users = new List<User>(); 
        
        User user_CCA = TestObjectsFactory.getUserRecord('Contact Centre Agent', 'CCA1');
        user_CCA.FirstName = 'CCA1';
        users.add(user_CCA);
        
        User user_SM = TestObjectsFactory.getUserRecord('Sales Manager', 'SM1');
        user_SM.FirstName = 'SM1';
        users.add(user_SM);
        
        User user_RM = TestObjectsFactory.getUserRecord('Resale Relationship Manager', 'RM1');
        user_RM.FirstName = 'RM1';
        user_RM.ManagerId = admin.Id;
        users.add(user_RM);
        
        insert users;
        Test.startTest();
        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, newAccount.Id, opp2.Id, 'Credit Card');
        insert receiptAcknowledgement;
        
        Document__c mouRec = new Document__c();
        mouRec.DocumentType__c = 'Listing MOU';
        mouRec.Opportunity__c = opp2.id;
        insert mouRec;

        Document__c documentRec = new Document__c();
        documentRec.DocumentType__c = 'Signed Listing MOU';
        documentRec.Opportunity__c = opp2.id;
        insert documentRec;

        Resale_Offers__c ro = new Resale_Offers__c(
            Unit__c = unit.Id,
            Comments__c = 'Please Accept', 
            Opportunity__c = opp2.Id, 
            Sales_Order__c = salesOrder.Id, 
            Status__c = 'Sent for Approval', 
            Offer_Price__c = 10000000 ,
            Buyer_Account__c = newAccount.Id,
            Seller_Account__c = newAccount.Id,
            BuyerEmail__c = 'test@test.com',
            SellerEmail__c = 'test@test.com'
        );
        insert ro;
        
        Blob beforeblob=Blob.valueOf('Unit Test Attachment Body');
        ContentVersion cv = new ContentVersion();
        cv.title = 'test content';      
        cv.PathOnClient ='test';           
        cv.VersionData = beforeblob;          
        insert cv;
        
        List<ContentDocument> documents = [ SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId = documentRec.id;
        // contentlink.ShareType= 'C';
        contentlink.ContentDocumentId = documents[0].Id;
        contentlink.Visibility = 'AllUsers'; 
        insert contentlink;
        
        JointOwner__c jointOwner1 = TestObjectsFactory.getJointOwnerRecord(salesOrder.id, newAccount.id, 'Friend Of');
        jointOwner1.Opportunity__c = opp2.id;
        jointOwner1.SharePercentage__c = 90; 
        insert jointOwner1;
        Test.stopTest();
        
    }
    
    @isTest 
    static void testGetAvailableResaleUnits(){
        // Arrange
        Set<Id> buildingSectionIdSet = new  Set<Id>();
        List<BuildingSection__c> buildingSectionRecList = [SELECT
                                                           Id 
                                                           FROM BuildingSection__c LIMIt 10 ];
        for(BuildingSection__c bcSec : buildingSectionRecList){
            buildingSectionIdSet.add(bcSec.id);
        }
        
        // Act
        Test.startTest();
        List<Unit__c> unitResultList = ResaleUnitService.getAvailableResaleUnits(buildingSectionIdSet);
        Test.stopTest();
        
        //Assert
        Assert.areEqual(true, unitResultList.size() >0 , 'returns unit list');
        Assert.areEqual(5000, unitResultList[0].Listing_Price__c, 'As we insert the listing price 5000 in set up' );
        Assert.areEqual('Apartment', unitResultList[0].UnitType__c , 'returns resaleList true');
    }
    
    @isTest
    static void testCreateResaleCharges(){ 
        // Arrange
        List<Opportunity> opportunityRecList = [SELECT 
                                                Id, 
                                                Name
                                                FROM opportunity WHERE SalesOrder__c != null LIMIT 1];
        // Act
        Test.startTest();
        ResaleUnitService.createResaleCharges(opportunityRecList);
        Test.stopTest();
        // Assert
        List<SalesOrderOtherCharges__c> createdSalesOrderOtherChargesRecList = [SELECT 
                                                                                Id,
                                                                                Approval_Status__c 
                                                                                FROM SalesOrderOtherCharges__c
                                                                                WHERE Opportunity__c = :opportunityRecList[0].id];
        
        Assert.areEqual(true, createdSalesOrderOtherChargesRecList.size() > 0 , 'As sales order charges is created');
        Assert.areEqual(3, createdSalesOrderOtherChargesRecList.size() , 'Three sales order other charges is created');  
    }
    
    @isTest
    static void testHandleUploadedResaleMOUDocAction(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        //Arrange
        Test.startTest();
        Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>([Select 
                                                                      id,
                                                                      Name
                                                                      FROM opportunity  WHERE Unit__c != null AND Lead_Type__c = 'Resale' LIMIT 1]);
        // Act
        ResaleUnitService.handleUploadedResaleMOUDocAction(opportunityMap.keySet());
        Test.stopTest();
        // Arrange
        Unit__c unitRec = [SELECT id ,MOU_Signed__c FROM Unit__c LIMIT 1];
        opportunity oppRec = [SELECT Id, StageName FROM opportunity WHERE Unit__c != null AND Lead_Type__c = 'Resale' LIMIT 1];
        
        Assert.areEqual(true, unitRec.MOU_Signed__c , 'Unit is Updated With true value of  MOU_Signed__c');
        // Assert.areEqual(ResaleConstants.OPP_STATUS_PAY_PROGRESS, oppRec.StageName );
    }
    
    @isTest 
    static void testGetOpportunityAccountId(){
        //Arrange
        Opportunity oppRec = [SELECT Id,AccountId FROM opportunity LIMIT 1];
        //Act(
        Test.startTest();
        Set<id> accountIdSet = ResaleUnitService.getOpportunityAccountId(oppRec.id);
        List<id> accountIdList = new List<id>(accountIdSet);
        Test.stopTest();
        
        // Assert
        Assert.areEqual(true ,accountIdList.size() > 0 , 'return Account id Set');
        Assert.areEqual(oppRec.AccountId ,accountIdList[0] , 'return opportunity Account id');   
    }
    
    @isTest
    Static void testCreateResaleMOUDocuments(){
        // Arrange
        List<Opportunity> opportunityRecList = [SELECT 
                                                Id, 
                                                Name,
                                                OwnerId
                                                FROM opportunity WHERE SalesOrder__c != null LIMIT 1];
        
        //Act
        Test.startTest();
        ResaleUnitService.createResaleMOUDocuments(opportunityRecList);
        Test.stopTest();
        //Assert
    }
    
    @isTest
    static void testHandleResaleUnitChange(){
        // Arrange
        List<Opportunity> opportunityRecList = [SELECT 
                                                Id, 
                                                Name,
                                                OwnerId
                                                FROM opportunity];
        
        //Act 
        Test.startTest();
        ResaleUnitService.handleResaleUnitChange(opportunityRecList);
        Test.stopTest();
    }
    
 /*   @isTest
    static void testHandleCasePopulationOnResaleLead(){
        // Arrange 
        List<Lead> leadList = [SELECT Id FROM Lead];
        // Act
        Test.startTest();
        ResaleUnitService.handleCasePopulationOnResaleLead(leadList);
        Test.stopTest();
        // Assert
    }*/
    
    @isTest
    static void testDisqualifyOtherOffers(){
        // Arrange
        List<Opportunity> opportunityRecList = [SELECT 
                                                Id, 
                                                Name,
                                                OwnerId
                                                FROM opportunity WHERE SalesOrder__c != null LIMIT 1];
        //Act
        Test.startTest();
        ResaleUnitService.disqualifyOtherOffers(opportunityRecList);
        Test.stopTest();
    }
    
    @isTest
    Static void testManageOpportunityJointOwners(){
        // Arrange
        List<JointOwner__c> jointOwnerList = [SELECT 
                                              Id, 
                                              Opportunity__c,
                                              SharePercentage__c FROM JointOwner__c ]; 
        //Act
        Test.startTest();
        ResaleUnitService.manageOpportunityJointOwners(jointOwnerList);
        Test.stopTest();
        
    }
    
    @isTest
    static void testSearchDefaultRecord(){
        // Arrange 
        Account acc = [SELECT Id FROM Account LIMIT 1];
        // Act
        ResaleUnitService.searchDefaultRecord(acc.Id , 'Account');
        //Assert
    }
    
    @isTest
    static void testGetVFDomainURL(){
        // Act
        ResaleUnitService.getVFDomainURL();
        //Assert
    }

    @IsTest
    static void testUpdateOpportunity(){
        List<Opportunity> opportunityRecList = [SELECT Id, Name, (SELECT Id FROM Documents__r WHERE DocumentType__c = 'Listing MOU') FROM opportunity WHERE SalesOrder__c != null LIMIT 1];

        Id sourceId = opportunityRecList[0].Documents__r[0].Id;
        dfsle__EnvelopeStatus__c envelopeStatus = new dfsle__EnvelopeStatus__c();
        envelopeStatus.dfsle__DocuSignId__c   = '24066dc3-2c7b-4459-90d4-83dcc349efdf';
        envelopeStatus.dfsle__SenderName__c   = 'Test Sender'; // Need to know where it is configured
        envelopeStatus.dfsle__SenderEmail__c  = 'test@test.com'; // Need to know where it is configured
        envelopeStatus.dfsle__EmailSubject__c = 'Test Subject';
        envelopeStatus.dfsle__Status__c       = 'Sent';
        envelopeStatus.dfsle__Sent__c         = system.now();
        envelopeStatus.CreatedFromAPI__c      = true;
        envelopeStatus.dfsle__SourceId__c     = sourceId;

        insert envelopeStatus;

        List<dfsle__RecipientStatus__c> recipientStatusList = new List<dfsle__RecipientStatus__c>();
        for(Integer i = 1; i <= 2; i++){
            dfsle__RecipientStatus__c recipientStatus = new dfsle__RecipientStatus__c();
            recipientStatus.dfsle__EnvelopeStatus__c = envelopeStatus.Id;
            recipientStatus.dfsle__Email__c = 'test'+i+'@test.com';
            recipientStatus.dfsle__RoutingOrder__c = i;
            recipientStatus.dfsle__Type__c = 'Signer';
            recipientStatus.dfsle__Status__c = 'Sent';
            recipientStatus.Name = 'Test Signer '+i;
            recipientStatus.dfsle__Sent__c = System.now();
            recipientStatus.dfsle__SourceId__c = sourceId;
            recipientStatusList.add(recipientStatus);
        }
        insert recipientStatusList;
        Map<Id, dfsle__RecipientStatus__c> oldMap = new Map<Id, dfsle__RecipientStatus__c>(recipientStatusList);

        List<dfsle__RecipientStatus__c> newList = [SELECT Id, dfsle__Status__c, dfsle__Email__c, dfsle__RoutingOrder__c, dfsle__SourceId__c FROM dfsle__RecipientStatus__c LIMIT 1];
        newList[0].dfsle__Status__c = 'Completed';
        Test.startTest();
            ResaleUnitService.updateOpportunity(newList, oldMap);
        Test.stopTest();
        
    }

    @IsTest
    static void testCreatePTCaseForResaleOpps(){
        List<Opportunity> opportunityRecList = [SELECT Id, Name, LeadSource,BuyerComplianceStatus__c, Unit__c FROM opportunity WHERE SalesOrder__c != null LIMIT 1];
        Test.startTest();
            ResaleUnitService.createPTCaseForResaleOpps(opportunityRecList);
        Test.stopTest();
        
    }
}