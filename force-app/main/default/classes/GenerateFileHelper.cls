/**********************************************************************************************************************
* Name               : GenerateFileHelper                                                        
* Description        : This Apex class will create DDS (txt file) and get signedRegistration form from document placeholder
and attach it to the created DDTransaction record.
* Method			 : (prepareFileFromDDTBulkify) Accepting a map of DDR and child DDT
* Created By         : tdontha@aldar.com - Tharun                                                   
******************************************************************************************************************/

public class GenerateFileHelper{
    
    public static String ClassName 									= 'GenerateFileHelper';
    public static String Method_prepareFileFromDDTBulkify 			= 'prepareFileFromDDTBulkify';
    public static String LOG_PROCESS_NAME	 						= 'DirectDebit';
    public static String CancellationFileName = '';
    public static void prepareFileFromDDTBulkify(Map<Id, DDTransaction__c> ddrDDTMapIds){
        
        System.debug('ddrDDTMapIds::'+ddrDDTMapIds);
        
        Set<String> requestTypes = new Set<String>();
        //All DirectDebitRequest Ids are stored here
        Set<Id> ddrIds = new Set<Id>();
        for(Id ddr : ddrDDTMapIds.keySet()){
            ddrIds.add(ddr);
        }
        
        Set<Id> ddTIds = new Set<Id>();
        for(DDTransaction__c ddT :  ddrDDTMapIds.Values()){
            ddTIds.add(ddT.id);
            requestTypes.add(ddT.RequestType__c);
        }
        
        Map<Id, DDTransaction__c> allDDTRecordsMap = new Map<Id, DDTransaction__c>([SELECT
                                                                                    Id,
                                                                                    Name,
                                                                                    DDBank__c,
                                                                                    DirectDebitRequest__c,
                                                                                    Sponsoring_Bank_Transaction_Reference_No__c,
                                                                                    DDA_Unique_Number__c,
                                                                                    Requesttype__c,
                                                                                    RequestFileName__c,
                                                                                    TransactionReferenceNumber__c
                                                                                    FROM DDTransaction__c
                                                                                    WHERE Id IN: ddTIds]);
        system.debug('allDDTRecordsMap::'+allDDTRecordsMap);
        
        Set<String> allFieldList			= Schema.getGlobalDescribe().get('DirectDebitRequest__c').getDescribe().fields.getMap().keySet();
        List<String> strList				= new List<String>();
        strList.addAll(allFieldList);
        String fields						= String.join(strList,',');
        fields = fields+', SalesOrder__r.Unit__r.Project__r.BankNameEscrow__c  ';
        String queryToGetAllDDRList			= 'SELECT ' + fields + ' FROM DirectDebitRequest__c WHERE ID IN: ddrIds';
        List<DirectDebitRequest__c> ddrList = Database.Query(queryToGetAllDDRList);
        
        Map<Id,String> uniqueRefNumberByDDT = new Map<Id,String>();
        Map<Id,DDTransaction__c> ddtMapToUpdate = new Map<Id,DDTransaction__c>();
        
        Map<String,Map<String,Direct_Debit_Header__mdt>> ddHeaderByRequestTypeByBank = new Map<String,Map<String,Direct_Debit_Header__mdt>>();
        
        //Workaround for Order By Start
        List<Integer> colOrdersLst							= new List<Integer>();
        Map<Integer, DirectDebit__mdt> colDDRec				= new Map<Integer, DirectDebit__mdt>(); 
        Map<String, Map<Integer, DirectDebit__mdt>> headerAndChild = new Map<String, Map<Integer, DirectDebit__mdt>>();
        //Workaround for Order By End
        
        for(Direct_Debit_Header__mdt ddh : [SELECT Id, Bank_Name__c, ControlRecordsCount__c, Request_type__c,
                                            File_format__c, File_name_prefix__c, File_name_postfix__c,
                                            Column_Separator__c,Include_headers__c,DateFormat__c,
                                            (SELECT Id,ColumnHeader__c,label,DefaultValue__c,PostFix__c,
                                             Prefix__c,RequestType__c, ColumnOrder__c,Type__c, Direct_Debit_Header__c, 
                                             IsActive__c, Query_Field__c  FROM Direct_Debit__r Where IsActive__c = true)
                                            FROM Direct_Debit_Header__mdt]){
                                                //Removed ORDER BY ColumnOrder__c ASC from Child Query
                                                
                                                for(DirectDebit__mdt ddR : ddh.Direct_Debit__r){
                                                    Integer colOrdVal = Integer.valueOf(ddR.ColumnOrder__c);
                                                    colOrdersLst.add(colOrdVal);
                                                    colDDRec.put(colOrdVal, ddR);
                                                }
                                                
                                                colOrdersLst.sort(); //Sorting by the Coloumn Order
                                                
                                                for(Integer colOrd : colOrdersLst) {
                                                    if(headerAndChild.containsKey(ddh.Bank_Name__c+'_'+ddh.Request_type__c)){
                                                        headerAndChild.get(ddh.Bank_Name__c+'_'+ddh.Request_type__c).put(colOrd,colDDRec.get(colOrd));
                                                    }else{
                                                        headerAndChild.put(ddh.Bank_Name__c+'_'+ddh.Request_type__c, new Map<Integer,DirectDebit__mdt>{colOrd=>colDDRec.get(colOrd)});
                                                    }
                                                }
                                                if(ddHeaderByRequestTypeByBank.containsKey(ddh.Bank_Name__c)){
                                                    ddHeaderByRequestTypeByBank.get(ddh.Bank_Name__c).put(ddh.Request_type__c ,ddh);
                                                }else{
                                                    //This occurance is only once for the first time
                                                    ddHeaderByRequestTypeByBank.put(ddh.Bank_Name__c,new Map<String,Direct_Debit_Header__mdt>{ddh.Request_type__c=>ddh});
                                                }
                                                colOrdersLst.clear();
                                            }
        
        
        // Bank & request should not be null. - Filed level required.
        // Generic email method to send email for any exception in DD.
        Map<Id, ContentVersion> fileByDDRId 			= new Map<Id, ContentVersion>();
        
        // fileName  => ddrid -> to get id for CDL 
        Map<String,id> ddrIdByFileName 					= new Map<String,id>();
        List<String> strFileGenerationDateFields 		= System.label.FileGenerationDateFields.split(';');
        Date dateToday = Date.today();
        
        
        //START - DirectDebitRequest single record for loop begins
        for(DirectDebitRequest__c ddrSingle : ddrList) {
            String headerString = '';
            String fileContent = '';
            
            if(ddHeaderByRequestTypeByBank.containsKey(ddrSingle.DirectDebitBank__c)){
                if(ddHeaderByRequestTypeByBank.get(ddrSingle.DirectDebitBank__c).containsKey(ddrDDTMapIds.get(ddrSingle.Id).RequestType__c)){
                    
                    Direct_Debit_Header__mdt ddh = ddHeaderByRequestTypeByBank.get(ddrSingle.DirectDebitBank__c).get(ddrDDTMapIds.get(ddrSingle.Id).RequestType__c);
                    if(ddh.Column_Separator__c != null) {
                        for(DirectDebit__mdt ddColumn : headerAndChild.get(ddh.Bank_Name__c+'_'+ddrDDTMapIds.get(ddrSingle.Id).RequestType__c).values()) {
                            headerString += ddColumn.ColumnHeader__c +ddh.Column_Separator__c ;
                            if(ddColumn.DefaultValue__c != null ){
                                fileContent += ddColumn.DefaultValue__c ;
                            }else  {
                                if(ddColumn.Prefix__c != null){
                                    fileContent += ddColumn.Prefix__c ;
                                }
                                if(ddColumn.Query_Field__c !=  null){
                                    //  Moved to CustomLabel to remove end for Date fields
                                    if(strFileGenerationDateFields.contains(ddColumn.Query_Field__c)){
                                        if(ddColumn.Query_Field__c == 'CommencesOn__c' || ddColumn.Query_Field__c == 'ExpiresOn__c'  && ddh.Bank_Name__c == 'First Abu Dhabi Bank'){
                                            datetime dt = (datetime)ddrSingle.get(ddColumn.Query_Field__c);
                                            fileContent += (ddrSingle.get(ddColumn.Query_Field__c) == null ? '' : String.valueOf(dt.format(ddh.DateFormat__c)) );
                                        }else if((ddColumn.Query_Field__c == 'FirstInitiationDate__c') &&  ddrSingle.get('PaymentFrequency__c') == 'Daily' && ddh.Bank_Name__c == 'First Abu Dhabi Bank'){
                                            fileContent += '';
                                        }else{
                                            fileContent += (ddrSingle.get(ddColumn.Query_Field__c) == null ? '' : String.valueOf(ddrSingle.get(ddColumn.Query_Field__c)).removeEnd(' 00:00:00') );
                                        } 
                                    } else if(( ddColumn.Query_Field__c == 'FrequencyParameter__c') &&  ddrSingle.get('PaymentFrequency__c') == 'Daily' && ddh.Bank_Name__c == 'First Abu Dhabi Bank'){
                                        fileContent += '';
                                    } 
                                    else if(ddColumn.Query_Field__c == 'RequestingBankReferenceNumber__c'){
                                        String dateStringForReqBankrefNum = String.valueof(dateToday.year()).right(2) + String.valueof(dateToday.month()).leftPad(2, '0') + String.valueof(dateToday.day()).leftPad(2, '0') ;
                                        String uniqRefNum = dateStringForReqBankrefNum + allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id).Id).Name.right(4);
                                        fileContent += uniqRefNum;
                                        uniqueRefNumberByDDT.put(allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id).Id).Id,uniqRefNum);
                                        
                                        DDTransaction__c ddt = new DDTransaction__c(Id=allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id).Id).Id,UniqueRegNumber__c=uniqRefNum);
                                        ddtMapToUpdate.put(ddt.Id,ddt);
                                    }
                                    else{
                                        fileContent += (ddrSingle.get(ddColumn.Query_Field__c) == null ? '' : ddrSingle.get(ddColumn.Query_Field__c) );
                                    }
                                    
                                    if(ddColumn.Query_Field__c == 'CollectionAmount__c'){
                                        fileContent +=  ddrDDTMapIds.get(ddrSingle.Id).CollectionAmount__c;
                                    }
                                }else {
                                    if(ddColumn.ColumnHeader__c == 'File creation date'){
                                        fileContent += String.valueOf(Datetime.now().format(ddh.DateFormat__c));
                                    }
                                    if(ddColumn.ColumnHeader__c == 'File creation time' ){
                                        fileContent += String.valueOf(Datetime.now().format('HH:mm:ss'));
                                    }
                                    if(ddColumn.ColumnHeader__c == 'Scanned DDA Copy PDF File Name' && ddrDDTMapIds.get(ddrSingle.Id).Requesttype__c == 'Cancellation'){
                                       // fileContent += ddrDDTMapIds.get(ddrSingle.Id).Requesttype__c == 'Cancellation' ? allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id).Id).Name.right(3)+'400'+ String.valueOf(Datetime.now().format('ddMMYYHHmm'))+'.pdf' : allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id).Id).Name.right(6)+String.valueOf(Datetime.now().format('YYMM'))+'.pdf';
                                      //  fileContent += Label.ADCB_BankRefNumber+allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id).Id).Name.right(6)+String.valueOf(Datetime.now().format('YYMM'))+'.pdf';
                                        fileContent += '003400'+allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id).Id).Name.right(6)+String.valueOf(Datetime.now().format('YYMM'))+'.pdf';
                                       // CancellationFileName = ddrDDTMapIds.get(ddrSingle.Id).Requesttype__c == 'Cancellation' ? allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id).Id).Name.right(3)+'400'+ String.valueOf(Datetime.now().format('ddMMYYHHmm'))+'.pdf' : allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id).Id).Name.right(6)+String.valueOf(Datetime.now().format('YYMM'))+'.pdf';
                                        //fileContent += allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id).Id).Name.right(6)+String.valueOf(Datetime.now().format('YYMM'))+'.pdf';
                                    }
                                    if(ddColumn.ColumnHeader__c == 'Scanned DDA Copy PDF File Name' && ddrDDTMapIds.get(ddrSingle.Id).Requesttype__c == 'New Registration'){
                                      fileContent += allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id).Id).Name.right(6)+String.valueOf(Datetime.now().format('YYMM'))+'.pdf';
                                    }
                                    if(ddColumn.ColumnHeader__c == 'Image File Name'){
                                        //fileContent += ddh.File_name_prefix__c+allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id)).Name.right(6)+String.valueOf(Datetime.now().format('YYMMddHH'))+'.pdf';
                                        //ddh.File_name_prefix__c+'-'+
                                        fileContent +=ddh.File_name_prefix__c+'-'+ddrSingle.OIC__c+'-'+String.valueOf(Datetime.now().format('ddMMYY'))+'-'+allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id).Id).Name.right(6)+'.pdf';
                                        //ddrSingle.OIC__c+'-'+String.valueOf(Datetime.now().format('ddMMYY'))+'-'+allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id)).Name.right(6)+'-Registration'+'.pdf';
                                    } 
                                    
                                    if(ddColumn.ColumnHeader__c == 'Sponsoring Bank Transaction Reference Number'){
                                        fileContent += allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id).Id).Sponsoring_Bank_Transaction_Reference_No__c;
                                    } if(ddColumn.ColumnHeader__c == 'Sponsoring Bank Sequence Number'){
                                        fileContent +=allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id).Id).Name.right(6) ;
                                    } if(ddColumn.ColumnHeader__c == 'Direct Debit Reference Number'){
                                        fileContent += allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id).Id).DDA_Unique_Number__c;
                                    } if(ddColumn.ColumnHeader__c == 'Sending Institution Reference Number'){
                                        fileContent += allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id).Id).name.right(3)+'DCI'+String.valueOf(Datetime.now().format('YYMMdd'))+allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id).Id).name.right(4);
                                    }if(ddColumn.ColumnHeader__c == 'Transaction Reference Number'){
                                        fileContent += allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id).Id).TransactionReferenceNumber__c;
                                    }
                                    if(ddColumn.ColumnHeader__c == 'PDF File Name' && ddrSingle.DirectDebitBank__c == 'First Abu Dhabi Bank' ){
                                        fileContent += (ddh.File_name_prefix__c+'-'+ddrSingle.OIC__c+'-'+String.valueOf(Datetime.now().format('ddMMYY'))+'-'+allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id).Id).Name.right(6)+'.pdf');
                                    }
                                }
                                if(ddColumn.PostFix__c != null){
                                    fileContent += ddColumn.PostFix__c ;
                                }
                            }
                            
                            //For ADCB Bank Control Record
                            if(ddColumn.ColumnOrder__c!=null && Integer.valueOf(ddColumn.ColumnOrder__c) == ddh.ControlRecordsCount__c) {
                                fileContent = fileContent+'\n';
                            } else {
                                fileContent += ddh.Column_Separator__c;
                            }
                        }
                        
                        System.debug('FinalheaderString '+headerString);
                        headerString = headerString.removeEnd(ddh.Column_Separator__c);
                        if(ddh.Bank_Name__c == 'First Abu Dhabi Bank'){
                            headerString = headerString + '\n'+'\n';
                        }else {
                            headerString = headerString + '\n';
                        }
                        fileContent = fileContent.removeEnd(ddh.Column_Separator__c);
                        
                        
                        String finalString = '';
                        if(ddh.Include_headers__c 
                           && allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id).Id).Requesttype__c != 'Collection' 
                               && ddrSingle.DirectDebitBank__c == 'First Abu Dhabi Bank' 
                          ){
                                finalString = headerString  + fileContent ;
   
                        }else{
                            finalString =  fileContent ;
                        }
                        
                        ContentVersion cv = new ContentVersion();
                        cv.ContentLocation = 'S'; //denotes it resides on Salesforce
                        String fileName = '';
                        //C300003[6 digit internal reference Name of DDT Record]YYMMDDHHMMSS.DDS
                        if(ddrSingle.DirectDebitBank__c == 'First Abu Dhabi Bank'){
                            fileName =  (ddh.File_name_prefix__c+'-'+ddrSingle.OIC__c+'-'+String.valueOf(Datetime.now().format('ddMMYY'))+'-'+allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id).Id).Name.right(6)+ddh.File_format__c);
                                }else {
                                    
                                    fileName = ddh.File_name_prefix__c+allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id).Id).Name.right(6)+String.valueOf(Datetime.now().format('YYMMddHHmmss'))+ddh.File_format__c; //title of the file
                                }
                        cv.Title = fileName;
                        if(ddtMapToUpdate.containsKey(allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id).Id).Id)){
                            ddtMapToUpdate.get(allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id).Id).Id).RequestFileName__c = fileName;
                        }else{
                            ddtMapToUpdate.put(allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id).Id).Id,new DDTransaction__c(Id=allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id).Id).Id,
                                                                                                                               RequestFileName__c=fileName));
                        }
                        cv.PathOnClient = fileName;
                        //cv.PathOnClient = ddh.File_name_prefix__c+allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingle.Id)).Name.right(6)+String.valueOf(Datetime.now().format('YYMMddHHmmss'))+ddh.File_format__c; // full path within Salesforce this can just be the name of file to be in the library
                        cv.VersionData = Blob.valueOf(finalString); //file data
                        //if(ddrDDTMapIds.get(ddrSingle.Id).RequestType__c != 'Collection'){
                        fileByDDRId.put(ddrSingle.Id, cv);
                        ddrIdByFileName.put(cv.Title,ddrSingle.Id );
                        //}
                    }else{
                        // handle exception.
                        // Message - Column Separator for the Bank and RequestType is not specified in Direct_Debit_Header__mdt
                        String StackTraceRecord = 'ddh.Column_Separator__c - '+ddh.Column_Separator__c;
                        LoggerService.save(DirectDebitService.createApexInfoLog('Column Separator for the Bank and RequestType is not specified in Direct_Debit_Header__mdt',
                                                                                LOG_PROCESS_NAME,
                                                                                ClassName,
                                                                                Method_prepareFileFromDDTBulkify,
                                                                                StackTraceRecord));
                    }
                }else{
                    // handle exception
                    // Message - RequestType for the Bank is not found in Direct_Debit_Header__mdt CustomMetadata
                    String StackTraceRecord = 'ddrSingle.RequestType__c - '+ddrDDTMapIds.get(ddrSingle.Id).RequestType__c;
                    LoggerService.save(DirectDebitService.createApexInfoLog('RequestType for the Bank is not found in Direct_Debit_Header__mdt CustomMetadata',
                                                                            LOG_PROCESS_NAME,
                                                                            ClassName,
                                                                            Method_prepareFileFromDDTBulkify,
                                                                            StackTraceRecord));
                }
            }else{
                // handle exception
                // Message - Bank name is not found in Direct_Debit_Header__mdt CustomMetadata
                String StackTraceRecord = 'ddrSingle.DirectDebitBank__c - '+ddrSingle.DirectDebitBank__c;
                LoggerService.save(DirectDebitService.createApexInfoLog('Bank name is not found in Direct_Debit_Header__mdt CustomMetadata',
                                                                        LOG_PROCESS_NAME,
                                                                        ClassName,
                                                                        Method_prepareFileFromDDTBulkify,
                                                                        StackTraceRecord));
            }
            System.debug('fileByDDRId-VALUES'+fileByDDRId.values());
        }
        //END - DirectDebitRequest single record for loop ENDS
        
        
        
        
        
        //START - Creation of text File
        List<ContentVersion> cvList 				= new List<ContentVersion>();
        List<ContentDocumentLink> cdlTxtFileList	= new List<ContentDocumentLink>();
        if(fileByDDRId.values().size() > 0)
        {
            cvList = fileByDDRId.Values();
            upsert cvList;
            for(ContentVersion insertedCv : [SELECT ContentDocumentId,title FROM ContentVersion WHERE Id IN :cvList]){
                ContentDocumentLink cdl = New ContentDocumentLink();
                cdl.LinkedEntityId = ddrDDTMapIds.get(ddrIdByFileName.get(insertedCv.title)).Id  ;
                cdl.ContentDocumentId = insertedCv.ContentDocumentId;
                cdl.shareType = 'V';
                cdlTxtFileList.add(cdl);
            }
        }
        
        //START of DML Action
        if(cdlTxtFileList.size() > 0 ){
            //Database methods - partial update - if true then all records will fail
            // 									  if false then success records will be inserted
            Database.SaveResult[] srList = Database.insert(cdlTxtFileList, false); //DML_ACTION
            for (Database.SaveResult sr : srList){
                if (sr.isSuccess()) {
                    
                } else {
                    for(Database.Error errDml1 : sr.getErrors()) {
                        LoggerService.save(LoggerService.createApexLog(errDml1,'DD-CreationOf_TextFile',ClassName,Method_prepareFileFromDDTBulkify));
                    }
                }
            }
        }
        //END of DML Action
        //END of file text insertion
        
        
        
        
        
        //START - Getting the Image pdfc file and attach to DDTransaction record
        //cdl.LinkedEntityId = ddT Record
        //Create CV with blob file from DDR
        Map<String, Map<Id, Id>> ddrRequestDocumentMap          = new Map<String, Map<Id, Id>>();
        Map<Id, Id> ddrDocumentMap								= new Map<Id, Id>();
        Map<Id, Id> documentContentLinkMap						= new Map<Id, Id>();
        Map<Id, ContentVersion> ContentLinkContentVersionMap 	= new Map<Id, ContentVersion>();
        Set<Id> signedDocumentsSetIds 							= new Set<Id>();
        Map<Id, ContentVersion> pdfFileByDDRId 					= new Map<Id, ContentVersion>();
        Map<String, Id> ddrIdByPdfFileName 						= new Map<String, Id>();
        List<ContentDocumentLink> contentDocumentLinks			= new List<ContentDocumentLink>();
        
        for(DirectDebitRequest__c ddrDocSingle  :[SELECT Id,
                                                  (SELECT
                                                   ID,
                                                   DocumentType__c
                                                   FROM Documents__r 
                                                   WHERE DocumentType__c IN  ('Signed direct debit registration form','Signed Direct Debit Cancellation form'))
                                                  FROM DirectDebitRequest__c
                                                  WHERE ID IN: ddrIds ]){
                                                      
                                                      if(ddrDDTMapIds.get(ddrDocSingle.Id).RequestType__c != 'Collection') {
                                                          for(Document__c docSingle : ddrDocSingle.Documents__r){
                                                              Map<Id, Id> finalddrDocumentMap = ddrRequestDocumentMap.get(ddrDDTMapIds.get(ddrDocSingle.Id).RequestType__c) != null ? ddrRequestDocumentMap.get(ddrDDTMapIds.get(ddrDocSingle.Id).RequestType__c) : new Map<Id, Id>();
                                                              signedDocumentsSetIds.add(docSingle.Id);
                                                              ddrDocumentMap.put(ddrDocSingle.Id, docSingle.Id);
                                                              
                                                              system.debug('docSingle.DocumentType__c ::'+docSingle.DocumentType__c );
                                                              system.debug('ddrDDTMapIds.get(ddrDocSingle.id).RequestType__c ::'+ddrDDTMapIds.get(ddrDocSingle.id).RequestType__c);
                                                              
                                                              if(docSingle.DocumentType__c == 'Signed Direct Debit Cancellation form' && ddrDDTMapIds.get(ddrDocSingle.id).RequestType__c == 'Cancellation'){
                                                                  finalddrDocumentMap.put(ddrDocSingle.Id, docSingle.Id);
                                                                  ddrRequestDocumentMap.put('Cancellation', finalddrDocumentMap);  
                                                              }else if(docSingle.DocumentType__c == 'Signed direct debit registration form' && ddrDDTMapIds.get(ddrDocSingle.id).RequestType__c == 'New Registration'){
                                                                  finalddrDocumentMap.put(ddrDocSingle.Id, docSingle.Id);
                                                                  ddrRequestDocumentMap.put('New Registration', finalddrDocumentMap);  
                                                              }
                                                              
                                                          }
                                                      }
                                                      
                                                  }
        
        if(signedDocumentsSetIds.size() > 0){
            contentDocumentLinks = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink
                                    WHERE LinkedEntityId IN :signedDocumentsSetIds];
        }
        if (contentDocumentLinks.size() > 0) {
            List<Id> contentDocumentLinkIds = new List<Id>();
            for (ContentDocumentLink contentDocumentLink : contentDocumentLinks ){
                contentDocumentLinkIds.add(contentDocumentLink.ContentDocumentId);
                documentContentLinkMap.put(contentDocumentLink.LinkedEntityId, contentDocumentLink.ContentDocumentId);
            }
            List<ContentVersion> contentVersions = [SELECT Id,ContentDocumentId,Title,VersionData,isLatest,FileExtension
                                                    FROM ContentVersion 
                                                    WHERE ContentDocumentId IN :contentDocumentLinkIds 
                                                    AND IsLatest = true];
            
            for(ContentVersion conVersion:contentVersions) {
                ContentLinkContentVersionMap.put(conVersion.ContentDocumentId, conVersion);
            }
            
            for(DirectDebitRequest__c ddrSingleDoc : [SELECT
                                                      Id,Name,
                                                      SalesOrder__r.Unit__r.Project__r.BankNameEscrow__c,
                                                      DirectDebitBank__c,
                                                      RequestType__c,CancelDirectDebitRequest__c, OIC__c
                                                      FROM DirectDebitRequest__c WHERE ID IN: ddrIds]){
                                                          if (contentVersions.size() > 0) {
                                                              Map<Id, Id> finalddrDocumentMap = ddrRequestDocumentMap.get(ddrDDTMapIds.get(ddrSingleDoc.id).RequestType__c);
                                                              ContentVersion cver = ContentLinkContentVersionMap.get(documentContentLinkMap.get(finalddrDocumentMap.get(ddrSingleDoc.id)));
                                                              system.debug('cver::'+cver);
                                                              ContentVersion cvSinglePDF = new ContentVersion();
                                                              cvSinglePDF.ContentLocation = 'S';
                                                              Direct_Debit_Header__mdt ddh = ddHeaderByRequestTypeByBank.get(ddrSingleDoc.DirectDebitBank__c).get(ddrDDTMapIds.get(ddrSingleDoc.id).RequestType__c);
                                                              String fileName = '';
                                                              if(ddrSingleDoc.DirectDebitBank__c == 'First Abu Dhabi Bank'){
                                                                  fileName = ddh.File_name_prefix__c+'-'+ddrSingleDoc.OIC__c+'-'+String.valueOf(Datetime.now().format('ddMMYY'))+'-'+allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingleDoc.Id).Id).Name.right(6)+'.pdf';
                                                              }else{
                                                                  if(ddrSingleDoc.CancelDirectDebitRequest__c){
                                                                      fileName= '003400'+allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingleDoc.Id).Id).Name.right(6)+String.valueOf(Datetime.now().format('YYMM'))+(cver != null? ('.'+cver.FileExtension): null);
                                                                  }else{
                                                                      fileName = Label.ADCB_BankRefNumber+allDDTRecordsMap.get(ddrDDTMapIds.get(ddrSingleDoc.Id).Id).Name.right(6)+String.valueOf(Datetime.now().format('YYMM'))+(cver != null? ('.'+cver.FileExtension): null);
                                                                  }
                                                              }
                                                              if(cver != null ){
                                                                  cvSinglePDF.Title = fileName;
                                                                  cvSinglePDF.PathOnClient = fileName;
                                                                  cvSinglePDF.VersionData = cver.VersionData;
                                                                  pdfFileByDDRId.put(ddrSingleDoc.Id, cvSinglePDF);
                                                                  ddrIdByPdfFileName.put(cvSinglePDF.Title, ddrSingleDoc.Id);
                                                              }
                                                          }
                                                      }
        }
        
        
        List<ContentVersion> cvPDFList			= new List<ContentVersion>();
        List<ContentDocumentLink> cdlPdFList	= new List<ContentDocumentLink>();
        if(pdfFileByDDRId.values().size() > 0) {
            cvPDFList = pdfFileByDDRId.Values();
            upsert cvPDFList;
            
            for(ContentVersion insertedPdfCv : [SELECT ContentDocumentId,title FROM ContentVersion WHERE Id IN :cvPDFList])  {
                System.debug('insertedPdfCv----'+insertedPdfCv.ContentDocumentId);
                ContentDocumentLink cdlPDF = New ContentDocumentLink();
                cdlPDF.LinkedEntityId = ddrDDTMapIds.get(ddrIdByPdfFileName.get(insertedPdfCv.title)).Id;
                cdlPDF.ContentDocumentId = insertedPdfCv.ContentDocumentId;
                cdlPDF.shareType = 'V';
                cdlPdFList.add(cdlPDF);
            }
        }
        
        //START of DML-2 Action
        if(cdlPdFList.size() > 0){
            //Database methods - partial update - if true then all records will fail
            // 									  if false then success records will be inserted
            Database.SaveResult[] srList1 = Database.insert(cdlPdFList, false); //DML_ACTION
            for (Database.SaveResult sr1 : srList1){
                if (sr1.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully inserted CDL for PDF file: ' + sr1.getId());
                } else {
                    for(Database.Error errDml2 : sr1.getErrors()) {
                        System.debug(errDml2.getStatusCode() + ': ' + errDml2.getMessage());
                        System.debug('CDL for signed PDFfilecreation fields that affected this error: ' + errDml2.getFields());
                        //Below logger accepts error,processName,className,methodName as parameters
                        LoggerService.save(LoggerService.createApexLog(errDml2,'DD-CreationOf_SignedPDFFile',ClassName,Method_prepareFileFromDDTBulkify));
                    }
                }
            }
        }
        //END of DML-2 Action
        //END - Getting the Image pdfc file and attach to DDTransaction record
        
        if(!ddtMapToUpdate.isEmpty()){
            Update ddtMapToUpdate.values();
        }
        
        
    }
}