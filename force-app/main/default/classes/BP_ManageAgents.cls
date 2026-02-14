@RestResource(urlMapping='/getAllAgentsInfo') 
global without sharing class BP_ManageAgents extends BP_BaseRestResource {
    
    @HttpPost
    global static void execute() {
        RestContextHandler handler = new RestContextHandler(false);
        
        Map<String, String> params = RestContext.request.params;
        String requestBody = RestContext.request.requestBody.toString();   
        
        if (!String.isEmpty(requestBody)) {   
            BP_ManageAgents service = new BP_ManageAgents();
            ApiResponse response = service.processRequest(params, requestBody);	
            handler.response.data = response.data;
            handler.response.success = true;
            handler.response.statusCode = response.statusCode;
            handler.response.message = response.message;
        } else {
            handler.response.success = false;
            handler.response.statusCode = 500;
            handler.response.message = 'Invalid Request Body';
        }
        
        handler.finalize();
    }
    
    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        
        Map<String, Object> requestBodyData = parseRequestBody(requestBody);
        String agencyId = (String) requestBodyData.get('agencyId');
        Boolean accountDocuments = requestBodyData.containsKey('accountDocuments') ? (Boolean) requestBodyData.get('accountDocuments') : false;
        
        
        Integer limits = (Integer) requestBodyData.get('limit');
        Integer offsets = (Integer) requestBodyData.get('offset');
        String searchKey = (String) requestBodyData.get('searchKey');
        String contactId = (String) requestBodyData.get('contactId');
        String role = (String) requestBodyData.get('role');
        
        List<AgentInformation> agentInformationList = getContacts(agencyId, limits, offsets, searchKey, contactId, role,accountDocuments);
        Integer totalRecords = getTotalAgentCount(agencyId, searchKey, contactId, role);
        
        Map<String, Object> responseData = new Map<String, Object>();
        responseData.put('sfRecordCount', totalRecords);
        responseData.put('agents', agentInformationList);
        
        return new ApiResponse(true, 200, 
                               agentInformationList.isEmpty() ? 'No data found' : 'Agents info fetched successfully',
                               responseData);
        
    }
    
    public class AgentInformation { 
        @AuraEnabled public Contact contactRecord {get;set;}
        @AuraEnabled public User userRecord {get;set;}
        @AuraEnabled public String realMobile {get;set;}
        @AuraEnabled public String realEmail {get;set;}
        @AuraEnabled public String profilePhoto {get;set;}
        @AuraEnabled public String emiratesOrVisaCopy {get;set;}
        @AuraEnabled public String passportCopy {get;set;}
        @AuraEnabled public String memorandumOfAssociation {get;set;}
        @AuraEnabled public String tradeLicense {get;set;}
        @AuraEnabled public String admOrReraCertificate {get;set;}
        @AuraEnabled public DateTime tradeLicenseLastModifiedDate {get;set;}
    }
    
    
    public static List<AgentInformation> getContacts(String agencyId , Integer limits, Integer offsets, String searchKey, String contactId, String role,boolean accountDocuments){
        List<String> conditions = new List<String>();
        
        
        String contactQuery = 'SELECT Id, Salutation, Name, FirstName, LastName, Email, ' +
            'MailingCity, MailingCountry, MobilePhone, Account.Name, Account.AgencyCategory__c,Account.RegistrationExpiryDate__c, ' +
            'Account.BillingCity, AccountId, BrokerType__c, Birthdate, ' +
            'MobileCountryCode__c, MobilePhone__c, AgentStatus__c, ' +
            'AgentID__c, NationalIdNumber__c, NationalIdExpiryDate__c, ' +
            'PrimaryOwner__c, PrimaryAgencyAdmin__c, Account.BillingState, ' +
            'Account.BillingCountry, BlockedFromBackend__c,Account.ApprovalStatus__c, Nationality__c, ' +
            'PassportNumber__c, PassportExpiryDate__c, ' +
            'LastModifiedDate,Account.FIABCIRegistered__c, ' +
            'Account.Email__c, Account.MobileCountryCode__c, Account.MobileNumber1__c, Account.RegistrationNumber__c,Account.BillingPostalCode ' +
            'FROM Contact WHERE AccountId =: agencyId';
        
        
        if(role != null){
            contactQuery += ' AND BrokerType__c= :role ';
        }
        
        if (!String.isEmpty(contactId)) {
            contactQuery += ' AND Id = :contactId ';
        }
        
        if(searchKey != null){
            String key =  '%'+ searchKey +'%' ;
            contactQuery += ' AND ' + '(MobilePhone LIKE :key OR Name LIKE :key OR Email LIKE :key )';
        }
        contactQuery += ' ORDER BY LastModifiedDate DESC';
        
        if(limits != null){
            contactQuery += ' LIMIT :limits ';
        }
        if(offsets != null){
            contactQuery += ' OffSet :offsets ';
        }
        System.debug('contactQuery::'+contactQuery);
        
        
        Map<String, String> documentMap = new Map<String, String>(); 
        Map<String, DateTime> lastModifiedDateMap = new Map<String, DateTime>();
        
        if (!String.isEmpty(contactId)) {
            Set<String> documentNames = new Set<String>{'Emirates ID Copy', 'Passport Copy'};
                
                
                List<Document__c> docs = [
                    SELECT Id, Name, DocumentType__c, Contact__c 
                    FROM Document__c 
                    WHERE Contact__c = :contactId 
                    AND DocumentType__c IN :documentNames
                ];
            
            Set<Id> documentIds = new Set<Id>();
            for (Document__c doc : docs) {
                documentIds.add(doc.Id);
            }
            
            Map<Id, Id> docToContentDocMap = new Map<Id, Id>();
            if (!documentIds.isEmpty()) {
                for (ContentDocumentLink cdl : [
                    SELECT ContentDocumentId, LinkedEntityId 
                    FROM ContentDocumentLink 
                    WHERE LinkedEntityId IN :documentIds
                ]) {
                    docToContentDocMap.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
                }
            }
            
            Set<Id> contentDocIds = new Set<Id>(docToContentDocMap.values());
            
            Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion>();
            if (!contentDocIds.isEmpty()) {
                for (ContentVersion cv : [
                    SELECT ContentDocumentId, VersionData, Title, LastModifiedDate
                    FROM ContentVersion 
                    WHERE ContentDocumentId IN :contentDocIds 
                    AND IsLatest = true 
                    ORDER BY CreatedDate DESC 
                ]) {
                    contentVersionMap.put(cv.ContentDocumentId, cv);
                }
            }
            
            for (Document__c doc : docs) {
                Id contentDocId = docToContentDocMap.get(doc.Id);
                if (contentDocId != null && contentVersionMap.containsKey(contentDocId)) {
                    ContentVersion cv = contentVersionMap.get(contentDocId);
                    String base64Data = EncodingUtil.base64Encode(cv.VersionData);
                    documentMap.put(doc.DocumentType__c, base64Data);
                    lastModifiedDateMap.put(doc.DocumentType__c, cv.LastModifiedDate);
                }
            }
        }
        Map<String, String> documentMap1 = new Map<String, String>();
        Map<String, DateTime> lastModifiedDateMap1 = new Map<String, DateTime>();
        Map<Id, Id> docToContentDocMap = new Map<Id, Id>();

        if (accountDocuments) {
            
            List<HexaBPM__SR_Doc__c> tradeDoc = new List<HexaBPM__SR_Doc__c>();
            tradeDoc = [ SELECT Id, Name, HexaBPM__Customer__c FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Customer__c = :agencyId
                AND Name = 'Trade/Commercial License' LIMIT 1 ];
            
            System.debug('TradeDoc: ' + tradeDoc);
            
            if (!tradeDoc.isEmpty()) {
                ContentDocumentLink tradeCdl;
                ContentVersion tradeCv;
                
                List<ContentDocumentLink> cdlRecords = new List<ContentDocumentLink>();
                cdlRecords  = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :tradeDoc[0].Id
                    ORDER BY SystemModstamp DESC LIMIT 1];
                
                System.debug('Trade ContentDocumentLink: ' + cdlRecords );
                
                if (!cdlRecords .isEmpty()) {
                    tradeCdl = cdlRecords[0];
                    List<ContentVersion> cvRecords = new List<ContentVersion>();
                    cvRecords = [
                        SELECT Id, Title, FileExtension, ContentSize, LastModifiedDate, CreatedDate, VersionData, ContentDocumentId
                        FROM ContentVersion
                        WHERE ContentDocumentId = :tradeCdl.ContentDocumentId
                        AND IsLatest = true
                        ORDER BY LastModifiedDate DESC
                        LIMIT 1
                    ];
                    
                    if(!cvRecords.isEmpty()){
                        tradeCv = cvRecords[0];
                    }
                    // Store in maps
                    documentMap1.put(tradeDoc[0].Name, EncodingUtil.base64Encode(tradeCv.VersionData));
                    lastModifiedDateMap1.put(tradeDoc[0].Name, tradeCv.LastModifiedDate);
                    docToContentDocMap.put(tradeDoc[0].Id, tradeCdl.ContentDocumentId);
                    
                    System.debug('Trade License Document Processed: ' + tradeDoc[0].Name);
                } else {
                    System.debug('No ContentDocumentLink found for Trade License document: ' + tradeDoc[0].Id);
                }
            } else {
                System.debug('No Trade License SR_Doc found for customer.');
            }
        }
        List<Contact> contactList = Database.query(contactQuery);
        Map<Id, Contact> contactsList = new Map<Id,Contact>(contactList);
        
        List<User> usersList = [SELECT Id, ContactId, IsActive, RoleName__c, Phone, Username, FullPhotoUrl FROM User WHERE ContactId in : contactsList.keySet()];
        
        List<AgentInformation> agentsList = new List<AgentInformation>();
        Set<Id> addedContacts = new Set<Id>();
        for(User userRec : usersList){
            
            AgentInformation agent = new AgentInformation();
            agent.userRecord = userRec;
            Contact con = contactsList.get(userRec.ContactId);
            addedContacts.add(userRec.ContactId);
            
            agent.realMobile = (con.MobileCountryCode__c != null && con.MobilePhone__c != null) ? (con.MobileCountryCode__c+con.MobilePhone__c) : con.MobilePhone != null ? con.MobilePhone : userRec.Phone;
            agent.realEmail = con.Email;
            
            con.Email = con.Email != null ? BrokerAgentsController.maskString(con.Email, 0, con.Email.length()-4, '*') : '' ;
            con.MobilePhone = agent.realMobile != null ? BrokerAgentsController.maskString(agent.realMobile, 0, agent.realMobile.length()-4, '*') : '';
            
            agent.contactRecord = con;
            if (!String.isEmpty(contactId)) {
                agent.emiratesOrVisaCopy = documentMap.containsKey('Emirates ID Copy') ? documentMap.get('Emirates ID Copy') : null;
                agent.passportCopy = documentMap.containsKey('Passport Copy') ? documentMap.get('Passport Copy') : null;
                
            }
            if (accountDocuments) {
                
                agent.memorandumOfAssociation = documentMap1.containsKey('Memorandum of Association/Power of Attorney') ? documentMap1.get('Memorandum of Association/Power of Attorney') : null;
               if (documentMap1.containsKey('Trade/Commercial License')) {
        agent.tradeLicense = documentMap1.get('Trade/Commercial License');
        agent.tradeLicenseLastModifiedDate = lastModifiedDateMap1.get('Trade/Commercial License'); // set last modified
    }
                
                
                agent.admOrReraCertificate = documentMap1.containsKey('ADM / RERA Certificate') ? documentMap1.get('ADM / RERA Certificate') : null;
            }
            
            PageReference ref = new PageReference(userRec.FullPhotoUrl); 
        
            Blob b = !Test.isRunningTest() ? ref.getContent() : Blob.valueOf('test content'); 
            agent.profilePhoto = EncodingUtil.base64Encode(b); 
            agentsList.add(agent);
        }
        if(contactsList.size() > 0 ){
            for(Contact con : contactsList.values()){
                if(!addedContacts.contains(con.Id) && (con.AgentStatus__c == 'Rejected' || con.AgentStatus__c == Constants.PENDING_VERIFICATION)){
                    AgentInformation agent = new AgentInformation();
                    agent.userRecord = null;
                    
                    agent.realMobile = (con.MobileCountryCode__c != null && con.MobilePhone__c != null) ? (con.MobileCountryCode__c+con.MobilePhone__c) : con.MobilePhone != null ? con.MobilePhone : '';
                    agent.realEmail = con.Email;
                    
                    con.Email = con.Email != null ? BrokerAgentsController.maskString(con.Email, 0, con.Email.length()-4, '*') : '' ;
                    con.MobilePhone = agent.realMobile != null ? BrokerAgentsController.maskString(agent.realMobile, 0, agent.realMobile.length()-4, '*') : '';
                    agent.contactRecord = con;
                    agentsList.add(agent);
                }
            }
        }
        return agentsList;
    }
    public static Integer getTotalAgentCount(String agencyId, String searchKey, String contactId, String role) {
        String countQuery = 'SELECT COUNT() FROM Contact WHERE AccountId = :agencyId';
        if (role != null) countQuery += ' AND BrokerType__c = :role';
        
        if (searchKey != null) {
            String key = '%' + searchKey + '%';
            countQuery += ' AND (MobilePhone LIKE :key OR Name LIKE :key OR Email LIKE :key)';
        }
        return Database.countQuery(countQuery);
    }
    
}