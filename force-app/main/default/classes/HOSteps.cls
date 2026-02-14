global class HOSteps implements Database.Batchable<sObject>{
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query='select id,HexaBPM__Customer__c,Unit__r.recordType.Name, HandoverDetail__r.HandoverCompletionDate__c,HandoverDetail__r.UtilityTransferDate__c ,HandoverDetail__r.LastInstallment__c,HandoverDetail__c,HandoverDetail__r.QASnaggingDate__c,HandoverDetail__r.QADesnaggingDate__c,HandoverDetail__r.KAR__c,HandoverDetail__r.CHODate__c,HandoverDetail__r.CustomerSnaggingAppointment__c,HandoverDetail__r.CustomerSnaggingDate__c,HandoverDetail__r.CustomerDesnaggingDate__c,HandoverDetail__r.TitleDeedIssuanceDate__c,HandoverDetail__r.KeyAcceptanceDate__c from  HexaBPM__Service_Request__c  where HandoverDetail__c!=null and HexaBPM__External_Status_Name__c = \'Submitted\' and HexaBPM__External_Status_Name__c !=\'Closed\' and '+System.label.HOSTepsQuery ;
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<HexaBPM__Service_Request__c> scope){
        map<id,HexaBPM__Service_Request__c> srMap = new map<id,HexaBPM__Service_Request__c>(scope);
        
        //Delete existing placeholder 
        delete [select id from HexaBPM__SR_Doc__c  where HexaBPM__Service_Request__c in :srMap.KeySet()];
        
        //Create all polaceholders **********
        list<HexaBPM__SR_Template_Docs__c> docTemplateList =[select id,Name, HexaBPM__Document_Master_Code__c,HexaBPM__Document_Master__c from HexaBPM__SR_Template_Docs__c where HexaBPM__SR_Template__r.Name ='Handover']; 
        list<HexaBPM__SR_Doc__c> docsToInsert = new list<HexaBPM__SR_Doc__c>();
        for(HexaBPM__Service_Request__c tempSR : scope ){
            for(HexaBPM__SR_Template_Docs__c tempDoc : docTemplateList){
                HexaBPM__SR_Doc__c tempRec = new HexaBPM__SR_Doc__c(HexaBPM__Customer__c = tempSR.HexaBPM__Customer__c,
                                                                    HexaBPM__Document_Description_External__c = tempDoc.name,
                                                                    HexaBPM__Document_Master__c = tempDoc.HexaBPM__Document_Master__c,
                                                                    HexaBPM__Service_Request__c =tempSR.Id ,
                                                                    HexaBPM__SR_Template_Doc__c = tempDoc.Id,
                                                                    Name = tempDoc.HexaBPM__Document_Master_Code__c );

                docsToInsert.add(tempRec);
            }
        }
        if(!docsToInsert.isEmpty()){ insert docsToInsert;
        }
        //Delete exsiting steps
        delete [select id from HexaBPM__Step__c  where HexaBPM__SR__c in :srMap.KeySet()];

        // Create new steps
        // pending Status
        HexaBPM__Status__c pendingStatus = [select id,name from HexaBPM__Status__c where name = 'Pending' limit 1];
        HexaBPM__SR_Status__c pendingFinanceVerification= [select id,name from HexaBPM__SR_Status__c where name = :Constants.SR_STATUS_PENDING_FINANCE_VERIFICATION limit 1];
        HexaBPM__SR_Status__c financeVerification= [select id,name from HexaBPM__SR_Status__c where name = :Constants.SR_STATUS_FINANCE_VERIFICATION_COMPLETED limit 1];

        map<string,HexaBPM__SR_Steps__c> stepTemplateMap = new map<string,HexaBPM__SR_Steps__c>();
        for(HexaBPM__SR_Steps__c tempStepCode : [select id,OwnerId,Name,HexaBPM__Sys_Custom_Conditions_Actions__c,HexaBPM__Estimated_Hours__c,HexaBPM__Step_No__c,HexaBPM__Step_Template__c,HexaBPM__Step_Template__r.Name from HexaBPM__SR_Steps__c where HexaBPM__SR_Template__r.Name ='Handover']){
            stepTemplateMap.put(tempStepCode.HexaBPM__Step_Template__r.Name,tempStepCode);
        }
        
        //Conditinal Update
        list<HexaBPM__Step__c> stepsToInsert = new list<HexaBPM__Step__c>();
        list<HexaBPM__Service_Request__c> srToUpdate = new list<HexaBPM__Service_Request__c>();
        list<HandoverDetails__c> hoDetailsToUpdate = new list<HandoverDetails__c>();

        set<String> templateNames = new set<String>();
        for(HexaBPM__Service_Request__c tempSR : scope ){
                HandoverDetails__c tempHORecordToUpdate = new HandoverDetails__c(id =tempSR.HandoverDetail__c,Stage__c = 'Offered By Projects',Status__c='' );
                HexaBPM__Service_Request__c tempSRRecordToUpdate = new HexaBPM__Service_Request__c(id =tempSR.id, isPlot__c = tempSR.Unit__r.recordType.Name == Constants.UNIT_RECORD_TYPE_PLOT );
                //Creating Steps *********
                if(tempSR.HandoverDetail__r.QASnaggingDate__c == null && !tempSRRecordToUpdate.isPlot__c){
                    //QA SNagging
                    templateNames.add('QA Snagging');
                }
                if(!tempSRRecordToUpdate.isPlot__c && (tempSR.HandoverDetail__r.QASnaggingDate__c == null || tempSR.HandoverDetail__r.QADesnaggingDate__c == null) ){
                    //QA Desnagging
                    templateNames.add('QA Desnagging');
                }
                if(tempSR.HandoverDetail__r.KAR__c == null && tempSR.HandoverDetail__r.LastInstallment__c ==null){
                    //KAR
                    templateNames.add('KAR Assignment / Billing');
                }else if(tempSR.HandoverDetail__r.CHODate__c == null){ templateNames.add('Finance Verification');
                }else if(!tempSRRecordToUpdate.isPlot__c && tempSR.HandoverDetail__r.CustomerSnaggingAppointment__c == null && tempSR.HandoverDetail__r.CustomerSnaggingDate__c==null && tempSR.HandoverDetail__r.CustomerDesnaggingDate__c ==null){
                    //Snagging appointment
                    templateNames.add('Customer Home Orientation Appointment');
                }else if(tempSR.HandoverDetail__r.CustomerSnaggingDate__c == null && tempSR.HandoverDetail__r.TitleDeedIssuanceDate__c ==null ){ templateNames.add('Title Deed Registration');
                }else if(tempSR.HandoverDetail__r.TitleDeedIssuanceDate__c == null && tempSR.HandoverDetail__r.UtilityTransferDate__c == null){ templateNames.add('Customer Utility Transfer');
                }else if(tempSR.HandoverDetail__r.KeyAcceptanceDate__c == null || tempSR.HandoverDetail__r.HandoverCompletionDate__c ==null ){ templateNames.add('Key Handover');
                    templateNames.add('Customer Key Handover Appointment');
                    
                }

                if(!tempSRRecordToUpdate.isPlot__c && tempSR.HandoverDetail__r.KAR__c != null && tempSR.HandoverDetail__r.CHODate__c != null && tempSR.HandoverDetail__r.CustomerSnaggingDate__c==null ){ templateNames.add('Home Orientation');
                    
                }
                if(!tempSRRecordToUpdate.isPlot__c && tempSR.HandoverDetail__r.KAR__c != null && tempSR.HandoverDetail__r.CHODate__c != null && tempSR.HandoverDetail__r.CustomerDesnaggingDate__c ==null){ templateNames.add('Ready for Occupancy');
                }

                //handover Stage values ************
                if(!tempSRRecordToUpdate.isPlot__c && tempSR.HandoverDetail__r.QASnaggingDate__c != null && tempSR.HandoverDetail__r.QADesnaggingDate__c != null){ tempHORecordToUpdate.Stage__c = 'Released by QA';
                }
                if(!tempSRRecordToUpdate.isPlot__c && tempSR.HandoverDetail__r.KAR__c != null){ tempHORecordToUpdate.Stage__c = 'Pending Finance Verification';
                }
                if(!tempSRRecordToUpdate.isPlot__c && tempSR.HandoverDetail__r.CHODate__c != null){ tempHORecordToUpdate.Stage__c = 'Finance Verification Completed';
                }

                //handover Status value values ************
                if(tempSR.HandoverDetail__r.CustomerSnaggingAppointment__c != null || tempSR.HandoverDetail__r.CustomerSnaggingDate__c != null || tempSR.HandoverDetail__r.CustomerDesnaggingDate__c !=null ){ tempHORecordToUpdate.Status__c = Constants.HO_STATUS_INPROGRESS;
                }

                for(String tpStepname : templateNames){
                    if(stepTemplateMap.containsKey(tpStepname)){
                    HexaBPM__SR_Steps__c tempStep = stepTemplateMap.get(tpStepname);
                    HexaBPM__Step__c tempRec = new HexaBPM__Step__c(    ExecuteCustomCode__c = tempStep.HexaBPM__Sys_Custom_Conditions_Actions__c,
                                                                    HexaBPM__SR_Step__c = tempStep.Id,
                                                                    OwnerId = tempStep.OwnerId,
                                                                    HexaBPM__SR__c = tempSR.id,
                                                                    HexaBPM__Start_Date__c = System.today(),
                                                                    HexaBPM__Step_No__c = tempStep.HexaBPM__Step_No__c,
                                                                    HexaBPM__Status__c = pendingStatus.id,
                                                                    HexaBPM__Step_Template__c = tempStep.HexaBPM__Step_Template__c,
                                                                    HexaBPM__Summary__c = tempStep.HexaBPM__Step_Template__r.Name,
                                                                    HexaBPM__Sys_Step_Loop_No__c = tempStep.HexaBPM__Step_No__c +'_1' );
            
                    stepsToInsert.add(tempRec);
                    }
                }
                
                hoDetailsToUpdate.add(tempHORecordToUpdate);
                if(tempHORecordToUpdate.Stage__c == 'Pending Finance Verification'){
                    tempSRRecordToUpdate.HexaBPM__External_SR_Status__c = pendingFinanceVerification.id;
                    tempSRRecordToUpdate.HexaBPM__Internal_SR_Status__c = pendingFinanceVerification.id;
                    srToUpdate.add(tempSRRecordToUpdate);
                }else if(tempHORecordToUpdate.Stage__c == 'Finance Verification Completed'){
                    tempSRRecordToUpdate.HexaBPM__External_SR_Status__c = financeVerification.id;
                    tempSRRecordToUpdate.HexaBPM__Internal_SR_Status__c = financeVerification.id;
                    srToUpdate.add(tempSRRecordToUpdate);
                }else if(tempSRRecordToUpdate.isPlot__c){ srToUpdate.add(tempSRRecordToUpdate);
                }
                
        }
        if(!stepsToInsert.isEmpty()){
            insert stepsToInsert;
        }

        if(!hoDetailsToUpdate.isEmpty()){
            update hoDetailsToUpdate;
        }

        if(!srToUpdate.isEmpty()){ update srToUpdate;
        }


    }    
    global void finish(Database.BatchableContext bc){}    
}