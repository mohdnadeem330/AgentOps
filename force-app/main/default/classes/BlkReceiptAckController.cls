@RestResource (urlMapping = '/update/ReceiptAck')
global without sharing class BlkReceiptAckController {
    
    public static Boolean isBlkReceiptAckAPI=false;
        
    global class ReceiptAckRequestWrapper{
        public String sfId{get;set;}
        public String statusReason{get;set;}
        public String status{get;set;}
        public String eRPID{get;set;}
        public String amount{get;set;}
        public String receiptNumber{get;set;}
        public String receiptDate{get;set;}
        public String clearedDate{get;set;}
        public String paymentSubType{get;set;} 
        public String remittanceChequeDate{get;set;}
        public String custAccountNum{get;set;}
        public String recBankAccount{get;set;}
        public String glDate{get;set;}
        public String createdBy{get;set;}
    }
      
    global class RequestWrapper{
        public List<ReceiptAckRequestWrapper> receipts{get;set;}
    }
     
    global class ReceiptAckResponseWrapper {
        public String id{get;set;}
        public Boolean success{get;set;}
        public List<Error> errors{get;set;}           
    }
    
    global class Error {
        public String statusCode{get;set;}
        public String message{get;set;}
        public List<Fields> fields{get;set;}
               
    }
    
     global class Fields {
        public String fieldName{get;set;}              
    }
      
    @HttpPost
    global static  List<ReceiptAckResponseWrapper> doPost() { 
        List<ReceiptAckResponseWrapper> responseWrapperList = new  List<ReceiptAckResponseWrapper>();
        try{
        RestContextHandler handler = new RestContextHandler(true);
        String jsonDataStr = handler.getRequestBody();
        System.debug('jsonReqDataStr***:: '+jsonDataStr);
        RequestWrapper reqWrapper = (RequestWrapper)JSON.deserializeStrict(jsonDataStr, RequestWrapper.class);
        List<ReceiptAckRequestWrapper> receiptDetails=reqWrapper.receipts;
        List<ReceiptAcknowledgement__c> updateReceiptsList=new List<ReceiptAcknowledgement__c>();
		Set<Id> receiptIdSet = new Set<Id>();
        for(ReceiptAckRequestWrapper requestWrapper:receiptDetails){
            receiptIdSet.add(requestWrapper.sfId);
        }
//        Map<Id,ReceiptAcknowledgement__c> receiptMap = new Map<Id,ReceiptAcknowledgement__c>{[SELECT Id,isValidationBypass__c FROM ReceiptAcknowledgement__c WHERE Id IN: receiptIdSet ]);
        for(ReceiptAckRequestWrapper requestWrapper:receiptDetails){
            ReceiptAcknowledgement__c updateReceipt=new ReceiptAcknowledgement__c();
                updateReceipt.Id=requestWrapper.sfId;
                if(requestWrapper.statusReason!=null){
                  updateReceipt.StatusReason__c=requestWrapper.statusReason;
                }
                if(requestWrapper.status!=null){
                updateReceipt.Status__c=requestWrapper.status;
                }
                if(requestWrapper.eRPID!=null){
                   updateReceipt.ERPID__c=requestWrapper.eRPID;
                 }
                if(requestWrapper.amount!=null){
                  updateReceipt.Amount__c=Decimal.valueOf(requestWrapper.amount);   
                }
                system.debug('requestWrapper.receiptDate::'+requestWrapper.receiptDate);
                if(requestWrapper.receiptDate!=null && requestWrapper.receiptDate!=''){
                   updateReceipt.ReceiptDate__c=Date.valueOf(requestWrapper.receiptDate);  
                }
                if(requestWrapper.clearedDate!=null && requestWrapper.clearedDate!= ''){
                    updateReceipt.ClearedDate__c=Date.valueOf(requestWrapper.clearedDate); 
                }
                if(requestWrapper.receiptNumber!=null){
                updateReceipt.ReceiptNumber__c=requestWrapper.receiptNumber;
                }
                if(requestWrapper.paymentSubType!=null){
                updateReceipt.PaymentSubType__c=requestWrapper.paymentSubType;
                }
            
                if(requestWrapper.remittanceChequeDate!=null && requestWrapper.remittanceChequeDate!=''){
                  updateReceipt.RemittanceChequeDate__c=Date.valueOf(requestWrapper.remittanceChequeDate); 
                }
            
            	if(requestWrapper.custAccountNum !=null && requestWrapper.custAccountNum !=''){
                  updateReceipt.ERPCustomerNumber__c = requestWrapper.custAccountNum; 
                }
            	if(requestWrapper.recBankAccount !=null && requestWrapper.recBankAccount !=''){
                  updateReceipt.ERPRemittedBankAccountNumber__c = requestWrapper.recBankAccount; 
                }
                if(requestWrapper.createdBy !=null && requestWrapper.createdBy !=''){
                  updateReceipt.ERPReceivedCreatedBy__c = requestWrapper.createdBy; 
                }
            	if(requestWrapper.glDate !=null && requestWrapper.glDate !=''){
                  updateReceipt.GLDate__c = Date.valueOf(requestWrapper.glDate); 
                }
            
                updateReceiptsList.add(updateReceipt);
        }
       BlkReceiptAckController.isBlkReceiptAckAPI=true;      
       List<Database.SaveResult> updateResults= Database.update(updateReceiptsList,false);
       
        for(Database.SaveResult result:updateResults){
            system.debug('++result '+result);
            if (result.isSuccess()) {
              System.debug( 'Successfully inserted: ' + result.getId());
              ReceiptAckResponseWrapper responseWrapper=new ReceiptAckResponseWrapper();
              responseWrapper.id=result.getId();
              responseWrapper.success=true;
              responseWrapper.errors=null;
              responseWrapperList.add(responseWrapper);
            }else {       
             
              ReceiptAckResponseWrapper responseWrapper=new ReceiptAckResponseWrapper();
              responseWrapper.id=result.getId();
              responseWrapper.success=false;
              responseWrapper.errors=new List<Error>();
              responseWrapperList.add(responseWrapper);
                for(Database.Error error : result.getErrors()) {
                       system.debug('error::'+error.getMessage());
                    System.debug(error.getStatusCode() + ': ' + error.getMessage() + ' Fields that affected the error: ' + error.getFields());
                    Error errorDetail=new Error();
                    errorDetail.statusCode=String.valueOf(error.getStatusCode());
                    errorDetail.message= result.getId()+ ' - '+error.getMessage();
                    // errorDetail.fields=error.getFields()+''.split(',');
                    responseWrapper.errors.add(errorDetail);
                    LoggerService.save(LoggerService.addApexLog(error,'BlkReceiptAckController','doPost',''));
                }
            }
         }  
        
        String str = JSON.serialize(responseWrapperList);
        System.debug('jsonRespDataStr***:: '+responseWrapperList);
        }catch(Exception ex){
            LoggerService.save(LoggerService.addApexLog(ex,'BlkReceiptAckController','doPost','')); 
        } 
        return responseWrapperList;
   }

}