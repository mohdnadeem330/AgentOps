/**********************************************************************************************************************
* Name               : AppointmentTriggerHandler                                                        
* Description        : This class is to write all the trigger automations for the Appointment__c object
* Usage              : AppointmentTrigger
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     29 Dec 2022     Initial Draft  
                                                        1. Populate the related handover SR based on unit code
                                                        2. Update the strat time and end time for Integration user
                                                        3. Update the appointment details on related Handover Records
******************************************************************************************************************/

public with sharing class AppointmentTriggerHandler extends TriggerHandler{ 
    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
        //TODO Populate SR based on Type
        set<String> handoverAppointmentTypes = new set<String>{Constants.HO_HOME_ORIENTATION, Constants.HO_DESNAGGING, Constants.HO_KEYHANDOVER };
        set<String> dlpAppointmentTypes = new set<String>{Constants.ASSESSMENT, Constants.RESOLUTION};

        map<string,HexaBPM__Service_Request__c> unitCodeToHOSR = new map<string,HexaBPM__Service_Request__c>();
        User loggedInUser = Utilities.getLoggedInUserDetail();
        Id handoverAppointmentRecordTypeId = Utilities.getRecordTypeId('Appointment__C', Constants.RECORDTYPE_HANDOVER);

        Map<String, Appointment__c> caseNumberWithAppointment = new Map<String, Appointment__c>();

        for(Appointment__c tempApp : (list<Appointment__c>) newList){
            
          if(tempApp.AppointmentType__c=='Resolution' && (tempApp.Broker__c!=null)){
               tempApp.IsAsiteCall__c=false;
          }else {
              tempApp.IsAsiteCall__c=true; 
          }
            
            if(handoverAppointmentTypes.contains(tempApp.AppointmentType__c)){
                tempApp.RecordTypeId=handoverAppointmentRecordTypeId;
                //Update the time by adding offset for integration user
                /*if(loggedInUser.Profile.Name == COnstants.INTEGRATION_PROFILE){
                    tempApp.EndTime__c = tempApp.EndTime__c!=null? tempApp.EndTime__c.addHours(4) : null;
                    tempApp.StartTime__c = tempApp.StartTime__c!=null? tempApp.StartTime__c.addHours(4) : null ;
                }*/
                //Collect unit codes to process
                unitCodeToHOSR.put(tempApp.UnitCode__c,null);
            }

            if(dlpAppointmentTypes.contains(tempApp.AppointmentType__c)){

                /*if(loggedInUser.Profile.Name == COnstants.INTEGRATION_PROFILE){
                    tempApp.EndTime__c = tempApp.EndTime__c!=null? tempApp.EndTime__c.addHours(4) : null;
                    tempApp.StartTime__c = tempApp.StartTime__c!=null? tempApp.StartTime__c.addHours(4) : null ;
                }*/

                tempApp.AsiteSyncStatus__c = Constants.STATUS_IN_PROGRESS;
                
                if(tempApp.CaseNumber__c != null){
                    caseNumberWithAppointment.put(tempApp.CaseNumber__c, tempApp);
                }
            }
        }
       

        // Fetch Case Record
        if(!caseNumberWithAppointment.isEmpty()){
            populateCaseLookup(caseNumberWithAppointment);
        }
        
        //Fetch handover SRs
        Id handoverRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.HANDOVER_RT);
        
        for(HexaBPM__Service_Request__c tempSRRecord : [select id,Unit__r.Name from HexaBPM__Service_Request__c where Unit__r.Name in :unitCodeToHOSR.keySet() and (RecordTypeId = :handoverRecordTypeId or HexaBPM__Record_Type_Name__c = :Constants.SPA_TITLEDEED_FOR_RTP_AND_PHPP_DEV_RT ) and HexaBPM__External_Status_Name__c != :Constants.SR_STATUS_CANCELLED order by HexaBPM__Record_Type_Name__c]){
            unitCodeToHOSR.put(tempSRRecord.Unit__r.Name,tempSRRecord);
        }
        //Update related Service request on Appointment
        for(Appointment__c tempApp : (list<Appointment__c>) newList){
            if(unitCodeToHOSR.get(tempApp.UnitCode__c)!=null && handoverAppointmentTypes.contains(tempApp.AppointmentType__c)){
                tempApp.ServiceRequest__c = unitCodeToHOSR.get(tempApp.UnitCode__c).id;
            }
        }
    }
    
    /*
    * To populate Case__c lookup based on CaseNumber__c
    */
    public static void populateCaseLookup(Map<String, Appointment__c> caseNumberWithAppointment){

        List<String> casesNumbersList =new List<String>();
        casesNumbersList.addAll(caseNumberWithAppointment.keySet());
        List<Case> casesList = CaseService.getCasesByCaseNumber(casesNumbersList);
        List<Case> casesToUpdate = new List<Case>();

        for (Case caseRecord : casesList) {
            Appointment__c appointmentRecord = caseNumberWithAppointment.get(caseRecord.CaseNumber);
            appointmentRecord.Case__c = caseRecord.Id;
            if(appointmentRecord.Broker__c != null){
                appointmentRecord.OwnerId = appointmentRecord.Broker__c;
                caseRecord.OwnerId = appointmentRecord.Broker__c;
                /*if(caseRecord.ParentId != null){
                    Case parentCaseRec = new Case(Id=caseRecord.ParentId, OwnerId=appointmentRecord.Broker__c);
                    casesToUpdate.add(parentCaseRec);
                }*/
                casesToUpdate.add(caseRecord);
            }
        }
        if(!casesToUpdate.isEmpty()){
            update casesToUpdate;
        }
    }
    
    //*** before Update Action***//
    public override void beforeUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        set<String> handoverAppointmentTypes = new set<String>{Constants.HO_HOME_ORIENTATION, Constants.HO_DESNAGGING, Constants.HO_KEYHANDOVER };
        set<ID> srIDsCancelled = new set<ID>();
        User loggedInUser = Utilities.getLoggedInUserDetail();
        set<String> dlpAppointmentTypes = new set<String>{Constants.ASSESSMENT, Constants.RESOLUTION};
        Set<Id> dlpAppointmentsIds = new Set<Id>();
        Map<Id,String> dlpAppointmentsIdsMap=new Map<Id,String>();
        List<Case> casesToUpdateList =new List<Case>();
        List<Id> casesIds = new List<Id>();
        Map<Id, Id> childCaseWithParentCase = new Map<Id, Id>();
        Map<Id, Id> parentCaseIdWithOwnerId = new Map<Id, Id>();
        Map<String, Appointment__c> caseNumberWithAppointment = new Map<String, Appointment__c>();
        List<String> canceledAppointmentsList = new List<String>();
        map<String,Appointment__c> updatedRecords = new map<String,Appointment__c>();
        for(Appointment__c tempApp : (list<Appointment__c>) newList){
            Appointment__c oldApp = (Appointment__c)oldMap.get(tempApp.Id);
            if(tempApp.Case__c != null){
                casesIds.add(tempApp.Case__c);
            }
            if(tempApp.CaseNumber__c != null && tempApp.Broker__c != oldApp.Broker__c && tempApp.Broker__c != null && dlpAppointmentTypes.contains(tempApp.AppointmentType__c)){
                caseNumberWithAppointment.put(tempApp.CaseNumber__c, tempApp);
            }

            if(tempApp.IsAsiteCall__c && dlpAppointmentTypes.contains(tempApp.AppointmentType__c) && tempApp.Status__c != oldApp.Status__c && tempApp.Status__c == Constants.APPOINMENT_CANCELLED){
                dlpAppointmentsIds.add(tempApp.Id);
                dlpAppointmentsIdsMap.put(tempApp.Id,tempApp.Status__c);
                canceledAppointmentsList.add(tempApp.AppointmentType__c + ' - #' + tempApp.CaseNumber__c + ' - ' + tempApp.Name);
            }else if(tempApp.IsAsiteCall__c && dlpAppointmentTypes.contains(tempApp.AppointmentType__c) && ( tempApp.Broker__c != oldApp.Broker__c ||  tempApp.Date__c != oldApp.Date__c || tempApp.Slot__c != oldApp.Slot__c )){
                dlpAppointmentsIds.add(tempApp.Id);
                 dlpAppointmentsIdsMap.put(tempApp.Id,Constants.APPOINMENT_UPDATED);
                updatedRecords.put(tempApp.AppointmentType__c + ' - #' + tempApp.CaseNumber__c + ' - ' + tempApp.Name , tempApp);
            }
        }

        if(!casesIds.isEmpty()){
            populateCaseLookup(caseNumberWithAppointment);
        }
        if(!casesIds.isEmpty()){
            for (Case caseRec : CaseService.getChildCases(casesIds)) {
                childCaseWithParentCase.put(caseRec.Id, caseRec.ParentId);
            }
        }

        for(Appointment__c tempApp : (list<Appointment__c>) newList){
            //Update the time by adding offset for integration user

            /*if(loggedInUser.Profile.Name == COnstants.INTEGRATION_PROFILE){
                tempApp.EndTime__c = tempApp.EndTime__c!=null? tempApp.EndTime__c.addHours(4) : null;
                tempApp.StartTime__c = tempApp.StartTime__c!=null? tempApp.StartTime__c.addHours(4) : null ;
            }*/

            Appointment__c oldRecord = (Appointment__c)oldMap.get(tempApp.Id);

            if(tempApp.IsAsiteCall__c && dlpAppointmentTypes.contains(tempApp.AppointmentType__c) && tempApp.AsiteSyncStatus__c == Constants.STATUS_IN_PROGRESS && oldRecord.AsiteSyncStatus__c==Constants.STATUS_FAILED){
                dlpAppointmentsIds.add(tempApp.Id);
                dlpAppointmentsIdsMap.put(tempApp.Id,tempApp.Status__c);
            }
            if(tempApp.OwnerId != oldRecord.OwnerId && tempApp.Case__c != null){
                Case caseRec = new Case(Id=tempApp.Case__c, OwnerId=tempApp.OwnerId);
                parentCaseIdWithOwnerId.put(tempApp.Case__c, tempApp.OwnerId);
                casesToUpdateList.add(caseRec);
            }
            if(tempApp.ServiceRequest__c !=null && handoverAppointmentTypes.contains(tempApp.AppointmentType__c) && tempApp.Status__c == Constants.CANCELLED_UNIT ){
                srIDsCancelled.add(tempApp.ServiceRequest__c);
            } 
        }

        //To update ownerId for child cases
        for (Id childId : childCaseWithParentCase.keySet()) {
            Id parentCaseId = childCaseWithParentCase.get(childId);
            Case childCaseRec = new Case(Id=childId, OwnerId=parentCaseIdWithOwnerId.get(parentCaseId));
            casesToUpdateList.add(childCaseRec);
        }

        if(!dlpAppointmentsIds.isEmpty()){
            System.enqueueJob(new DLPCalloutUtilities.BookingSystemIntegration(dlpAppointmentsIdsMap));
        }
        if(!casesToUpdateList.isEmpty()){
            //update casesToUpdateList;
        } if(!srIDsCancelled.isEmpty()){
         //  HandoverDetailsTriggerHandler.closeOpenTasks(srIDsCancelled);
             set<String> taskSubjectList =new  set<String>();
             taskSubjectList.add(Constants.TASK_HO_CALL_48);
             taskSubjectList.add(Constants.TASK_HO_CALL_7);
             taskSubjectList.add(Constants.TASK_HO_CALL_14);
            HandoverDetailsTriggerHandler.closeOpenTasks(srIDsCancelled,taskSubjectList,true);
        }

        if(!canceledAppointmentsList.isEmpty()){
            deleteEventRecords(canceledAppointmentsList);
        }
        if(!updatedRecords.isEmpty()){
            updateEventRecords(updatedRecords);
        }
    }
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        // Collected Handover related appointments
        set<String> handoverAppointmentTypes = new set<String>{Constants.HO_HOME_ORIENTATION, Constants.HO_DESNAGGING,Constants.HO_KEYHANDOVER };
        map<ID,HexaBPM__Service_Request__c> HOSR = new map<ID,HexaBPM__Service_Request__c>();
        map<ID,Appointment__c> HOSRToAppointmentId = new map<ID,Appointment__c>();

        Set<Id> dlpAppointmentsIds = new Set<Id>();
        set<String> dlpAppointmentTypes = new set<String>{Constants.ASSESSMENT, Constants.RESOLUTION};

       
        for(Appointment__c tempApp : (list<Appointment__c>) newList){
            if(tempApp.ServiceRequest__c !=null && handoverAppointmentTypes.contains(tempApp.AppointmentType__c)){
                HOSR.put(tempApp.ServiceRequest__c,null);
                HOSRToAppointmentId.put(tempApp.ServiceRequest__c,tempApp);
            } 
            
            if(tempApp.IsAsiteCall__c && dlpAppointmentTypes.contains(tempApp.AppointmentType__c) && tempApp.AsiteSyncStatus__c == Constants.STATUS_IN_PROGRESS){
                dlpAppointmentsIds.add(tempApp.Id);
             }
            
           
        }

        if(!dlpAppointmentsIds.isEmpty()){
            System.enqueueJob(new DLPCalloutUtilities.BookingSystemIntegration(dlpAppointmentsIds));
        }
       

        //Update Handover Details with the appointment record
        if(!HOSR.isEmpty()){
            HOSR = new map<ID,HexaBPM__Service_Request__c>([select id,HandoverDetail__c,SalesOrder__r.Account__r.PersonEmail from HexaBPM__Service_Request__c where id in :HOSR.keySet() and HexaBPM__External_Status_Name__c != :Constants.SR_STATUS_CANCELLED]);
            list<HandoverDetails__c> HODetailsToUpdate = new list<HandoverDetails__c>();
            list<HexaBPM__Service_Request__c> srToUpdate = new list<HexaBPM__Service_Request__c>();
            for(HexaBPM__Service_Request__c srRecord : HOSR.values()){
                HandoverDetails__c tempHORecord = new HandoverDetails__c( id = srRecord.HandoverDetail__c );
                HexaBPM__Service_Request__c tempSrRec = new HexaBPM__Service_Request__c(id = srRecord.Id);
                if(HOSRToAppointmentId.get(srRecord.Id).AppointmentType__c == Constants.HO_HOME_ORIENTATION ){
                    tempHORecord.CustomerSnaggingAppointment__c = HOSRToAppointmentId.get(srRecord.Id).Id;
                    tempHORecord.HandoverAgent__c = HOSRToAppointmentId.get(srRecord.Id).Broker__c;
                    tempHORecord.Status__c = Constants.HO_STATUS_INPROGRESS;
                    tempHORecord.CustomerEmail__c  = srRecord.SalesOrder__r.Account__r.PersonEmail;
                    tempSrRec.HOAgent__c = HOSRToAppointmentId.get(srRecord.Id).Broker__c;
                    srToUpdate.add(tempSrRec );
                }else if(HOSRToAppointmentId.get(srRecord.Id).AppointmentType__c == Constants.HO_DESNAGGING ){
                    tempHORecord.CustomerDesnaggingAppointment__c = HOSRToAppointmentId.get(srRecord.Id).Id;
                }else  if(HOSRToAppointmentId.get(srRecord.Id).AppointmentType__c == Constants.HO_KEYHANDOVER ){
                    tempHORecord.KeyHandoverAppointment__c = HOSRToAppointmentId.get(srRecord.Id).Id;
                    tempHORecord.KeyHandoverDate__c = HOSRToAppointmentId.get(srRecord.Id).Date__c;
                }
                HODetailsToUpdate.add(tempHORecord);
            }
            if(!HODetailsToUpdate.isEmpty()){
                update HODetailsToUpdate;
                update srToUpdate;
            }
            
        }
        createEventRecords(newList);
    }

    //*** After Update Action***//
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) {
        // Collected Handover related appointments
        set<String> handoverAppointmentTypes = new set<String>{Constants.HO_HOME_ORIENTATION, Constants.HO_DESNAGGING,Constants.HO_KEYHANDOVER };
        map<ID,HexaBPM__Service_Request__c> HOSR = new map<ID,HexaBPM__Service_Request__c>();
        map<ID,Appointment__c> HOSRToAppointmentId = new map<ID,Appointment__c>();

        Set<Id> dlpAppointmentsIds = new Set<Id>();

      
        for(Appointment__c tempApp : (list<Appointment__c>) newList){
            if(tempApp.ServiceRequest__c !=null && handoverAppointmentTypes.contains(tempApp.AppointmentType__c)){
                HOSR.put(tempApp.ServiceRequest__c,null);
                HOSRToAppointmentId.put(tempApp.ServiceRequest__c,tempApp);
            }
        }
   

        //Update Handover Details with the appointment record
        if(!HOSR.isEmpty()){
            HOSR = new map<ID,HexaBPM__Service_Request__c>([select id,HandoverDetail__c,SalesOrder__r.Account__r.PersonEmail from HexaBPM__Service_Request__c where id in :HOSR.keySet() and HexaBPM__External_Status_Name__c != :Constants.SR_STATUS_CANCELLED]);
            list<HandoverDetails__c> HODetailsToUpdate = new list<HandoverDetails__c>();
            list<HexaBPM__Service_Request__c> srToUpdate = new list<HexaBPM__Service_Request__c>();
            for(HexaBPM__Service_Request__c srRecord : HOSR.values()){
                HandoverDetails__c tempHORecord = new HandoverDetails__c( id = srRecord.HandoverDetail__c );
                HexaBPM__Service_Request__c tempSrRec = new HexaBPM__Service_Request__c(id = srRecord.Id);
                if(HOSRToAppointmentId.get(srRecord.Id).AppointmentType__c == Constants.HO_HOME_ORIENTATION ){
                    tempHORecord.CustomerSnaggingAppointment__c = HOSRToAppointmentId.get(srRecord.Id).Id;
                    tempHORecord.HandoverAgent__c = HOSRToAppointmentId.get(srRecord.Id).Broker__c;
                    tempHORecord.Status__c = Constants.HO_STATUS_INPROGRESS;
                    tempHORecord.CustomerEmail__c  = srRecord.SalesOrder__r.Account__r.PersonEmail;
                    tempHORecord.InternalComments__c = 'Appointment Updated: '+ Datetime.now();
                    tempSrRec.HOAgent__c = HOSRToAppointmentId.get(srRecord.Id).Broker__c;
                    
                    srToUpdate.add(tempSrRec );
                }else if(HOSRToAppointmentId.get(srRecord.Id).AppointmentType__c == Constants.HO_DESNAGGING ){
                    tempHORecord.CustomerDesnaggingAppointment__c = HOSRToAppointmentId.get(srRecord.Id).Id;
                }else  if(HOSRToAppointmentId.get(srRecord.Id).AppointmentType__c == Constants.HO_KEYHANDOVER ){
                    tempHORecord.KeyHandoverAppointment__c = HOSRToAppointmentId.get(srRecord.Id).Id;
                    tempHORecord.KeyHandoverDate__c = HOSRToAppointmentId.get(srRecord.Id).Date__c;
                }
                HODetailsToUpdate.add(tempHORecord);
            }
            if(!HODetailsToUpdate.isEmpty()){
                update HODetailsToUpdate;
                update srToUpdate;
            }
        }
    }

   

    /*
    * To Create Event Records
    */
    public static void createEventRecords(List<Appointment__c> newList){
        set<String> dlpAppointmentTypes = new set<String>{Constants.ASSESSMENT, Constants.RESOLUTION};
        List<Event> eventToInsertList = new List<Event>();
        for (Appointment__c appRec : newList) {
            if(dlpAppointmentTypes.contains(appRec.AppointmentType__c) && appRec.Case__c != null && appRec.Broker__c != null){
                Event NewEvent = new Event();
                NewEvent.OwnerId = appRec.Broker__c;
                NewEvent.WhatId = appRec.Case__c;
                NewEvent.StartDateTime = Datetime.newInstance(appRec.Date__c, appRec.StartTime__c);
                NewEvent.EndDateTime = Datetime.newInstance(appRec.Date__c, appRec.EndTime__c);
                NewEvent.ActivityDateTime = Datetime.newInstance(appRec.Date__c, appRec.StartTime__c);
                NewEvent.Subject = appRec.AppointmentType__c + ' - #' + appRec.CaseNumber__c + ' - ' + appRec.Name;

                eventToInsertList.add(NewEvent);
            }
        }
        if(!eventToInsertList.isEmpty()){
            insert eventToInsertList;
        }
    }

    /*
    * To Delete Event Records
    */
    public static void deleteEventRecords(List<String> canceledAppointmentsList){

        List<Event> eventToDeleteList = [Select Id From Event Where Subject In: canceledAppointmentsList];

        if(!eventToDeleteList.isEmpty()){
            delete eventToDeleteList;
        }
    }

    public static void updateEventRecords(map<String,Appointment__c> updatedAppointments){
        deleteEventRecords(new list<String> ( updatedAppointments.keyset() ) );
        createEventRecords( updatedAppointments.values() );
    }
}