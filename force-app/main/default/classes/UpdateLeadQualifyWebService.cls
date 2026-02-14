@RestResource (urlMapping = '/update/lead/status/qualify')
global with sharing class UpdateLeadQualifyWebService 
{
    @HttpPost
    global static void doPost(Task taskRecord, String	CustomerLocation,    String leadRecordId,   String unitType,     String numberOfBedrooms, 
                              String customerBudget,String purposeOfUse,   String financeRequired, Boolean qualificationNeeded)
    {   
        RestContextHandler handler = new RestContextHandler(true);
        try
        {
            List<Lead> toBeUpdatedLeadList     = new List<Lead>();
            List<Task> taskCreatedList       = new List<Task>();
            Lead toBeUpdatedLead         = new Lead();
            
            if (taskRecord.Id != Null && String.isNotBlank(taskRecord.Id)) {
                update taskRecord;
            }
            else if (qualificationNeeded == true ){
                Task task             = new Task();
                task.Subject          = 'Autodialler Qualified';
                task.whoId            = leadRecordId != null ? leadRecordId : '';
                task.ActivityDate         = Date.today();
                task.Priority          = 'Normal';
                task.Status            = 'Completed';
                task.AgentActivityHistory__c   = true;
                task.CustomerResponse__c     = taskRecord.CustomerResponse__c;
                taskCreatedList.add(task);
            }
            
            
            if(String.isNotBlank(leadRecordId) && leadRecordId != null && leadRecordId != '')
            {
                toBeUpdatedLead.Id = leadRecordId;
                
                if(String.isNotBlank(unitType) && unitType != null && unitType != ''){
                    toBeUpdatedLead.UnitType__c = unitType;
                }
                if(String.isNotBlank(numberOfBedrooms) && numberOfBedrooms != null && numberOfBedrooms != ''){
                    toBeUpdatedLead.NumberOfBedrooms__c = numberOfBedrooms;
                }
                if(String.isNotBlank(customerBudget) && customerBudget != null && customerBudget != ''){
                    toBeUpdatedLead.CustomerBudget__c = customerBudget;
                }
                if(String.isNotBlank(purposeOfUse) && purposeOfUse != null && purposeOfUse != ''){
                    toBeUpdatedLead.PurposeOfUse__c = purposeOfUse;
                }
                if(String.isNotBlank(financeRequired) && financeRequired != null && financeRequired != ''){
                    toBeUpdatedLead.Financing__c = financeRequired;
                }
                
                if(String.isNotBlank(CustomerLocation) && CustomerLocation != null && CustomerLocation != ''){
                    toBeUpdatedLead.CustomerLocation__c = CustomerLocation;
                }
                
                if(qualificationNeeded != null && qualificationNeeded){
                    toBeUpdatedLead.AssignToRoundRobin__c = true;
                    toBeUpdatedLead.Status = 'Qualified Lead';
                }
                
                toBeUpdatedLeadList.add(toBeUpdatedLead);
            }
            
            if(!taskCreatedList.isEmpty()){
                Insert taskCreatedList;
            }
            
            if(!toBeUpdatedLeadList.isEmpty()){
                update toBeUpdatedLeadList;
                handler.response.message = 'Record Updated Successfully';
                handler.response.success = true;
                handler.response.data    = toBeUpdatedLeadList ;
                handler.finalize();
            }
        }
        catch (DMLException exc){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = exc.getDMLMessage(0);
            handler.finalize(exc);
        }
        catch(Exception ex){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            //handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.response.message = ex.getStackTraceString() + ex.getMessage();
            handler.finalize(ex);
        }
    }
    
    
}