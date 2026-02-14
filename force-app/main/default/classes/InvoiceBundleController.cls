/* this class is covered from InvoiceBundleServiceTest */
public with sharing class InvoiceBundleController {

    @AuraEnabled
    public static List<invoiceWrapper> getInvoiceBundles(Date startDate,Date endDate){
       List<invoiceWrapper> invoiceWrapperList = new List<invoiceWrapper>();
        string dateFilter='';
        if(startDate!=null){
           dateFilter = ' WHERE createdDate >= :startDate';
        }
        if(endDate!=null){
            endDate = endDate.addDays(1);
            dateFilter += ' AND createdDate <= :endDate';
        }
        //Below BankDetailsPresent__c,BankDetailsMissingFields__c is added by Tharun as per BPM-255
        string finalSOQL = 'SELECT VATDetailsMissing__c,BankDetailsPresent__c, BankDetailsMissingFields__c, ApprovalStatus__c,BrokerAgency__c,BundleName__c,BundleNumber__c,CreatedDate,Id,InvoiceDate__c,Name,Status__c,TotalCommissionLineItemCount__c,TotalNumberofCommission__c,SubmitforReview__c, (select ReviewComments__c,SubmitforReview__c,Id, InvoiceBundle__c, TotalExternalCommissionPercentage__c,CustomerName__c,InvoiceNumber__c,SalesOrder__c,BrokerAgency__c,BrokerAgency__r.Name,BrokerAgent__c,BrokerAgent__r.Name ,SalesOrder__r.SubStatus__c,SalesOrder__r.Status__c, SalesOrder__r.ProjectName__c,SalesOrder__r.Unit__c ,SalesOrder__r.Unit__r.Name, SalesOrder__r.Unit__r.TotalRooms__c,SalesOrder__r.NetAmount__c, OrderDate__c, CommissionAmount__c,CommissionPercentage__c, CommissionType__c, InstallmentLine__c,Status__c,InvoiceDate__c,PaymentDueDate__c,ClearedDate__c,InstalmentNumber__c,SalesOrder__r.Opportunity__c,SalesOrder__r.Opportunity__r.Contact__c,SalesOrder__r.Opportunity__r.Contact__r.Name,SalesOrder__r.Opportunity__r.AccountId,SalesOrder__r.Opportunity__r.Account.Name,CommissionAmountWithVAT__c,  InstallmentLine__r.OutstandingAmount__c,InstallmentLine__r.InstallmentAmount__c,InstallmentLine__r.InvoicedAmount__c from Commission_Line_Items__r where CommissionType__c = \''+ Constants.COMMISSION_LINE_EXTERNAL_COMMISSION +'\') FROM InvoiceBundle__c' + dateFilter+  ' ORDER BY CREATEDDATE DESC ';
        system.debug('finalSOQL::'+finalSOQL);
        system.debug('database.Query(finalSOQL)::'+database.Query(finalSOQL));
        List<InvoiceBundle__c> allInvoiceBundleList = database.Query(finalSOQL);
        //return database.Query(finalSOQL);
        // List<InvoiceBundle__c> allInvoiceBundleList = [SELECT ApprovalStatus__c,BrokerAgency__c,BundleName__c,BundleNumber__c,CreatedDate,Id,InvoiceDate__c,Name,Status__c,TotalCommissionLineItemCount__c,TotalNumberofCommission__c FROM InvoiceBundle__c]
        for(InvoiceBundle__c inv: allInvoiceBundleList){
           
                
            if(inv.Commission_Line_Items__r.size()>0){
                system.debug('inv.Name::'+inv.Name);
                invoiceWrapper wrap = new invoiceWrapper();
                string bckColor = '';
                if(inv.Status__c =='Not Ready'){
                    bckColor = 'NoColor';
                    wrap.enableActions = false;
                    wrap.disableManageInvoice = true;
                }else if(inv.Status__c == 'Ready for Submission'){
                    bckColor = 'LightRed';
                // Below Line for fixed is added by Tharun as per BPE-149
                }else if(inv.Status__c == 'Fixed'){
                    bckColor = 'LightRed';
                }else if(inv.Status__c =='Paid'){
                    bckColor = 'GreenColor';
                    wrap.enableActions = false;
                }else if(inv.Status__c =='Rejected'){
                    wrap.enableActions = false;
                    bckColor = 'RedColor';
                }else if(inv.Status__c =='Pending Finance Verification' || 
                         inv.Status__c =='Pending Invoice Verification' || 
                         inv.Status__c == 'Sent to Finance' || 
                         inv.Status__c == 'Invoice Approval In Progress' || 
                         inv.Status__c == 'Payment Approval In Progress' || 
                         inv.Status__c == 'Payment Under Bank Clearance'){
                    bckColor = 'BlueColor';
                    wrap.enableActions = false;
                }
                wrap.badgerBackgroundColor = bckColor;
                wrap.InvoiceBundle = inv;
                
             /*   Blob key = Blob.valueOf('1234567890123456');
                Blob data = Blob.valueOf(inv.Id);
                Blob encrypted = Crypto.encryptWithManagedIV('AES128', key, data);
                String encodedCipherText = EncodingUtil.base64Encode(encrypted);
                system.debug('encodedCipherText::'+encodedCipherText); */
                
                wrap.CypherInvoiceBundleId  = EncryptionUtils.encryptString(inv.Id); 
                system.debug('CypherInvoiceBundleId'+EncryptionUtils.encryptString(inv.Id));
                List<commissionWrapper> commissionWrapperList = new List<commissionWrapper>();
                for(CommissionLineItem__c cli : inv.Commission_Line_Items__r){
                    commissionWrapper cliWrap = new commissionWrapper ();
                    cliWrap.Customer = cli.CustomerName__c;
                    cliWrap.AgencyName = cli.BrokerAgency__r.Name;
                    cliWrap.AgentName = cli.BrokerAgent__r.Name;
                    cliWrap.Property = cli.SalesOrder__r.ProjectName__c;
                    cliWrap.UnitNumber = cli.SalesOrder__r.Unit__r.Name;
                    cliWrap.NetPrice = cli.SalesOrder__r.NetAmount__c;
                    cliWrap.OrderDate = cli.OrderDate__c;
                    cliWrap.Commission = cli.CommissionAmount__c;
                    cliWrap.invoiceBundleId = cli.InvoiceBundle__c; 
                    cliWrap.commissionId = cli.Id;
                    cliWrap.Rate = cli.TotalExternalCommissionPercentage__c != null ? ((cli.TotalExternalCommissionPercentage__c/100) *100)+'%' : '0';
                    cliWrap.Status = cli.Status__c;
                    cliWrap.SalesOrderStatus = cli.SalesOrder__r.Status__c;
                    cliWrap.SubmitforReview = cli.SubmitforReview__c;
                    cliWrap.ReviewComments = cli.ReviewComments__c;
                    cliWrap.disableSubmitForReview = cli.SubmitforReview__c ? true: false;
                    commissionWrapperList.add(cliWrap);
                }
                for(CommissionLineItem__c cli : inv.Commission_Line_Items__r){
                    if(cli.SubmitforReview__c){
                        wrap.enableActions = false;
                        break;
                    }
                }
                wrap.commissionLineItems = commissionWrapperList;
                invoiceWrapperList.add(wrap);
            }
            
        }
        system.debug('invoiceWrapperList:::'+invoiceWrapperList);
        return invoiceWrapperList;
    }
    @AuraEnabled
    public static void cliSubmitForReview(String mdl_commissionId, String mdl_ReviewComments, Boolean mdl_SubmitforReview){
        if(mdl_commissionId != null){
            CommissionLineItem__c cli = new CommissionLineItem__c();
            cli.Id = mdl_commissionId;
            cli.ReviewComments__c = mdl_ReviewComments;
            cli.SubmitforReview__c = mdl_SubmitforReview;
            update cli;
        }
    }
    
    @AuraEnabled
    public static void updateStatus(String recordId, String statusValue ,string comment ){
       system.debug('recordId::'+recordId);
        if(recordId.contains(' ')){
            recordId = recordId.replaceAll(' ', '+');
        }
        system.debug('Decrypted value::'+recordId);
        String invoiceId = EncryptionUtils.decryptString(recordId);
        
        
        InvoiceBundle__c invoiceBundle = new InvoiceBundle__c(id=invoiceId,status__c=statusValue, AgencyAdmin__c=userInfo.getUserId() ,OwnerID= userInfo.getUserId(), Comments__c = comment, SubmittedByAgencyDate__c = System.today());
        if(!Schema.sObjectType.InvoiceBundle__c.isUpdateable() ){ throw new CustomException(Constants.SOQL_DML_OBJECT_ACCESS_MESSAGE); }
        update invoiceBundle;
        if( statusValue == Constants.STATUS_REJECTED || statusValue == Constants.COMMISSION_LINE_STATUS_ACCEPTED){
            Map<id,InvoiceBundle__c> documentmap = new Map<id,InvoiceBundle__c>();
            documentmap.put(invoiceBundle.Id,invoiceBundle);
            generateInvoiceDocumentFromVF(documentmap);
        }
    }
    public static void generateInvoiceDocumentFromVF(Map<id,InvoiceBundle__c> invoiceBundleProcess){
        if(Test.isRunningTest()){
            invoiceBundleProcess = new Map<id,InvoiceBundle__c>([SELECT Id, Name, InvoiceDate__c  FROM InvoiceBundle__c WHERE Id IN :invoiceBundleProcess.keySet()]);  
        }else{
            invoiceBundleProcess = new Map<id,InvoiceBundle__c>([SELECT Id, Name, InvoiceDate__c  FROM InvoiceBundle__c WHERE Id IN :invoiceBundleProcess.keySet()  WITH SECURITY_ENFORCED]); 
        }
        Map<Id,ContentVersion> contentVersionMap = new Map<Id,ContentVersion>();
        Map<Id, Id> invoiceBundleToDoc = new Map<Id, Id>();
        Network network =  [SELECT Name, UrlPathPrefix, Id FROM Network WHERE Name = :Constants.URL_PREFIX];
        
        list<Document__c> placeholderList = [SELECT Id,InvoiceBundle__c FROM Document__c WHERE InvoiceBundle__c IN :invoiceBundleProcess.keySet()];
        if(placeholderList.isEmpty()){
            for(InvoiceBundle__c invBundle: invoiceBundleProcess.values()){
                placeholderList.add(new Document__c(DocumentType__c = 'Commission Invoice',
                                                    InvoiceBundle__c = invBundle.Id,
                                                    AvailableForExternalUsers__c = true,
                                                    RecordtypeId = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('SalesOrderDocument').getRecordTypeId() ));
            }
            insert placeholderList;
        }
            for(Document__c tempDoc : placeholderList){
                invoiceBundleToDoc.put(tempDoc.InvoiceBundle__c,tempDoc.id); 
                PageReference pdf = Page.BrokerInvoiceBundlePDF;
                string InvoiceId = EncryptionUtils.encryptString(tempDoc.InvoiceBundle__c);
                pdf.getParameters().put('invoiceId',InvoiceId);
                contentVersionMap.put(tempDoc.Id, new ContentVersion(Title= invoiceBundleProcess.get(tempDoc.InvoiceBundle__c).Name+'.pdf', 
                                                                     PathOnClient = invoiceBundleProcess.get(tempDoc.InvoiceBundle__c).Name+'.pdf',
                                                                     VersionData = Test.isRunningTest()? blob.valueOf('Methods defined as TestMethod do not support getContent call') :pdf.getContentAsPDF(), 
                                                                     origin = 'H',
                                                                     NetworkId = (UserInfo.getUserType() == 'PowerPartner' || UserInfo.getUserType() == 'Partner')? network.Id: null
                                                                    ));
            }
            
            if(!contentVersionMap.isEmpty()){
                insert contentVersionMap.values();
                list<ContentDistribution> cdistribution = new list<ContentDistribution>();
                for(Id ccR : contentVersionMap.keySet()){
                    cdistribution.add(ContentDocumentLinkTriggerHandler.createContentDistribution(contentVersionMap.get(ccR).Id,ccR));
                }
                insert cdistribution;
                
                Map<Id,Id> reverseMap = new Map<Id,Id>();
                for(Id docId : contentVersionMap.keySet()){
                    reverseMap.put(contentVersionMap.get(docId).id,docId);
                }
                list<ContentDocumentLink> documentLinksToCreate = new list<ContentDocumentLink>();
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
    
    @AuraEnabled
    public static string generateInvoiceDocument(String recordId){
        Map<id,InvoiceBundle__c> documentmap = new Map<id,InvoiceBundle__c>();
           
        List<InvoiceBundle__c> invoiceBundleList = [SELECT
                                                    Id,
                                                    Name,
                                                    InvoiceDate__c,
                                                    status__c,
                                                    AgencyAdmin__c,
                                                    OwnerId,
                                                    Comments__c,
                                                    SubmittedByAgencyDate__c
                                                    FROM InvoiceBundle__c 
                                                    WHERE Id =: recordId];
        
        for(InvoiceBundle__c invoiceBundle: invoiceBundleList){
            documentmap.put(invoiceBundle.Id,invoiceBundle);
        }
        if(documentmap.keySet().size()>0){
            generateInvoiceDocumentFromVF(documentmap);
        }
        return Constants.SUCCESS_MESSAGE;
    }
    
    @AuraEnabled
    public static String getCommissionTrail(String recordId){ 
        system.debug('recordId::'+recordId);
        if(recordId.contains(' ')){
            recordId = recordId.replaceAll(' ', '+');
        }
        system.debug('Decrypted value::'+recordId);
        String invoiceId = EncryptionUtils.decryptString(recordId);
        
        list<InvoiceBundle__c> records = [select CommentTrail__c from InvoiceBundle__c where id = :recordId];
        return records.isEmpty() ? '' : records[0].CommentTrail__c;
    }
    public class invoiceWrapper{
        @AuraEnabled public InvoiceBundle__c InvoiceBundle;
        @AuraEnabled public String CypherInvoiceBundleId;
        @AuraEnabled public List<commissionWrapper> commissionLineItems;
        @AuraEnabled public Boolean enableActions = true;
        @AuraEnabled public String badgerBackgroundColor;
        @AuraEnabled public Boolean disableManageInvoice = false;
        @AuraEnabled public Boolean isRejected = false;

    }
    public class commissionWrapper{
        @AuraEnabled public String Customer;
        @AuraEnabled public String AgencyName;
        @AuraEnabled public String AgentName;
        @AuraEnabled public String Property; 
        @AuraEnabled public String UnitNumber;
        @AuraEnabled public Decimal NetPrice;
        @AuraEnabled public Date OrderDate;
        @AuraEnabled public Decimal Commission;
        @AuraEnabled public String Rate;
        @AuraEnabled public String Status;
        @AuraEnabled public String SalesOrderStatus;
        @AuraEnabled public String invoiceBundleId;
        @AuraEnabled public String commissionId;
        @AuraEnabled public String ReviewComments;
        @AuraEnabled public Boolean SubmitforReview;
        @AuraEnabled public Boolean disableSubmitForReview;
    }
    
}