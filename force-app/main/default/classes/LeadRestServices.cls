@RestResource(urlMapping='/leadRestService') 
global class LeadRestServices {
    
    private static ResponseWrapper objResponse = new ResponseWrapper();
    static List<String> FieldExceptionCodes = new List<String>{ 'FIELD_CUSTOM_VALIDATION_EXCEPTION', 'FIELD_FILTER_VALIDATION_EXCEPTION', 'INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST' };

    @httpPost
    global static ResponseWrapper createLead() {
        String requestString = RestContext.request.requestBody.toString();
        Lead requestLead = new Lead();
        
        try {
            requestLead = (Lead) JSON.deserialize(requestString, Lead.class);
            System.debug('requestLead: ' + requestLead);

            if (requestLead.Project__c != null && requestLead.EnquiryTrigger__c == 'Damascus') {
                Map<String, String> leadProjectMapping = mapPicklistValueFromProject(requestLead.Project__c);
                if (leadProjectMapping != null && leadProjectMapping.containsKey(requestLead.Project__c)) {
                    requestLead.Project__c = leadProjectMapping.get(requestLead.Project__c);
                }
            }

            String validatedString;
            if (String.isNotBlank(requestLead?.LeadSource) && requestLead?.LeadSource?.equalsIgnoreCase('Broker Portal')) {
                validatedString = BP_UtilitiesWithoutSharing.brokerLeadValidation(requestLead);

                if (validatedString == 'Duplicate') {
                    objResponse.leadId = requestLead.Id;
                    objResponse.success = false;
                    objResponse.message = 'Duplicate Lead';
                    return objResponse;
                } else if (validatedString == 'Unique') {
                    requestLead.Status = Constants.WORKING_LEAD;
                    List<Project__c> listProject = getProjects(requestLead?.Project__c);
                    system.debug('Peoject record '+ listProject);
                    List<Account> listAgency = getAgencyDetails(requestLead?.BrokerAgency__c);
                    system.debug('listAgency ==='+ listAgency);

                    if (!listProject.isEmpty() && !listAgency.isEmpty()) {
                        if (listAgency[0]?.AgencyCategory__c == 'Broker' && 
                            listAgency[0]?.AgencySubCategory__c == 'LSQ broker' && 
                            (listProject[0]?.Country__c == 'United Kingdom' || 
                             requestLead?.Project__c?.containsIgnoreCase('London'))) {
                                 
                            requestLead.OwnerId = Utilities.getQueueInformation('LSQ Queue')?.Id;
                                 system.debug(' requestLead.OwnerId ==='+  requestLead.OwnerId);
                        } else {
                            requestLead.OwnerId = Utilities.getQueueInformation(Constants.BROKER_QUEUE)?.Id;
                        }     
                    } else {
                        requestLead.OwnerId = Utilities.getQueueInformation(Constants.BROKER_QUEUE)?.Id;
                    }
                }
            } 

            Boolean isNewRecord = (requestLead.Id == null);

            upsert requestLead;
            requestLead = [SELECT Id, LeadNumber__c FROM Lead WHERE Id = :requestLead.Id];

            objResponse.leadId = requestLead.Id;
            objResponse.success = true;
            objResponse.message = isNewRecord ? 'Lead inserted successfully!' : 'Lead updated successfully!';
            return objResponse;
            
        } catch (DMLException dmlEx) {
            Integer statusCode = 500;
            String errorMessage = dmlEx.getMessage();
            List<String> fieldErrors = new List<String>();

            for (Integer i = 0; i < dmlEx.getNumDml(); i++) {
                if (FieldExceptionCodes.contains(dmlEx.getDmlStatusCode(i))) {
                    fieldErrors.add(dmlEx.getDmlMessage(i));
                }
            }

            if (!fieldErrors.isEmpty()) {
                statusCode = 300;
                errorMessage = String.join(fieldErrors, ' ');
            }

            objResponse.success = false;
            objResponse.message = errorMessage;
            System.debug('DMLException: ' + dmlEx.getStackTraceString());

        } catch (Exception ex) {
            objResponse.success = false;
            objResponse.message = ex.getMessage();
            System.debug('Exception: ' + ex.getStackTraceString());
        }

        return objResponse;
    }

    global class ResponseWrapper {
        public String leadId;
        public Boolean success;
        public String message;
        global ResponseWrapper() {}
    }

    public static Map<String, String> mapPicklistValueFromProject(String projectName) {
        List<Project__c> mappings = [SELECT Name, LeadProjectName__c, Damascus_Community_Name__c 
                                     FROM Project__c 
                                     WHERE Name = :projectName OR Damascus_Community_Name__c = :projectName LIMIT 1];

        Map<String, String> picklistMapping = new Map<String, String>();
        for (Project__c mapping : mappings) {
            picklistMapping.put(mapping.Name, mapping.LeadProjectName__c);
            picklistMapping.put(mapping.Damascus_Community_Name__c, mapping.LeadProjectName__c);
        }
        return picklistMapping;
    }

    public static List<Project__c> getProjects(String projectName) {
        return [SELECT Id, Name, Country__c 
                FROM Project__c 
                WHERE IsActive__c = true AND Country__c != null AND 
                      (Name = :projectName OR LeadProjectName__c = :projectName) LIMIT 1];
    }

    public static List<Account> getAgencyDetails(String agencyId) {
        return [SELECT Id, AgencyCategory__c, AgencySubCategory__c FROM Account WHERE Id = :agencyId];
    }
}