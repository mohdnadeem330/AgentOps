/* Class Name: ServiceAppointmentTriggerHandler
* Created By : Smaartt 
* Description :  This class serves as handler for Service appoinemnt trigger actions
*  * */
public class ServiceAppointmentTriggerHandler extends TriggerHandler{
    
    //*** Before Insert Action***//
    public override void  beforeInsertMethod(List<SObject> serviceAppNewList, Map<Id, SObject> newMap){
        try{	            
            List<String> wOrderLineItemsIds = new List<String>();
            for(ServiceAppointment appntmnt :(List<ServiceAppointment>) serviceAppNewList){
                if (appntmnt.AppointmentType == System.Label.checkinAppointmentType) {                          
                    appntmnt.RecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get(System.Label.EventRecordType).getRecordTypeId();
                }
                if(appntmnt.ParentRecordId != null ){
                    wOrderLineItemsIds.add(appntmnt.ParentRecordId);                
                }
            } 
            
            set<Id> emptyLocationUnits = new set<Id>();
            List<ServiceAppointment> pendingAppoinments = new List<ServiceAppointment>();           
            Id DLPWTId = System.Label.DLPExecutiveWorkTypeID ;
            if(wOrderLineItemsIds.size() > 0 ){
                Map<id, WorkOrderLineItem > mapWorkOrderLines = new Map<id , WorkOrderLineItem> ([Select id,WorkTypeId,StartDate,WorkOrder.Case.Unit__c,WorkOrder.Case.Unit__r.LatitudeLongitude__Latitude__s, WorkOrder.Case.Unit__r.LatitudeLongitude__Longitude__s,WorkOrder.Description,WorkOrder.AccEmailId__c,WorkOrder.WorkType.Name,WorkOrder.Case.CaseCategory__c,WorkOrder.CaseId,WorkOrder.Case.Subject, WorkOrderId from WorkOrderLineItem where Id in :wOrderLineItemsIds] );                           
                
                Id ResolutionRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Resolution').getRecordTypeId(); 
                
                for(ServiceAppointment appntmnt : (List<ServiceAppointment>) serviceAppNewList){                                  
                    
                    if(mapWorkOrderLines.containsKey(appntmnt.ParentRecordId)){
                        
                        WorkOrderLineItem woLines = mapWorkOrderLines.get(appntmnt.ParentRecordId);                    
                        
                        if(System.Label.DLP_Service_Appointment_optimization_Active != 'True' || Test.isRunningTest() ){
                            
                            if(woLines.WorkTypeId !=  DLPWTId) appntmnt.RecordTypeId = ResolutionRecordTypeId;
                            
                            appntmnt.Description = woLines.WorkOrder.Description;                
                            appntmnt.Case__c = woLines.WorkOrder.CaseId; 
                            appntmnt.Subject = woLines.WorkOrder.Case.Subject; 
                            appntmnt.FSL__Scheduling_Policy_Used__c = System.Label.DLPSchedulingPolicyID;
                            appntmnt.AccountEmailID__c = woLines.WorkOrder.AccEmailId__c ;
                            appntmnt.FSL__GanttLabel__c = woLines.WorkOrder.Case.CaseCategory__c;
                            appntmnt.FSSK__FSK_Work_Order__c=woLines.WorkOrderId;
                        }                                            
                        if(woLines.WorkOrder.Case.Unit__c != Null && woLines.WorkOrder.Case.Unit__r.LatitudeLongitude__Latitude__s != null 
                           && woLines.WorkOrder.Case.Unit__r.LatitudeLongitude__Longitude__s != null ){
                               appntmnt.Latitude = woLines.WorkOrder.Case.Unit__r.LatitudeLongitude__Latitude__s;
                               appntmnt.Longitude =  woLines.WorkOrder.Case.Unit__r.LatitudeLongitude__Longitude__s;
                           }else {
                               emptyLocationUnits.add(woLines.WorkOrder.Case.Unit__c);
                               pendingAppoinments.add(appntmnt);
                           }                           
                        DateTime now = DateTime.now();
                        DateTime myDateTime = DateTime.newInstance(now.year(),now.month(),now.day()+1,8,0,0);
                        //appntmnt.EarliestStartTime =  myDateTime ;
                        appntmnt.DueDate =  DateTime.newInstance(now.year(),now.month(),now.day()+30,8,0,0) ;                        
                        
                        if(woLines.StartDate != Null)
                        {							
                            appntmnt.EarliestStartTime = woLines.StartDate;
                        }
                        
                    } 
                    if(emptyLocationUnits.size() > 0){ 
                        Map<id,Unit__c> addressFromBuilding = new Map<id,Unit__c>([select Id,BuildingSectionName__r.LatitudeLongitude__Latitude__s,BuildingSectionName__r.LatitudeLongitude__Longitude__s  from Unit__c where id in: emptyLocationUnits ]);
                        for(ServiceAppointment pendingAppntmnt : pendingAppoinments){
                            WorkOrderLineItem woLinesPending = mapWorkOrderLines.get(pendingAppntmnt.ParentRecordId); 
                            Unit__c unit = addressFromBuilding.get(woLinesPending.WorkOrder.Case.Unit__c);
                            if(unit.BuildingSectionName__r.LatitudeLongitude__Latitude__s != null && unit.BuildingSectionName__r.LatitudeLongitude__Longitude__s != null){
                                appntmnt.Latitude = unit.BuildingSectionName__r.LatitudeLongitude__Latitude__s;
                                appntmnt.Longitude =  unit.BuildingSectionName__r.LatitudeLongitude__Longitude__s;  
                            }
                        }
                    }
                }
            }             
        }catch(Exception e){LoggerService.save(LoggerService.addApexLog(e,'DLP SA trigger Error','DLP SA trigger Error',''));}
    }            
    //*** Before Update Action***//
    public override void beforeUpdateMethod(list<SObject> serviceAppNewList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMapSA){ 
        try{
            // if(System.Label.DLP_Service_Appointment_optimization_Active != 'True'){
            set<ID> caseId = new set<Id>();
            system.debug('SAlist***'+serviceAppNewList+oldList);
            for(ServiceAppointment appntmnts : (List<ServiceAppointment>)serviceAppNewList){
                system.debug('SAlist***'+appntmnts.Status+ appntmnts.Record_Type_Name__c);
                if(appntmnts.Status == 'Work In Progress' && appntmnts.Record_Type_Name__c == 'Assessment' ){
                    caseId.add(appntmnts.Case__c);   
                }
            } 
            if(caseId.size()> 0 ){
                Map<id,case> mapCasesWithSA = new Map<id,case>([Select id,Skills_Required__c,(Select id, AppointmentNumber, SchedStartTime, SchedEndTime,Status,CreatedDate from Service_Appointments__r) from case where id in:caseId]);        
                for(ServiceAppointment appntmnt : (List<ServiceAppointment>)serviceAppNewList){                                  
                    String apmntDetails = '';
                    for(ServiceAppointment allSARecords: mapCasesWithSA.get(appntmnt.Case__c).Service_Appointments__r){
                        apmntDetails += '   Appoinment Number: '+allSARecords.AppointmentNumber ;   
                        if(allSARecords.SchedStartTime != null) apmntDetails += '   Appoiinment Start Time: '+allSARecords.SchedStartTime.format();
                        if(allSARecords.SchedEndTime != null) apmntDetails += '   Appoiinment End Time: '+allSARecords.SchedEndTime.format()+'\n';                         
                    }
                    if(appntmnt.ServiceAppoinementDetails__c != apmntDetails) appntmnt.ServiceAppoinementDetails__c = apmntDetails;              
                }
            }
            //}
        }catch(exception e){
            LoggerService.save(LoggerService.addApexLog(e,'DLP SA trigger Error','DLP SA trigger Error',''));
        }                  
    }    
    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        
        
        if(System.Label.DLP_Service_Appointment_optimization_Active != 'True' || Test.isRunningTest()){
            
            set<ID> caseIds = New set<Id>();
            
            List<ServiceAppointment> sharingSAs = New List<ServiceAppointment>();
            for(ServiceAppointment appntmnt :(List<ServiceAppointment>) newList){  
                if( appntmnt.Status ==  'New' ){
                    caseIds.add(appntmnt.Case__c);
                }
                
            }
            if(caseIds.size() > 0){                
                Map<Id,case> mapSaCaseAssociation =  new Map<Id,case>([Select id,(select id,Status,Record_Type_Name__c from Service_Appointments__r) from case where id in:caseIds ]);
                AppDefinition appDetails = [Select id,DeveloperName from AppDefinition where DeveloperName ='Aldar_Sales_Console'];
                string sa1 = '';
                string sa2 = '';           
                for(Id caseid: caseIds){  
                    if(mapSaCaseAssociation.get(caseid) != null  && mapSaCaseAssociation.get(caseid).Service_Appointments__r.size() == 2){
                        for(ServiceAppointment apmnts : mapSaCaseAssociation.get(caseid).Service_Appointments__r){
                            if(apmnts.Record_Type_Name__c == 'Resolution'){
                                sa1 =  apmnts.Id;  }
                            else if(apmnts.Record_Type_Name__c == 'Assessment'){
                                sa2 =  apmnts.Id;  
                            } 
                        }                 
                        if(sa1 != ''  && sa2 != '' && mapSaCaseAssociation.get(caseid).Service_Appointments__r.size() == 2){ 
                            try{  
                                fsl.Ctrl739_ComplexWork.addTimeDependency(appDetails.Id, sa1, sa2, 'Same Start', false);  
                            }catch(Exception e){ 
                                LoggerService.save(LoggerService.addApexLog(e,'DLP SA trigger Error','DLP SA trigger Error',''));
                            }
                        }
                    }
                } 
            }
        }
    }
    
    //*** After Update Action***//
    public override void afterUpdateMethod(list<SObject> serviceAppNewList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMapSA){
        
        fireInvoicePlatformEvent(serviceAppNewList, oldMapSA);
        fireRecieptPlatformEvent(serviceAppNewList, oldMapSA);
        //fireAmenityPlatformEvent(serviceAppNewList, oldMapSA);
    }
    
    
    public static void fireInvoicePlatformEvent(List<ServiceAppointment> appointmentList, Map<Id, SObject> oldAppointmentMap){
        
        User loggedInUser = [Select Id, ECSS_SapAccountID__c from User where Id =: UserInfo.getUserId()];
        
        Set<Id> appointmentIdSet = new Set<Id>();
        String communityAppointmentRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByDeveloperName().get('Community_Appointments').getRecordTypeId();
        for(ServiceAppointment appointmentObj : appointmentList){
            
            ServiceAppointment oldAppointmentObj = (ServiceAppointment)oldAppointmentMap.get(appointmentObj.Id);
            if(appointmentObj.RecordTypeId == communityAppointmentRecordTypeId && appointmentObj.AccountId != null && appointmentObj.Com_Payment_Status__c == 'Success' && appointmentObj.Com_Payment_Status__c != oldAppointmentObj.Com_Payment_Status__c && appointmentObj.Master_Service_Appointment__c == null){
                appointmentIdSet.add(appointmentObj.Id);
            }
        }
        
        Set<Id> classIdSet = new Set<Id>();
        List<ServiceAppointment> parentAppointments = [Select Id, ParentRecordId, AppointmentNumber, SchedStartTime, Booking_Amount__c, Comments, AccountId, Account.SapAccountID__c, Account.Com_Cost_Center_SAP_Code__c, 
                                                       Service_Appointment__c, Service_Appointment__r.AppointmentNumber, Service_Appointment__r.Master_Service_Appointment__c, Service_Appointment__r.Master_Service_Appointment__r.AppointmentNumber , Master_Service_Appointment__c, Master_Service_Appointment__r.AppointmentNumber,
                                                       FSSK__FSK_Assigned_Service_Resource__c, FSSK__FSK_Assigned_Service_Resource__r.AssetId, FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Terms_and_conditions__c, 
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__c,
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Com_Vat_Percentage__c,
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Com_Profit_Center__c,
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Com_Profit_Center__r.Com_Invoice_GL__c,
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Com_Profit_Center__r.SapAccountID__c,
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Description,
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Com_Is_VAT_Included__c, 
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Com_Business_Area__c, 
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Package__c, 
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Package__r.Com_Fees_AED__c, 
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Package__r.Com_Fee_including_VAT__c,
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Include_VAT__c,
                                                       (Select Id, AppointmentNumber, SchedStartTime, ParentRecordId, ParentRecord.Name, Asset__r.Com_Package__r.Com_Fee_including_VAT__c 
                                                        from Service_Appointments1__r) 
                                                       from ServiceAppointment where Id IN : appointmentIdSet];
        
        
        List<Com_Service_Appointment_Invoice__e> invoiceEventsToPublish = new List<Com_Service_Appointment_Invoice__e>();
        Com_Service_Appointment_Invoice__e invoiceEventObj;
        Integer lineItemNo = 1;
        
        for(ServiceAppointment parentAppointment : parentAppointments){
            if(parentAppointment.FSSK__FSK_Assigned_Service_Resource__c != null && parentAppointment.FSSK__FSK_Assigned_Service_Resource__r.AssetId != null && parentAppointment.FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__c != null){
                invoiceEventObj = new Com_Service_Appointment_Invoice__e();
                invoiceEventObj.DupCheck__c = 'X';
                invoiceEventObj.UpRefno__c = parentAppointment.AppointmentNumber;
                invoiceEventObj.BapiItemno__c = String.valueOf(lineItemNo);
                invoiceEventObj.Bukrs__c = '1500';
                invoiceEventObj.Bktxt__c = parentAppointment.FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__c;
                invoiceEventObj.Blart__c = 'DR';
                invoiceEventObj.Bldat__c = Date.today();
                invoiceEventObj.Budat__c = Date.today();
                invoiceEventObj.Ernam__c = loggedInUser.ECSS_SapAccountID__c;
                invoiceEventObj.CGvcno__c = parentAppointment.Account.SapAccountID__c;
                invoiceEventObj.Gvcno__c = parentAppointment.FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Com_Profit_Center__r.Com_Invoice_GL__c;
                //invoiceEventObj.Iref3__c = '';
                invoiceEventObj.Prctr__c = parentAppointment.FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Com_Profit_Center__r.SapAccountID__c;
                invoiceEventObj.Sgtxt__c = parentAppointment.FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Description;
                
                if(parentAppointment.FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Com_Is_VAT_Included__c == 'Yes'){
                    Decimal taxRate = Double.valueOf(parentAppointment.FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Com_Vat_Percentage__c)/100;
                    taxRate = taxRate + 1;
                    Decimal preTaxAmount = Double.valueOf(parentAppointment.Booking_Amount__c) / taxRate; 
                    invoiceEventObj.Wrbtr__c = preTaxAmount;
                    invoiceEventObj.TaxInc__c = ' ';
                    invoiceEventObj.TaxAmt__c = parentAppointment.Booking_Amount__c - preTaxAmount; 
                }else{
                    invoiceEventObj.Wrbtr__c = parentAppointment.Booking_Amount__c;
                    invoiceEventObj.TaxInc__c = ' ';
                    invoiceEventObj.TaxAmt__c = 0;
                }
                
                invoiceEventObj.Waers__c = 'AED';
                invoiceEventObj.Xblnr__c = parentAppointment.AppointmentNumber;
                invoiceEventObj.Zterm__c = '0001';
                invoiceEventObj.Zuonr__c = parentAppointment.AppointmentNumber;
                invoiceEventObj.Zfbdt__c = Date.today();
                invoiceEventObj.Mwskz__c = 'S4';
                invoiceEventObj.Service_Appointment_Id__c = parentAppointment.Id;
                invoiceEventObj.Gsber__c = parentAppointment.FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Com_Business_Area__c;
                invoiceEventObj.TaxPercent__c = parentAppointment.FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Com_Vat_Percentage__c;
                
                if(parentAppointment.Service_Appointment__c != null && parentAppointment.Service_Appointment__r.Master_service_appointment__c != null){
                    invoiceEventObj.MasterUpRefno__c = parentAppointment.Service_Appointment__r.Master_service_appointment__r.AppointmentNumber;
                    invoiceEventObj.Master_Appointment_Id__c = parentAppointment.Service_Appointment__r.Master_service_appointment__c;
                }else if(parentAppointment.Service_Appointment__c != null && parentAppointment.Master_Service_Appointment__c == null){
                    invoiceEventObj.MasterUpRefno__c = parentAppointment.Service_Appointment__r.AppointmentNumber;
                    invoiceEventObj.Master_Appointment_Id__c = parentAppointment.Service_Appointment__c;
                }else if(parentAppointment.Master_Service_Appointment__c != null && parentAppointment.Service_Appointment__c == null){
                    invoiceEventObj.MasterUpRefno__c = parentAppointment.Master_service_appointment__r.AppointmentNumber;
                    invoiceEventObj.Master_Appointment_Id__c = parentAppointment.Master_service_appointment__c;
                }else{
                    invoiceEventObj.MasterUpRefno__c = parentAppointment.AppointmentNumber;
                    invoiceEventObj.Master_Appointment_Id__c = parentAppointment.Id;
                }
                                
                invoiceEventsToPublish.add(invoiceEventObj);
            }
        }
        
        List<Database.SaveResult> results = EventBus.publish(invoiceEventsToPublish);
        
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event.');
            } else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Error returned: ' + err.getStatusCode());
                    ErrorLoggingController.logErrors('ServiceAppointmentTriggerHandler', 'fireInvoicePlatformEvent', err.getMessage(), null, 'High');
                }
            }
        }
    }
    
    public static void fireRecieptPlatformEvent(List<ServiceAppointment> appointmentList, Map<Id, SObject> oldAppointmentMap){
        
        User loggedInUser = [Select Id, ECSS_SapAccountID__c From User where Id=: UserInfo.getUserId()];
        
        Set<Id> appointmentIdSet = new Set<Id>();
        
        String communityAppointmentRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByDeveloperName().get('Community_Appointments').getRecordTypeId();
        
        for( ServiceAppointment appointmentObj: appointmentList){
            ServiceAppointment oldAppointmentObj = (ServiceAppointment)oldAppointmentMap.get(appointmentObj.Id);
            if(appointmentObj.RecordTypeId == communityAppointmentRecordTypeId && appointmentObj.AccountId != null 
               && appointmentObj.Com_SAP_Invoice_Integration_Status__c == 'Success' 
               &&  appointmentObj.Com_SAP_Invoice_Integration_Status__c != oldAppointmentObj.Com_SAP_Invoice_Integration_Status__c
               && appointmentObj.Master_Service_Appointment__c == null)
            {
                appointmentIdSet.add(appointmentObj.Id);
            }     
        }
        
        Set<Id> classIdSet = new Set<Id>();
        List<ServiceAppointment> parentAppointments = [Select Id, Com_SAP_Document_Number__c, ParentRecordId, AppointmentNumber, SchedStartTime, Booking_Amount__c, Comments, Com_SAP_Fiscal_Year__c,
                                                       Service_Appointment__c, Service_Appointment__r.AppointmentNumber, Service_Appointment__r.Master_Service_Appointment__c, Service_Appointment__r.Master_Service_Appointment__r.AppointmentNumber , Master_Service_Appointment__c, Master_Service_Appointment__r.AppointmentNumber,
                                                       Com_Payment_Ref__c, AccountId, Account.SapAccountID__c, Account.Com_Cost_Center_SAP_Code__c, 
                                                       FSSK__FSK_Assigned_Service_Resource__c, FSSK__FSK_Assigned_Service_Resource__r.AssetId, FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Terms_and_conditions__c, 
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__c, 
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Com_Profit_Center__c,
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Com_Profit_Center__r.com_Receipt_GL__c,
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Com_Profit_Center__r.SapAccountID__c,
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Description,
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Com_Is_VAT_Included__c, 
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Com_Business_Area__c, 
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Package__c, 
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Package__r.Com_Fees_AED__c, 
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Package__r.Com_Fee_including_VAT__c,
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Include_VAT__c,
                                                       (Select Id, AppointmentNumber, SchedStartTime, ParentRecordId, ParentRecord.Name, Asset__r.Com_Package__r.Com_Fee_including_VAT__c 
                                                        from Service_Appointments1__r) 
                                                       from ServiceAppointment where Id IN : appointmentIdSet];
        
        /*Set<Id> leadIdSet = new Set<Id>();
Map<String, String> leadToSapCodeMap = new Map<String, String>();
for(ServiceAppointment parentAppointmentObj : parentAppointments){
if(String.valueOf(parentAppointmentObj.ParentRecordId).startsWith('00Q')){
leadIdSet.add(parentAppointmentObj.ParentRecordId);
}
}

for(Lead leadObj : [Select Id, Account__c, Account__r.SapAccountID__c from Lead where Id In : leadIdSet]){
leadToSapCodeMap.put(leadObj.Id, leadObj.Account__r.SapAccountID__c);
}*/
        
        
        Map<Id, ServiceAppointment> parentClassToAppointmentMap = new Map<Id, ServiceAppointment>();
        
        List <Com_Service_Appointment_Receipt__e > receiptEventsToPublish  = new List<Com_Service_Appointment_Receipt__e>();
        Com_Service_Appointment_Receipt__e receiptEventObj;
        Integer lineItemNo = 1;
        for(ServiceAppointment parentAppointment : parentAppointments){
            if(parentAppointment.FSSK__FSK_Assigned_Service_Resource__c != null && parentAppointment.FSSK__FSK_Assigned_Service_Resource__r.AssetId != null && parentAppointment.FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__c != null){
                receiptEventObj = new Com_Service_Appointment_Receipt__e();
                receiptEventObj.Bukrs__c = '1500';
                receiptEventObj.Trtyp__c ='CR';
                receiptEventObj.Bldat__c = Date.Today();
                receiptEventObj.Budat__c = Date.Today();
                receiptEventObj.Waers__c = 'AED';
                receiptEventObj.Paymt__c ='CC';
                receiptEventObj.DupCheck__c	= 'X';   
                receiptEventObj.Valut__c = Date.Today();    
                receiptEventObj.Sgtxt__c = parentAppointment.FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Description;    
                receiptEventObj.Gvcno__c = parentAppointment.Account.SapAccountID__c;
                receiptEventObj.Xblnr__c = parentAppointment.AppointmentNumber;
                receiptEventObj.Bktxt__c = parentAppointment.FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__c;
                receiptEventObj.Hkont__c = parentAppointment.FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Com_Profit_Center__r.com_Receipt_GL__c;     
                receiptEventObj.Prctr__c = parentAppointment.FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Com_Profit_Center__r.SapAccountID__c;
                receiptEventObj.Gjahr__c = parentAppointment.Com_SAP_Fiscal_Year__c;    
                receiptEventObj.Belnr__c = parentAppointment.Com_SAP_Document_Number__c;
                receiptEventObj.PayRef__c =  parentAppointment.Com_Payment_Ref__c;        
                receiptEventObj.InvAmt__c = parentAppointment.Booking_Amount__c;        
                receiptEventObj.TotAmt__c = parentAppointment.Booking_Amount__c;        
                receiptEventObj.PayAmt__c = parentAppointment.Booking_Amount__c;        
                receiptEventObj.Gsber__c = parentAppointment.FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Com_Business_Area__c; 
                receiptEventObj.Zuonr__c =  parentAppointment.Com_Payment_Ref__c;         
                receiptEventObj.Service_Appointment_Id__c = parentAppointment.Id;
                
                
                if(parentAppointment.Service_Appointment__c != null && parentAppointment.Service_Appointment__r.Master_service_appointment__c != null){
                    receiptEventObj.MasterXblnr__c = parentAppointment.Service_Appointment__r.Master_service_appointment__r.AppointmentNumber;
                    receiptEventObj.Master_Appointment_Id__c = parentAppointment.Service_Appointment__r.Master_service_appointment__c;
                }else if(parentAppointment.Service_Appointment__c != null && parentAppointment.Master_Service_Appointment__c == null){
                    receiptEventObj.MasterXblnr__c = parentAppointment.Service_Appointment__r.AppointmentNumber;
                    receiptEventObj.Master_Appointment_Id__c = parentAppointment.Service_Appointment__c;
                }else if(parentAppointment.Master_Service_Appointment__c != null && parentAppointment.Service_Appointment__c == null){
                    receiptEventObj.MasterXblnr__c = parentAppointment.Master_service_appointment__r.AppointmentNumber;
                    receiptEventObj.Master_Appointment_Id__c = parentAppointment.Master_service_appointment__c;
                }else{
                    receiptEventObj.MasterXblnr__c = parentAppointment.AppointmentNumber;
                    receiptEventObj.Master_Appointment_Id__c = parentAppointment.Id;
                }
                
                receiptEventsToPublish.add(receiptEventObj);
            }
        }
        
        List<Database.SaveResult> results = EventBus.publish(receiptEventsToPublish);
        
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event.');
            } else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Error returned: ' + err.getStatusCode());
                    ErrorLoggingController.logErrors('ServiceAppointmentTriggerHandler', 'fireRecieptPlatformEvent', err.getMessage(), null, 'High');
                }
            }
        }        
    }
    
    /*public static void fireAmenityPlatformEvent(List<ServiceAppointment> appointmentList, Map<Id, SObject> oldAppointmentMap){
        Map<String, Amenity_Charge_Code_Mapping__mdt> allRecords = Amenity_Charge_Code_Mapping__mdt.getAll();
		Map<String, String> amenityTypeToChargeCodeMap = new Map<String, String>();
        
        for(Amenity_Charge_Code_Mapping__mdt mobj : allRecords.values()){
            amenityTypeToChargeCodeMap.put(mobj.MasterLabel, mobj.Charge_Code__c);
        }
        
        List<String> parentAppointmentList = new List<String>();
        String communityAppointmentRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByDeveloperName().get('Community_Appointments').getRecordTypeId();
        String amenityRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Amenity').getRecordTypeId();
        
        for(ServiceAppointment appointmentObj : appointmentList){
            ServiceAppointment oldAppointmentObj = (ServiceAppointment)oldAppointmentMap.get(appointmentObj.Id);
            if(appointmentObj.RecordTypeId == communityAppointmentRecordTypeId && appointmentObj.AccountId != null && appointmentObj.Com_Payment_Ref__c != null && appointmentObj.Com_Payment_Ref__c != oldAppointmentObj.Com_Payment_Ref__c){
                parentAppointmentList.add(appointmentObj.Id);
            }
        }
        
        Map<String, List<ServiceAppointment>> parentToChildAppointmentList = new Map<String, List<ServiceAppointment>>();
        
        List<ServiceAppointment> parentAppointments = [Select Id, AppointmentNumber, Com_Payment_Date__c, Com_Payment_Ref__c, SchedStartTime, SchedEndTime, Asset__c, Asset__r.FarVision_Code__c, Booking_Amount__c, Comments, AccountId, Account.SapAccountID__c,
                                                       Account.FarVision_Code__c, Account.Com_Cost_Center_SAP_Code__c, Account.FirstName, Account.Phone,
                                                       Account.LastName, Account.Name, Account.BillingAddress, Account.BillingCity, Account.BillingState, 
                                                       Account.BillingCountry, Account.BillingPostalCode, Account.BillingStreet, Account.PersonEmail,
                                                       FSSK__FSK_Assigned_Service_Resource__c, 
                                                       FSSK__FSK_Assigned_Service_Resource__r.AssetId,
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.RecordTypeId,
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Include_VAT__c,
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Project__c,
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Project__r.FarVision_Code__c,
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.FarVision_Code__c,
                                                       FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Amenity_Type__c
                                                       from ServiceAppointment where Id IN : parentAppointmentList];
        
        
        List<Amenity_Booking_Event__e> eventsToPublish = new List<Amenity_Booking_Event__e>();
        Amenity_Booking_Event__e eventObj;
        Integer lineNo = 1;
        
        for(ServiceAppointment parentAppointmentObj : parentAppointments){
            if(parentAppointmentObj.FSSK__FSK_Assigned_Service_Resource__c != null && parentAppointmentObj.FSSK__FSK_Assigned_Service_Resource__r.AssetId != null && parentAppointmentObj.FSSK__FSK_Assigned_Service_Resource__r.Asset.RecordtypeId == amenityRecordTypeId){
                eventObj = new Amenity_Booking_Event__e();
                eventObj.businessUnitCode__c = parentAppointmentObj.FSSK__FSK_Assigned_Service_Resource__r.Asset.Project__r.FarVision_Code__c;
                eventObj.bookingReference__c = parentAppointmentObj.AppointmentNumber;
                eventObj.bookingDate__c = Date.valueOf(parentAppointmentObj.SchedStartTime);
                eventObj.Appointment_Id__c = parentAppointmentObj.Id;
                Integer expiryIn = Date.today().daysBetween(Date.valueOf(parentAppointmentObj.SchedEndTime));
                eventObj.expiryDays__c = expiryIn;
                eventObj.unitCode__c = parentAppointmentObj.FSSK__FSK_Assigned_Service_Resource__r.Asset.FarVision_Code__c;
                eventObj.customerCode__c = parentAppointmentObj.Account.FarVision_Code__c;
                eventObj.firstName__c = parentAppointmentObj.Account.FirstName;
                eventObj.lastName__c = parentAppointmentObj.Account.LastName;
                eventObj.fullName__c = parentAppointmentObj.Account.Name;
                eventObj.line1__c = String.valueof(parentAppointmentObj.Account.BillingStreet);
                eventObj.city__c = parentAppointmentObj.Account.BillingCity;
                eventObj.state__c = parentAppointmentObj.Account.BillingState;
                eventObj.country__c = parentAppointmentObj.Account.BillingCountry;
                eventObj.postalCode__c = parentAppointmentObj.Account.BillingPostalCode;
                eventObj.mobileNo__c = parentAppointmentObj.Account.Phone;
                eventObj.email__c = parentAppointmentObj.Account.PersonEmail;
                eventObj.total__c = parentAppointmentObj.Booking_Amount__c;
                eventObj.payableAmount__c = String.valueof(parentAppointmentObj.Booking_Amount__c);
                eventObj.isTaxInclusive__c = true;
                eventObj.chargeCode__c = amenityTypeToChargeCodeMap.get(parentAppointmentObj.FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Amenity_Type__c); //parentAppointmentObj.FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Amenity_Type__c
                eventObj.paymentPurpose__c = '';
                eventObj.instrumentDate__c = parentAppointmentObj.Com_Payment_Date__c;
                eventObj.transactionId__c = parentAppointmentObj.Com_Payment_Ref__c;
                eventObj.qty__c = 1;
                
                eventsToPublish.add(eventObj);
            }
        }
        
        List<Database.SaveResult> results = EventBus.publish(eventsToPublish);
        
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event.');
            } else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Error returned: ' + err.getStatusCode());
                    ErrorLoggingController.logErrors('ServiceAppointmentTriggerHandler', 'fireAmenityPlatformEvent', err.getMessage(), null, 'High');
                }
            }
        }
    }*/
}