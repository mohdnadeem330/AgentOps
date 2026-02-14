@isTest
public class CloseDigitalPaymentStepQueueableTest {
    @isTest
    static void callQueueable(){
        
        Id personAccountRecordTypeId=utilities.getRecordTypeId('Account','Person Account');
        Account acc = new Account();
        acc.FirstName='Test';
        acc.LastName= 'Agni';
        acc.PersonEmail='agni@gmail.com';
        acc.RecordTypeId = personAccountRecordTypeId;
        acc.CustomerAppWebUser__c=false;
        insert acc;
        
        HexaBPM__SR_Status__c submittedStatus = new HexaBPM__SR_Status__c();
        submittedStatus=TestObjectsFactory.getSRStatus('Submitted');
        insert submittedStatus;
        
        HexaBPM__SR_Status__c cancelledStatus = new HexaBPM__SR_Status__c();
        cancelledStatus=TestObjectsFactory.getSRStatus('Cancelled');
        insert cancelledStatus;
        
        Project__c project=TestObjectsFactory.getProjectRecord('recordId');
        insert project;
        
        list<Unit__c> units = new list<unit__c>();
        unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        unit.Name = 'MAYAN-B1-1004'; 
        unit.Project__c= project.Id;
        insert unit;
        
        Id PropertyTransferNOCRTId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Property Transfer NOC');
        
        HexaBPM__SR_Template__c PTNSRTemplate = new HexaBPM__SR_Template__c();
        PTNSRTemplate.HexaBPM__Active__c = true;
        PTNSRTemplate.HexaBPM__SR_RecordType_API_Name__c = 'Property Transfer NOC';
        PTNSRTemplate.Name='Property Transfer NOC';
        insert PTNSRTemplate;
        
        HexaBPM__Service_Request__c srExists=TestObjectsFactory.getServiceRequest(submittedStatus.Id,unit.Id,'Property Transfer NOC',PropertyTransferNOCRTId,PTNSRTemplate.Id);
        srExists.TransferSellingPrice__c=19500.01;
        srExists.HexaBPM__Customer__c=acc.Id;
        srExists.IsChargeReceiptCreated__c = true;
        insert srExists;
        
        HexaBPM__Status__c completedStatus = new HexaBPM__Status__c();
        completedStatus.Name = 'Completed';
        completedStatus.HexaBPM__Code__c = 'Completed';
        Insert completedStatus;
        HexaBPM__Status__c PendingStatus = new HexaBPM__Status__c();
        PendingStatus.Name = 'Pending';
        PendingStatus.HexaBPM__Code__c = 'Pending';
        Insert PendingStatus;
        
        List<HexaBPM__Service_Request__c> NOCSRToUpdateStepList = new List<HexaBPM__Service_Request__c>();
        
        NOCSRToUpdateStepList.add(srExists);
         
        // STEP AND STEP TEMPLATE
        list<HexaBPM__Step_Template__c> stepTemplateToInsert = new list<HexaBPM__Step_Template__c>();
        list<String> templatesCode = new list<String>{'Verify the Customer Documents','Digital Step Pending'};
        for(String tempS : templatesCode){
            HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
            ST.Name = tempS;
            ST.HexaBPM__Code__c = tempS;
            ST.HexaBPM__Summary__c =tempS;
            ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
            stepTemplateToInsert.add(ST);
        }
        insert stepTemplateToInsert;
        
        //Step Status 
        list<HexaBPM__Status__c> stepStatus = new list<HexaBPM__Status__c>{ new HexaBPM__Status__c(Name=Constants.STEP_STATUS_PENDING, HexaBPM__Code__c=Constants.STEP_STATUS_PENDING , HexaBPM__Type__c = 'Start'),
                                                                        new HexaBPM__Status__c(Name=Constants.STEP_STATUS_COMPLETED, HexaBPM__Code__c=Constants.STEP_STATUS_COMPLETED , HexaBPM__Type__c = 'End')};
        //insert stepStatus;
        list<HexaBPM__SR_Steps__c> templateSteps = new list<HexaBPM__SR_Steps__c>();
        for(HexaBPM__Step_Template__c tempRec : stepTemplateToInsert){
            HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
            SRStep.HexaBPM__SR_Template__c = PTNSRTemplate.id;
            SRStep.HexaBPM__Step_No__c = templateSteps.size()+1;
            SRStep.HexaBPM__Step_Template__c = tempRec.Id;
            SRStep.HexaBPM__Summary__c = tempRec.Name;
            SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
            SRStep.HexaBPM__Start_Status__c = stepStatus[0].Id;
            
            templateSteps.add(SRStep);
        }   
        insert templateSteps;  
        List<HexaBPM__Step__c>stepList = new List<HexaBPM__Step__c>();
        for(HexaBPM__SR_Steps__c tempStep : templateSteps){
                            HexaBPM__Step__c tempRec = new 
                                HexaBPM__Step__c( ExecuteCustomCode__c =
                                                 tempStep.HexaBPM__Sys_Custom_Conditions_Actions__c,
                                                 HexaBPM__SR_Step__c = tempStep.Id,
                                                 OwnerId = UserInfo.getUserId(),
                                                 HexaBPM__SR__c = srExists.Id,
                                                 HexaBPM__Start_Date__c = System.today(),
                                                 HexaBPM__Step_No__c = tempStep.HexaBPM__Step_No__c,
                                                 HexaBPM__Status__c =  PendingStatus.Id,
                                                 HexaBPM__Step_Template__c =  tempStep.HexaBPM__Step_Template__c,
                                                 HexaBPM__Summary__c = tempStep.HexaBPM__Summary__c,
                                                 HexaBPM__Sys_Step_Loop_No__c = tempStep.HexaBPM__Step_No__c +'_1' );
                            stepList.add(tempRec);   
                        
                    }
        if(!stepList.isEmpty()){
        	insert stepList;
        }
        //SR DOCS
        HexaBPM__Document_Master__c ownerAssoDocMaster = new HexaBPM__Document_Master__c();
        ownerAssoDocMaster.HexaBPM__Code__c = 'Signed Owner Association Letter';
        ownerAssoDocMaster.HexaBPM__Available_to_client__c = true;
        ownerAssoDocMaster.AvailableForCustomer__c=true;
        insert ownerAssoDocMaster;
		
		HexaBPM__SR_Doc__c ownerAssoSRDoc = new HexaBPM__SR_Doc__c();
        ownerAssoSRDoc.HexaBPM__Document_Master__c = ownerAssoDocMaster.id  ;
        //ownerAssoSRDoc.HexaBPM__SR_Template_Doc__c = ownerAssoSRTemplate.id;
        ownerAssoSRDoc.HexaBPM__Service_Request__c = srExists.id  ;
        ownerAssoSRDoc.HexaBPM__Status__c = 'Uploaded';
        ownerAssoSRDoc.Name='Signed Owner Association Letter' ;
        insert ownerAssoSRDoc;
        
        HexaBPM__Document_Master__c signedDOADocMaster = new HexaBPM__Document_Master__c();
        signedDOADocMaster.HexaBPM__Code__c = 'Signed Document of Adherence';
        signedDOADocMaster.HexaBPM__Available_to_client__c = true;
        signedDOADocMaster.AvailableForCustomer__c=true;
        insert signedDOADocMaster;
		
		HexaBPM__SR_Doc__c signedDOASRDoc = new HexaBPM__SR_Doc__c();
        signedDOASRDoc.HexaBPM__Document_Master__c = signedDOADocMaster.id  ;
        //ownerAssoSRDoc.HexaBPM__SR_Template_Doc__c = ownerAssoSRTemplate.id;
        signedDOASRDoc.HexaBPM__Service_Request__c = srExists.id  ;
        signedDOASRDoc.HexaBPM__Status__c = 'Uploaded';
         signedDOASRDoc.Name='Signed Document of Adherence' ;
        insert signedDOASRDoc;
		
		
		system.debug('ownerAssoSRDoc::'+ ownerAssoSRDoc);
        system.debug('signedDOASRDoc::'+ signedDOASRDoc);
        Test.startTest();
        System.enqueueJob(new CloseDigitalPaymentStepQueueable(NOCSRToUpdateStepList));
        Test.stopTest();
        
        
    }
    
    
}