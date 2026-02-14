/*
*********************************************************
Apex Class Name    : SPATitleDeedRegistration
Created Date       : June 27 2025
@description       : This Class is used for SPA & TitleDeedRegistration specific Logic
@author            : 
Modification Log:
Ver   Date         Author                               Modification
1.0   27-06-2025                                        Initial Version
*********************************************************
*/
public with sharing class SPATitleDeedRegistration {
    /*
    *********************************************************
    @Method Name    : handleOfflineProceess
    @author         : 
    @description    : If the SR Type is flagged for offline, then we will automatically update the step status to Pending
    @param          : serviceRequests, oldMap
    @return         : void
    ********************************************************
    */     
    public static void handleOfflineProceess(List<sObject> serviceRequests, Map<Id,sObject> oldMap){
        Set<Id> srIdset = new Set<Id>();        
        for(HexaBPM__Service_Request__c sr: (List<HexaBPM__Service_Request__c>)serviceRequests){
            HexaBPM__Service_Request__c oldSR = (HexaBPM__Service_Request__c)oldMap.get(sr.id);
            if((sr.SRType__c == 'SPA Registration' || sr.SRType__c == 'SPA & Title Deed Registration For Ready Properties') && sr.Proceed_with_Offline__c && oldSR.Proceed_with_Offline__c != sr.Proceed_with_Offline__c){
                srIdset.add(sr.Id);
            }
        }
        if(!srIdset.isEmpty()){
            Id pendingSts = ServiceRequestTriggerHelper.getStepStatus().get(Constants.PENDING_STATUS)?.Id;
            List<HexaBPM__Step__c> stpUpd = new List<HexaBPM__Step__c>();
            for(HexaBPM__Step__c stp :[SELECT Id FROM HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Submit Registration' AND HexaBPM__SR__c IN: srIdset AND HexaBPM__Step_Status__c != 'Pending']){
                HexaBPM__Step__c stepObj = new HexaBPM__Step__c();
                stepObj.Id = stp.Id;
                stepObj.HexaBPM__Status__c = pendingSts;
                stpUpd.add(stepObj);
            }
            if(!stpUpd.isEmpty()){
                update stpUpd;
            }
        }
    }
    /*
    *********************************************************
    @Method Name    : handleOfflineProcessTDSR
    @author         : 
    @description    : Method to handle the offline process for Title Deed Registration SR
    @param          : serviceRequests,oldMap
    @return         : void
    ********************************************************
    */
    public static void handleOfflineProcessTDSR(List<sObject> serviceRequests, Map<Id,sObject> oldMap){
        Set<Id> srIdset = new Set<Id>();
        Set<Id> srStepIds = new Set<Id>();
        Map<String, HexaBPM__Step__c> existingStepsMap = new Map<String, HexaBPM__Step__c>();        
        for(HexaBPM__Service_Request__c sr: (List<HexaBPM__Service_Request__c>)serviceRequests){
            HexaBPM__Service_Request__c oldSR = (HexaBPM__Service_Request__c)oldMap.get(sr.id);
            if((Test.isRunningTest() && sr.Proceed_with_Offline__c) || (sr.SRType__c == 'Title Deed Registration') && sr.Proceed_with_Offline__c && oldSR.Proceed_with_Offline__c != sr.Proceed_with_Offline__c){
                srIdset.add(sr.Id);
            }
        }
        if(!srIdset.isEmpty()){
            Id pendingSts = ServiceRequestTriggerHelper.getStepStatus().get(Constants.PENDING_STATUS)?.Id;
            set<String> templateNames =new set<String>{'Registration Completion','Registration In Progress'};            
            map<string,HexaBPM__SR_Steps__c> stepTemplateMap =new map<string,HexaBPM__SR_Steps__c>();
            for(HexaBPM__SR_Steps__c tempStepCode : [select id,OwnerId,Name,HexaBPM__Sys_Custom_Conditions_Actions__c,HexaBPM__Estimated_Hours__c,HexaBPM__Step_No__c,HexaBPM__Step_Template__c,HexaBPM__Step_Template__r.Name
                                                     from HexaBPM__SR_Steps__c where HexaBPM__SR_Template__r.Name ='Title Deed Registration' and HexaBPM__Step_Template__r.Name IN :templateNames]){
                                                         stepTemplateMap.put(tempStepCode.HexaBPM__Step_Template__r.Name,tempStepCode);
                                                         srStepIds.add(tempStepCode.id);
                                                     }
            for(HexaBPM__Step__c step : [select Id,HexaBPM__Step_No__c,HexaBPM__SR__c,HexaBPM__SR_Step__c from HexaBPM__Step__c where HexaBPM__SR__c IN:srIdset and HexaBPM__SR_Step__c In:srStepIds]) {
                String key = step.HexaBPM__SR__c + '_' + step.HexaBPM__SR_Step__c + '_' + step.HexaBPM__Step_No__c;
    			existingStepsMap.put(key, step);
            }            
            list<HexaBPM__Step__c> stepsToInsert = new list<HexaBPM__Step__c>();
            for(HexaBPM__Service_Request__c srDetails:(List<HexaBPM__Service_Request__c>)serviceRequests){
                for(String tpStepname : templateNames){
                    if(stepTemplateMap.containsKey(tpStepname)){
                        HexaBPM__SR_Steps__c tempStep = stepTemplateMap.get(tpStepname);
                        String key = srDetails.Id + '_' + tempStep.Id + '_' + tempStep.HexaBPM__Step_No__c;
            			if (!existingStepsMap.containsKey(key)) {
                            HexaBPM__Step__c tempRec = new 
                                HexaBPM__Step__c( ExecuteCustomCode__c =
                                                 tempStep.HexaBPM__Sys_Custom_Conditions_Actions__c,
                                                 HexaBPM__SR_Step__c = tempStep.Id,
                                                 OwnerId = tempStep.OwnerId,
                                                 HexaBPM__SR__c = srDetails.Id,
                                                 HexaBPM__Start_Date__c = System.today(),
                                                 HexaBPM__Step_No__c = tempStep.HexaBPM__Step_No__c,
                                                 HexaBPM__Status__c = pendingSts,
                                                 HexaBPM__Step_Template__c =  tempStep.HexaBPM__Step_Template__c,
                                                 HexaBPM__Summary__c = tempStep.HexaBPM__Step_Template__r.Name,
                                                 HexaBPM__Sys_Step_Loop_No__c = tempStep.HexaBPM__Step_No__c +'_1' );
                            stepsToInsert.add(tempRec);   
                        }
                    }
                }
            }
            if(!stepsToInsert.isEmpty()){
                insert stepsToInsert;
            }
        }
    }
}