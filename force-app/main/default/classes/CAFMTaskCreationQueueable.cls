/***
Class       : CAFMTaskCreationQueueable
Author      : Smaartt
Description : This class is calling from cls-CAFMCalloutToMuleSoft
TestClass   : CAFMCalloutToMuleSoftTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details       
1.       V1.0              13/11/24           Initial Version 
****************************************************************************************************************/
public class CAFMTaskCreationQueueable implements Queueable, Database.AllowsCallouts{
    private List<Id> lstIds;
    private Integer counter;
    public CAFMTaskCreationQueueable(List<Id> lstIds,Integer cnt){
        this.counter = cnt;
        this.lstIds = lstIds;
    }
    public void execute(QueueableContext context) {        
        makeCallout(lstIds[counter]);         
        counter++;
        if(counter < lstIds.size()){
            System.enqueueJob(new CAFMTaskCreationQueueable(lstIds, counter));   
        }
    }
    @auraEnabled
    public static void makeCallout(string recId){
        Id cafmRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(Label.CAFMRecordType).getRecordTypeId();
       
        List<case> caseList = [SELECT Id, RecordTypeId, SuppliedName, SuppliedEmail, SuppliedPhone, Status, Type, Priority, Source__c,
                               Subject, Description, Category__c, Task_Number__c, Task_ID__c,Task_Discipline__c, Problem__c, 
                               Task_LOC__c, SLA_Completion_Date__c, SLA_Attended_Date__c, SLA_Performance_Attend_Date__c, 
                               SLA_Contain_Date__c, SLA_Performance_Contain_Date__c, SLA_Fix_Date__c, SLA_Performance_Fix_Date__c, Building_Location__r.External_Location_Id__c,
                               Integration_Status__c,Building_Name__r.Contract_Id__c,  Building_Name__r.External_Id__c
                               FROM Case 
                               WHERE Task_Number__c = null AND RecordTypeId = :cafmRecordTypeId AND Id=:recId];      
        if(caseList.size()>0){
            case caseRecord = caseList[0];
            List<Case> casesToUpdate = new List<Case>();
            List<Logger__c> logsToUpdate = new List<Logger__c>();
            String muleRes = '';
            String requestBody = '';
            
            try {
                // Prepare JSON payload
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                gen.writeStringField('Id', caseRecord.Id != null?caseRecord.Id:'');
                gen.writeStringField('SuppliedName', caseRecord.SuppliedName != null?caseRecord.SuppliedName:'');
                gen.writeStringField('SuppliedEmail', caseRecord.SuppliedEmail != null?caseRecord.SuppliedEmail:'');
                gen.writeStringField('SuppliedPhone', caseRecord.SuppliedPhone != null?caseRecord.SuppliedPhone:'');
                gen.writeStringField('Type', caseRecord.Type != null?caseRecord.Type:'');
                gen.writeStringField('Status', 'Assigned');
                gen.writeStringField('Priority', caseRecord.Priority != null?caseRecord.Priority:'');
                gen.writeStringField('Subject', caseRecord.Subject != null?caseRecord.Subject:'');
                gen.writeStringField('Description', caseRecord.Description != null?caseRecord.Description:'');
                gen.writeStringField('Category__c', caseRecord.Category__c != null?caseRecord.Category__c:'');
                gen.writeStringField('Contract__c', caseRecord.Building_Name__r.Contract_Id__c != null?caseRecord.Building_Name__r.Contract_Id__c:'');
                gen.writeStringField('Building_Location__c', caseRecord.Building_Location__r.External_Location_Id__c != null?caseRecord.Building_Location__r.External_Location_Id__c.split('_')[0]:'');
                gen.writeStringField('Building_Name__c', caseRecord.Building_Name__r.External_Id__c != null?caseRecord.Building_Name__r.External_Id__c.substringBefore('_'):'');
                gen.writeStringField('Problem__c', caseRecord.Problem__c != null?caseRecord.Problem__c:'');
                gen.writeStringField('Task_Discipline__c', caseRecord.Task_Discipline__c != null?caseRecord.Task_Discipline__c:'');
                gen.writeStringField('Task_LOC__c', caseRecord.Task_LOC__c != null?caseRecord.Task_LOC__c:'');
                gen.writeEndObject();
                system.debug('Jsongen=='+gen); 
                requestBody = gen.getAsString();
                system.debug('requestbody='+requestBody);
                HttpResponse response = DM_UtilityController.makeCallout('CAFMTask', requestBody);
                muleRes = response.getBody();
                system.debug('Mulesresponse=='+muleRes);
                
                if(response.getStatusCode() == 200 && response.getBody() != null) {
                    CAFM_MuleResWrapper wrapresp = CAFM_MuleResWrapper.parse(response.getBody());
                    system.debug('wrapresp=='+wrapresp);
                    CAFM_MuleResWrapper.cls_CreateBreakdownTaskResult task = wrapresp.results.CreateBreakdownTaskResponse.CreateBreakdownTaskResult;
                    caseRecord.Task_Number__c = task.TaskId;
                    caseRecord.Task_ID__c= task.Code;
                    caseRecord.Status='Assigned';
                    if(!task.TaskPerfSLAAttendDate.contains('0001-01-01')){
                       caseRecord.SLA_Attended_Date__c= (DateTime)JSON.deserialize('"' + task.TaskPerfSLAAttendDate + '"', DateTime.class);
                    }
                    if(!task.TaskPerfSLAFixDate.contains('0001-01-01')){
                       caseRecord.SLA_Fix_Date__c = (DateTime)JSON.deserialize('"' + task.TaskPerfSLAFixDate + '"', DateTime.class);
                    }
                    caseRecord.Integration_Status__c = 'Synced';
                    casesToUpdate.add(caseRecord);
                    system.debug('casesToUpdate=='+casesToUpdate);
                } else {               
                    
                    Logger__c log = LoggerService.addApexServiceCalls('CAFMTaskCreationQueueable', 'makeCallout', 'CAFMTask', requestBody, muleRes, caseRecord.Id);
                    log.Case__c = caseRecord.Id;
                    logsToUpdate.add(log);               
                    caseRecord.Integration_Status__c = 'Failed';
                    casesToUpdate.add(caseRecord);     
                }
                
            } catch (Exception e) {
                System.debug('Error in code: ' + e.getMessage());
                Logger__c log = LoggerService.addApexServiceCallsLog(e, 'CAFMTaskCreationQueueable', 'makeCallout', 'CAFMTask', (requestBody.length() < 131072 ? requestBody : ''), muleRes);
                if(caseRecord.Id !=null)
                    log.Case__c = caseRecord.Id;
                logsToUpdate.add(log);
            }
            if(!casesToUpdate.isEmpty()) {
                update casesToUpdate;
            }
            if(!logsToUpdate.isEmpty()) {
                insert logsToUpdate;
            }
        }
    }
}