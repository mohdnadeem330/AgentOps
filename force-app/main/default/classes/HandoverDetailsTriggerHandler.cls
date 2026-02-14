public with sharing class HandoverDetailsTriggerHandler extends TriggerHandler{

    public override void beforeUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        for (HandoverDetails__c newRecord: (List<HandoverDetails__c>)newList) {
            HandoverDetails__c oldRecord = (HandoverDetails__c)oldMap.get(newRecord.Id);
            //Populate Stage
            if(newRecord.QADesnaggingDate__c != oldRecord.QADesnaggingDate__c && newRecord.QADesnaggingDate__c !=null ){
                newRecord.stage__c=Constants.HO_STAGE_RELEASED_BY_QA;
            }

            /* RFO Condition */
            if(newRecord.CustomerDesnaggingDate__c != oldRecord.CustomerDesnaggingDate__c && newRecord.CustomerDesnaggingDate__c !=null){
                newRecord.RFODate__c= system.today();
                newRecord.RFODate__c= system.today();
                newRecord.UtilityTransferStatus__c =  Constants.HO_TRANSSTATUS_NOTSTRTED;
                newRecord.TitleDeedStatus__c =  Constants.HO_TRANSSTATUS_NOTSTRTED;
                //newRecord.ServiceChargeStartDate__c= system.today();
            }
        }
    }

   
    //*** After Update Action***//    
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        
        //Lettters Condition
        set<ID> HOLIds = new set<ID>();
        set<ID> PhasingIds = new set<ID>();
        set<ID> CHOIds = new set<ID>();
        set<ID> RFOIds = new set<ID>();
        set<ID> HCIds = new set<ID>();
        set<ID> snggedIds = new set<ID>();
        string integrationType='';

        //ERP Callout Vars
        set<ID> calloutIds = new set<ID>();

        //Activity 
        map<id,Date> homeOrientationEventDate = new map<id,Date>();

        //Auto Close Vars
        map<ID,set<String>> handoverIdToStepName = new map<ID,set<String>>();
        set<String> stepTemplateCodes = new set<String>();
        List<Asset> assetToInsert = new List<Asset>();
        Id EcssUnitRecordTypeId =  Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Ecss Unit').getRecordTypeId();
        Map<Id,Id>UnitMaphandover = new Map<Id,Id>();
        Set<Id> UnitIds = new Set<Id>();
        for(HandoverDetails__c newRecord:(List<HandoverDetails__c>)newList){
           UnitIds.add(newRecord.Unit__c);
            UnitMaphandover.put(newRecord.Id,newRecord.Unit__c);
        }
         Map<id, Unit__c> UnitMap = new Map<id, Unit__c>([SELECT Id,Name,Project__c,UnitView__c,FloorNumber__c,NumberOfBedrooms__c,NumberOfBathrooms__c,NumberOfCarParks__c, RelatedSalesOrder__r.Account__c, RelatedSalesOrder__r.AccountName__c, TotalArea__c,BuildingSectionName__c,UnitType__c FROM Unit__c 
            						WHERE Id IN :UnitIds]); 
        
        for (HandoverDetails__c newRecord: (List<HandoverDetails__c>)newList) {
            HandoverDetails__c oldRecord = (HandoverDetails__c)oldMap.get(newRecord.Id);
            /* Auto Close */
            
            /*if(newRecord.QASnaggingDate__c != oldRecord.QASnaggingDate__c || newRecord.QADesnaggingDate__c != oldRecord.QADesnaggingDate__c || newRecord.CustomerSnaggingDate__c != oldRecord.CustomerSnaggingDate__c || newRecord.CustomerDesnaggingDate__c != oldRecord.CustomerDesnaggingDate__c ||
                newRecord.CustomerDesnaggingAppointment__c != oldRecord.CustomerDesnaggingAppointment__c  || newRecord.CustomerSnaggingAppointment__c != oldRecord.CustomerSnaggingAppointment__c || newRecord.HandoverPhaseDate__c != oldRecord.HandoverPhaseDate__c || newRecord.KeyHandoverAppointment__c != oldRecord.KeyHandoverAppointment__c){
                if(!handoverIdToStepName.containsKey(newRecord.Id) ){
                    handoverIdToStepName.put(newRecord.Id,new set<String>());
                }
            }*/
            //Added By Tajinkumar Devar 15-05-2025 for Clsoing Steps using Service Appointments
            if(newRecord.QASnaggingDate__c != oldRecord.QASnaggingDate__c || newRecord.QADesnaggingDate__c != oldRecord.QADesnaggingDate__c || newRecord.CustomerSnaggingDate__c != oldRecord.CustomerSnaggingDate__c || newRecord.CustomerDesnaggingDate__c != oldRecord.CustomerDesnaggingDate__c ||
               newRecord.Desnagging_Appointment__c != oldRecord.Desnagging_Appointment__c  || newRecord.Home_Orientation_Appointment__c != oldRecord.Home_Orientation_Appointment__c || newRecord.HandoverPhaseDate__c != oldRecord.HandoverPhaseDate__c || newRecord.Key_Handover_Appointment__c != oldRecord.Key_Handover_Appointment__c){
                   if(!handoverIdToStepName.containsKey(newRecord.Id) ){
                       handoverIdToStepName.put(newRecord.Id,new set<String>());
                   }
               }

            if(newRecord.QASnaggingDate__c != oldRecord.QASnaggingDate__c && newRecord.QASnaggingDate__c !=null){
                handoverIdToStepName.get(newRecord.Id).add(Constants.QA_SNAGGING_STEP);
                stepTemplateCodes.add(Constants.QA_SNAGGING_STEP);
            }
            if(newRecord.QADesnaggingDate__c != oldRecord.QADesnaggingDate__c && newRecord.QADesnaggingDate__c !=null){
                handoverIdToStepName.get(newRecord.Id).add(Constants.QA_SNAGGING_STEP);
                handoverIdToStepName.get(newRecord.Id).add(Constants.QA_DESNAGGING_STEP);
                stepTemplateCodes.add(Constants.QA_SNAGGING_STEP);
                stepTemplateCodes.add(Constants.QA_DESNAGGING_STEP);
            }
            if(newRecord.CustomerSnaggingDate__c != oldRecord.CustomerSnaggingDate__c && newRecord.CustomerSnaggingDate__c !=null ){
                handoverIdToStepName.get(newRecord.Id).add(Constants.CUSTOMER_SNAGGING_STEP);
                stepTemplateCodes.add(Constants.CUSTOMER_SNAGGING_STEP);
            }
            if(newRecord.CustomerDesnaggingDate__c != oldRecord.CustomerDesnaggingDate__c && newRecord.CustomerDesnaggingDate__c !=null ){
                handoverIdToStepName.get(newRecord.Id).add(Constants.CUSTOMER_SNAGGING_STEP);
                handoverIdToStepName.get(newRecord.Id).add(Constants.CUSTOMER_DESNAGGING_STEP);
                stepTemplateCodes.add(Constants.CUSTOMER_SNAGGING_STEP);
                stepTemplateCodes.add(Constants.CUSTOMER_DESNAGGING_STEP);
            }
            
            if(newRecord.Home_Orientation_Appointment__c != oldRecord.Home_Orientation_Appointment__c && newRecord.Home_Orientation_Appointment__c !=null){
                handoverIdToStepName.get(newRecord.Id).add(Constants.STEP_NAME_SNAGGING_APPOINTMENT);
                stepTemplateCodes.add(Constants.STEP_NAME_SNAGGING_APPOINTMENT);
            }
            if(newRecord.Desnagging_Appointment__c != oldRecord.Desnagging_Appointment__c && newRecord.Desnagging_Appointment__c !=null ){
                handoverIdToStepName.get(newRecord.Id).add(Constants.STEP_NAME_DESNAGGING_APPOINTMENT);
                stepTemplateCodes.add(Constants.STEP_NAME_DESNAGGING_APPOINTMENT);
            }
            if(newRecord.Key_Handover_Appointment__c != oldRecord.Key_Handover_Appointment__c && newRecord.Key_Handover_Appointment__c !=null ){
                handoverIdToStepName.get(newRecord.Id).add(Constants.STEP_NAME_KEYHANDOVER_APPOINTMENT);
                stepTemplateCodes.add(Constants.STEP_NAME_KEYHANDOVER_APPOINTMENT);
            }
            if(newRecord.HandoverPhaseDate__c != oldRecord.HandoverPhaseDate__c && newRecord.HandoverPhaseDate__c !=null ){
                handoverIdToStepName.get(newRecord.Id).add(Constants.STEP_NAME_HANDOVER_PHASING);
                stepTemplateCodes.add(Constants.STEP_NAME_HANDOVER_PHASING);
            }
            
            
            /* Auto Close End*/

          
            /* Trigger Integration */
           /*if((newRecord.TitleDeedCompletionDate__c != oldRecord.TitleDeedCompletionDate__c && newRecord.TitleDeedCompletionDate__c !=null) ||
                (newRecord.HandoverCompletionDate__c != oldRecord.HandoverCompletionDate__c && newRecord.HandoverCompletionDate__c !=null) ||
                (newRecord.FinanceBilling__c != oldRecord.FinanceBilling__c && newRecord.FinanceBilling__c !=null) ||
                (newRecord.RFODate__c != oldRecord.RFODate__c && newRecord.RFODate__c !=null) ){
                    calloutIds.add(newRecord.Id);
            }*/
            
             if(newRecord.HandoverCompletionDate__c != oldRecord.HandoverCompletionDate__c && newRecord.HandoverCompletionDate__c !=null){
                integrationType = 'HO';
                 calloutIds.add(newRecord.Id);
            }else if(newRecord.TitleDeedCompletionDate__c != oldRecord.TitleDeedCompletionDate__c && newRecord.TitleDeedCompletionDate__c !=null){
                integrationType = 'NOC';
                calloutIds.add(newRecord.Id);
            }else if(newRecord.RFODate__c != oldRecord.RFODate__c && newRecord.RFODate__c !=null){
                integrationType = 'RFO';
                calloutIds.add(newRecord.Id);
            }else if(newRecord.FinanceBilling__c != oldRecord.FinanceBilling__c && newRecord.FinanceBilling__c !=null){
                integrationType = 'CHO';
                calloutIds.add(newRecord.Id);
            }

            /* Trigger Survey End */

            /* Letters to be Sent */
            if(newRecord.HandoverCompletionLetterDate__c != oldRecord.HandoverCompletionLetterDate__c && newRecord.HandoverCompletionLetterDate__c !=null ){
                HOLIds.add(newRecord.Id);
            }
            if(newRecord.HandoverPhasingLetterDate__c != oldRecord.HandoverPhasingLetterDate__c && newRecord.HandoverPhasingLetterDate__c !=null ){
                PhasingIds.add(newRecord.Id);
            }
            if(newRecord.CHODate__c != oldRecord.CHODate__c && newRecord.CHODate__c !=null ){
                CHOIds.add(newRecord.Id);
            }
            if(newRecord.RFODate__c != oldRecord.RFODate__c && newRecord.RFODate__c !=null ){
                RFOIds.add(newRecord.Id);
            }
            /*if(newRecord.HandoverCompletionDate__c != oldRecord.HandoverCompletionDate__c && newRecord.HandoverCompletionDate__c !=null ){
                HCIds.add(newRecord.Id);
            }*/
            if(newRecord.CustomerSnaggingDate__c != oldRecord.CustomerSnaggingDate__c && newRecord.CustomerSnaggingDate__c !=null ){
                snggedIds.add(newRecord.Id);
            }
            
            /* Letters End */

            if( (newRecord.InternalComments__c != oldRecord.InternalComments__c || newRecord.CustomerSnaggingAppointment__c != oldRecord.CustomerSnaggingAppointment__c  )  && newRecord.SnaggingAppointmentDate__c !=null ){
                homeOrientationEventDate.put(newRecord.Id,newRecord.SnaggingAppointmentDate__c);
            }
            
            //Added By Piyush 20-09-2025 create Assert if status changed to Handover Completed
        	if(newRecord.RFOSent__c != oldRecord.RFOSent__c && newRecord.RFOSent__c == true){
                Unit__c Unitrecord = UnitMaphandover.get(newRecord.Id)!= null?UnitMap.get(UnitMaphandover.get(newRecord.Id)) : null;
                if(Unitrecord != null){
                    Asset assetRecord = new Asset();
                    assetRecord.Name = Unitrecord.Name;
                    assetRecord.Unit__c = newRecord.Unit__c;
                    assetRecord.RecordTypeId =EcssUnitRecordTypeId;
                    assetRecord.ECSS_Unit_Total_Area__c = Unitrecord.TotalArea__c;
                    assetRecord.ECSS_Building_Section__c = Unitrecord.BuildingSectionName__c;
                    assetRecord.ECSS_Project__c = Unitrecord.Project__c;
                    assetRecord.ECSS_Unit_Type__c = Unitrecord.UnitType__c;
                    assetRecord.ECSS_Floor_Number__c = Unitrecord.FloorNumber__c;
                    assetRecord.ECSS_Number_of_Bedrooms__c = Unitrecord.NumberOfBedrooms__c;
                    assetRecord.ECSS_Number_of_Baths__c = Unitrecord.NumberOfBathrooms__c;
                    assetRecord.ECSS_CarParks__c = Unitrecord.NumberOfCarParks__c;
                 	assetToInsert.add(assetRecord);
                }
            }

        }
        
        //Added By Piyush 20-09-2025 create Assert if status changed to Handover Completed
        if(!assetToInsert.isEmpty()){
            insert assetToInsert;
            
            List<FM_Companies__c> companyToInsert = new List<FM_Companies__c>();
            
            For(Asset asset : assetToInsert){
                companyToInsert.add(new FM_Companies__c(Unit__c = asset.Id, Type_of_Management__c = 'OA'));
            }
            
            if(!companyToInsert.isEmpty()){
				insert companyToInsert;
            }
        } 

        //Completion Status
        /* Auto Close End*/
        if(!stepTemplateCodes.isEmpty()){
            //get closing status
            map<string,HexaBPM__Status__c> closeStepStatusMap = new map<string,HexaBPM__Status__c>();
            for(HexaBPM__Status__c tempStep : [select id,name from HexaBPM__Status__c where name in ( :Constants.STEP_STATUS_COMPLETED , :Constants.STEP_STATUS_APPOINTMENT_BOOKED )]){
                closeStepStatusMap.put(tempStep.Name,tempStep);
            }
            //get Pending step
            list<HexaBPM__Step__c> stepsToClose = [select id,HexaBPM__SR__c,HexaBPM__SR__r.HandoverDetail__c,Step_Template_Code__c from HexaBPM__Step__c where Step_Template_Code__c in :stepTemplateCodes and HexaBPM__SR__r.HandoverDetail__c in :handoverIdToStepName.keySet()  and HexaBPM__Step_Status__c =:Constants.STEP_STATUS_PENDING];

            for(HexaBPM__Step__c stepRec :stepsToClose ){ 
                if(handoverIdToStepName.containsKey(stepRec.HexaBPM__SR__r.HandoverDetail__c) && !handoverIdToStepName.get(stepRec.HexaBPM__SR__r.HandoverDetail__c).isEmpty() && handoverIdToStepName.get(stepRec.HexaBPM__SR__r.HandoverDetail__c).contains( stepRec.Step_Template_Code__c) ){
                    if(stepRec.Step_Template_Code__c == Constants.STEP_NAME_DESNAGGING_APPOINTMENT || stepRec.Step_Template_Code__c == Constants.STEP_NAME_SNAGGING_APPOINTMENT ||  stepRec.Step_Template_Code__c == Constants.STEP_NAME_KEYHANDOVER_APPOINTMENT){
                        stepRec.HexaBPM__Status__c = closeStepStatusMap.get(Constants.STEP_STATUS_APPOINTMENT_BOOKED).Id;
                    }else{
                        stepRec.HexaBPM__Status__c = closeStepStatusMap.get(Constants.STEP_STATUS_COMPLETED).Id;
                    }
                }
            }
            update stepsToClose;

        }
        
        // Initiate HO Completion Process
        if(!HOLIds.isEmpty()){
            HandoverUtility.sendHOL(HOLIds);
        }
        // Initiate Phasing Process
        if(!PhasingIds.isEmpty()){
            HandoverUtility.sendPhasing(PhasingIds);
        }
        // Initiate CHO Process
        if(!CHOIds.isEmpty()){
            HandoverUtility.sendCHO(CHOIds);
        }
        // Initiate RFO Process
        if(!RFOIds.isEmpty()){
            HandoverUtility.sendRFO(RFOIds);
            HandoverUtility.activateDLPAMC(RFOIds);
        }
       
        //Send Snagging
        
        if(!snggedIds.isEmpty()){
            //HandoverUtility.sendSnags(snggedIds); --> Sending it from Document Placeholder trigger
        }
        //Make Callout NOC + Handover Completion (RFO+CHO From batch)
        if(!calloutIds.isEmpty()){
            System.debug('@@@calloutIds'+calloutIds+'  - @@@integrationType'+integrationType);
            HandoverUtility.callERP(calloutIds);
        }

        //Activities
        list<Task> taskToBeCreated = new list<Task> ();
        list<Event> eventToBeCreated = new list<Event> ();
        set<Id> relHOActivityIDs = new set<ID>(); 
        if(!homeOrientationEventDate.isEmpty()){
            relHOActivityIDs.addAll(homeOrientationEventDate.keySet());
        }
        if(!RFOIds.isEmpty()){
            relHOActivityIDs.addAll(RFOIds);
        }
        set<ID> whatIdSet = new set<ID>();
        set<ID> whatIdToClosedSet = new set<ID>();
        Id handoverRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);
        set<String> taskSubjectList = new set<String>();
        Boolean eventDelete=false;
        for(HexaBPM__Service_Request__c tempSRRecord : [select id,HandoverDetail__c,HandoverDetail__r.CustomerSnaggingAppointment__r.Date__c,HandoverDetail__r.CustomerSnaggingAppointment__r.StartTime__c,HandoverDetail__r.CustomerSnaggingAppointment__r.EndTime__c ,HandoverDetail__r.HandoverAgent__c ,HOAgent__c,HexaBPM__Contact__c, HandoverDetail__r.CustomerSnaggingAppointmentStatus__c,HandoverDetail__r.kar__c,Unit__r.Name  from HexaBPM__Service_Request__c where HandoverDetail__c in :relHOActivityIDs and recordTypeId = :handoverRecordTypeId and HandoverDetail__r.HandoverAgent__c!=null]){
            if(homeOrientationEventDate.containsKey(tempSRRecord.HandoverDetail__c)){
                whatIdSet.add(tempSRRecord.Id);

                if(tempSRRecord.HandoverDetail__r.CustomerSnaggingAppointmentStatus__c != 'Cancelled'){
                    // Appointment Day Task
                    eventToBeCreated.add(new Event(   WhoId =  tempSRRecord.HexaBPM__Contact__c,
                        WhatId=tempSRRecord.Id,
                        subject=Constants.EVENT_HO+tempSRRecord.Unit__r.Name,
                        ownerId = !Test.isRunningTest() ? tempSRRecord.HandoverDetail__r.HandoverAgent__c :  userInfo.getUserId() ,
                        StartDateTime = DateTime.newInstance(tempSRRecord.HandoverDetail__r.CustomerSnaggingAppointment__r.Date__c,tempSRRecord.HandoverDetail__r.CustomerSnaggingAppointment__r.StartTime__c),
                        EndDateTime = DateTime.newInstance(tempSRRecord.HandoverDetail__r.CustomerSnaggingAppointment__r.Date__c,tempSRRecord.HandoverDetail__r.CustomerSnaggingAppointment__r.EndTime__c),
                        ActivityDateTime = DateTime.newInstance(tempSRRecord.HandoverDetail__r.CustomerSnaggingAppointment__r.Date__c,tempSRRecord.HandoverDetail__r.CustomerSnaggingAppointment__r.StartTime__c) ));
                    
                    taskToBeCreated.add(new Task(   WhoId =  tempSRRecord.HexaBPM__Contact__c,
                        WhatId=tempSRRecord.Id,
                        subject=Constants.TASK_HO_CALL_48+tempSRRecord.Unit__r.Name,
                        ownerId = !Test.isRunningTest() ? tempSRRecord.HandoverDetail__r.HandoverAgent__c : userInfo.getUserId(),
                        ActivityDate = homeOrientationEventDate.get(tempSRRecord.HandoverDetail__c).addDays(-2),
                        Priority= 'High',                         
                        IsReminderSet = true,
                        ReminderDateTime =  homeOrientationEventDate.get(tempSRRecord.HandoverDetail__c).addDays(-2)- (4/24)));
                    taskSubjectList.add(Constants.TASK_HO_CALL_48);
                   
                    // 7 Days after  Home Orientation Courtesy call
                    taskToBeCreated.add(new Task(   WhoId =  tempSRRecord.HexaBPM__Contact__c,
                        WhatId=tempSRRecord.Id,
                        subject=Constants.TASK_HO_CALL_7+tempSRRecord.Unit__r.Name,
                        ownerId = !Test.isRunningTest() ? tempSRRecord.HandoverDetail__r.HandoverAgent__c :  userInfo.getUserId() ,
                        ActivityDate = homeOrientationEventDate.get(tempSRRecord.HandoverDetail__c).addDays(7),
                        Priority= 'High',                         
                        IsReminderSet = true,
                        ReminderDateTime = homeOrientationEventDate.get(tempSRRecord.HandoverDetail__c).addDays(7)- (4/24)));
                    taskSubjectList.add(Constants.TASK_HO_CALL_7);
                    //14 Days after  Home Orientation Courtesy call
                      taskToBeCreated.add(new Task(   WhoId =  tempSRRecord.HexaBPM__Contact__c,
                        WhatId=tempSRRecord.Id,
                        subject=Constants.TASK_HO_CALL_14+tempSRRecord.Unit__r.Name,
                        ownerId = !Test.isRunningTest() ? tempSRRecord.HandoverDetail__r.HandoverAgent__c :  userInfo.getUserId(),
                        ActivityDate = homeOrientationEventDate.get(tempSRRecord.HandoverDetail__c).addDays(14),
                        Priority= 'High',                         
                        IsReminderSet = true,
                        ReminderDateTime = homeOrientationEventDate.get(tempSRRecord.HandoverDetail__c).addDays(14)- (4/24)));
                        taskSubjectList.add(Constants.TASK_HO_CALL_14);
                        eventDelete=true;
                } else {
                    taskSubjectList.add(Constants.TASK_HO_CALL_48);
            		taskSubjectList.add(Constants.TASK_HO_CALL_7);
            		taskSubjectList.add(Constants.TASK_HO_CALL_14);
                    eventDelete=true;
                    whatIdToClosedSet.add(tempSRRecord.Id);
                }
            }

            if(RFOIds.contains(tempSRRecord.HandoverDetail__c) && tempSRRecord.HandoverDetail__r.CustomerSnaggingAppointmentStatus__c != 'Cancelled'){
                // 7 Days after  RFO Courtesy call
                taskSubjectList.add(Constants.TASK_RFO_CALL);
                whatIdSet.add(tempSRRecord.Id);
                eventDelete=false;
                taskToBeCreated.add(new Task(   WhoId =  tempSRRecord.HexaBPM__Contact__c,
                    WhatId=tempSRRecord.Id,
                    subject=Constants.TASK_RFO_CALL+tempSRRecord.Unit__r.Name,
                    ownerId = !Test.isRunningTest() ? tempSRRecord.HandoverDetail__r.kar__c :  userInfo.getUserId() ,
                    ActivityDate = system.today().addDays(7),
                    Priority= 'High',                         
                    IsReminderSet = true,
                    ReminderDateTime = system.today().addDays(7)- (4/24)));
            }
        }
        if(!whatIdToClosedSet.isEmpty()){
            //close other tasks
            //task to close
            closeOpenTasks(whatIdToClosedSet,taskSubjectList,eventDelete);
        }
        if(!taskToBeCreated.isEmpty()){
            //close other tasks
            //task to close
            closeOpenTasks(whatIdSet,taskSubjectList,eventDelete);
            insert taskToBeCreated;
        }
        if(!eventToBeCreated.isEmpty()){
            insert eventToBeCreated;
        }
       
    }

    public static void closeOpenTasks( set<ID> whatIdSet, set<String> taskSubjectList, Boolean eventDelete ){
        list<Task> taskToBeUpdated = [select id,subject from task where Status != :Constants.TASK_COMPLETED  and WhatId in :whatIdSet ];
       
        List<Task> idsToBeDeleated=new  List<Task>();
        if(!taskToBeUpdated.isEmpty() && !taskSubjectList.isEmpty()){
            for(Task tRec : taskToBeUpdated){
                tRec.Status = Constants.TASK_COMPLETED;        
                for(String taskSub:taskSubjectList){
                   if(tRec.Subject!=null && tRec.Subject.contains(taskSub)){            
                       idsToBeDeleated.add(tRec);
                   } 
                }
                
            }
            //delete idsToBeDeleated;
        }

        if(eventDelete){
            list<Event> eventsToBeUpdated = [select id from Event where WhatId in :whatIdSet ];
            if(!eventsToBeUpdated.isEmpty()){
               // delete eventsToBeUpdated;
                
            } 
        }
       
            
    }
}