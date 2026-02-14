/*
* Name               : RETL_PortalContactCreation
* Description        : Class for Retail Tenant Contact Creation
* Created By          : Protiviti
* Version			 : V1.1 Added by Protiviti .
*/
@RestResource(urlMapping='/contactWithRole/*')
global with sharing class RETL_PortalContactCreation {
    // Holds the Id of an already existing Contact located during request validation.
    // Used to prevent duplicate Contact creation and to optionally provision a portal user.
    public static String existingContactId;

    /**
     * HTTP POST entry point: Creates a Contact and optionally related Contact Roles.
     * Process:
     * 1) Parse REST body and validate inputs (required fields, parent Account, Yardi Ids, duplicate roles).
     * 2) If a matching Contact was found during validation, reuse it (and provision portal user). Otherwise insert a new Contact.
     * 3) Create RETL_Contact_role__c records based on provided leaseTenantIds and/or customerIds when contactRole is supplied.
     * 4) Roll back if role creation is required but none are created, otherwise return a success response with created Ids.
     * Returns:
     *  - ContactResponse with success flag, message, contactId and created role Ids. Sets appropriate HTTP status via RestContext.
     */
    @HttpPost
    global static ContactResponse createContactWithRole() {
        Savepoint sp;
        try {
            // Parse and validate request
            ContactRequest req = parseAndValidateRequest();
            if (req == null) {
                return errorResponse(
                    new List<String>{'Request body is empty or invalid'},
                    400,
                    'Invalid request body'
                );
            }

            sp = Database.setSavepoint();

            // Find or create contact
            Id contactId ;
            system.debug('existingContactId'+existingContactId);
            if( existingContactId == null){
                system.debug('existingContactId'+existingContactId);
				 contactId  = insertContact(req);
            }
            else{
                contactId = existingContactId;
                createPortalUser(contactId);
            }

            if (contactId == null) {
                Database.rollback(sp);
                return errorResponse(
                    new List<String>{'Contact creation failed'},
                    400,
                    'Failed to create contact'
                );
            }

            // Create roles
            List<Id> roleIds = createContactRoles(contactId, req);

            // If role is required but none created → rollback
            Boolean roleRequired =
                (!String.isBlank(req.contactRole)) &&
                ((req.leaseTenantIds != null && !req.leaseTenantIds.isEmpty()) ||
                 (req.customerIds != null && !req.customerIds.isEmpty()));

            if (roleRequired && roleIds.isEmpty()) {
                Database.rollback(sp);
                return errorResponse(
                    new List<String>{'Contact Role creation failed'},
                    400,
                    'Failed to create contact role'
                );
            }

            // Success Response
            ContactResponse res = new ContactResponse();
            res.success = true;
            res.message = roleIds.isEmpty()
                ? 'Contact created successfully.'
                : 'Contact and Contact Roles created successfully.';
            res.contactId = contactId;
            res.contactRoleIds = roleIds;
            RestContext.response.statusCode = 201;
            return res;

        } catch (ValidationException vex) {
            if (sp != null) Database.rollback(sp);
            return errorResponse(vex.validationErrors, 400, 'Validation failed');
        } catch (Exception e) {
            if (sp != null) Database.rollback(sp);
            return errorResponse(
                new List<String>{'System error: ' + e.getMessage()},
                500,
                'Unexpected exception'
            );
        }
    }

    // -------------------- Contact Role Creation --------------------
    /**
     * Creates RETL_Contact_role__c records for a Contact.
     * For each Yardi Lease Id (Order.RETL_Yardi_Id__c) and/or Customer Id (Account.RETL_Yardi_Id__c) supplied in the request:
     *  - Resolves the related Order/Account
     *  - Inserts a role record with RETL_Contact_role__c = req.contactRole
     * Returns: list of inserted RETL_Contact_role__c Ids. Returns empty list when no valid targets are found.
     */
    private static List<Id> createContactRoles(Id contactId, ContactRequest req) {
        List<Id> roleIds = new List<Id>();
        List<RETL_Contact_role__c> rolesToInsert = new List<RETL_Contact_role__c>();

        // Leases
        Map<String, Id> leaseMap = new Map<String, Id>();
        if (req.leaseTenantIds != null && !req.leaseTenantIds.isEmpty()) {
            for (Order ord : [
                SELECT Id, RETL_Yardi_Id__c
                FROM Order
                WHERE RETL_Yardi_Id__c IN :req.leaseTenantIds
            ]) {
                leaseMap.put(ord.RETL_Yardi_Id__c, ord.Id);
            }
        }

        // Accounts
        Map<String, Id> accountMap = new Map<String, Id>();
        if (req.customerIds != null && !req.customerIds.isEmpty()) {
            for (Account acc : [
                SELECT Id, RETL_Yardi_Id__c
                FROM Account
                WHERE RETL_Yardi_Id__c IN :req.customerIds
            ]) {
                accountMap.put(acc.RETL_Yardi_Id__c, acc.Id);
            }
        }

        // Roles for Leases
        if (req.leaseTenantIds != null && !req.leaseTenantIds.isEmpty()) {
            for (String tenantId : req.leaseTenantIds) {
                if (!leaseMap.containsKey(tenantId)) continue;
                rolesToInsert.add(new RETL_Contact_role__c(
                    RETL_Contact__c = contactId,
                    RETL_Contact_role__c = req.contactRole,
                    RETL_Lease__c = leaseMap.get(tenantId),
                    Name = req.contactRole + ' Contact Role'
                ));
            }
        }

        // Roles for Customers
        if (req.customerIds != null && !req.customerIds.isEmpty()) {
            for (String custId : req.customerIds) {
                if (!accountMap.containsKey(custId)) continue;
                rolesToInsert.add(new RETL_Contact_role__c(
                    RETL_Contact__c = contactId,
                    RETL_Contact_role__c = req.contactRole,
                    RETL_Account_Name__c = accountMap.get(custId),
                    Name = req.contactRole + ' Contact Role'
                ));
            }
        }

        if (!rolesToInsert.isEmpty()) {
            insert rolesToInsert;
            for (RETL_Contact_role__c r : rolesToInsert) {
                roleIds.add(r.Id);
            }
        }
        return roleIds;
    }

    // -------------------- Validation --------------------
    /**
     * Validates the incoming request for Contact and Role creation.
     * Validations:
     *  - Required Contact fields: firstName, lastName, email, phone, parentAccountId
     *  - Parent Account exists
     *  - If any leaseTenantIds/customerIds provided, contactRole is required
     *  - Each provided Yardi Id (lease/account) must exist in Salesforce
     *  - If an existing Contact is found, prevents creating duplicate roles for the same Yardi Id(s)
     * Side effect:
     *  - Calls findContact(req) to populate existingContactId when possible.
     * Returns: list of validation error messages. Empty list means valid.
     */
    private static List<String> validateRequest(ContactRequest req) {
    List<String> errors = new List<String>();

    // 1. Required Contact Fields
    if (String.isBlank(req.firstName)) errors.add('First Name is required.');
    if (String.isBlank(req.lastName))  errors.add('Last Name is required.');
    if (String.isBlank(req.email))     errors.add('Email is required.');
    if (String.isBlank(req.phone))     errors.add('Phone is required.');
    String existingContactId;
    if(errors.isEmpty()){
          existingContactId = findContact(req) ;
    }
    // 2. Parent Account validation
    if (String.isBlank(req.parentAccountId)) {
        errors.add('Parent Account Id is required.');
    } else {
        if ([SELECT COUNT() FROM Account WHERE Id = :req.parentAccountId] == 0) {
            errors.add('Invalid Parent Account Id. No matching Account found.');
        }
    }

    // 3. Contact Role validation
    Boolean hasLeaseOrCustomer =
        (req.leaseTenantIds != null && !req.leaseTenantIds.isEmpty()) ||
        (req.customerIds != null && !req.customerIds.isEmpty());

    if (hasLeaseOrCustomer && String.isBlank(req.contactRole)) {
        errors.add('Invalid Designation or Designation missing.');
    }

    // 4. Validate Lease Ids
    Set<String> existingLeaseIds = new Set<String>();
    if (req.leaseTenantIds != null && !req.leaseTenantIds.isEmpty()) {
        Set<String> providedLeaseIds = new Set<String>(req.leaseTenantIds);
        for (Order ord : [
            SELECT RETL_Yardi_Id__c
            FROM Order
            WHERE RETL_Yardi_Id__c IN :providedLeaseIds
        ]) {
            existingLeaseIds.add(ord.RETL_Yardi_Id__c);
        }

        for (String idVal : providedLeaseIds) {
            if (!existingLeaseIds.contains(idVal)) {
                errors.add('Lease with Yardi Id ' + idVal + ' not found in Salesforce.');
            }
        }
    }

    // 5. Validate Customer Ids
    Set<String> existingCustIds = new Set<String>();
    if (req.customerIds != null && !req.customerIds.isEmpty()) {
        Set<String> providedCustIds = new Set<String>(req.customerIds);
        for (Account acc : [
            SELECT RETL_Yardi_Id__c
            FROM Account
            WHERE RETL_Yardi_Id__c IN :providedCustIds
        ]) {
            existingCustIds.add(acc.RETL_Yardi_Id__c);
        }

        for (String idVal : providedCustIds) {
            if (!existingCustIds.contains(idVal)) {
                errors.add('Account with Yardi Id ' + idVal + ' not found in Salesforce.');
            }
        }
    }
	system.debug('req.contactRole '+req.contactRole+ ' hasLeaseOrCustomer'+hasLeaseOrCustomer+' existingContactId'+existingContactId);
    // 6. Check if Contact Role already exists
    if (!String.isBlank(req.contactRole) && hasLeaseOrCustomer && existingContactId != 'No Contact Found' && existingContactId != null) {
        // Collect Yardi Ids to check
        Set<String> allYardiIds = new Set<String>();
        allYardiIds.addAll(req.leaseTenantIds != null && !req.leaseTenantIds.isEmpty()? req.leaseTenantIds : new List<String>());
        allYardiIds.addAll(req.customerIds != null && !req.customerIds.isEmpty()? req.customerIds : new List<String>());

        if (!allYardiIds.isEmpty()) {
            Map<String, String> roleExists = new Map<String, String>();
				system.debug('req.leaseTenantIds'+req.leaseTenantIds+'req.customerIds'+req.customerIds+'existingContactId'+existingContactId+'req.contactRole'+req.contactRole);
            for (RETL_Contact_role__c r : [
                SELECT Id, RETL_Lease__r.RETL_Yardi_Id__c,RETL_Account_Name__r.RETL_Yardi_Id__c
                FROM RETL_Contact_role__c
                WHERE RETL_Contact__c = :existingContactId AND RETL_Contact_role__c = :req.contactRole
                AND ( RETL_Lease__r.RETL_Yardi_Id__c IN :req.leaseTenantIds OR RETL_Account_Name__r.RETL_Yardi_Id__c IN :req.customerIds )
            ]) {
                if (r.RETL_Lease__r.RETL_Yardi_Id__c != null) {
                    roleExists.put(r.RETL_Lease__r.RETL_Yardi_Id__c, r.Id);
                } else if (r.RETL_Account_Name__r.RETL_Yardi_Id__c != null) {
                    roleExists.put(r.RETL_Account_Name__r.RETL_Yardi_Id__c, r.Id);
                }
            }

            for (String yId : allYardiIds) {
                if (roleExists.containsKey(yId)) {
                    errors.add('Designation ' + req.contactRole + ' already exists for Yardi Id ' + yId);
                }
            }
        }
    }

    System.debug('errors => ' + errors);
    return errors;
}


    /**
     * Parses the REST request body into ContactRequest and executes validateRequest.
     * Behavior:
     *  - Returns null if body is empty or invalid JSON.
     *  - Throws ValidationException when validation errors exist.
     * Returns: ContactRequest when parsing and validation pass.
     */
    private static ContactRequest parseAndValidateRequest() {
        String body = RestContext.request?.requestBody?.toString();
        if (String.isBlank(body)) return null;

        ContactRequest req;
        try {
            req = (ContactRequest) JSON.deserialize(body, ContactRequest.class);
        } catch (Exception er) {
            return null;
        }

        if (req == null) return null;

        List<String> validationErrors = validateRequest(req);
        system.debug('validationErrors'+validationErrors);
        if (!validationErrors.isEmpty()) {
            throw new ValidationException(validationErrors);
        }
        return req;
    }

    // -------------------- Contact --------------------
    /**
     * Finds an existing Contact by email with RecordType.Name = 'Contact'.
     * Side effect: assigns class static 'existingContactId' when a match is found.
     * Returns: the Contact Id string, or 'No Contact Found' when none exist.
     */
    private static String findContact(ContactRequest req) {
        List<Contact> existingContacts = !String.isBlank(req.email)
            ? [SELECT Id FROM Contact WHERE Email = :req.email AND RecordType.Name = 'Contact' LIMIT 1]
            : new List<Contact>();

        if (!existingContacts.isEmpty()) {
            existingContactId = existingContacts[0].Id;
            return existingContacts[0].Id;
        }
        return 'No Contact Found';
    }

    /**
     * Inserts a Contact using the 'Contact' record type and fields supplied in the request.
     * On successful insert, attempts to provision a portal user asynchronously via createPortalUser.
     * Errors are logged using LoggerService and surfaced as debug logs; method always returns the Contact Id (may be null on failure).
     */
    private static Id insertContact(ContactRequest req) {
        Id recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName()
            .get('Contact').getRecordTypeId();
        Contact con = new Contact(
            FirstName = req.firstName,
            LastName  = req.lastName,
            Email     = req.email,
            EmailAddress__c = req.email,
            MobilePhone     = req.phone,
            AccountId = req.parentAccountId,
            RecordTypeId = recordTypeId
        );
        try{
            insert con;
            if(con.Id != null){
                Organization org = Utilities.getOrganizationDetails();
                Boolean isSandbox  = org.IsSandbox;
                RETL_ContactAndContactRoleSyncToYardi.pushToYardiAsync(con.Id, isSandbox);  // Pass Contact Id  and Is Sandbox
                createPortalUser(con.Id);
            }
        }
        catch (DmlException e) {
                System.debug('Error creating portal user: ' + e.getMessage());
                LoggerService.save(LoggerService.addApexLog(e,'RetailPortalContactCreationFailed','RETL_PortalContactCreation','insertContact'));
        }
        return con.Id;
    }

    // -------------------- Error Helper --------------------
    /**
     * Helper to build an error response and set HTTP status code.
     * Parameters:
     *  - errors: list of error messages to include in response
     *  - statusCode: HTTP status code to set on RestContext.response
     *  - msg: top-level message; if null, first error message is used
     * Returns: ContactResponse with success=false and provided error details.
     */
    private static ContactResponse errorResponse(List<String> errors, Integer statusCode, String msg) {
        RestContext.response.statusCode = statusCode;
        ContactResponse res = new ContactResponse();
        res.success = false;
        res.message = msg != null ? msg : (errors != null && !errors.isEmpty() ? errors[0] : 'Error occurred');
        res.errors = errors != null ? errors : new List<String>();
        return res;
    }

    /**
     * Future method that provisions a portal User for the given Contact.
     * Steps:
     *  - Resolve Profile by Custom Label Retail_Tenant_Portal_Profile
     *  - Create Username from email prefix + contactId + domain suffix
     *  - Insert User without triggering email, set basic preferences
     *  - Mark Contact.Is_User_Created__c = true
     *  - Assign Permission Set given by Custom Label Retail_Tenant_Portal_Permission_Set
     * All DML exceptions are logged via LoggerService.
     */
    
    public static void createPortalUser(Id contactId) {
        Database.executeBatch(new RETL_PortalUserCreationBatch(new List<Id>{contactId}, true), 1);
    }

    // -------------------- Wrappers --------------------
    /**
     * Request DTO for Contact and Contact Role creation coming from REST body.
     * Fields:
     *  - firstName, lastName, email, phone, parentAccountId
     *  - leaseTenantIds: List of Yardi Lease Ids (Order.RETL_Yardi_Id__c)
     *  - customerIds: List of Yardi Customer Ids (Account.RETL_Yardi_Id__c)
     *  - contactRole: Role name to create on RETL_Contact_role__c
     */
    global class ContactRequest {
        public String firstName;
        public String lastName;
        public String email;
        public String phone;
        public String parentAccountId;
        public List<String> leaseTenantIds = new List<String>();
        public List<String> customerIds = new List<String>();
        public String contactRole;
    }

    /**
     * Response DTO returned by the REST method.
     * Fields:
     *  - success: operation result
     *  - message: summary
     *  - contactId: created/found Contact Id
     *  - contactRoleIds: created role Ids (may be empty)
     *  - errors: validation/system error messages when any
     */
    global class ContactResponse {
        public Boolean success;
        public String message;
        public Id contactId;
        public List<Id> contactRoleIds = new List<Id>();
        public List<String> errors = new List<String>();
    }

    // -------------------- Custom Exception --------------------
    /**
     * Custom exception carrying validation errors produced by validateRequest.
     */
    public class ValidationException extends Exception {
        public List<String> validationErrors;
        public ValidationException(List<String> errors) {
            validationErrors = errors;
        }
    }
}