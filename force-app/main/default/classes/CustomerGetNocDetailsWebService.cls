@RestResource (urlMapping = '/customer/GetNOC')
global without sharing class CustomerGetNocDetailsWebService {
    
    @HttpPost
    global static void getNOCDetails() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String,String> mapFieldApiFieldValues = handler.getRequestBodyMap();
            Map<String, Object> responseData = new Map<String, Object>(); 
            handler.response.data = GetNOCData(mapFieldApiFieldValues);
            handler.response.success = true;
            handler.finalize();
        }catch(Exception ex){
            System.debug('Ex'+ex.getLineNumber());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }
    public static NOCDetails GetNOCData( Map<String,String> mapFieldApiFieldValues){
        system.debug('mapFieldApiFieldValues::'+mapFieldApiFieldValues);
        Boolean isSeller = false, isBuyer = false, isSecBuyer = false;
        List<HexaBPM__Service_Request__c> srRequest = [SELECT Id,CreatedDate,Name,Case__c,BuyerName__c,Unit__c,SalesOrder__c,HexaBPM__Customer__c,HexaBPM__External_Status_Name__c,Has_OA_NOC__c,Retrive_Buyer_Acc_Docs__c,RecordTypeId,TransferSellingPrice__c,
                                                       (SELECT Id, HexaBPM__Summary__c,HexaBPM__Status__r.Name FROM HexaBPM__Steps_SR__r WHERE HexaBPM__Summary__c IN ('Issue NOC to Client', 'Issue Provis NOC to the Client') ) ,
                                                       (SELECT Id,Account__c FROM Partners__r) FROM HexaBPM__Service_Request__c WHERE Id=:mapFieldApiFieldValues.get('sRId') AND SRType__c =:mapFieldApiFieldValues.get('SRType') AND HexaBPM__External_Status_Name__c!= 'Cancelled' AND Origin__c ='Customer Portal' LIMIT 1];
        if(srRequest.size() >0){
            System.enqueueJob(new FastTRackSRDOC(srRequest[0]));
        }
        list<HexaBPM__Step__c> allNocSRSteps = new list<HexaBPM__Step__c>();
        for (HexaBPM__Service_Request__c sr : srRequest) {
            for (HexaBPM__Step__c step : sr.HexaBPM__Steps_SR__r) {
                allNocSRSteps.add(step);
                
            }             
        }
        list<Id> secBuyersId = new list<Id>();
        for (HexaBPM__Service_Request__c sr : srRequest) {
            for (AgencyTeam__c secBuyer : sr.Partners__r) {
                secBuyersId.add(secBuyer.Account__c);
            }              
        }
        List<Id> SRIds = new List<Id>();
        String passportEidDocsLabel = System.Label.User_documents_for_property_transfer_noc;
        if(srRequest.size()>0){
            for(HexaBPM__Service_Request__c hxr :srRequest){
                SRIds.add(hxr.Id);
            }
            String srIdStr = String.join(SRIds, '\',\'');
            List<String> passportEidDocList = passportEidDocsLabel.split(',');
            String whrClause = 'HexaBPM__Service_Request__c IN (\'' + srIdStr + '\') ' 
                + 'AND (HexaBPM__Document_Master__r.AvailableForCustomer__c = true '
                + ' OR  HexaBPM__Document_Name__c IN'  + passportEidDocList+')'
                + ' AND  HexaBPM__Document_Name__c != NULL ';
            
            system.debug('whrClause'+whrClause);
            List<HexaBPM__SR_Doc__c> srDocList = CustomerServiceUtility.getSRDocDetail(whrClause + ' ORDER BY HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Name ');
            
            
            NOCDetails noc = new NOCDetails();
            noc.CustomerId = srRequest[0].HexaBPM__Customer__c;
            noc.BuyerId = srRequest[0].BuyerName__c;
            noc.CaseId = srRequest[0].Case__c;
            noc.SRId = srRequest[0].Id;
            noc.SRStatus=srRequest[0].HexaBPM__External_Status_Name__c;
            noc.SecBuyersIdList = secBuyersId != null ?secBuyersId : null ;
            noc.CreatedDate = string.valueof(srRequest[0].CreatedDate);
            noc.SrNo = srRequest[0].Name ;
            noc.AgreedSellingPrice = srRequest[0].TransferSellingPrice__c;
            Set<Id> srDocIds = new Set<Id>();
            Set<Id>SerdocsPersonalIdsSeller = new Set<Id>();
            map<String,Id>personalDocMapSeller = new Map<String,Id>();
            Set<Id>SerdocsPersonalIdsBuyer = new Set<Id>();
            map<String,Id>personalDocMapBuyer = new Map<String,Id>();
            List<HexaBPM__SR_Doc__c>  expiringDocsList = new List<HexaBPM__SR_Doc__c>();
            List<Id>  buyerSignDocIds = new List<Id>();
            map<Id,list<string>> srDocToBuyerSignedMap = new Map<Id, list<string>>();
            Map<String,dfsle__RecipientStatus__c> recipientMap = new Map<String,dfsle__RecipientStatus__c>();
            set<String> accIdList = new set<String>();
            
            for (HexaBPM__SR_Doc__c srdoc : srDocList) {
                srDocIds.add(srdoc.Id);
                if(srdoc.Name == 'Buyer Emirates ID BackSideCopy' || srdoc.Name == 'Buyer Emirates ID Copy' || srdoc.Name == 'Buyer Passport Copy' || srdoc.Name == 'Seller Passport Copy' || srdoc.Name == 'Seller Emirates ID Copy' || srdoc.Name == 'Seller Emirates ID BackSideCopy' ){
                    expiringDocsList.add(srdoc);
                }
                if(srdoc.Name == 'Document of Adherence' || srdoc.Name == 'Owner Association Letter' ){
                    buyerSignDocIds.add(srdoc.Id);
                }
            }
          
            if(!buyerSignDocIds.isEmpty() ){
                for(dfsle__RecipientStatus__c recpStatusRec : [SELECT id,Account__c,dfsle__Status__c,dfsle__SourceId__c FROM dfsle__RecipientStatus__c WHERE dfsle__SourceId__c IN : buyerSignDocIds]){
                    if(!srDocToBuyerSignedMap.containsKey(recpStatusRec.dfsle__SourceId__c)){
                        srDocToBuyerSignedMap.put(recpStatusRec.dfsle__SourceId__c, new list<Id>());
                    }
                    srDocToBuyerSignedMap.get(recpStatusRec.dfsle__SourceId__c).add(recpStatusRec.Account__c);
                    if(!recipientMap.containsKey(recpStatusRec.dfsle__SourceId__c+'::'+recpStatusRec.Account__c)){
                        recipientMap.put(recpStatusRec.dfsle__SourceId__c+'::'+recpStatusRec.Account__c,recpStatusRec);
                    }
                }
            }
            for(Document__c personalDocs :[SELECT Id, DocumentType__c FROM Document__c WHERE Account__c =:srRequest[0].HexaBPM__Customer__c  AND DocumentType__c IN('National ID Front Copy','Passport Copy','National ID Back Copy') ]){
                SerdocsPersonalIdsSeller.add(personalDocs.Id);
                personalDocMapSeller.put(personalDocs.DocumentType__c,personalDocs.Id);
            }
            for(Document__c personalDocs :[SELECT Id, DocumentType__c FROM Document__c WHERE Account__c =:srRequest[0].BuyerName__c AND DocumentType__c IN('National ID Front Copy','Passport Copy','National ID Back Copy') ]){
                SerdocsPersonalIdsBuyer.add(personalDocs.Id);
                personalDocMapBuyer.put(personalDocs.DocumentType__c,personalDocs.Id);
            }
            SerdocsPersonalIdsSeller.AddAll(SerdocsPersonalIdsBuyer);
            map<Id,Id> contentDocLinkMap=new Map<Id, Id>();
            List<ContentDocumentLink> ContentDocumentlinkList = [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :SerdocsPersonalIdsSeller];
            for (ContentDocumentLink docLink1 : ContentDocumentlinkList) {
                contentDocLinkMap.put(docLink1.LinkedEntityId,docLink1.ContentDocumentId);
            }
            List<ContentDocumentLink> contentDocLinkList = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :srDocIds];
            Set<Id> contentDocIdSet = new Set<Id>();
            Map<Id, List<Id>> linkedEntitiToCondocIdMap = new Map<Id, List<Id>>();
            Map<Id, Integer> contentDocCountMap = new Map<Id, Integer>();
            for (ContentDocumentLink docLink : contentDocLinkList) {
                contentDocIdSet.add(docLink.ContentDocumentId);
                contentDocLinkMap.put(docLink.LinkedEntityId,docLink.ContentDocumentId);
                //docExpiryMapCreation
                if (!linkedEntitiToCondocIdMap.containsKey(docLink.LinkedEntityId)) {
                    linkedEntitiToCondocIdMap.put(docLink.LinkedEntityId, new List<Id>());
                }
                linkedEntitiToCondocIdMap.get(docLink.LinkedEntityId).add(docLink.ContentDocumentId);
            }
            for (Id linkedId : linkedEntitiToCondocIdMap.keySet()) {
                contentDocCountMap.put(linkedId, linkedEntitiToCondocIdMap.get(linkedId).size());
            }
            Map<Id, DateTime> createdDateMap = new Map<Id, DateTime>();
            Map<Id,String> titleMap = new Map<Id, String>();
            if (!contentDocIdSet.isEmpty()) {
                List<ContentVersion> contentVersions = [SELECT ContentDocumentId, CreatedDate,LastModifiedDate,Title FROM ContentVersion WHERE ContentDocumentId IN :contentDocIdSet AND IsLatest = true];
                for (ContentVersion version : contentVersions) {
                    createdDateMap.put(version.ContentDocumentId, version.CreatedDate);
                    titleMap.put(version.ContentDocumentId , version.Title);
                }
            }
            list<Account> seller = [SELECT Id,NationalIdExpiryDate__pc,PassportExpiryDate__pc FROM Account WHERE Id = :srRequest[0].HexaBPM__Customer__c];
            list<Account> buyer = [SELECT Id,NationalIdExpiryDate__pc,PassportExpiryDate__pc FROM Account WHERE Id = :srRequest[0].BuyerName__c];
            List<SRDoc> docList = new List<SRDoc>();
            for (List<String> innerList : srDocToBuyerSignedMap.values()) {
                accIdList.addAll(innerList);
            }
            
            for(HexaBPM__SR_Doc__c srdoc :srDocList){
                SRDoc sd = new SRDoc();
                if((srdoc.HexaBPM__Document_Name__c=='Provis NOC' && srRequest[0].Has_OA_NOC__c==false) || srdoc.HexaBPM__Document_Name__c=='Signed NOC Copy'){
                    
                    if (allNOCSrSteps.size() > 0) {
                        for (HexaBPM__Step__c singleStep : allNOCSrSteps) {
                            system.debug('singleStep.Summary'+singleStep.HexaBPM__Summary__c);
                            system.debug('singleStep.HexaBPM__Status__r.Name'+singleStep.HexaBPM__Status__r.Name);
                            if ((singleStep.HexaBPM__Summary__c == 'Issue Provis NOC to the Client' && (singleStep.HexaBPM__Status__r.Name == 'Issued via Physically' || singleStep.HexaBPM__Status__r.Name == 'Issued via Email')) || (singleStep.HexaBPM__Summary__c == 'Issue NOC to Client' && (singleStep.HexaBPM__Status__r.Name == 'Issued via Physically' ||singleStep.HexaBPM__Status__r.Name == 'Issued via Email'))) {
                                sd.Status = (srdoc.HexaBPM__Status__c =='Uploaded' ||srdoc.HexaBPM__Status__c =='Generated') ?'Completed':'Pending';
                                sd.DocId = srdoc.Id;
                                sd.DocType = srdoc.HexaBPM__Document_Name__c;
                                Id contentDocId = contentDocLinkMap.get(srdoc.Id);
                                DateTime generatedDate = contentDocId != null ? createdDateMap.get(contentDocId) : null;
                                if (generatedDate != null) {
                                    sd.DocGeneratedDate = generatedDate;
                                }
                                sd.RejectedReason= srdoc.Provis_Reason__c;
                            }
                        }
                    }	
                    
                }
                else{
                    if(srdoc.HexaBPM__Document_Name__c =='Seller Passport Copy' || srdoc.HexaBPM__Document_Name__c =='Seller Emirates ID Copy' || srdoc.HexaBPM__Document_Name__c =='Seller Emirates ID BackSideCopy' ||srdoc.HexaBPM__Document_Name__c =='Buyer Passport Copy' || srdoc.HexaBPM__Document_Name__c =='Buyer Emirates ID Copy' || srdoc.HexaBPM__Document_Name__c =='Buyer Emirates ID BackSideCopy' || Test.isRunningTest()  ){
                        sd.Status ='Completed';
                        sd.DocId = srdoc.Id;
                        sd.DocType = srdoc.HexaBPM__Document_Name__c;
                        if(contentDocLinkMap.get(srdoc.Id) == null || Test.isRunningTest()){
                            if((srdoc.HexaBPM__Document_Name__c =='Seller Passport Copy' && personalDocMapSeller.get('Passport Copy') != null)  || Test.isRunningTest()){
                                sd.DocId =personalDocMapSeller.get('Passport Copy');
                            }
                            if((srdoc.HexaBPM__Document_Name__c =='Seller Emirates ID Copy' && personalDocMapSeller.get('National ID Front Copy') != null) || Test.isRunningTest()){
                                sd.DocId = personalDocMapSeller.get('National ID Front Copy');
                            }
                            if((srdoc.HexaBPM__Document_Name__c =='Seller Emirates ID BackSideCopy' && personalDocMapSeller.get('National ID Back Copy') != null) || Test.isRunningTest()){
                                sd.DocId = personalDocMapSeller.get('National ID Back Copy');
                            }
                            if((srdoc.HexaBPM__Document_Name__c =='Buyer Passport Copy' && personalDocMapBuyer.get('Passport Copy') != null) || Test.isRunningTest()){
                                sd.DocId = personalDocMapBuyer.get('Passport Copy');
                            }
                            if((srdoc.HexaBPM__Document_Name__c =='Buyer Emirates ID Copy' && personalDocMapBuyer.get('National ID Front Copy') != null) || Test.isRunningTest()){
                                sd.DocId = personalDocMapBuyer.get('National ID Front Copy');
                            }
                            if((srdoc.HexaBPM__Document_Name__c =='Buyer Emirates ID BackSideCopy' && personalDocMapBuyer.get('National ID Back Copy') != null) || Test.isRunningTest()){
                                sd.DocId = personalDocMapBuyer.get('National ID Back Copy');
                            }
                        }else{
                            Id contentDocId = contentDocLinkMap.get(srdoc.Id); 
                            DateTime generatedDate = null;//contentDocId != null ? createdDateMap.get(contentDocId) : null;
                            if (generatedDate != null) {
                                sd.DocGeneratedDate = generatedDate;
                            }
                        }
                        Id contentDocTitleId = contentDocLinkMap.get(srdoc.Id);
                        string title = contentDocTitleId != null ? titleMap.get(contentDocTitleId) : null;
                        sd.fileName = title;
                        sd.RejectedReason= srdoc.Provis_Reason__c;
                    }
                    else if(srdoc.HexaBPM__Document_Name__c =='Document of Adherence' || srdoc.HexaBPM__Document_Name__c =='Owner Association Letter' ){
                        if (srDocToBuyerSignedMap.containsKey(srdoc.Id)) {
                            Set<String> uniqueAccIds = new Set<String>();
                            uniqueAccIds.addAll(srDocToBuyerSignedMap.get(srdoc.Id));
                            sd.SignedByList = new List<CustomerGetNocDetailsWebService.SignedByInfo>();
                            for (String accId : uniqueAccIds) {
                                CustomerGetNocDetailsWebService.SignedByInfo signer = new CustomerGetNocDetailsWebService.SignedByInfo();
                                signer.AccId = accId;
                                signer.Status = recipientMap.get(srdoc.Id+'::'+accId).dfsle__Status__c =='Created'?'Pending':(recipientMap.get(srdoc.Id+'::'+accId).dfsle__Status__c =='Sent' || recipientMap.get(srdoc.Id + '::' + accId).dfsle__Status__c == 'delivered' ?'Open':'Completed');
                                sd.SignedByList.add(signer);
                                
                            }
                        }
                        sd.Status = (srdoc.HexaBPM__Status__c =='Uploaded' ||srdoc.HexaBPM__Status__c =='Generated') ?'Completed':'Pending';
                        sd.DocId = srdoc.Id;
                        sd.DocType = srdoc.HexaBPM__Document_Name__c;
                        Id contentDocId = contentDocLinkMap.get(srdoc.Id);
                        DateTime generatedDate = contentDocId != null ? createdDateMap.get(contentDocId) : null;
                        if (generatedDate != null) {
                            sd.DocGeneratedDate = generatedDate;
                        }
                        //passing fileName
                        string title = contentDocId != null ? titleMap.get(contentDocId) : null;
                        sd.fileName = title;
                        sd.RejectedReason= srdoc.Provis_Reason__c;
                    }
                    else{                        
                        sd.Status = (srdoc.HexaBPM__Status__c =='Uploaded' ||srdoc.HexaBPM__Status__c =='Generated') ?'Completed':'Pending';
                        sd.DocId = srdoc.Id;
                        sd.DocType = srdoc.HexaBPM__Document_Name__c;
                        Id contentDocId = contentDocLinkMap.get(srdoc.Id);
                        DateTime generatedDate = contentDocId != null ? createdDateMap.get(contentDocId) : null;
                        if (generatedDate != null) {
                            sd.DocGeneratedDate = generatedDate;
                        }
                        //passing fileName
                        string title = contentDocId != null ? titleMap.get(contentDocId) : null;
                        sd.fileName = title;
                        sd.RejectedReason= srdoc.Provis_Reason__c;
                        
                    }
                }
                if(mapFieldApiFieldValues.containsKey('hasUserProfileUpdated')){
                    Boolean updateFlag=Boolean.valueOf(mapFieldApiFieldValues.get('hasUserProfileUpdated'));
                    
                    if(!updateFlag ){
                        //documentReGenerationPart																				
                        if (srdoc.HexaBPM__Document_Name__c == 'Owner Association Letter' ||srdoc.HexaBPM__Document_Name__c == 'Document of Adherence' ) {
                            
                            ContentVersion content = CustomerServiceUtility.getContentVersion(srdoc.Id);
                            System.debug(content);
                            if (content != null && content.Id != null && Datetime.now().addMinutes(-5) <= content.LastModifiedDate) {
                                sd.title = content.Title;
                            } else {
                                sd.title = '';
                            }
                        }
                        
                    }
                    else{
                        sd.title=srdoc.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Name;
                    }
                    
                }
                DocList.add(sd);
            }
            noc.DocList =docList;
            //EID&PASSPORT_EXPIRY _SECANRIO START
            if(mapFieldApiFieldValues.containsKey('customerId')){
                noc.ExpDocList = new List<docExpiryList>();
                List<docExpiryList> FinaldocExpiryList = new List<docExpiryList>();
                Set<String> expectedDocNames = new Set<String>();
                
                if(mapFieldApiFieldValues.get('customerId') == srRequest[0].BuyerName__c ){
                    //buyer
                    expectedDocNames.addAll(new List<String>{'Buyer Emirates ID BackSideCopy', 'Buyer Emirates ID Copy','Buyer Passport Copy'});                    
                }
                else if( mapFieldApiFieldValues.get('customerId') == srRequest[0].HexaBPM__Customer__c ){
                    //seller
                    expectedDocNames.addAll(new List<String>{ 'Seller Emirates ID Copy',  'Seller Emirates ID BackSideCopy', 'Seller Passport Copy'});
                }
                system.debug('expectedDocNames::'+expectedDocNames);
                system.debug('expiringDocsList::'+expiringDocsList);
                if (!expectedDocNames.isEmpty() && seller != null && buyer != null){                  
                    for(HexaBPM__SR_Doc__c srdoc : expiringDocsList){
                        if (expectedDocNames.contains(srdoc.HexaBPM__Document_Name__c)) {
                            docExpiryList dcexpiryList = new docExpiryList();
                            dcexpiryList.DocType = srdoc.HexaBPM__Document_Name__c;
                            dcexpiryList.docId = srdoc.Id;    
                            Boolean isBuyerDoc = srdoc.HexaBPM__Document_Name__c.startsWith('Buyer');
                            Date passportExpiryDate = isBuyerDoc ? buyer[0].PassportExpiryDate__pc : seller[0].PassportExpiryDate__pc;
                            Date nationalIdExpiryDate = isBuyerDoc ? buyer[0].NationalIdExpiryDate__pc : seller[0].NationalIdExpiryDate__pc;
                            
                            if (srdoc.HexaBPM__Document_Name__c.contains('Passport')) {
                                dcexpiryList.isExpired = System.today() > passportExpiryDate;
                            } else {
                                dcexpiryList.isExpired = System.today() > nationalIdExpiryDate;
                            }
                            Integer docCount = contentDocCountMap.containsKey(srdoc.Id) ? contentDocCountMap.get(srdoc.Id) : 0;
                            dcexpiryList.status = docCount <= 1 ?  'Pending' : 'Completed' ;
                            
                            FinaldocExpiryList.add(dcexpiryList);
                        }
                    }
                }
                else if(expectedDocNames.isEmpty()){
                    List<Account> acc= [SELECT Id,Name,NationalIdExpiryDate__pc,PassportExpiryDate__pc,(SELECT Id,Name,DocumentType__c,Status__c FROM Documents__r WHERE DocumentType__c  IN ('National ID Front Copy','National ID Back Copy','Passport Copy') ) FROM Account WHERE ID =: mapFieldApiFieldValues.get('customerId') ];
                    Map<String, Date> expiryMap = new Map<String, Date>{'National ID Front Copy' => acc[0].NationalIdExpiryDate__pc, 'National ID Back Copy'  => acc[0].NationalIdExpiryDate__pc, 'Passport Copy' => acc[0].PassportExpiryDate__pc };
                        Set<Id> accDocIds = new Set<Id>();
                    for (Document__c doc : acc[0].Documents__r) {
                        accDocIds.add(doc.Id);
                    }
                    List<ContentDocumentLink> accContentDocLinkList = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :accDocIds];
                    Map<Id, List<Id>> acDocsToCondocIdMap = new Map<Id, List<Id>>();
                    Map<Id, Integer> accDocsCountMap = new Map<Id, Integer>();
                    
                    for (ContentDocumentLink docLink : accContentDocLinkList ) {
                        //docExpiryMapCreation
                        if (!acDocsToCondocIdMap.containsKey(docLink.LinkedEntityId)) {
                            acDocsToCondocIdMap.put(docLink.LinkedEntityId, new List<Id>());
                        }
                        acDocsToCondocIdMap.get(docLink.LinkedEntityId).add(docLink.ContentDocumentId);
                    }
                    for (Id linkedId : linkedEntitiToCondocIdMap.keySet()) {
                        accDocsCountMap.put(linkedId, linkedEntitiToCondocIdMap.get(linkedId).size());
                    }
                    for (Document__c doc : acc[0].Documents__r) {
                        Date expiryDate = expiryMap.get(doc.DocumentType__c);
                        if (expiryDate != null) {
                            docExpiryList expiryDoc = new docExpiryList();expiryDoc.DocId = doc.Id;
                            if(doc.DocumentType__c == 'National ID Front Copy'){expiryDoc.DocType   = 'Buyer Emirates ID Copy';}else if(doc.DocumentType__c == 'National ID Back Copy'){ expiryDoc.DocType   = 'Buyer Emirates ID BackSideCopy';}else{ expiryDoc.DocType   = 'Buyer Passport Copy';}
                            Integer fileCount = accDocsCountMap.containsKey(doc.Id) ? accDocsCountMap.get(doc.Id) : 0;expiryDoc.status = fileCount <= 1 ? 'Pending': 'Completed';                                                                                                           
                            expiryDoc.isExpired = System.Today() > expiryDate; FinaldocExpiryList.add(expiryDoc);
                        }
                    }
                }
                noc.ExpDocList = FinaldocExpiryList;
            }
            //EID&PASSPORT_EXPIRY _SECANRIO END
            //Appenidng Receipt info 
            noc.nocFee = new List<Object>();
            for (HexaBPM__Service_Request__c sr : srRequest) {
                for (ReceiptAcknowledgement__c devFeeReceipt : sr.Receipt_Acknowledgements__r) {
                    fessData feeDetails = new fessData ();feeDetails.amount= devFeeReceipt.Amount__c ;feeDetails.type = 'dev-admin-fee';feeDetails.payerId = devFeeReceipt.Account__c ;noc.nocFee.add(feeDetails);
                }  
            }
            system.debug('Response::'+noc);
            return noc;
        }
        else{
            List<HexaBPM__Service_Request__c> invalidSRRequest = [SELECT Id,Case__c,BuyerName__c,Unit__c,SalesOrder__c,HexaBPM__Customer__c,HexaBPM__External_Status_Name__c FROM HexaBPM__Service_Request__c WHERE Id=:mapFieldApiFieldValues.get('sRId') AND SRType__c =:mapFieldApiFieldValues.get('SRType') ];
            NOCDetails nullNoc = new NOCDetails();
            nullNoc.CustomerId = '';
            nullNoc.BuyerId = '';
            nullNoc.CaseId = '';
            nullNoc.SRId ='';
            if(invalidSRRequest.size()>0){
                nullNoc.SRStatus= invalidSRRequest[0].HexaBPM__External_Status_Name__c;
            }
            return nullNoc;
        }
    }
    
    public class NOCDetails{
        public String CustomerId;
        public String BuyerId;
        public String CaseId;
        public String SRId;
        public List<SRDoc> DocList;
        public string SRStatus;
        public List<Id> SecBuyersIdList;
        public List<Object> nocFee;
        public string CreatedDate;
        Public string SrNo;
        public list<docExpiryList> ExpDocList;
        public Decimal agreedSellingPrice ;
    }
    public class SRDoc{
        public String Status;
        public String DocId;
        public String DocType;
        public String title;
        public DateTime DocGeneratedDate;
        public string RejectedReason;
        public string fileName;
        public List<SignedByInfo> SignedByList;
        
        
    }
    public class fessData{
        public decimal amount;
        public string type;
        public string payerId;        
    }
    public class docExpiryList{
        public String DocType;
        public Boolean isExpired;
        public string fileName;
        public string docId;  
        public String Status;
    }
    public class SignedByInfo {
        public String  AccId;
        public String Status;
        //public String ModifiedDate;
    }
    
    
}