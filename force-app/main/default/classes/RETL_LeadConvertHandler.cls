/**
 * RETL_LeadConvertHandler
 * -------------------------
 * This class provides an invocable Apex method to convert Leads into 
 * Accounts, Contacts, and optionally Opportunities. 
 * It also supports linking the converted Account to multiple Brand 
 * Accounts via the RETL_Brand_Linkage__c junction object.
 * 
 * Use case:
 * - Called from Salesforce Flows or Processes to handle Lead conversion.
 * - Allows configuration of whether or not to create an Opportunity.
 * - Creates RETL_Brand_Linkage__c records to link the converted Account to selected Brands.
 * - Rolls back if any part of the transaction fails.
 */
public with sharing class RETL_LeadConvertHandler {
    
    /**
     * Wrapper class representing the input request for Lead conversion.
     */
    public class ConvertRequest {
        @InvocableVariable(required = true)
        public Id leadId; // Lead to be converted

        @InvocableVariable
        public Id accountId; // Optional: Use an existing Account instead of creating a new one

        @InvocableVariable
        public Id contactId; // Optional: Use an existing Contact instead of creating a new one

        @InvocableVariable
        public Boolean createOpportunity; // If false, Opportunity will not be created

        @InvocableVariable
        public string selectedBrandIds; // Optional: List of Brand Account Ids to link via RETL_Brand_Linkage__c 
        
        @InvocableVariable
        public List<Id> selectedGroupId; // Optional: List of Brand Account Ids to link via RETL_Brand_Linkage__c 

        @InvocableVariable
        public string OpportunityRecordTypeName;

        @InvocableVariable
        public string AccountRecordTypeName;

        @InvocableVariable
        public string ContactRecordTypeName;
    }

    /**
     * Wrapper class representing the response after Lead conversion.
     */
    public class ConvertResponse {
        @InvocableVariable
        public Id accountId; // Resulting Account Id

        @InvocableVariable
        public Id contactId; // Resulting Contact Id

        @InvocableVariable
        public Id opportunityId; // Resulting Opportunity Id (if created)

        @InvocableVariable
        public Id tradeLicenseAccountId; // Resulting Trade License Account Id (if created)

        @InvocableVariable
        public Boolean success; // Indicates if the conversion was successful

        @InvocableVariable
        public String errorMessage; // Error message if conversion failed
    }

    /**
     * Invocable method to convert one or more Leads.
     * 
     * @param requests - List of ConvertRequest objects containing Lead Id, 
     *                   optional parameters (Account, Contact, createOpportunity, selectedBrandIds).
     * @return List of ConvertResponse objects indicating success or failure 
     *         and containing related record Ids if successful.
     */
    @InvocableMethod( label = 'Convert Lead with Brand Linkage' description = 'Converts a Lead into Account, Contact, and optionally Opportunity. Also links the Account to selected Brand Accounts via RETL_Brand_Linkage__c.'    )
    public static List<ConvertResponse> convertLead(List<ConvertRequest> requests) {
        List<ConvertResponse> responses = new List<ConvertResponse>();

        Set<Id> leadIds = new Set<Id>();
        for (ConvertRequest req : requests) {
            leadIds.add(req.leadId);
        }
        Map<Id, Lead> leadsMap = new Map<Id, Lead>([SELECT Id, Company,RETL_Trade_License_No__c,RETL_Trade_License_Issuing_Authority__c, OwnerId FROM Lead WHERE Id IN :leadIds]);

        for (ConvertRequest req : requests) {
            ConvertResponse res = new ConvertResponse();
            Savepoint sp = Database.setSavepoint(); // Start transaction savepoint
            Lead ld = leadsMap.get(req.leadId);

            try {
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(req.leadId);
               
                // Use provided Account if passed
                if (req.accountId != null) {
                    lc.setAccountId(req.accountId);
                }

                // Use provided Contact if passed
                if (req.contactId != null) {
                    lc.setContactId(req.contactId);
                }

                // Configure Opportunity creation
                lc.setDoNotCreateOpportunity(
                    req.createOpportunity != null && req.createOpportunity == false
                );

                // Must set a valid converted status from Lead Status picklist
                lc.setConvertedStatus('Converted Lead'); 

                
                // Perform the conversion
                Database.LeadConvertResult lcr = Database.convertLead(lc, true);

                if (lcr.isSuccess()) {
                    res.accountId = lcr.getAccountId();
                    res.contactId = lcr.getContactId();
                    res.opportunityId = lcr.getOpportunityId();
                    res.success = true;
					//to Link new opportunity to document with type Brand Profile 
                    if(  res.opportunityId != null && req.leadId != null ){
                      linkBrandProfileDocToOpportunity( res.opportunityId, req.leadId);
                    }
                    // Apply record types if developer names were passed
                    List<SObject> conversionUpdates = new List<SObject>();

                    if (!String.isBlank(req.AccountRecordTypeName) && res.accountId != null) {
                        conversionUpdates.add(new Account(
                            Id = res.accountId,
                            RecordTypeId = getRecordTypeId('Account', req.AccountRecordTypeName),
                            Type = 'Customer', // Default Type for Accounts created from Leads,
                            //RETL_Customer_Type__c = 'Retail',
                            CustomerVertical__c = 'Retail',
                            RETL_Status__c = 'Active', // Default Status for Accounts created from Leads
                            OwnerId = UserInfo.getUserId()
                        ));
                    }
                    string contactName = '';
                    if (!String.isBlank(req.ContactRecordTypeName) && res.contactId != null) {
                        contact conTemp = [select id,Name from contact where Id=:res.contactId];
                        contactName = conTemp.Name;
                        conversionUpdates.add(new Contact(
                            Id = res.contactId,
                            RecordTypeId = getRecordTypeId('Contact', req.ContactRecordTypeName)
                        ));

                        //createOpportunityContactRoles(res.contactId, res.accountId, res.opportunityId, contactName);

                        // Create a contact role in case of New Contact created via Conversion ( If a contact is selected from Duplicate list on screen flow then it wont create ccontact role assuming the Role exist)
                        /* RETL_Contact_role__c conRole = new RETL_Contact_role__c();
                        conRole.Name = contactName;
                        conRole.RETL_Account_Name__c = res.accountId;
                        conRole.RETL_Contact_role__c = 'Customer Leasing Manager';
                        conRole.RETL_Role_Type__c = 'Commercial Prospect';
                        conRole.RETL_Contact__c = res.contactId;
                        conRole.RETL_Primary__c = true;
                        conRole.RETL_Opportunity__c = res.opportunityId;
                        insert conRole; */

                        // ROLES FOR TAGGING UNDER CUSTOMER IN YARDI
                        RETL_Contact_role__c conRoleCust = new RETL_Contact_role__c();
                        conRoleCust.Name = contactName;
                        conRoleCust.RETL_Account_Name__c = res.accountId;
                        conRoleCust.RETL_Contact_role__c = 'Customer Leasing Manager';
                        conRoleCust.RETL_Role_Type__c = '478';
                        conRoleCust.RETL_Contact__c = res.contactId;
                        conRoleCust.RETL_Primary__c = true;                        
                        insert conRoleCust;

                        RETL_Contact_role__c conRoleCLM = new RETL_Contact_role__c();
                        conRoleCLM.Name = contactName;
                        //conRoleCLM.RETL_Account_Name__c = res.accountId;
                        conRoleCLM.RETL_Contact_role__c = 'Customer Leasing Manager';
                        conRoleCLM.RETL_Role_Type__c = '1783';
                        conRoleCLM.RETL_Contact__c = res.contactId;
                        conRoleCLM.RETL_Primary__c = true;
                        conRoleCLM.RETL_Opportunity__c = res.opportunityId;
                        insert conRoleCLM; 


                        //ROLES FOR TAGGING THE Leasing Manager UNDER YARDI
                        List<User> currentUser = new List<User>();
                        if( ld.OwnerId != null){
                            currentUser = [SELECT Id, Name, FirstName,  Email, LastName, RETL_Yardi_Leasing_Manager_Code__c FROM User WHERE Id = :ld.OwnerId LIMIT 1]; 
                        }
                        
                        Contact lmContact;
                        List<Contact> lmContacts  = new List<Contact>();
                        if(!currentUser.isEmpty()){
                            lmContacts = [
                                SELECT Id, FirstName, LastName 
                                FROM Contact 
                                WHERE Email = :currentUser[0].Email AND RETL_Yardi_Id__c != null AND RETL_Yardi_Id__c = :currentUser[0].RETL_Yardi_Leasing_Manager_Code__c
                                LIMIT 1];   
                            
                            
                        if(!lmContacts.isEmpty()){
                            lmContact = lmContacts[0];
                        } else {
                            // Create a Contact for Leasing Manager
                            lmContact = New Contact();
                            lmContact.title = 'Aldar Leasing Manager';                        
                                lmContact.FirstName = currentUser[0].FirstName;
                                lmContact.LastName =  currentUser[0].LastName;
                                lmContact.Email = currentUser[0].Email;
                                lmContact.RETL_Yardi_Id__c = currentUser[0].RETL_Yardi_Leasing_Manager_Code__c;
                                lmContact.AccountId = res.accountId;
                                insert lmContact; 
                            }
                        }
                        RETL_Contact_role__c conRoleAdmin = new RETL_Contact_role__c();
                        conRoleAdmin.Name = lmContact.FirstName + ' ' + lmContact.LastName;                        
                        //conRoleAdmin.RETL_Account_Name__c = res.accountId;
                        conRoleAdmin.RETL_Contact_role__c = 'Leasing Manager';
                        conRoleAdmin.RETL_Role_Type__c = '1783';
                        conRoleAdmin.RETL_Contact__c = lmContact.Id;
                        conRoleAdmin.RETL_Primary__c = false;
                        conRoleAdmin.RETL_Opportunity__c = res.opportunityId;                      
                        insert conRoleAdmin; 
                        
                        // Call Portal User Creation Batch
                        Database.executeBatch(new RETL_PortalUserCreationBatch(new List<Id>{res.contactId}, true), 1);
                    }
                    if (!String.isBlank(req.OpportunityRecordTypeName) && res.opportunityId != null) {
                        conversionUpdates.add(new Opportunity(
                            Id = res.opportunityId,
                            Name = ld.Company,
                            RecordTypeId = getRecordTypeId('Opportunity', req.OpportunityRecordTypeName),
                            StageName = 'Deal In Progress'
                        ));
                    }

                    if (!conversionUpdates.isEmpty()) {
                        update conversionUpdates;
                        // Run the async Yardi push
                        if(!test.isRunningTest()){
                            RETL_AccountSyncToYardi.pushToYardiAsync(res.accountId); // TODO Dynamic
                        }
                    }

                    // Parse semicolon-separated Brand Account Ids
                    List<Id> brandIds = new List<Id>();
                    if (!String.isBlank(req.selectedBrandIds)) {
                        for (String s : req.selectedBrandIds.split(';')) {
                            if (!String.isBlank(s)) {
                                brandIds.add((Id)s.trim());
                            }
                        }
                    }

                    // Insert Brand Linkages
                    if (!brandIds.isEmpty()) {
                        List<RETL_Brand_Linkage__c> brandLinkagesToInsert = new List<RETL_Brand_Linkage__c>();
                        for (Id brandId : brandIds) {
                            brandLinkagesToInsert.add(new RETL_Brand_Linkage__c(
                                RETL_Customer__c = res.accountId,
                                RETL_Brand__c = brandId
                            ));
                        }
                        insert brandLinkagesToInsert;
                    }

                    // Insert Trade License Account ---
                    if (res.accountId != null) {
                        Id orgAccountRTId = getRecordTypeId('Account', req.AccountRecordTypeName);
                        if (orgAccountRTId != null) {
                            // Fetch the name of the newly converted Account
                            Account convertedAccount = [SELECT Name FROM Account WHERE Id = :res.accountId LIMIT 1];
                            
                            Account tradeLicenseAccount = new Account(
                                Name = convertedAccount.Name + ' (Trade License)',
                                Type = 'Trade License', 
                                RecordTypeId = orgAccountRTId,
                                ParentId = res.accountId, // Link it to the main converted Account
                                RETL_Status__c = 'Data Missing' ,
                                ECSS_Trade_License_Number__c = ld.RETL_Trade_License_No__c,
                                RETL_Trade_License_Issuing_Authority__c =ld.RETL_Trade_License_Issuing_Authority__c
                            );
                            insert tradeLicenseAccount;
                            res.tradeLicenseAccountId = tradeLicenseAccount.Id;
                            // Run the async Yardi push
                            if(!test.isRunningTest()){
                               // RETL_AccountSyncToYardi.pushToYardiAsync(tradeLicenseAccount.id);  Push to Custom table Pending
                            }
                            
                            //System.enqueueJob(new RETL_ContactYardiSyncQueueable(res.contactId));
                            
                        } else {
                            // Log or handle error if the Organnization_Account RecordType is not found
                            System.debug('Error: Account RecordType \'Organnization_Account\' not found.');
                            // For simplicity, we'll continue, but a stricter implementation might rollback or log a failure.
                        }
                    }
                } else {
                    // Rollback if Lead conversion fails
                    Database.rollback(sp);
                    res.success = false;
                    res.errorMessage = (
                        lcr.getErrors().isEmpty() 
                        ? 'Unknown error during conversion' 
                        : lcr.getErrors()[0].getMessage()
                    );
                }
            } catch (Exception e) {
                // Rollback if any unexpected error occurs
                Database.rollback(sp);
                res.success = false;
                //res.errorMessage = e.getMessage();
                res.errorMessage = getFriendlyErrorMessage(e);
            }

            responses.add(res);
        }

        return responses;
    }

    public static void linkBrandProfileDocToOpportunity(String oppId, String leadId){
        List<Document__c> docToUpdate = new List<Document__c>();
        for( Document__c doc:[SELECT Id, Lead__c, Opportunity__c 
                              FROM Document__c 
                              WHERE DocumentType__c ='Brand Profile' AND Lead__c =: leadId ]){
            doc.Opportunity__c = oppId;
            docToUpdate.add(doc);
        }
        if(!docToUpdate.isEmpty()){
            Update docToUpdate;
        }
    }

    private static String getFriendlyErrorMessage(Exception e) {
        String msg = e.getMessage();
        
        if (msg == null) return 'An unknown error occurred. Please contact your admin.';

        // Remove row/tech details
        msg = msg.replaceAll('(?i)first exception on row \\d+; first error: ', '');
        msg = msg.replaceAll('ConvertLead failed\\. ', '');
        msg = msg.replaceAll(': \\[\\]$', ''); // remove trailing []

        // Optionally strip error codes like INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST
        msg = msg.replaceAll('^[A-Z_]+, ', '');

        // Trim whitespace
        msg = msg.trim();

        return msg;
    }

    private static Id getRecordTypeId(String objectApiName, String developerName) {
        if (String.isBlank(developerName)) return null;
        Map<String, Id> cache = new Map<String, Id>();

        // Query once per call
        for (RecordType rt : [
            SELECT Id, DeveloperName, SObjectType 
            FROM RecordType 
            WHERE SObjectType = :objectApiName
        ]) {
            cache.put(rt.DeveloperName, rt.Id);
        }
        return cache.containsKey(developerName) ? cache.get(developerName) : null;
    }

    //
    public static void createOpportunityContactRoles(
        Id contactId, 
        Id accountId, 
        Id opportunityId,
        String contactName
    ) {
        // 1. Define the roles in a simple list of strings
        List<String> roleNames = new List<String>{
            'Customer Leasing Manager',
            'Leasing Manager'
        };

        // 2. Create a list to hold all new records
        List<RETL_Contact_role__c> rolesToInsert = new List<RETL_Contact_role__c>();

        // 3. Loop through the role names to create records
        for (String roleName : roleNames) {
            
            // Use a boolean to determine primary status based on the role name
            Boolean isPrimary = (roleName == 'Customer Leasing Manager');
            
            RETL_Contact_role__c newRole = new RETL_Contact_role__c(
                // Set fields using the passed parameters and current role name
                Name                    = contactName, 
                RETL_Account_Name__c    = accountId,   
                RETL_Opportunity__c     = opportunityId, // Assuming this field exists
                RETL_Contact_role__c    = roleName, 
                RETL_Contact__c         = contactId,   
                RETL_Primary__c         = isPrimary // Set based on the conditional check
            );
            
            rolesToInsert.add(newRole);
        }

        // 4. Perform a single DML operation (Bulkification)
        if (!rolesToInsert.isEmpty()) {
            insert rolesToInsert;
            System.debug('Successfully created ' + rolesToInsert.size() + ' Contact Roles.');
        }
    }


}