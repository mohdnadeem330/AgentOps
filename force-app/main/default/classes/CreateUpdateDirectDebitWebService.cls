@RestResource (urlMapping = '/upsert/directDebit')
global with sharing class CreateUpdateDirectDebitWebService {
    
    @HTTPPost
    global static void doPost(Id salesOrderId, String customerIdType, String customerBankAccountType, String customerBankName,
                              String customerIdNumber, String customerAccountName, String customerIBANNumber, Boolean cloneDirectDebit, 
                              String directDebitRequestId, String remarks, Id payerAccountId){
                                  RestContextHandler handler = new RestContextHandler(true);  
                                  try {
                                      List<DirectDebitRequest__c> directDebitRequestListToUpdate = new List<DirectDebitRequest__c>();
                                      DirectDebitRequest__c directDebitRequest                   = new DirectDebitRequest__c();
                                      
                                      if(String.isNotBlank(directDebitRequestId) && directDebitRequestId != null && directDebitRequestId != ''){
                                          directDebitRequest.Id = directDebitRequestId;
                                      }
                                      if(salesOrderId != null)
                                      {
                                          if(directDebitRequestId == ''){
                                              directDebitRequest.SalesOrder__c          = salesOrderId;
                                          }
                                          directDebitRequest.CustomerIdType__c          = customerIdType;
                                          directDebitRequest.CustomerBankAccountType__c = customerBankAccountType;
                                          directDebitRequest.CustomerBankName__c        = customerBankName;
                                          directDebitRequest.CustomerIDNumber__c        = customerIdNumber;
                                          directDebitRequest.CustomerAccountName__c     = customerAccountName;
                                          directDebitRequest.CustomerIBANNumber__c      = customerIBANNumber;
                                          directDebitRequest.Remarks__c					= remarks;
                                          directDebitRequest.PayerAccount__c			= payerAccountId;
                                          if(cloneDirectDebit){
                                              directDebitRequest.Replicate_same_on_other_Sales_Order__c = cloneDirectDebit;
                                          }
                                          
                                          directDebitRequestListToUpdate.add(directDebitRequest);
                                      }
                                      if(!directDebitRequestListToUpdate.isEmpty()){
                                          upsert directDebitRequestListToUpdate;
                                          handler.response.success = true;
                                          handler.response.data    = directDebitRequestListToUpdate ;
                                          handler.finalize();
                                      }
                                  }
                                  catch (DMLException exc) {
                                      handler.response.success    = false;
                                      handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
                                      handler.response.message    = exc.getDMLMessage(0);
                                      handler.finalize(exc);
                                  } catch (Exception ex) {
                                      System.debug('msg '+ex.getMessage());
                                      System.debug('line no '+ex.getLineNumber());
                                      handler.response.success    = false;
                                      handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
                                      handler.response.message    = Constants.MESSAGE_GENERIC_ERROR;
                                      handler.finalize(ex);            
                                  }                      
                                  
                              }
}