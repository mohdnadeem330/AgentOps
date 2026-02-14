// ========================================================================================
// CLASS NAME       : AuditLogsController
// PURPOSE          : To fetch workflow-related CaseHistory logs for audit tracking.
// FUNCTIONAL AREA  : District Management (DM)
// INVOKED FROM     : Lightning Web Component (LWC) - DMPortalRequestHistoryLogs
// ========================================================================================

public class AuditLogsController {
    @AuraEnabled(cacheable=true)
    public static List<CaseHistoryWrapper> getCaseHistoryRecords(Id caseId) {
        List<CaseHistoryWrapper> historyList = new List<CaseHistoryWrapper>();
        
        for (CaseHistory ch : [
            SELECT CreatedDate, CreatedBy.Name, Field, OldValue, NewValue
            FROM CaseHistory
            WHERE CaseId = :caseId
            ORDER BY CreatedDate DESC
        ]) {
            String oldVal = ch.OldValue == null ? null : String.valueOf(ch.OldValue);
            String newVal = ch.NewValue == null ? null : String.valueOf(ch.NewValue);
            
            String description;
            if (oldVal == null && newVal == null) {
                description = '';
            } else {
                description = ch.Field + ': ' + String.valueOf(oldVal) + ' changed to ' + String.valueOf(newVal);
            }
            
            historyList.add(new CaseHistoryWrapper(
                ch.CreatedDate,
                ch.CreatedBy.Name,
                String.valueOf(ch.Field),
                ch.OldValue == null ? null : String.valueOf(ch.OldValue),
                ch.NewValue == null ? null : String.valueOf(ch.NewValue)
            ));
            
        }
        
        return historyList;
    }

 
    public class CaseHistoryWrapper {
        @AuraEnabled public String createdDateFormatted;
        @AuraEnabled public String createdByName;
        @AuraEnabled public String fieldChanged;
        @AuraEnabled public String description;
        
        public CaseHistoryWrapper(Datetime createdDate, String createdBy, String field, String oldVal, String newVal) {
            this.createdDateFormatted = createdDate.format('dd MMM yyyy HH:mm:ss');
            this.createdByName = createdBy;
            this.fieldChanged = field;
            
            // If both values are null, leave description blank
            if (oldVal == null && newVal == null) {
                this.description = '';
            } else {
                this.description = field + ': ' + (oldVal == null ? '' : oldVal) + ' changed to ' + (newVal == null ? '' : newVal);
            }
        }
    }
    
    
    
}