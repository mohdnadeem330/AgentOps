public without sharing class ManageCasesController {
    //case raise request screen
    @AuraEnabled
    public static list<ContentVersion> returnFiles(list<String> lstFileIds){
        return [SELECT Id, Title FROM ContentVersion WHERE Id IN :lstFileIds];
    }
    
    @AuraEnabled
    public static Boolean hasSalesOrdersForCaseAccount(Id caseId) {
        //Fetch the Case with AccountId
        Case caseRecord = [SELECT AccountId FROM Case WHERE Id = :caseId LIMIT 1];
        Integer salesOrderCount;
        if (caseRecord.AccountId == null) {
            salesOrderCount = 0;
        }else{        
        // Check if there are any Sales Order records related to the Account
		    salesOrderCount = [
				SELECT COUNT()
				FROM SalesOrder__c
				WHERE Account__c = :caseRecord.AccountId
			];
        }
		System.debug('salesOrderCount -->'+ salesOrderCount);
        return salesOrderCount == 0;
    }
    
        
    @AuraEnabled
    public static List<Id> saveFiles(
        List<Object> filesToInsert,
        sObject caseRec,
        String comment,
        Id accountId,
        Id contactId
    ) {
        List<Id> lstCntVerIds = new List<Id>();
        List<ContentVersion> lstVersionsToInsert = new List<ContentVersion>();
        
        Case cs = (Case)caseRec;
        cs.RecordTypeId = Schema.getGlobalDescribe().get('Case')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('BrokerCase')
            .getRecordTypeId();
        
        User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        system.debug('logged in name::'+UserInfo.getUserName());
        system.debug('currentUser.ContactId ::'+currentUser.ContactId );
        if (currentUser.ContactId != null) {
            contactId = currentUser.ContactId;
            List<Contact> currentContactList = new List<Contact>();
            currentContactList = [SELECT AccountId FROM Contact WHERE Id = :contactId LIMIT 1];
            //system.debug('currentContact::'+currentContact );
            if(!currentContactList.isEmpty()){
                accountId = currentContactList[0].AccountId;
            }
        }
        
        
        cs.AccountId = accountId;
        cs.ContactId = contactId;
        cs.Origin='Broker Portal';
        
        if (comment != null) {
            cs.Status = Constants.CASE_IN_PROGRESS;
        }
         insert cs;
        
        // ✅ Add the inserted Case ID to the return list
        lstCntVerIds.add(cs.Id);
       
        if (comment != null) {
            CaseComment cmt = new CaseComment();
            cmt.ParentId = cs.Id;
            cmt.CommentBody = comment;
            insert cmt;
        }
        
        Network network = [SELECT Name, UrlPathPrefix, Id FROM Network WHERE Name = :Constants.URL_PREFIX];
        for (Object file : filesToInsert) {
            FileInfo fileData = (FileInfo)JSON.deserialize(JSON.serialize(file), FileInfo.class);
            ContentVersion objCntVersion = new ContentVersion();
            objCntVersion.PathOnClient = fileData.Title;
            objCntVersion.FirstPublishLocationId = cs.Id;
            objCntVersion.Title = fileData.Title;
            objCntVersion.VersionData = fileData.VersionData;
            objCntVersion.NetworkId = network.Id;
            lstVersionsToInsert.add(objCntVersion);
        }
        
        insert lstVersionsToInsert;
        
        return lstCntVerIds; // ✅ Now returning the inserted Case ID
    }
    
    public class FileInfo {
        public String Title;
        public Blob VersionData;
    }
    
    
    
    
    @AuraEnabled
    public static List<casewrapper> displayCaseRecords(Id userId,String whereCondition) {
        try {
            
            List<casewrapper> wrapresponse= new List<casewrapper>();
            Set<Id> caseIds = new Set<Id>();
            Set<Id>conAccountIds= new Set<Id>();
            Set<Id> childAccountsId = new Set<Id>();
            Map<Id,Case> caseWithFiles= new   Map<Id,Case>();
            List<Id> allCases= new List<Id>();
            
            
            User userInfo=Utilities.getLoggedInUserDetail();
            
            
            
            Id contactId=userInfo.ContactId;
            
            String loggedInUserProfile =  userInfo.ProfileName__c;
            
            
            Id conAccountId = ContactService.getAccountId(contactId);
            
            
            
            if(conAccountId != null && (loggedInUserProfile ==Constants.AGENCY_ADMIN_PROFILE || loggedInUserProfile ==Constants.AGENCY_ADMIN_PROFILE_LOGIN)){
                Account accountRec=AccountService.fetchAccountById(conAccountId).isEmpty()?null:AccountService.fetchAccountById(conAccountId)[0] ;
                
                Id parentAccountId =accountRec.ParentId;
                
                
                
                if(parentAccountId == null ){//means its a parent account
                    
                    
                    //getting  cases of associated contacts's account
                    Map<Id,Account> parentAccountWithCases=new   Map<Id,Account>([SELECT ID,Name,(SELECT Id,Subject from Cases ) from Account WHERE Id=:conAccountId + 'abc']);
                    
                    if(parentAccountWithCases.size()>0){
                        for(Account a:parentAccountWithCases.Values()){
                            
                            if(parentAccountWithCases.get(a.Id).Cases.size()>0){
                                for(Case parentCases:parentAccountWithCases.get(a.Id).Cases){
                                    
                                    string caseId= parentCases.Id;
                                    allCases.add(caseId);
                                    
                                } 
                            }
                        } 
                    }  
                    
                    caseWithFiles=new Map<Id,Case>( [SELECT Id,AccountId,CreatedDate,CaseNumber,Category__c,Status,Subject,(SELECT Id, LinkedEntityId, ContentDocumentId, IsDeleted,ContentDocument.Title,ContentDocument.createdDate, ContentDocument.FileType FROM ContentDocumentLinks   ) FRom Case WHERE ID IN:allCases OR AccountId =:conAccountId OR Account.ParentId=:conAccountId  ORDER BY CreatedDate Desc ]);
                    
                    
                }else{// ----------child account
                    
                    
                    caseWithFiles=new Map<Id,Case>( [SELECT Id,AccountId,CreatedDate,CaseNumber,Category__c,Status,Subject,(SELECT Id, LinkedEntityId, ContentDocumentId, IsDeleted,ContentDocument.Title,ContentDocument.createdDate, ContentDocument.FileType FROM ContentDocumentLinks   ) FRom Case WHERE AccountId =:conAccountId ORDER BY CreatedDate Desc ]);
                    
                    
                    
                }
            } else{
                system.debug('else');  
                
                // List<sObject> q  = Database.query('SELECT Id,AccountId,CreatedDate,CaseNumber,Category__c,Status,Subject,(SELECT Id, LinkedEntityId, ContentDocumentId, IsDeleted,ContentDocument.Title,ContentDocument.createdDate, ContentDocument.FileType FROM ContentDocumentLinks   ) FRom Case WHERE ContactId =:contactId '+ 'AND' + ' ' + whereCondition + 'ORDER BY CreatedDate Desc');
                // system.debug('query>>>>'+q);
                caseWithFiles= new Map<Id,Case>([SELECT Id,AccountId,CreatedDate,CaseNumber,Category__c,Status,Subject,(SELECT Id, LinkedEntityId, ContentDocumentId, IsDeleted,ContentDocument.Title,ContentDocument.createdDate, ContentDocument.FileType FROM ContentDocumentLinks   ) FRom Case WHERE ContactId =:contactId  ORDER BY CreatedDate Desc ]);
                
            }
            
            
            if(!caseWithFiles.isEmpty()){
                
                for(Case ca:caseWithFiles.Values()) {
                    casewrapper wrap= new casewrapper(); 
                    if(caseWithFiles.get(ca.Id).ContentDocumentLinks.size()>0){
                        
                        wrap.Id =ca.Id;
                        wrap.Attachment ='Yes';
                        
                        
                    }else{
                        wrap.Id =ca.Id;
                        wrap.Attachment ='No';
                        
                    }
                    wrap.Category=ca.Category__c;
                    wrap.ReferenceNumber=ca.CaseNumber;
                    wrap.RequestedDate=(ca.CreatedDate).date();
                    
                    wrap.Status=ca.Status;
                    wrap.Subject=ca.Subject;
                    
                    wrapresponse.add(wrap);
                    System.debug('wrapResponse'+wrapResponse); 
                }
                
                
            }   System.debug('finalwrapResponse size'+wrapResponse.size());
            return  wrapresponse; 
            
            
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        } 
        
        
    }  
    
    //case detail screen -used to display files with title to download
    @AuraEnabled
    public static List<ContentVersion> getRelatedFilesByCaseId(String caseId) {       
        List<ContentDocumentLink> files =ContentDocumentLinkService.getAllContentDocumentLinkRecord(caseId);
        List<ID> fileIDs = new List<ID>();
        for (ContentDocumentLink docLink : files) {
            fileIDs.add(docLink.ContentDocumentId);
        }
        return contentVersionService.getFileIds(fileIDs);
        
    }
    
    
    //case detail screen- used to create files
    @AuraEnabled
    public static list<Id> createFiles(list<Object> filesToInsert,String caseId){
        
        list<Id> lstCntVerIds = new list<Id>();
        List<ContentVersion> lstVersionsToInsert = new List<ContentVersion>();
        
        for (Object file : filesToInsert) {
            FileInfo fileData = (FileInfo)JSON.deserialize(JSON.serialize(file), FileInfo.class);
            ContentVersion objCntVersion = new ContentVersion();
            objCntVersion.PathOnClient = fileData.Title;
            objCntVersion.FirstPublishLocationId = caseId;  
            objCntVersion.Title = fileData.Title;
            objCntVersion.VersionData = fileData.VersionData;
            lstVersionsToInsert.add(objCntVersion);
        }
        
        list<Database.saveResult> res = Database.insert(lstVersionsToInsert);
        for (Database.SaveResult saveResult : res) {
            if(saveResult.isSuccess()) {
                lstCntVerIds.add(saveResult.getId());
            }
        }
        return lstCntVerIds;
    }
    
    
    private class casewrapper{
        @AuraEnabled
        public String Attachment {get;set;}
        @AuraEnabled
        public Id  Id {get;set;} 
        @AuraEnabled
        public String Status {get;set;} 
        @AuraEnabled
        public String Category {get;set;} 
        @AuraEnabled
        public String Subject {get;set;} 
        @AuraEnabled
        public String CreatedByName {get;set;} 
        @AuraEnabled
        public String ReferenceNumber {get;set;} 
        @AuraEnabled
        public Date RequestedDate {get;set;} 
        
        
    }   
    @AuraEnabled
    public static string getURLPath(){
        Network network = [SELECT Name, UrlPathPrefix FROM Network WHERE Name =: Constants.URL_PREFIX];
        string urlPathPrefix= network.UrlPathPrefix ;
        return urlPathPrefix;
    }
      /**
     * Case revamp : Added for Case Revamp 03/09/2024 - Harsh / Adarsh
     */
    @AuraEnabled 
    public static wrapdata getAccountid(String UnitId, String AccountId){
        wrapdata wrapdata = new wrapdata();
        
        if(UnitId!= null && AccountId == null)
        {
            List<SalesOrder__c> soList  = [select id,Unit__c,Account__c from SalesOrder__c where Unit__c = :UnitId and Status__c = 'Sold'];
            if(!soList.isEmpty())
            {        
                List<Account> acc = [select id, Name, IsPersonAccount from Account where id = :soList[0].Account__c];
                List<Contact> ConList = [Select id,Name from Contact where AccountId = :acc[0].id];
                
                wrapdata.AccountList = acc;
                wrapdata.AccountVal = acc[0].id; 
                if(!ConList.isEmpty())     
                {                                     
                    wrapdata.Contactlist = ConList;}
                if(acc[0].IsPersonAccount == true)
                {
                    wrapdata.AccounType = 'Person';
                }
                else{
                    wrapdata.AccounType = 'Org';
                }
                return wrapdata;                                   
            }
        }
        
        if(AccountId!= null && UnitId == null)
        {
            List<Id> unitList = new List<Id>();
            List<Account> acc = [select id, Name, IsPersonAccount from Account where id = :AccountId];
            List<Contact> conList = [select id,Name from Contact where AccountId = :AccountId];
            List<SalesOrder__c> soList  = [select id,Unit__c,Account__c from SalesOrder__c where Account__c = :AccountId];
            if (soList != null && !soList.isEmpty()) {
                for(SalesOrder__c so: soList)
                {
                    unitList.add(so.Unit__c);
                }
            }
            
            if(!unitList.isEmpty())
            {
                wrapdata.UnitList = [Select Id, Name from Unit__c where ID IN:unitList];
            }
                if(!conList.isEmpty())
                {
                    wrapdata.Contactlist = conList;
                }
                if(acc[0].IsPersonAccount == true)
                {
                    wrapdata.AccounType = 'Person';
                }
                else{
                    wrapdata.AccounType = 'Org';
                }
                return wrapdata;
            
        }
        
        return null;
    }
	
    /**
     * Case revamp : Added for Case Revamp 03/09/2024 - Harsh / Adarsh
     */
    public class wrapdata {
        @AuraEnabled
        public Id AccountVal;
        @AuraEnabled
        public String UnitVal;
        @AuraEnabled
        public List<Contact> Contactlist;
        @AuraEnabled
        public List<Unit__c> UnitList;
        @AuraEnabled
        public List<Account> AccountList;
        @AuraEnabled
        public string AccounType;
    }
    
}