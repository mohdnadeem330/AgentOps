public class BrokerAgentsController {
    

    public class AgentInformation {

        @AuraEnabled
        public Contact contactRecord {get;set;}
        
        @AuraEnabled
        public User userRecord {get;set;}

        @AuraEnabled
        public String realMobile {get;set;}
        @AuraEnabled
        public String realEmail {get;set;}

    }

    @AuraEnabled(cacheable=false)
    public static List<AgentInformation> getContacts(){
        // Updated By Moh Sarfaraj for BPE-110, BPM-355
        Map<Id, Contact> contactsList = new Map<Id,Contact>([SELECT Id, Salutation, Name, FirstName, LastName, Email, 
                                                             MailingCity, MailingCountry, MobilePhone, Account.Name, 
                                                             Account.BillingCity, AccountId, BrokerType__c, Birthdate, 
                                                             MobileCountryCode__c, MobilePhone__c, AgentStatus__c, 
                                                             AgentID__c, NationalIdNumber__c, NationalIdExpiryDate__c, 
                                                             PrimaryOwner__c, PrimaryAgencyAdmin__c, Account.BillingState,
                                                             Account.BillingCountry, BlockedFromBackend__c, Nationality__c,
                                                             PassportNumber__c, PassportExpiryDate__c
                                                             FROM Contact]);

        List<User> usersList = [SELECT Id, ContactId, IsActive, RoleName__c, Phone, Username FROM User WHERE ContactId in : contactsList.keySet()];

        List<AgentInformation> agentsList = new List<AgentInformation>();
        Set<Id> addedContacts = new Set<Id>();
        for(User userRec : usersList){

            AgentInformation agent = new AgentInformation();

            agent.userRecord = userRec;
            Contact con = contactsList.get(userRec.ContactId);
            addedContacts.add(userRec.ContactId);
                
            agent.realMobile = (con.MobileCountryCode__c != null && con.MobilePhone__c != null) ? (con.MobileCountryCode__c+con.MobilePhone__c) : con.MobilePhone != null ? con.MobilePhone : userRec.Phone;
            agent.realEmail = con.Email;

            con.Email = con.Email != null ? maskString(con.Email, 0, con.Email.length()-4, '*') : '' ;
            con.MobilePhone = agent.realMobile != null ? maskString(agent.realMobile, 0, agent.realMobile.length()-4, '*') : '';

            agent.contactRecord = con;

            agentsList.add(agent);
        }
        // Added by Tharun to show the contacts without user created
        if(contactsList.size() > 0 )
        {
            for(Contact con : contactsList.values())
            {
                if(!addedContacts.contains(con.Id) && (con.AgentStatus__c == 'Rejected' ||con.AgentStatus__c == Constants.PENDING_VERIFICATION))
                {
                    AgentInformation agent = new AgentInformation();
                    agent.userRecord = null;
                    
                    agent.realMobile = (con.MobileCountryCode__c != null && con.MobilePhone__c != null) ? (con.MobileCountryCode__c+con.MobilePhone__c) : con.MobilePhone != null ? con.MobilePhone : '';
                    agent.realEmail = con.Email;
                    
                    con.Email = con.Email != null ? maskString(con.Email, 0, con.Email.length()-4, '*') : '' ;
                    con.MobilePhone = agent.realMobile != null ? maskString(agent.realMobile, 0, agent.realMobile.length()-4, '*') : '';
                    agent.contactRecord = con;
                    agentsList.add(agent);
                }
            }
        }
        // Added by Tharun to show the contacts without user created
        return agentsList;
    }

    @AuraEnabled
    public static String maskString(String strText, integer start1, integer end1, String maskChar){
    
        if(strText == null || strText.equals(''))
            return '';
    
        if(start1 < 0)
            start1 = 0;
    
        if( end1 > strText.length() ) 
            end1 = strText.length();
    
            integer maskLength = end1 - start1;
    
        if(maskLength == 0)
            return strText;
    
        String sbMaskString='';
    
        for(integer i = 0; i < maskLength; i++){
            sbMaskString += maskChar;
        }   
    
        return strText.substring(0, start1) + sbMaskString + strText.substring(start1 + maskLength);
    }

    @AuraEnabled
    public static void  generatepassword(Id userId,string newPassword,string userEmail){
        
        try {
            User users=Utilities.getBrokerPortalUserDetails(userId);
            Id usrId= users.Id;
            String usrFullName=users.Contact.Name;
            System.setPassword(usrId,newPassword );
            if(userEmail != null){
                SetNewPassword.sendEmail(userEmail,usrFullName,newPassword);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void resetPassword(Id userId){
        
        try {
            System.resetPassword(userId, true);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateContactAgentStatus(String userId,String checkboxVal){

        System.debug('checkboxVal: '+checkboxVal);
        Contact con = new Contact(Id= userId);

        if(checkboxVal == 'Active'){
            con.AgentStatus__c='In Active'; 
        }else{
            con.AgentStatus__c='Active';
        }
        update con;
    }

    @AuraEnabled
    public static void updateUserAgentStatus(String userId,String checkboxVal){

        System.debug('checkboxVal: '+checkboxVal);
        User user = new User(Id= userId);

        if(checkboxVal == 'Active'){
            user.IsActive = false; 
        }else{
            user.IsActive = true;
        }
        update user;
    }

    // update by Moh Sarfaraj for BPE-10
    @AuraEnabled
    public static String uploadFile(String base64, String filename, String type, String recordId) {
        if(String.isNotBlank(base64) && String.isNotBlank(filename) && String.isNotBlank(type) && String.isNotBlank(recordId)){
            for(Document__c eachDoc : [SELECT Id FROM Document__c WHERE Contact__c =:recordId  AND DocumentType__c = :type]){
                ContentVersion cv = createContentVersion(base64, filename);
                ContentDocumentLink cd1 = createContentLink(cv.Id, eachDoc.Id);
            }
            return 'Success';
        }
        return '';
    }

    private static ContentVersion createContentVersion(String base64, String filename) {
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.Title = filename;
        cv.PathOnClient = filename;
        try {
            insert cv;
            return cv;
        } catch(DMLException e) {
            System.debug(e);
            return null;
        }
    }

    private static ContentDocumentLink createContentLink(String contentVersionId, String recordId) {
        if (contentVersionId == null || recordId == null) { return null; }
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: contentVersionId].ContentDocumentId;
        cdl.LinkedEntityId = recordId;
        // ShareType is either 'V', 'C', or 'I'
        // V = Viewer, C = Collaborator, I = Inferred
        cdl.ShareType = 'V';
        try {
            insert cdl;
            return cdl;
        } catch(DMLException e) {
            System.debug(e);
            return null;
        }
    }

    @AuraEnabled // Updated By Moh Sarfaraj for BPM-331
    public static List<Map<String, Object>> getUploadedFiles(String contactId, String role){
        try{
            List<Map<String, Object>> documentObjList1 = new List<Map<String, Object>>();
            if(String.isNotBlank(contactId)){
                // Added By Moh Sarfaraj for BPM-331 starts
                Map<Id,Document__c> mapDocuments;
                
                if(role == 'Partner/Owner' || role == 'Agency Admin'){
                    mapDocuments = new Map<Id,Document__c>([SELECT Id,DocumentType__c FROM Document__c WHERE Contact__c =:contactId AND DocumentType__c NOT IN ('RERA Broker Card', 'ADM Card')]);
                }else {
                    mapDocuments = new Map<Id,Document__c>([SELECT Id,DocumentType__c FROM Document__c WHERE Contact__c =:contactId]);
                }
                // Added By Moh Sarfaraj for BPM-331 end
                
                Map <String, String> contentDocMap = new Map<String, String>();

                if(!mapDocuments.isEmpty()){
                    for(ContentDocumentLink contentDocumentRecord : [SELECT ContentDocumentId, Id, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId =: mapDocuments.keySet()]){
                        contentDocMap.put(contentDocumentRecord.ContentDocumentId, contentDocumentRecord.LinkedEntityId);
                    }     
                }
                if(!contentDocMap.isEmpty()){
                    for(ContentVersion contentVersionRecord : [SELECT Id, ContentDocumentId, VersionData, Title FROM ContentVersion WHERE ContentDocumentId in : contentDocMap.keySet()]){

                        System.debug('data:base64,'+EncodingUtil.base64Encode(contentVersionRecord.VersionData));
    
                        Blob file = contentVersionRecord.VersionData;
                        Map<String, Object> map1 = new Map<String, Object>();
                        map1.put('fileName',contentVersionRecord.Title);
                        map1.put('base64',EncodingUtil.base64Encode(file));
                        map1.put('type', mapDocuments.get(contentDocMap.get(contentVersionRecord.ContentDocumentId)).DocumentType__c);
                        documentObjList1.add(map1);
                    }
                }  
            }
            return documentObjList1;
        } catch(exception e) {
            system.debug(e);
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static list<map<String,string>> getCountryCodeValues(){
        list<map<String,string>> picklistToReturn = new list<map<String,string>>();
        Schema.DescribeFieldResult fieldResult = Contact.MobileCountryCode__c.getDescribe();        
        for(Schema.PicklistEntry tempVal: fieldResult.getPicklistValues()){
            map<string,string> tempMap=new map<string,string>();
            tempMap.put('label',tempVal.getLabel());
            tempMap.put('value',tempVal.getValue());
            picklistToReturn.add(tempMap);
        }
        return picklistToReturn;
    }

    // Added by Moh Sarfaraj for BPE-10 updated BPM-331
    @AuraEnabled(cacheable=true)
    public static User getCurrentBrokerDetails(){
        return [SELECT Id,Account.BillingState, AccountId, ContactId, Contact.BrokerType__c FROM User WHERE Id =: UserInfo.getUserId() AND AccountId != null];
    }

    // Added by Moh Sarfaraj for BPM-331
    @AuraEnabled
    public static Boolean getExistingBrokerWithEmailOrMobile(String value, String type, String editedUserContact, String actionType){
        if(String.isNotBlank(value) && String.isNotBlank(type) && String.isNotBlank(actionType)){
            List<Contact> listBrokers = new List<Contact>();
            String BROKER_AGENT_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('BrokerAgent').getRecordTypeId();

            String query = 'SELECT Id FROM Contact WHERE RecordTypeId = : BROKER_AGENT_RECORD_TYPE_ID ';
            
            if(type == 'Email'){ 
                query += 'AND Email = : value '; 
            }else if(type == 'Mobile') {
                query += 'AND (MobilePhone__c = :value OR MobilePhone = :value) '; 
            }
            if(actionType == 'Edit Agent'){
                query += 'AND Id != :editedUserContact'; 
            }
            System.debug('query===>'+query);
            listBrokers = Database.query(query);
            return listBrokers.isEmpty() ? false : true;
        }
        return false;
    }
}