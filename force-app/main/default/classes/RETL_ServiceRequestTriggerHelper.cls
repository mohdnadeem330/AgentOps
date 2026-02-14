public class RETL_ServiceRequestTriggerHelper {
    
    // -----------------------------
    // Wrapper Classes
    // -----------------------------
    public class SyncMilestoneWrapper {
        public String Description;
        public String Timestamp;
        public String Reserve1 = '';
        public String Reserve2 = '';
        public String Reserve3 = '';
        public String Reserve4 = '';
        public String Reserve5 = '';
        public List<SyncMilestoneTable> Details;
    }
    public class SyncMilestoneTable {
        public String TableName;
        public List<SyncMilestoneData> Data;
    }
    public class SyncMilestoneData {
        public String EntityRecordCode;
        public List<SyncMilestoneField> Fields;
    }
    public class SyncMilestoneField {
        public String FieldName;
        public Object FieldValue;
        public SyncMilestoneField(String name, Object value) {
            this.FieldName = name;
            this.FieldValue = value;
        }
    }
    public class CalloutException extends Exception {}
    public static String requestBody;
    // Helper method to get ALL monitored fields (useful for Insert)
    public static Set<String> getAllMonitoredFields() {
        return new Set<String>{
            'RETL_Contr_Kick_Off_Meeting_b_a__c', 'RETL_Contr_Kick_Off_Meeting__c',
            'RETL_Contr_Concept_Design_Submission_b_a__c', 'RETL_Contr_Concept_Design_Submission__c',
            'RETL_Contr_Detailed_Arch_MEP_Design_b_a__c', 'RETL_Contr_Detailed_Arch_MEP_Design__c',
            'RETL_Contr_Authorities_Submission_b_a__c', 'RETL_Contr_Authorities_Submission__c',
            'RETL_Contr_Start_onsite_b_a__c', 'RETL_Contr_Start_onsite__c',
            
            'RETL_Actual_Kick_Off_Meeting_b_a__c', 'RETL_Actual_Kick_Off_Meeting__c',
            'RETL_Actual_Concept_Design_Submission_ba__c', 'RETL_Actual_Concept_Design_Submission__c',
            'RETL_Actual_Detailed_Arch_MEP_Design_b_a__c', 'RETL_Actual_Detailed_Arch_MEP_Design__c',
            'RETL_Actual_Authorities_Submission_b_a__c', 'RETL_Actual_Authorities_Submission__c',
            'RETL_Actual_Start_onsite_b_a__c', 'RETL_Actual_Start_onsite__c',
            'RETL_Actual_Store_Opening_Date__c'
        };
    }
    // -----------------------------
    // Public Entry Point (@future) - MODIFIED FOR @future
    // -----------------------------
    @future(callout=true)
    public static void syncServiceRequests(List<Id> serviceRequestIds, String serializedFieldsMap, Boolean permanentMPCheck) {
        Map<Id, Set<String>> fieldsToSync = (Map<Id, Set<String>>) JSON.deserialize(serializedFieldsMap, Map<Id, Set<String>>.class);
        
        HttpResponse res = null;
        Boolean overallSuccess = false;
        List<RETL_Service_Request__c> updateList = new List<RETL_Service_Request__c>();

        // Create a map to find the SR Id by the EntityRecordCode (Yardi Proposal Id)
        Map<String, Id> yardiIdToSrIdMap = new Map<String, Id>();
        for(RETL_Service_Request__c sr : [SELECT Id, RETL_Opportunity_Id__r.RETL_Yardi_Proposal_Id__c FROM RETL_Service_Request__c WHERE Id IN :serviceRequestIds]) {
            if(sr.RETL_Opportunity_Id__r.RETL_Yardi_Proposal_Id__c != null) {
                yardiIdToSrIdMap.put(sr.RETL_Opportunity_Id__r.RETL_Yardi_Proposal_Id__c, sr.Id);
            }
        }
        
        try {
            res = executeBulkSyncSRMilestone(serviceRequestIds, fieldsToSync); 
            if (res != null) {
                System.debug('res==> '+ res);
                Map<String, Object> resBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                // Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(res);
                overallSuccess = (resBody.get('ResponseCode') == '200' || resBody.get('ResponseCode') == '201'); 
                System.debug('Response::' + resBody.get('ResponseCode'));
                System.debug('resBody::' + resBody);
                // 1. Check for the "Details" list in the response body
                if (resBody.containsKey('Details')) {
                    List<Object> detailsList = (List<Object>) resBody.get('Details');
                    
                    for (Object detailObj : detailsList) {
                        Map<String, Object> detail = (Map<String, Object>) detailObj;
                        
                        // Extract values from the detail item
                        String entityCode = String.valueOf(detail.get('EntityRecordCode'));
                        String rowResponseCode = String.valueOf(detail.get('ResponseCode'));
                        String rowStatus = String.valueOf(detail.get('Status'));
                        String rowMessage = String.valueOf(detail.get('Message'));
                        
                        Id currentSrId = yardiIdToSrIdMap.get(entityCode);
                        
                        if (currentSrId != null) {
                            Boolean isRowSuccess = ((rowResponseCode == '200' || rowResponseCode == '201') && overallSuccess);
                            
                            RETL_Service_Request__c srToUpdate = new RETL_Service_Request__c(
                                Id = currentSrId,
                                RETL_MP_Update_Sync__c = isRowSuccess
                            );
                            if(!isRowSuccess){
                                srToUpdate.Milestone_Program_Sync_Info__c = rowMessage;
                            }

                            // Logic: If successfully synced and check is false, mark program as synced
                            if (permanentMPCheck == false && isRowSuccess) {  
                                srToUpdate.RETL_Milestone_Program_Synced__c = true;
                            }
                            
                            updateList.add(srToUpdate);
                        }
                    }
                }
                else {
                    LoggerService.save(
                        LoggerService.addApexServiceCalls(
                            'SRMilestoneToYardi',
                            'RETL_ServiceRequestTriggerHelper',
                            'syncServiceRequests',
                            requestBody, 
                            'ERROR: Status ' + res.getStatusCode() + ' Body: ' + res.getBody(),
                            null 
                        )
                    );
                }
            } else {
                LoggerService.save(
                    LoggerService.addApexServiceCalls(
                        'SRMilestoneToYardi',
                        'RETL_ServiceRequestTriggerHelper',
                        'syncServiceRequests',
                        '',
                        'ERROR: Null HttpResponse returned from executeBulkSyncSRMilestone',
                        null
                    )
                );
            }
        } catch (Exception e) {
                LoggerService.save(
                    LoggerService.addApexServiceCalls(
                        'SRMilestoneToYardi',
                        'RETL_ServiceRequestTriggerHelper',
                        'syncServiceRequests',
                        '',
                    'EXCEPTION: ' + e.getMessage(),
                    null
                )
            );
        }
        
        // for (Id srId : serviceRequestIds) {
        //     // updateList.add(new RETL_Service_Request__c(
        //     //     Id = srId,
        //     //     RETL_MP_Update_Sync__c = overallSuccess
        //     // )); 

        //     RETL_Service_Request__c srToUpdate = new RETL_Service_Request__c(
        //         Id = srId,
        //         RETL_MP_Update_Sync__c = overallSuccess
        //     );
        //     if (permanentMPCheck == false && overallSuccess == true) {  
        //         srToUpdate.RETL_Milestone_Program_Synced__c = true;
        //     }
        //     updateList.add(srToUpdate);

            
        //     // updateList.add(new RETL_Service_Request__c(
        //     //     Id = srId,
        //     //     RETL_MP_Update_Sync__c = true,
        //     //     RETL_Milestone_Program_Synced__c = true
        //     // )); 
        // }
        if (!updateList.isEmpty()) {
            update updateList;
        }
    }
    // -----------------------------
    // Core Logic
    // -----------------------------
    private static HttpResponse executeBulkSyncSRMilestone(List<Id> srIds, Map<Id, Set<String>> fieldsToSync) {
        
        SyncMilestoneWrapper payload = buildServiceRequestMilestonePayload(srIds, fieldsToSync);
        requestBody = JSON.serialize(payload, false); // Store for logging
        MuleSoftSetting__mdt api = Utilities.getMuleSoftDetails('RETL_SRMilestoneSyncToYardi');
        if (api == null) throw new CalloutException('MuleSoft endpoint config not found.');
        HttpResponse res = CalloutToMuleSoft.makeCallout(api.DeveloperName, requestBody);
        if (res == null) throw new CalloutException('Null response from MuleSoft.');
        System.debug('SR Milestone Bulk Sync Request: ' + requestBody);
        System.debug('SR Milestone Bulk Sync Response: ' + res.getBody());
        return res;
    }
    // -----------------------------
    // Build Payload - MODIFIED TO USE DYNAMIC SOQL AND FIELDS
    // -----------------------------
    @TestVisible
    private static SyncMilestoneWrapper buildServiceRequestMilestonePayload(List<Id> srIds, Map<Id, Set<String>> fieldsToSync) {

        // --- NEW LOGIC: Query ALL monitored fields for Rule 1 ---
        Set<String> allMonitoredFields = getAllMonitoredFields();
        Set<String> fieldsToQuery = new Set<String>(allMonitoredFields); // Start with all monitored fields
        fieldsToQuery.add('Id'); 
        fieldsToQuery.add('RETL_Opportunity_Id__c'); 
        fieldsToQuery.add('RETL_Order__r.RETL_Yardi_Id__c'); 
        fieldsToQuery.add('RETL_Opportunity_Id__r.RETL_Yardi_Proposal_Id__c'); 

        // Check if any record in fieldsToSync actually triggered a sync
        Boolean hasRecordsToSync = false;
        for (Set<String> changedFields : fieldsToSync.values()) {
            if (changedFields != null && !changedFields.isEmpty()) {
                hasRecordsToSync = true;
                break;
            }
        }
        if (!hasRecordsToSync) return null; // No need to build payload if no records triggered a sync

        // --- Execute Query ---
        String fieldList = String.join(new List<String>(fieldsToQuery), ', ');
        String query = 'SELECT ' + fieldList + ' FROM RETL_Service_Request__c WHERE Id IN :srIds'; 

        // Use a map for quick access
        Map<Id, RETL_Service_Request__c> srsMap = new Map<Id, RETL_Service_Request__c>((List<RETL_Service_Request__c>)Database.query(query));
        List<RETL_Service_Request__c> srs = srsMap.values();

        // --- Build Payload Structure (Standard) ---
        SyncMilestoneWrapper req = new SyncMilestoneWrapper();
        req.Description = 'Milestone';
        req.Timestamp = Datetime.now().format('yyyy-MM-dd HH:mm:ss'); 

        SyncMilestoneTable tbl = new SyncMilestoneTable();
        tbl.TableName = 'AMENDBUT_FITOUT_MILESTONES_TMP';
        tbl.Data = new List<SyncMilestoneData>();

        // --- Field Mapping (Standard) ---
        Map<String, String> fieldMapping = new Map<String, String>{
            'RETL_Contr_Kick_Off_Meeting_b_a__c' => 'KICK_OFF_MEETING1',
            'RETL_Contr_Kick_Off_Meeting__c' => 'KICK_OFF_MEETING',
            'RETL_Contr_Concept_Design_Submission_b_a__c' => 'CONC_DESIGN_SUBMiSSION1',
            'RETL_Contr_Concept_Design_Submission__c' => 'CONC_DESIGN_SUBMiSSION',
            'RETL_Contr_Detailed_Arch_MEP_Design_b_a__c' => 'DETL_ARC_MEP_DESIGN1',
            'RETL_Contr_Detailed_Arch_MEP_Design__c' => 'DETL_ARC_MEP_DESIGN',
            'RETL_Contr_Authorities_Submission_b_a__c' => 'AUTH_SUBMISSION1',
            'RETL_Contr_Authorities_Submission__c' => 'AUTH_SUBMISSION',
            'RETL_Contr_Start_onsite_b_a__c' => 'START_ON_SITE1',
            'RETL_Contr_Start_onsite__c' => 'START_ON_SITE',

            'RETL_Actual_Kick_Off_Meeting_b_a__c' => 'ACT_KICK_OFF_MEETING1',
            'RETL_Actual_Kick_Off_Meeting__c' => 'ACT_KICK_OFF_MEETING',
            'RETL_Actual_Concept_Design_Submission_ba__c' => 'ACT_CONC_DESIGN_SUBMiSSION1',
            'RETL_Actual_Concept_Design_Submission__c' => 'ACT_CONC_DESIGN_SUBMiSSION',
            'RETL_Actual_Detailed_Arch_MEP_Design_b_a__c' => 'ACT_DETL_ARC_MEP_DESIGN1',
            'RETL_Actual_Detailed_Arch_MEP_Design__c' => 'ACT_DETL_ARC_MEP_DESIGN',
            'RETL_Actual_Authorities_Submission_b_a__c' => 'ACT_AUTH_SUBMISSION1',
            'RETL_Actual_Authorities_Submission__c' => 'ACT_AUTH_SUBMISSION',
            'RETL_Actual_Start_onsite_b_a__c' => 'ACT_START_ON_SITE1',
            'RETL_Actual_Start_onsite__c' => 'ACT_START_ON_SITE',
            'RETL_Actual_Store_Opening_Date__c' => 'ACT_STOR_OPEN_DT'
        };
		RETL_Service_Request__c sr;
        // --- NEW LOGIC: Build Data ---
        for (Id srId : srIds) {
            // Only process records that triggered a sync
            if (!fieldsToSync.containsKey(srId) || fieldsToSync.get(srId) == null || fieldsToSync.get(srId).isEmpty()) {
                continue; 
            }
            sr = srsMap.get(srId);
            if (sr == null) continue; // Should not happen

            SyncMilestoneData data = new SyncMilestoneData();
            // data.EntityRecordCode = (String)sr.get('RETL_Order__r.RETL_Yardi_Id__c'); 
            // //RETL_Opportunity_Id__r.RETL_Yardi_Proposal_Id__c
            if (sr.RETL_Opportunity_Id__r != null) {
                data.EntityRecordCode = sr.RETL_Opportunity_Id__r.RETL_Yardi_Proposal_Id__c;
            } else {
                data.EntityRecordCode = ''; 
            }
            data.Fields = new List<SyncMilestoneField>();

            data.Fields.add(new SyncMilestoneField('CONTRACTUAL', ''));
            Boolean actualHeaderAdded = false;
            
            // Rule 1: Iterate over ALL monitored fields, not just the changed ones
            for (String sfFieldName : allMonitoredFields) {
                String jsonFieldName = fieldMapping.get(sfFieldName);
                
                if (jsonFieldName != null) {
                    // Get the field value. If it is null, the JSON serializer will handle it as null, 
                    // satisfying the requirement to pass null if no value exists.
                    Object fieldValue = sr.get(sfFieldName); 

                    if (!actualHeaderAdded && jsonFieldName.startsWith('ACT_')) {
                        data.Fields.add(new SyncMilestoneField('ACTUAL', ''));
                        actualHeaderAdded = true;
                    }
                    
                    data.Fields.add(new SyncMilestoneField(jsonFieldName, fieldValue == null ? '' : fieldValue));
                }
            }
            tbl.Data.add(data);
        }
        
        req.Details = new List<SyncMilestoneTable>{ tbl };
        return req;
    }
}