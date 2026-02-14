public class ECSS_OpportunityTriggerHelper {
    
    public static List<Id> getNonLeasingCreatedOpportunityIds(List<Opportunity> opportunityList) {
        Set<Id> ownerIds = new Set<Id>();
        String ECSSLabelRecordType = System.Label.ECSS_OpportunityRecordType;
        String ECSSLabelRecordTypeParent = System.Label.ECSS_OpportunityRecordTypeParent;
        Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get(ECSSLabelRecordType)
            .getRecordTypeId();
        System.debug('recordTypeId' + recordTypeId);
        
        Id recordTypeId2 = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get(ECSSLabelRecordTypeParent)
            .getRecordTypeId();
        System.debug('recordTypeId2' + recordTypeId);
        
        for (Opportunity opp : opportunityList) {
            if (opp.OwnerId != null && ((opp.RecordTypeId == recordTypeId && opp.ExistingOpportunity__c == null) || (opp.RecordTypeId == recordTypeId2))) { ownerIds.add(opp.OwnerId);
                                                                                                                                                          }
        }
        
        // Map of OwnerId to Profile Name (User.Profile.Name)
        Map<Id, User> userMap = new Map<Id, User>(
            [SELECT Id, Profile.Name, RoleName__c FROM User WHERE Id IN :ownerIds]
        );
        
        List<Id> filteredOpportunityIds = new List<Id>();
        
        System.debug('opportunityList ' + opportunityList);
        for (Opportunity opp : opportunityList) {
            User ownerUser = userMap.get(opp.OwnerId);
            String profileName = ownerUser != null ? ownerUser.RoleName__c : '';
            if (profileName != 'Leasing Executive' && profileName != 'Leasing Agent' && ((opp.RecordTypeId == recordTypeId && opp.ExistingOpportunity__c == null) || (opp.RecordTypeId == recordTypeId2))) { filteredOpportunityIds.add(opp.Id);
                                                                                                                                                                                                           }
        }
        
        System.debug('filteredOpportunityIds ' + filteredOpportunityIds);
        if(!System.isQueueable() && !System.isFuture()){
            if(filteredOpportunityIds.size()>0){
                
                List <Assignment_Engine__c> EngList = [SELECT Id,Criteria__c,Object_Name__c,No_Criteria__c FROM Assignment_Engine__c  WHERE Object_Name__c = 'Opportunity' ];
                if(!Test.isRunningTest()){ system.enqueueJob(new ECSS_RoundRobinQueueable('Opportunity',filteredOpportunityIds,EngList,null,null,false));                    
                                         }              
                
            }
        }
        
        return filteredOpportunityIds;
    }
    public static void publishOfferEvents(List<Opportunity> newList,Map<Id,Opportunity> oldMap) {
        
        List<Sales_Opportunity_Event__e> events = new List<Sales_Opportunity_Event__e>();
        
        
        string oppRecTypeName;
        Map<Id, Schema.RecordTypeInfo> recTypeInfo = Schema.SObjectType.Opportunity.getRecordTypeInfosById();
        
        for (Opportunity newOpp : newList) {
            
            Opportunity oldOpp = oldMap != null && oldMap.containsKey(newOpp.Id) 
                
                ? oldMap.get(newOpp.Id) 
                
                : null;
            
            if (recTypeInfo.containsKey(newOpp.RecordTypeId)) {
                oppRecTypeName = recTypeInfo.get(newOpp.RecordTypeId).getDeveloperName();
            }
            system.debug('OPP:'+oppRecTypeName+'STAGE:'+newOpp.StageName);
            system.debug('oldOpp != null: '+oldOpp);
            system.debug('oldOpp.StageName: '+oldOpp.StageName);
            if ((oppRecTypeName == 'ECSS_SecondaryMarket' || oppRecTypeName == 'ECSS_OffPlan')  && newOpp.StageName == 'Closed Won' && oldOpp != null && oldOpp.StageName != newOpp.StageName)
            {	
                system.debug('IN Offer Event');
                /*
Sales_Opportunity_Event__e eventRecord = new Sales_Opportunity_Event__e();
eventRecord.ECSS_QuoteId__c = newOpp.Id;
eventRecord.ECSS_Record_Type__c  = newOpp.RecordType.DeveloperName;
eventRecord.ECSS_CompanyCode__c = newOpp.ECSS_Company__r.ECSS_LegalEntity__c;
eventRecord.Name__c = newOpp.Name;
eventRecord.ECSS_OfferTermStartDate__c = newOpp.CreatedDate.date();
eventRecord.ECSS_ProspectApplicantAccountBP__c = newOpp.Account.SAPAccountId__c;
eventRecord.ECSS_BrokerPayBy__c ='Owner';
eventRecord.ECSS_OwnerCommission__c ='N';
eventRecord.ECSS_NoOfCheques__c =1;
eventRecord.ECSS_SupplimentaryTexts__c = newOpp.Name;
eventRecord.ECSS_OfferLeadOrigin__c = newOpp.LeadOrigin__c;
eventRecord.ECSS_OfferStatus__c = 'RELS';
eventRecord.ECSS_SignatoryRoleZSIGNTBP__c = newOpp.ECSS_OwnerSAPId__c ;
eventRecord.ECSS_CashFlowFromDate__c = newOpp.CreatedDate.date();
eventRecord.ECSS_OfferTermEndDate__c = newOpp.CreatedDate.date();
events.add(eventRecord);
*/
            }
            
        }
        
        
        
        if (!events.isEmpty()) {
            
            Database.SaveResult[] results = EventBus.publish(events);
            
            for (Database.SaveResult sr : results) {
                
                System.debug('Offer_Event__e published => Success: ' + sr.isSuccess() + ', Id: ' + sr.getId());
                
                if (!sr.isSuccess()) {
                    
                    for (Database.Error err : sr.getErrors()) {
                        
                        System.debug('Error: ' + err.getMessage());
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    public static void UpdateLeasingAssetinSplit(List<Opportunity> opportunityList,Map<Id,Opportunity> oldMap){
		Set<Id>OppIds = new Set<Id>(); 
         List<Opportunity>oppList = new List<Opportunity>();
        Id parentId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('ECSS_Parent').getRecordTypeId();
        for(Opportunity opp :opportunityList){
            Opportunity OldRec = (Opportunity)oldmap.get(opp.Id);
            if(opp.recordTypeId == parentId && opp.StageName =='In Progress' && OldRec.StageName !='In Progress'){
                OppIds.add(opp.Id);Opportunity op = new Opportunity();op.Id=opp.Id;op.Leasing_Asset__c =null;oppList.add(op);
            }
        }
        
        Set<Id>leasingIds = new Set<Id>();
        
        for(Opportunity opp : [SELECT id,Leasing_Asset__c FROM Opportunity WHERE RecordType.Name ='Leasing' AND ExistingOpportunity__c =:oppIds]){
            leasingIds.add(opp.Id);
            
        }
        Map<Id,Id>LeasingAssetIdsMap = new Map<Id,Id>();
        for(QuoteLineItem quoteline : [SELECT Id,Asset__c,Quote.OpportunityId FROM QuoteLineItem WHERE Quote.OpportunityId =:leasingIds AND Asset__c != null]){
            LeasingAssetIdsMap.put(quoteline.Quote.OpportunityId,quoteline.Asset__c);
        }
        Id LeasingAssetId;
        for(Id OppId: LeasingAssetIdsMap.keySet()){
            Opportunity Oppor = new Opportunity();
            Oppor.Id = OppId;
            if(LeasingAssetIdsMap.get(OppId) != null){Oppor.Leasing_Asset__c =LeasingAssetIdsMap.get(OppId);LeasingAssetId = LeasingAssetIdsMap.get(OppId);
            }
            oppList.add(oppor);
        }
        if(!oppList.isEmpty()){
            Update oppList;
          }
    }
}