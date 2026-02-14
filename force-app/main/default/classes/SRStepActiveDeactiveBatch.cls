global class SRStepActiveDeactiveBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    
    public List<String> templateNames=new  List<String>();
    public String query='';
    public String createdByID='0058d0000047YS8AAM';
    public Boolean isDeleteStep=false;
    //public List<String> srIds=new List<String>();
    
    /* Batch Execution code
       List<String> templateNames = new List<String>();
         templateNames.add('Title Deed Registration');
         templateNames.add('Upload Title Deed');
         templateNames.add('Customer Utility Transfer');
         String query='Select id,SalesOrder__r.Unit__r.Project__r.Name,SalesOrder__r.Unit__r.BuildingSectionName__r.Name,HandoverDetail__r.RFODate__c, SalesOrder__r.Unit__r.Name, HandoverDetail__r.HandoverCompletionLetterDate__c,HandoverDetail__r.Status__c,SalesOrder__r.PHPP__c from  HexaBPM__Service_Request__c  where HandoverDetail__r.PaymentStatus__c   =\'Settled\' and HandoverDetail__r.KAR__c !=null and SalesOrder__r.Unit__r.Project__r.Name = \'AlReeman2\' and HandoverDetail__r.Status__c!=\'Handover Completed\' and HexaBPM__External_Status_Name__c!=\'Closed\'  	and (SalesOrder__r.Unit__r.BuildingSectionName__r.Name =\'AlReeman2-N1\' or SalesOrder__r.Unit__r.BuildingSectionName__r.Name =\'AlReeman2-N2\') and SalesOrder__r.PHPP__c=false limit 1' ;
         SRStepActiveDeactiveBatch srBatch=new SRStepActiveDeactiveBatch(templateNames,query,false);
         Database.executeBatch(srBatch, 1);
   */
    
    global SRStepActiveDeactiveBatch(List<String> templateNames, String query,
                                     Boolean isDeleteStep){
        this.query=query;
        this.templateNames=templateNames;
        this.isDeleteStep=isDeleteStep;   
                                     
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        //String query='select id,HexaBPM__Customer__c,Unit__r.recordType.Name, HandoverDetail__r.HandoverCompletionDate__c,HandoverDetail__r.UtilityTransferDate__c ,HandoverDetail__r.LastInstallment__c,HandoverDetail__c,HandoverDetail__r.QASnaggingDate__c,HandoverDetail__r.QADesnaggingDate__c,HandoverDetail__r.KAR__c,HandoverDetail__r.CHODate__c,HandoverDetail__r.CustomerSnaggingAppointment__c,HandoverDetail__r.CustomerSnaggingDate__c,HandoverDetail__r.CustomerDesnaggingDate__c,HandoverDetail__r.TitleDeedCompletionDate__c,HandoverDetail__r.KeyAcceptanceDate__c from  HexaBPM__Service_Request__c  where HandoverDetail__c!=null and HexaBPM__External_Status_Name__c = \'Submitted\' and HexaBPM__External_Status_Name__c !=\'Closed\' and '+System.label.HOSTepsQuery ;
        return Database.getQueryLocator(query);
    }
    
    
    global void execute(Database.BatchableContext BC, List<HexaBPM__Service_Request__c> scope) {
         map<id,HexaBPM__Service_Request__c> srMap = new map<id,HexaBPM__Service_Request__c>(scope);
        //Delete exsiting steps
        //created by paras or Nithu or yuganther or integration user or Rohit
        if(isDeleteStep){
            delete [select id from HexaBPM__Step__c  where 
                    HexaBPM__SR__c in :srMap.KeySet() and HexaBPM__Status__r.Name='Pending' and CreatedBy.Id=:createdByID];
        }
       
        // Create new steps
        // pending Status
        HexaBPM__Status__c pendingStatus = [select id,name from HexaBPM__Status__c where name = 'Pending' limit 1];
        map<string,HexaBPM__SR_Steps__c> stepTemplateMap = new map<string,HexaBPM__SR_Steps__c>();
        for(HexaBPM__SR_Steps__c tempStepCode : [select id,OwnerId,Name,HexaBPM__Sys_Custom_Conditions_Actions__c,HexaBPM__Estimated_Hours__c,HexaBPM__Step_No__c,HexaBPM__Step_Template__c,HexaBPM__Step_Template__r.Name from HexaBPM__SR_Steps__c where HexaBPM__SR_Template__r.Name ='Handover']){
            stepTemplateMap.put(tempStepCode.HexaBPM__Step_Template__r.Name,tempStepCode);
        }
        //Conditinal Update
        list<HexaBPM__Step__c> stepsToInsert = new list<HexaBPM__Step__c>();    
        for(HexaBPM__Service_Request__c tempSR : scope ){
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
                
        }
        if(!stepsToInsert.isEmpty()){
            insert stepsToInsert;
        }

        
    }
    
     global void finish(Database.BatchableContext BC){
       System.debug(' ***** SRStepActiveDeactiveBatch ******* Finished');
    }

}