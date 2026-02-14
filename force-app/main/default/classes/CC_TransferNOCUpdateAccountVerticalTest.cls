@isTest
private class CC_TransferNOCUpdateAccountVerticalTest {
    
    //Create setupData
    
    
    @isTest
    public static void callMethod (){ 
        
         Id personAccountRecordTypeId=utilities.getRecordTypeId('Account','Person Account');
        
        Id handoverRecordType = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Account nonExistingAcc = new Account();
        nonExistingAcc.FirstName='Test';
        nonExistingAcc.LastName= 'Drogo';
        nonExistingAcc.PersonEmail='drogo@gmail.com';
        nonExistingAcc.RecordTypeId = personAccountRecordTypeId;
        acc.CustomerAppWebUser__c=false;
        insert nonExistingAcc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = Constants.UNIT_STATUS_SOLD;
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
         Test.startTest();
        insert salesOrder;
         
        
        //SR TEMPLATE
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = Constants.RECORDTYPE_HANDOVER;
        SR_Template.HexaBPM__SR_RecordType_API_Name__c=Constants.RECORDTYPE_HANDOVER;
        insert SR_Template;
        
        
        // STEP AND STEP TEMPLATE
        list<HexaBPM__Step_Template__c> stepTemplateToInsert = new list<HexaBPM__Step_Template__c>();
        list<String> templatesCode = new list<String>{Constants.STEP_NAME_HOPRECHECK
            };            
          /*  Constants.STEP_NAME_FINANCE_VERIFICATION,
            Constants.STEP_NAME_KAR_ASSIGNMENT,
            Constants.STEP_NAME_UTILITY_TRANSFER,
            Constants.STEP_NAME_KEYHANDOVER_APPOINTMENT,
            Constants.STEP_NAME_SNAGGING_APPOINTMENT,
            Constants.STEP_NAME_HANDOVER_PHASING,
            Constants.STEP_NAME_TITLE_DEED}; */
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
                
                //SR AND STEP
                HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = handoverRecordType;
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        //SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
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
        
        JointOwner__c jointOwner1 = new JointOwner__c();
        jointOwner1.Account__c = acc.Id;
        jointOwner1.SharePercentage__c = 10;
        jointOwner1.SalesOrder__c = salesOrder.Id;
        insert jointOwner1;
        
        JointOwner__c jointOwner2 = new JointOwner__c();
        jointOwner2.Account__c = nonExistingAcc.Id;
        jointOwner2.SharePercentage__c = 10;
        jointOwner2.SalesOrder__c = salesOrder.Id;
        insert jointOwner2;
        
          insert new AgencyTeam__c(Name='test',ServiceRequest__c=SR.id,Type__c =Constants.AGENCY_ADMIN, MobileNumber__c='971 12345', Account__c=acc.Id );
        HexaBPM__Service_Request__c SeR = [Select Id, SalesOrder__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c, Step_Template_Code__c From HexaBPM__Step__c where Step_Template_Code__c= :Constants.STEP_NAME_HOPRECHECK limit 1];
        CC_TransferNOCUpdateAccountVertical cc = new CC_TransferNOCUpdateAccountVertical();
       
		
        cc.EvaluateCustomCode(SeR, stp);
        cc.EvaluateCustomCode(new HexaBPM__Service_Request__c(), new HexaBPM__Step__c(HexaBPM__SR__c=SR.Id));
        cc.EvaluateCustomCode(null, null);
        
        Test.stopTest();
        /*List<Account> updatedAccounts = [SELECT Id, CustomerVertical__c FROM Account WHERE PersonEmail = 'org@gmail.com'];
        for(Account acc : updatedAccounts){
            System.assert(acc.CustomerVertical__c != null && acc.CustomerVertical__c.contains('Aldar Estates'), 'Expected Aldar Estates in CustomerVertical__c for account:'+acc.Id);
        }*/
    }
    
    
}