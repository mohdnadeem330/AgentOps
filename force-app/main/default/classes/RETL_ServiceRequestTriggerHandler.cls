public class RETL_ServiceRequestTriggerHandler {
    private List<RETL_Service_Request__c> newRecords;
    private Map<Id, RETL_Service_Request__c> oldMap;
    private Boolean isUpdate;
    
    // List of all Contractual Fields (RETL_Contr) API names
    private static final List<String> CONTRACTUAL_FIELDS = new List<String>{
        'RETL_Contr_Kick_Off_Meeting_b_a__c',
        'RETL_Contr_Kick_Off_Meeting__c',
        'RETL_Contr_Concept_Design_Submission_b_a__c',
        'RETL_Contr_Concept_Design_Submission__c',
        'RETL_Contr_Detailed_Arch_MEP_Design_b_a__c',
        'RETL_Contr_Detailed_Arch_MEP_Design__c',
        'RETL_Contr_Authorities_Submission_b_a__c',
        'RETL_Contr_Authorities_Submission__c',
        'RETL_Contr_Start_onsite_b_a__c',
        'RETL_Contr_Start_onsite__c'
    };
    // List of all Actual Fields (RETL_Actual) API names
    private static final List<String> ACTUAL_FIELDS = new List<String>{
        'RETL_Actual_Kick_Off_Meeting_b_a__c',
        'RETL_Actual_Kick_Off_Meeting__c',
        'RETL_Actual_Concept_Design_Submission_ba__c',
        'RETL_Actual_Concept_Design_Submission__c',
        'RETL_Actual_Detailed_Arch_MEP_Design_b_a__c',
        'RETL_Actual_Detailed_Arch_MEP_Design__c',
        'RETL_Actual_Authorities_Submission_b_a__c',
        'RETL_Actual_Authorities_Submission__c',
        'RETL_Actual_Start_onsite_b_a__c',
        'RETL_Actual_Start_onsite__c',
        'RETL_Actual_Store_Opening_Date__c'
    };
    
    public RETL_ServiceRequestTriggerHandler(List<RETL_Service_Request__c> newRecords, Map<Id, RETL_Service_Request__c> oldMap, Boolean isUpdate) {
        this.newRecords = newRecords;
        this.oldMap = oldMap;
        this.isUpdate = isUpdate;
    }
    
    /**
     * @description Main method to process Service Request sync logic based on new requirements.
     */
    public void processYardiSync() {
        Map<Id, Set<String>> recordsToSync = new Map<Id, Set<String>>();
        Set<String> allMonitoredFields = RETL_ServiceRequestTriggerHelper.getAllMonitoredFields();
        Boolean permanentMPCheck;
        
        for (RETL_Service_Request__c sr : newRecords) {
            permanentMPCheck = sr.RETL_Milestone_Program_Synced__c;
            // 1. FORCE SYNC
            if (sr.RETL_Force_Milestone_Program_Sync__c) {
                recordsToSync.put(sr.Id, allMonitoredFields);
                continue;
            }

            if (isUpdate) {
                // Ensure we have the old record.
                RETL_Service_Request__c oldSr = oldMap.get(sr.Id);
                if (oldSr == null) {
                    // This should generally not happen in after update, but if it does, skip it.
                    continue; 
                }
                
                Set<String> changedFields = getChangedFields(sr, oldSr);
                
                Boolean didActualFieldChange = isActualFieldChanged(changedFields);
                Boolean didContractualFieldChange = isContractualFieldChanged(changedFields);
                Boolean allContractualFilled = checkAllContractualFieldsPopulated(sr);

                // 2. Actual Field Change (Rule 2: Everytime any RETL_Actual* field changes)
                if (didActualFieldChange) {
                    recordsToSync.put(sr.Id, allMonitoredFields);
                    continue;
                }
                
                // 3. Contractual Field Change (Rule 3: All filled + change)
                if (didContractualFieldChange && allContractualFilled) {
                    recordsToSync.put(sr.Id, allMonitoredFields);
                    continue;
                }
            } 
        }
        
        if (recordsToSync.isEmpty()) return;

        List<RETL_Service_Request__c> resetList = new List<RETL_Service_Request__c>();
        for (Id idVal : recordsToSync.keySet()) {
            resetList.add(new RETL_Service_Request__c(
                Id = idVal,
                RETL_Force_Milestone_Program_Sync__c = false
                // RETL_Milestone_Program_Synced__c = true
            ));
        }
        // Use a DML control class or try-catch block if needed, but assuming a simple update is fine.
        Database.update(resetList, false); 
        
        RETL_ServiceRequestTriggerHelper.syncServiceRequests(
            new List<Id>(recordsToSync.keySet()),
            JSON.serialize(recordsToSync),
            permanentMPCheck
        );
    }

    /**
     * @description Returns a Set of API names for fields that have changed (from null or a value).
     * IMPORTANT: This method is critical for Rule 2 & 3. 
     */
    private static Set<String> getChangedFields(RETL_Service_Request__c newSr, RETL_Service_Request__c oldSr) {
        Set<String> changedFields = new Set<String>();
        
        // Combine all monitored fields for one loop to be robust
        List<String> allMonitoredFields = new List<String>();
        allMonitoredFields.addAll(CONTRACTUAL_FIELDS);
        allMonitoredFields.addAll(ACTUAL_FIELDS);

        for (String field : allMonitoredFields) {
            Object newValue = newSr.get(field);
            Object oldValue = oldSr.get(field);
            
            // Standard check: comparison handles null to value, value to null, and value to different value.
            if (newValue != oldValue) {
                String newStr = newValue == null ? null : String.valueOf(newValue);
                String oldStr = oldValue == null ? null : String.valueOf(oldValue);
                
                if (newStr != oldStr) {
                    changedFields.add(field);
                }
            }
        }
        
        return changedFields;
    }
    
    private static Boolean checkAllContractualFieldsPopulated(RETL_Service_Request__c sr) {
        for (String field : CONTRACTUAL_FIELDS) { if (sr.get(field) == null) return false; }
        return true;
    }
    private static Boolean isActualFieldChanged(Set<String> changedFields) {
        for (String field : ACTUAL_FIELDS) { if (changedFields.contains(field)) return true; }
        return false;
    }
    private static Boolean isContractualFieldChanged(Set<String> changedFields) {
        for (String field : CONTRACTUAL_FIELDS) { if (changedFields.contains(field)) return true; }
        return false;
    }
}