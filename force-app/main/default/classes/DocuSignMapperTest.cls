@isTest
public with sharing class DocuSignMapperTest {
    @TestSetup
    static void makeData(){
        
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
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
        opp.ReservationApprovalStatus__c = Constants.STATUS_REJECTED;
		update opp;
        
        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(sa.Id, acc.Id, 'Spouse Of');
        insert jointOwner;
                
        Document__c document = TestObjectsFactory.getSalesOrderDocument(opp.Id,sa.Id);
        insert document;
        //ContentVersion conVer = TestObjectsFactory.getContentVersion();
        //insert conVer;
        //TestObjectsFactory.insertContentDocumentLink(document.Id, conVer.Id);
        ContentDocumentLink conLink = TestObjectsFactory.createContentDocumentLink(document.Id);
       
    }

    @IsTest
    static void testGetDocumentRecord(){        
        Test.startTest();
        Document__c document = [SELECT Id FROM Document__c LIMIT 1];
        try{
            DocuSignMapper.getDocumentRecord(document.Id);
        }catch(Exception ex){
            System.debug('Exception');
        }
		try{
            DocuSignMapper.getFile(document.Id);
        }catch(Exception ex){
            System.debug('Exception');
        }                 
        Test.stopTest();        
    }
    @IsTest static void testgetJointOwnersMap(){        
        Test.startTest();
        Document__c document = [SELECT Id FROM Document__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];        
        try{
            DocuSignMapper.createEnvelopeWrapper(document.Id, null);
        }catch(Exception ex){
            System.debug('Exception');
        } 
        Map<Id, String> relatedSObjectIdToTypeMap = new Map<Id, String>();
        relatedSObjectIdToTypeMap.put(acc.Id,'test');
        DocuSignMapper.getJointOwnersMap(relatedSObjectIdToTypeMap);
        DocuSignMapper.getPrimaryAccountsMap(relatedSObjectIdToTypeMap);
        Test.stopTest();        
    }
    @IsTest
    static void testgetRecipients(){        
        Test.startTest();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        try{
            DocuSignWrapper.Signer signer1 = new DocuSignWrapper.Signer(acc.Id,acc.Id,'BUYER');
            DocuSignWrapper.Signer signer2 = new DocuSignWrapper.Signer(acc.Id,acc.Id,'SELLER');
            List<DocuSignWrapper.Signer> lstSigner = new List<DocuSignWrapper.Signer>();
            lstSigner.add(signer1);
            lstSigner.add(signer2);
            DocuSignMapper.getRecipients(lstSigner);
        }catch(Exception ex){
            System.debug('Exception');
        } 
        Test.stopTest();        
    }
    
    

    @IsTest
    static void createRecipientTest(){        
        Test.startTest();
        try{
            DocuSignMapper.createRecipient(true, 'Test', 'Tester@aldar.com', '1000', 1000);
        }catch(Exception ex){
            System.debug('Exception');
        }         
        Test.stopTest();        
    }
}