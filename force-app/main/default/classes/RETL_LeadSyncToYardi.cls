/**
 * @description
 * Handles synchronization of Opportunity data from Salesforce to Yardi via MuleSoft.
 * This class constructs the request payload using Opportunity record data,
 * performs a callout to MuleSoft, and updates Salesforce with the Yardi Opportunity Code.
 *
 * NOTE: This implementation assumes the existence of:
 * 1. A custom setting or metadata type (e.g., MuleSoftSetting__mdt) with endpoint details.
 * 2. Utility classes (Utilities, CalloutToMuleSoft, LoggerService, CustomException)
 * as referenced in the existing class structure.
 *
 * @author vkotaprolu@aldar.com
 * @date 2025-10-24
 */
public with sharing class RETL_LeadSyncToYardi {

    // --------------------------------------------------------------------------
    // Wrapper Classes for Request/Response Payloads
    // --------------------------------------------------------------------------

    /**
     * Wrapper class representing the root of the Yardi Opportunity request payload.
     */
    public class YardiOpportunityRequestWrapper {
        public List<CommProspect> CommProspect;
    }

    /**
     * Wrapper for the CommProspect object containing individual Opportunity details.
     * Field names match the JSON request keys exactly.
     */
    public class CommProspect {
        public String SF_Ref_Lead_Id;
        public String Lead_Name;
        public string Lead_Date;
        public String LeadSource;
        public String CustomerCode;
        public String BrandCode;
        public String TypeofContact;
        public String WhyMoving;
        public String LeadStatus;
        public String Notes;
        public String Primary_Property;
        public string Moveindate;
        public string MoveOUTdate;
        public Decimal Desired_Area;
        public Decimal Desired_Rent;
        public String UnitType;
        public String SalesCategory;
        public String Attribute1;
        public String Attribute2;
        public String Attribute3;
        public String Attribute4;
        public String Attribute5;
        public String Attribute6;
        public String Attribute7;
        public String Attribute8;
        public String Units;
    }

    /**
     * Wrapper class representing the Yardi API response for a Opportunity.
     */
    public class YardiOpportunityResponseWrapper {
        public String Status;
        public String ErrorMessage;
        public String SF_Ref_Lead_Id;
        public String LeadCode;
    }

    // --------------------------------------------------------------------------
    // Core Callout Methods
    // --------------------------------------------------------------------------

    /**
     * Asynchronous version of the main callout method.
     * Invoked from triggers or other async contexts.
     *
     * @param OpportunityId - Salesforce Opportunity record Id. 
     */
    @future(callout=true)
    public static void pushToYardiAsync(Id OpportunityId) {
        pushToYardiAndUpdate(OpportunityId);
    }

    /**
     * Core method to push Opportunity data to Yardi.
     * Constructs the request body, performs the HTTP callout,
     * parses the response, and updates the Salesforce Opportunity record.
     *
     * @param OpportunityId - Salesforce Opportunity record Id to be synchronized.     
     */
    public static void pushToYardiAndUpdate(Id OpportunityId) {
        String className = 'RETL_OpportunitySyncToYardi';
        String methodName = 'pushToYardiAndUpdate';
        HttpResponse response;

        try {
            if (OpportunityId == null){
                throw new RETL_ContactAndContactRoleSyncToYardi.CustomException('Opportunity Id cannot be null.');
            }

            // Step 1: Build payload wrapper for Yardi
            YardiOpportunityRequestWrapper OpportunityData = buildOpportunityWrapper(OpportunityId);
            if (OpportunityData == null || OpportunityData.CommProspect.isEmpty()){
                throw new RETL_ContactAndContactRoleSyncToYardi.CustomException('Unable to construct Yardi Opportunity payload.');
            }

            // Step 2: Fetch MuleSoft endpoint configuration
            // Assumes 'RETL_OpportunitySyncToYardi' is the DeveloperName for the endpoint configuration
            // NOTE: Assumes existence of Utilities.getMuleSoftDetails and MuleSoftSetting__mdt
            MuleSoftSetting__mdt api = Utilities.getMuleSoftDetails(className);

            if (api == null){
                throw new RETL_ContactAndContactRoleSyncToYardi.CustomException('Yardi API configuration not found in MuleSoftSetting__mdt.');
            }

            // Step 3: Serialize payload to JSON
            replaceNullStringsWithEmpty(OpportunityData);
            String requestBody = JSON.serialize(OpportunityData,false);
            System.debug('Yardi Opportunity Request Body: ' + requestBody);

            // Step 4: Perform callout
            // NOTE: Assumes existence of CalloutToMuleSoft.makeCallout
            response = CalloutToMuleSoft.makeCallout(api.DeveloperName, requestBody);
            if (response == null){
                throw new RETL_ContactAndContactRoleSyncToYardi.CustomException('No response received from Yardi endpoint.');
            }

            Integer statusCode = response.getStatusCode();
            String resBody = response.getBody();
            System.debug('Response Code: ' + statusCode);
            System.debug('Response Body: ' + resBody);

            // Step 5: Parse response and update Salesforce
            if (statusCode >= 200 && statusCode < 300 && !String.isBlank(resBody)) {
                YardiOpportunityResponseWrapper resWrapper =
                    (YardiOpportunityResponseWrapper) JSON.deserialize(resBody, YardiOpportunityResponseWrapper.class);

                // Check for successful status and required fields
                if (resWrapper.Status == 'Success' && !String.isBlank(resWrapper.LeadCode)) {
                    // Update Opportunity record with Yardi Opportunity Code
                    update new Opportunity(
                        Id = OpportunityId,
                        RETL_Yardi_Id__c = resWrapper.LeadCode // Assumes custom field RETL_Yardi_Id__c on Opportunity                        
                    );
                    // Call Financial Info
                    System.enqueueJob(new RETL_UnitSyncToYardiQueueable(OpportunityId));
                    System.debug('Updated Opportunity ' + resWrapper.SF_Ref_Lead_Id + ' with Yardi Opportunity Code: ' + resWrapper.LeadCode);
                    
                    // Sync attachments
                    syncAttachments(OpportunityId);

                    // Sync Lead Contact association
                    syncContactAssociation(OpportunityId);

                    

                    
                } else {
                    // Handle logical failure (2xx status but not 'Success')
                    String errMsg = 'Yardi Opportunity Sync Failed (Status Success but missing LeadCode/Error): ' + resBody;
                    logError(className, methodName, requestBody, errMsg, resWrapper.SF_Ref_Lead_Id);
                }
            } else {
                // Handle HTTP error response
                String errMsg = 'Yardi Opportunity Sync Failed: ' + statusCode + ' | Body: ' + resBody;
                logError(className, methodName, requestBody, errMsg, OpportunityId);
            }

        } catch (Exception e) {
            // Handle and log exceptions
            // NOTE: Assumes existence of LoggerService
            logError(className, methodName, null, 'Exception while pushing Opportunity to Yardi: ' + e.getMessage(), OpportunityId);
            throw e;
        }
    }

    /**
     * Constructs the Yardi request wrapper using Opportunity data.
     * Queries the Salesforce Opportunity record and related OpportunityLineItems (for Units)
     * and maps field values into the wrapper structure.
     *
     * @param OpportunityId - Salesforce Opportunity record Id.
     * @return YardiOpportunityRequestWrapper object populated with Opportunity details.
     */
    @Testvisible
    private static YardiOpportunityRequestWrapper buildOpportunityWrapper(Id OpportunityId) {
        Opportunity opp = [
            SELECT
                Id, Name, CreatedDate, LeadSource, Account.RETL_Yardi_Id__c, RETL_Brand__r.RETL_Yardi_Id__c,
                  Description,RETL_Desired_Rent__c,RETL_Desired_Area__c,RETL_Term_Start_Date__c,RETL_Term_End_Date__c,RETL_Sales_Category__c,RETL_Project__c,RETL_Configure_By__c
                  //RETL_Sales_Category__c
                //RETL_Type_of_Contact__c,
                //Status, 
                //RETL_Why_Moving__c,
                //RETL_Primary_Property__c, RETL_Move_In_Date__c, 
                //RETL_Desired_Rent__c, RETL_Unit_Type__c, RETL_Desired_Area__c,
                //RETL_Attribute1__c, RETL_Attribute2__c, RETL_Attribute3__c, RETL_Attribute4__c,
                //RETL_Attribute5__c, RETL_Attribute6__c, RETL_Attribute7__c, RETL_Attribute8__c
            FROM Opportunity
            WHERE Id = :OpportunityId
            LIMIT 1
        ];

        // Query OpportunityLineItems to get ProductCode for Units
        List<OpportunityLineItem> lineItems = [
            SELECT PricebookEntry.Product2.ProductCode,RETL_Unit_Type__c,RETL_Selected_Unit__r.Property_Code__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :OpportunityId
            AND PricebookEntry.Product2.ProductCode != NULL
        ];

        // Construct the comma-separated Units string
        List<String> unitCodes = new List<String>();
        string UnitType;
        string projectCode = '';
        for(OpportunityLineItem oli : lineItems) {
            unitCodes.add(oli.PricebookEntry.Product2.ProductCode);
            UnitType = oli.RETL_Unit_Type__c;
            projectCode = oli.RETL_Selected_Unit__r.Property_Code__c;
        }
        String unitsString = String.join(unitCodes, ',');
        System.debug('Constructed Units String from OpportunityLineItems: ' + unitsString);


        CommProspect prospect = new CommProspect();
        prospect.SF_Ref_Lead_Id = opp.Id;
        prospect.Lead_Name = opp.Name;
        prospect.Lead_Date = formatDateAsYardiString(date.valueof(opp.createddate));//Date.valueOf(opp.CreatedDate);
        prospect.Moveindate = formatDateAsYardiString(opp.RETL_Term_Start_Date__c);
        prospect.MoveOUTdate = formatDateAsYardiString(opp.RETL_Term_End_Date__c);
        prospect.LeadSource = opp.LeadSource;
        prospect.CustomerCode = opp.Account.RETL_Yardi_Id__c;
        prospect.BrandCode = opp.RETL_Brand__r.RETL_Yardi_Id__c;
        //prospect.TypeofContact = opp.RETL_Type_of_Contact__c;
        //prospect.WhyMoving = opp.RETL_Why_Moving__c;
        prospect.LeadStatus = 'Active'; 
        prospect.Notes = opp.Description;
        prospect.Primary_Property = projectCode;
        prospect.SalesCategory = opp.RETL_Sales_Category__c;
        //prospect.Primary_Property = opp.RETL_Primary_Property__c; // Need to create on Opportunity
        //
        prospect.Desired_Area = opp.RETL_Desired_Area__c!=NULL?opp.RETL_Desired_Area__c:0; // Need to create on Opportunity
        prospect.Desired_Rent = opp.RETL_Desired_Rent__c!=NULL?opp.RETL_Desired_Rent__c:0; // Need to create on Opportunity
        prospect.UnitType = UnitType; // Comes from OpportunityLineItem
       
        prospect.Units = unitsString; // Comes from OpportunityLineItem

        /* prospect.Attribute1 = opp.RETL_Attribute1__c;
        prospect.Attribute2 = opp.RETL_Attribute2__c;
        prospect.Attribute3 = opp.RETL_Attribute3__c;
        prospect.Attribute4 = opp.RETL_Attribute4__c;
        prospect.Attribute5 = opp.RETL_Attribute5__c;
        prospect.Attribute6 = opp.RETL_Attribute6__c;
        prospect.Attribute7 = opp.RETL_Attribute7__c;
        prospect.Attribute8 = opp.RETL_Attribute8__c; */

        YardiOpportunityRequestWrapper wrapper = new YardiOpportunityRequestWrapper();
        wrapper.CommProspect = new List<CommProspect>{prospect};

        return wrapper;
    }

    /**
     * Helper method to log errors using the presumed LoggerService.
     * @param className - The name of the calling Apex class.
     * @param methodName - The name of the calling method.
     * @param requestBody - The JSON request body sent.
     * @param errorMsg - The error message to log.
     * @param recordId - The Salesforce record Id associated with the error.
     */
    private static void logError(String className, String methodName, String requestBody, String errorMsg, Id recordId) {
        // Assuming Utilities.sendExceptionEmail and LoggerService exist and have methods as shown in the reference class
        // Utilities.sendExceptionEmail(className, methodName, errorMsg, 'Yardi Opportunity Sync Failed', null);

        // NOTE: Assumes existence of LoggerService
        LoggerService.save(
            LoggerService.addApexServiceCalls(
                'OpportunitySyncToYardi',     // Process name
                className,         // Class name
                methodName,         // Method name
                'requestBody: ' + requestBody, // Request body for traceability
                errorMsg,          // Response body/Error message
                recordId           // Lookup for Mapping Related Opportunity record ID
            )
        );
        System.debug('Yardi Push Failure: ' + errorMsg);
    }

    /**
     * Replaces null string fields in CommProspect with empty strings
     */
    private static void replaceNullStringsWithEmpty(YardiOpportunityRequestWrapper wrapper) {
        if (wrapper == null || wrapper.CommProspect == null) return;

        for (CommProspect c : wrapper.CommProspect) {
            if (c.WhyMoving == null) c.WhyMoving = '';
            if (c.UnitType == null) c.UnitType = '';
            if (c.TypeofContact == null) c.TypeofContact = '';
            if (c.SalesCategory == null) c.SalesCategory = '';
            if (c.Notes == null) c.Notes = '';
            if (c.Primary_Property == null) c.Primary_Property = '';
            if (c.LeadStatus == null) c.LeadStatus = '';
            if (c.Attribute1 == null) c.Attribute1 = '';
            if (c.Attribute2 == null) c.Attribute2 = '';
            if (c.Attribute3 == null) c.Attribute3 = '';
            if (c.Attribute4 == null) c.Attribute4 = '';
            if (c.Attribute5 == null) c.Attribute5 = '';
            if (c.Attribute6 == null) c.Attribute6 = '';
            if (c.Attribute7 == null) c.Attribute7 = '';
            if (c.Attribute8 == null) c.Attribute8 = '';
            if (c.Units == null) c.Units = '';
            if (c.Moveindate == null) c.Moveindate = '';
        }
    }

    /**
     * Converts a Date to a GMT-formatted string yyyy-MM-dd
     * @param d Date to format
     * @return String in yyyy-MM-dd format or null if input is null
     */
    public static String formatDateAsYardiString(Date d) {
        if (d == null) return null;
        Datetime dt = Datetime.newInstance(d, Time.newInstance(0, 0, 0, 0));
        return dt.formatGMT('yyyy-MM-dd');
    }

    /**
     * Converts a Datetime to a GMT-formatted string yyyy-MM-dd
     * @param dt Datetime to format
     * @return String in yyyy-MM-dd format or null if input is null
     */
    public static String formatDatetimeAsYardiString(Datetime dt) {
        if (dt == null) return null;
        return dt.formatGMT('yyyy-MM-dd');
    }

    /**
     * Syncs Lead Contact (Aldar Leasing Manager) after Opportunity push to Yardi.
     */
    private static void syncContactAssociation(Id opportunityId) {
        if (opportunityId == null) return;

        Opportunity opp = [
            SELECT Id, AccountId
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        /* // Contact of type Aldar Leasing Manager
        List<Contact> leadContacts = [
            SELECT Id
            FROM Contact
            WHERE AccountId = :opp.AccountId
            AND Title = 'Aldar Leasing Manager'
            LIMIT 1
        ];

        // Contact of type Aldar Leasing Manager
        List<Contact> leadContactsNonAldrar = [
            SELECT Id
            FROM Contact
            WHERE AccountId = :opp.AccountId
            AND Title != 'Aldar Leasing Manager'
            LIMIT 1
        ]; */

        // Get Contact Roles related to Opportunity
        List<RETL_Contact_role__c> relatedContactRoles = [
            SELECT Id, RETL_Contact__c, RETL_Contact_Role__c
            FROM RETL_Contact_role__c
            WHERE RETL_Opportunity__c = :opportunityId
        ];
        // Get set of Contact Ids from the roles
        Set<Id> relatedContactIds = new Set<Id>();
        for (RETL_Contact_role__c cr : relatedContactRoles) {
            relatedContactIds.add(cr.RETL_Contact__c);
        }

        if (!relatedContactIds.isEmpty()) {
            System.enqueueJob(new RETL_ContactYardiSyncQueueable(new List<Id>(relatedContactIds), opp.AccountId));            
        }
        
        /* if (!leadContacts.isEmpty()) {
            System.enqueueJob(new RETL_ContactYardiSyncQueueable(leadContacts[0].Id));            
        }
         if (!leadContactsNonAldrar.isEmpty()) {
            System.enqueueJob(new RETL_ContactYardiSyncQueueable(leadContactsNonAldrar[0].Id)); 
        } */
    }


    /**
     * Syncs Brand Profile attachment for Contact under the Opportunity’s Account.
     */
    private static void syncAttachments(Id opportunityId) {
        if (opportunityId == null) return;

        Opportunity opp = [
            SELECT Id, AccountId
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        List<Document__c> docList = [
            SELECT Id, Lead__c, Opportunity__c 
            FROM Document__c 
            WHERE DocumentType__c ='Brand Profile' AND Opportunity__c =: opportunityId
        ];
        
        // Contact that is NOT the Aldar Leasing Manager
        /*List<Contact> contacts = [
            SELECT Id 
            FROM Contact
            WHERE AccountId = :opp.AccountId
            AND Title != 'Aldar Leasing Manager'
            LIMIT 1
        ];

        if (contacts.isEmpty()) return;

        Id contactId = contacts[0].Id;*/
        if( !docList.isEmpty() ){
        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink cdl : [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
                WHERE LinkedEntityId = :docList[0].Id
        ]) {
            docIds.add(cdl.ContentDocumentId);
        }

        if (docIds.isEmpty()) return;

        // Get Brand Profile file
        List<ContentVersion> cv = [
            SELECT Id, Title
            FROM ContentVersion
            WHERE ContentDocumentId IN :docIds
                ORDER BY CreatedDate DESC
                LIMIT 1
            ]; 
            system.debug('cv==>'+cv);
        if (cv != null && !cv.isEmpty() && cv[0].Id != null) {
            System.enqueueJob(new RETL_AttachmentSyncToYardiQueueable(opportunityId, cv[0].Id));
            System.debug('Enqueued Attachment Sync for Brand Profile: ' + cv[0].Id);
        }
    }
        // Collect all ContentDocumentIds linked to contact
        
    }


}