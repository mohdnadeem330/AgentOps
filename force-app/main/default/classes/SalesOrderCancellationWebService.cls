@RestResource (urlMapping = '/upsert/ordercancellation')
global with sharing class SalesOrderCancellationWebService {
    
    @HttpPost
    global static void doPost(SalesOrderCancellation__c orderCancellation,String salesAdmin) {
        RestContextHandler handler = new RestContextHandler(true);
        Savepoint savePoint = null;
        try {
            savePoint = Database.setSavepoint();

            if(orderCancellation!=null){
                if(orderCancellation.Id ==null){
                    Id userId = UserInfo.getUserId();
                    SalesOrder__c orderDetail = [SELECT Id,Offer__c,Opportunity__r.BrokerAgencyAccount__c,Unit__c,PaymentPlan__c,Status__c FROM SalesOrder__c WHERE Id=:orderCancellation.SalesOrder__c];
                    orderCancellation.Cancellation_Status__c = 'Awaiting approval';
                    orderCancellation.CancellationRequestDate__c = Date.today();
                    orderCancellation.SalesManager__c = userId ;
                    if(orderDetail !=null && orderDetail.Id !=null){
                        orderCancellation.ExistingPromoOrOffer__c =  orderDetail.Offer__c ;
                        orderCancellation.BrokerageAgencyName__c = orderDetail.Opportunity__r.BrokerAgencyAccount__c ;
                        if(orderDetail.Status__c == Constants.OPPO_UNIT_STATUS_PENDING){
                            orderCancellation.DownPaymentStatus__c = 'Unpaid';
                        }
                        else{
                            orderCancellation.DownPaymentStatus__c = 'Paid';
                        }
                        orderCancellation.Unit__c =  orderDetail.Unit__c ;
                        orderCancellation.PaymentPlan__c =  orderDetail.PaymentPlan__c ;
                    }
                    insert orderCancellation ; 

                    Approval.ProcessSubmitRequest cancellationApproval = new Approval.ProcessSubmitRequest();
                    cancellationApproval.setSubmitterId(userId);
                    cancellationApproval.setComments(orderCancellation.ReasonforCancellation__c);
                    cancellationApproval.setObjectId(orderCancellation.Id);
                    cancellationApproval.setNextApproverIds(new List<ID>{salesAdmin});
                    Approval.process(cancellationApproval);
                }
                else{
                    update orderCancellation ; 
                }
            }
                        
            handler.response.success = true;
            handler.response.data = orderCancellation;
            handler.finalize();
            
            
            
        }catch (DMLException exc) {
            Database.rollback(savePoint);
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = exc.getDMLMessage(0);
            handler.finalize(exc);
        }
        catch (Exception exc) {
            Database.rollback(savePoint);
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(exc);
        }
    }

}