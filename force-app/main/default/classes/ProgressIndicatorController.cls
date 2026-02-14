/******************************************************************************************
 *  Company     : Pwc
 *  Date        : 24/03/2022
 *  Description : Controller for ProgressIndicator Component which shows the steps under its group with SLA details
 ----------------------------------------------------------------------------------------- 
 Version    Author      Date            Description
 -----------------------------------------------------------------------------------------
*******************************************************************************************/

public without sharing class ProgressIndicatorController {
    public string TemplateStepsList {
        get;
        set;
    }
    public string StageShortLabels {
        get;
        set;
    }
    public string CurrentOpenStep {
        get;
        set;
    }


    map < string, list < HexaBPM__SR_Steps__c >> MapSRSteps = new map < string, list < HexaBPM__SR_Steps__c >> ();
    map < string, list < HexaBPM__Step__c >> MapExistingSteps = new map < string, list < HexaBPM__Step__c >> ();
    @AuraEnabled public static string strTemplateId {
        get;
        set;
    }
    @AuraEnabled public static string strSRID {
        get;
        set;
    }
    public string SRStepDetails {
        get;
        set;
    }

    //@AuraEnabled public map<string,string> MapGroupData{get;set;}

    @AuraEnabled public static list < StepGroupWrap > lstGroupWrap {
        get;
        set;
    }
    @AuraEnabled public static string GroupWidth {
        get;
        set;
    }

    @AuraEnabled public static LtngStepGroupWrapper ltngStepGroupObj {
        get;
        set;
    }

    public class LtngStepGroupWrapper {
        @AuraEnabled public string totalTime {
            get;
            set;
        }
        @AuraEnabled public list < StepGroupWrap > lstLtngGroupWrapper {
            get;
            set;
        }
        @AuraEnabled public string estimatedHours {
            get;
            set;
        }
        @AuraEnabled public string srStatus {
            get;
            set;
        }
    }

    @AuraEnabled
    public static LtngStepGroupWrapper getStepGroupWrapper(string serviceRequestId) {
        Datetime submittedDateTime;
        string strSRStatus;
        if (serviceRequestId != null) {
            //strSRID = apexpages.currentPage().getParameters().get('Id');
            for (HexaBPM__Service_Request__c sr: [select id, HexaBPM__SR_Template__c, HexaBPM__Submitted_DateTime__c, HexaBPM__External_SR_Status__r.Name from HexaBPM__Service_Request__c where Id =: serviceRequestId]) {
                strTemplateId = sr.HexaBPM__SR_Template__c;
                submittedDateTime = sr.HexaBPM__Submitted_DateTime__c;
                strSRStatus = sr.HexaBPM__External_SR_Status__r.Name;
            }
        }
        Datetime currentDateTime = DateTime.now();
        ltngStepGroupObj = new LtngStepGroupWrapper();
        if (submittedDateTime != null) {
            Long seconds = (currentDateTime.getTime() - submittedDateTime.getTime()) / 1000;
            Long minutes = seconds / 60;
            Long hours = minutes / 60;
            Long days = hours / 24;
            ltngStepGroupObj.totalTime = hours > 24 ? String.valueOf(days) + ' day(s)' : String.valueOf(hours) + ' hour(s)';
        }
        ltngStepGroupObj.lstLtngGroupWrapper = PrepareGroups(serviceRequestId, strTemplateId);
        return ltngStepGroupObj;
    }
    @AuraEnabled
    public static list < StepGroupWrap > PrepareGroups(string serviceRequestId, string strTemplateIdVal) {
        lstGroupWrap = new list < StepGroupWrap > ();
        set<string> grpname_stepname = new set<string>();

        if (strTemplateIdVal != null && strTemplateIdVal != '') {
            StepGroupWrap objGrpWrap;
            map < string, integer > mapGroupIndex = new map < string, integer > ();
            map < string, list < HexaBPM__SR_Steps__c >> MapGroupSteps = new map < string, list < HexaBPM__SR_Steps__c >> ();
            //v1.0 
            for (HexaBPM__SR_Steps__c SRStp: [select Id, Name, HexaBPM__Step_Type__c, HexaBPM__Step_No__c, HexaBPM__Summary__c, 
                                                HexaBPM__Group_Name__c, HexaBPM__Step_Instructions__c, HexaBPM__Owner_Queue_Name__c,
                                                HexaBPM__SR_template__r.HexaBPM__Estimated_Hours__c,
                                                (select Id,HexaBPM__Parent_Step__r.HexaBPM__Step_Notes__c, HexaBPM__Step_Notes__c, Is_Client_Step__c, HexaBPM__SLA__c, HexaBPM__Status__r.Name, HexaBPM__Actual_Time_Taken_Mins__c, 
                                                HexaBPM__Closed_Date__c, HexaBPM__Status_Type__c, HexaBPM__SR_Step__c, //Actual_Business_Hours__c,
                                                HexaBPM__Sys_Step_Loop_No__c, HexaBPM__Summary__c, HexaBPM__SR__r.HexaBPM__Submitted_DateTime__c 
                                                from HexaBPM__Steps__r where HexaBPM__SR__c =: serviceRequestId order by createddate desc) from HexaBPM__SR_Steps__c where HexaBPM__SR_Template__c =: strTemplateIdVal and HexaBPM__Group_Name__c != null order by HexaBPM__Step_No__c]) {
                list < HexaBPM__SR_Steps__c > lstSRSteps = new list < HexaBPM__SR_Steps__c > ();
                if (MapGroupSteps.get(SRStp.HexaBPM__Group_Name__c) == null) {
                    objGrpWrap = new StepGroupWrap();
                    objGrpWrap.GroupLabel = SRStp.HexaBPM__Group_Name__c;
                    objGrpWrap.GroupShortLabel = string.valueOf(lstGroupWrap.size() + 1);
                    objGrpWrap.SLA = SRStp.HexaBPM__SR_template__r.HexaBPM__Estimated_Hours__c != null ? string.valueOf(SRStp.HexaBPM__SR_template__r.HexaBPM__Estimated_Hours__c) + ' hour(s)' : '0';
                    lstGroupWrap.add(objGrpWrap);
                } else {
                    lstSRSteps = MapGroupSteps.get(SRStp.HexaBPM__Group_Name__c);
                }
                lstSRSteps.add(SRStp);
                MapGroupSteps.put(SRStp.HexaBPM__Group_Name__c, lstSRSteps);
            }
            if (lstGroupWrap != null && lstGroupWrap.size() > 0 && MapGroupSteps != null && MapGroupSteps.size() > 0) {
                for (StepGroupWrap SGW: lstGroupWrap) {
                    list < StepGroupChildData > lstChilds = new list < StepGroupChildData > ();
                    for (HexaBPM__SR_Steps__c SRStep: MapGroupSteps.get(SGW.GroupLabel)) {
                        if (SRStep.HexaBPM__Steps__r != null && SRStep.HexaBPM__Steps__r.size() > 0) {
                            for (HexaBPM__Step__c stp: SRStep.HexaBPM__Steps__r) {

                                //if(!grpname_stepname.contains(stp.Group_Name__c + '_' + stp.HexaBPM__Summary__c)){

                                    StepGroupChildData CD = new StepGroupChildData();
                                    CD.hasStep = true;
                                    CD.clientstep = stp.Is_Client_Step__c;
                                    if (SRStep.HexaBPM__Step_Type__c != null && SRStep.HexaBPM__Step_Type__c == 'Document Check')
                                        CD.DocumentCheckStep = true;
                                    else if (SRStep.HexaBPM__Step_Type__c != null && SRStep.HexaBPM__Step_Type__c == 'Quick Action')
                                        CD.QuickActionStep = true;
                                    CD.StepSummary = stp.HexaBPM__Summary__c;
                                    CD.StepId = stp.Id;
                                    CD.status = stp.HexaBPM__Status__r.Name;
                                    CD.ActionType = SRStep.HexaBPM__Step_Type__c;
                                    CD.SRID = stp.HexaBPM__SR__c;
                                    CD.StepLoop = stp.HexaBPM__Sys_Step_Loop_No__c;
                                    if(stp.HexaBPM__Step_Notes__c!=null)//v1.0 
                                        CD.stpNotes = stp.HexaBPM__Step_Notes__c;
                                    else if(stp.HexaBPM__Parent_Step__r.HexaBPM__Step_Notes__c!=null)//v1.0 
                                        CD.stpNotes = stp.HexaBPM__Parent_Step__r.HexaBPM__Step_Notes__c;
                                    else
                                        CD.stpNotes = '';
                                    //string stpnotes = stp.HexaBPM__Step_Notes__c <> null ? ' (Action Item Notes- ' + stp.HexaBPM__Step_Notes__c + ')' : '';
                                    CD.helpText = SRStep.HexaBPM__Step_Instructions__c; // + stpnotes;
                                    if (stp.HexaBPM__Status_Type__c != 'End') {
                                        SGW.CurrentGroup = true;
                                        CD.IsOpen = true;
                                    } else if (stp.HexaBPM__Status_Type__c == 'End') {
                                        CD.IsClosed = true;
                                    }
                                    if (stp.HexaBPM__Actual_Time_Taken_Mins__c != null && stp.HexaBPM__Actual_Time_Taken_Mins__c > 59) //Consider only hours, ignoring minutes
                                    {
                                        decimal actualTimeInMins = stp.HexaBPM__Actual_Time_Taken_Mins__c / 60;
                                        
                                        if(actualTimeInMins >= 24)
                                            CD.SLA = string.valueOf(math.floor(actualTimeInMins/24)) + ' day(s)';
                                        else
                                            CD.SLA = string.valueOf(math.floor(actualTimeInMins)) + ' hour(s)';
                                        
                                        
                                        //CD.SLA = string.valueOf(stp.Actual_Business_Hours__c) + ' hour(s)';
                                    }
                                    /*
                                        if(stp.SLA__c!=null && stp.SLA__c>0)
                                        CD.SLA = stp.SLA__c+' hours';
                                        */
                                    lstChilds.add(CD);
                                    //grpname_stepname.add(stp.Group_Name__c + '_' + stp.HexaBPM__Summary__c);
                                //}


                            }
                        } else {
                            StepGroupChildData CD = new StepGroupChildData();
                            SGW.Passed_Group = false;
                            CD.hasStep = false;
                            CD.StepSummary = SRStep.HexaBPM__Summary__c;
                            if(SRStep.HexaBPM__Owner_Queue_Name__c <> null && SRStep.HexaBPM__Owner_Queue_Name__c.containsignorecase('client'))
                            CD.clientstep = true;

                            lstChilds.add(CD);
                        }
                    }
                    SGW.lstChilds = lstChilds;
                }
            }
            system.debug('lstGroupWrap===>' + lstGroupWrap);
            if (lstGroupWrap != null && lstGroupWrap.size() > 0)
                GroupWidth = (100 / lstGroupWrap.size()) + '%';
            system.debug('GroupWidth===>' + GroupWidth);

        }
        return lstGroupWrap;
    }


    public class StepGroupWrap {
        @AuraEnabled public string GroupLabel {
            get;
            set;
        }
        @AuraEnabled public string GroupShortLabel {
            get;
            set;
        }
        @AuraEnabled public boolean CurrentGroup {
            get;
            set;
        }
        @AuraEnabled public boolean Passed_Group {
            get;
            set;
        }
        @AuraEnabled public list < StepGroupChildData > lstChilds {
            get;
            set;
        }
        @AuraEnabled public string SLA {
            get;
            set;
        }

        public StepGroupWrap() {
            lstChilds = new list < StepGroupChildData > ();
            CurrentGroup = false;
            Passed_Group = true;
        }
    }
    public class StepGroupChildData {
        @AuraEnabled public string StepSummary {
            get;
            set;
        }
        @AuraEnabled public string StepId {
            get;
            set;
        }
        @AuraEnabled public string StepLoop {
            get;
            set;
        }
        @AuraEnabled public boolean hasStep {
            get;
            set;
        }
        @AuraEnabled public boolean IsOpen {
            get;
            set;
        }
        @AuraEnabled public boolean IsClosed {
            get;
            set;
        }
        @AuraEnabled public string helpText {
            get;
            set;
        }
        @AuraEnabled public string SLA {
            get;
            set;
        }
        @AuraEnabled public string ActionType {
            get;
            set;
        }
        @AuraEnabled public string SRID {
            get;
            set;
        }
        @AuraEnabled public boolean QuickActionStep {
            get;
            set;
        }
        @AuraEnabled public boolean DocumentCheckStep {
            get;
            set;
        }
        @AuraEnabled public string status {
            get;
            set;
        }
        @AuraEnabled public string stpNotes {
            get;
            set;
        }
        @AuraEnabled public boolean clientstep {
            get;
            set;
        }
        public StepGroupChildData() {
            IsOpen = false;
            IsClosed = false;
            DocumentCheckStep = false;
            QuickActionStep = false;
            clientstep = false;
            ActionType = '';
            status='';
        }
    }
}