/**
* @File Name : UnifiedAccountController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : August 11, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 11, 2025 |   | Initial Version
**/

public class UnifiedAccountController {
	private static final List<String> VALID_VERTICALS = new List<String>{
        'Aldar Properties', 'Aldar Logistics', 'LSQ', 'Retail', 'Commercial',
        'Aldar Estates', 'Government', 'Kingsfield', 'KingsfieldAD', 'KingsfieldDXB'
    };

    /**
     * Main method to assign CustomerVertical__c based on Lead and Account data
     */
    public static Account getCustomerVertical(Account ac, Lead leadRec) {
		String ECSSLabelRecordType = System.Label.ECSS_LeadRecordType_AlDarEstate;
		Id ECSSrecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(ECSSLabelRecordType).getRecordTypeId();
		Id organizationRecordTypeId = Schema.getGlobalDescribe().get('Lead').getDescribe().getRecordTypeInfosByDeveloperName().get('Organization').getRecordTypeId();
		Id personRecordTypeId = Schema.getGlobalDescribe().get('Lead').getDescribe().getRecordTypeInfosByDeveloperName().get('Person').getRecordTypeId();

        Set<String> existingVerticals = new Set<String>();

        if (ac.CustomerVertical__c != NULL && !String.isBlank(ac.CustomerVertical__c)) {
            existingVerticals.addAll(ac.CustomerVertical__c.split(';'));
        }

        // Person or Organization based logic
        if (leadRec.RecordTypeId == personRecordTypeId || leadRec.RecordTypeId == organizationRecordTypeId) {
            List<String> projectLabelData = new List<String>();
            for (String item : label.LSQProject.split(',')) {
                projectLabelData.add(item.trim());
            }
            System.debug('leadRec.Project__c==>' + leadRec.Project__c);
            System.debug('leadRec.Project__c==>' + projectLabelData);
            if(projectLabelData.contains(leadRec.Project__c)) {
                existingVerticals.add('LSQ');
            } else if (leadRec.Lead_Type__c != null) {
                String vertical = getVerticalFromLeadType(leadRec.Lead_Type__c);
                if (!String.isBlank(vertical)) {
                    existingVerticals.add(vertical);
                }
            }
        }

        // ECSS record type
        if (leadRec.recordTypeId == ECSSrecordTypeId) {
            existingVerticals.add('Aldar Estates');
        }

        ac.CustomerVertical__c = String.join(new List<String>(existingVerticals), ';');
        setCustomerVerticalCheckboxes(ac, existingVerticals);
        return ac;
    }

    /**
     * Maps Lead_Type__c to CustomerVertical values
     */
    private static String getVerticalFromLeadType(String leadType) {
        switch on leadType {
            when 'AM Sale', 'New Sale', 'Resale', 'Options and Upgrades' {
                return 'Aldar Properties';
            }
            when 'Logistics' {
                return 'Aldar Logistics';
            }
            // Add more mappings here as needed
            when else {
                return '';
            }
        }
    }

    /**
     * Updates the boolean checkbox fields based on multi-picklist values
     */
    public static void setCustomerVerticalCheckboxes(Account ac, Set<String> verticals) {
        ac.IsAldarProperties__c = verticals.contains('Aldar Properties');
        ac.IsAldarLogistics__c = verticals.contains('Aldar Logistics');
        ac.IsLSQ__c = verticals.contains('LSQ');
        ac.IsRetail__c = verticals.contains('Retail');
        ac.IsCommercial__c = verticals.contains('Commercial');
        ac.ECSS_Aldar_Estate__c = verticals.contains('Aldar Estates');
        ac.IsGovernment__c = verticals.contains('Government');
        ac.IsKingsfield__c = verticals.contains('Kingsfield');
        ac.IsKingsfieldAD__c = verticals.contains('KingsfieldAD');
        ac.IsKingsfieldDXB__c = verticals.contains('KingsfieldDXB');
        ac.IsAldarEducation__c = verticals.contains('Aldar Education');
        ac.IsHospitality__c = verticals.contains('Hospitality');
        ac.IsAldarInvestment__c = verticals.contains('Aldar Investment');
    }

    /**
     * Hook method if Customer Vertical is changed (can be invoked on update trigger)
     */
    public static Boolean isCustomerVerticalChanged(Account oldAcc, Account newAcc) {
        return oldAcc.CustomerVertical__c != newAcc.CustomerVertical__c;
    }

    /**
     * SFMC Sync Handler
     */
    /*public static void syncWithSFMC(Account acc, Boolean isSalesOrderUpdate) {
        if (acc.CustomerVertical__c != null && acc.CustomerVertical__c.contains('Aldar Properties')) {
            if (!acc.Sync_with_SFMC__c) {
                acc.Sync_with_SFMC__c = true;
            }
        }

        // Sales order update condition
        if (isSalesOrderUpdate && !acc.Sync_with_SFMC__c) {
            acc.Sync_with_SFMC__c = true;
        }
    }

	public static Account manageSFMCAccount(Account acc) {
        Account acct = NULL;

        if(acc.RecordTypeId == Constants.PERSON_RECORD_TYPE_ID && !acc.Sync_with_SFMC__pc && (acc.CustomerVertical__c == null || !acc.CustomerVertical__c.contains('LSQ'))) {
            acct = new Account(Id=acc.Id);
            acct.Sync_with_SFMC__pc = true;
            acct.Sync_with_SFMC__c = true;
        } else if((acc.RecordTypeId == Constants.ORGANIZATION_RECORD_TYPE_ID || acc.RecordTypeId == Constants.BROKER_AGENCY_RECORD_TYPE_ID) && !acc.Sync_with_SFMC__c && (acc.CustomerVertical__c == null || !acc.CustomerVertical__c.contains('LSQ'))) {
            acct = new Account(Id=acc.Id);
            acct.Sync_with_SFMC__c = true;
        }

        return acct;
    }

	public static void manageSFMCFullAccount(Account acc) {
		if(acc.RecordTypeId == Constants.PERSON_RECORD_TYPE_ID && !acc.Sync_with_SFMC__pc && (acc.CustomerVertical__c == null || !acc.CustomerVertical__c.contains('LSQ'))) {
            acc.Sync_with_SFMC__pc = true;
            acc.Sync_with_SFMC__c = true;
        } else if((acc.RecordTypeId == Constants.ORGANIZATION_RECORD_TYPE_ID || acc.RecordTypeId == Constants.BROKER_AGENCY_RECORD_TYPE_ID) && !acc.Sync_with_SFMC__c && (acc.CustomerVertical__c == null || !acc.CustomerVertical__c.contains('LSQ'))) {
            acc = new Account(Id=acc.Id);
            acc.Sync_with_SFMC__c = true;
        }
	}*/
}