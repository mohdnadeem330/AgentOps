@RestResource (urlMapping = '/booking/unitverification')
global without sharing class UnitAvailabilityWebService {
    //DIGITAL SALES CHIRAG
    global static String UnitCustomerId;
    global static Boolean UnitdigitalSales;
    @HttpPost
    global static void doPost(List<Id> unitIds,String purpose,String reservationOrBooking,Boolean digitalSales,String CustomerId,String opportunityId,String leadId) {   
        
        RestContextHandler handler = new RestContextHandler(false);
        Savepoint sp = Database.setSavepoint();
        try {
            UnitVerificationResponse response = new UnitVerificationResponse();
            
            Set<Id> unitSet = new Set<Id>();
            unitSet.addAll(unitIds);
            List<Unit__c> unitDetails = new List<Unit__c>();
            //DIGITAL SALES CHIRAG
            if(digitalSales ==  true){
                UnitCustomerId = CustomerId;
                UnitdigitalSales = true;
                unitDetails = WithoutSharingClass.getAllOnlineUnitsById(unitSet);
            }else{
                unitDetails = WithoutSharingClass.getAllUnitsById(unitSet);
            } 
            
            Set<Id> unitsNotAvailable = new Set<Id>();
            
            if(unitDetails == null || unitIds.size() != unitDetails.size()){
                
                Map<Id,Unit__c> unitMap = new Map<Id,Unit__c>(unitDetails);
                
                for(Id unitId : unitIds){
                    if(!unitMap.containsKey(unitId)){
                        unitsNotAvailable.add(unitId);
                    }
                }
                
                SystemMessages__mdt unitsUnAvailable = Utilities.getSystemMessages(Constants.UNITS_ALREADY_BOOKED);
                Exceptions.UnitsAlreadyBookedException exc = new Exceptions.UnitsAlreadyBookedException();
                exc.setMessage(unitsUnAvailable.Message__c);
                response.unitRemoved = unitsNotAvailable;
                handler.response.data = response;
                throw exc;
            }
            boolean isassignAvailable = false;
            if(digitalSales != true){
                //By Narayana Start
                // To check the Service fee oustanding of the customer to restrict the booking 
                Boolean isEnabled = BatchUpdateOutstandingAmountAccs__c.getOrgDefaults().Enable_Outstanding_Balance_Check__c;
                if(isEnabled){
                    list<Opportunity> lstOpps = [Select id, Account.HasOutstandingBalance__c from Opportunity where id =: opportunityId];
                    if(!lstOpps.isEmpty()){
                        if(lstOpps[0].Account.HasOutstandingBalance__c){
                            handler.response.success = false;
                            handler.response.statusCode = Constants.STATUS_CODE_UNITS_NOT_AVAILABLE;
                            handler.response.message = label.iPadSCoutstandingMessage;
                            handler.finalize();  
                            isassignAvailable = true;
                        }
                    }
                }
                //By Narayana End
                //Checking for UnitAssignedTo
                List<Unit__c> unitDetailsWithOutSharing = new List<Unit__c>();
                unitDetailsWithOutSharing = UnitServiceWithoutSharing.getAllUnitsById(unitSet);            
                if (unitDetailsWithOutSharing.size()>0){
                    for(unit__c unitRecord : unitDetailsWithOutSharing ){
                        if (unitRecord.AssignedToUser__c == null){ 
                            handler.response.success = false;
                            handler.response.statusCode = Constants.STATUS_CODE_UNITS_NOT_AVAILABLE;
                            handler.response.message = 'Kindly request for the Unit before Reserve/Book. Please use \'Request to Assign\' button ';
                            handler.finalize();  
                            isassignAvailable = true;
                            return;
                        }

                        //Confirm unit is assigned to the correct user
                        if(unitRecord.AssignedToUser__c != UserInfo.getUserId()){
                            handler.response.success = false;
                            handler.response.statusCode = Constants.STATUS_CODE_UNITS_NOT_AVAILABLE;
                            handler.response.message = 'Cannot proceed with booking as the unit is not assigned to you';
                            handler.finalize();  
                            isassignAvailable = true;
                            return;
                        }
                    }            
                }
            } 
            Boolean stopBooking = false;
            
            if(isassignAvailable== false && digitalSales != true){
                //code from here by for UA
                List<Unit_Assignment__c> unitAssignment = [SELECT ownerId,Id,ExistingAllocationGroup__c,Unit__r.AssignedToUser__c, Unit__c, Unit__r.LockedBy__c
                                                           FROM Unit_Assignment__c
                                                           where Unit__c IN :unitIds AND
                                                           status__c IN ('Pending approval','Approved') 
                                                           and  Unit__r.Status__c =: Constants.UNIT_STATUS_AVAILABLE  
                                                          ];
                
                /*List<Unit_Assignment__c> inProgressUnit = [SELECT ownerId,Id,ExistingAllocationGroup__c,Unit__r.AssignedToUser__c, Unit__c, Unit__r.LockedBy__c
                                                           FROM Unit_Assignment__c
                                                           where Unit__c IN :unitIds AND Unit__r.Status__c ='In-Progress'  
                                                          ];*/
                
                
                /*integer count=0;        
                Map<Id,Unit_Assignment__c>    objMapNotSameUser = new  Map<Id,Unit_Assignment__c>();                       
                Id userID =  UserInfo.getUserId();
                Boolean isLogInUser = false;
                
                for(Unit_Assignment__c ua: inProgressUnit){
                    if(ua.Unit__r.AssignedToUser__c != userId){
                        isLogInUser = true;
                        stopBooking = true;
                    }
                }
                // other user stop
                for(Unit_Assignment__c ua: unitAssignment){
                    if(ua.Unit__r.AssignedToUser__c != userId){
                        isLogInUser = true;
                        stopBooking = true;
                    }
                    
                }
                
                if(isLogInUser){
                    
                    handler.response.success = false;
                    handler.response.statusCode = Constants.STATUS_CODE_UNITS_NOT_AVAILABLE;
                    handler.response.message = 'Select unit is already In progress or booked';
                    handler.finalize(); 
                    return;
                }*/
                
                // if records are not coming                
                
                if(unitAssignment == null){        
                    List<String> stringList = new List<String>();            
                    // Add each Id to the list as a String
                    for (Id recordId : unitIds) {
                        stringList.add((String)recordId);
                    }
                    OpportunityUnitSearchController.sendAssignRequestEmail(stringList,opportunityId);
                }
                //till here
            }
            if(!stopBooking) {
                if((reservationOrBooking == Constants.RESERVE_PROCESS || reservationOrBooking == Constants.BOOKING_PROCESS) && (purpose == Constants.UNIT_LOCKING || purpose == Constants.BROKER_RESERVE_UNIT)) {
                    verifyUnitStatus(response,unitDetails,purpose,reservationOrBooking);
                }
                else if(String.isNotBlank(CustomerId) && purpose == Constants.CUSTOMER_KYC_STATUS) {
                    checkCustomerKYCStatusHelper(CustomerId,response);
                }
                else if(!unitDetails.isEmpty() && (purpose == Constants.BROKER_KYC || purpose == Constants.BROKER_UNIT_RESERVATION) && String.isNotBlank(leadId) && String.isNotBlank(CustomerId)) {
                    brokerRequestReservation(unitDetails,purpose,response,leadId,CustomerId);
                }
                else if(!unitDetails.isEmpty() && purpose == Constants.BROKER_CANCEL_RESERVATION && String.isNotBlank(CustomerId) && String.isNotBlank(leadId)) {
                   cancelBrokerReservation(purpose,unitDetails[0],CustomerId,leadId);
                }
            }
            
            handler.response.data = response;
            handler.response.success = true;
            handler.finalize();
            return;
        }
        catch(Exceptions.UnitsAlreadyBookedException ex) {
            Database.rollback(sp);
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_UNITS_NOT_AVAILABLE;
            RestContext.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = ex.getMessage() + ex.getStackTraceString();
            handler.finalize(ex);
         }
        catch (Exception exc) {
            Database.rollback(sp);
            handler.response.message = exc.getMessage() + exc.getStackTraceString();
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            RestContext.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = exc.getMessage();//Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(exc);
        }
    } 
    
    global class UnitVerificationResponse {
        public Long timer                      {get;set;}
        public List<Unit__c> removedUnits      {get;set;}
        public List<Unit__c> lockedUnits       {get;set;}
        public Set<Id> unitRemoved             {get;set;}
        public Decimal lockDurationInMinutes   {get;set;}
        public Boolean isKYCValid              {get;set;}
        Map<String,Object> result              {get;set;}
        
        public UnitVerificationResponse() {
            this.timer = 0 ;
            this.removedUnits = new List<Unit__c>();
            this.lockedUnits = new List<Unit__c>();
            this.unitRemoved = new Set<Id>();
            this.lockDurationInMinutes = 0;
            this.isKYCValid = false;
            this.result = new Map<String,Object>();
        }
    }
    
    public static UnitVerificationResponse verifyUnitStatus(UnitVerificationResponse response,List<Unit__c> unitDetails,String purpose,String reservationOrBooking) {
        
        try {
            List<Unit__c> availableUnits = new List<Unit__c>();
            User loggedInUser = Utilities.getLoggedInUserDetail();
            Map<String,Timer__mdt> getTimerDetails = Timer__mdt.getAll();
            
            if((!unitDetails.isEmpty() && (unitDetails[0].Status__c == Constants.UNIT_STATUS_BOOKING_INPROGRESS || unitDetails[0].Status__c == Constants.STATUS_RESERVED) && String.isNotBlank(UnitCustomerId) && unitDetails[0].LockedByCustomer__c != null && unitDetails[0].LockedByCustomer__c != UnitCustomerId)) {
                throw new customException(label.UnitLockedByOtherCustomer);
            }
            System.debug(' unitDetails[0].Status__c >>>> : ' +  unitDetails[0].Status__c);
            
            for(Unit__c unitRec : unitDetails) {
                if(unitRec.Status__c == Constants.UNIT_STATUS_AVAILABLE)
                    availableUnits.add(unitRec);
                else if(unitRec.Status__c == Constants.UNIT_STATUS_BOOKING_INPROGRESS && (unitRec.LockedBy__c == loggedInUser.Id || unitRec.LockedByCustomer__c == UnitCustomerId)) ////DIGITAL SALES CHIRAG
                    response.lockedUnits.add(unitRec);
                else
                    response.removedUnits.add(unitRec);
            }
            System.debug(' availableUnits >>>> : ' +  availableUnits);
            
            if(purpose == Constants.UNIT_LOCKING || purpose == Constants.BROKER_RESERVE_UNIT) {
                String timerName = '' ;
                
                if(reservationOrBooking == Constants.RESERVE_PROCESS && purpose == Constants.UNIT_LOCKING) {
                    timerName = Constants.RESERVATION_TIMERNAME;
                    response.lockDurationInMinutes = (getTimerDetails.get(Constants.RESERVATION_TIMERNAME)).Timer__c;
                }
                
                else if(reservationOrBooking == Constants.BOOKING_PROCESS && purpose == Constants.UNIT_LOCKING) {
                    timerName = Constants.BOOKING_TIMERNAME;
                    response.lockDurationInMinutes = (getTimerDetails.get(Constants.BOOKING_TIMERNAME)).Timer__c;
                }
                
                else if(purpose == Constants.BROKER_RESERVE_UNIT) {
                    if(!unitDetails.isEmpty() && unitDetails[0].Status__c == Constants.UNIT_STATUS_BOOKING_INPROGRESS && String.isNotBlank(UnitCustomerId) && unitDetails[0].LockedByCustomer__c == UnitCustomerId && unitDetails[0].LockType__c == 'Broker KYC') {
                        unitDetails[0].LockType__c = 'Broker Reserve';
                        unitDetails[0].LockTime__c = System.now();
                        Integer brokerReserveTime = Integer.valueOf((getTimerDetails.get(Constants.BROKER_RESERVATION_TIMERNAME)).Timer__c);
                        unitDetails[0].LockExpiryTime__c = System.now().addMinutes(brokerReserveTime);
                        
                        try {
                            update unitDetails;
                        } catch(DMLException ex) {
                            throw new customException('Broker Reserve Unit Update Failed');
                        } 
                    }
                    timerName = Constants.BROKER_RESERVATION_TIMERNAME;
                    response.lockDurationInMinutes = (getTimerDetails.get(Constants.BROKER_RESERVATION_TIMERNAME)).Timer__c;
                }
                
                else if(purpose == Constants.BROKER_RESERVE_UNIT && unitDetails[0].Status__c == Constants.UNIT_STATUS_BOOKING_INPROGRESS && unitDetails[0].LockType__c == 'Broker Reserve') {
                    response.lockDurationInMinutes = (getTimerDetails.get(Constants.BROKER_RESERVATION_TIMERNAME)).Timer__c;
                }
                
                if(availableUnits != null && availableUnits.size() > 0 && String.isNotBlank(purpose) && String.isNotBlank(timerName)) {
                    List<Unit__c> lockedunits = WithoutSharingClass.lockUnit(availableUnits,UnitCustomerId,timerName,purpose);
                    response.lockedUnits.addAll(lockedunits);
                    System.debug('lockedunits[0].Status__c >>>> : ' + lockedunits[0].Status__c);
                }
                if(!response.lockedUnits.isEmpty())
                    response.Timer = calculateTimer(response.lockedUnits);
            }
        }
        catch (DMLException exc) {
            throw exc;
        }
        return response;
    }
    
    public static Long calculateTimer(List<Unit__c> lockedUnitList) {
        Long timer = 0;
        Long now = System.now().getTime();
        Long timeLeftMilli = 0;
        
        for(Unit__c unit: lockedUnitList) {
            if(unit.LockExpiryTime__c != null) {
                Long difference = unit.LockExpiryTime__c.getTime() - now;
                timeLeftMilli = difference > timeLeftMilli ? difference : timeLeftMilli;
            }
        }
        
        if(timeLeftMilli != null) {
            timer = timeLeftMilli/1000;  
        }
        return timer;  
    }
    
    public static Map<String,Object> cancelBrokerReservation(String purpose,Unit__c unit,String customerId,String leadId) {
        Map<String,Object> result = new Map<String,Object>();
        if(purpose == Constants.BROKER_CANCEL_RESERVATION) {
            List<Lead> getBrokerLead = [SELECT Id,InitiateDigitalBooking__c,Unit__c,IsConverted FROM Lead WHERE Id =: leadId LIMIT 1]; 
            
            if(!getBrokerLead.isEmpty()) {
                cancelBrokerSalesOrder(purpose,unit);
                deactivateBrokerCpRecord(unit.Id,customerId,getBrokerLead[0].Id);
                result = releaseBrokerUnit(unit);
                
                if(!getBrokerLead[0].IsConverted) {
                    getBrokerLead[0].Unit__c = null;
                    getBrokerLead[0].InitiateDigitalBooking__c = false;
                    
                    try {
                        update getBrokerLead;
                    } catch(DMLException ex) {
                        throw new customException('Broker Lead Update Failed');
                    }
                }
            } 
        } 
        return result;
    }
    
    public static void cancelBrokerSalesOrder(String purpose, Unit__c reservedUnit) {
        if(purpose == Constants.BROKER_CANCEL_RESERVATION && reservedUnit != null && reservedUnit.RelatedSalesOrder__c != null) {
            List<SalesOrder__c> getSalesOrder = [SELECT Id,Status__c FROM SalesOrder__c WHERE Unit__c =: reservedUnit.Id AND Id =: reservedUnit.RelatedSalesOrder__c AND Status__c =: Constants.STATUS_RESERVATION_IN_PROGRESS LIMIT 1];
            if(!getSalesOrder.isEmpty()){
                getSalesOrder[0].Status__c = Constants.SO_STATUS_CANCELLED;
                
                try {
                    update getSalesOrder; 
                } catch(DMLException ex) {
                    throw new customException('SalesOrder Cancellation Failed');
                }
            }
        }
    }
    
    public static void deactivateBrokerCpRecord(Id unitId,String accountId,Id leadId) {
        List<Communication_Preference__c> getExistingBokerCP = [SELECT Id,Active__c FROM Communication_Preference__c WHERE Lead__c =: leadId AND Unit__c =: unitId AND Account__c =: accountId AND Category__c = 'Booking' AND Status__c In ('Link Sent','Fasttrack Completed') AND Source_Type__c = 'Broker Portal' AND Active__c = true Order By CreatedDate DESC LIMIT 1];
        if(!getExistingBokerCP.isEmpty()) {
            getExistingBokerCP[0].Active__c = false;
            
            try {
                update getExistingBokerCP;
            } catch(DMLException ex) {
                throw new customException('Deactivate Broker CP Record Update Failed');
            }
        }
    }
    
    public static Map<String,Object> releaseBrokerUnit(Unit__c releaseUnit) {
        releaseUnit.LockedBy__c = null;
        releaseUnit.LockedByCustomer__c = null;
        releaseUnit.LockTime__c = null;
        releaseUnit.LockExpiryTime__c = null;
        releaseUnit.LockType__c = null;
        releaseUnit.RelatedOpportunity__c = null;
        releaseUnit.RelatedSalesOrder__c = null;
        releaseUnit.Status__c = Constants.UNIT_STATUS_AVAILABLE;
        
        try {
            update releaseUnit;
        } catch(DMLException ex) {
            throw new customException('Release Broker Unit Update Failed');
        }
        callDamascusCallbackMethod(releaseUnit,true);
        return createResult(releaseUnit.Id,'Unit Released Successfully!');
    }
    
    public static void callDamascusCallbackMethod(Unit__c unit,Boolean callDamascus) {
        if(callDamascus && unit != null && (UserInfo.getUserType() == 'PowerPartner' || UserInfo.getUserType() == 'Partner')) {
            CalloutToMuleSoft.calloutFutureService(
                JSON.serialize(new Map<String,Object>{ 'units' =>  Damascus_RestApiHandler.getModifiedUnits(new List<String>{unit.Id})}), 
                true, 
                Constants.Damascus_Callback_Property, 
                new List<Id>{unit.Id}
            );    
        }
    }
    
    public static UnitVerificationResponse brokerRequestReservation(List<Unit__c> unitDetails,String purpose,UnitVerificationResponse response,String leadId,String customerId) {
        Map<String,Object> result = new Map<String,Object>();
        
        if((!unitDetails.isEmpty() && (unitDetails[0].Status__c == Constants.UNIT_STATUS_BOOKING_INPROGRESS || unitDetails[0].Status__c == Constants.STATUS_RESERVED) && unitDetails[0].LockedByCustomer__c != null && unitDetails[0].LockedByCustomer__c != customerId)) {
            throw new customException(label.UnitLockedByOtherCustomer);
        }
        
        List<Lead> getExistingLead = [SELECT Id,InitiateDigitalBooking__c,Project__c,Unit__c,ExistingAccount__c,BrokerAgency__c,BrokerAgent__c,IsConverted,ConvertedAccountId,ConvertedOpportunityId,ConvertedAccount.PersonContactId FROM Lead WHERE Id =: leadId LIMIT 1];
        if(getExistingLead.isEmpty()) {
            throw new customException('Lead not found with provided Id.');
        }
        
        if(purpose == Constants.BROKER_KYC && unitDetails[0].Status__c == Constants.UNIT_STATUS_AVAILABLE) {
            if(!getExistingLead[0].IsConverted) {
                getExistingLead[0].Unit__c = unitDetails[0].Id;
                getExistingLead[0].InitiateDigitalBooking__c = true;
                
                try {
                    update getExistingLead;
                } catch(DMLException ex) {
                    throw new customException('Broker Lead Update Failed');
                }
                response = brokerRequestReservationHelper(getExistingLead,unitDetails,customerId,Constants.BROKER_KYC_TIMERNAME,purpose,response);
            }
        }
        
        else if(purpose == Constants.BROKER_KYC && unitDetails[0].Status__c == Constants.UNIT_STATUS_BOOKING_INPROGRESS && String.isNotBlank(customerId) && unitDetails[0].LockedByCustomer__c == customerId && unitDetails[0].LockType__c == 'Broker KYC') {
            responseHelper(response,unitDetails,Constants.BROKER_KYC_TIMERNAME);
        }
        
        else if(purpose == Constants.BROKER_UNIT_RESERVATION && unitDetails[0].Status__c == Constants.UNIT_STATUS_AVAILABLE) {
            if(!getExistingLead[0].IsConverted) {
                throw new customException('Broker Unit Reservation Failed, Lead not Converted yet !');
            }
            response = brokerRequestReservationHelper(getExistingLead,unitDetails,customerId,Constants.BROKER_RESERVATION_TIMERNAME,purpose,response);
        }
        
        else if(purpose == Constants.BROKER_UNIT_RESERVATION && (unitDetails[0].Status__c == Constants.UNIT_STATUS_BOOKING_INPROGRESS || unitDetails[0].Status__c == Constants.STATUS_RESERVED) && String.isNotBlank(CustomerId) && unitDetails[0].LockedByCustomer__c == CustomerId && unitDetails[0].LockType__c == 'Broker Reserve') {
            responseHelper(response,unitDetails,Constants.BROKER_RESERVATION_TIMERNAME);
        }
        return response;
    }
    
    public static UnitVerificationResponse brokerRequestReservationHelper(List<Lead> getExistingLead,List<Unit__c> unitDetails,String customerId,String timerName, String purpose,UnitVerificationResponse response) {
        List<Unit__c> brokerLockedUnits = new List<Unit__c>();
        Communication_Preference__c cpRecord = new Communication_Preference__c();
        
        brokerLockedUnits = WithoutSharingClass.lockUnit(new List<Unit__c>{unitDetails[0]},customerId,timerName,purpose);
        List<Communication_Preference__c> getExistingCP = [SELECT Id FROM Communication_Preference__c WHERE Lead__c =: getExistingLead[0].Id AND Unit__c =: unitDetails[0].Id AND Account__c =: customerId AND Active__c = true AND Category__c = 'Booking' AND Source_Type__c = 'Broker Portal' LIMIT 1];
        
        if(!getExistingCP.isEmpty()) {
            cpRecord = getExistingCP[0];
            response.result = createResult(cpRecord.Id,'CP record Already Exists!');
        } else {
            cpRecord = createBrokerCPRecord(getExistingLead[0],getExistingLead[0].Project__c,unitDetails[0].Id);
            response.result = createResult(cpRecord.Id,'CP record Created Successfully!');
        }
        responseHelper(response,brokerLockedUnits,timerName);
        return response;
    }
    
    public static UnitVerificationResponse responseHelper(UnitVerificationResponse response,List<Unit__c> unitDetailsList,String timerDetails) {
        Map<String,Timer__mdt> getTimerDetails = Timer__mdt.getAll();
        if(unitDetailsList[0].Status__c == Constants.UNIT_STATUS_BOOKING_INPROGRESS) {
            response.lockedUnits.addAll(unitDetailsList);
        } else {
            response.removedUnits.addAll(unitDetailsList);
        }
        response.timer = calculateTimer(unitDetailsList);
        response.lockDurationInMinutes = (getTimerDetails.get(timerDetails)).Timer__c;
        return response;
    }
    
    public static Communication_Preference__c createBrokerCPRecord(Lead ld,String projectName, Id unitId) {
        Communication_Preference__c cpRec = new Communication_Preference__c(
            Account__c = ld.ExistingAccount__c,
            Broker_Agency__c = ld.BrokerAgency__c,
            Broker_Agent__c = ld.BrokerAgent__c,
            Category__c = 'Booking',
            Source_Type__c = 'Broker Portal',
            Status__c = ld.IsConverted ? 'Fasttrack Completed' : 'Link Sent',
            Active__c = true,
            Contact__c = ld.IsConverted && ld.ConvertedAccountId != null ? ld.ConvertedAccount.PersonContactId : null,
            Project__c = projectName, 
            Unit__c = unitId,
            FastTrack_Completion_Date_Time__c = ld.IsConverted ? System.now() : null,
            Lead__c = ld.Id,
            Opportunity__c = ld.IsConverted && ld.ConvertedOpportunityId != null ? ld.ConvertedOpportunityId : null
        );
        
        try {
            insert cpRec;
        } catch(DMLException ex) {
            throw new customException('CP Record Creation Failed');
        }
        return cpRec;
    } 
    
    public static Map<String,Object> createResult(Id recordId,String message) {
        Map<String,Object> result = new Map<String,Object>();
        result.put('recordId', recordId);
        result.put('message', message);
        return result;
    }
    
    public static UnitVerificationResponse checkCustomerKYCStatusHelper(String customerId,UnitVerificationResponse response) {
        response.isKYCValid = checkCustomerKYCStatus(customerId);
        return response;
    }
    
    public static Boolean checkCustomerKYCStatus(String customerId) {
        if(String.isBlank(customerId))
            return false;
        
        DateTime latestDigitalKYCDateTime;
        DateTime latestManualKYCDateTime;
        DateTime latestDigitalOrManualKYCTime;
        Boolean isKYCValid = false;
        
        String accWhrClause = ' (Id = \'' + customerId + '\') ';
        List<Account> accountList = CustomerServiceUtility.getAccountDetail(accWhrClause);
        Account acc = !accountList.isEmpty() ? accountList[0] : new Account();
        if(acc == null || String.isBlank(acc.Id))
            return false;
        
        for(Communication_Preference__c cp : acc.Communication_Preferences__r) {
            if(!cp.isFastTrackAutoCompleted__c && cp.FastTrack_Completion_Date_Time__c != null && (cp.Category__c == 'Booking' || cp.Category__c == 'Fasttrack')) {                
                if(latestDigitalKYCDateTime == null || cp.FastTrack_Completion_Date_Time__c > latestDigitalKYCDateTime) {
                    latestDigitalKYCDateTime = cp.FastTrack_Completion_Date_Time__c;
                }
            }
        }
        
        for(Document__c doc : acc.Documents__r) {
            Boolean isKYCForm = doc.DocumentType__c == CustomerAPIConstants.DOCUMENT_TYPE_SIGNED_KYC_FORM;
            if(isKYCForm){
                ContentVersion contentVersion = CustomerServiceUtility.getContentVersion(doc.Id);
                if(contentVersion != null && doc.Status__c == Constants.DOCUMENT_STATUS_UPLOADED){
                    if(latestManualKYCDateTime == null || contentVersion.CreatedDate > latestManualKYCDateTime) {
                        latestManualKYCDateTime = contentVersion.CreatedDate;
                    } 
                }
            }
        }
        System.debug('latestManualKYCDateTime >>>> :' + latestManualKYCDateTime);
        
        if(latestDigitalKYCDateTime == null && latestManualKYCDateTime == null)
            return false;
        else if(acc.ResidentStatus__pc == 'Resident' && acc.Nationality__pc == 'United Arab Emirates' && acc.NationalIdExpiryDate__pc != null  && acc.NationalIdExpiryDate__pc < System.Today())
            return false;
        else if(acc.ResidentStatus__pc == 'Resident' && acc.Nationality__pc != 'United Arab Emirates' && acc.PassportExpiryDate__pc != null && acc.PassportExpiryDate__pc < System.Today())
            return false;
        else if(acc.ResidentStatus__pc != 'Resident' && acc.PassportExpiryDate__pc != null && acc.PassportExpiryDate__pc < System.Today())
            return false;
        else if(latestDigitalKYCDateTime == null)
            latestDigitalOrManualKYCTime = latestManualKYCDateTime;
        else if(latestManualKYCDateTime == null)
            latestDigitalOrManualKYCTime = latestDigitalKYCDateTime;
        else latestDigitalOrManualKYCTime = (latestDigitalKYCDateTime > latestManualKYCDateTime ? latestDigitalKYCDateTime : latestManualKYCDateTime);
        
        System.debug('latestDigitalOrManualKYCTime >>>> :' + latestDigitalOrManualKYCTime);
        
        if(latestDigitalOrManualKYCTime == null) return false;
        
        Datetime nowDt = Datetime.now();
        Long diffInMs = nowDt.getTime() - latestDigitalOrManualKYCTime.getTime();
        Double diffInDaysDouble = diffInMs / (1000.0 * 60.0 * 60.0 * 24.0);
        Integer diffInDays = Integer.valueOf(Math.floor(diffInDaysDouble));
        
        if(acc.ResidentStatus__pc == 'Resident') {
            Integer validityDays = (acc.Nationality__pc == 'United Arab Emirates') ? 730 : 365;
            isKYCValid = (diffInDays <= validityDays);
        } else {
            Date completionDate = latestDigitalOrManualKYCTime.date();
            isKYCValid = (System.today() <= completionDate.addDays(15));
        }
        return isKYCValid;
    }
}