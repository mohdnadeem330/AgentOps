public class ECSS_ProjectCommissionHelper {
    
    public static void checkForDuplicates(List<ECSS_ProjectCommission__c> newList, Map<Id, ECSS_ProjectCommission__c> oldMap) {
        Set<Id> projectIds = new Set<Id>();
        Set<Id> assetIds   = new Set<Id>();
        Set<String> categories = new Set<String>();
        
        for (ECSS_ProjectCommission__c pc : newList) {
            Boolean shouldCheck = true;
            if (oldMap != null && oldMap.containsKey(pc.Id)) {
                ECSS_ProjectCommission__c oldPc = oldMap.get(pc.Id);
                shouldCheck = (pc.ECSS_Project__c != oldPc.ECSS_Project__c ||
                               pc.ECSS_Asset__c   != oldPc.ECSS_Asset__c ||
                               pc.ECSS_UnitCategory__c != oldPc.ECSS_UnitCategory__c);
            }
            
            if (shouldCheck) {
                if (pc.ECSS_Project__c != null) {
                    projectIds.add(pc.ECSS_Project__c);
                }
                if (pc.ECSS_Asset__c != null) {
                    assetIds.add(pc.ECSS_Asset__c);
                }
                if (pc.ECSS_UnitCategory__c != null) {
                    categories.add(pc.ECSS_UnitCategory__c);
                }
            }
        }
        
        if ((projectIds.isEmpty() && assetIds.isEmpty()) || categories.isEmpty()) return;
        
        List<ECSS_ProjectCommission__c> existing = [
            SELECT Id, Name,
                   ECSS_Project__c, ECSS_Project__r.Name,
                   ECSS_Asset__c, ECSS_Asset__r.Name,
                   ECSS_UnitCategory__c
            FROM ECSS_ProjectCommission__c
            WHERE (ECSS_Project__c IN :projectIds OR ECSS_Asset__c IN :assetIds)
              AND ECSS_UnitCategory__c IN :categories
        ];
        
        for (ECSS_ProjectCommission__c pc : newList) {
            if (pc.ECSS_UnitCategory__c == null) continue;
            
            for (ECSS_ProjectCommission__c ex : existing) {
                if (ex.Id == pc.Id) continue; 
                
                if (pc.ECSS_Asset__c != null && ex.ECSS_Asset__c == pc.ECSS_Asset__c &&
                    ex.ECSS_UnitCategory__c == pc.ECSS_UnitCategory__c) {
                    
                    pc.ECSS_Asset__c.addError(
                        'Duplicate: Asset "' + ex.ECSS_Asset__r.Name +
                        '" already has a Project Commission with category "' + pc.ECSS_UnitCategory__c + '".'
                    );
                }
                
                if (pc.ECSS_Project__c != null && ex.ECSS_Project__c == pc.ECSS_Project__c &&
                    ex.ECSS_UnitCategory__c == pc.ECSS_UnitCategory__c) {
                    
                    pc.ECSS_Project__c.addError(
                        'Duplicate: Project "' + ex.ECSS_Project__r.Name +
                        '" already has a Project Commission with category "' + pc.ECSS_UnitCategory__c + '".'
                    );
                }
            }
        }
    }
}