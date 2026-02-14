public with sharing class BookingUtility {

    public static List<Unit__c> lockUnit(List<Unit__c> lstUnits, String timerName){
        try{
            Decimal timerDetails = Utilities.getTimer(timerName).Timer__c;
            String timerUnit = Utilities.getTimer(timerName).Time__c;
            for(Unit__c objUnit : lstUnits){
                //DIGITAL SAles CHIRAG
                if(UnitAvailabilityWebService.UnitdigitalSales == true){
                    objUnit.LockedByCustomer__c = UnitAvailabilityWebService.UnitCustomerId;
                }else{
                    objUnit.LockedBy__c = UserInfo.getUserId();
                }
                objUnit.LockTime__c = system.now();
                objUnit.Status__c = Constants.UNIT_STATUS_BOOKING_INPROGRESS;       
                if (timerUnit == Constants.HOURS) {
                    timerDetails = timerDetails * 60;
                    objUnit.LockExpiryTime__c = system.now().addMinutes(Integer.valueOf(timerDetails));
                } else {
                    objUnit.LockExpiryTime__c = system.now().addMinutes(Integer.valueOf(timerDetails));
                }
            }
            system.debug('before update unit details '+lstUnits);
             update lstUnits;
             
        }catch(Exception ex){
            LoggerService.save(LoggerService.addApexLog(ex,'Locking of Unit','LockingUnits','LockUnits'));
            throw ex ;
        }
        return lstUnits ;
    }

    public static Map<Id,SalesOfferUtility.SalesOfferDetails> verifyBooking(BookingDetailModel bookingVerification){

            Map<Id,SalesOfferUtility.SalesOfferDetails> bookingDetailWrapper = new Map<Id,SalesOfferUtility.SalesOfferDetails>();

            Map<Id,Unit__c> unitDetailMap = new Map<Id,Unit__c>(UnitService.getAllUnitsById(bookingVerification.unitIds));
            System.debug('**Unit Detail**'+unitDetailMap);
            //DIGITAL SAles CHIRAG
            for(Id unId : unitDetailMap.keySet()){
                UnitAvailabilityWebService.UnitdigitalSales =  unitDetailMap.get(unId).DigitalSales__c;
            }
            UnitAvailabilityWebService.UnitCustomerId = bookingVerification.accountId;
            //---- Unit Availability
            UnitAvailabilityWebService.UnitVerificationResponse unitAvailability = new UnitAvailabilityWebService.UnitVerificationResponse();
            unitAvailability = UnitAvailabilityWebService.verifyUnitStatus(unitAvailability, unitDetailMap.values(), Constants.UNIT_LOCKING, Constants.BOOKING_PROCESS);
            system.debug('unitAvailability**'+unitAvailability);

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

                bookingDetailWrapper = OpportunityUnitSearchController.generateSalesOffer(bookingVerification.inputWrapperList,bookingVerification.opportunityId);

                Set<Id> projectBudgetIds = new Set<Id>();
                Map<Unit__c,SalesOfferUtility.PaymentPlanWrapper> unitPaymentPlanWrapper = new Map<Unit__c,SalesOfferUtility.PaymentPlanWrapper>();

                for(Id unitId : bookingDetailWrapper.keySet()){
                    SalesOfferUtility.SalesOfferDetails unitBookingDetail = bookingDetailWrapper.get(unitId);
                    for(SalesOfferUtility.PaymentPlanWrapper paymentPlanDetail : unitBookingDetail.applicablePaymentPlansCalculated){
                        if(paymentPlanDetail.isSelected){
                            if(bookingDetailWrapper.get(unitId).unitRecord.ProjectBudget__c != null){
                                projectBudgetIds.add(bookingDetailWrapper.get(unitId).unitRecord.ProjectBudget__c);
                            }
                            unitPaymentPlanWrapper.put(bookingDetailWrapper.get(unitId).unitRecord ,paymentPlanDetail);
                        }
                    }
                }

                Map<Id,ProjectBudgetWrapper> projectSalesOrderMap = BudgetLinesService.checkAvailableProjectBudget(projectBudgetIds,unitPaymentPlanWrapper);
                if(projectSalesOrderMap != null){
                    SystemMessages__mdt unitsUnAvailable = Utilities.getSystemMessages(Constants.BUDGET_UNAVIALABLE);
                    for(ProjectBudgetWrapper wrapper : projectSalesOrderMap.values()){
                        System.debug('**Budget Available ?**'+wrapper.isBudgetAvailable);
                        if(wrapper.isBudgetAvailable == false){
                            Exceptions.BudgetUnAvailableException exc = new Exceptions.BudgetUnAvailableException();
                            exc.setMessage(unitsUnAvailable.Message__c);
                            throw exc;
                        }
                    }
                }
            }

        return bookingDetailWrapper ;
    }

}