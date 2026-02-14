@RestResource (urlMapping = '/get/opportunityEOI')
global class EOIDetailWebService {
    @HTTPPost
    global static void doPost(Id opportunityId){
        
        RestContextHandler handler = new RestContextHandler(true);
        EOIModel eoiData = new EOIModel();
        try {
            
            List<OpportunityEOI__c> opportunityEOIRecords = OpportunityEOIService.queryAllFieldsWithExtraFields(new List<Id>{opportunityId});
            //if(opportunityEOIRecords.size()>0){
            
                OpportunityEOI__c eoiRecord = opportunityEOIRecords[0];
                eoiData.opportunityEOIRecordDetail = eoiRecord;

                eoiData.opportunityEOInformation.add(new OpportunityEOIRecord('Sequence Number',eoiRecord.Name));
                eoiData.opportunityEOInformation.add(new OpportunityEOIRecord('Compliance Status',eoiRecord.ComplianceStatus__c));
                eoiData.opportunityEOInformation.add(new OpportunityEOIRecord('Status',eoiRecord.Status__c));
                eoiData.opportunityEOInformation.add(new OpportunityEOIRecord('Allotted Unit',eoiRecord.AllottedUnit__c));

                eoiData.unitDetails.add(new OpportunityEOIRecord('Project Name',eoiRecord.ProjectNameFormula__c));
                eoiData.unitDetails.add(new OpportunityEOIRecord('Building/Section Name',eoiRecord.BuildingNameFormula__c));
                eoiData.unitDetails.add(new OpportunityEOIRecord('Unit Type',eoiRecord.UnitType__c));
                eoiData.unitDetails.add(new OpportunityEOIRecord('Unit Model',eoiRecord.UnitModel__c));
                eoiData.unitDetails.add(new OpportunityEOIRecord('Unit Features',eoiRecord.UnitFeatures__c));
                eoiData.unitDetails.add(new OpportunityEOIRecord('Customer Preference',eoiRecord.CustomerPreference__c));


                eoiData.paymentInformation.add(new OpportunityEOIRecord('Price Range From',String.valueOf(eoiRecord.PriceRangeFrom__c) != null ? String.valueOf(eoiRecord.PriceRangeFrom__c.format()) + ' ' + eoiRecord.CurrencyIsoCode : String.valueOf(eoiRecord.PriceRangeFrom__c)));
                eoiData.paymentInformation.add(new OpportunityEOIRecord('Price Range To',String.valueOf(eoiRecord.PriceRangeTo__c) != null ? String.valueOf(eoiRecord.PriceRangeTo__c.format()) + ' ' + eoiRecord.CurrencyIsoCode : String.valueOf(eoiRecord.PriceRangeTo__c)));
                eoiData.paymentInformation.add(new OpportunityEOIRecord('Interest Fee',String.valueOf(eoiRecord.InterestFee__c) != null ? String.valueOf(eoiRecord.InterestFee__c.format()) + ' ' + eoiRecord.CurrencyIsoCode : String.valueOf(eoiRecord.InterestFee__c)));
                eoiData.paymentInformation.add(new OpportunityEOIRecord('Payment Mode',eoiRecord.PaymentMode__c));
                eoiData.paymentInformation.add(new OpportunityEOIRecord('Remarks',eoiRecord.Remarks__c));
                eoiData.paymentInformation.add(new OpportunityEOIRecord('Number of Units',String.valueOf(eoiRecord.NumberOfUnits__c)));


                Schema.DescribeFieldResult fieldResult = OpportunityEOI__c.Status__c.getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                
                for( Schema.PicklistEntry pickListVal : ple){
                    eoiData.statusValues.add(pickListVal.getLabel());
                }
                
                if(eoiRecord.ComplianceStatus__c == Constants.RECEIPT_STATUS_CLEARED && eoiRecord.AllottedUnit__c != null && eoiRecord.Status__c != Constants.EOISTATUS_UNITCONFIRMED && eoiRecord.Status__c != Constants.EOI_PAID && String.isNotBlank(eoiRecord.AllottedUnit__c))
                    eoiData.isStatusUpdatable = true;
                
                Map<Id,Document__c> documentDetailMap = new Map<Id,Document__c> (eoiRecord.DocumentsExpressionofInterest__r);
                Map<Id,DocumentQueryModel> documentData = new Map<Id,DocumentQueryModel>();
                
                if(documentDetailMap != null && !documentDetailMap.isEmpty())
                    documentData =  DocumentService.getDocumentDetails(documentDetailMap);
                
                eoiData.documents = documentData.values();  
                
                for(ReceiptAcknowledgement__c receipts : eoiRecord.Payments__r)
                {
                    ReceiptDetails receiptDetail = new ReceiptDetails();
                    receiptDetail.receiptRecord = receipts;
                    
                    if(receipts.PaymentType__c != Constants.ONLINE)
                        receiptDetail.isReceiptUpdatable = true;
                    
                    eoiData.receipts.add(receiptDetail); 
                }
            //}
            handler.response.success = true;
            handler.response.data = eoiData; 
            handler.finalize();            
        } 
        catch (Exception e) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(e);            
        }
    }
    
    global class EOIModel
    {
        public OpportunityEOI__c opportunityEOIRecordDetail             {get;set;}
        public List<OpportunityEOIRecord> opportunityEOInformation      {get;set;}
        public List<OpportunityEOIRecord> unitDetails                   {get;set;}
        public List<OpportunityEOIRecord> paymentInformation            {get;set;}
        public Boolean isStatusUpdatable                                {get;set;}
        public List<String> statusValues                                {get;set;}
        public List<DocumentQueryModel> documents                       {get;set;} 
        public List<ReceiptDetails> receipts                            {get;set;}   
        
        public EOIModel()
        {
            this.opportunityEOIRecordDetail = new OpportunityEOI__c();
            this.opportunityEOInformation = new List<OpportunityEOIRecord>();
            this.unitDetails = new List<OpportunityEOIRecord>();
            this.paymentInformation = new List<OpportunityEOIRecord>();
            this.isStatusUpdatable = false;
            this.statusValues = new List<String>();
            this.documents = new List<DocumentQueryModel>();
            this.receipts = new List<ReceiptDetails>();
        }
    }
    
    global class OpportunityEOIRecord {
        public String label     {get;set;}
        public Object value     {get;set;}
        
        public OpportunityEOIRecord(String label, Object value) {
            this.label = label;
            this.value = value;
        }
    }
    
    global class ReceiptDetails{
        public ReceiptAcknowledgement__c receiptRecord     {get;set;}
        public Boolean isReceiptUpdatable                  {get;set;}
        
        public ReceiptDetails()
        {
            this.receiptRecord = new ReceiptAcknowledgement__c();
            this.isReceiptUpdatable = false;
        }
    }
}