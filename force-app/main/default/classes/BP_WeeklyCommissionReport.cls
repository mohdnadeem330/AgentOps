@RestResource (urlMapping = '/getWeeklyCommissionReport')
global without sharing class BP_WeeklyCommissionReport extends BP_BaseRestResource{
    @HttpPost
    global static void excute(){ 
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, String> params = RestContext.request.params;
            String requestBody = RestContext.request.requestBody.toString();
            
            System.debug('requestBody '+requestBody);
            if(!String.isEmpty(requestBody)){   
                BP_WeeklyCommissionReport service = new BP_WeeklyCommissionReport();
                ApiResponse response = service.processRequest(params, requestBody);
                handler.response.data = response.data;
                handler.response.success = true;
                handler.response.statusCode = response.statusCode;
                handler.response.message = response.message;
            } else{
                handler.response.success = false;
                handler.response.statusCode = 500;
                handler.response.message = 'Invalid Request Body';
            }
        } catch(Exception ex){
            handler.response.success = false;
            handler.response.statusCode = 500;
            handler.response.message = ex.getMessage();
        }
        handler.finalize();
    }
    
    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try {
            WeeklyCommissionWrapper requestWrapper = (WeeklyCommissionWrapper) JSON.deserialize(requestBody, WeeklyCommissionWrapper.class);
            return new ApiResponse(true, 200,'Weekly Commission Report is fetched', getInvoiceBundles(requestWrapper.agencyId,
                                                                                                      requestWrapper.startDate, 
                                                                                                      requestWrapper.endDate, 
                                                                                                      requestWrapper.status, 
                                                                                                      requestWrapper.searchKey,  
                                                                                                      requestWrapper.limits, 
                                                                                                      requestWrapper.offsets)); 
        } catch (Exception e) {
            return new ApiResponse(false, 500,'Failed to load Weekly Commission Report: ' + e.getMessage(), null);
        }
    }
    
    public class WeeklyCommissionWrapper{
        public String agencyId;
        public Date startDate;
        public Date endDate;
        public String status;
        public String searchKey;
        public Integer limits;
        public Integer offsets;
        
        public WeeklyCommissionWrapper(){}
    }
    
    public static ResponseWrapper getInvoiceBundles(String agencyId, Date startDate, Date endDate, String status, String searchKey, Integer limits, Integer offsets){
        Set<Id> SalesOderIdSet = new Set<Id>();
        Set<Id> invoiceBundleIdSet = new Set<Id>();
        Map<String, Integer> SOPaidCommissionMap = new Map<String, Integer>();
        Map<String, List<CommissionWrapper>> invoiceCommissionWrapperMap = new Map<String, List<CommissionWrapper>>();
        List<invoiceWrapper> invoiceWrapperList = new List<invoiceWrapper>();
        Decimal VAT = 0;
        for(Constant__mdt tempRec : [select id, ConstantValue__c from Constant__mdt where DeveloperName=:Constants.VAT]){
            VAT=Integer.valueOf(tempRec.ConstantValue__c);
        }
        string dateFilter='';
        if(startDate!=null){
            dateFilter = ' AND createdDate >= :startDate';
        }
        if(endDate!=null){
            endDate = endDate.addDays(1);
            dateFilter += ' AND createdDate <= :endDate';
        }
        
        String soql = 'SELECT BankDetailsPresent__c, BankDetailsMissingFields__c, VATDetailsMissing__c, ApprovalStatus__c,BrokerAgency__c,BundleName__c,'+
            'BundleNumber__c,CreatedDate,Id,InvoiceDate__c,Name,Status__c,TotalCommissionLineItemCount__c,TotalNumberofCommission__c,'+
            'SubmitforReview__c,'+
            'BrokerAgency__r.Name,BrokerAgency__r.ProposedBankDetailStatus__c, BrokerAgency__r.UAEVATRegisterNumber__c,BrokerAgency__r.BillingStreet, BrokerAgency__r.BillingCity, BrokerAgency__r.BillingState, BrokerAgency__r.BillingCountry, BrokerAgency__r.BillingPostalCode '+
            ' FROM InvoiceBundle__c WHERE BrokerAgency__c = :agencyId ' + 
            dateFilter;
        
        
        
        String filter = '';
        if(status != null && String.isNotBlank(status)){
            filter = ' AND Status__c =: status ';
        }
        if(searchKey != null && String.isNotBlank(searchKey)){
            String searchKeyLike = '%'+searchKey+'%';
            filter += ' AND Name LIKE :searchKeyLike ' ;
        }
        
        String offSetLimit = '';
        if(limits != null){
            offSetLimit += ' LIMIT :limits ';
        }
        if(offsets != null){
            offSetLimit += ' OffSet :offsets ';
        }
        
        String finalSOQL = soql + filter;
        String finalSOQLWithOffSet = soql + filter + offSetLimit;
        System.debug('finalSOQL :::'+finalSOQL);   
        System.debug('finalSOQLWithOffSet:::'+finalSOQLWithOffSet);        

        List<InvoiceBundle__c> allInvoiceBundleTotal = database.Query(finalSOQL);
        List<InvoiceBundle__c> allInvoiceBundleList = database.Query(finalSOQLWithOffSet);
        
        
        System.debug('allInvoiceBundleList:::'+allInvoiceBundleList);
      
        
        Set<Id> invoiceBundleIds = new Set<Id>();

        // Collect InvoiceBundle__c IDs
        for (InvoiceBundle__c inv : allInvoiceBundleList) {
            invoiceBundleIds.add(inv.Id);
        }

        System.debug('invoiceBundleIds:::' + invoiceBundleIds);
        
        // Declare the map at the beginning
        Map<Id, String> invoiceDocumentBase64Map = new Map<Id, String>();
        
        if (!invoiceBundleIds.isEmpty()) {
            // Get Document__c records linked to InvoiceBundle__c
            List<Document__c> documentList = [SELECT Id, InvoiceBundle__c FROM Document__c WHERE InvoiceBundle__c IN :invoiceBundleIds AND DocumentType__c = 'Commission Invoice' order by createddate desc];
            
            Map<Id, Id> documentToInvoiceMap = new Map<Id, Id>();
            Set<Id> documentIds = new Set<Id>();
            
            for (Document__c doc : documentList) {
                documentIds.add(doc.Id);
                documentToInvoiceMap.put(doc.Id, doc.InvoiceBundle__c);
            }
            
            System.debug('documentToInvoiceMap: ' + documentToInvoiceMap);
            
            if (!documentIds.isEmpty()) {
                // Get ContentDocumentLink records (Fixed SOQL restriction)
                List<ContentDocumentLink> documentLinks = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :documentIds];
                
                Map<Id, Id> contentDocumentToDocumentMap = new Map<Id, Id>();
                Set<Id> contentDocumentIds = new Set<Id>();
                
                for (ContentDocumentLink link : documentLinks) {
                    contentDocumentIds.add(link.ContentDocumentId);
                    contentDocumentToDocumentMap.put(link.ContentDocumentId, link.LinkedEntityId);
                }
                
                System.debug('contentDocumentToDocumentMap: ' + contentDocumentToDocumentMap);
                
                if (!contentDocumentIds.isEmpty()) {
                    // Get latest ContentVersion records
                    List<ContentVersion> contentVersionList = [SELECT Id, ContentDocumentId, VersionData 
                                                               FROM ContentVersion 
                                                               WHERE ContentDocumentId IN :contentDocumentIds 
                                                               ORDER BY CreatedDate DESC LIMIT 1];
                    
                    for (ContentVersion cv : contentVersionList) {
                        Id documentId = contentDocumentToDocumentMap.get(cv.ContentDocumentId);
                        Id invoiceId = documentToInvoiceMap.get(documentId);
                        
                        if (invoiceId != null) {
                            invoiceDocumentBase64Map.put(invoiceId, EncodingUtil.base64Encode(cv.VersionData));
                        }
                    }
                    
                    System.debug('invoiceDocumentBase64Map: ' + invoiceDocumentBase64Map);
                }
            }
        }
        
        String commissionLineItemSOQL = 'SELECT ReviewComments__c,SubmitforReview__c,Id, InvoiceBundle__c, TotalExternalCommissionPercentage__c,CustomerName__c,'+
            'InvoiceNumber__c,SalesOrder__c,BrokerAgency__c,BrokerAgency__r.Name,BrokerAgent__c,BrokerAgent__r.Name ,'+
            'SalesOrder__r.SubStatus__c,SalesOrder__r.Status__c, SalesOrder__r.ProjectName__c,SalesOrder__r.Unit__c ,'+
            'SalesOrder__r.Unit__r.Name, SalesOrder__r.Unit__r.TotalRooms__c,SalesOrder__r.NetAmount__c, OrderDate__c,'+
            'CommissionAmount__c,CommissionPercentage__c, CommissionType__c, InstallmentLine__c,Status__c,InvoiceDate__c,'+
            'PaymentDueDate__c,ClearedDate__c,InstalmentNumber__c,SalesOrder__r.Opportunity__c,SalesOrder__r.Opportunity__r.Contact__c,'+
            'SalesOrder__r.Opportunity__r.Contact__r.Name,SalesOrder__r.Opportunity__r.AccountId,SalesOrder__r.Opportunity__r.Account.Name,'+
            'CommissionAmountWithVAT__c,InstallmentLine__r.OutstandingAmount__c,InstallmentLine__r.InstallmentAmount__c,'+
            'Unit__r.Project__r.Broker_invoice_TRN_Number__c, Unit__r.Project__r.Broker_invoice_Bill_To_Address_1__c, Unit__r.Project__r.Broker_invoice_Bill_To_Address_2__c,'+ 
            'Unit__r.Project__r.Broker_invoice_Bill_To_Address_3__c,Unit__r.Project__r.Description__c,Unit__r.Project__r.Broker_invoice_Bill_To_Name__c,'+
            'InstallmentLine__r.InvoicedAmount__c, SalesOrder__r.ExternalCommissionAmount__c, BrokerAgency__r.UAEVATRegisterNumber__c FROM CommissionLineItem__c WHERE '+
            'CommissionType__c = \''+ Constants.COMMISSION_LINE_EXTERNAL_COMMISSION +'\' AND InvoiceBundle__c IN: allInvoiceBundleList ' ;
        system.debug('Unit records '+ commissionLineItemSOQL);
        List<CommissionLineItem__c> commissionLineItemList = database.Query(commissionLineItemSOQL); 
        for(CommissionLineItem__c commissionLineItem: commissionLineItemList){
            SalesOderIdSet.add(commissionLineItem.SalesOrder__c);
        }
        
        List<AggregateResult> groupResult = [Select SalesOrder__c soId,
                                             SUM(CommissionAmount__c)commissionAmount FROM 
                                             CommissionLineItem__c 
                                             WHERE SalesOrder__c IN: SalesOderIdSet 
                                             AND Status__c = 'Paid'
                                             AND Id NOT in: commissionLineItemList 
                                             AND CommissionType__c = 'External' GROUP BY SalesOrder__c];
        for(AggregateResult ar: groupResult){
            SOPaidCommissionMap.put(String.valueOf(ar.get('soId')),Integer.valueOf(ar.get('commissionAmount')));
        }
        for(CommissionLineItem__c commissionRecord: commissionLineItemList){
          
            CommissionWrapper wrap = new CommissionWrapper();
            wrap.commissionLineItem = commissionRecord;
            wrap.UnitName = commissionRecord.SalesOrder__r.Unit__r.Name;
            wrap.Property = commissionRecord.SalesOrder__r.ProjectName__c;
            wrap.CustomerName = commissionRecord.SalesOrder__r.Opportunity__r.Account.Name;
            wrap.PurchasePrice = commissionRecord.SalesOrder__r.NetAmount__c;
            wrap.TotalCommission = commissionRecord.SalesOrder__r.ExternalCommissionAmount__c;
            wrap.TotalRate = (commissionRecord.SalesOrder__r.ExternalCommissionAmount__c*100/commissionRecord.SalesOrder__r.NetAmount__c);
            wrap.InvoiceRate = (commissionRecord.CommissionAmount__c*100/commissionRecord.SalesOrder__r.NetAmount__c);
            wrap.PaidAmount = SOPaidCommissionMap.get(commissionRecord.SalesOrder__c) != null ? SOPaidCommissionMap.get(commissionRecord.SalesOrder__c) : 0;
            wrap.CommissionAmount = commissionRecord.CommissionAmount__c;
            wrap.OrderDate = commissionRecord.OrderDate__c;
            if(commissionRecord.BrokerAgency__r.UAEVATRegisterNumber__c != null){
                wrap.VATPercentage =  VAT;
                wrap.VATAmount =  (wrap.CommissionAmount*VAT/100);
            }
            List<CommissionWrapper> commissionwrapList  = invoiceCommissionWrapperMap.get(commissionRecord.InvoiceBundle__c) != null ? invoiceCommissionWrapperMap.get(commissionRecord.InvoiceBundle__c) : new List<CommissionWrapper>();
            commissionwrapList.add(wrap);
            invoiceCommissionWrapperMap.put(commissionRecord.InvoiceBundle__c, commissionwrapList);
        }
        
        
        List<invoiceWrapper> allInvoiceWrapperList = new List<invoiceWrapper>(); // Wrap for all records (no conditions)
        //List<invoiceWrapper> invoiceWrapperList = new List<invoiceWrapper>();    // Wrap only those meeting conditions
        
        for (InvoiceBundle__c inv : allInvoiceBundleList) {
            system.debug('main record count: ' + allInvoiceBundleList.size());
            
            invoiceWrapper fullWrap = new invoiceWrapper(); // For all records
            fullWrap.InvoiceBundle = inv;
            fullWrap.invoiceDownloadableDocument = invoiceDocumentBase64Map.get(inv.Id);
            fullWrap.Description = 'Sales Commission';
            fullWrap.commissionList = invoiceCommissionWrapperMap.get(inv.id);
            allInvoiceWrapperList.add(fullWrap); // Always add to the complete list
            System.debug('InvoiceBundle__c ' + inv);
            // Add to filtered list only if it has commission data
            if (invoiceCommissionWrapperMap.containsKey(inv.id)) {
                invoiceWrapper wrap = new invoiceWrapper();
                wrap.InvoiceBundle = inv;
                wrap.invoiceDownloadableDocument = invoiceDocumentBase64Map.get(inv.Id);
                
                if (inv.Status__c == 'Not Ready') {
                    wrap.enableActions = false;
                    wrap.disableManageInvoice = true;
                } else if (inv.Status__c == 'Paid') {
                    wrap.enableActions = false;
                } else if (inv.Status__c == 'Rejected') {
                    wrap.enableActions = false;
                    wrap.isRejected = true;
                } else if (
                    inv.Status__c == 'Pending Finance Verification' || 
                    inv.Status__c == 'Pending Invoice Verification' || 
                    inv.Status__c == 'Sent to Finance' || 
                    inv.Status__c == 'Invoice Approval In Progress' || 
                    inv.Status__c == 'Payment Approval In Progress' || 
                    inv.Status__c == 'Payment Under Bank Clearance'
                ) {
                    wrap.enableActions = false;
                }
                
                wrap.Description = 'Sales Commission';
                wrap.commissionList = invoiceCommissionWrapperMap.get(inv.id);
                
                invoiceWrapperList.add(wrap); 
            }
        }
        
        ResponseWrapper responseWrap = new ResponseWrapper();
        responseWrap.totalRecordCount = allInvoiceBundleList != null ? allInvoiceBundleList.size() : 0;
        responseWrap.invoiceBundle = allInvoiceWrapperList;         
        //responseWrap.allInvoiceBundle = allInvoiceWrapperList;   
        
        
        return responseWrap;
    }
    
    
    public class ResponseWrapper{
        public Integer totalRecordCount = 0;
        public List<invoiceWrapper> invoiceBundle;
        
        //public List<invoiceWrapper> allInvoiceBundle; // <-- Add this if not already declared
        
    }
    
    public class invoiceWrapper{
        public InvoiceBundle__c InvoiceBundle;
        public Boolean enableActions = true;
        public Boolean disableManageInvoice = false;
        public Boolean isRejected = false;
        public List<CommissionWrapper> commissionList;
        public String Description; 
        public String invoiceDownloadableDocument;
    }
    
    public class CommissionWrapper {
        public CommissionLineItem__c commissionLineItem;
        public String CustomerName;
        public Decimal PurchasePrice;
        public Decimal TotalCommission;
        public Decimal TotalRate;
        public Decimal InvoiceRate;
        public Decimal PaidAmount;
        public Decimal CommissionAmount; 
        public String UnitName;
        public String Property;
        public Date OrderDate;
        public Decimal VATPercentage;
        Public Decimal VATAmount;
    }
    
}