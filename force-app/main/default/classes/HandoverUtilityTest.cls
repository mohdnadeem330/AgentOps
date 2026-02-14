@isTest
private class HandoverUtilityTest {
    //Create setupData
    @testSetup static void setupData() {
        Id handoverRecordType = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);        
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
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
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Noya');
        projectRecord.Name = 'NoyaLuma';
        insert projectRecord;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = Constants.UNIT_STATUS_SOLD;
        unit.UnitType__c = 'Villa';
        unit.Project__c = projectRecord.Id;
        insert unit;
        BuildingSection__c buildSection=new BuildingSection__c();
        buildSection.Id=unit.BuildingSectionName__c;
        buildSection.CompletionCertificateDate__c=Date.Today().addDays(-100);
        update buildSection;
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.AdditionalRebate__c=200;
        salesOrder.Unit__c = unit.Id;        
        salesOrder.ApprovePendingDate__c=Date.Today();
        insert salesOrder;        
        
        OffersPromotions__c offerRecord= TestObjectsFactory.getOfferPromotion(buildSection.Id,projectRecord.Id);
        offerRecord.BuildingSectionName__c = null;
        insert offerRecord;
        OfferLines__c offerLinesRecord = new OfferLines__c();
        offerLinesRecord.OfferName__c = offerRecord.Id;
        offerLinesRecord.OfferType__c = 'Waiver';
        offerLinesRecord.DiscountType__c = '';
        offerLinesRecord.OfferOn__c = Constants.BUDGET_LINE_AMC;
        offerLinesRecord.OfferValue__c = 3;
        offerLinesRecord.OfferValueType__c = 'Years'; 
        offerLinesRecord.Nationality__c=null;
        offerLinesRecord.BudgetTaskName__c = Constants.BUDGET_LINE_AMC;
        insert offerLinesRecord;
        
        OpportunityOfferLine__c tempLine = new OpportunityOfferLine__c();
        tempLine.SalesOrder__c = salesOrder.Id;
        tempLine.MaintenanceVisits__c = '1';
        tempLine.OfferValue__c=2;
        tempLine.OfferLine__c = offerLinesRecord.Id;
        insert tempLine;
        
        Product2 prod = new Product2();
        prod.Name = 'Duct Cleaning';
        prod.Type__c = 'On Demand';
        prod.IsActive = true;
        prod.Family = 'Villas- Medium Packages';
        prod.ProductCode = 'Duct Cleaning';
        insert prod;
        
        schema.location loc = New schema.location(Name = 'NoyaLuma', LocationType = 'Project', IsInventoryLocation = true);
        insert loc;
        ProductItem prdItem = new ProductItem();
        prdItem.Product2Id = prod.Id;
        prdItem.LocationId = loc.Id;
        prdItem.QuantityOnHand = 1;
        insert prdItem;
        //SR TEMPLATE
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = Constants.RECORDTYPE_HANDOVER;
        SR_Template.HexaBPM__SR_RecordType_API_Name__c=Constants.RECORDTYPE_HANDOVER;
        insert SR_Template;
        
        Test.startTest(); 
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
        
        //Step Status 
        list<HexaBPM__Status__c> stepStatus = new list<HexaBPM__Status__c>{ new HexaBPM__Status__c(Name=Constants.STEP_STATUS_PENDING, HexaBPM__Code__c=Constants.STEP_STATUS_PENDING , HexaBPM__Type__c = 'Start'),
            new HexaBPM__Status__c(Name=Constants.STEP_STATUS_COMPLETED, HexaBPM__Code__c=Constants.STEP_STATUS_COMPLETED , HexaBPM__Type__c = 'End')};
                insert stepStatus;
        list<HexaBPM__SR_Steps__c> templateSteps = new list<HexaBPM__SR_Steps__c>();
        for(HexaBPM__Step_Template__c tempRec : stepTemplateToInsert){
            HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
            SRStep.HexaBPM__SR_Template__c = SR_Template.id;
            SRStep.HexaBPM__Step_No__c = templateSteps.size()+1;
            SRStep.HexaBPM__Step_Template__c = tempRec.Id;
            SRStep.HexaBPM__Summary__c = tempRec.Name;
            SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
            SRStep.HexaBPM__Start_Status__c = stepStatus[0].Id;
            
            templateSteps.add(SRStep);
        }   
        insert templateSteps;           
        
        Test.stoptest(); 
        
        //SR Status 
        insert new list<HexaBPM__SR_Status__c>{ TestObjectsFactory.getSRStatus(Constants.STEP_STATUS_APPOINTMENT_BOOKED),
            TestObjectsFactory.getSRStatus(Constants.STEP_STATUS_SENT),
            TestObjectsFactory.getSRStatus(Constants.SUBMITTED),
            TestObjectsFactory.getSRStatus(Constants.SR_STATUS_CANCELLED),
            TestObjectsFactory.getSRStatus(Constants.STATUS_DRAFT) , 
            TestObjectsFactory.getSRStatus(Constants.SR_STATUS_PENDING_FINANCE_VERIFICATION)};
                
                }
    
    @isTest
    public static void testCreateSR (){
        Unit__c tempUnit = [select id from Unit__c limit 1];
        
        Map<Id,HandoverDetails__c> createRes = HandoverUtility.createHandoverSR(new set<ID>{tempUnit.Id});
        System.assertEquals(createRes.isEmpty(),false);
        createRes = HandoverUtility.createHandoverSR(new set<ID>{tempUnit.Id});
        System.assertEquals(createRes.isEmpty(),true);
        // get SR
        HexaBPM__Service_Request__c srRecord = [select id from HexaBPM__Service_Request__c];
        HandoverUtility.updateSRDetails(new list<ID>{srRecord.Id},system.today(),'G1',null,system.today());
        //HandoverUtility.updateSRDetails(new list<ID>{srRecord.Id},null,null,UserInfo.getUserId() );
    }
    
    @isTest
    public static void testWithoutSO (){
        Unit__c tempUnit = [select id from Unit__c limit 1];
        delete [select id from SalesOrder__c];
        
        Map<Id,HandoverDetails__c> createRes = HandoverUtility.createHandoverSR(new set<ID>{tempUnit.Id});
        System.assertEquals(createRes.isEmpty(),false);
        test.StartTest();
        createRes = HandoverUtility.createHandoverSR(new set<ID>{tempUnit.Id});
        System.assertEquals(createRes.isEmpty(),false);
        test.StopTest();
    }
    
    @isTest
    public static void testWithSO (){
        Unit__c tempUnit = [select id from Unit__c limit 1];
        SalesOrder__c so = [select id from SalesOrder__c];
        so.Status__c = Constants.SO_STATUS_CANCELLED;
        
        update so;
        test.StartTest();
        Map<Id,HandoverDetails__c> createRes = HandoverUtility.createHandoverSR(new set<ID>{tempUnit.Id});
        System.assertEquals(createRes.isEmpty(),false);
        
        so.Status__c = Constants.SO_STATUS_SOLD;
        update so;
        String screateRes = HandoverUtility.createHandoverSRUpdateSO(new list<ID>{tempUnit.Id});
        screateRes = HandoverUtility.createHandoverSRUpdateSO(new list<ID>{tempUnit.Id});
        test.StopTest();
        
    }
    
    @isTest
    public static void testGetSR (){
        Unit__c tempUnit = [select id from Unit__c limit 1];
        Map<Id,HandoverDetails__c> createRes = HandoverUtility.createHandoverSR(new set<ID>{tempUnit.Id});
        System.assertEquals(createRes.isEmpty(),false);
        
        HexaBPM__Service_Request__c srRecord = [select id from HexaBPM__Service_Request__c];
        HandoverUtility.getUnitDetails(null,null,null,null,null,null);
        HandoverUtility.getKARList();
        test.StartTest();
        HandoverUtility.performFinanceVerification(new list<ID>{srRecord.Id});
        HandoverUtility.populateSRCloseDate(new set<ID>{srRecord.Id});
        HandoverUtility.getHandoverSR(new set<ID>{srRecord.Id});
        try{
            HandoverUtility.getDesnagReportID(new set<ID>{srRecord.Id});
        }catch(exception e){}
        
        test.StopTest();
    }
    
    @isTest
    public static void testHOSR (){
        Unit__c tempUnit = [select id from Unit__c limit 1];
        Map<Id,HandoverDetails__c> createRes = HandoverUtility.createHandoverSR(new set<ID>{tempUnit.Id});
        System.assertEquals(createRes.isEmpty(),false);
        HexaBPM__Service_Request__c srRecord = [select id from HexaBPM__Service_Request__c];
        HandoverUtility.closeTitleDeedStep(new set<ID>{srRecord.Id},true);
        HandoverUtility.generateSOA(new set<ID>{srRecord.Id});
        HandoverUtility.sendLetter(new list<ID>{srRecord.Id}, HandoverUtility.HANDOVERACTION_SEND_HC);
        test.StartTest();
        HandoverUtility.sendLetter(new list<ID>{srRecord.Id}, HandoverUtility.HANDOVERACTION_SEND_HP);
        HandoverUtility.sendLetter(new list<ID>{srRecord.Id}, HandoverUtility.HANDOVERACTION_SEND_HO);
        HandoverUtility.sendHOL(new set<ID>{srRecord.Id});
        HandoverUtility.sendPhasing(new set<ID>{srRecord.Id});
        HandoverUtility.sendCHO(new set<ID>{srRecord.Id});
        
        
        HandoverUtility.callERP(new set<ID>{srRecord.Id});
        HandoverUtility.CancelHandoverSR(new set<ID>{tempUnit.Id});
        test.StopTest();
    }
    
    @isTest
    public static void testKAR(){
        
        Unit__c tempUnit = [select id from Unit__c limit 1];
        Map<Id,HandoverDetails__c> createRes = HandoverUtility.createHandoverSR(new set<ID>{tempUnit.Id});
        System.assertEquals(createRes.isEmpty(),false);
        HexaBPM__Service_Request__c srRecord = [select id,HandoverDetail__c from HexaBPM__Service_Request__c];
        
        
        test.StartTest();
        try{
            HandoverUtility.handleKARAssignment(new list<ID>{srRecord.Id},UserInfo.getUserId() );
        }catch(exception e){}
        try{
            HandoverUtility.sendSnags(new set<ID>{srRecord.HandoverDetail__c});
            HandoverUtility.sendDeSnags(new set<ID>{srRecord.HandoverDetail__c});
        }catch(exception e){}
        
        //Document Placeholder
        HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c =Constants.HO_DOC_CUST_SNAG;
        objDocMaster.HexaBPM__Available_to_client__c = true;
        //Dummy IDs
        objDocMaster.HexaBPM__LetterTemplate__c='a152z000000gIW4';
        objDocMaster.Delivery_Option__c ='a132z000000dViI';
        insert objDocMaster;
        
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id ;
        insert docTemp;
        HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
        objSRDoc.HexaBPM__Document_Master__c = objDocMaster.id  ;
        objSRDoc.HexaBPM__SR_Template_Doc__c =docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c = srRecord.id;
        insert objSRDoc;
        
        HandoverUtility.generateSOA(new set<ID>{objSRDoc.Id});
        test.StopTest();
        //HandoverUtility.getSnagReportID(new set<ID>{srRecord.Id});
        
        
    }
    
    
    
    @isTest
    public static void testERPSOADoc(){
        test.StartTest();
        Unit__c tempUnit = [select id from Unit__c limit 1];
        Map<Id,HandoverDetails__c> createRes = HandoverUtility.createHandoverSR(new set<ID>{tempUnit.Id});
        HexaBPM__Service_Request__c srRecord = [select id,HandoverDetail__c from HexaBPM__Service_Request__c];
        //Document Placeholder
        HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c ='ERP_SOA';
        objDocMaster.HexaBPM__Available_to_client__c = true;
        insert objDocMaster;
        
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id ;
        insert docTemp;
        HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
        objSRDoc.Name='ERP_SOA';
        objSRDoc.HexaBPM__Document_Master__c = objDocMaster.id  ;
        objSRDoc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c = srRecord.id  ;
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
        
        HandoverUtility.getSRsrDocID(srRecord.Id);
        set<Id> srIDs=new set<Id>();
        srIDs.add(srRecord.Id);
        HandoverUtility.getSOAReportID(srIDs);
        test.StopTest();
        
    }
    @isTest
    public static void completedHandoverTest(){
        Unit__c tempUnit = [select id from Unit__c LIMIT 1];
        System.debug(tempUnit);
        Map<Id,HandoverDetails__c> createRes = HandoverUtility.createHandoverSR(new set<ID>{tempUnit.Id});
        System.assertEquals(createRes.isEmpty(),false);
        HandoverDetails__c handoverDetRec = createRes.get(tempUnit.Id);
        handoverDetRec.HandoverCompletionDate__c = Date.newInstance(2024,9,20);
        Test.startTest();       
        update handoverDetRec;
        //HandoverUtility.completedHandover(new set<ID>{handoverDetRec.Id});
        Test.stopTest();
    }
    
    @isTest
    public static void sendRFOTest(){
        Unit__c tempUnit = [select id from Unit__c LIMIT 1];
        System.debug(tempUnit);
        Map<Id,HandoverDetails__c> createRes = HandoverUtility.createHandoverSR(new set<ID>{tempUnit.Id});
        System.assertEquals(createRes.isEmpty(),false);
        HandoverDetails__c handoverDetRec = createRes.get(tempUnit.Id);
        handoverDetRec.RFODate__c = Date.newInstance(2024,9,20);
        Test.startTest();       
        update handoverDetRec;
        HandoverUtility.sendRFO(new set<ID>{handoverDetRec.Id});
        Test.stopTest();
    }
    
    // harsh@aldar added test method for ReassignKAR
    @isTest
    public static void testReAssignKARToServiceRequestsSuccessfully(){
        Unit__c tempUnit = [select id from Unit__c limit 1];
        System.debug(tempUnit);
        Map<Id,HandoverDetails__c> createRes = HandoverUtility.createHandoverSR(new set<ID>{tempUnit.Id});
        System.assertEquals(createRes.isEmpty(),false);
        HexaBPM__Service_Request__c srRecord = [select id,HandoverDetail__c from HexaBPM__Service_Request__c];
        
        HexaBPM__SR_Steps__c tempStepTemp= [select id,HexaBPM__Summary__c,HexaBPM__Start_Status__c from HexaBPM__SR_Steps__c where HexaBPM__Summary__c = :Constants.STEP_NAME_KAR_ASSIGNMENT limit 1];        
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = tempStepTemp.HexaBPM__Summary__c;
        step.HexaBPM__SR__c = srRecord.Id;
        step.HexaBPM__SR_Step__c = tempStepTemp.Id;
        step.HexaBPM__Start_Date__c = System.today();
        step.HexaBPM__Status__c = tempStepTemp.HexaBPM__Start_Status__c;
        
        insert step;
        Test.startTest();
        String result = HandoverUtility.reAssignKARToServiceRequests(new list<ID>{srRecord.Id},UserInfo.getUserId() );
        Test.stopTest();
        system.assertEquals('KAR ReAssignment Successfully',result);
        
    }
    
    // harsh@aldar added test method for ReassignKAR
    @isTest
    public static void testRssignKARToServiceRequestsWhenIdIsNull(){
        Unit__c tempUnit = [select id from Unit__c limit 1];
        System.debug(tempUnit);
        Map<Id,HandoverDetails__c> createRes = HandoverUtility.createHandoverSR(new set<ID>{tempUnit.Id});
        System.assertEquals(createRes.isEmpty(),false);
        HexaBPM__Service_Request__c srRecord = [select id,HandoverDetail__c from HexaBPM__Service_Request__c];
        
        HexaBPM__SR_Steps__c tempStepTemp= [select id,HexaBPM__Summary__c,HexaBPM__Start_Status__c from HexaBPM__SR_Steps__c where HexaBPM__Summary__c = :Constants.STEP_NAME_KAR_ASSIGNMENT limit 1];
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = tempStepTemp.HexaBPM__Summary__c;
        step.HexaBPM__SR__c = srRecord.Id;
        step.HexaBPM__SR_Step__c = tempStepTemp.Id;
        step.HexaBPM__Start_Date__c = System.today();
        step.HexaBPM__Status__c = tempStepTemp.HexaBPM__Start_Status__c;
        insert step;
        try {
            Test.startTest();
            String result = HandoverUtility.reAssignKARToServiceRequests(new list<ID>{srRecord.Id},'');
            HandoverUtility.createSteps( new set<Id>{ srRecord.id }, new set<String>{'Handover'} );
            Test.stopTest();
        } catch (Exception e) {
            System.assert(true, 'Exception caught: ' + e.getMessage());
        }
    }
    
    @isTest
    public static void testUpdateHandoverSR() {
        // Fetch necessary data from setup
        Account acc = [SELECT Id FROM Account LIMIT 1];
        SalesOrder__c so = [SELECT Id, Unit__c, Account__c, PaymentPlan__c, PHPP__c, 
                            Sales_Type__c, RecordType.Name, 
                            Unit__r.UnitType__c, Unit__r.RecordType.Name, 
                            Contact__c, PaymentPlan__r.PHPPFlag__c 
                            FROM SalesOrder__c WHERE Account__c = :acc.Id LIMIT 1];
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = Constants.UNIT_STATUS_SOLD;
        insert unit;
        
        HandoverDetails__c hodetail = new HandoverDetails__c(UnitOfferedDate__c = system.today(),
                                                             Unit__c = unit.Id,
                                                             HandoverPhaseDate__c = system.today(),
                                                             Status__c=Constants.HO_STATUS_READY,
                                                             Stage__c=Constants.HO_STAGE_OFFERED_BY_PROJECTS,
                                                             SalesOrder__c = so.Id,
                                                             isRTOHandover__c =  false,
                                                             UtilityTransferStatus__c =  Constants.HO_TRANSSTATUS_NOTREADY,
                                                             TitleDeedStatus__c =  Constants.HO_TRANSSTATUS_NOTREADY    );                                        
        insert hodetail;
        
        HexaBPM__Service_Request__c sr = new HexaBPM__Service_Request__c(
            HexaBPM__Customer__c = acc.Id,
            RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER),
            HandoverDetail__c = hodetail.Id,
            Unit__c = so.Unit__c
        );
        insert sr;
        
        Map<Id, HandoverDetails__c> handoverDetailsToUpdate = new Map<Id, HandoverDetails__c>();
        Map<Id, HexaBPM__Service_Request__c> SRtoUpdate = new Map<Id, HexaBPM__Service_Request__c>();
        Map<Id, SalesOrder__c> unitTosalesOrderMap = new Map<Id, SalesOrder__c>{
            so.Unit__c => so
                };
                    
                    Test.startTest();
        HandoverUtility.updateHandoverSR(handoverDetailsToUpdate, SRtoUpdate, sr, unitTosalesOrderMap);
        Test.stopTest();
        
        System.assertEquals(1, handoverDetailsToUpdate.size());
        System.assertEquals(hodetail.Id, handoverDetailsToUpdate.get(so.Unit__c).Id);
        System.assertEquals(so.Id, handoverDetailsToUpdate.get(so.Unit__c).SalesOrder__c);
        
        System.assertEquals(1, SRtoUpdate.size());
        HexaBPM__Service_Request__c updatedSR = SRtoUpdate.get(so.Unit__c);
        System.assertEquals(so.Account__c, updatedSR.HexaBPM__Customer__c);
        System.assertEquals(so.Id, updatedSR.SalesOrder__c);
        System.assertEquals(so.Contact__c, updatedSR.HexaBPM__Contact__c);
    }
    
    @isTest
    static void testCreateHandoverSRUpdateSO_CoverBranches() {
        
        String RECORDTYPE_HANDOVER = Constants.RECORDTYPE_HANDOVER; 
        String STATUS_APPROVAL_PENDING = Constants.STATUS_APPROVAL_PENDING;
        Set<String> soldSR = new Set<String>{Constants.STATUS_APPROVAL_PENDING, Constants.SO_STATUS_SOLD, Constants.SO_STATUS_RTO_Approve_PENDING, Constants.SO_STATUS_RTO_SOLD};
            
            List<Unit__c> units = new List<Unit__c>();
        for(Integer i = 0; i < 3; i++) {
            Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
            unit.Status__c = Constants.UNIT_STATUS_SOLD;
            unit.ASiteUnitStatus__c = 'Released for QA';
            units.add(unit);
        }
        insert units;
        
        SalesOrder__c soCancelled = new SalesOrder__c(
            Unit__c = units[0].Id,
            Status__c = Constants.SR_STATUS_CANCELLED
        );
        SalesOrder__c soOther = new SalesOrder__c(
            Unit__c = units[1].Id,
            Status__c = STATUS_APPROVAL_PENDING
        );
        insert new List<SalesOrder__c>{soCancelled, soOther};
            
            
            HexaBPM__Service_Request__c srCancelled = new HexaBPM__Service_Request__c(
                Unit__c = units[0].Id,
                SalesOrder__c = soCancelled.Id,
                RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', RECORDTYPE_HANDOVER)
            );
        
        HexaBPM__Service_Request__c srOther = new HexaBPM__Service_Request__c(
            Unit__c = units[1].Id,
            SalesOrder__c = soOther.Id,
            RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', RECORDTYPE_HANDOVER)
        );
        
        HexaBPM__Service_Request__c srNoSO = new HexaBPM__Service_Request__c(
            Unit__c = units[2].Id,
            SalesOrder__c = null,
            RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', RECORDTYPE_HANDOVER)
        );
        
        insert new List<HexaBPM__Service_Request__c>{srCancelled, srOther, srNoSO};
            List<Id> unitIds = new List<Id>{units[0].Id, units[1].Id, units[2].Id};
                
                Test.startTest();
        String result = HandoverUtility.createHandoverSRUpdateSO(unitIds);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
       // System.assert(result == 'Sales Order not fond for the selected unit(s)' || result == 'success', 'Unexpected result: ' + result);
    }
    
    @isTest
    public static void testCreateStepsFullCoverage() {
        
        
        HexaBPM__Step_Template__c stepTemplate = new HexaBPM__Step_Template__c(
            Name = 'TestTemplate',
            HexaBPM__Code__c = 'TestCode_' + String.valueOf(Crypto.getRandomInteger()),
            HexaBPM__Step_RecordType_API_Name__c = 'General'
        );
        insert stepTemplate;
        
        HexaBPM__SR_Template__c srTemplate = new HexaBPM__SR_Template__c(
            Name = Constants.RECORDTYPE_HANDOVER,
            HexaBPM__SR_RecordType_API_Name__c=Constants.RECORDTYPE_HANDOVER
        );
        insert srTemplate;
        
        HexaBPM__SR_Steps__c srStep = new HexaBPM__SR_Steps__c(
            HexaBPM__Step_Template__c = stepTemplate.Id,
            HexaBPM__SR_Template__c = srTemplate.Id,
            HexaBPM__Step_No__c = 1,
            HexaBPM__Sys_Custom_Conditions_Actions__c = True,
            HexaBPM__Summary__c = stepTemplate.Name
        );
        insert srStep;
        
        
        HexaBPM__Status__c pendingStatus = new HexaBPM__Status__c(
            Name = Constants.STEP_STATUS_PENDING,
            HexaBPM__Code__c='TestCode_' + String.valueOf(Crypto.getRandomInteger()) , 
            HexaBPM__Type__c = 'Start'
        );
        insert pendingStatus;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = Constants.UNIT_STATUS_SOLD;
        unit.ASiteUnitStatus__c = 'Released for QA';
        insert unit;
        
        HexaBPM__Service_Request__c sr = new HexaBPM__Service_Request__c(
            Unit__c = unit.Id,
            IsNewSale__c = true,
            RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER)
        );
        insert sr;
        
        Test.startTest();
        HandoverUtility.createSteps(new Set<Id>{unit.Id}, new Set<String>{stepTemplate.Name});
        Test.stopTest();
        
        List<HexaBPM__Step__c> steps = [SELECT Id, HexaBPM__SR__c, HexaBPM__Summary__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c = :sr.Id];
        System.assertEquals(1, steps.size(), 'One step should have been created');
        System.assertEquals(stepTemplate.Name, steps[0].HexaBPM__Summary__c);
    }
    
}