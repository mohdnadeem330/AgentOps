@isTest
private class HandoverBatchTest {
   //Create setupData
    @testSetup static void setupData() {
        Id handoverRecordType = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        //acc.Id=null;
        acc.PassportNumber__pc = 'N6385378';
        acc.ResidentStatus__pc = 'Resident';
        acc.MaritalStatus__pc = 'Married';
        acc.EmploymentStatus__pc = 'Self Employed';
        acc.PersonEmail = 'test@aldar.com.invalid';
        acc.MobileCountryCode__pc = '971';
        acc.MobilePhone__pc = '9876543115';
        acc.Company__pc = 'XXXXX';
        acc.Position__pc = 'XXX';
        acc.CompanyAddress__pc = 'NA';
        acc.NoofYearswithCompany__pc = 10;
        acc.Industry = 'Agriculture';
        acc.AnnualIncome__pc = 1234567;
        acc.SourceofFunds__pc = 'Profits/Salary';
        acc.CustomerBankName__c = 'XXXXX';
        acc.CustomerBankCountry__c = 'United Arab Emirates';
        insert acc;

        //insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = Constants.UNIT_STATUS_SOLD;
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        
        //SR TEMPLATE
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = Constants.RECORDTYPE_HANDOVER;
        SR_Template.HexaBPM__SR_RecordType_API_Name__c=Constants.RECORDTYPE_HANDOVER;
        insert SR_Template;
        
        
        // STEP AND STEP TEMPLATE
        list<HexaBPM__Step_Template__c> stepTemplateToInsert = new list<HexaBPM__Step_Template__c>();
        list<String> templatesCode = new list<String>{Constants.STEP_NAME_KAR_ASSIGNMENT,
                                                Constants.STEP_NAME_FINANCE_VERIFICATION,
                                                Constants.STEP_NAME_DESNAGGING_APPOINTMENT,
                                                Constants.STEP_NAME_UTILITY_TRANSFER,
                                                Constants.STEP_NAME_KEYHANDOVER_APPOINTMENT,
                                                Constants.STEP_NAME_SNAGGING_APPOINTMENT,
                                                Constants.STEP_NAME_HANDOVER_PHASING,
                                                Constants.STEP_NAME_TITLE_DEED};
        for(String tempS : templatesCode){
            HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
            ST.Name = tempS;
            ST.HexaBPM__Code__c = tempS;
            ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
            stepTemplateToInsert.add(ST);
        }
        insert stepTemplateToInsert;
        
        list<HexaBPM__SR_Steps__c> templateSteps = new list<HexaBPM__SR_Steps__c>();
        for(HexaBPM__Step_Template__c tempRec : stepTemplateToInsert){
            HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
            SRStep.HexaBPM__SR_Template__c = SR_Template.id;
            SRStep.HexaBPM__Step_No__c = templateSteps.size()+1;
            SRStep.HexaBPM__Step_Template__c = tempRec.Id;
            SRStep.HexaBPM__Summary__c = tempRec.Name;
            SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
            templateSteps.add(SRStep);
        }   
        insert templateSteps;
        
        //SR Status 
        insert new list<HexaBPM__SR_Status__c>{ TestObjectsFactory.getSRStatus(Constants.STEP_STATUS_APPOINTMENT_BOOKED),
                                                TestObjectsFactory.getSRStatus(Constants.STEP_STATUS_SENT),
                                                TestObjectsFactory.getSRStatus(Constants.SUBMITTED),
                                                TestObjectsFactory.getSRStatus(Constants.STATUS_DRAFT)};
        
        //Handover 
        HandoverDetails__c hodetail = new HandoverDetails__c(UnitOfferedDate__c = system.today(),
                                                                        Unit__c = unit.Id,
                                                                        HandoverPhaseDate__c = system.today(),
                                                                        Status__c=Constants.HO_STATUS_READY,
                                                                        Stage__c=Constants.HO_STAGE_OFFERED_BY_PROJECTS,
                                                                        SalesOrder__c = salesOrder.Id,
                                                                        isRTOHandover__c =  false,
                                                                        UtilityTransferStatus__c =  Constants.HO_TRANSSTATUS_NOTREADY,
                                                                        TitleDeedStatus__c =  Constants.HO_TRANSSTATUS_NOTREADY    );                                        
        insert hodetail;                                            
        //SR AND STEP
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = handoverRecordType;
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        //SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        SR.HandoverDetail__c = hodetail.Id;
        insert SR;
        
        list<HexaBPM__Step__c> srSteps = new list<HexaBPM__Step__c>();
        for(HexaBPM__SR_Steps__c tempRec : templateSteps){
            HexaBPM__Step__c step = new HexaBPM__Step__c();
            step.HexaBPM__Summary__c = tempRec.HexaBPM__Summary__c;
            step.HexaBPM__SR__c = SR.Id;
            step.HexaBPM__SR_Step__c = tempRec.Id;
            step.HexaBPM__Start_Date__c = System.today();
            srSteps.add(step);
        }
        insert srSteps;
        
        
        //Document Placeholder
        HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c ='Handover Phasing Letter';
        objDocMaster.HexaBPM__Available_to_client__c = true;
        insert objDocMaster;
        
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id ;
       
        insert docTemp;
        HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
        objSRDoc.Name='ERP_SOA';
        objSRDoc.HexaBPM__Document_Master__c = objDocMaster.id  ;
        objSRDoc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c = SR.id  ;
       // objSRDoc.DocumentMasterCode__c='Handover Phasing Letter';
        insert objSRDoc;
        
        ContentVersion cv = new ContentVersion(Title= 'TestDoc.pdf', 
                                                        PathOnClient ='TestDoc.pdf',
                                                        VersionData = blob.valueOf('Methods defined as TestMethod do not support getContent call'), 
                                                        origin = 'H');
        insert cv;
        map<id,ContentVersion> cvMap = new  map<id,ContentVersion>([select id, ContentDocumentId  from ContentVersion where id = :cv.Id]);
        insert new ContentDocumentLink(contentdocumentid = cvMap.get(cv.Id).ContentDocumentId,
                                                          LinkedEntityId = objSRDoc.Id,
                                                          ShareType ='V');
        
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;
        list<PaymentInstallments__c> installmentLine = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert installmentLine;
        paymentPlanRecord.IsActive__c =Constants.YES;
        update paymentPlanRecord;

        Integer dayCount = 30;
        List<InstallmentLines__c> installmentLines = new list<InstallmentLines__c>();
        Decimal totalNetSellingPrice = 1000000;
        SalesOrder__c salesOrderRecord = [SELECT Id FROM SalesOrder__c LIMIT 1];
        for(PaymentInstallments__c tempInstallmentLine : [select Id,BrokerPayoutPercentage__c,Description__c,InstallmentNumber__c,InstallmentPercentage__c,InstallmentDate__c,PaymentPlan__c from PaymentInstallments__c LIMIT 1]){
            installmentLines.add(new InstallmentLines__c( 
                BrokerPayoutPercentage__c= tempInstallmentLine.BrokerPayoutPercentage__c,
                Description__c= tempInstallmentLine.Description__c,
                InstallmentNumber__c = tempInstallmentLine.InstallmentNumber__c,
                InstallmentPercentage__c= tempInstallmentLine.InstallmentPercentage__c,
                InstallmentDate__c = dayCount == 0 ? System.today() : System.today().addDays(dayCount),
                InstallmentAmount__c= totalNetSellingPrice * (tempInstallmentLine.InstallmentPercentage__c/100),
                PaymentInstallments__c= tempInstallmentLine.Id,
                SalesOrder__c = salesOrderRecord.Id,
                PaymentPlan__c= tempInstallmentLine.PaymentPlan__c
            )); 
        }

        insert installmentLines;
        
        hodetail.LastInstallment__c = installmentLines[installmentLines.size() - 1].Id;
        update hodetail;
    }
    
    @isTest
    public static void testBatchHC (){
        Test.startTest();
            HexaBPM__Service_Request__c tempRec = [select id from HexaBPM__Service_Request__c limit 1];
        database.executebatch(new HandoverBatch(new set<ID>{tempRec.Id},HandoverUtility.HANDOVERACTION_SEND_SNAG),1);     
            database.executebatch(new HandoverBatch(new set<ID>{tempRec.Id},HandoverUtility.HANDOVERACTION_SEND_HC),1);     
        Test.stopTest();
    }
    @isTest
    public static void testBatchHP (){
        Test.startTest();
           // HexaBPM__Service_Request__c tempRec = [select id from HexaBPM__Service_Request__c limit 1];
            Unit__c tempUnit = [select id from Unit__c limit 1];
            Map<Id,HandoverDetails__c> createRes = HandoverUtility.createHandoverSR(new set<ID>{tempUnit.Id});
             HexaBPM__Service_Request__c srRecord = [select id,HandoverDetail__c from HexaBPM__Service_Request__c order by createdDate DESC];
            database.executebatch(new HandoverBatch(new set<ID>{srRecord.Id},HandoverUtility.HANDOVERACTION_SEND_HP),1);     
        Test.stopTest();
    }
    @isTest
    public static void testBatchHO (){
        Test.startTest();
            HexaBPM__Service_Request__c tempRec = [select id from HexaBPM__Service_Request__c limit 1];
            database.executebatch(new HandoverBatch(new set<ID>{tempRec.Id},HandoverUtility.HANDOVERACTION_SEND_HO),1);     
        Test.stopTest();
    }
    @isTest
    public static void testBatchRFO (){
        try{
        Test.startTest();
        HexaBPM__Service_Request__c tempRec = [select id from HexaBPM__Service_Request__c limit 1];
        database.executebatch(new HandoverBatch(new set<ID>{tempRec.Id},HandoverUtility.HANDOVERACTION_SEND_RFO),1);     
        Test.stopTest();
        }Catch(exception e){}
    }
}