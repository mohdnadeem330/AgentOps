/*
* Class Name:  AFX_serviceAppointmentTriggerHandler
* Created By : R3-DLP implementation-Smaartt
* Description: Controller class used for handling Service appoinement actions
*/
public class AFX_serviceAppointmentTriggerHandler {
    public static Boolean executeBeforeInsert = true;
    public static Boolean executeBeforeUpdate = true;
    public static Boolean executeafter = true;
    public static void serviceAppointmentCreationChild(List <ServiceAppointment> serviceAppNewList){
        
        try{                                                                                      
            set<ID> caseIds = New set<Id>();
            for(ServiceAppointment appntmnt : serviceAppNewList){                                
                caseIds.add(appntmnt.Case__c);                   
            }
           // ShareHelper.shareSA(serviceAppNewList);
            Map<Id,case> mapSaCaseAssociation =  new Map<Id,case>([Select id,(select id,Status,Record_Type_Name__c from Service_Appointments__r) from case where id in:caseIds ]);
            string sa1 = '';
            string sa2 = '';           
            for(Id caseid: caseIds){           
                for(ServiceAppointment apmnts : mapSaCaseAssociation.get(caseid).Service_Appointments__r){
                    if(apmnts.Record_Type_Name__c == 'Resolution'){
                        sa1 =  apmnts.Id;                       
                    }else if(apmnts.Record_Type_Name__c == 'Assessment'){
                        sa2 =  apmnts.Id;  
                    }
                }                 
                if(sa1 != ''  && sa2 != '' && mapSaCaseAssociation.get(caseid).Service_Appointments__r.size() == 2){
                    try{
                        AppDefinition appDetails = [Select id,DeveloperName from AppDefinition where DeveloperName ='Aldar_Sales_Console'];
                        fsl.Ctrl739_ComplexWork.addTimeDependency(appDetails.Id, sa1, sa2, 'Same Start', false);                     
                    }catch(Exception e){ system.debug('Issue with Dependency Creation'); }
                }
            }            
        }catch(exception e){          }
    }
    /*
    public static void serviceAppointmentUpdate(List <ServiceAppointment> serviceAppNewList,Map<id,ServiceAppointment> oldMapSA){
        try{
            set<ID> caseId = new set<Id>();
            for(ServiceAppointment appntmnts : serviceAppNewList){
                caseId.add(appntmnts.Case__c);
            }
            Map<id,case> mapCasesWithSA = new Map<id,case>([Select id,Skills_Required__c,(Select id, AppointmentNumber, SchedStartTime, SchedEndTime,Status,CreatedDate from Service_Appointments__r) from case where id in:caseId]);        
            for(ServiceAppointment appntmnt : serviceAppNewList){
                
                Id ResolutionRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Resolution').getRecordTypeId();             
                WorkType WorkTypeRec = [Select id,name from WorkType where id=: appntmnt.WorkTypeId Limit 1] ; 
                
                try{
                    String apmntDetails = '';
                    for(ServiceAppointment allSARecords: mapCasesWithSA.get(appntmnt.Case__c).Service_Appointments__r){
                        apmntDetails += '   Appoinment Number: '+allSARecords.AppointmentNumber ;                    
                        apmntDetails += '   Appoiinment Start Time: '+allSARecords.SchedStartTime;
                        apmntDetails += '   Appoiinment End Time: '+allSARecords.SchedEndTime+'\n';  
                        //apmntDetails += '   Status: '+allSARecords.Status+'\n' ;  
                    }
                    if(appntmnt.ServiceAppoinementDetails__c != apmntDetails) appntmnt.ServiceAppoinementDetails__c = apmntDetails;}catch(Exception e){                            }
                if(appntmnt.SchedStartTime != null && appntmnt.SchedEndTime != null){              
                    Long milliseconds =  appntmnt.SchedEndTime.getTime() - appntmnt.SchedStartTime.getTime();
                    Long mins = milliseconds / 60000;
                    Long hours = mins / 60;
                    Long remainingMins = mins - (hours * 60);
                    Decimal durations = hours + (Decimal)((Decimal)remainingMins/100);
                    String totalTime = String.valueOf(hours) + ' hrs ' +  String.valueOf(remainingMins) +' mins';
                    System.debug('totalTime-' + durations+''+totalTime); 
                    if(appntmnt.Duration != durations) appntmnt.Duration = durations ; 
                    
                }
            }
        }catch(exception e){}  
    }
    */
    
    
    public static void serviceAppointmentCreation(List <ServiceAppointment> serviceAppNewList){
        executeBeforeInsert = false;
        try{
            // get the work order ids from appointment
            List<String> wOrderLineItemsIds = new List<String>();
            for(ServiceAppointment appntmnt : serviceAppNewList){
                if(appntmnt.ParentRecordId != null ){
                    wOrderLineItemsIds.add(appntmnt.ParentRecordId);                
                }
            } 
            set<Id> emptyLocationUnits = new set<Id>();
            List<ServiceAppointment> pendingAppoinments = new List<ServiceAppointment>();
            WorkType DLPWT = [select id from WorkType where name = 'DLP Executive']; 
            Map<id, WorkOrderLineItem > mapWorkOrderLines = new Map<id , WorkOrderLineItem> ([Select id,WorkTypeId,WorkOrder.Case.Unit__c,WorkOrder.Case.Unit__r.LatitudeLongitude__Latitude__s, WorkOrder.Case.Unit__r.LatitudeLongitude__Longitude__s,WorkOrder.Description,WorkOrder.AccEmailId__c,WorkOrder.WorkType.Name,WorkOrder.Case.CaseCategory__c,WorkOrder.CaseId,WorkOrder.Case.Subject, WorkOrderId from WorkOrderLineItem where Id in :wOrderLineItemsIds] );            
            FSL__Scheduling_Policy__c policy=[select id ,Name  from FSL__Scheduling_Policy__c where Name='Aldar Scheduling Policy' LIMIT 1];               
            Map<id,WorkType> mapWorkTypeRec = new map<id,WorkType>([Select id,name from WorkType]) ; 
             Id ResolutionRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Resolution').getRecordTypeId(); 
            for(ServiceAppointment appntmnt : serviceAppNewList){
                 WorkType WorkTypeRec = mapWorkTypeRec.get(appntmnt.WorkTypeId) ;              
                if(mapWorkOrderLines.containsKey(appntmnt.ParentRecordId)){
                    WorkOrderLineItem woLines = mapWorkOrderLines.get(appntmnt.ParentRecordId); 
                    if(woLines.WorkTypeId !=  DLPWT.Id) appntmnt.RecordTypeId = ResolutionRecordTypeId;
                    appntmnt.Description = woLines.WorkOrder.Description;                
                    appntmnt.Case__c = woLines.WorkOrder.CaseId; 
                    appntmnt.Subject = woLines.WorkOrder.Case.Subject; 
                    if(woLines.WorkOrder.Case.Unit__c != Null && 
                        woLines.WorkOrder.Case.Unit__r.LatitudeLongitude__Latitude__s != null &&
                       woLines.WorkOrder.Case.Unit__r.LatitudeLongitude__Longitude__s != null
                      ){
                          appntmnt.Latitude = woLines.WorkOrder.Case.Unit__r.LatitudeLongitude__Latitude__s;
                          appntmnt.Longitude =  woLines.WorkOrder.Case.Unit__r.LatitudeLongitude__Longitude__s;
                      }else {
                          emptyLocationUnits.add(woLines.WorkOrder.Case.Unit__c);
                          pendingAppoinments.add(appntmnt);
                      }                   
                    appntmnt.FSL__Scheduling_Policy_Used__c = policy.id;
                    appntmnt.AccountEmailID__c = woLines.WorkOrder.AccEmailId__c ; 
                    appntmnt.FSL__GanttLabel__c = woLines.WorkOrder.Case.CaseCategory__c;
                    appntmnt.FSSK__FSK_Work_Order__c=woLines.WorkOrderId;
                } 
                if(emptyLocationUnits.size() > 0){
                   Map<id,Unit__c> addressFromBuilding = new Map<id,Unit__c>([select Id,BuildingSectionName__r.LatitudeLongitude__Latitude__s,BuildingSectionName__r.LatitudeLongitude__Longitude__s  from Unit__c where id in: emptyLocationUnits ]);
                    for(ServiceAppointment pendingAppntmnt : serviceAppNewList){
                       WorkOrderLineItem woLinesPending = mapWorkOrderLines.get(pendingAppntmnt.ParentRecordId); 
                        Unit__c unit = addressFromBuilding.get(woLinesPending.WorkOrder.Case.Unit__c);
                        if(unit.BuildingSectionName__r.LatitudeLongitude__Latitude__s != null &&
                          unit.BuildingSectionName__r.LatitudeLongitude__Longitude__s != null
                          ){
                            appntmnt.Latitude = unit.BuildingSectionName__r.LatitudeLongitude__Latitude__s;
                            appntmnt.Longitude =  unit.BuildingSectionName__r.LatitudeLongitude__Longitude__s; 
                        }
                    }
                }
            } }Catch(Exception e){system.debug('Exception in SA update'); }      
    }
}