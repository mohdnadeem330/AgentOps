public without sharing class QuarterlyBonusController {
    @AuraEnabled
    public static void runQuarterlyPayout(String type, String quarter, String year) {

        System.debug('type---'+type);
        System.debug('quarter---'+quarter); 
        System.debug('year---'+year);

        if(type == 'Quarterly Bonus'){
            runQuarterlyBonus(quarter, year);
        }else if(type == 'Marketing Reimbursement'){
            runMarketingReimbursement(quarter, year);
        }else if(type == 'Sub Account Manager QB'){
            //Integer quarterNumber = Integer.valueOf(quarter.substring(1));
            //runSubAccountManagerQB(quarter, quarterNumber, Integer.valueOf(year));
        }
    }

    private static void runQuarterlyBonus(String quarter, String year){
        // Date today = Date.today();
        // Integer currentMonth = today.month();
        // Integer currentYear = today.year();
        Integer quarterNumber = Integer.valueOf(quarter.substring(1));
        /*
        List<QuarterlyBonusCommission__c> processedRuns = [
            SELECT Id 
            FROM QuarterlyBonusCommission__c 
            WHERE Quarter__c = :quarter 
            AND Year__c = :year 
            LIMIT 1
        ];

        if (!processedRuns.isEmpty()) {
            throw new AuraHandledException(
                'Bonus calculation already performed for ' + quarter + ' ' + year + '.'
            );
        }

       Map<Integer, String> quarterErrorMessages = new Map<Integer, String>{
        1 => 'Calculations for Q1 can only be run after April 1st.',
        2 => 'Calculations for Q2 can only be run after July 1st.',
        3 => 'Calculations for Q3 can only be run after October 1st.',
        4 => 'Calculations for Q4 can only be run after January 1st of the next year.'
        };
    
        if ((quarterNumber > currentMonth / 3 + 1) || (currentYear > Integer.valueOf(year))) {
            throw new AuraHandledException('You cannot run calculations for future quarters.');
        }


       if (quarterNumber == 1 && (currentMonth < 4)) {
            throw new AuraHandledException(quarterErrorMessages.get(quarterNumber));
        }

     
*/
        Integer lastMonthOfQuarter=0;
        switch on quarterNumber {
            When 1 {
                lastMonthOfQuarter = 3;
            }
            When 2 {
                lastMonthOfQuarter = 6;
            }
            When 3 {
                lastMonthOfQuarter = 9;
            }
            When 4 {
                lastMonthOfQuarter = 12;
            }
        }
 
        Map<Id, String> accountAgencyMap = new Map<Id, String>();
        List<Broker_Classification_Details__c> brokerClassificationDetails = [SELECT
                                                                              Id,
                                                                              Month__c,
                                                                              Year__c,
                                                                              Name,
                                                                              Classification__c,
                                                                              Classification__r.name,
                                                                              AgencyName__c 
                                                                              FROM Broker_Classification_Details__c
                                                                              WHERE Month__c =: lastMonthOfQuarter
                                                                              AND Year__c =: year 
                                                                              
                                                                              AND ((Classification__r.Name NOT in ('Standard','Envoy', 'Protege')
                                                                                    AND  AgencyName__r.AgencyRegion__c = 'Domestic')
                                                                                   OR (Classification__r.Name NOT in ('Standard', 'Protege', 'Envoy') 
                                                                                       AND  AgencyName__r.AgencyRegion__c = 'International'))];  

 
        for(Broker_Classification_Details__c brokerClassificationDetail: brokerClassificationDetails){
            if(!accountAgencyMap.containsKey(brokerClassificationDetail.AgencyName__c)){
                accountAgencyMap.put(brokerClassificationDetail.AgencyName__c, brokerClassificationDetail.Classification__r.name);
            }
        }
        system.debug('accountids' + accountAgencyMap);
        Map<Id, String> accountData = new Map<Id, String>();
        /* for (Account acc : [SELECT Id, BrokerClassification__r.Name 
        FROM Account 
        WHERE BrokerClassification__r.Name != 'Standard' 
        AND BrokerClassification__r.Name != null]) {
        accountData.put(acc.Id, acc.BrokerClassification__r.Name);
        }
        */
        if(accountAgencyMap != null && quarter != null && quarterNumber != null && year != null){
            Database.executeBatch(new ALD_QuarterlyBonusGeneratorBatch(accountAgencyMap, quarter, quarterNumber, Integer.valueOf(year)));
        } 
    }

    private static void runMarketingReimbursement(String quarter, String year){
        Database.executeBatch(new BatchToMarketingReimbursement(quarter, year));
    }

    //private static void runSubAccountManagerQB(String quarter, Integer quarterNumber, Integer year){
        //Database.executeBatch(new BatchToSubAccountManagerQB(quarter, quarterNumber, year));
    //}
}