global class TasareehStatusHistoryBatch implements Database.Batchable<sObject>, schedulable {
    global void execute(SchedulableContext sc){
        Database.executeBatch(new TasareehStatusHistoryBatch(), 100);
    }
    global Database.QueryLocator start(Database.BatchableContext bc){
        String query='SELECT Id, ServiceCode__c, KPIStartDate__c, KPIEndDate__c ' +
               'FROM Permit__c ' +
               'WHERE Municipality_Owner__c = \'Al DAR\' ' +
            'AND (CreatedDate =TODAY OR LastModifiedDate=TODAY) '; 
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<Permit__c> scope){
        BusinessHours businessHoursRecord = [SELECT Id FROM BusinessHours WHERE Name = 'Tasareeh Business Hours'];
        Set<Id> permitIds = new Set<Id>();
        Set<Id> InspectionpermitIds = new Set<Id>();
        List<Permit__c>permitToUpdate = new List<Permit__c>();
        Map<Id,Inspections__c> mapPermitInsp= new Map<Id,Inspections__c>();
        Decimal totalBusinessHours;
        Set<String> endStatus= new Set<String> {'Approved','Issued','Pending Payment','Pending Contractor Assignment','Rejected','Rejected Manually','Cancelled','Permit Cancelled','Canceled','Permit Completed','Expired','Completed','Closed'};
        Set<String> customerStatus= new Set<String> {'Pending Services Documents','Pending Consultant Approval'}; //statuses where customer/consultant has to take action 'Waiting on Applicant','InProgress–Waiting onApplicant'
        StatusHistory__c previousHist;
         for (SObject record : scope) {
            permitIds.add(((Permit__c) record).Id);
            if(((Permit__c)record).ServiceCode__c=='INSP'){ // for INSP services add permit in InspectionpermitIds set
                InspectionpermitIds.add( ((Permit__c)record).Id);
            }
        }
        for(Inspections__c insp:[SELECT Id,InspectionDate__c,Permit__c FROM Inspections__c WHERE Permit__c =:InspectionpermitIds AND InspectionDate__c !=NULL]){
            
            mapPermitInsp.put(insp.Permit__c,insp);
        }
        
        Set<String> stpermits = new Set<String>();
        Set<String> closedpermits = new Set<String>();
        Map<Id,Integer> mapPermitDuration=new Map<Id,Integer>();
        Integer Duration;
        Integer Count;
        
        List<StatusHistory__c> SHtoUpdate=new List<StatusHistory__c>();
        List<StatusHistory__c> stHist = [SELECT Id,Permit__c,permit__r.Name,permit__r.KPIEndDate__c,Status__c,ServiceCode__c,StatusDate__c FROM StatusHistory__c where Permit__c =: permitIds ORDER by Permit__c,Name ASC];
       
        for(StatusHistory__c sh : stHist){
            if(stpermits.contains(sh.Permit__c) && !closedpermits.contains(sh.Permit__c) ){
                          
                if(previousHist.Status__c != sh.Status__c   ){
                    if(endStatus.contains(sh.Status__c)){
                      closedpermits.add(sh.Permit__c);  
                    }
                    system.debug('SHrecord '+sh.Status__c);
                    If(!customerStatus.contains(previousHist.Status__c) ){
                        IF( (previousHist.Status__c=='Waiting on Applicant' || previousHist.Status__c=='InProgress–Waiting onApplicant') && (sh.Status__c!='Updated by Applicant' || sh.Status__c!='In Progress')){ //updated by Applicant and Waiting on Applicant  coming aas adjacent statuses 
                            previousHist=sh;
                            continue;
                        }
                      if(mapPermitInsp.containskey(sh.Permit__c)){ // for Inspection take inspection date to calculate KPI
                        totalBusinessHours = calculatebusinesshours(businessHoursRecord.Id, previousHist.StatusDate__c, mapPermitInsp.get(sh.Permit__c).InspectionDate__c);    
                      }else {
                    	totalBusinessHours = calculatebusinesshours(businessHoursRecord.Id, previousHist.StatusDate__c, sh.StatusDate__c);
                    }
                        
                        Duration= Duration + (Integer)((totalBusinessHours) /(24*60*60*1000) );
                   
                        if(sh.Status__c=='Waiting on Applicant' || endStatus.contains(sh.Status__c)){
                            sh.Duration__c= Duration;
                            sh.KPI_Transaction__c='Transaction '+count;
                            Duration=0;
                            count=count+1;
                        }
                        
                }
                   
                   // sh.Previous_Status__c=previousHist.Status__c;
                   // sh.Previous_Status_Date__c=previousHist.StatusDate__c;
                    previousHist=sh;
                
                    SHtoUpdate.add(sh);
                  
                }
                
            }else if(sh.Status__c!='Approved' || sh.Status__c!='Expired') { // first statushistory record in permit
                previousHist=sh;
                Duration=0;
                count=1;
                
                 if(endStatus.contains(sh.Status__c)){
                      closedpermits.add(sh.Permit__c);  
                    }
              
                if((sh.ServiceCode__c =='INSP' || sh.ServiceCode__c =='BCRE')){
                    If((sh.Status__c =='Inspection Scheduled') || (sh.Permit__r.Name.contains('INS') && sh.Status__c =='In Progress') ){
                    stpermits.add(sh.Permit__c);
                }
                }else{
                    stpermits.add(sh.Permit__c);
                }
                
            }      
            
        }
        system.debug('SHtoUpdate '+SHtoUpdate);
        if(!SHtoUpdate.isEmpty()){
            Update SHtoUpdate;
        }
               
        
    }
     global void finish(Database.BatchableContext bc){
        system.debug('TasareehStatusHistoryBatch Finished'); 
        
    }
   

    
    private Decimal calculatebusinesshours(Id businessHoursId, DateTime startDate,DateTime endDate) {
        system.debug('Inside method');
        return BusinessHours.diff(businessHoursId, startDate, endDate);
    }
}