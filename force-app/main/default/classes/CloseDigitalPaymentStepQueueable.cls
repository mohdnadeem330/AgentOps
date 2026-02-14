public with sharing class CloseDigitalPaymentStepQueueable implements Queueable, Database.AllowsCallouts {
    
    public List<HexaBPM__Service_Request__c> srToUpdateStepList = new List<HexaBPM__Service_Request__c>();
    public CloseDigitalPaymentStepQueueable( List<HexaBPM__Service_Request__c> NOCSRToUpdateStepList) {
        this.srToUpdateStepList = NOCSRToUpdateStepList;
    }
    public void execute(QueueableContext context) {
        if (!srToUpdateStepList.isEmpty()) {
            List<Id> srIdList = new List<Id>();
            List<HexaBPM__Step__c> srStepsToUpdateList = new List<HexaBPM__Step__c>();
            for(HexaBPM__Service_Request__c sr: srToUpdateStepList){
                if(sr.IsChargeReceiptCreated__c == true){
                    srIdList.add(sr.Id);
                }
                
            }
            String srIdStr = String.join(srIdList, '\',\'');
            String whrClause = 'HexaBPM__Service_Request__c IN (\'' + srIdStr + '\') AND (Name=\'Signed Owner Association Letter\' OR Name=\'Signed Document of Adherence\' OR Name=\'Signed Assignment of Service Charge\') AND HexaBPM__Status__c=\'Uploaded\'';
            List<HexaBPM__SR_Doc__c> srDocList = CustomerServiceUtility.getSRDocDetail(whrClause);
            
            Boolean hasSignedOwnerAssocLetter = false;
            Boolean hasSignedDocumentAdherence = false;
            
            
            for (HexaBPM__SR_Doc__c doc : srDocList) {
                if (doc.Name == 'Signed Owner Association Letter') {  hasSignedOwnerAssocLetter = true;}
                if (doc.Name == 'Signed Document of Adherence') { hasSignedDocumentAdherence = true;}
                
            }
            map<string, HexaBPM__Status__c> stepStatusMap = new map<string, HexaBPM__Status__c>();
            for (HexaBPM__Status__c srStepStatus : [SELECT Id, Name FROM HexaBPM__Status__c WHERE Name IN ('Completed','Pending')]) {
                stepStatusMap.put(srStepStatus.Name, srStepStatus);
            }
            System.debug('srIdList'+srIdList);
            List<HexaBPM__Step__c> srStepsToProcess = [SELECT Id, HexaBPM__Status__c, HexaBPM__SR__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c IN :srIdList AND HexaBPM__Summary__c IN ('Digital Step Pending') AND HexaBPM__Step_Status__c = 'Pending'];
            for (HexaBPM__Step__c srStep : srStepsToProcess) {
                if (stepStatusMap.containsKey('Completed') && hasSignedOwnerAssocLetter && hasSignedDocumentAdherence) {
                    srStep.HexaBPM__Status__c = stepStatusMap.get('Completed').Id;
                    srStepsToUpdateList.add(srStep); }
            }
            if(!srStepsToUpdateList.IsEmpty()){
                update srStepsToUpdateList;
                
                List<HexaBPM__Step__c> stepList = new List<HexaBPM__Step__c>();
                set<String> templateNames =new set<String>();
                templateNames.add('Verify the Customer Documents'); 
                
                map<string,HexaBPM__SR_Steps__c> stepTemplateMap =new map<string,HexaBPM__SR_Steps__c>();
                for(HexaBPM__SR_Steps__c tempStepCode : [select id,OwnerId,Name,HexaBPM__Sys_Custom_Conditions_Actions__c,HexaBPM__Estimated_Hours__c,HexaBPM__Step_No__c,HexaBPM__Step_Template__c,HexaBPM__Step_Template__r.Name
                                                         from HexaBPM__SR_Steps__c where HexaBPM__SR_Template__r.Name ='Property Transfer NOC' and HexaBPM__Step_Template__r.Name IN :templateNames]){
                                                             stepTemplateMap.put(tempStepCode.HexaBPM__Step_Template__r.Name,tempStepCode);
                                                         }
                
                list<HexaBPM__Step__c> stepsToInsert = new list<HexaBPM__Step__c>();
                for(Id srId:srIdList){
                    for(String tpStepname : templateNames){
                        if(stepTemplateMap.containsKey(tpStepname)){
                            HexaBPM__SR_Steps__c tempStep = stepTemplateMap.get(tpStepname);
                            HexaBPM__Step__c tempRec = new 
                                HexaBPM__Step__c( ExecuteCustomCode__c =
                                                 tempStep.HexaBPM__Sys_Custom_Conditions_Actions__c,
                                                 HexaBPM__SR_Step__c = tempStep.Id,
                                                 OwnerId = tempStep.OwnerId,
                                                 HexaBPM__SR__c = srId,
                                                 HexaBPM__Start_Date__c = System.today(),
                                                 HexaBPM__Step_No__c = tempStep.HexaBPM__Step_No__c,
                                                 HexaBPM__Status__c =  stepStatusMap.get('Pending').Id,
                                                 HexaBPM__Step_Template__c =  tempStep.HexaBPM__Step_Template__c,
                                                 HexaBPM__Summary__c = tempStep.HexaBPM__Step_Template__r.Name,
                                                 HexaBPM__Sys_Step_Loop_No__c = tempStep.HexaBPM__Step_No__c +'_1' );
                            stepList.add(tempRec);   
                        }
                    }
                    
                }
                if(!stepList.isEmpty()){
                    insert stepList;
                }
            }
        }
    }
}