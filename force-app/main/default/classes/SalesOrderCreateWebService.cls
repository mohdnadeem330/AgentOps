@RestResource (urlMapping = '/create/salesorder')
global with sharing class SalesOrderCreateWebService {
    @HTTPPost
    global static void doPost(){
        
        RestContextHandler handler = new RestContextHandler(true);
        try {   
            
            RestRequest req = RestContext.request;
            String jsonBody = req.requestBody.toString();
            BookingDetailModel bookingDetail = (BookingDetailModel)JSON.deserializeStrict(jsonBody,BookingDetailModel.class);
            
            Map<Id,SalesOfferUtility.SalesOfferDetails> bookingDetailWrapper = BookingUtility.verifyBooking(bookingDetail);
            
            system.debug('bookingDetail.opportunityId::'+bookingDetail.opportunityId);
            OpportunityUnitSearchController.blockWrapper wrap = OpportunityUnitSearchController.checkSMAuthorizationForBooking(bookingDetail.opportunityId);
            system.debug('wrap::'+wrap);
            if(wrap.isBlocked){
                
                handler.response.success = false;
                handler.response.message = wrap.blockedMessage ;
                handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
                handler.finalize(); 
            } else{
                String opportunityValidation = OpportunityService.opportunityFieldsValidation(bookingdetail.opportunityId);
                Id accountId = bookingDetail.accountId ;
                if(accountId==null){
                    Opportunity opptyRecord = [Select Id,AccountId FROM Opportunity WHERE Id=:bookingdetail.opportunityId] ;
                }  
                if(UnitAvailabilityWebService.UnitdigitalSales == false){ //Added by Chirag Digital Sales
                    String accountValidation = AccountService.accountsFieldsValidation(accountId);
                    
                    if(opportunityValidation!=null && opportunityValidation!='' ){
                        Exceptions.DataNotCompleteException exc = new Exceptions.DataNotCompleteException();
                        exc.setMessage( 'Please populate values for '+opportunityValidation +' field(s) on related Opportunity record');
                        throw exc;
                        
                    }else if(accountValidation!=null && accountValidation !=''){
                        Exceptions.DataNotCompleteException exc = new Exceptions.DataNotCompleteException();
                        exc.setMessage( 'Please populate values for '+accountValidation +' field(s) on related Account record');
                        throw exc;
                    }
                }
                String reserveOrBook = Constants.BOOKING_ACTION ;
                if(bookingDetail.orderType!=null){reserveOrBook = bookingDetail.orderType ;}
                Map<string,string> salesOrderMap = OpportunityUnitSearchController.reserveUnit(bookingDetail.inputWrapperList, bookingDetail.opportunityId, reserveOrBook,bookingDetail.winReason,bookingDetail.selectedEOI);
                handler.response.data = salesOrderMap ;handler.response.success = true;handler.finalize(); 
            }
            
        }
        catch(Exceptions.UnitsAlreadyBookedException ex){
            System.debug('line no '+ex.getStackTraceString());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_UNITS_NOT_AVAILABLE;
            handler.response.message = ex.getMessage();
            handler.finalize(ex);
        }
        catch(Exceptions.UnitsTimerExpiredException ex){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_TIMER_EXPIRED;
            handler.response.message =  ex.getMessage();
            handler.finalize(ex);
        }
        catch(Exceptions.PaymentPlanException ex){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_PAYMENT_TERMS_EXPECTION;
            handler.response.message =  ex.getMessage();
            handler.finalize(ex);
        }
        catch(Exceptions.DataNotCompleteException ex){
            System.debug('line no '+ex.getStackTraceString());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_OPPORTUNITY_INCOMPLETE;
            handler.response.message =  ex.getMessage();
            handler.finalize(ex);
        }
        catch(Exceptions.BudgetUnAvailableException ex){handler.response.success = false;handler.response.statusCode = Constants.STATUS_CODE_BUDGET_NOT_AVAILABLE;handler.response.message =  ex.getMessage();handler.finalize(ex);
        }
        catch (DMLException ex) {handler.response.success = false;handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR; handler.response.message = ex.getDMLMessage(0);handler.finalize(ex);
        }
        catch(Exception ex){
            System.debug('msg '+ex.getmessage());
            System.debug('line no '+ex.getLineNumber()+ex.getStackTraceString());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        } 
    }
    
}