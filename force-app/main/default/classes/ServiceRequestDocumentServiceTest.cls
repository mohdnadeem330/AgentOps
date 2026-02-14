@isTest(SeeAllData=false)
public class ServiceRequestDocumentServiceTest {
    
    @testSetup static void setupData() {
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND (DeveloperName = 'PaymentExtension' OR DeveloperName = 'PaymentPlanChange')]){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
        acc.Email__c = 'ali.athamneh@pwc.com';
        insert acc;

        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ali.athamneh@pwc.com';
        update con;
        
        /*Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.PersonEmail = 'ali.athamneh@pwc.com';
        insert acc;*/
                
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert objSRStatus;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Account__c = acc.Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.Unit__c = unit.Id;
        salesOrder.NetAmount__c = 1000;
        insert salesOrder;

        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Payment Plan Change';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='PaymentPlanChange';
        insert SR_Template;
        
        HexaBPM__SR_Template__c SR_Template2 = new HexaBPM__SR_Template__c();
        SR_Template2.Name = 'Cheque Replacement';
        SR_Template2.HexaBPM__SR_RecordType_API_Name__c='ChequeReplacement';
        insert SR_Template2;
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('PaymentPlanChange');
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        SR.NewNetAmount__c = 20000;
        insert SR;
        
        HexaBPM__Service_Request__c SR2 = new HexaBPM__Service_Request__c();
        SR2.RecordTypeId = recordTypeSR.get('PaymentPlanChange');
        SR2.HexaBPM__Customer__c = acc.Id;
        SR2.HexaBPM__Contact__c = acc.PersonContactId;
        SR2.OwnerId = UserInfo.getUserId();
        SR2.HexaBPM__SR_Template__c = SR_Template.Id;
        SR2.Unit__c = unit.Id;
        SR2.SalesOrder__c = salesOrder.Id;
        SR2.NewNetAmount__c = 1234;
        insert SR2;
        
        HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
        objSRDoc.HexaBPM__Service_Request__c = SR.id  ;
        objSRDoc.Name = Constants.SUPPORTING_DOCUMENTS_SRDOC;
        insert objSRDoc;
        
        HexaBPM__SR_Doc__c objSRDoc2 = new HexaBPM__SR_Doc__c();
        objSRDoc2.HexaBPM__Service_Request__c = SR2.id  ;
        objSRDoc2.Name = Constants.SUPPORTING_DOCUMENTS_SRDOC;
        insert objSRDoc2;
    }
    
    @isTest static void callMethod() {

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Opportunity__c, Unit__c, HexaBPM__Customer__c, Unit__r.BuildingSectionName__r.TaxPercentage__c, NewNetAmount__c, HexaBPM__Contact__c From HexaBPM__Service_Request__c Where NewNetAmount__c = 20000 Limit 1];
		
        Id recordTypeId = Utilities.getRecordTypeId('Case', 'Standard Case');
        Case caseRecord = TestObjectsFactory.getCaseRecord(recordTypeId, '', SR.Unit__c, 'Phone');
        insert caseRecord;

        Document__c document = new Document__c();
        document.SalesOrder__c = SR.SalesOrder__c;    
        document.DocumentType__c = 'Aldar Signed SPA';
        insert document;
        
        TestObjectsFactory.createContentDocumentLink(document.Id);
        
		HexaBPM__Service_Request__c SR1 = [Select Id, SalesOrder__c, SalesOrder__r.Opportunity__c, Unit__c, HexaBPM__Customer__c, Unit__r.BuildingSectionName__r.TaxPercentage__c, NewNetAmount__c, HexaBPM__Contact__c From HexaBPM__Service_Request__c Where NewNetAmount__c = 1234 Limit 1];
        //TestObjectsFactory.createContentDocumentLink(caseRecord.Id);

        Test.startTest();
		ServiceRequestDocumentService.getCaseUploadedFiles(caseRecord.Id, SR.Id, Constants.SUPPORTING_DOCUMENTS_SRDOC);
		ServiceRequestDocumentService.getExistingUploadedFiles(SR.SalesOrder__c, SR.Id, Constants.SUPPORTING_DOCUMENTS_SRDOC, 'Aldar Signed SPA');

        Test.stopTest();
    }
}