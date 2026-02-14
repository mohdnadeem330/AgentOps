Public class TopUpCommissionTriggerHelper{
    
    
    public static void validateDuplicatesTopUpCommBeforeInsert(List<TopUpCommission__c> newRecords){
    checkForTopUpCom(newRecords);
    }
       public static void validateDuplicatesTopUpCommBeforeUpdate(List<TopUpCommission__c> newRecords,Map<Id, TopUpCommission__c> oldMap){
        List<TopUpCommission__c> newTopUpChanged = new List<TopUpCommission__c>();
        for(TopUpCommission__c tp : newRecords){
            if(oldMap.containsKey(tp.Id) && oldMap.get(tp.id).Classification__c != tp.Classification__c && tp.Classification__c !=null){
            newTopUpChanged.add(tp);
            }
          if(oldMap.containsKey(tp.Id) && oldMap.get(tp.id).Internal_Commission__c != tp.Internal_Commission__c && tp.Internal_Commission__c !=null){
            newTopUpChanged.add(tp);

          }

        }
        checkForTopUpCom(newTopUpChanged);
    }

    
    
    Public static void checkForTopUpCom(List<TopUpCommission__c> newRecords){
        // Extract unique combinations of Classification__c and intercomm__c
        Map<String, String> classificationToInterCommMap = new Map<String, String>();
        for (TopUpCommission__c record : newRecords) {
            if (record.Classification__c != null && record.Internal_Commission__c != null) {
                classificationToInterCommMap.put(record.Classification__c, record.Internal_Commission__c);
            }
        }

        // Fetch existing records matching the classification and intercomm combinations
        List<TopUpCommission__c> existingTopUpCom = getTopUpComByClassificationAndInterComm(classificationToInterCommMap);

        // Compare new records with existing records
        for (TopUpCommission__c newRecord : newRecords) {
            for (TopUpCommission__c existingRecord : existingTopUpCom) {
                if (newRecord.Classification__c == existingRecord.Classification__c &&
                    newRecord.Internal_Commission__c == existingRecord.Internal_Commission__c) {
                    newRecord.addError(Label.TopUpCommissionTriggerError +'Classification: ' + existingRecord.Name );
                }
            }
        }
    }

      Public static  List<TopUpCommission__c> getTopUpComByClassificationAndInterComm(Map<String, String> classificationToInterCommMap){
    
    return TopUpCommissionService.getTopUpCommissionWithClassificationAndInterComm(classificationToInterCommMap);
    
    
    }


}