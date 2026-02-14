/**********************************************************************************************************************
* Name                  : ManageRequestController                                                        
* Description           : 
* Created By            : 
* Last Modified By      : tdontha@aldar.com - Tharun (ASF-1536)
* Last Modified Date    : 15 Sep 2023   
******************************************************************************************************************/
public without sharing class ManageRequestController {
    
    @AuraEnabled
    public static Account getAgencyName(){
        try {
            User userDet    = Utilities.getLoggedInUserDetail();
            Id accountId    = userDet.Contact.AccountId;
            Account acc     = AccountService.fetchAccountById(accountId).isEmpty()?null:AccountService.fetchAccountById(accountId)[0] ;
            return acc;
        }
        catch (Exception e) {throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Map<String, String> getAgencyDetailsWithClassification(){
        try {
            Map<String, String> returnMap   = new Map<String, String>();
            User userDet                    = Utilities.getLoggedInUserDetail();
            Id accountId                    = userDet.Contact.AccountId;
            Date todaysDate                 = Date.today();
            Integer currentQuarter          = ( (todaysDate.month() -1) / 3) ;            
            
            Account accDetailsReturn    = [SELECT Id, Name, UAEVATRegisterNumber__c,BrokerPremiumClassification__c, AgencyRegion__c
                                           FROM Account WHERE Id =: accountId];
            returnMap.put('Id', accDetailsReturn.Id);
            returnMap.put('Name', accDetailsReturn.Name);
            returnMap.put('UAEVATRegisterNumber__c', accDetailsReturn.UAEVATRegisterNumber__c);
            returnMap.put('AgencyRegion__c', accDetailsReturn.AgencyRegion__c);
            
            if(currentQuarter == 0){
                Map<Id, String> getPrevClassificationByAccId            = new Map<Id, String>();
                List<String> premClassif                                = System.Label.BrokerClassifications.split(',');//new List<String>{'Standard','Envoy','Attache','Consul','Ambassador'};
                List<AccountHistory> accHisList                         = [SELECT Id, CreatedDate, OldValue, NewValue, AccountId, Account.Name FROM AccountHistory WHERE Field = 'BrokerClassification__c' AND CreatedDate = THIS_QUARTER  ORDER BY Account.Name ASC];
                for(AccountHistory accHisSingle: accHisList){
                    if(accHisSingle.OldValue <> null && accHisSingle.OldValue <> '' && String.valueOf(accHisSingle.OldValue).isAlpha() && premClassif.contains(String.valueOf(accHisSingle.OldValue))){
                        getPrevClassificationByAccId.put(accHisSingle.AccountId, String.valueOf(accHisSingle.OldValue));
                    }
                }
                if(getPrevClassificationByAccId.keySet().contains(accountId)){ returnMap.put('BrokerPremiumClassification__c', 'true');
                }else{returnMap.put('BrokerPremiumClassification__c', 'false');
                }
            }else{returnMap.put('BrokerPremiumClassification__c', String.valueof(accDetailsReturn.BrokerPremiumClassification__c));
            }
            return returnMap;
        } catch (Exception e) {throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Map<String, Decimal> monthlyLimit(String accountId, String recordTypeId){
        Map<String, Decimal> returnMap = new Map<String, Decimal>();
        try {
            Account acc = [SELECT Id, Name, BrokerClassification__c, BrokerClassification__r.MonthlyMarketingBudget__c FROM Account WHERE Id =: accountId LIMIT 1];
            System.debug('acc>>>' + acc);
            returnMap.put('monthlyLimit', acc.BrokerClassification__r.MonthlyMarketingBudget__c);
            Decimal consumeLimit = 0;
            for (BrokerRequest__c brokerRequest: [ SELECT Id, Name, RecordTypeId, RecordType.Name, InvoiceDate__c, TotalAmount__c FROM BrokerRequest__c WHERE RecordTypeId =: recordTypeId AND InvoiceDate__c = THIS_MONTH]) {
                consumeLimit = consumeLimit + brokerRequest.TotalAmount__c;
            }
            returnMap.put('consumeLimit', consumeLimit);
            System.debug('returnMap>>>' + returnMap);
            return returnMap;
        } catch (Exception e) {throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void  updateBrokerRecords(sObject updateReq) {
        System.debug('update brokerRec >>> ' + updateReq);
        System.debug('update brokerRec Comments >>> ' + updateReq.get('Comments__c'));
        update updateReq;
        System.debug('done');
    }
    
    @AuraEnabled
    public static list<Id> createMarketingRequest(list<Object> filesToInsert,sObject createMarketingReq){
       // try{
            System.debug('data>>>'+createMarketingReq);
            
            insert createMarketingReq;
            
            list<Id> lstCntVerIds = new list<Id>();
            List<ContentVersion> lstVersionsToInsert = new List<ContentVersion>();
            
            for (Object file : filesToInsert) {
                FileInfo fileData = (FileInfo)JSON.deserialize(JSON.serialize(file), FileInfo.class);
                ContentVersion objCntVersion = new ContentVersion();
                objCntVersion.PathOnClient = fileData.Title;
                objCntVersion.FirstPublishLocationId = createMarketingReq.Id;  
                objCntVersion.Title = fileData.Title;
                objCntVersion.VersionData = fileData.VersionData;
                lstVersionsToInsert.add(objCntVersion);
            }
            if (!lstVersionsToInsert.isEmpty()) {
                list<Database.saveResult> res = Database.insert(lstVersionsToInsert);
                for (Database.SaveResult saveResult : res) {
                    if(saveResult.isSuccess()) {
                        lstCntVerIds.add(saveResult.getId());
                    }
                }
            }
            
            return lstCntVerIds;
            
/*        } catch (Exception ex) {
            System.debug('Exception-createMarketingRequest'+ex);
            LoggerService.save(LoggerService.addApexLog(ex,'New BrokerRequest','ManageRequestController','createMarketingRequest'));
            throw new AuraHandledException(ex.getMessage());
        } */
    }
    
    @AuraEnabled
    public static void createEventRequest(sObject createEventReq){
        try{
            insert createEventReq;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<BrokerRequest__c> displayBrokerRequestRecord(string recordTypeName){
        try{
            System.debug('recordTypeName------>'+recordTypeName);
            List<BrokerRequest__c> requestRec= [ SELECT Id, Name, Type__c,RecordType.Name,StartDate__c, EndDate__c, 
                                                Location__c, InvoiceAmount__c, SodicInvoiceAmount__c, Comments__c, TaxAmount__c, InvoiceDate__c, 
                                                Invoice__c, TotalAmount__c,  ApprovalStatus__c, AgencyName__c 
                                                FROM BrokerRequest__c 
                                                WHERE RecordType.Name=:recordTypeName 
                                                ORDER BY CreatedDate Desc];
            System.debug('requestRecRTname'+requestRec);      
            return requestRec;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static list<Id> createFiles(list<Object> filesToInsert,String recordId){
        
        list<Id> lstCntVerIds = new list<Id>();
        List<ContentVersion> lstVersionsToInsert = new List<ContentVersion>();
        
        for (Object file : filesToInsert) {
            FileInfo fileData = (FileInfo)JSON.deserialize(JSON.serialize(file), FileInfo.class);
            ContentVersion objCntVersion = new ContentVersion();
            objCntVersion.PathOnClient = fileData.Title;
            objCntVersion.FirstPublishLocationId = recordId;  
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
    
    
    @AuraEnabled
    public static List<ContentVersion> getRelatedFilesByCaseId(String recordId) {       
        List<ContentDocumentLink> files =ContentDocumentLinkService.getAllContentDocumentLinkRecord(recordId);
        List<ID> fileIDs = new List<ID>();
        for (ContentDocumentLink docLink : files) {
            fileIDs.add(docLink.ContentDocumentId);
        }
        return contentVersionService.getFileIds(fileIDs);
        
    }
    
    @AuraEnabled
    public static string getURLPath(){
        Network network = [SELECT Name, UrlPathPrefix FROM Network WHERE Name =: Constants.URL_PREFIX];
        string urlPathPrefix= network.UrlPathPrefix ;
        return urlPathPrefix;
    }
    
    public class FileInfo {
        public String Title;
        public Blob VersionData;
    }
    
    //***************************************MangeREquestController--Wrapper****************************//
    @AuraEnabled
    public static List<brokerwrapper> brokerRequestRecords(String type) {
        try {
            List<brokerwrapper> wrapresponse = new List<brokerwrapper>();

            User userInfo=Utilities.getLoggedInUserDetail();
            System.debug('userInfo'+userInfo);
            Id accountId=userInfo.Contact.AccountId;
            System.debug('accountId'+accountId);
            //Id conAccountId = ContactService.getAccountId(contactId);
            
            List<BrokerRequest__c> brokerReqWithFiles = new List<BrokerRequest__c>();
            if (Test.isRunningTest()) {
                brokerReqWithFiles = [SELECT Id, AgencyName__c, Name, Type__c, StartDate__c, EndDate__c, Location__c,RequestYear__c,RequestQuarter__c, 
                                        InvoiceAmount__c, SodicInvoiceAmount__c, Comment__c, TaxAmount__c, InvoiceDate__c, Invoice__c, 
                                        TotalAmount__c, ApprovalStatus__c, Agency__c, (SELECT Id, LinkedEntityId, 
                                        ContentDocumentId, ContentDocument.Title, IsDeleted, ContentDocument.createdDate, 
                                        ContentDocument.FileType FROM ContentDocumentLinks) FROM BrokerRequest__c ORDER BY CreatedDate DESC];
            } else {
                brokerReqWithFiles = [SELECT Id, AgencyName__c, Name, Type__c, StartDate__c, EndDate__c, Location__c, 
                                        InvoiceAmount__c, SodicInvoiceAmount__c, Comment__c, TaxAmount__c, InvoiceDate__c, Invoice__c, 
                                        TotalAmount__c, InvoiceStatus__c, ApprovalStatus__c, Agency__c, RequestYear__c, RequestQuarter__c, 
                                        (SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.Title, IsDeleted, 
                                        ContentDocument.createdDate, ContentDocument.FileType FROM ContentDocumentLinks) 
                                        FROM BrokerRequest__c WHERE AgencyName__c =: accountId AND InvoiceStatus__c != 'Draft' AND 
                                        Type__c = :type /*AND CreatedById =: userInfo.Id*/ ORDER BY CreatedDate DESC];
            }
            System.debug('brokerReqWithFiles'+brokerReqWithFiles);           
            
            for(BrokerRequest__c br:brokerReqWithFiles) {
                brokerwrapper wrap= new brokerwrapper(); 
                if(br.ContentDocumentLinks.size()>0){
                    wrap.Attachment ='Yes';
                }else{
                    wrap.Attachment ='No';
                }
                wrap.Id =br.Id;
                wrap.Agency=br.Agency__c;
                wrap.BrokerRequestNumber=br.Name;
                wrap.StartDate=br.StartDate__c;
                wrap.EndDate=br.EndDate__c;
                wrap.InvoiceDate=br.InvoiceDate__c;
                wrap.Location=br.Location__c;
                wrap.Comments=br.Comment__c;
                wrap.Type=br.Type__c;
                wrap.ApprovalStatus=br.ApprovalStatus__c;
                wrap.Invoice=br.Invoice__c;
                wrap.InvoiceAmount=br.InvoiceAmount__c;
                wrap.SodicInvoiceAmount=br.SodicInvoiceAmount__c;
                wrap.TotalAmount=br.TotalAmount__c;
                wrap.TaxAmount=br.TaxAmount__c;
                wrap.invoiceStatus = br.InvoiceStatus__c;
                wrap.requestYear = br.RequestYear__c;
                wrap.requestedQuarter = br.RequestQuarter__c;
                wrapresponse.add(wrap);

                System.debug('wrapResponse'+wrapResponse); 
            }
            System.debug('finalwrapResponse size'+wrapResponse.size());
            return  wrapresponse; 
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        } 
    }
    
    private class brokerwrapper{
        @AuraEnabled
        public String Attachment {get;set;}
        @AuraEnabled
        public Id  Id {get;set;} 
        @AuraEnabled
        public String ApprovalStatus {get;set;} 
        @AuraEnabled
        public String invoiceStatus {get;set;} 
        @AuraEnabled
        public String Agency {get;set;} 
        @AuraEnabled
        public String Location {get;set;} 
        @AuraEnabled
        public Decimal InvoiceAmount {get;set;} 
        @AuraEnabled
        public Decimal SodicInvoiceAmount {get;set;}
        @AuraEnabled
        public Date InvoiceDate {get;set;}
        @AuraEnabled
        public Decimal TotalAmount {get;set;} 
        @AuraEnabled
        public Decimal TaxAmount {get;set;} 
        @AuraEnabled
        public String Comments {get;set;} 
        @AuraEnabled
        public String Type {get;set;} 
        @AuraEnabled
        public String BrokerRequestNumber {get;set;} 
        @AuraEnabled
        public Date StartDate {get;set;} 
        @AuraEnabled
        public Date EndDate {get;set;} 
        @AuraEnabled
        public String Invoice {get;set;} 

        @AuraEnabled
        public String requestYear {get;set;} 

        @AuraEnabled
        public String requestedQuarter {get;set;} 
    }
    
    
    //***************************************Maketing Reimbursement quarterly New Methods****************************//
    
    /* Method Name      : quarterlyLimit
     * Description      : check for quarterly limit configured under BrokerClassification
     * Created By       : tdontha@aldar.com
     */
    @AuraEnabled
    public static Map<String, Decimal> quarterlyLimit(String accountId, String recordTypeId, Date invoiceDate)
    {
        Map<String, Decimal> returnMap = new Map<String, Decimal>();
        return returnMap;
        /*
        // Added by Tharun - ASF-1536
        String AGENCYSTATUS_DOMESTIC            =   'Domestic';
        String AGENCYSTATUS_INTERNATIONAL       =   'International';
        // Added by Tharun - ASF-1536
        try 
        {
            // Added By Moh Sarfaraj for BPM-650
            String currentyear = String.valueOf(System.Today().year());
            
            Map<String, BrokerClassification__c> brokerClassificationMap    = new Map<String, BrokerClassification__c>();
            Map<Id, String> getPrevClassificationByAccId                    = new Map<Id, String>();
            String strBrokerClassification                                  = '';
            // ASF-1536 - Added Intl marketing budget values
            List<BrokerClassification__c> brokerClassificationList          = [SELECT Id, Name,
                                                                               Quarter1MarketingBudget__c,
                                                                               Quarter2MarketingBudget__c,
                                                                               Quarter3MarketingBudget__c,
                                                                               Quarter4MarketingBudget__c,
                                                                               SodicMarketingBudget__c,
                                                                               Quarter1MarketingBudgetIntl__c,
                                                                               Quarter2MarketingBudgetIntl__c,
                                                                               Quarter3MarketingBudgetIntl__c,
                                                                               Quarter4MarketingBudgetIntl__c,
                                                                               SodicMarketingBudgetInternational__c
                                                                               FROM BrokerClassification__c WHERE Year__c = :currentyear];
            if(!brokerClassificationList.isEmpty()){
                for(BrokerClassification__c brokeCls:brokerClassificationList){
                    // map of Consul => BrokerClassification__c
                    brokerClassificationMap.put(brokeCls.Name, brokeCls);
                }
            }
            
            // Below List is queried to remove premium accounts which were changed to classifications current quarter
            List<AccountHistory> accsHisList = [SELECT Id, Field, OldValue, NewValue,  AccountId, Account.Name 
                                                FROM AccountHistory 
                                                WHERE Field = 'BrokerClassification__c' 
                                                AND CreatedDate = THIS_QUARTER
                                                AND DAY_IN_MONTH(CreatedDate ) > 1 
                                                AND AccountId = :accountId
                                                ORDER BY CreatedDate DESC ];
            if(!accsHisList.isEmpty()){
                for(AccountHistory singleAccHisRecord : accsHisList){
                    if(singleAccHisRecord.OldValue <> NULL && singleAccHisRecord.OldValue <> ''  &&
                       String.valueOf(singleAccHisRecord.OldValue).isAlpha()){
                           getPrevClassificationByAccId.put(singleAccHisRecord.AccountId, String.valueOf(singleAccHisRecord.OldValue));
                       }
                }
            }
            
            Account acc = [SELECT Id, Name, Broker_Classification_Formula__c, AgencyRegion__c 
                           FROM Account WHERE Id =: accountId LIMIT 1];
            
            if(getPrevClassificationByAccId.keySet().Contains(accountId)){
                strBrokerClassification = getPrevClassificationByAccId.get(accountId);
            }else{
                strBrokerClassification = acc.Broker_Classification_Formula__c;
            }
            
            System.debug('acc>>>' + acc); 
            Integer quarter             = ( (invoiceDate.month() -1) / 3) + 1 ;
            String yearQuarter          = String.valueOf(invoiceDate.year() +'-'+quarter);
            String agencyRegion         = String.valueOf(acc.AgencyRegion__c);
            System.debug('quarter----agencyRegion---'+quarter+agencyRegion);
            
            if(quarter == 1){
                if(agencyRegion == AGENCYSTATUS_DOMESTIC){
                    returnMap.put('quarterlyLimit', brokerClassificationMap.get(strBrokerClassification).Quarter1MarketingBudget__c );
                }else if(agencyRegion == AGENCYSTATUS_INTERNATIONAL){
                    returnMap.put('quarterlyLimit', brokerClassificationMap.get(strBrokerClassification).Quarter1MarketingBudgetIntl__c );
                }
            }else if(quarter == 2){
                if(agencyRegion == AGENCYSTATUS_DOMESTIC){
                    returnMap.put('quarterlyLimit', brokerClassificationMap.get(strBrokerClassification).Quarter2MarketingBudget__c );
                }else if(agencyRegion == AGENCYSTATUS_INTERNATIONAL){
                    returnMap.put('quarterlyLimit', brokerClassificationMap.get(strBrokerClassification).Quarter2MarketingBudgetIntl__c );
                }
                //returnMap.put('quarterlyLimit', brokerClassificationMap.get(strBrokerClassification).Quarter2MarketingBudget__c);
            }else if (quarter == 3){
                if(agencyRegion == AGENCYSTATUS_DOMESTIC){
                    returnMap.put('quarterlyLimit', brokerClassificationMap.get(strBrokerClassification).Quarter3MarketingBudget__c );
                }else if(agencyRegion == AGENCYSTATUS_INTERNATIONAL){
                    returnMap.put('quarterlyLimit', brokerClassificationMap.get(strBrokerClassification).Quarter3MarketingBudgetIntl__c );
                }
                //returnMap.put('quarterlyLimit', brokerClassificationMap.get(strBrokerClassification).Quarter3MarketingBudget__c);
            }else{
                if(agencyRegion == AGENCYSTATUS_DOMESTIC){
                    returnMap.put('quarterlyLimit', brokerClassificationMap.get(strBrokerClassification).Quarter4MarketingBudget__c );
                }else if(agencyRegion == AGENCYSTATUS_INTERNATIONAL){
                    returnMap.put('quarterlyLimit', brokerClassificationMap.get(strBrokerClassification).Quarter4MarketingBudgetIntl__c );
                }
                //returnMap.put('quarterlyLimit', brokerClassificationMap.get(strBrokerClassification).Quarter4MarketingBudget__c);    
            }
            
            // Sodic Marketing Budget
            if(agencyRegion == AGENCYSTATUS_DOMESTIC){
                returnMap.put('sodicQuarterlyLimit', brokerClassificationMap.get(strBrokerClassification).SodicMarketingBudget__c);
            }else if(agencyRegion == AGENCYSTATUS_INTERNATIONAL){
                returnMap.put('sodicQuarterlyLimit', brokerClassificationMap.get(strBrokerClassification).SodicMarketingBudgetInternational__c);
            }
            
            Decimal consumeLimit = 0;
            for (BrokerRequest__c brokerRequest: [SELECT Id, Name, RecordTypeId, RecordType.Name, 
                                                  InvoiceDate__c, TotalAmount__c 
                                                  FROM BrokerRequest__c 
                                                  WHERE RecordTypeId =: recordTypeId 
                                                  AND AgencyName__c =: accountId
                                                  AND ApprovalStatus__c = 'Approved'
                                                  AND InvoiceDateQuarter__c =: yearQuarter]) 
            {
                consumeLimit = consumeLimit + brokerRequest.TotalAmount__c;
            }
            returnMap.put('consumeLimit', consumeLimit);
            System.debug('returnMap>>>' + returnMap);
            return returnMap;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }*/
    }
    
    /* Method Name      : getBufferDaysBrokerClassification
     * Description      : check for buffer days for invoice days specific to agency
     * Created By       : tdontha@aldar.com
     */
    @AuraEnabled
    public static Map<String, Decimal> getBufferDaysBrokerClassification(String accountId)
    {
        Map<String, Decimal> returnMap = new Map<String, Decimal>();
        try
        {
            Account acc = [SELECT Id, Name, BrokerClassification__c,
                           BrokerClassification__r.InvoiceBufferDays__c
                           FROM Account 
                           WHERE Id =: accountId LIMIT 1];
            if(acc != null){
                returnMap.put('bufferDays', acc.BrokerClassification__r.InvoiceBufferDays__c);
            }
            return returnMap;
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Boolean checkForExistingRequestForQuarter(String accountId, Date invoiceDate)
    {
        System.debug('Inside checkForExistingRequestForQuarter------');
        Boolean isExisting = false;
        Set<String> allBRsetValues = new Set<String>();
        List<BrokerRequest__c> allBrokerRequestsList = [SELECT
                                                       Id,AgencyName__c,
                                                       InvoiceDateQuarter__c,
                                                       ApprovalStatus__c
                                                       FROM BrokerRequest__c
                                                       WHERE InvoiceDateQuarter__c != null];
        if(allBrokerRequestsList.size() > 0){
            for(BrokerRequest__c brSingle : allBrokerRequestsList){
                allBRsetValues.add(brSingle.AgencyName__c+'_'+brSingle.InvoiceDateQuarter__c);
            }
            System.debug('allBRsetValues----'+allBRsetValues);
        }
        
        if(invoiceDate != null && accountId != null){
            String yearQuaterInvoiceDate = getYearWithQuarterForDate(invoiceDate);
            String checkDuplicate = accountId+'_'+yearQuaterInvoiceDate;
            System.debug('Marketingreimbursement-checkDuplicate--->'+checkDuplicate);
            if(allBRsetValues.contains(checkDuplicate)){
                System.debug('InsideIfCheck---@@@@');
                //throw new AuraHandledException('Reimbursement request already created for the same agency for the quarter');
                isExisting = true;
            }
        }
        return isExisting;
    }
    
    @AuraEnabled
    public static String getYearWithQuarterForDate(Date receivedInvDate)
    {
        Integer quarter = ( (receivedInvDate.month() -1) / 3) + 1 ;
        System.debug('quarterFromLine44----'+quarter);
        String yearQuarter = String.valueOf(receivedInvDate.year() +'-'+quarter);
        return yearQuarter;
    }
    
    //Below method is created here by Tharun as temporary
    @AuraEnabled
    public static String createHomeFinanceCase(sObject caseRecord)
    {
        Id homeFinanceRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Home_Finance').getRecordTypeId();
        Case caseRec = (Case)caseRecord;
        caseRec.RecordTypeId = homeFinanceRecTypeId;
        Insert caseRec;
        caseRec = [SELECT Id,CaseNumber from Case where id= :caseRec.Id];  
        return caseRec.CaseNumber;
    }
    
    //BPM-252 Added by Karunakar Pulkam
    //Marketing Reuimbersment budget calculation monthly wise.
    @AuraEnabled
    public static Map<String, Decimal> quarterlyLimitNew(String accountId, String recordTypeId, Date invoiceDate, Integer requestedQuarter, Integer requestedYear)
    {
        Map<String, Decimal> returnMap = new Map<String, Decimal>();
        String AGENCYSTATUS_DOMESTIC            =   'Domestic';
        String AGENCYSTATUS_INTERNATIONAL       =   'International';
        
        try{
            // Added By Moh Sarfaraj for BPM-650
            String currentyear = String.valueOf(System.Today().year());
            
            Map<String, BrokerClassification__c> brokerClassificationMap    = new Map<String, BrokerClassification__c>();
            Map<Id, String> getPrevClassificationByAccId                    = new Map<Id, String>();
            String strBrokerClassification                                  = '';
            
            List<BrokerClassification__c> brokerClassificationList          = [SELECT Id, Name,Quarter1MarketingBudget__c,Quarter2MarketingBudget__c,
                                                                               Quarter3MarketingBudget__c,Quarter4MarketingBudget__c,SodicMarketingBudget__c,
                                                                               Quarter1MarketingBudgetIntl__c,Quarter2MarketingBudgetIntl__c,Quarter3MarketingBudgetIntl__c,
                                                                               Quarter4MarketingBudgetIntl__c,SodicMarketingBudgetInternational__c
                                                                               FROM BrokerClassification__c WHERE Year__c = :currentyear];
            
            if(!brokerClassificationList.isEmpty()){
                for(BrokerClassification__c brokeCls:brokerClassificationList){
                    brokerClassificationMap.put(brokeCls.Name, brokeCls);
                }
            }
            
            Account acc = [SELECT Id, Name, Broker_Classification_Formula__c, AgencyRegion__c,
                           BrokerClassificationInJan__c,BrokerClassificationInFeb__c,BrokerClassificationInMar__c,
                           BrokerClassificationInApr__c,BrokerClassificationInMay__c,BrokerClassificationInJun__c,
                           BrokerClassificationInJul__c,BrokerClassificationInAug__c,BrokerClassificationInSep__c,
                           BrokerClassificationInOct__c,BrokerClassificationInNov__c,BrokerClassificationInDec__c
                           FROM Account WHERE Id =: accountId LIMIT 1]; 
            
            String quarterString ='';
            if(requestedQuarter == 1){
                quarterString = 'Q1';
            }else if(requestedQuarter == 2){
                quarterString = 'Q2';
            }else if(requestedQuarter == 3){
                quarterString = 'Q3';
            }else {
                quarterString = 'Q4';
            }
            
            Integer quarter             = requestedQuarter; //( (invoiceDate.month() -1) / 3) + 1 ;
            String reqYear              = String.valueOf(requestedYear);
            //String yearQuarter          = String.valueOf(invoiceDate.year() +'-'+quarter);
            String agencyRegion         = String.valueOf(acc.AgencyRegion__c);
            Decimal DomesticLimit = 0.00;
            Decimal IntlLimit = 0.00;
            
            if(quarter == 1){                
                if(acc.BrokerClassificationInJan__c != null){
                    DomesticLimit += brokerClassificationMap.get(acc.BrokerClassificationInJan__c).Quarter1MarketingBudget__c / 3;
                    IntlLimit += brokerClassificationMap.get(acc.BrokerClassificationInJan__c).Quarter1MarketingBudgetIntl__c / 3;
                }
                if(acc.BrokerClassificationInFeb__c != null){
                    DomesticLimit += brokerClassificationMap.get(acc.BrokerClassificationInFeb__c).Quarter1MarketingBudget__c / 3;
                    IntlLimit += brokerClassificationMap.get(acc.BrokerClassificationInFeb__c).Quarter1MarketingBudgetIntl__c / 3;
                }
                if(acc.BrokerClassificationInMar__c != null){
                    DomesticLimit += brokerClassificationMap.get(acc.BrokerClassificationInMar__c).Quarter1MarketingBudget__c / 3;
                    IntlLimit += brokerClassificationMap.get(acc.BrokerClassificationInMar__c).Quarter1MarketingBudgetIntl__c / 3;
                }
                
                //ELSE - Existing Logic should be execute
                
                if(agencyRegion == AGENCYSTATUS_DOMESTIC){
                    returnMap.put('quarterlyLimit', DomesticLimit );
                }else if(agencyRegion == AGENCYSTATUS_INTERNATIONAL){
                    returnMap.put('quarterlyLimit', IntlLimit );
                }
            }else if(quarter == 2){
                
                if(acc.BrokerClassificationInApr__c != null){
                    DomesticLimit += brokerClassificationMap.get(acc.BrokerClassificationInApr__c).Quarter2MarketingBudget__c / 3;
                    IntlLimit += brokerClassificationMap.get(acc.BrokerClassificationInApr__c).Quarter2MarketingBudgetIntl__c / 3;
                }
                if(acc.BrokerClassificationInMay__c != null){
                    DomesticLimit += brokerClassificationMap.get(acc.BrokerClassificationInMay__c).Quarter2MarketingBudget__c / 3;
                    IntlLimit += brokerClassificationMap.get(acc.BrokerClassificationInMay__c).Quarter2MarketingBudgetIntl__c / 3;
                }
                if(acc.BrokerClassificationInJun__c != null){
                    DomesticLimit += brokerClassificationMap.get(acc.BrokerClassificationInJun__c).Quarter2MarketingBudget__c / 3;
                    IntlLimit += brokerClassificationMap.get(acc.BrokerClassificationInJun__c).Quarter2MarketingBudgetIntl__c / 3;
                }
                
                if(agencyRegion == AGENCYSTATUS_DOMESTIC){
                    returnMap.put('quarterlyLimit', DomesticLimit );
                }else if(agencyRegion == AGENCYSTATUS_INTERNATIONAL){
                    returnMap.put('quarterlyLimit', IntlLimit );
                }
            }else if (quarter == 3){
                
                if(acc.BrokerClassificationInJul__c != null){
                    DomesticLimit += brokerClassificationMap.get(acc.BrokerClassificationInJul__c).Quarter3MarketingBudget__c / 3;
                    IntlLimit += brokerClassificationMap.get(acc.BrokerClassificationInJul__c).Quarter3MarketingBudgetIntl__c / 3;
                }
                if(acc.BrokerClassificationInAug__c != null){
                    DomesticLimit += brokerClassificationMap.get(acc.BrokerClassificationInAug__c).Quarter3MarketingBudget__c / 3;
                    IntlLimit += brokerClassificationMap.get(acc.BrokerClassificationInAug__c).Quarter3MarketingBudgetIntl__c / 3;
                }
                if(acc.BrokerClassificationInSep__c != null){
                    DomesticLimit += brokerClassificationMap.get(acc.BrokerClassificationInSep__c).Quarter3MarketingBudget__c / 3;
                    IntlLimit += brokerClassificationMap.get(acc.BrokerClassificationInSep__c).Quarter3MarketingBudgetIntl__c / 3;
                }
                
                if(agencyRegion == AGENCYSTATUS_DOMESTIC){
                    returnMap.put('quarterlyLimit', DomesticLimit );
                }else if(agencyRegion == AGENCYSTATUS_INTERNATIONAL){
                    returnMap.put('quarterlyLimit', IntlLimit );
                }
            }else{
                
                System.debug('Oct QB '+ brokerClassificationMap.get(acc.BrokerClassificationInOct__c).Quarter4MarketingBudget__c);
                if(acc.BrokerClassificationInOct__c != null){
                    DomesticLimit += brokerClassificationMap.get(acc.BrokerClassificationInOct__c).Quarter4MarketingBudget__c / 3;
                    IntlLimit += brokerClassificationMap.get(acc.BrokerClassificationInOct__c).Quarter4MarketingBudgetIntl__c / 3;
                }
                if(acc.BrokerClassificationInNov__c != null){
                    DomesticLimit += brokerClassificationMap.get(acc.BrokerClassificationInNov__c).Quarter4MarketingBudget__c / 3;
                    IntlLimit += brokerClassificationMap.get(acc.BrokerClassificationInNov__c).Quarter4MarketingBudgetIntl__c / 3;
                }
                if(acc.BrokerClassificationInDec__c != null){
                    DomesticLimit += brokerClassificationMap.get(acc.BrokerClassificationInDec__c).Quarter4MarketingBudget__c / 3;
                    IntlLimit += brokerClassificationMap.get(acc.BrokerClassificationInDec__c).Quarter4MarketingBudgetIntl__c / 3;
                }
                
                if(agencyRegion == AGENCYSTATUS_DOMESTIC){
                    returnMap.put('quarterlyLimit', DomesticLimit );
                }else if(agencyRegion == AGENCYSTATUS_INTERNATIONAL){
                    returnMap.put('quarterlyLimit', IntlLimit );
                }    
            }
            
            // Sodic Marketing Budget
            if(agencyRegion == AGENCYSTATUS_DOMESTIC){
                returnMap.put('sodicQuarterlyLimit', brokerClassificationMap.get(acc.Broker_Classification_Formula__c).SodicMarketingBudget__c);
            }else if(agencyRegion == AGENCYSTATUS_INTERNATIONAL){
                returnMap.put('sodicQuarterlyLimit', brokerClassificationMap.get(acc.Broker_Classification_Formula__c).SodicMarketingBudgetInternational__c);
            }
            
            Decimal consumeLimit = 0;
            for (BrokerRequest__c brokerRequest: [SELECT Id, Name, RecordTypeId, RecordType.Name, 
                                                  InvoiceDate__c, TotalAmount__c 
                                                  FROM BrokerRequest__c 
                                                  WHERE RecordTypeId =: recordTypeId 
                                                  AND AgencyName__c =: accountId
                                                  AND ApprovalStatus__c = 'Approved'
                                                  AND RequestQuarter__c =: quarterString 
                                                  AND RequestYear__c =: reqYear]) 
            {
                consumeLimit = consumeLimit + brokerRequest.TotalAmount__c;
            }
            returnMap.put('consumeLimit', consumeLimit);
            return returnMap;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    // Added By Moh Sarfaraj requested by Sanath 26-11-24
    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getQuarters(){
        Map<String,String> quarterMap = new Map<String,String>{'Q1'=>'1','Q2'=>'2','Q3'=>'3','Q4'=>'4'};
        List<Map<String,String>> listOfMapToReturn = new list<map<String,String>>();
    
        for(String qtr : System.Label.BPM_MarketingReimbursementQuarters.split(',')){
            Map<String, String> tempMap = new Map<String,String>();
            if(quarterMap.containsKey(qtr)){
                tempMap.put('label', qtr);
                tempMap.put('value', quarterMap.get(qtr));
                listOfMapToReturn.add(tempMap);
            }
        }
        return listOfMapToReturn;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getYears(){
        List<Map<String,String>> listOfMapToReturn = new list<map<String,String>>();

        for(String year : System.Label.BPM_MarketingReimbursementYears.split(',')){
            Map<String, String> tempMap = new Map<String,String>();
            tempMap.put('label', year);
            tempMap.put('value', year);
            listOfMapToReturn.add(tempMap);
        }
        return listOfMapToReturn;
    }

    // Added By Moh Sarfaraj requested by Sanath 26-11-24
    @AuraEnabled(cacheable=false)
    public static Boolean checkExistingRequests(String accountId, String quarter, String year){
        Boolean isExisting = false;

        if(String.isNotBlank(accountId) && String.isNotBlank(quarter)){
            List<BrokerRequest__c> allBrokerRequestsList = [SELECT Id,AgencyName__c, InvoiceDate__c
                                                        FROM BrokerRequest__c WHERE AgencyName__c = :accountId AND InvoiceDate__c != null AND
                                                        RequestQuarter__c = :quarter AND RequestYear__c =: year AND ApprovalStatus__c != 'Rejected'];
            if(allBrokerRequestsList.size() > 0){
                for(BrokerRequest__c brSingle : allBrokerRequestsList){
                    //if(System.today().year() == Integer.valueOf(year)){
                        isExisting = true;
                        break;
                    //}
                }
            }
        }
        return isExisting;
    }
    
    static Map<String,Set<Integer>> mapQuarterToMonths = new Map<String,Set<Integer>>{
        'Q1' => new Set<Integer>{ 1, 2, 3 },
        'Q2' => new Set<Integer>{ 4, 5, 6 },
        'Q3' => new Set<Integer>{ 7, 8, 9 },
        'Q4' => new Set<Integer>{ 10, 11, 12 }
    };

    @AuraEnabled(cacheable=true)
    public static Map<String,Decimal> calculateInvoiceAmount(String agencyId, String agencyRegion, String quarter, String year){
        try{
            Map<String,Decimal> mapToReturn = new Map<String,Decimal>();
            Decimal sumInvoiceAmount = 0;
            Set<Integer> setQuarterMonths = mapQuarterToMonths.get(quarter);

            for(Broker_Classification_Details__c bcd : [SELECT Id,Name,Classification__r.Quarter1MarketingBudget__c,Classification__r.Quarter2MarketingBudget__c,
                                                        Classification__r.Quarter3MarketingBudget__c, Classification__r.Quarter4MarketingBudget__c,
                                                        Classification__r.Quarter1MarketingBudgetIntl__c, Classification__r.Quarter2MarketingBudgetIntl__c,
                                                        Classification__r.Quarter3MarketingBudgetIntl__c, Classification__r.Quarter4MarketingBudgetIntl__c
                                                        FROM Broker_Classification_Details__c WHERE AgencyName__c = :agencyId AND 
                                                        Month__c IN :setQuarterMonths AND Year__c = :year AND 
                                                        Total_number_of_Sales_in_month__c > 0 AND Classification__r.Name != 'Standard']){
                                                            
                // at least one sales order in a month and 
                // classification is not standard
                System.debug('bcd--->'+bcd);
                // Domestic                                          
                if(agencyRegion == 'Domestic'){
                    if(quarter == 'Q1'){
                        sumInvoiceAmount = sumInvoiceAmount + bcd?.Classification__r?.Quarter1MarketingBudget__c / 3;
                    }else if(quarter == 'Q2'){
                        sumInvoiceAmount = sumInvoiceAmount + bcd?.Classification__r?.Quarter2MarketingBudget__c / 3;
                    }else if(quarter == 'Q3'){
                        sumInvoiceAmount = sumInvoiceAmount + bcd?.Classification__r?.Quarter3MarketingBudget__c / 3;
                    }else if(quarter == 'Q4'){
                        sumInvoiceAmount = sumInvoiceAmount + bcd?.Classification__r?.Quarter4MarketingBudget__c / 3;
                    }
                }else if(agencyRegion == 'International'){
                // International
                    if(quarter == 'Q1'){
                        sumInvoiceAmount = sumInvoiceAmount + bcd?.Classification__r?.Quarter1MarketingBudgetIntl__c / 3;
                    }else if(quarter == 'Q2'){
                        sumInvoiceAmount = sumInvoiceAmount + bcd?.Classification__r?.Quarter2MarketingBudgetIntl__c / 3;
                    }else if(quarter == 'Q3'){
                        sumInvoiceAmount = sumInvoiceAmount + bcd?.Classification__r?.Quarter3MarketingBudgetIntl__c / 3;
                    }else if(quarter == 'Q4'){
                        sumInvoiceAmount = sumInvoiceAmount + bcd?.Classification__r?.Quarter4MarketingBudgetIntl__c / 3;
                    }
                }
            }
            
            mapToReturn.put('success', sumInvoiceAmount.setScale(2));
            return mapToReturn;
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string updateStatus(String recordId, String statusValue, String comment){
        try {
            Boolean isLockedBefore = false;
            if(Approval.isLocked(recordId)){
                Approval.unlock(recordId);
                isLockedBefore = true;
            }
            
            BrokerRequest__c br = new BrokerRequest__c();
            br.Id = recordId;
            br.InvoiceStatus__c = statusValue;
            br.Comment__c = comment;
            update br;
            
            if(isLockedBefore){
                Approval.lock(recordId);
            }
            

            if(statusValue == 'Pending Invoice Verification'){
                // Map<Id,BrokerRequest__c> tempMap = new Map<Id, BrokerRequest__c>{ br.Id => br};
                generateInvoiceDocumentFromVF(new Map<Id, BrokerRequest__c>{ br.Id => br});
            }
            
            return br.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static void generateInvoiceDocumentFromVF(Map<id,BrokerRequest__c> brokerRequestProcess){
        if(Test.isRunningTest()){
            brokerRequestProcess = new Map<Id,BrokerRequest__c>([SELECT Id, Name  FROM BrokerRequest__c WHERE Id IN :brokerRequestProcess.keySet()]);  
        }else{
            brokerRequestProcess = new Map<Id,BrokerRequest__c>([SELECT Id, Name  FROM BrokerRequest__c WHERE Id IN :brokerRequestProcess.keySet()  WITH SECURITY_ENFORCED]); 
        }
        Map<Id,ContentVersion> contentVersionMap = new Map<Id,ContentVersion>();
        Map<Id, Id> invoiceBundleToDoc = new Map<Id, Id>();
        
        List<Document__c> placeholderList = [SELECT ID, BrokerRequest__c FROM Document__c 
                                             WHERE BrokerRequest__c IN :brokerRequestProcess.keySet() AND 
                                             DocumentType__c = 'Broker Marketing Reimbursement' ];
        if(placeholderList.isEmpty()){
            for(BrokerRequest__c brokerRequest : brokerRequestProcess.values()){
                placeholderList.add(new Document__c(DocumentType__c = 'Broker Marketing Reimbursement',
                                                    BrokerRequest__c = brokerRequest.Id,
                                                    AvailableForExternalUsers__c = true,
                                                    RecordtypeId = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('MarketingReimbursement').getRecordTypeId()));
            }
            insert placeholderList;
        }
        for(Document__c tempDoc : placeholderList){
            invoiceBundleToDoc.put(tempDoc.BrokerRequest__c,tempDoc.id); 
            PageReference pdf = Page.BrokerMarketingReimbursementPDF;

            String brokerRequestId = tempDoc.BrokerRequest__c; // EncryptionUtils.encryptString(tempDoc.BrokerRequest__c);
            pdf.getParameters().put('brokerRequestId', brokerRequestId);
            contentVersionMap.put(tempDoc.Id, new ContentVersion(Title= brokerRequestProcess.get(tempDoc.BrokerRequest__c).Name+'.pdf', 
                                                                    PathOnClient = brokerRequestProcess.get(tempDoc.BrokerRequest__c).Name+'.pdf',
                                                                    VersionData = Test.isRunningTest()? blob.valueOf('Methods defined as TestMethod do not support getContent call') : pdf.getContentAsPDF(), 
                                                                    origin = 'H'));
        }
            
        if(!contentVersionMap.isEmpty()){
            insert contentVersionMap.values();
            List<ContentDistribution> cdistribution = new List<ContentDistribution>();
            for(Id ccR : contentVersionMap.keySet()){
                cdistribution.add(ContentDocumentLinkTriggerHandler.createContentDistribution(contentVersionMap.get(ccR).Id,ccR));
            }
            insert cdistribution;
            
            Map<Id,Id> reverseMap = new Map<Id,Id>();
            for(Id docId : contentVersionMap.keySet()){
                reverseMap.put(contentVersionMap.get(docId).id,docId);
            }
            List<ContentDocumentLink> documentLinksToCreate = new List<ContentDocumentLink>();
            for(ContentVersion tempCV : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersionMap.values()]){
                documentLinksToCreate.add(new ContentDocumentLink(contentdocumentid = tempCV.ContentDocumentId,
                                                                    LinkedEntityId = reverseMap.get(tempCV.Id),
                                                                    ShareType ='V'));
            }
            if(!documentLinksToCreate.isEmpty()){
                insert documentLinksToCreate;
            }
        }
    }
}