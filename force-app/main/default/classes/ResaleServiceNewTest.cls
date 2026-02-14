@isTest
public with sharing class ResaleServiceNewTest {
    @TestSetup
    static void makeData(){
        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        project.AsiteProjectName__c = 'Test Project Name';
        project.EligibleforResale__c = true;
        insert project;

        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        insert buildingSection;

        Unit__c unit = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
        unit.Name += '1';
        unit.Status__c = 'Sold';
        unit.CompletionDate__c = System.today().addDays(7);
        unit.ResaleListed__c = true;
        insert unit;
        ResaleServiceNew.checkIfCaseExistForSelectedUnit(unit.Id);   
        Account newAccount = TestObjectsFactory.getPersonAccountRecord();
        newAccount.MaritalStatus__pc = 'Single';
        insert newAccount;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        opp.OwnerManger__c = UserInfo.getUserId();
        insert opp;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        salesOrder.Account__c = newAccount.Id;
        salesOrder.Status__c = 'Sold';
        CalloutToMuleSoft.updateSOSyncStatus = true;
        insert salesOrder;
        CalloutToMuleSoft.updateSOSyncStatus = false;
        
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
        
        User admin1 = TestObjectsFactory.getUserRecord('System Administrator', 'admin');
        admin1.FirstName = 'Admin Testing';
        users.add(admin1);

        insert users;

    }

    @IsTest
    static void testResaleCaseInsert(){
        Id resaleRecordTypeId = ResaleConstants.Resale_Case_RecordTypeId;

        SalesOrder__c so = [SELECT Id, Status__c, Account__c, Unit__c, Unit__r.OffPlanProperty__c FROM SalesOrder__c LIMIT 1][0];
        System.debug(so);
        Case resaleCase = TestObjectsFactory.getCaseRecord(resaleRecordTypeId, '', so.Unit__c, '800-Aldar');
            
        TriggerHandler.processedIds = new Set<Id>();
        Test.startTest();
        insert resaleCase;
        User u = [SELECT Id FROM User where Profile.Name = 'Resale Relationship Manager' LIMIT 1];
        ResaleServiceNew.getCustomerCasesRM(new Map<Id,Id>{resaleCase.AccountId=>u.Id});

        Test.stopTest();
        
        Case caseInDB = [SELECT Id, Status, Origin, 
                                AccountId, SalesOrder__c, 
                                Is_Directly_Assigned__c, Eligible_for_Round_Robin__c 
                         FROM Case 
                         WHERE Unit__c =: so.Unit__c 
                         LIMIT 1][0];
        
        Assert.areEqual(so.Account__c, caseInDB.AccountId, 'Account not populated');
        Assert.areNotEqual(null, caseInDB.SalesOrder__c, 'Sales Order not populated');
    }

    @IsTest
    static void testResaleCase_Existing(){
        Id resaleRecordTypeId = ResaleConstants.Resale_Case_RecordTypeId;

        User rm1 = [SELECT Id FROM User WHERE Name = 'RM1 Testing' LIMIT 1][0];

        SalesOrder__c so = [SELECT Id, Status__c, Account__c, Unit__c, Unit__r.OffPlanProperty__c FROM SalesOrder__c LIMIT 1][0];
        System.debug(so);
        
        Case resaleCase = TestObjectsFactory.getCaseRecord(resaleRecordTypeId, '', so.Unit__c, '800-Aldar');
        TriggerHandler.processedIds = new Set<Id>();
        insert resaleCase;

        Case resaleCase2 = TestObjectsFactory.getCaseRecord(resaleRecordTypeId, '', so.Unit__c, '800-Aldar');
        TriggerHandler.processedIds = new Set<Id>();
        Test.startTest();
            try {
                insert resaleCase2;   
            } catch (Exception ex) {
                System.debug('Error : '+ex.getMessage());
            }
        Test.stopTest();
    }

    @IsTest
    static void testResaleCase_DirectAssignment(){
        Id resaleRecordTypeId = ResaleConstants.Resale_Case_RecordTypeId;
        User rm1 = [SELECT Id FROM User WHERE Name = 'RM1 Testing' LIMIT 1][0];
        User cc1 = [SELECT Id FROM User WHERE Name = 'CCA1 Testing' LIMIT 1][0];

        SalesOrder__c so = [SELECT Id, Status__c, Account__c, Unit__c, Unit__r.Project__c, Unit__r.BuildingSectionName__c, Unit__r.OffPlanProperty__c FROM SalesOrder__c LIMIT 1][0];
        
        Case resaleCase = TestObjectsFactory.getCaseRecord(resaleRecordTypeId, '', so.Unit__c, '800-Aldar');
        resaleCase.OwnerId = ResaleServiceNew.ResaleRRQueue.Id;
        TriggerHandler.processedIds = new Set<Id>();
        insert resaleCase;
        
        Unit__c unit = TestObjectsFactory.getUnitDetail(so.Unit__r.Project__c, so.Unit__r.BuildingSectionName__c);
        unit.CompletionDate__c = System.today().addDays(7);
        unit.Status__c = 'Sold';
        insert unit;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(so.Account__c);
        opp.OwnerManger__c = UserInfo.getUserId();
        opp.Lead_Type__c = null;
        UtilitiesWithoutSharing.bypassOpportunityTrigger = true;
        insert opp;
        UtilitiesWithoutSharing.bypassOpportunityTrigger = false;

        SalesOrder__c so2 = TestObjectsFactory.getSalesOrderRecord(opp.Id, so.Account__c);
        so2.Unit__c = unit.Id;
        so2.IsBookingCompleted__c = true;
        so2.NetAmount__c = 100000;
        so2.Account__c = so.Account__c;
        so2.Status__c = 'Sold';
        CalloutToMuleSoft.updateSOSyncStatus = true;
        insert so2;
        CalloutToMuleSoft.updateSOSyncStatus = false;

        Case resaleCase2 = TestObjectsFactory.getCaseRecord(resaleRecordTypeId, '', so2.Unit__c, '800-Aldar');
        TriggerHandler.processedIds = new Set<Id>();
        
        Test.startTest();
            insert resaleCase2;
        Test.stopTest();
    }
    
    @IsTest
    static void testResaleCase_OwnerUpdate(){
        Id resaleRecordTypeId = ResaleConstants.Resale_Case_RecordTypeId;

        User rm1 = [SELECT Id FROM User WHERE Name = 'RM1 Testing' LIMIT 1][0];

        SalesOrder__c so = [SELECT Id, Status__c, Account__c, Unit__c, Unit__r.OffPlanProperty__c FROM SalesOrder__c LIMIT 1][0];
        System.debug(so);
        
        Case resaleCase = TestObjectsFactory.getCaseRecord(resaleRecordTypeId, '', so.Unit__c, '800-Aldar');
        insert resaleCase;
            
        resaleCase.OwnerId = rm1.Id;
        TriggerHandler.processedIds = new Set<Id>();
        Test.startTest();
            update resaleCase;
        Test.stopTest();
    }

    @IsTest
    static void testResaleCase_Qualified(){
        Id resaleRecordTypeId = ResaleConstants.Resale_Case_RecordTypeId;

        User rm1 = [SELECT Id FROM User WHERE Name = 'RM1 Testing' LIMIT 1][0];

        SalesOrder__c so = [SELECT Id, Status__c, Account__c, Unit__c, Unit__r.OffPlanProperty__c FROM SalesOrder__c LIMIT 1][0];
        System.debug(so);
        
        Case resaleCase = TestObjectsFactory.getCaseRecord(resaleRecordTypeId, '', so.Unit__c, '800-Aldar');
        insert resaleCase;
            
        resaleCase.OwnerId = rm1.Id;
        resaleCase.Status = ResaleConstants.CASE_QUALIFIED;
        TriggerHandler.processedIds = new Set<Id>();
        Test.startTest();
            update resaleCase;
        Test.stopTest();
    }

    @IsTest
    static void testResaleCase_QualifiedToQueue(){
        Id resaleRecordTypeId = ResaleConstants.Resale_Case_RecordTypeId;

        User rm1 = [SELECT Id FROM User WHERE Name = 'RM1 Testing' LIMIT 1][0];

        SalesOrder__c so = [SELECT Id, Status__c, Account__c, Unit__c, Unit__r.OffPlanProperty__c FROM SalesOrder__c LIMIT 1][0];
        System.debug(so);
        
        Case resaleCase = TestObjectsFactory.getCaseRecord(resaleRecordTypeId, '', so.Unit__c, '800-Aldar');
        insert resaleCase;
        
        resaleCase.Status = ResaleConstants.CASE_QUALIFIED;
        resaleCase.OwnerId = ResaleServiceNew.ResaleRRQueue.Id;
        TriggerHandler.processedIds = new Set<Id>();
        Test.startTest();
            update resaleCase;
        Test.stopTest();
    }
    
    @IsTest
    static void testResaleCase_QualifiedOwnerUpdate(){
        Id resaleRecordTypeId = ResaleConstants.Resale_Case_RecordTypeId;

        User rm1 = [SELECT Id FROM User WHERE Name = 'RM1 Testing' LIMIT 1][0];

        SalesOrder__c so = [SELECT Id, Status__c, Account__c, Unit__c, Unit__r.OffPlanProperty__c FROM SalesOrder__c LIMIT 1][0];
        System.debug(so);
        
        Case resaleCase = TestObjectsFactory.getCaseRecord(resaleRecordTypeId, '', so.Unit__c, '800-Aldar');
        insert resaleCase;
        
        resaleCase.Status = ResaleConstants.CASE_QUALIFIED;
        TriggerHandler.processedIds = new Set<Id>();
        update resaleCase;

        resaleCase.OwnerId = rm1.Id;
        TriggerHandler.processedIds = new Set<Id>();
        Test.startTest();
            update resaleCase;
        Test.stopTest();
    }

    @IsTest
    static void testResaleCase_SignatureInProgress(){
        Id resaleRecordTypeId = ResaleConstants.Resale_Case_RecordTypeId;

        User rm1 = [SELECT Id, ManagerId FROM User WHERE Name = 'RM1 Testing' LIMIT 1][0];
        User admin = [SELECT Id FROM User WHERE Name = 'Admin Testing' LIMIT 1][0];

        SalesOrder__c so = [SELECT Id, Status__c, Account__c, Unit__c, Unit__r.OffPlanProperty__c FROM SalesOrder__c LIMIT 1][0];
        System.debug(so);
        
        Case resaleCase = TestObjectsFactory.getCaseRecord(resaleRecordTypeId, '', so.Unit__c, '800-Aldar');
        insert resaleCase;
            
        resaleCase.OwnerId = rm1.Id;
        resaleCase.CustomerContacted__c = true;
        resaleCase.Listing_Price__c = 741852;
        resaleCase.Listing_Expiry__c = '5';
        resaleCase.ResaleListingExclusiveness__c = 'Exclusive';
        resaleCase.Status = ResaleConstants.CASE_DISCUSSION_IN_PROGRESS;
        TriggerHandler.processedIds = new Set<Id>();
        update resaleCase;

        Test.startTest();
            System.runAs(rm1){
                //Submit for Approval
                Approval.ProcessSubmitRequest testapproval = new Approval.ProcessSubmitRequest();
                testapproval.setComments('Submitting request for approval');
                testapproval.setObjectId(resaleCase.Id);
                testapproval.setNextApproverIds(new List<Id>{admin.Id});
                TriggerHandler.processedIds = new Set<Id>();
                Approval.ProcessResult result1 = Approval.process(testapproval);
            }
            List<ProcessInstanceWorkitem> workItems = [ SELECT Id, ProcessInstanceId  
                                                        FROM ProcessInstanceWorkitem 
                                                        WHERE ProcessInstance.TargetObjectId = :resaleCase.Id];
            List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
            for(ProcessInstanceWorkitem workItem : workItems){
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setWorkitemId(workItem.Id);
                req.setAction('Approve');
                req.setComments('Test Comments.');
                requests.add(req);
            }
            TriggerHandler.processedIds = new Set<Id>();    
            Approval.ProcessResult[] processResults = Approval.process(requests);
        Test.stopTest();
    }

    @IsTest
    static void testResaleCase_PropertyListed(){
        Id resaleRecordTypeId = ResaleConstants.Resale_Case_RecordTypeId;

        User rm1 = [SELECT Id FROM User WHERE Name = 'RM1 Testing' LIMIT 1][0];
        User admin = [SELECT Id FROM User WHERE Name = 'Admin Testing' LIMIT 1][0];

        SalesOrder__c so = [SELECT Id, Status__c, Account__c, Unit__c, Unit__r.OffPlanProperty__c FROM SalesOrder__c LIMIT 1][0];
        System.debug(so);
        
        Case resaleCase = TestObjectsFactory.getCaseRecord(resaleRecordTypeId, '', so.Unit__c, '800-Aldar');
        insert resaleCase;
        
        List<Document__c> docs = new List<Document__c>{            
            new Document__c(Case__c = resaleCase.Id, DocumentType__c = ResaleConstants.CASE_SIGNED_LISTING_AGREEMENT_DOCUMENT_TYPE)
        };
        insert docs;
            
        resaleCase.OwnerId = rm1.Id;
        resaleCase.CustomerContacted__c = true;
        resaleCase.Listing_Price__c = 741852;
        resaleCase.Listing_Expiry__c = '5';
        resaleCase.ResaleListingExclusiveness__c = 'Exclusive';
        resaleCase.Status = ResaleConstants.CASE_DISCUSSION_IN_PROGRESS;
        TriggerHandler.processedIds = new Set<Id>();
        update resaleCase;
        
        System.runAs(rm1){
            //Submit for Approval
            Approval.ProcessSubmitRequest testapproval = new Approval.ProcessSubmitRequest();
            testapproval.setComments('Submitting request for approval');
            testapproval.setObjectId(resaleCase.Id);
            TriggerHandler.processedIds = new Set<Id>();
            Approval.ProcessResult result1 = Approval.process(testapproval);
        }

        List<ProcessInstanceWorkitem> workItems = [ SELECT Id, ProcessInstanceId  
                                                    FROM ProcessInstanceWorkitem 
                                                    WHERE ProcessInstance.TargetObjectId = :resaleCase.Id];
        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
        for(ProcessInstanceWorkitem workItem : workItems){
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setWorkitemId(workItem.Id);
            req.setAction('Approve');
            req.setComments('Test Comments.');
            requests.add(req);
        }
        TriggerHandler.processedIds = new Set<Id>();
        Test.startTest();    
        Approval.ProcessResult[] processResults = Approval.process(requests);
        
        List<Document__c> docRecs = [SELECT Id, Case__c, Status__c FROM Document__c WHERE Case__c =: resaleCase.Id AND DocumentType__c =: ResaleConstants.CASE_SIGNED_LISTING_AGREEMENT_DOCUMENT_TYPE];

        Blob beforeblob=Blob.valueOf('Unit Test Attachment Body');

        ContentVersion cv = new ContentVersion();
            cv.title = 'test content';      
            cv.PathOnClient ='test';           
            cv.VersionData =beforeblob;          
        insert cv;

        List<ContentDocument> documents = [ SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=docRecs[0].id;
        // contentlink.ShareType= 'C';Dummy Commite
        contentlink.ContentDocumentId=documents[0].Id;
        contentlink.Visibility = 'AllUsers'; 

        TriggerHandler.processedIds = new Set<Id>();
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        insert contentlink;
        Test.stopTest();
    }

    @IsTest
    static void testResaleCase_Cancelled(){
        Id resaleRecordTypeId = ResaleConstants.Resale_Case_RecordTypeId;

        User rm1 = [SELECT Id FROM User WHERE Name = 'RM1 Testing' LIMIT 1][0];
        User admin = [SELECT Id FROM User WHERE Name = 'Admin Testing' LIMIT 1][0];

        SalesOrder__c so = [SELECT Id, Status__c, Account__c, Unit__c, Unit__r.OffPlanProperty__c FROM SalesOrder__c LIMIT 1][0];
        System.debug(so);
        
        Case resaleCase = TestObjectsFactory.getCaseRecord(resaleRecordTypeId, '', so.Unit__c, '800-Aldar');
        insert resaleCase;
        
        List<Document__c> docs = new List<Document__c>{            
            new Document__c(Case__c = resaleCase.Id, DocumentType__c = ResaleConstants.CASE_SIGNED_LISTING_AGREEMENT_DOCUMENT_TYPE)
        };
        insert docs;
            
        resaleCase.OwnerId = rm1.Id;
        resaleCase.CustomerContacted__c = true;
        resaleCase.Listing_Price__c = 741852;
        resaleCase.Listing_Expiry__c = '5';
        resaleCase.ResaleListingExclusiveness__c = 'Exclusive';
        resaleCase.Status = ResaleConstants.CASE_DISCUSSION_IN_PROGRESS;
        TriggerHandler.processedIds = new Set<Id>();
        update resaleCase;
        
        System.runAs(rm1){
            //Submit for Approval
            Approval.ProcessSubmitRequest testapproval = new Approval.ProcessSubmitRequest();
            testapproval.setComments('Submitting request for approval');
            testapproval.setObjectId(resaleCase.Id);
            testapproval.setNextApproverIds(new List<Id>{admin.Id});
            TriggerHandler.processedIds = new Set<Id>();
            Approval.ProcessResult result1 = Approval.process(testapproval);
        }
        Test.startTest();

        List<ProcessInstanceWorkitem> workItems = [ SELECT Id, ProcessInstanceId  
                                                    FROM ProcessInstanceWorkitem 
                                                    WHERE ProcessInstance.TargetObjectId = :resaleCase.Id];
        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
        for(ProcessInstanceWorkitem workItem : workItems){
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setWorkitemId(workItem.Id);
            req.setAction('Approve');
            req.setComments('Test Comments.');
            requests.add(req);
        }
        TriggerHandler.processedIds = new Set<Id>();
        Approval.ProcessResult[] processResults = Approval.process(requests);

        List<Document__c> docRecs = [SELECT Id, Case__c, Status__c FROM Document__c WHERE Case__c =: resaleCase.Id AND DocumentType__c =: ResaleConstants.CASE_SIGNED_LISTING_AGREEMENT_DOCUMENT_TYPE];

        Blob beforeblob=Blob.valueOf('Unit Test Attachment Body');

        ContentVersion cv = new ContentVersion();
            cv.title = 'test content';      
            cv.PathOnClient ='test';           
            cv.VersionData =beforeblob;          
        insert cv;

        List<ContentDocument> documents = [ SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=docRecs[0].id;
        // contentlink.ShareType= 'C';
        contentlink.ContentDocumentId=documents[0].Id;
        contentlink.Visibility = 'AllUsers';
        
        TriggerHandler.processedIds = new Set<Id>();
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        insert contentlink;

        resaleCase.Status = ResaleConstants.CASE_CANCELLED;
        resaleCase.CancellationReason__c = ResaleConstants.CASE_CANCELLATION_REASON_OTHER;
        TriggerHandler.processedIds = new Set<Id>();
              update resaleCase;
        Test.stopTest();
    }

    @IsTest
    static void testResaleCase_CreateCharges(){
        Id resaleRecordTypeId = ResaleConstants.Resale_Case_RecordTypeId;

        User rm1 = [SELECT Id FROM User WHERE Name = 'RM1 Testing' LIMIT 1][0];
        User admin = [SELECT Id FROM User WHERE Name = 'Admin Testing' LIMIT 1][0];

        SalesOrder__c so = [SELECT Id, Status__c, Account__c, Unit__c, Unit__r.OffPlanProperty__c FROM SalesOrder__c LIMIT 1][0];
        
        Case resaleCase = TestObjectsFactory.getCaseRecord(resaleRecordTypeId, '', so.Unit__c, '800-Aldar');
        insert resaleCase;
            
        resaleCase.OwnerId = rm1.Id;
        resaleCase.CustomerContacted__c = true;
        resaleCase.Listing_Price__c = 741852;
        resaleCase.Listing_Expiry__c = '5';
        resaleCase.ResaleListingExclusiveness__c = 'Exclusive';
        resaleCase.Status = ResaleConstants.CASE_DISCUSSION_IN_PROGRESS;
        TriggerHandler.processedIds = new Set<Id>();
        update resaleCase;
        
        // System.runAs(rm1){
        //     //Submit for Approval
        //     Approval.ProcessSubmitRequest testapproval = new Approval.ProcessSubmitRequest();
        //     testapproval.setComments('Submitting request for approval');
        //     testapproval.setObjectId(resaleCase.Id);
        //     testapproval.setNextApproverIds(new List<Id>{admin.Id});
        //     TriggerHandler.processedIds = new Set<Id>();
        //     Approval.ProcessResult result1 = Approval.process(testapproval);
        // }

        // List<ProcessInstanceWorkitem> workItems = [ SELECT Id, ProcessInstanceId  
        //                                             FROM ProcessInstanceWorkitem 
        //                                             WHERE ProcessInstance.TargetObjectId = :resaleCase.Id];
        // List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
        // for(ProcessInstanceWorkitem workItem : workItems){
        //     Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        //     req.setWorkitemId(workItem.Id);
        //     req.setAction('Approve');
        //     req.setComments('Test Comments.');
        //     requests.add(req);
        // }
        // TriggerHandler.processedIds = new Set<Id>();
        // Approval.ProcessResult[] processResults = Approval.process(requests);

        // List<Document__c> docRecs = [SELECT Id, Case__c, Status__c FROM Document__c WHERE Case__c =: resaleCase.Id AND DocumentType__c =: ResaleConstants.CASE_SIGNED_LISTING_AGREEMENT_DOCUMENT_TYPE];

        // Blob beforeblob=Blob.valueOf('Unit Test Attachment Body');

        // ContentVersion cv = new ContentVersion();
        //     cv.title = 'test content';      
        //     cv.PathOnClient ='test';           
        //     cv.VersionData =beforeblob;          
        // insert cv;

        // List<ContentDocument> documents = [ SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        // ContentDocumentLink contentlink=new ContentDocumentLink();
        // contentlink.LinkedEntityId=docRecs[0].id;
        // // contentlink.ShareType= 'C';
        // contentlink.ContentDocumentId=documents[0].Id;
        // contentlink.Visibility = 'AllUsers';
        
        // TriggerHandler.processedIds = new Set<Id>();
        // StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        // mock.setStatusCode(200);
        // mock.setStaticResource('GetSMSNotificationSuccess');
        // Test.setMock(HttpCalloutMock.class, mock);
        
        // insert contentlink;

        // resaleCase.Status = ResaleConstants.CASE_CANCELLED;
        // resaleCase.CancellationReason__c = ResaleConstants.CASE_CANCELLATION_REASON_OTHER;
        // TriggerHandler.processedIds = new Set<Id>();
        // update resaleCase;

        Test.startTest();
            ResaleServiceNew.createResaleCharges_AuraEnabled(resaleCase.Id);
        Test.stopTest();
    }

    @IsTest
    static void testUncoveredMethods(){
        SalesOrder__c so = [SELECT Id, Status__c, Account__c, Unit__c, Unit__r.OffPlanProperty__c FROM SalesOrder__c LIMIT 1][0];
        ResaleServiceNew.getSalesOrder(so.Id);

        Id resaleRecordTypeId = ResaleConstants.Resale_Case_RecordTypeId;
        Case resaleCase = TestObjectsFactory.getCaseRecord(resaleRecordTypeId, '', so.Unit__c, '800-Aldar');
        insert resaleCase;
        ResaleServiceNew.getCase(resaleCase.Id);

        try {
            ResaleServiceNew.createResaleCharges_AuraEnabled('a2A8d000001X6R1EAK');            
        } catch (Exception ex) {
            System.debug(ex.getMessage());
        }

        try {
            ResaleServiceNew.createResaleCharges_AuraEnabled(so.Id);            
        } catch (Exception ex) {
            System.debug(ex.getMessage());
        }
    }

    @IsTest
    static void test_processCaseFromTask(){
        Id resaleRecordTypeId = ResaleConstants.Resale_Case_RecordTypeId;

        User rm1 = [SELECT Id FROM User WHERE Name = 'RM1 Testing' LIMIT 1][0];
        User admin = [SELECT Id FROM User WHERE Name = 'Admin Testing' LIMIT 1][0];
        SalesOrder__c so = [SELECT Id, Status__c, Account__c, Unit__c, Unit__r.OffPlanProperty__c FROM SalesOrder__c LIMIT 1][0];
        System.debug(so);
        
        Case resaleCase = TestObjectsFactory.getCaseRecord(resaleRecordTypeId, '', so.Unit__c, '800-Aldar');
        insert resaleCase;

        resaleCase.OwnerId = rm1.Id;
        resaleCase.Status = ResaleConstants.CASE_QUALIFIED;
        TriggerHandler.processedIds = new Set<Id>();
        update resaleCase;
        Task ts = [SELECT Id,WhatId,Subject,OwnerId, CustomerResponse__c FROM Task WHERE WhatId =: resaleCase.Id LIMIT 1];
        
        
//        for(Task t : ts){
//            ts.CustomerResponse__c = ResaleConstants.CUSTOMER_REACHED;
//        }
        Task t2 = new Task();
        t2 = ts;
        t2.CustomerResponse__c = ResaleConstants.CUSTOMER_REACHED;
        ResaleServiceNew.processCaseFromTask(new List<Task>{ts},new Map<Id,Task>{t2.Id => t2});

        Test.startTest();
            System.runAs(rm1){
                update ts;
            }
        ResaleServiceNew.processResaleTransfers(new Set<Id>{so.Id});
        Test.stopTest();
    }
    @isTest
    static void getInfoFromResaleCases_Insert_test(){
        Id resaleRecordTypeId = ResaleConstants.Resale_Case_RecordTypeId;

        User rm1 = [SELECT Id FROM User WHERE Name = 'RM1 Testing' LIMIT 1][0];
        User admin = [SELECT Id FROM User WHERE Name = 'Admin Testing' LIMIT 1][0];
        Unit__c unit = [Select id from Unit__c Where Status__c = 'Sold' and ResaleListed__c = true][0];
        SalesOrder__c so = [SELECT Id, Status__c, Account__c, Unit__c, Unit__r.OffPlanProperty__c FROM SalesOrder__c LIMIT 1][0];
        System.debug(so);
        
        Case resaleCase = TestObjectsFactory.getCaseRecord(resaleRecordTypeId, '', so.Unit__c, '800-Aldar');
        resaleCase.Unit__c = unit.Id;        
        insert resaleCase;

        resaleCase.OwnerId = admin.Id;
        resaleCase.Status = ResaleConstants.CASE_AGREEMENT_SIGNATURE_IN_PROCESS;
        resaleCase.ReferredBy__c = rm1.Id;
        TriggerHandler.processedIds = new Set<Id>();
        update resaleCase;
        
        resaleCase.Status = ResaleConstants.CASE_PROPERTY_LISTED;
        TriggerHandler.processedIds = new Set<Id>();
        //update resaleCase;
        ResaleServiceNew.listUnitsAfterAgreementSignature(new Set<Id>{resaleCase.id});
        ResaleServiceNew.validateSignedDocumentForCases(ResaleConstants.CASE_SIGNED_LISTING_AGREEMENT_DOCUMENT_TYPE,new Map<Id,Boolean>{resaleCase.id=>true});
        List<Case> newCase = new List<Case>{resaleCase};
        ResaleServiceNew.getInfoFromResaleCases_Insert(newCase);
        ResaleServiceNew.getRecordTypeId('Case','Requests');
        ResaleServiceNew.getRecordTypeName('Case',resaleRecordTypeId);
        ResaleServiceNew.getSystemMessage(Constants.CUSTOMER_BLACKLISTED);
        ResaleServiceNew.getProfileByIds(new List<String>{'System Administrator'});
        ResaleServiceNew.getPermissionAssignedMap('ServiceUsers');
        
    }
    
    @isTest
    static void getInfoFromResaleCases_Update_test(){
        
        
    }
}