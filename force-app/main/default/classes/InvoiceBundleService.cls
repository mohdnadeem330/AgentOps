public class InvoiceBundleService {
    
    public static void bundleCommissionLineItems(Map<Id, Map<String, List<CommissionLineItem__c>>> brokerAgencyCommissionLineMap, Map<String, CommissionLineItem__c> bssUnitCommissionLineItemMap ){
        //Map<Id, List<CommissionLineItem__c>> brokerAgencyCommissionLineMap = new Map<Id, List<CommissionLineItem__c>>();
        Map<Id, Map<String,List<InvoiceBundle__c>>> existingbrokerAgencyBundle = new Map<Id, Map<String,List<InvoiceBundle__c>>>();
        Map<Id, Map<String,List<InvoiceBundle__c>>> brokerAgencyBundle = new Map<Id, Map<String,List<InvoiceBundle__c>>>();
        List<InvoiceBundle__c> AllInvoiceBundles = new List<InvoiceBundle__c>();
        Map<Id, List<CommissionLineItem__c>> invoiceCommissionLineItem = new Map<Id, List<CommissionLineItem__c>>();
        List<CommissionLineItem__c> allClitemsToUpdate = new List<CommissionLineItem__c>();
        
        Decimal sizeOfBundle = Decimal.valueOf(System.Label.SizeOfInvoiceBundle);
        /*  
commissionLineItems = [SELECT BrokerAgency__c,Id,InstallmentLine__c,InstalmentNumber__c,InstalmentPaid__c,InstalmentPercentage__c,InvoiceBundle__c,InvoiceDate__c,InvoiceNumber__c,Name,Project__c,QuarterlyBonusCommission__c,
QuarterlyPayout__c,SalesOrder__c,Status__c,TotalExternalCommissionPercentage__c,TotalPayableCommission__c,Total_External_Commission__c,Unit_Number__c,Unit__c FROM CommissionLineItem__c
WHERE InvoiceBundle__c = null AND BrokerAgency__c != null AND CALENDAR_YEAR(SalesOrder__r.createdDate)= 2023 
AND CommissionType__c =: Constants.COMMISSION_LINE_EXTERNAL_COMMISSION
AND SalesOrder__r.Status__c != 'Cancelled'
// AND Status__c = 'Ready for Submission'
];


for(CommissionLineItem__c commissionLineItem : commissionLineItems) {
List<CommissionLineItem__c> allCommissionLineItems = brokerAgencyCommissionLineMap.get(commissionLineItem.BrokerAgency__c) != null ? brokerAgencyCommissionLineMap.get(commissionLineItem.BrokerAgency__c) : new List<CommissionLineItem__c>();
allCommissionLineItems.add(commissionLineItem);
brokerAgencyCommissionLineMap.put(commissionLineItem.BrokerAgency__c, allCommissionLineItems);
} */
        system.debug('brokerAgencyCommissionLineMap:'+brokerAgencyCommissionLineMap);
        existingbrokerAgencyBundle = getBrokerAgencyInvoiceBundle(brokerAgencyCommissionLineMap.keySet());
        for(Id brokerAgencyId : brokerAgencyCommissionLineMap.keySet()){
            Map<String, List<CommissionLineItem__c>> trnCommissionLineItemMap = brokerAgencyCommissionLineMap.get(brokerAgencyId);
            Map<String, List<CommissionLineItem__c>> businessUnitCommissionLineItemMap = brokerAgencyCommissionLineMap.get(brokerAgencyId);
            
            // for(String trnNumber: trnCommissionLineItemMap.keySet()){
            for(String businessUnitNumber: businessUnitCommissionLineItemMap.keySet()){
                Integer bundleNumber = 0;
                if(existingbrokerAgencyBundle.containsKey(brokerAgencyId)){
                    Map<String, List<InvoiceBundle__c>> trnInvoiceMap = existingbrokerAgencyBundle.get(brokerAgencyId);
                    Map<String, List<InvoiceBundle__c>> businessUnitInvoiceMap = existingbrokerAgencyBundle.get(brokerAgencyId);
                    List<InvoiceBundle__c> existingInvoiceBundleList = businessUnitInvoiceMap.get(businessUnitNumber);
                    if(existingInvoiceBundleList != null){
                        bundleNumber =  Integer.valueOf(existingInvoiceBundleList[0].BundleNumber__c);
                    }
                }
                
                List<CommissionLineItem__c> clitems = businessUnitCommissionLineItemMap.get(businessUnitNumber);
                List<InvoiceBundle__c> invoiceBundleList = new List<InvoiceBundle__c>(); 
                Decimal clitemsSize = clitems.size();
                
                Decimal result = clitemsSize/sizeOfBundle;
                Integer roundedResult = (Integer)Math.ceil(result);
                for(Integer i=0; i<roundedResult; i++) {
                    InvoiceBundle__c invoiceBundle = new InvoiceBundle__c(); 
                    invoiceBundle.BrokerAgency__c = brokerAgencyId;
                    invoiceBundle.BundleName__c = 'brokerAgencyId_'+i;
                    invoiceBundle.Status__c = 'Ready for Submission';
                    invoiceBundle.BundleNumber__c = bundleNumber + i + 1;
                    invoiceBundle.InvoiceDate__c = system.today();
                    
                    invoiceBundle.BusinessUnitId__c = businessUnitNumber;
                    invoiceBundle.BrokerManager__c = (String.isNotBlank(clitems[0]?.BrokerAgency__r?.OwnerId)) ? (clitems[0]?.BrokerAgency__r?.OwnerId) : null;
                    
                    if(bssUnitCommissionLineItemMap.containsKey(businessUnitNumber)){
                        invoiceBundle.BrokerinvoiceBillToName__c = bssUnitCommissionLineItemMap.get(businessUnitNumber).Frmla_Broker_invoice_Bill_To_Name__c;
                        invoiceBundle.BrokerinvoiceBillToAddress1__c = bssUnitCommissionLineItemMap.get(businessUnitNumber).Frmla_Broker_invoice_Bill_To_Address_1__c;
                        invoiceBundle.BrokerinvoiceBillToAddress2__c = bssUnitCommissionLineItemMap.get(businessUnitNumber).Frmla_Broker_invoice_Bill_To_Address_2__c;
                        invoiceBundle.BrokerinvoiceBillToAddress3__c = bssUnitCommissionLineItemMap.get(businessUnitNumber).Frmla_Broker_invoice_Bill_To_Address_3__c;  
                        invoiceBundle.TRNNumber__c = bssUnitCommissionLineItemMap.get(businessUnitNumber).Frmla_Broker_invoice_TRN_Number__c;                    
                    }
                    
                    AllInvoiceBundles.add(invoiceBundle);
                }
            }
        }
        insert AllInvoiceBundles;
        brokerAgencyBundle = getBrokerAgencyInvoiceBundle(brokerAgencyCommissionLineMap.keySet());
        system.debug('brokerAgencyBundle::'+brokerAgencyBundle);
        for(Id brokerAgencyId: brokerAgencyCommissionLineMap.keySet()){
            
            system.debug('brokerAgencyCommissionLineMap.get(brokerAgencyId)::'+brokerAgencyCommissionLineMap.get(brokerAgencyId));
            Map<String, List<CommissionLineItem__c>> trnCommissionLineItemMap = brokerAgencyCommissionLineMap.get(brokerAgencyId);

            for(String trnNumber: trnCommissionLineItemMap.keySet()){
                system.debug('trnNumber::'+trnNumber);
                List<CommissionLineItem__c> clitems      = trnCommissionLineItemMap.get(trnNumber);
                Map<String, List<InvoiceBundle__c>> trnInvoiceMap = brokerAgencyBundle.get(brokerAgencyId); 
                system.debug('brokerAgencyBundle.get(brokerAgencyId)::'+brokerAgencyBundle.get(brokerAgencyId));
                List<InvoiceBundle__c> invoiceBundleList = trnInvoiceMap.get(trnNumber);
                
                for(Integer i = 0; i < invoiceBundleList.size(); i++){
                    for(Integer j = 0; j < clitems.size() ; j++){
                        if( invoiceCommissionLineItem.get(invoiceBundleList[i].Id) ==null || invoiceCommissionLineItem.get(invoiceBundleList[i].Id).size() < sizeOfBundle ){
                            if(clitems[j].BrokerAgency__c == invoiceBundleList[i].BrokerAgency__c){
                                List<CommissionLineItem__c> cliItemList = invoiceCommissionLineItem.get(invoiceBundleList[i].id) != null ? invoiceCommissionLineItem.get(invoiceBundleList[i].id) : new List<CommissionLineItem__c>();
                                cliItemList.add(new CommissionLineItem__c(
                                    Id = clitems[j].Id,
                                    InvoiceBundle__c = invoiceBundleList[i].id ,
                                    BundleRemovalComments__c = ''
                                ));
                                clitems.remove(j);
                                j--;
                                invoiceCommissionLineItem.put(invoiceBundleList[i].id, cliItemList);
                            }
                        }
                    }
                } 
                
                for(InvoiceBundle__c inv: invoiceBundleList){
                    if(invoiceCommissionLineItem.containsKey(inv.Id)){
                        for(CommissionLineItem__c clitem: invoiceCommissionLineItem.get(inv.Id)){
                            if(!allClitemsToUpdate.contains(clitem)){
                                allClitemsToUpdate.add(clitem);
                            }
                        }
                    }
                    if(invoiceCommissionLineItem.containsKey(inv.Id)){
                        //   allClitemsToUpdate.addAll(invoiceCommissionLineItem.get(inv.Id));
                    }
                }
            } 
        }
        if(!allClitemsToUpdate.isEmpty()){
            update allClitemsToUpdate;
        }
        system.debug('invoiceCommissionLineItem values::' + invoiceCommissionLineItem.values());
    }
    public static Map<Id, Map<String, List<InvoiceBundle__c>>> getBrokerAgencyInvoiceBundle(Set<Id> brokeragencyIdSet){
        Map<Id, Map<String, List<InvoiceBundle__c>>> brokerAgencyBundle = new Map<Id, Map<String, List<InvoiceBundle__c>>>();
        List<InvoiceBundle__c> invoiceBundleList = [SELECT
                                                    ApprovalStatus__c,
                                                    BrokerAgency__c,
                                                    BundleName__c,
                                                    BundleNumber__c,
                                                    Id,
                                                    InvoiceDate__c,
                                                    Name,
                                                    Status__c,
                                                    BusinessUnitId__c,
                                                    TRNNumber__c,
                                                    TotalNumberofCommission__c
                                                    FROM InvoiceBundle__c
                                                    WHERE BrokerAgency__c IN:brokeragencyIdSet
                                                   // AND BusinessUnitId__c != null 
                                                    ORDER BY BundleNumber__c DESC];
        
        System.debug('invoiceBundleList::::'+invoiceBundleList);
        for(InvoiceBundle__c invoiceBundle: invoiceBundleList){
            
            Map<String, List<InvoiceBundle__c>> trnInvoiceMap = new Map<String, List<InvoiceBundle__c>>();
            Map<String, List<InvoiceBundle__c>> businessUnitInvoiceMap = new Map<String, List<InvoiceBundle__c>>();
            
           // trnInvoiceMap = brokerAgencyBundle.get(invoiceBundle.BrokerAgency__c) != null ? brokerAgencyBundle.get(invoiceBundle.BrokerAgency__c) : new Map<String, List<InvoiceBundle__c>>();
            businessUnitInvoiceMap = brokerAgencyBundle.get(invoiceBundle.BrokerAgency__c) != null ? brokerAgencyBundle.get(invoiceBundle.BrokerAgency__c) : new Map<String, List<InvoiceBundle__c>>();
            
            //List<InvoiceBundle__c> bundleList = trnInvoiceMap.get(invoiceBundle.TRNNumber__c) != null ? trnInvoiceMap.get(invoiceBundle.TRNNumber__c) : new List<InvoiceBundle__c>();
            List<InvoiceBundle__c> bundleList = businessUnitInvoiceMap.get(invoiceBundle.BusinessUnitId__c) != null ? businessUnitInvoiceMap.get(invoiceBundle.BusinessUnitId__c) : new List<InvoiceBundle__c>();            
            System.debug('invoiceBundle::::'+invoiceBundle);
            System.debug('bundleList::::'+bundleList);
            bundleList.add(invoiceBundle);
            System.debug('bundleList::::'+bundleList);
           // trnInvoiceMap.put(invoiceBundle.TRNNumber__c, bundleList);
            businessUnitInvoiceMap.put(invoiceBundle.BusinessUnitId__c, bundleList);
            brokerAgencyBundle.put(invoiceBundle.BrokerAgency__c, businessUnitInvoiceMap);
        }
        System.debug('brokerAgencyBundle:::'+brokerAgencyBundle);
        return brokerAgencyBundle;
    }
    
    //[KP] - Method for DeReference CommissionLineItems from Invoice Bundle on Rejection.
    public static void deReferenceCommissionLinesOnRejection(List<InvoiceBundle__c> rejectedInvoiceBundles) {
        List<CommissionLineItem__c> commissionLineItemListToUpdate = new List<CommissionLineItem__c>();
        
        if (rejectedInvoiceBundles == null || rejectedInvoiceBundles.isEmpty()) {
            return;
        }
        
        Set<Id> rejectedInvoiceBundleIds = new Set<Id>();
        for (InvoiceBundle__c bundle : rejectedInvoiceBundles) {
            rejectedInvoiceBundleIds.add(bundle.Id);
        }
        
        // Prepare the records for update
        for (CommissionLineItem__c cli : [ SELECT Id, Status__c, InvoiceBundle__c
                                          FROM CommissionLineItem__c
                                          WHERE InvoiceBundle__c IN :rejectedInvoiceBundleIds]) 
        {
            cli.InvoiceBundle__c = null; // Dereference the InvoiceBundle
            cli.Status__c = 'Ready for Submission'; // Set status
            commissionLineItemListToUpdate.add(cli);
        }
        
        // Update the records if there are any to update
        if (!commissionLineItemListToUpdate.isEmpty()) {
            try {
                update commissionLineItemListToUpdate;
            } catch (DmlException e) {
                System.debug('Error updating CommissionLineItem__c records: ' + e.getMessage());
            }
        }
    }
    
    @InvocableMethod(label='getCountOnInvoiceBunlde')
    public static void getCountOnInvoiceBunlde (List<Id> invoiceIdList){
        CommissionLineItemTriggerHandler.getCountOnInvoiceBunlde(invoiceIdList);
    }
    @InvocableVariable
    Public list<Id> invoiceIdList;    
    
}