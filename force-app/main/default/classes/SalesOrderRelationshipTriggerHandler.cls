Public class SalesOrderRelationshipTriggerHandler {
   public static void onBeforeInsert(List<Sales_Order_Relationship__c> newList){
     SalesOrderRelationshipTriggerHelper.validateDuplicatesForThridParty(newList); //ASF-3319
     SalesOrderRelationshipTriggerHelper.validateAccountDocuemnts(Trigger.new,'Sales_Order_Relationship__c');  //ASF-3481 chnages
       
       for (Sales_Order_Relationship__c sor : newlist ) {
                if (sor.Account__c != null) {
                    JointOwnerandThirdpartyValidation.ValidationResult res = JointOwnerandThirdpartyValidation.validateThirdParty(sor.Account__c);
                    
                    if (!res.isValid) {
                        sor.addError(res.errorMessage);
                    }
                }
            }

   }
   public static void onAfterInsert(List<Sales_Order_Relationship__c> newList){
      SalesOrderRelationshipTriggerHelper.inserAARealtionShipRecords(newList); //ASF-3319
      SalesOrderRelationshipTriggerHelper.updateSalesOrderRecord(newList,null);//ASF-3320
      SalesOrderRelationshipTriggerHelper.createSORDocuments(newList);//ASF-need a story
   }
   public static void onAfterUpdate(List<Sales_Order_Relationship__c> newList,Map<Id,Sales_Order_Relationship__c> oldMap ){
      SalesOrderRelationshipTriggerHelper.updateSalesOrderRecord(newList,oldMap); //ASF-3320  
   } 
   public static void onBeforeDelete(List<Sales_Order_Relationship__c> oldList){
      SalesOrderRelationshipTriggerHelper.preventDeleteOfReceipt(oldList); //ASF-3480  changes
  }
}