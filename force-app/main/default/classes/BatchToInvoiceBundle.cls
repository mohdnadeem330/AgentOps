global class BatchToInvoiceBundle implements Database.Batchable<sObject>, Schedulable{
    Map<Id, List<CommissionLineItem__c>> brokerAgencyCommissionLineMap = new Map<Id, List<CommissionLineItem__c>>();
    Map<Id, Map<String, List<CommissionLineItem__c>>> brokerAgencyCommissionLineMap1 = new Map<Id, Map<String, List<CommissionLineItem__c>>>();
    Map<String, CommissionLineItem__c> trnCommissionLineItemMap = new Map<String, CommissionLineItem__c>();

	Map<String, CommissionLineItem__c> businessUnitCommissionLineItemMap = new Map<String, CommissionLineItem__c>();
    global void execute(SchedulableContext ctx) {
         database.executeBatch(new BatchToInvoiceBundle());
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){ 
        String CancelledStatus = 'Cancelled';
        String SalesOrderSoldStatus = 'Sold';
        String SalesOrderRTOSoldStatus = 'RTO Sold';
        String FixedStatus = 'Fixed';
        String ReadyforSubmissionStatus = 'Ready for Submission';
        String ExternalCommissionType = 'External';
      //  List<String> testId = new List<String>{'a1a8d000008xkwEAAQ','a1a8d000008xkwWAAQ','a1a8d000008xkwgAAA'};
       
        String query = 'SELECT FrmlaBusinessUnitId__c,Frmla_Broker_invoice_Bill_To_Address_3__c,Frmla_Broker_invoice_Bill_To_Address_2__c,'+
                        'Frmla_Broker_invoice_Bill_To_Address_1__c,Frmla_Broker_invoice_Bill_To_Name__c,Frmla_Broker_invoice_TRN_Number__c,'+
                        'BrokerAgency__c,BrokerAgency__r.OwnerId,Id,InstallmentLine__c,InstalmentNumber__c,InstalmentPaid__c,'+
                        'InstalmentPercentage__c,InvoiceBundle__c,InvoiceDate__c,InvoiceNumber__c,Name,Project__c,QuarterlyBonusCommission__c,'+
                        'QuarterlyPayout__c,SalesOrder__c,Status__c,TotalExternalCommissionPercentage__c,TotalPayableCommission__c,'+
                        'Total_External_Commission__c,Unit_Number__c,Unit__c FROM CommissionLineItem__c WHERE ' +
                        'CommissionAmount__c != 0 AND InvoiceBundle__c = null AND BrokerAgency__c != null AND '+
                        'CommissionType__c =: ExternalCommissionType  AND '+
                        '(SalesOrder__r.Status__c =: SalesOrderSoldStatus OR SalesOrder__r.Status__c =:SalesOrderRTOSoldStatus ) AND '+
                        '( Status__c =: ReadyforSubmissionStatus OR  Status__c =: FixedStatus )  ORDER BY BrokerAgency__c ASC';
                       
                  //  AND CALENDAR_YEAR(SalesOrder__r.createdDate)= 2022
        system.debug('query::'+query);
        system.debug('Database.getQueryLocator(query)::'+Database.getQueryLocator(query));
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<CommissionLineItem__c> commissionLineItems){
        system.debug('commissionLineItems::'+commissionLineItems.size());
        for(CommissionLineItem__c commissionLineItem : commissionLineItems) {

            if(commissionLineItem.Frmla_Broker_invoice_TRN_Number__c != null){
                trnCommissionLineItemMap.put(commissionLineItem.Frmla_Broker_invoice_TRN_Number__c , commissionLineItem);
                businessUnitCommissionLineItemMap.put(commissionLineItem.FrmlaBusinessUnitId__c, commissionLineItem);
            }
            //FrmlaBusinessUnitId__c
            String TrnNumber = commissionLineItem.Frmla_Broker_invoice_TRN_Number__c != null ? commissionLineItem.Frmla_Broker_invoice_TRN_Number__c : '100597683000003';
            String businessUnitNumber = commissionLineItem.FrmlaBusinessUnitId__c; 
            
          /*  Map<String, List<CommissionLineItem__c>> trnCommissionLieItemMap = new Map<String, List<CommissionLineItem__c>>();
            trnCommissionLieItemMap = brokerAgencyCommissionLineMap1.get(commissionLineItem.BrokerAgency__c) != null ? brokerAgencyCommissionLineMap1.get(commissionLineItem.BrokerAgency__c) : new Map<String, List<CommissionLineItem__c>>();
            List<CommissionLineItem__c> allCommissionLineItems1 = trnCommissionLieItemMap.get(TrnNumber) != null ? trnCommissionLieItemMap.get(TrnNumber) : new List<CommissionLineItem__c>();
            allCommissionLineItems1.add(commissionLineItem);
            trnCommissionLieItemMap.put(TrnNumber, allCommissionLineItems1); */
            
            
            Map<String, List<CommissionLineItem__c>> businessUnitCommissionLieItemMap = new Map<String, List<CommissionLineItem__c>>();
            businessUnitCommissionLieItemMap = brokerAgencyCommissionLineMap1.get(commissionLineItem.BrokerAgency__c) != null ? brokerAgencyCommissionLineMap1.get(commissionLineItem.BrokerAgency__c) : new Map<String, List<CommissionLineItem__c>>();
            List<CommissionLineItem__c> allCommissionLineItems1 = businessUnitCommissionLieItemMap.get(businessUnitNumber) != null ? businessUnitCommissionLieItemMap.get(businessUnitNumber) : new List<CommissionLineItem__c>();
            allCommissionLineItems1.add(commissionLineItem);
            businessUnitCommissionLieItemMap.put(businessUnitNumber, allCommissionLineItems1);

            brokerAgencyCommissionLineMap1.put(commissionLineItem.BrokerAgency__c, businessUnitCommissionLieItemMap);
            List<CommissionLineItem__c> allCommissionLineItems = brokerAgencyCommissionLineMap.get(commissionLineItem.BrokerAgency__c) != null ? brokerAgencyCommissionLineMap.get(commissionLineItem.BrokerAgency__c) : new List<CommissionLineItem__c>();
            allCommissionLineItems.add(commissionLineItem);
            brokerAgencyCommissionLineMap.put(commissionLineItem.BrokerAgency__c, allCommissionLineItems);   
        }
        system.debug('brokerAgencyCommissionLineMap1:::'+brokerAgencyCommissionLineMap1);
        system.debug('brokerAgencyCommissionLineMap::'+brokerAgencyCommissionLineMap);
        InvoiceBundleService.bundleCommissionLineItems(brokerAgencyCommissionLineMap1, businessUnitCommissionLineItemMap); 
    }
    global void finish(Database.BatchableContext BC){ 
    
       
    }
}