/**********************************************************************************************************************
* Name               : EmailCommPreferenceController                                                        
* Description        : Controller Class for EmailCommPreferencePage VFPage used to send User Communication Preference via SendGrid's REST API
* Created By         : Harsh@Aldar                                                    
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           hrohilla@aldar.com     15/09/2023      Initial Draft       
******************************************************************************************************************/
global with sharing class EmailCommPreferenceController {
    
    public String accountName { get; set; }
    public String accountId { get; set; }
    //to make the options dynamic in future
    public List<String> options { get; set; }
    public static Blob encryptionKey = Blob.valueOf(Label.EmailCommPrefEncryptionKey);
    public Boolean killSwitch {get; set;}
    public String refreshTokenFromURL {get; set;}

    public EmailCommPreferenceController() {
        //[Harsh 03/11] ToDo take acc id in with sharing context, save in a backend field, then fire an event and seach for account loopkup and populate -- get rid of without sharing
        String encryptedAccountId = ApexPages.currentPage().getParameters().get('id');
        String refreshToken = ApexPages.currentPage().getParameters().get('token');
        refreshTokenFromURL = refreshToken;
        killSwitch = false;
        String decryptedAccountId = decryptAccountId(encryptedAccountId);
        // String decryptedAccountId = encryptedAccountId;
        if (String.isNotBlank(decryptedAccountId)) {
            Communication_Preference__c prefRecord = getCommPrefRecord(decryptedAccountId, false);
            accountName = prefRecord.Account_Name__c;
            accountId = prefRecord.Account__c;
            // account = [SELECT Id, Name FROM Account WHERE Id = :decryptedAccountId LIMIT 1];
            //USER HAS REFRESHED THE PAGE
            if(prefRecord != null && prefRecord.PreferenceToken__c != refreshToken){
                killSwitch = true;
            }
            if(prefRecord == null){
                killSwitch = true;
            }
        }

        // Load options from a custom label
        String customLabelValue = Label.EmailCommPrefEncryptionOptions;
        options = new List<String>();
        for (String optionValue : customLabelValue.split(',')) {
            options.add(optionValue.trim());
        }
    }

    public static String generateURL(String accountId){
        // Encrypt the accountId
        String encryptedAccountId = encryptAccountId(accountId);
        String refreshToken = generateToken(accountId);

        // Construct the URL
        PageReference pageRef = Page.EmailCommPreferencePage;
        pageRef.getParameters().put('id', encryptedAccountId);
        pageRef.getParameters().put('token', refreshToken);

        // Generate the URL
        String url = Label.EmailCommPrefSite + pageRef.getUrl();
        return url;
    }

    @RemoteAction
    public static String getCheckboxValues(Map<String, Boolean> checkboxValues, String accountId, String refreshToken) {

        if (checkboxValues != null && !checkboxValues.isEmpty()) {

            List<String> selectedValues = new List<String>();

            // Loop through the checkbox values
            for (String checkboxId : checkboxValues.keySet()) {
                Boolean isChecked = checkboxValues.get(checkboxId);

                // Check if the checkbox is checked (true)
                if (isChecked) {
                    selectedValues.add(checkboxId);
                }
            }

            //clear Account refresh token so one link can only be used once
            // Account accountToUpdate = new Account(Id = accountId, PreferenceToken__c = '');
            Communication_Preference__c prefRecord = getCommPrefRecordWithToken(accountId);
            if(prefRecord != null){
                prefRecord.PreferenceToken__c = null;
                prefRecord.ContainsToken__c = false;
                prefRecord.Account__c = accountId;
            }

            // Check if there are records to be created
            if (!selectedValues.isEmpty()) {
                Communication_Preference__c record = new Communication_Preference__c();
                record.Account__c = accountId;
                record.Type__c = String.join(selectedValues, ';'); // Combine selected values into a semicolon-separated string
                record.Active__c = true;
                //text id field
                record.AccountId__c = accountId;

                // Insert the records into the database
                try {
                    disableExisting(accountId);
                    // insert record;
                    SendGridWithoutSharingUtil.doDML_SingleObject(record, 'insert');
                    if(prefRecord != null) {SendGridWithoutSharingUtil.doDML_SingleObject(prefRecord, 'update');}
                } catch (Exception e) {
                    // Handle any exceptions that may occur during insertion
                    System.debug('Error: ' + e.getMessage());
                    return 'error';
                }
            }
        }
        return 'success';
    }

    // Method to decrypt the Account Id
    // Implement decryption logic here
    // Use Crypto.decryptWithManagedIV with encryption key
    // Return the decrypted Id
    @TestVisible
    private String decryptAccountId(String encryptedId) {
        
        Blob decryptedAccountBlob = Crypto.decryptWithManagedIV('AES256', encryptionKey, EncodingUtil.base64Decode(encryptedId));
        String decryptedAccountId = decryptedAccountBlob.toString();
        return decryptedAccountId;

    }
    @TestVisible
    private static String encryptAccountId(String accountId){
        String encryptedAccountId = EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES256', encryptionKey, Blob.valueOf(accountId)));
        return encryptedAccountId;
    }
    @TestVisible
    private static void disableExisting(Id accId){
        List<Communication_Preference__c> recordsToDisable = new List<Communication_Preference__c>();
        for(Communication_Preference__c record: [SELECT Id, Active__c FROM Communication_Preference__c WHERE Account__c =: accId AND Active__c = true AND Category__c = 'Communication preference' ]){
            record.Active__c = false;
            record.Disabled_Date__c = System.today();
            recordsToDisable.add(record);
        }

        // update recordsToDisable;
        SendGridWithoutSharingUtil.doDML_List(recordsToDisable, 'update');
    }
    @TestVisible
    private static String generateToken(String accountId){

        // Define the characters that can be used in the token
        String characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

        // Initialize a string to store the token
        String token = '';

        // Generate the token by selecting random characters from the allowed characters
        for (Integer i = 0; i < 24; i++) {
            Integer randomIndex = Math.mod(Math.abs(Crypto.getRandomInteger()), characters.length());
            token += characters.substring(randomIndex, randomIndex + 1);
        }

        Communication_Preference__c record = getCommPrefRecord(accountId, true);

        Communication_Preference__c  thisCommPrefRec = new Communication_Preference__c( Id = record.Id, 
                                                                                        PreferenceToken__c = token, 
                                                                                        ContainsToken__c = true, 
                                                                                        Account__c = accountId, 
                                                                                        AccountId__c = accountId, 
                                                                                        Active__c = false);

        SendGridWithoutSharingUtil.doDML_SingleObject(thisCommPrefRec, 'upsert');

        // Return the generated token
        return token;

    }   

    private static Communication_Preference__c getCommPrefRecord(String accountId, Boolean create){
        List<Communication_Preference__c> recordList = [SELECT Id, AccountId__c, Account_Name__c, Active__c, Account__c, Type__c, PreferenceToken__c 
                                                        FROM Communication_Preference__c 
                                                        WHERE AccountId__c =: accountId 
                                                        AND Category__c = 'Communication preference'
                                                        ORDER BY CreatedDate DESC
                                                        ];


        if(recordList.size() > 0){
            return recordList[0];
        }else if(create){
            Communication_Preference__c record = new Communication_Preference__c();
            record.Account__c = accountId;
            record.Type__c = null;
            // record.Active__c = false;
            record.AccountId__c = accountId;
            return record;
        }else{
            return null;
        }
    }

    private static Communication_Preference__c getCommPrefRecordWithToken(String accountId){
        List<Communication_Preference__c> recordList = [SELECT Id, AccountId__c, Account_Name__c, Active__c, Account__c, Type__c, ContainsToken__c, PreferenceToken__c 
                                                        FROM Communication_Preference__c 
                                                        WHERE AccountId__c =: accountId 
                                                        AND ContainsToken__c = TRUE 
                                                        AND Category__c = 'Communication preference'
                                                        ORDER BY CreatedDate DESC];

        if(recordList.size() > 0){
            return recordList[0];
        }else{
            return null;
        }
    }
}