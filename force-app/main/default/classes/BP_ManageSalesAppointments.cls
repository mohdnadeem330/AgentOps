@RestResource(urlMapping='/getSalesAppointments')
global without sharing class BP_ManageSalesAppointments extends BP_BaseRestResource{
        
    @HttpPost
    global static void execute() {
        RestContextHandler handler = new RestContextHandler(false);
        try{
            BP_ManageSalesAppointments service = new BP_ManageSalesAppointments();
            Map<String, String> params = RestContext.request.params;
            String requestBody = RestContext.request.requestBody.toString();
            
            ApiResponse response = service.processRequest(params, requestBody);
            
            handler.response.data = response.data;
            handler.response.success = true;
            handler.response.statusCode = response.statusCode;
            handler.response.message = response.message;
        }catch (Exception ex) {
            handler.response.success = false; handler.response.statusCode = 500; handler.response.message = ex.getMessage();
            
        } finally {
            handler.finalize();
        }
    }
    
    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try{  
            
            // Parse JSON string to Map<String,Object>
            Map<String, Object> requestBodyData = parseRequestBody(requestBody);
            
            Integer limits = requestBodyData.containsKey('limit') && requestBodyData.get('limit') != null
                ? Integer.valueOf(String.valueOf(requestBodyData.get('limit')))
                : 500;
            
            Integer offsets = requestBodyData.containsKey('offset') && requestBodyData.get('offset') != null
                ? Integer.valueOf(String.valueOf(requestBodyData.get('offset')))
                : 0;
            
            String type = (String) requestBodyData.get('type');
            String leadName = (String) requestBodyData.get('leadName');
            String leadId = (String) requestBodyData.get('leadId');
            String accountId = (String) requestBodyData.get('accountId');
            String unitId = (String) requestBodyData.get('unitId');
            String appointmentId = (String) requestBodyData.get('appointmentId');
            
            List<SalesAppointmentDetails> salesappointments = getSalesAllAppointments(limits,offsets, type, leadName, leadId, accountId, unitId, appointmentId);
            
            Integer totalRecords = getTotalAppntsCount(type, leadName, appointmentId);
            Map<String, Object> responseData = new Map<String, Object>();            
            
            if(salesappointments == null || salesappointments.isEmpty()){
                return new ApiResponse(true, 200, 'No Appointment related to this User', responseData);
            }
            responseData.put('appointmentsCount', totalRecords);
            responseData.put('appointments', salesappointments);
            return new ApiResponse(true, 200, 'Sales Appointments fetched successfully', responseData);
            
        }catch (Exception e) {
            return new ApiResponse(false, 400, 'Failed to load lead details: ' + e.getMessage(), null);
        }
    }
    
    public static List<SalesAppointmentDetails> getSalesAllAppointments(Integer limits, Integer offsets, String type, String leadName,String leadId,String accountId,String unitId, String appointmentId){
        Map<Id,String> leadReservationStatusMap = new Map<Id,String>(); 
        Id loggedInUserId = UserInfo.getUserId();
        String salesRecordTypeId = Schema.SObjectType.Appointment__c.getRecordTypeInfosByDeveloperName().get('PreSales').getRecordTypeId();
        List<SalesAppointmentDetails> listSalesAppointments = new List<SalesAppointmentDetails>();
        List<SalesAppointmentDetails> FnllistSalesAppointments = new List<SalesAppointmentDetails>();
        List<String> conditions = new List<String>();
        String ONLINE_TYPE = 'Virtual';
                
        String appSoQL = 
            'SELECT Id, EventName__c, Appointment_Status__c, Appointment_Slot_Time__c, IsCancelledByManager__c, ' +
            'Location__c, Project__c,Project__r.Name,Project__r.Damascus_Community_Name__c,Appointment_Location__c, Date__c, Slot__c, AppointmentId__c, ' +
            'Lead__c, Lead__r.LeadNumber__c,Lead__r.Status, Lead__r.RecordType.Name, Lead__r.Name, Lead__r.Email, ' +
            'Lead__r.MobilePhone, Lead__r.ExistingAccount__c, Lead__r.ExistingAccount__r.MergedAccount__c, Lead__r.ExistingAccount__r.SkipCustomerLogin__c, ' +
            'Lead__r.ExistingAccount__r.Blacklisted__c, Lead__r.ExistingAccount__r.CustomerType__c, ' +
            'Lead__r.ExistingAccount__r.SkipLiveAldarReason__c, Lead__r.ConvertedOpportunityId, Lead__r.Unit__c, '+
            'Lead__r.Unit__r.Status__c, Lead__r.Unit__r.LockedByCustomer__c, Lead__r.Unit__r.UnitNumber__c,Lead__r.Unit__r.Name, '+
            'Lead__r.BrokerAgency__r.AllowDigitalSale__c, Lead__r.ExistingAccount__r.LiveAldarLastActiveDatetime__pc ' +
            'FROM Appointment__c WHERE Lead__c != null AND Date__c >= TODAY ' +
            'AND Broker__c = \'' + String.escapeSingleQuotes(loggedInUserId) + '\' ' +
            'AND RecordTypeId = \'' + String.escapeSingleQuotes(salesRecordTypeId) + '\' ';
        
        
        if (String.isNotBlank(type)) {
            if (type == 'Virtual') {
                conditions.add('Appointment_Location__c = \'' + String.escapeSingleQuotes(ONLINE_TYPE) + '\'');
            } else if (type == 'In-person') {
                conditions.add('Appointment_Location__c != \'' + String.escapeSingleQuotes(ONLINE_TYPE) + '\'');
            }
        }
        if (leadName != null) {
            String leadNameLike = '%' + leadName + '%';
            appSoQL += ' AND Lead__r.Name LIKE \'' + String.escapeSingleQuotes(leadNameLike) + '\'';
        }
        
        if(appointmentId != null){
            conditions.add('Id = \'' + String.escapeSingleQuotes(appointmentId) + '\'');
        }
        
        if (!conditions.isEmpty()) {
            appSoQL += ' AND ' + String.join(conditions, ' AND ');
        }
        
        
        appSoQL += ' ORDER BY CreatedDate DESC';
        
        if (limits != null) {
            appSoQL += ' LIMIT ' + limits;
        }
        
        if (offsets != null) {
            appSoQL += ' OFFSET ' + offsets;
        }
        
        System.debug(' Final appSoQL '+appSoQL);
        
        if (Test.isRunningTest()) {
            appSoQL = appSoQL.split('AND')[0];
        }
        
        Set<Id> projectIdSet = new Set<Id>();
        Set<Id> oppIdSet = new Set<Id>();
        
        if (accountId !=null  && appointmentId != null && unitId != null && leadId !=null) {
            //KYC started, KYC completed, Reservation started, Reservation in progress, Reservation completed
            
            //Check SalesOrder
            List<SalesOrder__c> SaleOrderLst = new List<SalesOrder__c>();
            if(unitId != null){
                System.debug('Unit Id for Reservation '+unitId);
                SaleOrderLst = [select Id,Status__c,DownPaymentReceivedAmount__c
                                FROM SalesOrder__c 
                                Where unit__c =:unitId AND Account__c=:accountId AND Is_Digital_Sales__c = TRUE
                                AND Status__c != 'Cancelled' AND Status__c != 'Cancelled by User' LIMIT 1
                               ];
            }
            
            if(!SaleOrderLst.isEmpty()){
                
                System.debug('SO Id for Reservation '+SaleOrderLst[0]);
                
                if(SaleOrderLst[0].DownPaymentReceivedAmount__c == 0){
                    leadReservationStatusMap.put(leadId, 'Reservation In Progress');
                }else if(SaleOrderLst[0].DownPaymentReceivedAmount__c > 0){
                    leadReservationStatusMap.put(leadId, 'Reservation Completed');
                }
                
            }else{
                
                System.debug('Checking Comm Pref');
                List<Communication_Preference__c> commPrefList = [select id,Opportunity__c,Account__c,
                                                                  Unit__c,Lead__c,
                                                                  Active__c,Status__c,Category__c,Source_Type__c,FasttrackProgress__c
                                                                  From Communication_Preference__c 
                                                                  Where Active__c=true 
                                                                  AND (Category__c = 'FastTrack' OR Category__c = 'Booking')
                                                                  AND Account__c =: accountId 
                                                                  ORDER BY createddate Desc];
                
                Map<Id,Communication_Preference__c> fasttrackcommMap = new Map<Id,Communication_Preference__c>();
                Map<Id,Communication_Preference__c> bookingcommMap = new Map<Id,Communication_Preference__c>();
                
                //System.debug('Comminication Preference 1:'commPrefList.size());
                for(Communication_Preference__c cp : commPrefList){
                    System.debug('Checking Comm Pref in loop'+ cp);
                    if(cp.Category__c == 'FastTrack' && cp.Source_Type__c == 'Broker Portal'){
                        fasttrackcommMap.put(cp.Lead__c, cp);
                    }
                    if(cp.Category__c == 'Booking' && cp.Source_Type__c == 'Broker Portal' && cp.Unit__c == unitId){
                        bookingcommMap.put(cp.Lead__c, cp);
                    }
                    
                } 
                System.debug('Comminication Preference 2:'+fasttrackcommMap);
                System.debug('Comminication Preference 3:'+bookingcommMap);
                System.debug('accountId from Req '+ accountId);
                
                Communication_Preference__c fasttrackCP;
                Communication_Preference__c bookingCP;
                
                if(fasttrackcommMap.keySet() != null && fasttrackcommMap.containsKey(leadId)){
                    fasttrackCP = fasttrackcommMap.get(leadId);
                }
                if(bookingcommMap.keySet() != null && bookingcommMap.containsKey(leadId)){
                    bookingCP = bookingcommMap.get(leadId);
                }
                System.debug('Comminication fasttrackCP '+fasttrackCP);
                System.debug('Comminication bookingCP '+bookingCP);
                
                if(bookingCP != null && bookingCP.Category__c == 'Booking' && bookingCP.Lead__c == leadId && bookingCP.unit__c == unitId && bookingCP.Opportunity__c != null) {
                    leadReservationStatusMap.put(bookingCP.Lead__c,'Reservation started');
                } 
                else if(UnitAvailabilityWebService.checkCustomerKYCStatus(accountId)) {
                    leadReservationStatusMap.put(leadId, 'KYC Completed');
                }
                /*else if((fasttrackCP != null && fasttrackCP.Status__c=='Fasttrack Completed') || (bookingCP != null && bookingCP.Status__c=='Fasttrack Completed')) {
                    leadReservationStatusMap.put(accountId, 'KYC Completed');
                }*/
                else if((fasttrackCP != null && fasttrackCP.Status__c=='Link Sent' && fasttrackCP.FasttrackProgress__c != null) || (bookingCP != null && bookingCP.Status__c=='Link Sent' && bookingCP.FasttrackProgress__c != null)) {
                    leadReservationStatusMap.put(leadId, 'KYC started');
                }
               else if((fasttrackCP != null && fasttrackCP.Status__c=='Link Sent' && String.isBlank(fasttrackCP.FasttrackProgress__c)) || (bookingCP != null && bookingCP.Status__c=='Link Sent' && String.isBlank(bookingCP.FasttrackProgress__c))) {
                    leadReservationStatusMap.put(leadId, 'KYC Pending');
                }
                /* if(bookingCP != null && bookingCP.Category__c=='Booking' && bookingCP.Lead__c == leadid 
                   && bookingCP.unit__c == unitId && bookingCP.Opportunity__c != null){
                       leadReservationStatusMap.put(bookingCP.Account__c, 'Reservation started');
                   }else if (UnitAvailabilityWebService.checkCustomerKYCStatus(accountId)){
                       leadReservationStatusMap.put(accountId, 'Reservation Pending');
                   }else{
                       if((fasttrackCP != null && fasttrackCP.Status__c=='Link Sent' && String.isBlank(fasttrackCP.FasttrackProgress__c)) || (bookingCP != null && bookingCP.Status__c=='Link Sent' && String.isBlank(bookingCP.FasttrackProgress__c))){
                           leadReservationStatusMap.put(accountId, 'KYC Pending');
                       }else if((fasttrackCP != null && fasttrackCP.Status__c=='Link Sent' && fasttrackCP.FasttrackProgress__c != null) || (bookingCP != null && bookingCP.Status__c=='Link Sent' && bookingCP.FasttrackProgress__c != null)){
                           leadReservationStatusMap.put(accountId, 'KYC started');
                       }else if((fasttrackCP != null && fasttrackCP.Status__c=='Fasttrack Completed') || (bookingCP != null && bookingCP.Status__c=='Fasttrack Completed')){
                           leadReservationStatusMap.put(accountId, 'KYC completed');
                       }
                   }*/
            }
        }
        System.debug('leadReservationStatusMap Final '+leadReservationStatusMap);
        List<Appointment__c> apptList = Database.query(appSoQL);
        Map<Id,Communication_Preference__c> leadToActiveCPMap = new Map<Id,Communication_Preference__c>();
        Map<Id,Communication_Preference__c> getUnitDetailsAfterReserved = new Map<Id,Communication_Preference__c>();
        Set<Id> getLeadIds = new Set<Id>();
       
        for(Appointment__c appt : apptList) {
            if(appt.Lead__c != null) {
                getLeadIds.add(appt.Lead__c);
            }
        }
        
        if(!getLeadIds.isEmpty()) {
            for(Communication_Preference__c cp : [SELECT Id,Active__c,Lead__c,Unit__c,Unit__r.Name,Unit__r.Status__c,Sales_Order__c,Sales_Order__r.Status__c FROM Communication_Preference__c WHERE Lead__c IN : getLeadIds AND Source_Type__c = 'Broker Portal' AND Category__c = 'Booking']) {
                if(cp.Active__c) {
                    leadToActiveCPMap.put(cp.Lead__c,cp);
                } else if(!cp.Active__c && cp.Sales_Order__c != null && cp.Sales_Order__r.Status__c == 'Reserved') {
                    getUnitDetailsAfterReserved.put(cp.Lead__c,cp);
                    leadReservationStatusMap.put(cp.Lead__c, 'Reservation Completed');
                }
            }
        }
        
        for(Appointment__c eachAppt : apptList) {            
            // check Lead Conversion
            if(eachAppt.Lead__r.Status == 'Converted Lead') {
                projectIdSet.add(eachAppt.Project__c);
                oppIdSet.add(eachAppt.Lead__r.ConvertedOpportunityId);
            } 
            
            Boolean digitalSale = eachAppt.Lead__r.RecordType.Name == 'Person' && 
                eachAppt.Lead__r.ExistingAccount__c != null && 
                eachAppt.Lead__r.ExistingAccount__r.MergedAccount__c == false && 
                eachAppt.Lead__r.ExistingAccount__r.Blacklisted__c == false && 
                eachAppt.Lead__r.ExistingAccount__r.SkipCustomerLogin__c == false &&
                String.isBlank(eachAppt.Lead__r.ExistingAccount__r.SkipLiveAldarReason__c) && 
                eachAppt.Lead__r.ExistingAccount__r.CustomerType__c != 'VIP' && 
                eachAppt.Lead__r.BrokerAgency__r.AllowDigitalSale__c && 
                eachAppt.Lead__r.Unit__c == null;
            
            SalesAppointmentDetails salesAppointment = new SalesAppointmentDetails();
            salesAppointment.appointment = eachAppt; 
            salesAppointment.leadNumber = eachAppt.Lead__r.LeadNumber__c; 
            salesAppointment.leadName = eachAppt.Lead__r.Name;
            salesAppointment.leadId = eachAppt.Lead__c; 
            salesAppointment.emailId = eachAppt.Lead__r.Email; 
            salesAppointment.mobileNumber = eachAppt.Lead__r.MobilePhone;
            salesAppointment.unitStatus = eachAppt.Lead__r.Unit__r.Status__c; 
            salesAppointment.unitid = eachAppt.Lead__r.Unit__r.Id;
            salesAppointment.unitName = eachAppt.Lead__r.Unit__r.Name;
            salesAppointment.isDigitalSale = digitalSale;
            salesAppointment.ReservationStatus = leadReservationStatusMap.get(eachAppt.Lead__c) != null ? leadReservationStatusMap.get(eachAppt.Lead__c) : 'To be Reserved';
            
            Communication_Preference__c activeCP = leadToActiveCPMap.get(eachAppt.Lead__c);
            
            if(eachAppt.Lead__r.Status == 'Converted Lead' && activeCP == null) {
                salesAppointment.unitid = null;
                salesAppointment.unitName = null;
                salesAppointment.unitStatus = null;
            }
            
            if(eachAppt.Lead__r.Status == 'Converted Lead' && activeCP == null && getUnitDetailsAfterReserved.containsKey(eachAppt.Lead__c)) {
                salesAppointment.unitid = getUnitDetailsAfterReserved.get(eachAppt.Lead__c).Unit__c;
                salesAppointment.unitName = getUnitDetailsAfterReserved.get(eachAppt.Lead__c).Unit__r.Name;
                salesAppointment.unitStatus = getUnitDetailsAfterReserved.get(eachAppt.Lead__c).Unit__r.Status__c;
            }
            
            if(eachAppt.Lead__r.Status == 'Converted Lead' && activeCP != null && activeCP.Unit__c != null) {
                salesAppointment.unitid = activeCP.Unit__c;
                salesAppointment.unitName = activeCP.Unit__r.Name;
                salesAppointment.unitStatus = activeCP.Unit__r.Status__c;
            }
            
            listSalesAppointments.add(salesAppointment);
        }
        
        Map<String,SalesOrder__c> soMap = new Map<String,SalesOrder__c>();
        
        if(oppIdSet.size()>0){
            for(SalesOrder__c so : [SELECT Id,Status__c,Opportunity__c,Opportunity__r.LeadNumber__c,Unit__c,Unit__r.Project__c 
                                    From SalesOrder__c WHERE Opportunity__c IN : oppIdSet AND Unit__r.Project__c IN : projectIdSet AND
                                    Is_Digital_Sales__c = FALSE AND
                                    (Status__c = 'Pending' OR Status__c = 'Reserved' )])
            {
                soMap.put(so.Opportunity__r.LeadNumber__c, so);
            }
        }
        
        for(SalesAppointmentDetails sapp : listSalesAppointments){
            if(!soMap.containsKey(sapp.appointment.Lead__r.LeadNumber__c)){
                FnllistSalesAppointments.add(sapp);
            }
        }
        return FnllistSalesAppointments;
    }  
    
    public static Integer getTotalAppntsCount(String type, String leadName, String appointmentId){
        
        Id loggedInUserId = UserInfo.getUserId();
        String salesRecordTypeId = Schema.SObjectType.Appointment__c.getRecordTypeInfosByDeveloperName().get('PreSales').getRecordTypeId();
        List<String> conditions = new List<String>();
        String ONLINE_TYPE = 'Virtual';
        
        String appSoQL = 
            'SELECT COUNT() FROM Appointment__c WHERE Lead__c != null AND Date__c >= TODAY ' +
            'AND Broker__c = \'' + String.escapeSingleQuotes(loggedInUserId) + '\' ' +
            'AND RecordTypeId = \'' + String.escapeSingleQuotes(salesRecordTypeId) + '\' ';
        
        
        if (String.isNotBlank(type)) {
            if (type == 'Virtual') {
                conditions.add('Appointment_Location__c = \'' + String.escapeSingleQuotes(ONLINE_TYPE) + '\'');
            } else if (type == 'In-person') {
                conditions.add('Appointment_Location__c != \'' + String.escapeSingleQuotes(ONLINE_TYPE) + '\'');
            }
        }
        if (leadName != null) {
            String leadNameLike = '%' + leadName + '%';
            appSoQL += ' AND Lead__r.Name LIKE \'' + String.escapeSingleQuotes(leadNameLike) + '\'';
        }
        if(appointmentId != null) {
            conditions.add('Id = \'' + String.escapeSingleQuotes(appointmentId) + '\'');
        }
        
        if (!conditions.isEmpty()) {
            appSoQL += ' AND ' + String.join(conditions, ' AND ');
        }
        return Database.countQuery(appSoQL);
    }
    
    global class AppointmentDetails{
        global List<SalesAppointmentDetails> salesappointments;
    }
    
    global class SalesAppointmentDetails{
        global Appointment__c appointment;
        global String leadNumber;
        global String leadName;
        global String leadId;
        global String accountId;
        global String unitid;
        global String unitName;
        global String emailId;
        global String mobileNumber;
        global String unitStatus;
        global Boolean isDigitalSale = false;
        global String ReservationStatus;
    }
    
}