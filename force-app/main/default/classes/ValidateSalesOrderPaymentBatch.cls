/**********************************************************************************************************************
* Name               : ValidateSalesOrderPaymentBatch                                                       
* Description        : For Pending SO - Batch to update SO to Pending Approve if Installment Lines and Other chnarges have (Invoiced Amount)
* Usage              :                                                       
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     10 Feb 2022      Initial Draft
* 2.0                                                     ASF-3634: Added check for pending downpayment installments       
******************************************************************************************************************/
//Script to schedule batch 
//System.schedule('ValidateSalesOrderPaymentBatch-Every_Hour', '0 0 * * * ?', new ValidateSalesOrderPaymentBatch() );
global class ValidateSalesOrderPaymentBatch implements Database.Batchable<sObject>,Schedulable,Database.Stateful {
    private set<String> contactsIds;
    public set<Id> soIds = new Set<Id>();
    global void execute(SchedulableContext ctx) { 
        database.executebatch(this,10);
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime currentDT = system.now();//.addHours(-2);
        String query='select id, Unit__c, Opportunity__r.ResidentStatus__c, Opportunity__r.CustomerResidentStatus__c,CustomerSPASigned__c,SubStatus__c, JointOwnerComplianceStatus__c from SalesOrder__c where Status__c= \''+Constants.OPPO_UNIT_STATUS_PENDING +'\' AND CustomerSPASigned__c = TRUE AND ComplianceStatus__c = \'' + Constants.STATUS_CLEARED + '\' order by lastModifiedDate';
                //String query='select id, Unit__c, Opportunity__r.ResidentStatus__c, Opportunity__r.CustomerResidentStatus__c,CustomerSPASigned__c,SubStatus__c from SalesOrder__c  LIMIT 5 order by lastModifiedDate';
        return Database.getQueryLocator(query);
    }
    
    
    global void execute(Database.BatchableContext bc, List<SalesOrder__c> scope){
        try {
            
            // Checking Joint Owner Compliance Status
             
            scope = checkJointOwnerComplianceStatus(new map<id,SalesOrder__c>(scope));
            
            map<id,SalesOrder__c> salesOrdersToProcess = new map<id,SalesOrder__c>(scope);
            set<Id> handoverUnitIds = new set<Id>();
            
            list<SalesOrder__c> salesOrdersToUpdate = new list<SalesOrder__c>();
            
            map<id,list<SalesOrderOtherCharges__c>> relatedADMCharges = new map<id,list<SalesOrderOtherCharges__c>>();
            map<id,list< InstallmentLines__c>> relatedInstallmentLines = new map<id,list< InstallmentLines__c>>();

            //Added By Tharun - Added below conditions in SOQL for AM Sale.
            List <String> projectNames = System.Label.ExcludeSalesOrdersOtherCharges.Split(';');
            List <String> oppSaleTypes = System.Label.ExcludeSalesOrdersOtherChargesSaleType.Split(';');

        

            // Updated by Tharun - below check is performed
            for(SalesOrderOtherCharges__c tempRec : [select id,Amount__c, InvoicedAmount__c,SalesOrder__c, 
                                                     SalesOrder__r.ProjectName__c , SalesOrder__r.OpportunitySaleType__c
                                                     FROM SalesOrderOtherCharges__c 
                                                     WHERE SalesOrder__c in :salesOrdersToProcess.keySet() and (TypeOfCharge__c = :Constants.BUDGET_LINE_ADMFEE OR TypeOfCharge__c = :Constants.BUDGET_LINE_ADMADMINFEE 
                                                                                                                OR TypeOfCharge__c = 'DLD' OR TypeOfCharge__c = 'RAK Municipality Fee')
                                                     AND SalesOrder__r.ProjectName__c NOT IN : projectNames 
                                                     AND SalesOrder__r.OpportunitySaleType__c NOT IN :oppSaleTypes])
            {
                if(!relatedADMCharges.containsKey(tempRec.SalesOrder__c))
                {
                    relatedADMCharges.put(tempRec.SalesOrder__C, new list<SalesOrderOtherCharges__c>());
                }
                relatedADMCharges.get(tempRec.SalesOrder__c).add(tempRec);
            }
            system.debug('relatedADMCharges.size()' + relatedADMCharges);
            
            
            for(InstallmentLines__c tempRec: [select Id, SalesOrder__c, InstallmentDate__c, InstallmentAmount__c,InvoicedAmount__c, OutstandingAmount__c from InstallmentLines__c
                            where SalesOrder__c  in :salesOrdersToProcess.keySet() 
                           // and InstallmentNumber__c =1                      
                             AND InstallmentDate__c <= TODAY]){
                if(!relatedInstallmentLines.containsKey(tempRec.SalesOrder__c)){
                    relatedInstallmentLines.put(tempRec.SalesOrder__c, new list< InstallmentLines__c>());
                }
                relatedInstallmentLines.get(tempRec.SalesOrder__c).add(tempRec);
            }
            system.debug(relatedInstallmentLines);
            for(Id salesOrderId : salesOrdersToProcess.keySet()){
            

                Decimal diffValue=0;
                
                Boolean exitloop = false;            
                if(relatedADMCharges.containsKey(SalesOrderID) && !relatedAdmCharges.get(SalesOrderID).isEmpty()){
                    for(SalesOrderOtherCharges__c SOOthercharges : relatedADMCharges.get(salesOrderId)){
                        if ((SOOthercharges.InvoicedAmount__c ==null || SOOthercharges.Amount__c == null || SOOthercharges.Amount__c == 0 || SOOthercharges.InvoicedAmount__c == 0  ) ){
                            exitloop = true;
                        } else if(SOOthercharges.InvoicedAmount__c !=null && SOOthercharges.Amount__c !=null){
                            diffValue = diffValue + (SOOthercharges.Amount__c - SOOthercharges.InvoicedAmount__c);
                        }       
                        //system.debug('TypeOfCharge__c' + SOOthercharges.TypeOfCharge__c);
                        if(exitloop) continue;   
                    } 
                }
                
                
                //if(relatedADMCharges.containsKey(salesOrderId) && (relatedADMCharges.get(salesOrderId).InvoicedAmount__c ==null || relatedADMCharges.get(salesOrderId).Amount__c == null  ) ){
                //    continue;
                //}else if(relatedADMCharges.containsKey(salesOrderId) && relatedADMCharges.get(salesOrderId).InvoicedAmount__c !=null &&  relatedADMCharges.get(salesOrderId).Amount__c !=null){
                //    diffValue = relatedADMCharges.get(salesOrderId).Amount__c - relatedADMCharges.get(salesOrderId).InvoicedAmount__c;
                // }
                //if(relatedInstallmentLines.containsKey(salesOrderId) && !relatedInstallmentLines.get(salesOrderId).isEmpty() )
                //Arvind removed the isEmpty check and kept null check 
               if (relatedADMCharges.containsKey(salesOrderId) && relatedADMCharges.get(salesOrderId) != null)
                {
                    
                    for(InstallmentLines__c tempRec : relatedInstallmentLines.get(salesOrderId)){
                        if(tempRec.InstallmentAmount__c==null || tempRec.InvoicedAmount__c==null){
                            exitLoop=true;
                            break;
                        }else if(tempRec.InstallmentAmount__c!=null && tempRec.InvoicedAmount__c!=null){
                            diffValue += (tempRec.InstallmentAmount__c - tempRec.InvoicedAmount__c);
                        }
                    }
                    if(exitLoop){ continue; }
                }
                system.debug('diffValue' + diffValue);
                if( ((salesOrdersToProcess.get(salesOrderId).Opportunity__r.CustomerResidentStatus__c!=null
                 && salesOrdersToProcess.get(salesOrderId).Opportunity__r.CustomerResidentStatus__c == Constants.RESIDENTTYPE_NON_RESIDENT) 
                 || (salesOrdersToProcess.get(salesOrderId).Opportunity__r.ResidentStatus__c!=null 
                 && salesOrdersToProcess.get(salesOrderId).Opportunity__r.ResidentStatus__c == Constants.RESIDENTTYPE_NON_RESIDENT ))
                  && diffValue > 2000){
                  continue;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  }else if(((salesOrdersToProcess.get(salesOrderId).Opportunity__r.CustomerResidentStatus__c==null || salesOrdersToProcess.get(salesOrderId).Opportunity__r.CustomerResidentStatus__c != Constants.RESIDENTTYPE_NON_RESIDENT) && (salesOrdersToProcess.get(salesOrderId).Opportunity__r.ResidentStatus__c ==null || salesOrdersToProcess.get(salesOrderId).Opportunity__r.ResidentStatus__c != Constants.RESIDENTTYPE_NON_RESIDENT)) && diffValue > 100){ continue;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        } 
                if(salesOrdersToProcess.get(salesOrderId).SubStatus__c == Constants.SALES_SUB_STATUS_FINANCE_PENDING){
                    salesOrdersToUpdate.add(new SalesOrder__c(ID=salesOrderId,Status__c=Constants.SALES_STATUS, SubStatus__c=Constants.SUB_STATUS_PENDINGWITHSALESADMIN ));
                }else{
                   salesOrdersToUpdate.add(new SalesOrder__c(ID=salesOrderId,Status__c=Constants.SALES_STATUS )); 
                }
                
                soIds.add(salesOrderId);
                system.debug('soIds++++++++ '+soIds);
                handoverUnitIds.add(salesOrdersToProcess.get(salesOrderId).Unit__c);
            }
            system.debug(salesOrdersToUpdate);
            if(!salesOrdersToUpdate.isEmpty()){
                update salesOrdersToUpdate;
                //Handover SR if not present
               // HandoverUtility.createHandoverSRUpdateSO(new list<ID>(handoverUnitIds));
            }
        }catch(Exception e){
            LoggerService.save(LoggerService.addApexLog(e,'ValidateSalesOrderPaymentBatch','execute',''));
        }
        
    }    
    global void finish(Database.BatchableContext bc){
        system.debug('soIds inside finish  '+soIds);
        if(soIds != null && !soIds.isEmpty()) {
            SalesOrderIntegrationBatch batch = new SalesOrderIntegrationBatch(soIds);
            database.executeBatch(batch, 5);
        }
        
        scheduleJob();
    }
    
    global static void scheduleJob() {
        Integer ValidateSalesOrderPaymentBatchScheduleTime = Integer.valueOf(System.Label.ValidateSalesOrderPaymentBatchSchedule);
        ValidateSalesOrderPaymentBatch objSchedule = new ValidateSalesOrderPaymentBatch();
		Datetime dt = system.now().addMinutes(ValidateSalesOrderPaymentBatchScheduleTime);
		string sCornExp = '0 ' + dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
        
        for(CronTrigger obj : [SELECT Id FROM CronTrigger WHERE CronJobDetailId IN (SELECT Id FROM CronJobDetail WHERE Name = 'ValidateSalesOrderPaymentBatch-Every_Hour')]) {
            system.abortJob(obj.Id);
        }
			
		system.schedule('ValidateSalesOrderPaymentBatch-Every_Hour', sCornExp, objSchedule);
    }

    private static List<SalesOrder__c> checkJointOwnerComplianceStatus(Map<Id, SalesOrder__c> salesOrderMap) {
        // Query to find SalesOrders that have JointOwners
        Set<Id> salesOrderIdsWithJointOwners = new Set<Id>();
        
        for (AggregateResult ar : [
            SELECT SalesOrder__c salesOrderId
            FROM JointOwner__c
            WHERE SalesOrder__c IN :salesOrderMap.keySet()
            GROUP BY SalesOrder__c
        ]) {
            salesOrderIdsWithJointOwners.add((Id) ar.get('salesOrderId'));
        }
        
        // Remove SalesOrders that have JointOwners and compliance status is not 'Cleared'
        for (Id soId : salesOrderIdsWithJointOwners) {
            SalesOrder__c so = salesOrderMap.get(soId);
            if (so != null && so.JointOwnerComplianceStatus__c != Constants.STATUS_CLEARED) {
                salesOrderMap.remove(soId);
            }
        }
        return salesOrderMap.values();
    }

}