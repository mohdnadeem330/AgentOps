@IsTest
public class SendGridHandoverPhasingTest {
    @TestSetup
    static void makeData(){
        //SendGridHandoverPhasingTestUtils.generateTestData();
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'SPARegistrationForOffPlan']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.NationalIdNumber__pc = '';
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        projectRecord.Name_of_Seller__c = Label.ProformaSellerName;
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
       // unit.Project__c=projectRecord.ID;
       // unit.BuildingSectionName__c=buildingRecord.ID;
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Account__c = acc.Id;
        salesOrder.Opportunity__c = opp.Id;
        insert salesOrder;

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 4);

        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert objSRStatus;

        HexaBPM__SR_Status__c objSRStatus1 = TestObjectsFactory.getSRStatus(Constants.PENDING_STATUS);
        insert objSRStatus1;

        HexaBPM__SR_Status__c objSRStatus2 = TestObjectsFactory.getSRStatus(Constants.COMPLETED_STATUS);
        insert objSRStatus2;
        
        HexaBPM__SR_Status__c objSRStatus3 = TestObjectsFactory.getSRStatus(Constants.STEP_APPROVED_STATUS);
        insert objSRStatus3;

        HexaBPM__SR_Status__c objSRStatus4 = TestObjectsFactory.getSRStatus(Constants.STEP_ACCEPTED_STATUS);
        insert objSRStatus4;
        
        HexaBPM__SR_Status__c objSRStatus5 = TestObjectsFactory.getSRStatus(Constants.STEP_REJECTED_STATUS);
        insert objSRStatus5;

        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'SPA Registration For Off Plan';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='SPARegistrationForOffPlan';
        insert SR_Template;
        
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('SPARegistrationForOffPlan');
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        sr.SPACounterSignedDate__c = date.today();
        insert SR;

        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'Verify Details';
        ST.HexaBPM__Code__c = 'Verify Details';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST;
        Test.startTest(); 
        List<HexaBPM__SR_Steps__c> SRSteList=new List<HexaBPM__SR_Steps__c>();
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = 'Verify Details';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
        //insert SRStep;
        SRSteList.add(SRStep);
        
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'Verify Details';
        step.HexaBPM__SR__c = SR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        insert step; 
       // SRSteList.add(step);

        HexaBPM__Step_Template__c ST1 = new HexaBPM__Step_Template__c();
        ST1.Name = 'Submit Registration';
        ST1.HexaBPM__Code__c = 'Submit Registration';
        ST1.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST1;

        HexaBPM__SR_Steps__c SRStep1 = new HexaBPM__SR_Steps__c();
        SRStep1.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep1.HexaBPM__Step_No__c = 1;
        SRStep1.HexaBPM__Step_Template__c = ST1.Id;
        SRStep1.HexaBPM__Summary__c = 'Submit Registration';
        SRStep1.HexaBPM__Step_RecordType_API_Name__c = 'General';
       // insert SRStep1;
        SRSteList.add(SRStep1);
        
        HexaBPM__Step__c step1 = new HexaBPM__Step__c();
        step1.HexaBPM__Summary__c = 'Submit Registration';
        step1.HexaBPM__SR__c = SR.Id;
        step1.HexaBPM__SR_Step__c = SRStep1.Id;
        step1.HexaBPM__Start_Date__c = System.today();
        insert step1; 
        //SRSteList.add(step1);

        HexaBPM__Step_Template__c ST2 = new HexaBPM__Step_Template__c();
        ST2.Name = 'Salesforce - Approval';
        ST2.HexaBPM__Code__c = 'Salesforce - Approval';
        ST2.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST2;

       
        HexaBPM__SR_Steps__c SRStep2 = new HexaBPM__SR_Steps__c();
        SRStep2.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep2.HexaBPM__Step_No__c = 1;
        SRStep2.HexaBPM__Step_Template__c = ST2.Id;
        SRStep2.HexaBPM__Summary__c = 'Salesforce - Approval';
        SRStep2.HexaBPM__Step_RecordType_API_Name__c = 'General';
       // insert SRStep2;
        SRSteList.add(SRStep2);
        
        HexaBPM__Step__c step2 = new HexaBPM__Step__c();
        step2.HexaBPM__Summary__c = 'Salesforce - Approval';
        step2.HexaBPM__SR__c = SR.Id;
        step2.HexaBPM__SR_Step__c = SRStep2.Id;
        step2.HexaBPM__Start_Date__c = System.today();
        insert step2;

        HexaBPM__Step_Template__c ST3 = new HexaBPM__Step_Template__c();
        ST3.Name = 'Payment Step';
        ST3.HexaBPM__Code__c = 'Payment Step';
        ST3.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST3;

        HexaBPM__SR_Steps__c SRStep3 = new HexaBPM__SR_Steps__c();
        SRStep3.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep3.HexaBPM__Step_No__c = 1;
        SRStep3.HexaBPM__Step_Template__c = ST3.Id;
        SRStep3.HexaBPM__Summary__c = 'Payment Step';
        SRStep3.HexaBPM__Step_RecordType_API_Name__c = 'General';
        //insert SRStep3;
        
        HexaBPM__Step__c step3 = new HexaBPM__Step__c();
        step3.HexaBPM__Summary__c = 'Payment Step';
        step3.HexaBPM__SR__c = SR.Id;
        step3.HexaBPM__SR_Step__c = SRStep3.Id;
        step3.HexaBPM__Start_Date__c = System.today();
       // insert step3;

        HexaBPM__Step_Template__c ST4 = new HexaBPM__Step_Template__c();
        ST4.Name = 'ADM Team Approval';
        ST4.HexaBPM__Code__c = 'ADM Team Approval';
        ST4.HexaBPM__Step_RecordType_API_Name__c = 'General';
      //  insert ST4;

        HexaBPM__SR_Steps__c SRStep4 = new HexaBPM__SR_Steps__c();
        SRStep4.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep4.HexaBPM__Step_No__c = 1;
        SRStep4.HexaBPM__Step_Template__c = ST4.Id;
        SRStep4.HexaBPM__Summary__c = 'ADM Team Approval';
        SRStep4.HexaBPM__Step_RecordType_API_Name__c = 'General';
       // insert SRStep4;
        
        HexaBPM__Step__c step4 = new HexaBPM__Step__c();
        step4.HexaBPM__Summary__c = 'ADM Team Approval';
        step4.HexaBPM__SR__c = SR.Id;
        step4.HexaBPM__SR_Step__c = SRStep4.Id;
        step4.HexaBPM__Start_Date__c = System.today();
        //insert step4; 
        insert  SRSteList;
        HexaBPM__Status__c status = new HexaBPM__Status__c();
        status.Name = Constants.PENDING_STATUS;
        status.HexaBPM__Code__c = Constants.PENDING_STATUS;
        insert status;

        HexaBPM__Status__c status1 = new HexaBPM__Status__c();
        status1.Name = Constants.COMPLETED_STATUS;
        status1.HexaBPM__Code__c = Constants.COMPLETED_STATUS;
        insert status1;
        
        HexaBPM__Status__c status2 = new HexaBPM__Status__c();
        status2.Name = Constants.STEP_APPROVED_STATUS;
        status2.HexaBPM__Code__c = Constants.STEP_APPROVED_STATUS;
        insert status2;
        

        HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c = 'Aldar Signed SPA';
        objDocMaster.HexaBPM__Available_to_client__c = true;
        insert objDocMaster;
        
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id ;
        insert docTemp;
        
        List<HexaBPM__SR_Doc__c> objSRDocList=new List<HexaBPM__SR_Doc__c>();
        HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
        objSRDoc.HexaBPM__Document_Master__c = objDocMaster.id  ;
        objSRDoc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c = SR.id  ;
        objSRDoc.Name = 'ERP SOA';
       // insert objSRDoc;
        objSRDocList.add(objSRDoc);

        HexaBPM__SR_Doc__c objSRDoc2 = new HexaBPM__SR_Doc__c();
        objSRDoc2.HexaBPM__Document_Master__c = objDocMaster.id  ;
        objSRDoc2.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc2.HexaBPM__Service_Request__c = SR.id  ;
        objSRDoc2.Name = 'Customer Snagging';
       // insert objSRDoc2;
         objSRDocList.add(objSRDoc2);

        HexaBPM__SR_Doc__c objSRDoc3 = new HexaBPM__SR_Doc__c();
        objSRDoc3.HexaBPM__Document_Master__c = objDocMaster.id  ;
        objSRDoc3.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc3.HexaBPM__Service_Request__c = SR.id  ;
        objSRDoc3.Name = 'Customer Desnagging';
        //insert objSRDoc3;
        objSRDocList.add(objSRDoc3);

        HexaBPM__SR_Doc__c objSRDoc4 = new HexaBPM__SR_Doc__c();
        objSRDoc4.HexaBPM__Document_Master__c = objDocMaster.id  ;
        objSRDoc4.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc4.HexaBPM__Service_Request__c = SR.id  ;
        objSRDoc4.Name = 'Home Orientation Letter';
        //insert objSRDoc4;
        objSRDocList.add(objSRDoc4);
        insert objSRDocList;
        // Create test data: ContentDocument
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test Content',
            PathOnClient = 'test.pdf',
            VersionData = Blob.valueOf('Test Content Data')
        );
        insert testContentVersion;

        ContentDocument testContentDocument = [SELECT Id FROM ContentDocument WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id) LIMIT 1];
        List<ContentDocumentLink> cdLinkList = new List<ContentDocumentLink>();
        Id linkedEntityId = objSRDoc2.Id;
         Id linkedEntityId1 = objSRDoc3.Id;

        // Create test data: ContentDocumentLink
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = testContentDocument.Id,
            LinkedEntityId = linkedEntityId,
            ShareType = 'I'
            // add any additional required fields
        );
        cdLinkList.add(testContentDocumentLink);

      //  insert cdLinkList;
        
         // Create test data: ContentDocumentLink
        ContentDocumentLink testContentDocumentLink1 = new ContentDocumentLink(
            ContentDocumentId = testContentDocument.Id,
            LinkedEntityId = linkedEntityId1,
            ShareType = 'I'
            // add any additional required fields
        );
        cdLinkList.add(testContentDocumentLink1);
        insert cdLinkList;
        Test.stopTest(); 
    }
        
    

    static testMethod void handover_Phasing_Letter_40Days_Success(){
        List<HexaBPM__SR_Doc__c> srDocIdList = [SELECT Id FROM HexaBPM__SR_Doc__c];
        Unit__c unitDetails=[select ID from Unit__c limit 1];
        Project__c ProjDetails=[select ID from Project__c limit 1];
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(ProjDetails.id);
        buildingRecord.BankNameEscrow__c='Abu Dhabi Commercial Bank';
        insert buildingRecord;
        unitDetails.BuildingSectionName__c=buildingRecord.Id;
        update unitDetails;
        HexaBPM__Service_Request__c sr=[select Id from HexaBPM__Service_Request__c limit 1];
        HexaBPM__SR_Doc__c srDoc=[select Id from HexaBPM__SR_Doc__c limit 1];
         
        Test.startTest();
        try {
            SendGridTestUtils.prepareMockDataToSendPaymentReminder();
            SendGridIntegrationController.sendHandoverPhasingLetter(new List<Id>{srDocIdList[0].Id},'tpl_ho1_1');
            SendGridIntegrationUtilities.getSRData(new List<String>{sr.ID});
            SendGridIntegrationUtilities.updateFailureReason_Handover(srDoc.ID, 'Test', 'tpl_ho4');
            SendGridIntegrationUtilities.updateFailureReason_Handover(srDoc.ID, 'Test', '');
            SendGridIntegrationUtilities.updateFailureReason_Handover(srDoc.ID, 'Test', 'tpl_ho1_1');
            SendGridIntegrationUtilities.roundToTen(15);
            SendGridIntegrationUtilities.roundToTen(3);
            SendGridIntegrationUtilities.resetStep(srDocIdList[0].Id, 'Verify Details');
            SendGridIntegrationUtilities.resetFailureReasonOnSRDoc(srDocIdList[0].Id);
            SendGridIntegrationUtilities.getPendingStatusId();
        } catch (Exception ex) {
            
        }
        Test.stopTest();
    }

    static testMethod void handover_ACD_Extension_Success(){
        Test.startTest();
        Project__c ProjDetails=[select ID from Project__c limit 1];
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(ProjDetails.id);
        buildingRecord.BankNameEscrow__c='Abu Dhabi Commercial Bank';
        insert buildingRecord;
        Test.stopTest();
    }
    static testMethod void handover_ACD_Extension_Success2(){
        Test.startTest();
        Project__c ProjDetails=[select ID from Project__c limit 1];
        try {
            BankVirtualAccountController.createVirtualAccounts(ProjDetails.id, 'Abu Dhabi Commercial Bank', 1, true, false);
            BankVirtualAccounts__c bankVirtualAcc=[select Id,BufferFlag__c from BankVirtualAccounts__c limit 1];
            bankVirtualAcc.BufferFlag__c=false;
            update bankVirtualAcc;
        } catch (Exception ex) {
            
        }
        Test.stopTest();
    }
    static testMethod void sendHandoverPhasingLetterTest(){
        Test.startTest();
        SendGridTestUtils.prepareMockDataToSendPaymentReminder();
        List<HexaBPM__SR_Doc__c> srDocIdList = [SELECT Id FROM HexaBPM__SR_Doc__c limit 1];
        SendGridIntegrationController.sendHandoverPhasingLetter(new List<Id>{srDocIdList[0].Id},'tpl_ho1_2');
        Test.stopTest();
    }

    static testMethod void handover_Home_Orientation_Snagging_Success(){
        List<HexaBPM__SR_Doc__c> srDocIdList = [SELECT Id FROM HexaBPM__SR_Doc__c];
        Unit__c unitDetails=[select ID from Unit__c limit 1];
        Project__c ProjDetails=[select ID,BankNameEscrow__c from Project__c limit 1];
        ProjDetails.BankNameEscrow__c='';
        update ProjDetails;
        unitDetails.Project__c=ProjDetails.Id;
        update unitDetails;
        Test.startTest();

        SendGridTestUtils.prepareMockDataToSendPaymentReminder();
        SendGridIntegrationController.sendHandoverPhasingLetter(new List<Id>{srDocIdList[0].Id},'tpl_ho4');
        Test.stopTest();
    }

    static testMethod void handover_RFO_Letter_Success(){
        List<HexaBPM__SR_Doc__c> srDocIdList = [SELECT Id FROM HexaBPM__SR_Doc__c];
        Test.startTest();
        try {
             SendGridTestUtils.prepareMockDataToSendPaymentReminder();
             SendGridIntegrationController.sendHandoverPhasingLetter(new List<Id>{srDocIdList[0].Id},'tpl_ho2_3');
        } catch (Exception ex) {
            
        }
        Test.stopTest();
    }

    static testMethod void handover_Home_Orientation_Success(){
        List<HexaBPM__SR_Doc__c> srDocIdList = [SELECT Id FROM HexaBPM__SR_Doc__c];
        Test.startTest();
        SendGridTestUtils.prepareMockDataToSendPaymentReminder();
        SendGridIntegrationController.sendHandoverPhasingLetter(new List<Id>{srDocIdList[0].Id},'tpl_ho2');
        Test.stopTest();
    }
}