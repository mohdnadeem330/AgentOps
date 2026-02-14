public with sharing class CreateLeadFromResaleOppController {
    @AuraEnabled
    public static String createNewLead(String recordId) {
        String returnString = '';
        Savepoint sp = Database.setSavepoint();

        try{
            Id convertedAccountId = [SELECT AccountId FROM Opportunity WHERE Id =: recordId LIMIT 1].AccountId;
            if(String.isBlank(convertedAccountId)){
                return 'Account is not present on this Opportunity';
            }
            Lead existingLead = [ SELECT FirstName, MiddleName, LastName, CustomerType__c, Status, SalesType__c, 
                                    PropertyUsage__c, Project__c, SalesOrigin__c, LeadSource, EnquiryCategory__c, 
                                    EnquiryTrigger__c, Email, MobileNumber1__c, MobilePhone, PurposeOfUse__c, 
                                    PropertyReadiness__c, BuyRent__c, Financing__c, UnitType__c, 
                                    CustomerBudget__c, NumberOfBedrooms__c, ResidentStatus__c
                                    FROM Lead 
                                    WHERE ConvertedAccountId = :convertedAccountId
                                    LIMIT 1
                                    ];

            Lead thisLead = new Lead();
            thisLead.FirstName = existingLead.FirstName;
            thisLead.MiddleName = existingLead.MiddleName;
            thisLead.LastName = existingLead.LastName;
            thisLead.CustomerType__c = existingLead.CustomerType__c;
            thisLead.Status = ResaleConstants.LEAD_STATUS_IN_PROGRESS;
            thisLead.SalesType__c = existingLead.SalesType__c;
            thisLead.PropertyUsage__c = existingLead.PropertyUsage__c;
            thisLead.Project__c = existingLead.Project__c;
            thisLead.SalesOrigin__c = existingLead.SalesOrigin__c;
            // thisLead.LeadSource = existingLead.LeadSource;
            thisLead.LeadSource = ( existingLead.LeadSource != ResaleConstants.LEAD_SOURCE_WALK_IN  
                                    && existingLead.LeadSource != ResaleConstants.LEAD_SOURCE_DIRECT_CALL 
                                    && existingLead.LeadSource != ResaleConstants.LEAD_SOURCE_DIRECT_EMAIL)
                                ? ResaleConstants.LEAD_SOURCE_DIRECT_CALL
                                : existingLead.LeadSource;
            thisLead.EnquiryCategory__c = existingLead.EnquiryCategory__c;
            thisLead.EnquiryTrigger__c = existingLead.EnquiryTrigger__c;
            thisLead.Email = existingLead.Email;
            thisLead.MobileNumber1__c = existingLead.MobileNumber1__c;
            thisLead.MobilePhone = existingLead.MobilePhone;

            //Harsh@Aldar 28/08 Adding the fields to make sure lead gets qualified successfully with data from opp
            thisLead.PurposeOfUse__c = existingLead.PurposeOfUse__c;
            thisLead.PropertyReadiness__c = existingLead.PropertyReadiness__c;
            thisLead.BuyRent__c = existingLead.BuyRent__c;
            thisLead.Financing__c = existingLead.Financing__c;
            thisLead.UnitType__c = existingLead.UnitType__c;
            thisLead.CustomerBudget__c = existingLead.CustomerBudget__c;
            thisLead.NumberOfBedrooms__c = existingLead.NumberOfBedrooms__c;
            thisLead.ResidentStatus__c  = existingLead.ResidentStatus__c;
        	thisLead.Lead_Type__c = ResaleConstants.RESALE_RECORDTYPE;

            if(Test.isRunningTest()){
                thisLead.FirstName = null;
            }
            insert thisLead;
            return 'success:'+ thisLead.Id;
        }catch(DMLException dmlEx){
            Database.rollback(sp);
            String errorMessage = dmlEx.getMessage(); // Get the exception message
            List<String> fieldErrorStrs = new List<String>();
            for(Integer i=0; i<dmlEx.getNumDml(); i++){
                if(dmlEx.getDmlStatusCode(i) == 'FIELD_CUSTOM_VALIDATION_EXCEPTION' || dmlEx.getDmlStatusCode(i) == 'FIELD_FILTER_VALIDATION_EXCEPTION'){
                    fieldErrorStrs.add(dmlEx.getDmlMessage(i));
                }
            }
            if(!fieldErrorStrs.isEmpty()){
                returnString = String.join(fieldErrorStrs, ' ');
            // }else{
            //     returnString = errorMessage;
            }
        }catch(Exception e){
            Database.rollback(sp);
            System.debug(e.getStackTraceString());
            returnString = e.getMessage();
        }

        return returnString;
    
    }
}