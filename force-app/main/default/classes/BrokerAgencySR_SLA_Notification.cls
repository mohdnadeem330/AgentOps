/*
****************************************************************************************
Apex Class Name    : BrokerAgencySR_SLA_Notification
Created Date       : 09-09-2024
@description       : This is class is use to Notify Brokers and Broker Managers
@author            : Moh Sarfaraj
Modification Log:
Ver   Date              Author                               Modification
1.0   09-09-2024      Moh Sarfaraj                          Initial Version
*****************************************************************************************
*/
public class BrokerAgencySR_SLA_Notification implements Database.Batchable<SObject>, Schedulable, Database.Stateful {
    /* Note: first reminder will send via StepTriggerHandler at the time of Record Creation by this class, from 2nd and onwards will send by this schedule batch;
     for First Reminders we are using this batch class as utility class. */

    List<String> listDigitalSignSLA; // 0,5,12,13,14 days
    List<String> listRequireMoreInfoSLA; // 0,8,12,29,30 days
    List<HexaBPM__SR_Status__c> listCloseStatus;
    OrgWideEmailAddress owea;
    Map<String,EmailTemplate> mapNameToEmailTemplate = new Map<String,EmailTemplate>(); 
    Map<Id,Contact> mapAgencyIdToAgencyAdmin = new Map<Id,Contact>();
    Set<Id> setExternalServiceRequestIds = new Set<Id>();
    final Set<String> stepNameForAgencies = new Set<String>{'digital signature by authorized signatory', 'require more information'};
    final Set<String> stepNameForBrokerAdmins = new Set<String>{'assignment of broker manager','validation by sales admin','digital signature by head of broker management'};
    Map<String,List<String>> mapStepNameToListSLADays = new Map<String,List<String>>();
    Map<String,String> mapStepNameToEmailTemplateName = new Map<String,String>();
    Map<Id,List<HexaBPM__Step__c>> mapBrokerAdminIdToListPendingSteps = new Map<Id,List<HexaBPM__Step__c>>();
    Map<Id,List<HexaBPM__Step__c>> mapOwnerQueueIdToListPendingSteps = new Map<Id,List<HexaBPM__Step__c>>();
    Map<String,String> mapStepStatusRecords = new Map<String,String>();
    static Id SR_AGENCY_REGISTRATION_RecordTypeId = Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByDeveloperName().get('AgencyRegistration').getRecordTypeId();

    // Scheduleable method
    public void execute(SchedulableContext sc){
        Database.executeBatch(new BrokerAgencySR_SLA_Notification(null));
    }

    // Class constructor
    public BrokerAgencySR_SLA_Notification(Set<Id> setExternalServiceRequestIds){
        this.setExternalServiceRequestIds = setExternalServiceRequestIds;
        Set<String> setTemplateName = new Set<String> {'RequireMoreInfoSLA1', 'RequireMoreInfoSLA2','RequireMoreInfoSLA3', 'RequireMoreInfoSLA4','RequireMoreInfoSLA5',
                                                       'DigitalSignatureSLA1', 'DigitalSignatureSLA2', 'DigitalSignatureSLA3', 'DigitalSignatureSLA4','DigitalSignatureSLA5'};
        listDigitalSignSLA = new List<String>(System.Label.BPM_NotifyBrokersforDigitalSignatureSLA.split(','));
        listRequireMoreInfoSLA = new List<String>(System.Label.BPM_NotifyBrokersforRequireMoreInfoSLA.split(','));

        mapStepNameToListSLADays.put('digital signature by authorized signatory', listDigitalSignSLA);
        mapStepNameToListSLADays.put('require more information', listRequireMoreInfoSLA);
        mapStepNameToListSLADays.put('assignment of broker manager', new List<String>{});
        mapStepNameToListSLADays.put('validation by sales admin', new List<String>{});
        //mapStepNameToListSLADays.put('digital signature by head of broker management', new List<String>{});

        mapStepNameToEmailTemplateName.put('digital signature by authorized signatory', 'DigitalSignatureSLA');
        mapStepNameToEmailTemplateName.put('require more information', 'RequireMoreInfoSLA');
        mapStepNameToEmailTemplateName.put('assignment of broker manager', 'DigitalSignatureSLA');
        mapStepNameToEmailTemplateName.put('validation by sales admin', 'RequireMoreInfoSLA');
        //mapStepNameToEmailTemplateName.put('digital signature by head of broker management', 'DigitalSignatureSLA');
        
        owea = new OrgWideEmailAddress();
        listCloseStatus = new List<HexaBPM__SR_Status__c>();
        listCloseStatus = [SELECT Id FROM HexaBPM__SR_Status__c WHERE Name = 'Closed' LIMIT 1];
        owea = [SELECT Id,Address,DisplayName FROM OrgWideEmailAddress WHERE DisplayName='Aldar Agency Support'];
        
        for(EmailTemplate eachEmailTemplate : [SELECT Id,Subject,HtmlValue,DeveloperName FROM EmailTemplate WHERE 
                                               DeveloperName IN :setTemplateName]){

            mapNameToEmailTemplate.put(eachEmailTemplate.DeveloperName, eachEmailTemplate);
        } 
    }

    // Batchable method
    public List<HexaBPM__Step__c> start(Database.BatchableContext bc){
        List<HexaBPM__Step__c> listSteps = new List<HexaBPM__Step__c>();
        try{
            Set<Id> setAccountIds = new Set<Id>();
            if(setExternalServiceRequestIds != null && !setExternalServiceRequestIds.isEmpty()){
                listSteps = [SELECT Id, Name,HexaBPM__Start_Date__c,HexaBPM__Due_Date__c,SLAExtensionInHours__c, HexaBPM__Summary__c, 
                            HexaBPM__SR__c, Account__c, HexaBPM__Step_No__c,HexaBPM__Step_Status__c, HexaBPM__Step_Template__c,CreatedDate,
                            OwnerId,Owner.Name,Owner.Email,HexaBPM__SR__r.Name,HexaBPM__SR__r.CompanyEmail__c,HexaBPM__SR__r.HexaBPM__Customer__c,Sent_Reminders__c
                            FROM HexaBPM__Step__c WHERE 
                            HexaBPM__SR__r.RecordTypeId = :SR_AGENCY_REGISTRATION_RecordTypeId AND
                            HexaBPM__SR__r.HexaBPM__SR_Template__r.Name = 'Agency Registration' AND 
                            HexaBPM__SR__r.HexaBPM__External_Status_Name__c NOT IN ('Closed', 'Completed', 'Rejected', 'Cancelled') AND
                            HexaBPM__Step_Status__c IN ('Pending', 'Pending Review') AND
                            HexaBPM__SR__c IN :setExternalServiceRequestIds];
            }else{
                listSteps = [SELECT Id, Name,HexaBPM__Start_Date__c,HexaBPM__Due_Date__c,SLAExtensionInHours__c, HexaBPM__Summary__c, 
                            HexaBPM__SR__c, Account__c, HexaBPM__Step_No__c,HexaBPM__Step_Status__c, HexaBPM__Step_Template__c,CreatedDate,
                            OwnerId,Owner.Name,Owner.Email,HexaBPM__SR__r.Name,HexaBPM__SR__r.CompanyEmail__c,HexaBPM__SR__r.HexaBPM__Customer__c,Sent_Reminders__c
                            FROM HexaBPM__Step__c WHERE 
                            HexaBPM__SR__r.RecordTypeId = :SR_AGENCY_REGISTRATION_RecordTypeId AND
                            HexaBPM__SR__r.HexaBPM__SR_Template__r.Name = 'Agency Registration' AND 
                            HexaBPM__SR__r.HexaBPM__External_Status_Name__c NOT IN ('Closed', 'Completed', 'Rejected', 'Cancelled') AND
                            HexaBPM__Step_Status__c IN ('Pending', 'Pending Review')];
            }
            
            if(!listSteps.isEmpty()){
                for(HexaBPM__Step__c eachStep : listSteps){
                    if(String.isNotBlank(eachStep?.HexaBPM__SR__r?.HexaBPM__Customer__c)){
                        setAccountIds.add(eachStep?.HexaBPM__SR__r?.HexaBPM__Customer__c);
                    }
                }
                Map<Id,Contact> mapAccountIdToContact = new Map<Id,Contact>();
                for(Contact eachContact : [SELECT Id,Name,StepNotes__c,AccountId,PrimaryAgencyAdmin__c
                                        FROM Contact WHERE Account.RecordTypeId = :Constants.BROKER_AGENCY_RECORD_TYPE_ID AND
                                        RecordTypeId = : ALD_Constants.BROKER_AGENT_RT AND
                                        BrokerType__c = 'Agency Admin' AND AccountId IN :setAccountIds ORDER BY LastModifiedDate DESC]){
                    
                    if(mapAgencyIdToAgencyAdmin.containsKey(eachContact.AccountId)){
                        if(eachContact.PrimaryAgencyAdmin__c && !mapAgencyIdToAgencyAdmin.get(eachContact.AccountId).PrimaryAgencyAdmin__c){
                            mapAgencyIdToAgencyAdmin.put(eachContact.AccountId, eachContact);
                        }
                    }else{
                        mapAgencyIdToAgencyAdmin.put(eachContact.AccountId, eachContact);
                    }
                }

                for(HexaBPM__Status__c eachStepStatus : [SELECT Id, Name FROM HexaBPM__Status__c WHERE Name = 'Closed']){
                    mapStepStatusRecords.put(eachStepStatus.Name, eachStepStatus.Id);
                }
            }
            return listSteps;
        }catch(Exception e){StepTriggerHandler.createLogs(e, 'BrokerAgencySR_SLA_Notification', 'start method', new List<String>(), listSteps);}
        return null;
    }

    // Batchable method
    public void execute(Database.BatchableContext bc, List<HexaBPM__Step__c> listSteps){
        List<HexaBPM__Service_Request__c> listSRtoUpdateClose = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Step__c> listStepsToUpdate = new List<HexaBPM__Step__c>();
        List<Account> listAccountToUpdateClosed = new List<Account>();

        try{
            for(HexaBPM__Step__c eachStep : listSteps){
                // calculate mintues also later
                String summary = eachStep?.HexaBPM__Summary__c?.toLowerCase();
                if(String.isNotBlank(summary) && mapStepNameToListSLADays.containsKey(summary)){
                    List<String> listSLADays = mapStepNameToListSLADays?.get(summary);
                    String templateName = mapStepNameToEmailTemplateName?.get(summary);

                    if(String.isNotBlank(templateName)){
                        //Closing Step, SR and Account. 
                        if(System.now() >= eachStep?.HexaBPM__Due_Date__c){
                            // Time over for Agencies go to mark closed, sending last intimate to Broker/ Agency (External ONLY)
                            if(stepNameForAgencies.contains(summary)){
                                String stepSummary = templateName + listSLADays.size();

                                listStepsToUpdate.add(constructBreachData(eachStep, listSRtoUpdateClose, listAccountToUpdateClosed, listSLADays.size()));
                            
                                // Launch flow for Email Alert
                                Map<String, Object> inputs = new Map<String, Object>();
                                inputs.put('templateName', stepSummary);
                                inputs.put('contact', mapAgencyIdToAgencyAdmin.get(eachStep?.HexaBPM__SR__r?.HexaBPM__Customer__c));
                                inputs.put('isExternal', true);
                                
                                Flow.Interview.StepNotificationFlow myFlow = new Flow.Interview.StepNotificationFlow(inputs);
                                myFlow.start();
                            }
                            // Time over for Broker Admin, sending List intimates to brokers of all SR Steps
                            // this logic is for Internal Broker Admins/ Managers ONLY (Internal ONLY)
                            else if(stepNameForBrokerAdmins.contains(summary)){
                                if(eachStep.OwnerId.getSObjectType() == User.SObjectType) {
                                    // Owner is a user
                                    if(!mapBrokerAdminIdToListPendingSteps.containsKey(eachStep.OwnerId)){
                                        mapBrokerAdminIdToListPendingSteps.put(eachStep.OwnerId, new List<HexaBPM__Step__c>{eachStep});
                                    }
                                    mapBrokerAdminIdToListPendingSteps.get(eachStep.OwnerId).add(eachStep);
                                } else if(eachStep.OwnerId.getSobjectType() == Group.SObjectType) {
                                    // Owner is a group
                                    if(!mapOwnerQueueIdToListPendingSteps.containsKey(eachStep.OwnerId)){
                                        mapOwnerQueueIdToListPendingSteps.put(eachStep.OwnerId, new List<HexaBPM__Step__c>{eachStep});
                                    }
                                    mapOwnerQueueIdToListPendingSteps.get(eachStep.OwnerId).add(eachStep);
                                }
                            }
                        } // (External ONLY)
                        else if(listSLADays?.size() != 0 && 
                                System.today() != Date.valueOf(eachStep?.HexaBPM__Due_Date__c).addDays(-1) && 
                                System.today() >= Date.valueOf(eachStep?.HexaBPM__Start_Date__c?.addDays(Integer.valueOf(listSLADays[listSLADays?.size() - 1])))){
                            // close SR on 30th or 14th day for Agencies go to mark closed, sending last intimate
                            Date generatedSLADate = Date.valueOf(eachStep?.HexaBPM__Start_Date__c?.addDays(Integer.valueOf(listSLADays[listSLADays?.size() - 1])));
                            Date greaterDateValue = Date.valueOf(eachStep?.HexaBPM__Due_Date__c) >  generatedSLADate ? Date.valueOf(eachStep?.HexaBPM__Due_Date__c) : generatedSLADate;

                            if(System.today() >= greaterDateValue && stepNameForAgencies.contains(summary)){
                                String stepSummary = templateName + listSLADays.size(); //? 'DigitalSignatureSLA'+(listDigitalSignSLA?.size()) : 'RequireMoreInfoSLA'+(listRequireMoreInfoSLA?.size());

                                listStepsToUpdate.add(constructBreachData(eachStep, listSRtoUpdateClose, listAccountToUpdateClosed, listSLADays?.size()));

                                // Launch flow for Email Alert
                                Map<String, Object> inputs = new Map<String, Object>();
                                inputs.put('templateName', stepSummary);
                                inputs.put('contact', mapAgencyIdToAgencyAdmin.get(eachStep?.HexaBPM__SR__r?.HexaBPM__Customer__c));
                                inputs.put('isExternal', true);
                                
                                Flow.Interview.StepNotificationFlow myFlow = new Flow.Interview.StepNotificationFlow(inputs);
                                myFlow.start();
                            }
                        }
                        // Notifiy Broker/ Agency from 1st to second last value of SLA days Custom label (External ONLY)
                        else if(listSLADays?.size() != 0  && stepNameForAgencies.contains(summary)){
                            Set<Id> setProcessedStepIds = new Set<Id>();

                            for(Integer i=0;i<=listSLADays.size()-2; i++){
                                DateTime sentReminderDate = Date.valueOf(eachStep.HexaBPM__Start_Date__c.addDays(Integer.valueOf(listSLADays[i])));
                                // Sending final intimation 1 day before the blocked after given extension
                                if(i == listSLADays.size()-2){
                                    sentReminderDate = Date.valueOf(eachStep?.HexaBPM__Due_Date__c).addDays(-1);
                                }
                                
                                if(System.today() == sentReminderDate){
                                    if(!setProcessedStepIds.contains(eachStep.Id)){
                                        eachStep.Sent_Reminders__c = String.valueOf((i + 1));
                                        listStepsToUpdate.add(eachStep);
                                        
                                        // Launch flow for Email Alert 
                                        Map<String, Object> inputs = new Map<String, Object>();
                                        inputs.put('templateName', templateName + (i + 1));
                                        inputs.put('contact', mapAgencyIdToAgencyAdmin.get(eachStep?.HexaBPM__SR__r?.HexaBPM__Customer__c));
                                        inputs.put('isExternal', true);
                                        
                                        Flow.Interview.StepNotificationFlow myFlow = new Flow.Interview.StepNotificationFlow(inputs);
                                        myFlow.start();
                                        setProcessedStepIds.add(eachStep.Id);
                                    }
                                }   
                            }
                        }
                    }
                }
            }
            // This logic is for sending last intimate to Broker/ Agency start
            if(!listSRtoUpdateClose.isEmpty()){
                update listSRtoUpdateClose;
            }
            if(!listAccountToUpdateClosed.isEmpty()){
                update listAccountToUpdateClosed;
            }
            if(!listStepsToUpdate.isEmpty()){
                update listStepsToUpdate;
            }
            // This logic is for sending last intimate to Broker/ Agency end
            
            // This logic is for Internal Broker Admins/ Managers ONLY (Internal ONLY)
            if(!mapOwnerQueueIdToListPendingSteps.isEmpty()){
                Map<Id,List<Id>> mapQueueIdToListUserIds = new Map<Id,List<Id>>();
                for(GroupMember gm : [SELECT UserOrGroupId,GroupId FROM GroupMember WHERE GroupId IN :mapOwnerQueueIdToListPendingSteps.keySet()]){
                    if(!mapQueueIdToListUserIds.containsKey(gm.GroupId)){
                        mapQueueIdToListUserIds.put(gm.GroupId, new List<Id>{gm.UserOrGroupId});
                    }
                    mapQueueIdToListUserIds.get(gm.GroupId).add(gm.UserOrGroupId);
                }

                for(Id queueId : mapOwnerQueueIdToListPendingSteps.keySet()){
                    if(mapQueueIdToListUserIds.containsKey(queueId) && mapQueueIdToListUserIds.get(queueId) != null && !mapQueueIdToListUserIds.get(queueId).isEmpty()){
                        for(Id userId : mapQueueIdToListUserIds.get(queueId)){
                            if(!mapBrokerAdminIdToListPendingSteps.containsKey(userId)){
                                mapBrokerAdminIdToListPendingSteps.put(userId, mapOwnerQueueIdToListPendingSteps.get(queueId));
                            }
                            mapBrokerAdminIdToListPendingSteps.get(userId).addAll(mapOwnerQueueIdToListPendingSteps.get(queueId));
                        }
                    }
                }
            }
        }catch(Exception e){StepTriggerHandler.createLogs(e, 'BrokerAgencySR_SLA_Notification', 'execute method', new List<String>(), listSteps);}
    }
    
    // Batchable method
    public void finish(Database.BatchableContext bc){
        // BROKER MANAGER Notification Internal ONLY
        List<User> listUsersToNotified = new List<User>();
        try{
            for(User eachUser : [SELECT Id,Name,Email,Manager.ManagerId,Manager.Email FROM User WHERE isActive = true AND Id IN : mapBrokerAdminIdToListPendingSteps.keySet()]){
                Map<String, Object> inputs = new Map<String, Object>();
                inputs.put('isExternal', false); inputs.put('userId', eachUser.id);
                Flow.Interview.StepNotificationFlow myFlow = new Flow.Interview.StepNotificationFlow(inputs);
                myFlow.start();
            }
        }catch(Exception e){StepTriggerHandler.createLogs(e, 'BrokerAgencySR_SLA_Notification', 'start method', new List<String>(), listUsersToNotified);}
    }

    private HexaBPM__Step__c constructBreachData(HexaBPM__Step__c eachStep,
                                                 List<HexaBPM__Service_Request__c> listSRtoUpdateClose, 
                                                 List<Account> listAccountToUpdateClosed, 
                                                 Integer reminder){
                    
        listSRtoUpdateClose.add(new HexaBPM__Service_Request__c(
            Id = eachStep.HexaBPM__SR__c, 
            HexaBPM__External_SR_Status__c = listCloseStatus[0]?.Id
        ));

        listAccountToUpdateClosed.add(new Account(
            Id = eachStep?.HexaBPM__SR__r?.HexaBPM__Customer__c, 
            AgencyStatus__c = 'Closed')
        );

        eachStep.Sent_Reminders__c = String.valueOf(reminder);
        if(mapStepStatusRecords.containsKey('Closed')){
            eachStep.HexaBPM__Status__c = mapStepStatusRecords.get('Closed');
        }
        return eachStep;
    }
}