/**
 * @description
 * Handles synchronization of Contact and Contact Role data from Salesforce to Yardi via MuleSoft.
 * This class constructs the request payload using Contact and related Contact Role records,
 * performs a callout to MuleSoft, and updates Salesforce with Yardi Contact and Contact Role IDs.
 *
 * @author
 * vkotaprolu@aldar.com
 * @date
 * 2025-10-08
 */
public with sharing class RETL_ContactAndContactRoleSyncToYardi {

    /**
     * Wrapper class representing the Yardi contact payload.
     * Includes primary Contact data and related Contact Associations.
     */
    public class YardiContactRequestWrapper {
        public String firstName;
        public String lastName;
        public String email;
        public String phone;
        public String parentAccountId;
        public List<YardiContactAssociation> contactAssociations;
        public String sfRefContactId;
        public String country;
        public String yardiContactCode;
    }

    /**
     * Wrapper for each Contact Association record sent in the request.
     */
    public class YardiContactAssociation {
        public String role;
        public String entityId;
        public String type;
        public Integer isPrimary;
        public String SFId;
        public String YardiId;
    }

    /**
     * Wrapper class representing the Yardi API response.
     * Includes the overall Yardi Contact Code and related association responses.
     */
    public class YardiContactResponseWrapper {
        public String firstName;
        public String lastName;
        public String email;
        public String phone;
        public String parentAccountId;
        public List<YardiContactAssociationResponse> contactAssociations;
        public String sfRefContactId;
        public String country;
        public String yardiContactCode;
    }

    /**
     * Wrapper for each Contact Association record returned in the response.
     */
    public class YardiContactAssociationResponse {
        public String Yardi_Contact_Code; // Yardi Id of the Contact 
        public String Status;
        public String ErrorMessage;
        public String SF_ContactAssociation_Id;
        public String Y_ContactAssociation_Id; // Yardi Id of the Contact Role
    }

    /**
     * Asynchronous version of the main callout method.
     * Can be invoked from triggers or batch jobs to avoid mixed DML or synchronous limits.
     *
     * @param contactId  - Salesforce Contact record Id.
     * @param isSandbox  - Boolean flag to choose Sandbox or Production URL.
     */
    @future(callout=true)
    public static void pushToYardiAsync(Id contactId, Boolean isSandbox) {
        pushToYardiAndUpdate(contactId, isSandbox);
    }

    /**
     * Core method to push Contact and related Contact Role data to Yardi.
     * It constructs the request body, performs the HTTP callout using MuleSoft configuration,
     * parses the response, and updates Salesforce records with returned Yardi IDs.
     *
     * @param contactId  - Salesforce Contact record Id to be synchronized.
     * @param isSandbox  - Boolean flag to choose Sandbox or Production URL from MuleSoft metadata.
     */
    public static void pushToYardiAndUpdate(Id contactId, Boolean isSandbox) {
        String className = 'RETL_ContactAndContactRoleSyncToYardi';
        String methodName = 'pushToYardiAndUpdate';
        HttpResponse response;

        try {
            if (contactId == null){
                throw new CustomException('Contact Id cannot be null.');
            }

            // Step 1: Build payload wrapper for Yardi
            YardiContactRequestWrapper contactData = buildContactWrapper(contactId);
            if (contactData == null){
                throw new CustomException('Unable to construct Yardi Contact payload.');
            }

            // Step 2: Fetch MuleSoft endpoint configuration            
            MuleSoftSetting__mdt api = Utilities.getMuleSoftDetails('RETL_ContactAndContactRoleSyncToYardi');

            if (api == null){
                throw new CustomException('Yardi API configuration not found in MuleSoftSetting__mdt.');
            }

            // Step 3: Serialize payload to JSON
            String requestBody = JSON.serialize(contactData);
            System.debug('Yardi Request Body: ' +  requestBody);

            // Step 4: Perform callout using the shared MuleSoft callout method
            response = CalloutToMuleSoft.makeCallout(api.DeveloperName, requestBody);
            if (response == null){
                throw new CustomException('No response received from Yardi endpoint.');
            }

            Integer statusCode = response.getStatusCode();
            String resBody = response.getBody();
            System.debug('Response Code: ' + statusCode);
            System.debug('Response Body: ' + resBody);

            // Step 5: Parse response and update Salesforce
            if (statusCode >= 200 && statusCode < 300 && !String.isBlank(resBody)) {
                YardiContactResponseWrapper resWrapper =
                    (YardiContactResponseWrapper) JSON.deserialize(resBody, YardiContactResponseWrapper.class);

                // Update Contact record with Yardi Contact Code
                if (!String.isBlank(resWrapper.yardiContactCode)) {
                    update new Contact(
                        Id = resWrapper.sfRefContactId,
                        RETL_Yardi_Id__c = resWrapper.yardiContactCode
                    );
                    System.debug('Updated Contact with Yardi Contact Code: ' + resWrapper.yardiContactCode);
                }

                // Update Contact Role records with returned Yardi IDs
                if (resWrapper.contactAssociations != null && !resWrapper.contactAssociations.isEmpty()) {
                    List<RETL_Contact_role__c> rolesToUpdate = new List<RETL_Contact_role__c>();

                    for (YardiContactAssociationResponse assocRes : resWrapper.contactAssociations) {
                        if (!String.isBlank(assocRes.SF_ContactAssociation_Id) &&
                            !String.isBlank(assocRes.Yardi_Contact_Code)&&
                            !String.isBlank(assocRes.Y_ContactAssociation_Id)) {

                            rolesToUpdate.add(new RETL_Contact_role__c(
                                Id = assocRes.SF_ContactAssociation_Id,
                                RETL_Yardi_Id__c = assocRes.Y_ContactAssociation_Id
                            ));
                        }

                        System.debug('Contact Role Response => SFId: ' + assocRes.SF_ContactAssociation_Id +
                                     ', YardiId: ' + assocRes.Y_ContactAssociation_Id +
                                     ', Status: ' + assocRes.Status +
                                     ', Message: ' + assocRes.ErrorMessage);
                    }

                    if (!rolesToUpdate.isEmpty()) {
                        update rolesToUpdate;
                        System.debug('Updated ' + rolesToUpdate.size() + ' Contact Roles with Yardi IDs.');
                    }
                }
            } else {
                // Handle failed responses
                String errMsg = 'Contact or Contact Role Sync to Failed: ' + statusCode + ' | Body: ' + resBody;
                //Utilities.sendExceptionEmail(className, methodName, errMsg, 'Contact or Contact Role Sync to Failed', null);
                LoggerService.save(
                LoggerService.addApexServiceCalls(
                    'ContactAndContactRoleSyncToYardi',              // Process name
                    className,                         // Class name
                    methodName,                        // Method name
                    'requestBody: ' + requestBody,     // Request body for traceability
                    errMsg,                           // Response body
                    null                          // No Lookup for Mapping Related Contact record ID
                )
            );
                System.debug('Yardi Push Failure: ' + errMsg);
            }

        } catch (Exception e) {
            // Handle and log exceptions            
            //Utilities.sendExceptionEmail(className,methodName,'Exception while pushing Contact and Contact Roles to Yardi: ' + e.getMessage(),'Yardi Push Exception', e);
            LoggerService.save(LoggerService.addApexLog(e,'Contact and Roles Sync to Yardi',className,methodName));
            throw e;            
        }
    }

    /**
     * Constructs the Yardi request wrapper using Contact and related Contact Role data.
     * Queries the Salesforce records and maps field values into the wrapper structure.
     *
     * @param contactId - Salesforce Contact record Id.
     * @return YardiContactRequestWrapper object populated with Contact and Role details.
     */
    @Testvisible
    private static YardiContactRequestWrapper buildContactWrapper(Id contactId) {
        Contact con = [
            SELECT Id, FirstName, LastName, Email, Phone, MobilePhone, AccountId, MailingCountry ,RETL_Yardi_Id__c
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];

        List<RETL_Contact_role__c> roles = [
            SELECT Id, RETL_Contact_role__c, RETL_Account_Name__c, RETL_Lease__c, RETL_Account_Name__r.RETL_Yardi_Id__c,
                    RETL_Lease__r.RETL_Yardi_Id__c, RETL_Primary__c, RETL_Yardi_Id__c,RETL_Role_Type__c
            FROM RETL_Contact_role__c
            WHERE RETL_Contact__c = :con.Id
        ];

        YardiContactRequestWrapper wrapper = new YardiContactRequestWrapper();
        wrapper.firstName = con.FirstName;
        wrapper.lastName = con.LastName;
        wrapper.email = con.Email;
        //wrapper.phone = con.Phone;
        wrapper.phone = con.MobilePhone;
        wrapper.parentAccountId = con.AccountId;
        wrapper.sfRefContactId = con.Id;
        wrapper.country = String.isBlank(con.MailingCountry) ? '' : con.MailingCountry;
        wrapper.yardiContactCode = con.RETL_Yardi_Id__c!=NULL?con.RETL_Yardi_Id__c:null;
        wrapper.contactAssociations = new List<YardiContactAssociation>();

        for (RETL_Contact_role__c role : roles) {
            YardiContactAssociation assoc = new YardiContactAssociation();
            assoc.role = role.RETL_Contact_role__c;
            assoc.entityId = role.RETL_Lease__c!=NULL?role.RETL_Lease__r.RETL_Yardi_Id__c : role.RETL_Account_Name__r.RETL_Yardi_Id__c;
            //assoc.type = role.RETL_Lease__c!=NULL?'Tenant':'Customer';//role.Type__c;
            assoc.type = role.RETL_Lease__c!=NULL?'Tenant':role.RETL_Role_Type__c!=NULL?role.RETL_Role_Type__c:'Customer';  // Role types  Input given by Vyankatesh on 2025 Nov 20         
            assoc.isPrimary = (role.RETL_Primary__c == true ? -1 : 0); //-1 to be passed for True passing 1 is not working on Yardi, Input given by Vyankatesh on 2025 Nov 20
            assoc.SFId = role.Id;
            assoc.YardiId = role.RETL_Yardi_Id__c;
            wrapper.contactAssociations.add(assoc);
        }

        return wrapper;
    }

    /**
     * Custom exception used to handle application-level errors within this integration.
     */
    public class CustomException extends Exception {}

    // Call from Flow once Account yardi Id is avalibale on Lead conversion


    /**
     * @description
     * Invocable method for Flow — triggers async Contact + Role push to Yardi.
     * Calls the existing @future method internally to handle callouts asynchronously.
     */
    public class FlowInputSimple {
        @InvocableVariable(required=true description='Contact Id to sync with Yardi')
        public Id contactId;        
    }

    @InvocableMethod(
        label='Push Contact & Roles to Yardi (Async)'
        description='Triggers async Yardi sync for Contact and related Roles using the RETL_ContactAssoicationToYardi.pushToYardiAsync method.'
        category='RETL Yardi Integration'
    )
    public static void pushContactToYardiAsyncFromFlow(List<FlowInputSimple> requests) {
        if (requests == null || requests.isEmpty()) return;

        for (FlowInputSimple req : requests) {
            if (req != null && req.contactId != null) {                
                RETL_ContactAndContactRoleSyncToYardi.pushToYardiAsync(req.contactId, true);
            }
        }
    }
}