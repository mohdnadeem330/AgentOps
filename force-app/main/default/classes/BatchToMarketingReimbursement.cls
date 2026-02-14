/* This class is covered from BatchToMarketingReimbursementCalloutTest apex test class */

public class BatchToMarketingReimbursement implements Database.Batchable <SObject>, Database.stateful{
    String quarter;
    String year;
    String BROKER_ENVOY_CLASSIFICATION = 'Envoy';
    
    public BatchToMarketingReimbursement(String quarter, String year){
        this.quarter = quarter;
        this.Year = Year;
    }
    
    public List<Broker_Classification_Details__c> start(Database.BatchableContext bc){
        Set<Integer> setQuarterMonths = mapQuarterToMonths.get(quarter);
        List<Broker_Classification_Details__c> bcdList = [SELECT 
                                                          Id,
                                                          Name,
                                                          Month__c,Year__c,
                                                          Classification__c,
                                                          Classification__r.Name,
                                                          Classification__r.Quarter1MarketingBudget__c,
                                                          Classification__r.Quarter2MarketingBudget__c,
                                                          Classification__r.Quarter3MarketingBudget__c,
                                                          Classification__r.Quarter4MarketingBudget__c,
                                                          Classification__r.Quarter1MarketingBudgetIntl__c,
                                                          Classification__r.Quarter2MarketingBudgetIntl__c,
                                                          Classification__r.Quarter3MarketingBudgetIntl__c, 
                                                          Classification__r.Quarter4MarketingBudgetIntl__c,
                                                          AgencyName__r.AgencyRegion__c,
                                                          AgencyName__c,
                                                          AgencyName__r.UAEVATRegisterNumber__c
                                                          FROM Broker_Classification_Details__c
                                                          WHERE  Month__c IN :setQuarterMonths
                                                          AND AgencyName__r.AgencyCategory__c = 'Broker'
                                                          AND Year__c = :year 
                                                          AND AgencyName__c != null
                                                          AND Total_number_of_Sales_in_month__c > 0
                                                          AND Classification__c != null
                                                          AND Classification__r.Name NOT in ('Standard', 'Protege')
                                                          ORDER BY AgencyName__r.Name];
        system.debug('bcdList::'+bcdList);
        return bcdList;
    }

    public void execute(Database.BatchableContext bc, List<Broker_Classification_Details__c> listOfBrokerClassificationDetails){
        system.debug('listOfBrokerClassificationDetails:::'+listOfBrokerClassificationDetails);
        Decimal sumInvoiceAmount = 0;
        Map<Id, Decimal> agencySumInvoiceAmountMap = new  Map<Id, Decimal>();
        Map<Id, String> agencyUAEVATRegistrationMap = new Map<Id, String>();
        Map<Id, String> agencyIdDescriptionMap = new  Map<Id, String>();
        
        List<BrokerRequest__c> brokerRequestListToUpdate = new List<BrokerRequest__c>();
        
        // Added By Moh Sarfaraj for BRP-5653 starts
        Map<Id,AgencyLastQuarterInfo> mapAgencyIdToLastQuarterInfo = new Map<Id, AgencyLastQuarterInfo>();
        Map<Id,String> mapAgencyIdToCurrentClassification = new Map<Id, String>();

        String previousQuarter;
        Set<Integer> setPreviousQuarterMonths = new Set<Integer>();
        if(!quarter.equalsIgnoreCase('Q1')){
            previousQuarter = quarter.substring(0, 1) + (Integer.valueOf(quarter.substring(1, 2)) - 1);
            setPreviousQuarterMonths = mapQuarterToMonths.get(previousQuarter);
        }

        if(!setPreviousQuarterMonths.isEmpty()){
            Decimal currentMonth = 0;

            for(Broker_Classification_Details__c bcd : listOfBrokerClassificationDetails){
                if(bcd.Month__c > currentMonth){
                    currentMonth = bcd.Month__c;
                    mapAgencyIdToCurrentClassification.put(bcd.AgencyName__c, bcd.Classification__r.Name);
                }

                AgencyLastQuarterInfo objWrp = new AgencyLastQuarterInfo();
                objWrp.agencyId = bcd?.AgencyName__c;
                mapAgencyIdToLastQuarterInfo.put(bcd?.AgencyName__c, objWrp);
            }

            for(Account eachAgency : [SELECT Id, (SELECT Id, Net_amount__c, Month__c, Classification__r.Name FROM Broker_Classification_Details__r 
                                      WHERE Month__c IN :setPreviousQuarterMonths AND Year__c = :year) 
                                      FROM Account WHERE Id IN: mapAgencyIdToLastQuarterInfo.keySet()]){

                Double netAmount = 0;
                String classification;
                Decimal month = 0;
                
                for(Broker_Classification_Details__c eachBCD : eachAgency.Broker_Classification_Details__r){
                    netAmount += eachBCD?.Net_amount__c != null ? eachBCD?.Net_amount__c : 0;

                    if(eachBCD?.Month__c != null && eachBCD?.Month__c > month){
                        month = eachBCD?.Month__c;
                        classification = eachBCD?.Classification__r?.Name;
                    }
                }

                if(String.isNotBlank(classification)){
                    AgencyLastQuarterInfo lastQuarterInfo = mapAgencyIdToLastQuarterInfo.get(eachAgency?.Id);
                    lastQuarterInfo.netAmount = netAmount;
                    lastQuarterInfo.classification = classification;

                    mapAgencyIdToLastQuarterInfo.put(eachAgency?.Id, lastQuarterInfo);
                }
            }
        }
        // Added By Moh Sarfaraj for BRP-5653 end
        
        
        for(Broker_Classification_Details__c bcd : listOfBrokerClassificationDetails){

            // Added By Moh Sarfaraj for BRP-5653 starts
            if(String.isNotBlank(previousQuarter) && 
                mapAgencyIdToCurrentClassification.containsKey(bcd?.AgencyName__c) &&
                mapAgencyIdToCurrentClassification.get(bcd?.AgencyName__c).equalsIgnoreCase(BROKER_ENVOY_CLASSIFICATION) &&
                mapAgencyIdToLastQuarterInfo.containsKey(bcd?.AgencyName__c) && 
                String.isNotBlank(mapAgencyIdToLastQuarterInfo?.get(bcd?.AgencyName__c)?.classification) &&
                mapAgencyIdToLastQuarterInfo?.get(bcd?.AgencyName__c)?.classification?.equalsIgnoreCase(BROKER_ENVOY_CLASSIFICATION) && 
                mapAgencyIdToLastQuarterInfo?.get(bcd?.AgencyName__c)?.netAmount < Double.valueOf(System.Label.BrokerAgencyClassifiedSalesTarget)){

                continue;
            }
            // Added By Moh Sarfaraj for BRP-5653 end
            
            if(!agencyUAEVATRegistrationMap.containsKey(bcd.AgencyName__c)){
                agencyUAEVATRegistrationMap.put(bcd.AgencyName__c, bcd.AgencyName__r.UAEVATRegisterNumber__c);
            }
            
            if(bcd.AgencyName__r.AgencyRegion__c == 'Domestic'){
                if(quarter == 'Q1'){
                    Decimal marketingInvoiceAmount = agencySumInvoiceAmountMap.get(bcd.AgencyName__c) != null ? agencySumInvoiceAmountMap.get(bcd.AgencyName__c) : 0;
                    marketingInvoiceAmount = marketingInvoiceAmount+ (bcd?.Classification__r?.Quarter1MarketingBudget__c / 3);
                    agencySumInvoiceAmountMap.put(bcd.AgencyName__c, marketingInvoiceAmount);
                    
                    //To prepare description of MR
                    String existingDesc = agencyIdDescriptionMap.get(bcd.AgencyName__c);
                    String newEntry = mapMonthToName.get(bcd.Month__c) + ' - ' + (bcd?.Classification__r?.Quarter1MarketingBudget__c / 3);
                    
                    String updatedDesc = String.isNotBlank(existingDesc)
                        ? existingDesc + '\n' + newEntry
                        : newEntry;
                    
                    agencyIdDescriptionMap.put(bcd.AgencyName__c, updatedDesc);                   
                    
                }else if(quarter == 'Q2'){
                    Decimal marketingInvoiceAmount = agencySumInvoiceAmountMap.get(bcd.AgencyName__c) != null ? agencySumInvoiceAmountMap.get(bcd.AgencyName__c) : 0;
                    marketingInvoiceAmount = marketingInvoiceAmount+ (bcd?.Classification__r?.Quarter2MarketingBudget__c / 3) ;
                    agencySumInvoiceAmountMap.put(bcd.AgencyName__c, marketingInvoiceAmount);
                    
                    //To prepare description of MR
                    String existingDesc = agencyIdDescriptionMap.get(bcd.AgencyName__c);
                    String newEntry = mapMonthToName.get(bcd.Month__c) + ' - ' + (bcd?.Classification__r?.Quarter2MarketingBudget__c / 3);
                    
                    String updatedDesc = String.isNotBlank(existingDesc)
                        ? existingDesc + '\n' + newEntry
                        : newEntry;
                    
                    agencyIdDescriptionMap.put(bcd.AgencyName__c, updatedDesc);                     
                }else if(quarter == 'Q3'){
                    Decimal marketingInvoiceAmount = agencySumInvoiceAmountMap.get(bcd.AgencyName__c) != null ? agencySumInvoiceAmountMap.get(bcd.AgencyName__c) : 0;
                    marketingInvoiceAmount = marketingInvoiceAmount+ (bcd?.Classification__r?.Quarter3MarketingBudget__c / 3) ;
                    agencySumInvoiceAmountMap.put(bcd.AgencyName__c, marketingInvoiceAmount);
                    
                    //To prepare description of MR
                    String existingDesc = agencyIdDescriptionMap.get(bcd.AgencyName__c);
                    String newEntry = mapMonthToName.get(bcd.Month__c) + ' - ' + (bcd?.Classification__r?.Quarter3MarketingBudget__c / 3);
                    
                    String updatedDesc = String.isNotBlank(existingDesc)
                        ? existingDesc + '\n' + newEntry
                        : newEntry;
                    
                    agencyIdDescriptionMap.put(bcd.AgencyName__c, updatedDesc);
                    
                }else if(quarter == 'Q4'){
                    Decimal marketingInvoiceAmount = agencySumInvoiceAmountMap.get(bcd.AgencyName__c) != null ? agencySumInvoiceAmountMap.get(bcd.AgencyName__c) : 0;
                    marketingInvoiceAmount = marketingInvoiceAmount+ (bcd?.Classification__r?.Quarter4MarketingBudget__c / 3) ;
                    agencySumInvoiceAmountMap.put(bcd.AgencyName__c, marketingInvoiceAmount);
                    
                    //To prepare description of MR
                    String existingDesc = agencyIdDescriptionMap.get(bcd.AgencyName__c);
                    String newEntry = mapMonthToName.get(bcd.Month__c) + ' - ' + (bcd?.Classification__r?.Quarter4MarketingBudget__c / 3);
                    
                    String updatedDesc = String.isNotBlank(existingDesc)
                        ? existingDesc + '\n' + newEntry
                        : newEntry;
                    
                    agencyIdDescriptionMap.put(bcd.AgencyName__c, updatedDesc);
                    
                }
            } else if(bcd.AgencyName__r.AgencyRegion__c ==  'International'){
                if(quarter == 'Q1'){
                    
                    Decimal marketingInvoiceAmount = agencySumInvoiceAmountMap.get(bcd.AgencyName__c) != null ? agencySumInvoiceAmountMap.get(bcd.AgencyName__c) : 0;
                    marketingInvoiceAmount = marketingInvoiceAmount+ (bcd?.Classification__r?.Quarter1MarketingBudgetIntl__c / 3) ;
                    agencySumInvoiceAmountMap.put(bcd.AgencyName__c, marketingInvoiceAmount);
                    
                    //To prepare description of MR
                    String existingDesc = agencyIdDescriptionMap.get(bcd.AgencyName__c);
                    String newEntry = mapMonthToName.get(bcd.Month__c) + ' - ' + (bcd?.Classification__r?.Quarter1MarketingBudgetIntl__c / 3);
                    
                    String updatedDesc = String.isNotBlank(existingDesc)
                        ? existingDesc + '\n' + newEntry
                        : newEntry;
                    
                    agencyIdDescriptionMap.put(bcd.AgencyName__c, updatedDesc);
                    
                }else if(quarter == 'Q2'){
                    
                    Decimal marketingInvoiceAmount = agencySumInvoiceAmountMap.get(bcd.AgencyName__c) != null ? agencySumInvoiceAmountMap.get(bcd.AgencyName__c) : 0;
                    marketingInvoiceAmount = marketingInvoiceAmount+ (bcd?.Classification__r?.Quarter2MarketingBudgetIntl__c / 3) ;
                    agencySumInvoiceAmountMap.put(bcd.AgencyName__c, marketingInvoiceAmount);
                    
                    //To prepare description of MR
                    String existingDesc = agencyIdDescriptionMap.get(bcd.AgencyName__c);
                    String newEntry = mapMonthToName.get(bcd.Month__c) + ' - ' + (bcd?.Classification__r?.Quarter2MarketingBudgetIntl__c / 3);
                    
                    String updatedDesc = String.isNotBlank(existingDesc)
                        ? existingDesc + '\n' + newEntry
                        : newEntry;
                    
                    agencyIdDescriptionMap.put(bcd.AgencyName__c, updatedDesc);
                    
                }else if(quarter == 'Q3'){
                    Decimal marketingInvoiceAmount = agencySumInvoiceAmountMap.get(bcd.AgencyName__c) != null ? agencySumInvoiceAmountMap.get(bcd.AgencyName__c) : 0;
                    marketingInvoiceAmount = marketingInvoiceAmount+ (bcd?.Classification__r?.Quarter3MarketingBudgetIntl__c / 3) ;
                    agencySumInvoiceAmountMap.put(bcd.AgencyName__c, marketingInvoiceAmount);
                    
                    //To prepare description of MR
                    String existingDesc = agencyIdDescriptionMap.get(bcd.AgencyName__c);
                    String newEntry = mapMonthToName.get(bcd.Month__c) + ' - ' + (bcd?.Classification__r?.Quarter3MarketingBudgetIntl__c / 3);
                    
                    String updatedDesc = String.isNotBlank(existingDesc)
                        ? existingDesc + '\n' + newEntry
                        : newEntry;
                    
                    agencyIdDescriptionMap.put(bcd.AgencyName__c, updatedDesc);
                    
                }else if(quarter == 'Q4'){
                    Decimal marketingInvoiceAmount = agencySumInvoiceAmountMap.get(bcd.AgencyName__c) != null ? agencySumInvoiceAmountMap.get(bcd.AgencyName__c) : 0;
                    marketingInvoiceAmount = marketingInvoiceAmount+ (bcd?.Classification__r?.Quarter4MarketingBudgetIntl__c / 3) ;
                    agencySumInvoiceAmountMap.put(bcd.AgencyName__c, marketingInvoiceAmount);
                    
                    //To prepare description of MR
                    String existingDesc = agencyIdDescriptionMap.get(bcd.AgencyName__c);
                    String newEntry = mapMonthToName.get(bcd.Month__c) + ' - ' + (bcd?.Classification__r?.Quarter4MarketingBudgetIntl__c / 3);
                    
                    String updatedDesc = String.isNotBlank(existingDesc)
                        ? existingDesc + '\n' + newEntry
                        : newEntry;
                    
                    agencyIdDescriptionMap.put(bcd.AgencyName__c, updatedDesc);
                }
            }
        }
        Id marketingRequestRecordTypeId = Schema.SObjectType.BrokerRequest__c.getRecordTypeInfosByDeveloperName().get('MarketingReimbursement').getRecordTypeId();
        Map<Id, BrokerRequest__c> brokerRequestMap = new Map<Id, BrokerRequest__c> ();      
        List<BrokerRequest__c> brokerRequestList = [SELECT
                                                    Id,
                                                    name,
                                                    AgencyName__c,
                                                    ApprovalStatus__c,
                                                    InvoiceStatus__c,
                                                    InvoiceAmount__c,
                                                    RequestQuarter__c,
                                                    RequestYear__c
                                                    FROM BrokerRequest__c
                                                    WHERE Agencyname__c in: agencySumInvoiceAmountMap.keySet()
                                                    AND RequestYear__c =: year
                                                    AND RequestQuarter__c=: quarter];
        
        for(BrokerRequest__c brokerRequest: brokerRequestList){
            brokerRequestMap.put(brokerRequest.AgencyName__c, brokerRequest);
        }
        for(Id agencyId : agencySumInvoiceAmountMap.keySet()){
            
            BrokerRequest__c brokerRequest = new BrokerRequest__c();
            if(brokerRequestMap.containsKey(agencyId)){
                brokerRequest.id = brokerRequestMap.get(agencyId).Id;
            }
            brokerRequest.AgencyName__c = agencyId;
            brokerRequest.ApprovalStatus__c = 'Draft';
            brokerRequest.InvoiceStatus__c = 'Draft';
            brokerRequest.InvoiceAmount__c = agencySumInvoiceAmountMap.get(agencyId);
            brokerRequest.RequestQuarter__c = quarter;
            brokerRequest.RequestYear__c = year;
            brokerRequest.RecordTypeId = marketingRequestRecordTypeId;
            brokerRequest.TaxAmount__c = agencyUAEVATRegistrationMap.get(agencyId) != null? ((brokerRequest.InvoiceAmount__c * 5)/100): 0;
            brokerRequest.InvoiceDate__c = System.today();
            brokerRequest.Invoice__c = brokerRequest.Name;
            brokerRequest.Description__c = agencyIdDescriptionMap.get(agencyId);
            brokerRequestListToUpdate.add(brokerRequest);
        }
        system.debug('brokerRequestListToUpdate:::'+brokerRequestListToUpdate);
        
        if(!brokerRequestListToUpdate.isEmpty()){
            upsert brokerRequestListToUpdate;
        }
    }
    public void finish(Database.BatchableContext bc){
        
    }
    
    static Map<String,Set<Integer>> mapQuarterToMonths = new Map<String,Set<Integer>>{
        'Q1' => new Set<Integer>{ 1, 2, 3 },
            'Q2' => new Set<Integer>{ 4, 5, 6 },
                'Q3' => new Set<Integer>{ 7, 8, 9 },
                    'Q4' => new Set<Integer>{ 10, 11, 12 }
    };
        
     public static final Map<Decimal, String> mapMonthToName = new Map<Decimal, String>{
        1 => 'January',
        2 => 'February',
        3 => 'March',
        4 => 'April',
        5 => 'May',
        6 => 'June',
        7 => 'July',
        8 => 'August',
        9 => 'September',
        10 => 'October',
        11 => 'November',
        12 => 'December'
    };

    // Added By Moh Sarfaraj for BRP-5653 
    public class AgencyLastQuarterInfo {
        public Id agencyId;
        public Double netAmount;
        public String classification;
    }
}