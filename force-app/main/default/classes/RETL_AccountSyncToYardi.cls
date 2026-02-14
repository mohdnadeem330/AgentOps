/**
 * @description
 * Handles synchronization of Account (Customer) data from Salesforce to Yardi via MuleSoft.
 * This class constructs the request payload using Account details,
 * performs a callout to MuleSoft, and updates Salesforce with Yardi Customer Codes.
 *
 * @author
 * vkotaprolu@aldar.com
 * @date
 * 2025-10-17
 */
public with sharing class RETL_AccountSyncToYardi implements Queueable, Database.AllowsCallouts {

    private Id accountId;

    public RETL_AccountSyncToYardi(Id accountId) {
        this.accountId = accountId;
    }

    /**
     * Wrapper class representing the Yardi Customer request payload.
     * Includes the list of Customer objects to be sent.
     */
    public class YardiCustomerRequestWrapper {
        public List<Customer> Customer;

        public YardiCustomerRequestWrapper() {
            Customer = new List<Customer>();
        }
    }

    /**
     * Wrapper for each Customer record in the request.
     */
    public class Customer {
        public String SF_Ref_Customer_Id;
        public String Customer_Name;
        public String Customer_Type;
        public String Yardi_Customer_Code;
        public String Customer_Parent;
        public String Customer_Status;
        public String Preferred_Language;
        public String Sales_Category;
        public String Notes;
        /*public String UserDefined_1;
        public String UserDefined_2;
        public String UserDefined_3;
        public String UserDefined_4;
        public String UserDefined_5;
        public String UserDefined_6;*/
        public String VATRegistration_Number;
        public String TaxAuthority;
    }

    /**
     * Wrapper class representing the Yardi Customer API response.
     */
    public class YardiCustomerResponseWrapper {
        public String Yardi_Customer_Code;
        public String Status;
        public String ErrorMessage;
        public String SF_Ref_Customer_Id;
    }

    /**
     * Asynchronous version of the main callout method.     
     * @param accountId  - Salesforce Account record Id.     
     */
    public static void pushToYardiAsync(Id accountId) {
        System.enqueueJob(new RETL_AccountSyncToYardi(accountId));
    }

    public void execute(QueueableContext context) {
        pushToYardiAndUpdate(this.accountId);
    }

    /**
     * Core method to push Account (Customer) data to Yardi via MuleSoft.
     * Constructs the request payload, performs the callout, parses response,
     * and updates the Salesforce Account record with the returned Yardi Customer Code.
     *
     * @param accountId  - Salesforce Account record Id to be synchronized.     
     */
    public static void pushToYardiAndUpdate(Id accountId) {
        String className = 'RETL_AccountSyncToYardi';
        String methodName = 'pushToYardiAndUpdate';
        HttpResponse response;

        try {
            if (accountId == null){
                throw new CustomException('Account Id cannot be null.');
            }

            // Step 1: Build payload wrapper for Yardi
            YardiCustomerRequestWrapper reqWrapper = buildAccountWrapper(accountId);
            if (reqWrapper == null || reqWrapper.Customer.isEmpty()){
                throw new CustomException('Unable to construct Yardi Account payload.');
            }

            // Step 2: Fetch MuleSoft endpoint configuration            
            MuleSoftSetting__mdt api = Utilities.getMuleSoftDetails('RETL_AccountSyncToYardi');
            if (api == null){
                throw new CustomException('Yardi API configuration not found in MuleSoftSetting__mdt.');
            }

            // Step 3: Serialize payload to JSON
            String requestBody = JSON.serialize(reqWrapper);
            System.debug('Yardi Account Request Body: ' +  requestBody);

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
                YardiCustomerResponseWrapper resWrapper =
                    (YardiCustomerResponseWrapper) JSON.deserialize(resBody, YardiCustomerResponseWrapper.class);

                if (resWrapper != null && resWrapper.Status == 'Success' && !String.isBlank(resWrapper.Yardi_Customer_Code)) {
                    update new Account(
                        Id = accountId,
                        RETL_Yardi_Id__c = resWrapper.Yardi_Customer_Code
                    );
                    System.debug('Updated Account with Yardi Customer Code: ' + resWrapper.Yardi_Customer_Code);

                    //Get Contact Roles related to this Account
                    List<RETL_Contact_role__c> relatedContactRoles = [
                        SELECT Id, RETL_Contact__c, RETL_Account_Name__c
                        FROM RETL_Contact_role__c
                        WHERE RETL_Account_Name__c = :accountId AND RETL_Contact_role__c != 'Leasing Manager'
                    ];
                    Set<Id> relatedContactIds = new Set<Id>();
                    for (RETL_Contact_role__c role : relatedContactRoles) {
                        if (role.RETL_Contact__c != null) {
                            relatedContactIds.add(role.RETL_Contact__c);
                        }
                    }
                    if (!relatedContactIds.isEmpty()) {
                        //convert relatedContactIds set to list
                        List<Id> relatedContactIdsList = new List<Id>(relatedContactIds);
                        System.enqueueJob(new RETL_ContactYardiSyncQueueable(relatedContactIdsList, accountId));
                    }

                    /* for(Id conId : relatedContactIds){
                        System.debug('Related Contact Id: ' + conId);
                        System.enqueueJob(new RETL_ContactYardiSyncQueueable(conId));
                    } */
                    
                    /* 
                    //Get Contact from under this Account
                    List<Contact> relatedContacts = [
                        SELECT Id
                        FROM Contact
                        WHERE AccountId = :accountId and Email != :UserInfo.getUserEmail() AND Title !='Aldar Leasing Manager'
                    ];

                    if (!relatedContacts.isEmpty()) {                            
                        System.enqueueJob(new RETL_ContactYardiSyncQueueable(relatedContacts[0].Id));                           
                        System.debug('Pushed ' + relatedContacts.size() + ' Contact(s) under Account ' + accountId + ' to Yardi.');
                    } 
                     */
                } else {
                    String errMsg = 'Yardi Account Sync Failed: ' + resWrapper.ErrorMessage;
                    LoggerService.save(
                        LoggerService.addApexServiceCalls(
                            'AccountSyncToYardi',
                            className,
                            methodName,
                            'Request: ' + requestBody,
                            'Response: ' + resBody,
                            null
                        )
                    );
                    System.debug('Yardi Push Failure: ' + errMsg);
                }

            } else {
                String errMsg = 'Account Sync to Yardi Failed: ' + statusCode + ' | Body: ' + resBody;
                LoggerService.save(
                    LoggerService.addApexServiceCalls(
                        'AccountSyncToYardi',
                        className,
                        methodName,
                        'RequestBody: ' + requestBody,
                        errMsg,
                        null
                    )
                );
                System.debug('Yardi Push Failure: ' + errMsg);
            }

        } catch (Exception e) {
            LoggerService.save(LoggerService.addApexLog(e, 'Account Sync to Yardi', className, methodName));
            throw e;
        }
    }

    /**
     * Constructs the Yardi request wrapper using Account data.
     *
     * @param accountId - Salesforce Account record Id.
     * @return YardiCustomerRequestWrapper object populated with Account details.
     */
    @TestVisible
    private static YardiCustomerRequestWrapper buildAccountWrapper(Id accountId) {
        Account acc = [
            SELECT Id, Name, Type, ParentId, RETL_Status__c,
                   RETL_SalesCategory__c, Description,
                   //UserDefined_1__c, UserDefined_2__c, UserDefined_3__c,
                   //UserDefined_4__c, UserDefined_5__c, UserDefined_6__c,
                   UAEVATRegisterNumber__c, RETL_Tax_Authority__c, RETL_Yardi_Id__c,RETL_Group__r.RETL_Yardi_Id__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        YardiCustomerRequestWrapper wrapper = new YardiCustomerRequestWrapper();
        Customer cust = new Customer();

        cust.SF_Ref_Customer_Id   = acc.Id;
        cust.Customer_Name        = String.isBlank(acc.Name) ? '' : acc.Name;
        cust.Customer_Type        = String.isBlank(acc.Type) ? '' : acc.Type;
        cust.Yardi_Customer_Code  = String.isBlank(acc.RETL_Yardi_Id__c) ? '' : acc.RETL_Yardi_Id__c;
        cust.Customer_Parent      = (acc.RETL_Group__r != null && !String.isBlank(acc.RETL_Group__r.RETL_Yardi_Id__c))
                                    ? acc.RETL_Group__r.RETL_Yardi_Id__c : '';
        cust.Customer_Status      = String.isBlank(acc.RETL_Status__c) ? 'Active' : acc.RETL_Status__c;
        cust.Preferred_Language   = 'English'; // Default static value
        cust.Sales_Category       = String.isBlank(acc.RETL_SalesCategory__c) ? '' : acc.RETL_SalesCategory__c;
        cust.Notes                = String.isBlank(acc.Description) ? '' : acc.Description;
        /*
        cust.UserDefined_1        = String.isBlank(acc.UserDefined_1__c) ? '' : acc.UserDefined_1__c;
        cust.UserDefined_2        = String.isBlank(acc.UserDefined_2__c) ? '' : acc.UserDefined_2__c;
        cust.UserDefined_3        = String.isBlank(acc.UserDefined_3__c) ? '' : acc.UserDefined_3__c;
        cust.UserDefined_4        = String.isBlank(acc.UserDefined_4__c) ? '' : acc.UserDefined_4__c;
        cust.UserDefined_5        = String.isBlank(acc.UserDefined_5__c) ? '' : acc.UserDefined_5__c;
        cust.UserDefined_6        = String.isBlank(acc.UserDefined_6__c) ? '' : acc.UserDefined_6__c;
        */
        cust.VATRegistration_Number = String.isBlank(acc.UAEVATRegisterNumber__c) ? '' : acc.UAEVATRegisterNumber__c;
        cust.TaxAuthority           = String.isBlank(acc.RETL_Tax_Authority__c) ? '' : acc.RETL_Tax_Authority__c;


        wrapper.Customer.add(cust);
        return wrapper;
    }

    /**
     * Custom exception used to handle application-level errors within this integration.
     */
    public class CustomException extends Exception {}
}