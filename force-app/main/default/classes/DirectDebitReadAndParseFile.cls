public class DirectDebitReadAndParseFile {
    
    public static String ADCB                   		= 'Abu Dhabi Commercial Bank';
    public static String RegistrationAckNack            = 'Registration AckNack';
    public static String RegistrationResponse           = 'Registration Response';
    public static String RegistrationValidationResponse = 'Registration Validation';
    public static String CollectionResponse     		= 'Collection Response';
    public static String CollectionAckNack      		= 'Collection AckNack';
    public static String CancellationResponse   		= 'Cancellation Response';
    public static String CancellationAckNack   			= 'Cancellation AckNack';
    public static String SentToBank             		= 'Sent to Bank';
    public static String ACK                   			= 'ACK';
    
    public static void readContentVersionAndParse(List<DDResponseFiles__c> ddResponseFiles){
        Set<Id> contentDocumentIdSet                                 = new Set<Id>();
        Set<Id> LinkedEntityIdSet                                    = new Set<Id>();
        List<ContentDocumentLink> contentDocumentLinkList            = new List<ContentDocumentLink>();
        List<ContentVersion> contentVersionList                      = new List<ContentVersion>();
        Map<Id, Id> linkedEntityContentDocumentMap                   = new Map<Id, Id>();
        Map<Id, String> ContentDocumentVersionMap                    = new Map<Id, String>();
        Map<Id, String> ContentVersionTitleMap                       = new Map<Id, String>();
        Map<String, DDTransaction__c> ddTransactionMap               = getDirectDebitTransactionMap();
        List<DDTransaction__c> ackNackddTransactionList              = new List<DDTransaction__c>();
        List<DDTransaction__c> responseddTransactionList             = new List<DDTransaction__c>();
        Map<Id, DDTransaction__c> ddTransactionToBeUpdatedMap        = new Map<Id, DDTransaction__c>();
        Map<Id, DirectDebitRequest__c> ddrToBeUpdatedMap             = new Map<Id, DirectDebitRequest__c>();
        Map<String, Map<String, DDResponseFile__mdt>> ddHeaderResponseMap = new Map<String, Map<String, DDResponseFile__mdt>>();        // Bank Name =>( File Type => DDResponseFile__mdt Metadata)
        List<DDResponseFiles__c>  ddResponseFilesToBeUpdated         = new List<DDResponseFiles__c> (); 
        //Set<Id> file_Ids_ForLog                                      = new Set<Id>();
        
        try{
            List<Direct_Debit_Header__mdt> directDebitHeaderMetadat = [SELECT Id,
                                                                       Bank_Name__c,
                                                                       (SELECT Id,
                                                                        MasterLabel,
                                                                        FileType__c,
                                                                        DDIndexfield__c,
                                                                        Delimiter__c,
                                                                        Identifier_Index__c,
                                                                        Ack_Nack_Index__c,
                                                                        HasHeaders__c,
                                                                        SendFullResponse__c
                                                                        FROM DD_Response_File__r)
                                                                       FROM Direct_Debit_Header__mdt];
            
            for(Direct_Debit_Header__mdt mdt: directDebitHeaderMetadat){
                Map<String, DDResponseFile__mdt> ddResponseMap = new Map<String, DDResponseFile__mdt>();
                for(DDResponseFile__mdt respmtd: mdt.DD_Response_File__r){
                    ddResponseMap.put(respmtd.FileType__c, respmtd);
                    Map<String, DDResponseFile__mdt> ddfinalResponseMap = ddHeaderResponseMap.get(mdt.Bank_Name__c) != null ? ddHeaderResponseMap.get(mdt.Bank_Name__c) : new Map<String, DDResponseFile__mdt>();
                    ddfinalResponseMap.put(respmtd.FileType__c, respmtd);
                    ddHeaderResponseMap.put(mdt.Bank_Name__c, ddfinalResponseMap);
                }   
            }
            system.debug('ddResponseFiles:::'+ddResponseFiles);
            if(!ddResponseFiles.isEmpty()){
                for(DDResponseFiles__c ddResponseFile : ddResponseFiles){
                    LinkedEntityIdSet.add(ddResponseFile.Id);
                }
            }
            if(!LinkedEntityIdSet.isEmpty()){
                contentDocumentLinkList = [SELECT 
                                           ContentDocumentId,
                                           Id,
                                           LinkedEntityId,
                                           ShareType,
                                           Visibility
                                           FROM ContentDocumentLink
                                           WHERE LinkedEntityId IN: LinkedEntityIdSet];
            }
            
            if(!contentDocumentLinkList.isEmpty()){
               for(ContentDocumentLink contentDocumentLink : contentDocumentLinkList){
                    contentDocumentIdSet.add(contentDocumentLink.ContentDocumentId);
                    linkedEntityContentDocumentMap.put(contentDocumentLink.LinkedEntityId, contentDocumentLink.ContentDocumentId);
                }
            }
            if(!contentDocumentIdSet.isEmpty()){
                contentVersionList =  [SELECT
                                       VersionData,
                                       ContentDocumentId,
                                       Title
                                       FROM ContentVersion
                                       WHERE ContentDocumentId IN: contentDocumentIdSet
                                       ORDER BY Createddate Desc];
            }
            
            if(!contentVersionList.isEmpty()) {
                for(ContentVersion contentVersion : contentVersionList) {
                    ContentDocumentVersionMap.put(contentVersion.ContentDocumentId, ContentVersion.VersionData.toString());
                    ContentVersionTitleMap.put(contentVersion.ContentDocumentId, contentVersion.Title);
                }
            } 
            
            if(!ddResponseFiles.isEmpty()) {
                for(DDResponseFiles__c ddResponseFile : ddResponseFiles){
                    system.debug('ddResponseFile:::'+ddResponseFile);
                    Integer totalCount = 0;
                    Integer processedRecords = 0;
                    Map<String, DDResponseFile__mdt> ddResponseMap = ddHeaderResponseMap.get(ddResponseFile.Bank__c);
                    DDResponseFile__mdt ddResponseFileMdt = ddResponseMap.get(ddResponseFile.Type__c);
                    system.debug('ddResponseFileMdt:::'+ddResponseFileMdt);
                    Integer iterationSize = ddResponseFileMdt.HasHeaders__c ? 1 : 0;
                    String versionDataString = ContentDocumentVersionMap.get(linkedEntityContentDocumentMap.get(ddResponseFile.Id));
                   // String versionDataTitle = ContentVersionTitleMap.get(linkedEntityContentDocumentMap.get(ddResponseFile.Id));
                    boolean isRESFile = ContentVersionTitleMap.get(linkedEntityContentDocumentMap.get(ddResponseFile.Id)).endsWithIgnoreCase('.Res') ? true : false;
                    system.debug('isRESFile::'+isRESFile);
                    system.debug('versionDataString:::'+versionDataString);
                    string delimiter;
                    if(ddResponseFileMdt.Delimiter__c == '|'){ delimiter = '\\|';  
                    }else{
                        delimiter = ddResponseFileMdt.Delimiter__c;
                    }
                    
                    List<String> ddtResponseList = versionDataString.split('\n');
                    system.debug('ddtResponseList:::'+ddtResponseList);
                    /*Checking if File is empty*/
                    if(iterationSize == ddtResponseList.size()){
                        ddResponseFile.BlankFile__c = true;
                        ddResponseFile.Status__c = 'Processed';    
                    }
                    system.debug('iterationSize::'+iterationSize);
                    for(Integer i = iterationSize; i< ddtResponseList.size(); i++) {
                        DDTransaction__c ddTransaction = new DDTransaction__c();
                        DirectDebitRequest__c directDebitRequest = new DirectDebitRequest__c();
                        if(ddtResponseList[i].contains(ddResponseFileMdt.Delimiter__c+ddResponseFileMdt.Delimiter__c)){
                            ddtResponseList[i] = ddtResponseList[i].replace(ddResponseFileMdt.Delimiter__c+ddResponseFileMdt.Delimiter__c, ddResponseFileMdt.Delimiter__c+'Null'+ddResponseFileMdt.Delimiter__c);
                        }
                        system.debug('ddtResponseList::'+ddtResponseList);
                        system.debug('ddtResponseList.size()::'+ddtResponseList.size());
                        List<String> responseValueString = ddtResponseList[i].split(delimiter);
                        system.debug('responseValueString::'+responseValueString);
                        totalCount = ddResponseFile.Bank__c != ADCB ? (ddtResponseList.size()-1) : 1;
                        system.debug('responseValueString:::'+responseValueString);
                       
                        /*To handle .Res type of file */
                        if(isRESFile){
                          //  system.debug(ContentVersionTitleMap.get(linkedEntityContentDocumentMap.get(ddResponseFile.Id)).split('\\.')[0]);
                            string RequestFileName = ContentVersionTitleMap.get(linkedEntityContentDocumentMap.get(ddResponseFile.Id)).split('\\.')[0]+'.'+ContentVersionTitleMap.get(linkedEntityContentDocumentMap.get(ddResponseFile.Id)).split('\\.')[1];
                            if(ddTransactionMap.containskey(RequestFileName)){
                                ddTransaction.Id = ddTransactionMap.get(RequestFileName).Id; 
                                ddTransaction.DDResponse__c  = versionDataString;
                                ddTransaction.DDResponsefiletype__c = ddResponseFile.Type__c;
                                ddTransaction.TransactionStatus__c = 'Rejected';
                                ddTransaction.DD_Response_Files__c = ddResponseFile.id;
                                
                                directDebitRequest.Id = ddTransactionMap.get(RequestFileName).DirectDebitRequest__c;
                                directDebitRequest.Rejection_Reason__c = versionDataString;
                               
                                ddrToBeUpdatedMap.put(directDebitRequest.Id, directDebitRequest);
                                ddTransactionToBeUpdatedMap.put(ddTransactionMap.get(RequestFileName).Id, ddTransaction);
                                
                                ddResponseFile.SkippedRecordValues__c = RequestFileName;
                                ddResponseFile.Status__c = 'Processed';
                                ddResponseFilesToBeUpdated.add(ddResponseFile);
                            }
                            
                        }else{
                            
                            for(Integer j = 0; j<responseValueString.size(); j++) {
                              
                                if((j+1 == Integer.valueOf(ddResponseFileMdt.Identifier_Index__c)) && responseValueString[j] != null && responseValueString[j] != ''){
                                  /*  if(ddResponseFile.Type__c == CancellationAckNack && ddResponseFile.Bank__c == ADCB){
                                        responseValueString[j]= responseValueString[j].substringBetween('(', ')');  
                                    } */
                                    system.debug('responseValueString[j]::'+responseValueString[j]);
                                    system.debug('ddTransactionMap.get(responseValueString[j]):::'+ddTransactionMap.get(responseValueString[j]));
                                    if(ddTransactionMap.get(responseValueString[j]) != null && responseValueString[j] != null){
                                        
                                        system.debug('responseValueString[j]::'+responseValueString[j]);
                                        system.debug('ddTransactionMap.get(responseValueString[j]):::'+ddTransactionMap.get(responseValueString[j]));
                                        
                                        ddTransaction.Id = ddTransactionMap.get(responseValueString[j]).Id;
                                        ddTransaction.DD_Response_Files__c = ddResponseFile.id;
                                        string resp = ddResponseFileMdt.SendFullResponse__c ? versionDataString : ddtResponseList[i];
                                        
                                        if(ddResponseFile.Type__c == RegistrationAckNack || ddResponseFile.Type__c == CollectionAckNack || ddResponseFile.Type__c == CancellationAckNack){
                                            ddTransaction.DDResponse__c = ddResponseFile.Bank__c != ADCB ? ('ACKNAK'+resp) : resp;
                                        }
                                        if(ddResponseFile.Type__c == RegistrationResponse || ddResponseFile.Type__c == CollectionResponse || ddResponseFile.Type__c == CancellationResponse){
                                            ddTransaction.DDResponse__c =  !resp.startsWith('DACDR') ? ('DACDR'+resp) : resp;
                                        }
                                        if(ddResponseFile.Type__c == RegistrationValidationResponse && ddTransactionMap.get(responseValueString[j]).TransactionStatus__c == SentToBank){
                                            ddTransaction.DDResponse__c =  !resp.startsWith('REGVAL') ? ('REGVAL'+resp) : resp;
                                        }
                                        if(ddTransaction.DDResponse__c != null){
                                            ddResponseFile.Status__c = 'Processed';
                                        }
                                        ddTransaction.DDResponsefiletype__c = ddResponseFile.Type__c;
                                        ddTransactionToBeUpdatedMap.put(ddTransactionMap.get(responseValueString[j]).Id, ddTransaction);
                                        
                                        system.debug('ddTransactionMap.get(responseValueString[j])::'+ddTransactionMap.get(responseValueString[j]));
                                        system.debug('ddTransactionToBeUpdatedMap::'+ddTransactionToBeUpdatedMap.keySet().size());
                                        processedRecords = ddTransactionToBeUpdatedMap.keySet().size();
                                        
                                    }else /*Skipped records*/
                                    {
                                        ddResponseFile.SkippedRecordValues__c = ddResponseFile.SkippedRecordValues__c+'; '+responseValueString[j];
                                        ddResponseFile.SkippedRecordValues__c = ddResponseFile.SkippedRecordValues__c.replace('null;', '');
                                        ddResponseFile.Status__c = 'Processed';
                                    }
                                    ddResponseFile.TotalRecords__c     = totalCount;
                                    ddResponseFile.ProcessedRecords__c = processedRecords;
                                    ddResponseFile.SkippedRecords__c   =  (totalCount-processedRecords);
                                }
                            }
                        }
                    }
                    if(!ddResponseFilesToBeUpdated.contains(ddResponseFile)){
                        ddResponseFilesToBeUpdated.add(ddResponseFile);
                    }
                }
                
            }
        system.debug('ddTransactionToBeUpdatedMap:::'+ddTransactionToBeUpdatedMap);
            if(ddTransactionToBeUpdatedMap != null){
                update ddTransactionToBeUpdatedMap.values();
                
                if(!ddResponseFilesToBeUpdated.isEmpty()){
                    update ddResponseFilesToBeUpdated;
                }
                
                if(ddrToBeUpdatedMap != null){
                    update ddrToBeUpdatedMap.values();
                }
            } 
        }catch(Exception e){  LoggerService.save(LoggerService.addApexLog(e,'DirectDebitReadAndParseFile','readContentVersionAndParse',''));
        } 
        
    }
    public static Map<String, DDTransaction__c> getDirectDebitTransactionMap() {
        Map<String, DDTransaction__c> ddTransactionMap = new Map<String, DDTransaction__c> ();
        List<DDTransaction__c> ddTransactionList =  [SELECT
                                                     DDResponseFileName__c,
                                                     DDResponse__c,
                                                     DDBank__c,
                                                     RequestFileName__c,
                                                     Id,
                                                     DirectDebitRequest__c,
                                                     DirectDebitRequest__r.PayerIdentification__c,
                                                     DirectDebitRequest__r.DDAreferencenumber__c,
                                                     TransactionStatus__c,
                                                     Requesttype__c
                                                     FROM DDTransaction__c
                                                     WHERE ((TransactionStatus__c=: SentToBank
                                                             OR TransactionStatus__c=: ACK)
                                                             AND Is_EDDS__c = FALSE
                                                            AND DirectDebitRequest__r.Status__c NOT IN ('Cancelled', 'Approved by bank but SO cancelled', ''))
                                                    ];
        for(DDTransaction__c ddTransaction: ddTransactionList) {
            
            if(ddTransaction.DirectDebitRequest__r.PayerIdentification__c != null){
                ddTransactionMap.put(ddTransaction.DirectDebitRequest__r.PayerIdentification__c, ddTransaction);
            }
            if(ddTransaction.DDBank__c == ADCB && ddTransaction.RequestFileName__c != null){
                ddTransactionMap.put(ddTransaction.RequestFileName__c, ddTransaction); 
            }
            if( (ddTransaction.Requesttype__c == 'Collection' ||  ddTransaction.Requesttype__c == 'Cancellation') && ddTransaction.DirectDebitRequest__r.DDAreferencenumber__c != null){
                ddTransactionMap.put(ddTransaction.DirectDebitRequest__r.DDAreferencenumber__c, ddTransaction);
            }
        }
        system.debug('ddTransactionMap::'+ddTransactionMap);
        
        return ddTransactionMap;
    }
    
}