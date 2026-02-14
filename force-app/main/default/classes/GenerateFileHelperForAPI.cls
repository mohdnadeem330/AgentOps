/*This class is to append the DD form from DDR to DDT */
public class GenerateFileHelperForAPI {
    public static String SignedDirectDebitRegistrationForm = 'Signed direct debit registration form';
    public static String SignedDirectDebitCancellationForm = 'Signed Direct Debit Cancellation form';
    public static String NewRegistration                   = 'New Registration';
    public static String Cancellation                      = 'Cancellation';
    public static String Collection                        = 'Collection';
    public static List<String> SignedDirectDebitFormList = new List<String>{SignedDirectDebitRegistrationForm, SignedDirectDebitCancellationForm};
        
        public static void appendDDRFormToDDT(Map<Id, DDTransaction__c> DDTransactionMap){
            
            List<ContentDocumentLink> contentDocumentLinks			= new List<ContentDocumentLink>();
            List<ContentVersion> cvPDFList			                = new List<ContentVersion>();
            List<ContentDocumentLink> cdlPdFList	                = new List<ContentDocumentLink>();
            Map<String, Map<Id, Id>> ddrRequestDocumentMap          = new Map<String, Map<Id, Id>>();
            Map<Id, Id> ddrDocumentMap								= new Map<Id, Id>();
            Map<Id, Id> documentContentLinkMap						= new Map<Id, Id>();
            Map<Id, ContentVersion> ContentLinkContentVersionMap 	= new Map<Id, ContentVersion>();
            Set<Id> signedDocumentsSetIds 							= new Set<Id>();
            Map<Id, ContentVersion> pdfFileByDDRId 					= new Map<Id, ContentVersion>();
            Map<String, Id> ddrIdByPdfFileName 						= new Map<String, Id>();
            Set<Id>	directDebitRequestIdSet							= new Set<Id>();
            
            List<DirectDebitRequest__c> directDebitRequestList = [SELECT Id,Name, SalesOrder__r.Unit__r.Project__r.BankNameEscrow__c,  DirectDebitBank__c,
                                                                  RequestType__c,CancelDirectDebitRequest__c, OIC__c, 
                                                                  (SELECT ID, DocumentType__c FROM Documents__r
                                                                   WHERE DocumentType__c IN: SignedDirectDebitFormList)
                                                                  FROM DirectDebitRequest__c
                                                                  WHERE ID IN: DDTransactionMap.keySet()];
            
            
            for(DirectDebitRequest__c directDebit: directDebitRequestList){
                
                if(DDTransactionMap.get(directDebit.Id).RequestType__c != Collection){
                    
                    for(Document__c document : directDebit.Documents__r){
                        Map<Id, Id> finalddrDocumentMap = ddrRequestDocumentMap.get(DDTransactionMap.get(directDebit.Id).RequestType__c) != null ? ddrRequestDocumentMap.get(DDTransactionMap.get(directDebit.Id).RequestType__c) : new Map<Id, Id>();
                        signedDocumentsSetIds.add(document.Id);
                        ddrDocumentMap.put(directDebit.Id, document.Id);
                        if(document.DocumentType__c == SignedDirectDebitCancellationForm && DDTransactionMap.get(directDebit.id).RequestType__c == Cancellation){
                            finalddrDocumentMap.put(directDebit.Id, document.Id);
                            ddrRequestDocumentMap.put(Cancellation, finalddrDocumentMap);  
                        }else if(document.DocumentType__c == SignedDirectDebitRegistrationForm && DDTransactionMap.get(directDebit.id).RequestType__c == NewRegistration){
                            finalddrDocumentMap.put(directDebit.Id, document.Id);
                            ddrRequestDocumentMap.put(NewRegistration, finalddrDocumentMap);  
                        }
                    }
                }
            }
            
            if(signedDocumentsSetIds.size() > 0){
                contentDocumentLinks = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :signedDocumentsSetIds];
            }
           
            if (contentDocumentLinks.size() > 0) {
                List<Id> contentDocumentLinkIds = new List<Id>();
                for (ContentDocumentLink contentDocumentLink : contentDocumentLinks ){
                    contentDocumentLinkIds.add(contentDocumentLink.ContentDocumentId);
                    documentContentLinkMap.put(contentDocumentLink.LinkedEntityId, contentDocumentLink.ContentDocumentId);
                }
                List<ContentVersion> contentVersions = [SELECT Id,ContentDocumentId,Title,VersionData,isLatest,FileExtension FROM ContentVersion 
                                                        WHERE ContentDocumentId IN :contentDocumentLinkIds 
                                                        AND IsLatest = true];             
                
                for(ContentVersion conVersion:contentVersions) {
                    ContentLinkContentVersionMap.put(conVersion.ContentDocumentId, conVersion);
                }
                
                for(DirectDebitRequest__c directDebitRequest: directDebitRequestList){
                    if (contentVersions.size() > 0) {
                        Map<Id, Id> finalddrDocumentMap = ddrRequestDocumentMap.get(DDTransactionMap.get(directDebitRequest.id).RequestType__c);
                        ContentVersion contentVersion = ContentLinkContentVersionMap.get(documentContentLinkMap.get(finalddrDocumentMap.get(directDebitRequest.id)));
                        
                        ContentVersion cvSinglePDF = new ContentVersion();
                        cvSinglePDF.ContentLocation = 'S';
                        
                        String fileName = '';
                        
                        if(directDebitRequest.CancelDirectDebitRequest__c){
                            fileName= '003400'+DDTransactionMap.get(directDebitRequest.Id).Name.right(6)+String.valueOf(Datetime.now().format('YYMM'))+(contentVersion != null? ('.'+contentVersion.FileExtension): null);
                        }else{
                            if(contentVersion.FileExtension != 'pdf'){
                                fileName = Label.ADCB_BankRefNumber+DDTransactionMap.get(directDebitRequest.Id).Name.right(6)+String.valueOf(Datetime.now().format('YYMM'))+(contentVersion != null ? ('.'+contentVersion.FileExtension): null);
                            }else{
                                fileName = DDTransactionMap.get(directDebitRequest.Id).DDAFileName__c;
                            }
                        }
                        
                        
                        if(contentVersion != null ){
                            cvSinglePDF.Title = fileName;
                            cvSinglePDF.PathOnClient = fileName;
                            cvSinglePDF.VersionData = contentVersion.VersionData;
                            pdfFileByDDRId.put(directDebitRequest.Id, cvSinglePDF);
                            ddrIdByPdfFileName.put(cvSinglePDF.Title, directDebitRequest.Id);
                        }
                    }
                }
            }
            
            if(pdfFileByDDRId.values().size() > 0) {
                cvPDFList = pdfFileByDDRId.Values();
                upsert cvPDFList;
                
                for(ContentVersion insertedPdfCv : [SELECT ContentDocumentId,title FROM ContentVersion WHERE Id IN :cvPDFList])  {
                    ContentDocumentLink cdlPDF = New ContentDocumentLink();
                    cdlPDF.LinkedEntityId = DDTransactionMap.get(ddrIdByPdfFileName.get(insertedPdfCv.title)).Id;
                    cdlPDF.ContentDocumentId = insertedPdfCv.ContentDocumentId;
                    cdlPDF.shareType = 'V';
                    cdlPdFList.add(cdlPDF);
                }
            }
            if(cdlPdFList.size() > 0){
                Database.SaveResult[] srList1 = Database.insert(cdlPdFList, false);
                for (Database.SaveResult sr1 : srList1){
                    if (sr1.isSuccess()) {
                        System.debug('Successfully inserted CDL for PDF file: ' + sr1.getId());
                    } else {
                        for(Database.Error errDml2 : sr1.getErrors()) {
                            LoggerService.save(LoggerService.createApexLog(errDml2,'DD-CreationOf_SignedPDFFile','GenerateFileHelperForAPI','appendDDRFormToDDT'));
                        }
                    }
                }
            }
        }    
}