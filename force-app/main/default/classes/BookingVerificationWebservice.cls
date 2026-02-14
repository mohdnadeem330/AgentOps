@RestResource (urlMapping = '/booking/verification')
global with sharing class BookingVerificationWebservice {
    
    @HTTPPost
    global static void doPost(){
        
        RestContextHandler handler = new RestContextHandler(true);

        try {   
            
            RestRequest req = RestContext.request;
            String jsonBody = req.requestBody.toString();
            BookingDetailModel bookingVerification = (BookingDetailModel)JSON.deserializeStrict(jsonBody,BookingDetailModel.class);

            Map<Id,Unit__c> unitDetailMap = new Map<Id,Unit__c>(UnitService.getAllUnitsById(bookingVerification.unitIds));
            System.debug('**Unit Detail**'+unitDetailMap);
            //---- Unit Availability
            UnitAvailabilityWebService.UnitVerificationResponse unitAvailability = new UnitAvailabilityWebService.UnitVerificationResponse();
            unitAvailability = UnitAvailabilityWebService.verifyUnitStatus(unitAvailability, unitDetailMap.values(), Constants.UNIT_LOCKING, Constants.BOOKING_PROCESS);
            

            if (unitAvailability.lockedUnits !=null && unitAvailability.lockedUnits.size()>0 && unitAvailability.timer == 0){
                SystemMessages__mdt timerExpired = Utilities.getSystemMessages(Constants.UNITS_TIMER_EXPIRED);
                Exceptions.UnitsTimerExpiredException exc = new Exceptions.UnitsTimerExpiredException();
                exc.setMessage(timerExpired.Message__c);
                exc.units = unitAvailability.lockedUnits;
                throw exc;
            }
            else if(unitAvailability.removedUnits !=null && unitAvailability.removedUnits.size()>0){
                SystemMessages__mdt unitsUnAvailable = Utilities.getSystemMessages(Constants.UNITS_ALREADY_BOOKED);
                Exceptions.UnitsAlreadyBookedException exc = new Exceptions.UnitsAlreadyBookedException();
                exc.units = unitAvailability.removedUnits;
                exc.setMessage(unitsUnAvailable.Message__c);
                throw exc;
            }
            else{

                Map<String,SystemMessages__mdt> systemMessages = Utilities.getSystemMessages(new Set<String>{Constants.NO_PAYMENT_PLAN,Constants.MULTIPLE_PAYMENT_PLAN});

                //---- Verify payment plan should be one for booking
                for(SalesOfferUtility.SaleOfferInputParam booking : bookingVerification.inputWrapperList){
                    System.debug(booking.selectedPayments);
                    if(booking.selectedPayments!=null && booking.selectedPayments.size()>1){
                        Exceptions.PaymentPlanException exc = new Exceptions.PaymentPlanException();
                        exc.setMessage(systemMessages.get(Constants.MULTIPLE_PAYMENT_PLAN).Message__c);
                        throw exc;
                    }
                    else if(booking.selectedPayments.size()==0){
                        Exceptions.PaymentPlanException exc = new Exceptions.PaymentPlanException();
                        exc.setMessage(systemMessages.get(Constants.NO_PAYMENT_PLAN).Message__c);
                        throw exc;
                    }
                }

                //---- Project Budget Check and also build the response
                Map<Id,SalesOfferUtility.SalesOfferDetails> unitDetailWrapper = OpportunityUnitSearchController.generateSalesOffer(bookingVerification.inputWrapperList,bookingVerification.opportunityId);

                BookingVerificationResponseModel bookingResponse = new BookingVerificationResponseModel();
                bookingResponse.timer = unitAvailability.timer;

                Set<Id> projectBudgetIds = new Set<Id>();
                Map<Unit__c,SalesOfferUtility.PaymentPlanWrapper> unitPaymentPlanWrapper = new Map<Unit__c,SalesOfferUtility.PaymentPlanWrapper>();

                Decimal totalAmount = 0 ;

                for(Id unitId : unitDetailWrapper.keySet()){
                    SalesOfferUtility.SalesOfferDetails unitBookingDetail = unitDetailWrapper.get(unitId);

                    for(SalesOfferUtility.PaymentPlanWrapper paymentPlanDetail : unitBookingDetail.applicablePaymentPlansCalculated){
                        if(paymentPlanDetail.isSelected){
                            Decimal downPayment = 0 ;
                            if(unitDetailWrapper.get(unitId).unitRecord.ProjectBudget__c != null){
                                projectBudgetIds.add(unitDetailWrapper.get(unitId).unitRecord.ProjectBudget__c);
                            }
                            for(SalesOfferUtility.PaymentInstallmentWrapper installmentLine : paymentPlanDetail.installmentDetails){
                                if(installmentLine.installmentRecord.InstallmentNumber__c==1){
                                    downPayment = installmentLine.totalValue ;
                                }
                            }
                            List<EOIDetail> eoiDetail = new List<EOIDetail>();
                            if(unitBookingDetail.availableEOIs !=null){
                                for(Map<String,String> eoiMap : unitBookingDetail.availableEOIs){
                                    System.debug(eoiMap+'**availableEOI**'+unitBookingDetail.availableEOIs);
                                    List<String> eoiId = eoiMap.values();
                                    if(eoiId[0]!=null && !eoiId[0].contains('None')){
                                        eoiDetail.add(new EOIDetail(eoiId[1],eoiId[0]));     
                                    }
                                }
                            }
                            
                            unitPaymentPlanWrapper.put(unitDetailWrapper.get(unitId).unitRecord ,paymentPlanDetail);
                            bookingResponse.unitDetails.add(new UnitDetailModel(unitBookingDetail.unitRecord,unitBookingDetail.unitRecord.SellingPrice__c,paymentPlanDetail.discountAmount,paymentPlanDetail.netSalesPrice,paymentPlanDetail.rebateAmount,paymentPlanDetail.paymentPlanDetails.Name,unitBookingDetail.offerRecord.Name,downPayment,eoiDetail));
                            totalAmount = totalAmount + paymentPlanDetail.netSalesPrice ;
                        }
                    }
                }

                Map<Id,ProjectBudgetWrapper> projectSalesOrderMap = BudgetLinesService.checkAvailableProjectBudget(projectBudgetIds,unitPaymentPlanWrapper);
                if(projectSalesOrderMap != null){
                    List<ProjectBudget__c> projectBudget = new List<ProjectBudget__c>();
                    SystemMessages__mdt unitsUnAvailable = Utilities.getSystemMessages(Constants.BUDGET_UNAVIALABLE);
                    Boolean throwBudgetException = false ;
                    for(Id projectBudgetId : projectSalesOrderMap.keySet()){
                        ProjectBudgetWrapper wrapper = projectSalesOrderMap.get(projectBudgetId);
                        System.debug('**Budget Available ?**'+wrapper.isBudgetAvailable);
                        if(wrapper.isBudgetAvailable == false){
                            projectBudget.add(new ProjectBudget__c(Id=projectBudgetId,NotifyDevelopment__c=true));
                            throwBudgetException = true ;
                        }
                    }
                    if(throwBudgetException){
                        ProjectBudgetService.updatProjectBudgetList(projectBudget);
                        Exceptions.BudgetUnAvailableException exc = new Exceptions.BudgetUnAvailableException();
                        exc.setMessage(unitsUnAvailable.Message__c);
                        throw exc;
                    }
                }

                //---- Send the confirmation Details
                bookingResponse.totalAmount = totalAmount ;
                bookingResponse.opportunityDetail = OpportunityService.fetchOpportunityById(bookingVerification.opportunityId);
                if(bookingResponse.opportunityDetail.CustomerResidentStatus__c != Constants.RESIDENTSTATUS_RESIDENT){
                    bookingResponse.ICArequired = true ;
                }
                Schema.DescribeFieldResult fieldResult = Opportunity.WinReason__c.getDescribe();
                for(Schema.PicklistEntry picklist: fieldResult.getPicklistValues()){
                    bookingResponse.winReason.add(picklist.getValue());
                }
                Schema.DescribeFieldResult SignatureTypes = SalesOrder__c.SignatureType__c.getDescribe();
                for(Schema.PicklistEntry picklist: SignatureTypes.getPicklistValues()){
                    bookingResponse.spaSignatureTypes.add(picklist.getValue());
                }
                
                //---- Add Reservation dropdown values
                bookingResponse.paymentMode = System.Label.ReservationPaymentModes.Split(';');
                bookingResponse.reservationAmountType = System.Label.ReservationPaymentAmount.Split(';');
                handler.response.data = bookingResponse ; 
            }
            handler.response.success = true;
            handler.finalize(); 
        }
        catch(Exceptions.UnitsAlreadyBookedException ex){
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
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_OPPORTUNITY_INCOMPLETE;
            handler.response.message =  ex.getMessage();
            handler.finalize(ex);
        }
        catch(Exceptions.BudgetUnAvailableException ex){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_BUDGET_NOT_AVAILABLE;
            handler.response.message =  ex.getMessage();
            handler.finalize(ex);
        }
        catch (DMLException ex) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = ex.getDMLMessage(0);
            handler.finalize(ex);
        }
        catch(Exception ex){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }

    global class BookingVerificationResponseModel{

        public List<String> winReason                                         {get;set;}
        public List<String> spaSignatureTypes                                 {get;set;}
        public Long timer                                                     {get;set;}
        public boolean ICArequired                                            {get;set;}
        public boolean customerDetailsVerified                                {get;set;}
        public Decimal totalAmount                                            {get;set;}
        public Opportunity opportunityDetail                                  {get;set;}
        public List<UnitDetailModel> unitDetails                              {get;set;}
        public List<String> paymentMode                                       {get;set;}
        public List<String> reservationAmountType                             {get;set;}
        
        public BookingVerificationResponseModel(){
            this.winReason = new List<String>();
            this.spaSignatureTypes = new List<String>();
            this.opportunityDetail = new Opportunity();
            this.unitDetails = new List<UnitDetailModel>();
            this.ICArequired = false ;
            this.customerDetailsVerified = false ;
            this.totalAmount = 0 ;
            this.paymentMode = new List<String>();
            this.reservationAmountType = new List<String>();
        }
    }

    global class UnitDetailModel{
        public Unit__c unitRecord               {get;set;}
        public Decimal sellingPrice             {get;set;}
        public Decimal totalDiscount            {get;set;}
        public Decimal payablePrice             {get;set;}
        public Decimal rebateAmount             {get;set;}
        public String offerName                 {get;set;}
        public String paymentPlanName           {get;set;}
        public Decimal downpayment              {get;set;}
        public List<EOIDetail> eois    {get;set;}

        public UnitDetailModel(Unit__c unitRecord,Decimal sellingPrice,Decimal totalDiscount,Decimal payablePrice,Decimal rebateAmount,String paymentPlanName,String offerName,Decimal downPayment,List<EOIDetail> eois){
            this.unitRecord = unitRecord ;
            this.sellingPrice = sellingPrice ;
            this.totalDiscount = totalDiscount ;
            this.payablePrice = payablePrice ;
            this.rebateAmount = rebateAmount ;
            this.offerName = offerName ;
            this.paymentPlanName = paymentPlanName ;
            this.downpayment = downPayment ;
            this.eois = eois ;
        }
    }

    global class EOIDetail{
        public Id eoiId  {get;set;}
        public String eoiName  {get;set;}

        public EOIDetail(Id eoiId,String eoiName){
            this.eoiId = eoiId ;
            this.eoiName = eoiName ;
        }
    }
}