public without sharing  class PropertyAccountMetrics {

// Customer 360 summary
@AuraEnabled(cacheable=true)
public static Map<String, String> getCustomer360Summary(Id accountId) {
    Map<String, String> summary = new Map<String, String>();

    try {
        Account acc = [SELECT Id, CustomerType__c, CustomerSubType__c,DarnaId__c,DarnaRegistered__pc FROM Account WHERE Id = :accountId LIMIT 1];
        summary.put('customerType', acc.CustomerType__c);
        summary.put('customerSubType', acc.CustomerSubType__c);
        summary.put('darnaRegistered', String.valueOf(acc.DarnaRegistered__pc));
    } catch (Exception e) {
        System.debug('Error in getCustomer360Summary: ' + e.getMessage());
    }

    return summary;
}

     @AuraEnabled(cacheable=true)   
public static Map<String, Object> getLeasingSummary(Id accountId) {
    Map<String, Object> result = new Map<String, Object>();

    Date today = Date.today();
    List<Contract> activeLeases = [SELECT Id, ECSS_AnnualRent__c, EndDate FROM Contract WHERE EndDate > :today AND ECSS_ContractOrganizationType__c = 'Tenancy' AND AccountId = :accountId];

    Date ninetyDays = today.addDays(90);
    List<Contract> expiringSoon = [SELECT Id FROM Contract WHERE EndDate >= :today AND EndDate <= :ninetyDays AND ECSS_ContractOrganizationType__c = 'Tenancy' AND AccountId = :accountId];

    Decimal totalLeaseValue = 0;
    for (Contract c : activeLeases) {
        if (c.ECSS_AnnualRent__c != null) {
            try {
                totalLeaseValue += Decimal.valueOf(c.ECSS_AnnualRent__c);
            } catch (Exception e) {
                System.debug('Skipping invalid rent value for Contract Id: ' + c.Id);
            }
        }
    }
    result.put('activeLeases', activeLeases.size());
    result.put('leaseValue', totalLeaseValue);
    result.put('expiringSoon', expiringSoon.size());

    return result;
}


	// Ownership Summary
    @AuraEnabled(cacheable=true)
public static Map<String, Object> getOwnershipSummary(Id accountId) {
    Map<String, Object> result = new Map<String, Object>();
    List<SalesOrder__c> ownedUnits = [
        SELECT Id, NetAmount__c, Unit__r.ProjectName__c
        FROM SalesOrder__c
        WHERE Account__c = :accountId
        AND Status__c NOT IN ('Cancelled by User', 'RTO Sold', 'RTO Converted', 'RTOConverted','Reservation In Progress','Cancelled')
    ];

    Integer totalOwned = ownedUnits.size();
    Decimal totalSalesValue = 0;
    Set<String> projectNamesSet = new Set<String>();

    for (SalesOrder__c so : ownedUnits) {
        if (so.NetAmount__c != null) {
            try {
                totalSalesValue += Decimal.valueOf(String.valueOf(so.NetAmount__c));
            } catch (Exception e) {
                System.debug('Invalid NetAmount__c for record: ' + so.Id);
            }
        }

        if (so.Unit__r != null && String.isNotBlank(so.Unit__r.ProjectName__c)) {
            projectNamesSet.add(so.Unit__r.ProjectName__c);
        }
    }

    String projectNamesCSV = String.join(new List<String>(projectNamesSet), ', ');
    if (String.isBlank(projectNamesCSV)) {
        projectNamesCSV = 'N/A'; // Apply N/A fallback for Project names
    }
    result.put('ownedUnits', totalOwned);
    result.put('totalSalesValue', totalSalesValue);
    result.put('projectNames', projectNamesCSV);

    return result;
}

   //Engagement Insights
    @AuraEnabled(cacheable=true)
public static Map<String, Object> getFinancialInsights(Id accountId) {
    Map<String, Object> result = new Map<String, Object>();

    try {
        if (accountId == null) {
            throw new AuraHandledException('Account Id cannot be null');
        }
        Integer totalCases = [SELECT COUNT() FROM Case WHERE AccountId = :accountId];
        Integer totalServiceRequests = [SELECT COUNT() FROM HexaBPM__Service_Request__c WHERE HexaBPM__Customer__c = :accountId];
        Integer totalCombined = totalCases + totalServiceRequests;

        Integer openCases = [SELECT COUNT() FROM Case WHERE AccountId = :accountId AND Status NOT IN ('Closed', 'Cancelled', 'Resolved')];
        Integer openServiceRequests = [SELECT COUNT() FROM HexaBPM__Service_Request__c WHERE HexaBPM__Customer__c = :accountId AND HexaBPM__IsClosedStatus__c = FALSE];
        Integer openCombined = openCases + openServiceRequests;

       try { 
        List<QualtricsResponse__c> feedbackList = [SELECT Id, AccountId__c, CSAT_Score__c, NPS_Score__c FROM QualtricsResponse__c WHERE AccountId__c = :accountId AND (CSAT_Score__c != null OR NPS_Score__c != null)]; Decimal totalCsat = 0; Decimal totalNps = 0; Integer countCsat = 0; Integer countNps = 0; for (QualtricsResponse__c fb : feedbackList) 
        { if
         (fb.CSAT_Score__c != null) {
        totalCsat += Decimal.valueOf(fb.CSAT_Score__c); 
         countCsat++; } 
         
         if (fb.NPS_Score__c != null) {
         totalNps += Decimal.valueOf(fb.NPS_Score__c);
        countNps++; } } 
          Decimal avgCsat = (countCsat > 0) ? (totalCsat / countCsat).setScale(1) : 0; 
          Decimal avgNps = (countNps > 0) ? (totalNps / countNps).setScale(1) : 0; 
          result.put('csatScore', String.valueOf(avgCsat)); 
          result.put('npsScore', String.valueOf(avgNps)); }
        
        catch (Exception e) { 
        System.debug('Error fetching average CSAT/NPS: ' + e.getMessage());
        result.put('csatScore', ''); result.put('npsScore', ''); }

        result.put('totalCombined', totalCombined);
        result.put('openCombined', openCombined);
    } 
    catch (Exception e) {
        System.debug('Error in getFinancialInsights: ' + e.getMessage());
        throw new AuraHandledException('Failed to load Financial Insights data: ' + e.getMessage());
    }

    return result;
}



    // Engagement (VIP) Summary
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getEngagementSummary(Id accountId) {
        Map<String, Object> result = new Map<String, Object>();

        try {
            if (accountId == null) {
                throw new AuraHandledException('Account Id cannot be null');
            }
            // Query account defensively
            List<Account> accList = [
                SELECT Id, RETL_Last_Login__pc, KYC_Validity_Status__c, LiveAldarLastActiveDatetime__pc, KYC_ValidityDate__c, CustomerVertical__c
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
            ];

            // Initialize with nulls; LWC will render 'N/A'
            String lastLoginStr = null;
            String kycStatus = null;
            String customerVertical = null;
            Date kycDate = null;
            Datetime lastActive = null;

            if (!accList.isEmpty()) {
                Account acc = accList[0];

                // KYC Status fallback to "N/A" only if blank; otherwise pass through
                kycStatus = String.isBlank(acc.KYC_Validity_Status__c) ? 'N/A' : acc.KYC_Validity_Status__c;

                // Last active: guard null before format()
                lastActive = acc.LiveAldarLastActiveDatetime__pc;
                if (lastActive != null) {
                    lastLoginStr = lastActive.format();
                }

                customerVertical = acc.CustomerVertical__c;
                kycDate = acc.KYC_ValidityDate__c;
            }

            result.put('lastLogin', lastLoginStr);
            result.put('kycStatus', kycStatus);
            result.put('customerVertical', customerVertical);
            result.put('kycdate', kycDate);

            // Communication Preference query guarded and optional
            List<Communication_Preference__c> commPrefs = [
                SELECT Id, FastTrack_Completion_Date_Time__c, CreatedDate
                FROM Communication_Preference__c
                WHERE Account__c = :accountId
                AND FastTrack_Completion_Date_Time__c != null
                ORDER BY FastTrack_Completion_Date_Time__c DESC
                LIMIT 1
            ];

            if (!commPrefs.isEmpty()) {
                result.put('fastTrackCompletion', commPrefs[0].FastTrack_Completion_Date_Time__c);
            } else {
                result.put('fastTrackCompletion', null);
            }

        } catch (Exception e) {
            System.debug('Error in getEngagementSummary: ' + e.getMessage());
            throw new AuraHandledException('Failed to load Engagement Summary data: ' + e.getMessage());
        }

        return result;
    }


    // In Maintenance & DLP Summary
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getMaintenanceAndDLPData(Id accountId) {
        Map<String, Object> result = new Map<String, Object>();

        try {
            List<Case> amcCases = [SELECT Id, Total_Amount__c, AMC_Start_Date__c, AMC_Due_Date__c FROM Case WHERE AccountId = :accountId AND Vertical__c = 'DLP' AND SubVertical__c = 'AMC'];

            Decimal totalAMCValue = 0;
            Datetime amcStart;
            Datetime amcEnd;
            for (Case c : amcCases) {
                if (c.Total_Amount__c != null) totalAMCValue += c.Total_Amount__c;
                if (amcStart == null || (c.AMC_Start_Date__c != null && c.AMC_Start_Date__c < amcStart))
                    amcStart = c.AMC_Start_Date__c;
                if (amcEnd == null || (c.AMC_Due_Date__c != null && c.AMC_Due_Date__c > amcEnd))
                    amcEnd = c.AMC_Due_Date__c;
            }

            result.put('maintenanceValue', totalAMCValue);
            result.put('maintenanceDuration', 
                (amcStart != null && amcEnd != null) 
                    ? amcStart.format() + ' - ' + amcEnd.format() 
                    : 'N/A'
            );

            List<Case> dlpCases = [SELECT Id, CustomerDLPStartDate__c, CustomerDLPEndDate__c FROM Case WHERE AccountId = :accountId AND Vertical__c = 'DLP' AND SubVertical__c = 'DLP'];

            Date dlpStart;
            Date dlpEnd;
            if (!dlpCases.isEmpty()) {
                dlpStart = dlpCases[0].CustomerDLPStartDate__c;
                dlpEnd = dlpCases[0].CustomerDLPEndDate__c;
            }
            result.put('dlpCoverage', 
                (dlpStart != null && dlpEnd != null) 
                    ? dlpStart.format() + ' - ' + dlpEnd.format() 
                    : 'N/A'
            );

            Integer openDLP = [
                SELECT COUNT()
                FROM Case
                WHERE AccountId = :accountId
                AND Vertical__c = 'DLP'
                AND SubVertical__c = 'DLP'
                AND IsClosed = FALSE
            ];

            // Treat both Closed and Resolved statuses as "resolved"
            // If your org uses different picklist values, add them to the IN clause.
            Integer resolvedDLP = [
                SELECT COUNT()
                FROM Case
                WHERE AccountId = :accountId
                AND Vertical__c = 'DLP'
                AND SubVertical__c = 'DLP'
                AND (IsClosed = TRUE OR Status IN ('Resolved','Closed'))
            ];

            result.put('openDLP', openDLP);
            result.put('resolvedDLP', resolvedDLP);
        }
        catch (Exception e) {
            System.debug('Error in getMaintenanceAndDLPData: ' + e.getMessage());
            throw new AuraHandledException('Failed to fetch Maintenance & DLP Summary: ' + e.getMessage());
        }

        return result;
    }

    // Family & Relationship View
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getFamilyRelationshipView(Id accountId) {
        Map<String, Object> result = new Map<String, Object>();

        List<AccountRelationship__c> relationships = [SELECT Id, RelationshipSubType__c, RelatedAccount__r.Name FROM AccountRelationship__c WHERE Account__c = :accountId AND RelationshipSubType__c IN ('Spouse', 'Child')];

        List<String> spouseNames = new List<String>();
        List<String> childrenNames = new List<String>();

        for (AccountRelationship__c rel : relationships) {
            if (rel.RelatedAccount__r != null) {
                if (rel.RelationshipSubType__c == 'Spouse') {
                    spouseNames.add(rel.RelatedAccount__r.Name);
                } else if (rel.RelationshipSubType__c == 'Child') {
                    childrenNames.add(rel.RelatedAccount__r.Name);
                }
            }
        }

        result.put('spouseNames', spouseNames);
        result.put('childrenNames', childrenNames);

        return result;
    }

    // Options and Upgrades Section
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getOptionsAndUpgrades(Id accountId) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            if (accountId == null) {
                throw new AuraHandledException('Account Id cannot be null');
            }

            Integer totalShoryInsuranceOrders = [SELECT COUNT() FROM Order WHERE AccountId = :accountId AND RecordType.DeveloperName = 'Insurance' AND Type = 'Shory'];

            result.put('totalShoryInsuranceOrders', totalShoryInsuranceOrders);
        } catch (Exception e) {
            System.debug('Error in getOptionsAndUpgrades: ' + e.getMessage());
            throw new AuraHandledException('Failed to load Options and Upgrades data: ' + e.getMessage());
        }

        return result;
    }
  
  // other LOBs

@AuraEnabled(cacheable=true)
public static List<String> getBusinessCrossoverLOB(Id accountId) {
    if (accountId == null) {
        return new List<String>();
    }

    Set<String> emails = new Set<String>();
    for (Contact con : [SELECT Email FROM Contact WHERE AccountId = :accountId AND Email != null]) {
        emails.add(con.Email.trim().toLowerCase());
    }

    if (emails.isEmpty()) {
        return new List<String>();
    }

    List<Contact> potentialMatches = [SELECT Email, Account.CustomerVertical__c FROM Contact WHERE Email IN :emails AND AccountId != :accountId AND Account.CustomerVertical__c != null LIMIT 200];

    Set<String> relatedVerticals = new Set<String>();
    for (Contact c : potentialMatches) {
        if (String.isNotBlank(c.Account.CustomerVertical__c)) {
            for (String val : c.Account.CustomerVertical__c.split(';')) {
                relatedVerticals.add(val.trim());
            }
        }
    }

    List<String> sortedVerticals = new List<String>(relatedVerticals);
    sortedVerticals.sort();
    return sortedVerticals;
}

        }